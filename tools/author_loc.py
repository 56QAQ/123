"""本地化生成脚本：写出 game/data/loc/zh.json 与 en.json。
键约定：unit.<id>.name/desc/passive.<ability_id>/note/normal · equipment.<id>.name/desc · trait.<id>.name/desc/tier.<n> · ui.* fx.* keyword.* ...
模板里的 %s/%d 必须与调用处参数个数一致(Loc.t 会截断多余参数)。"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "data", "loc")
Z, E = {}, {}


def add(key, zh, en):
    Z[key] = zh
    E[key] = en


# ------------------------------------------------------------------ 通用
for k, zh, en in [
    ("white", "白", "White"), ("red", "红", "Red"), ("blue", "蓝", "Blue"), ("green", "绿", "Green"),
    ("purple", "紫", "Purple"), ("yellow", "黄", "Yellow"), ("cyan", "青", "Cyan"), ("black", "黑", "Black")]:
    add("color." + k, zh, en)
for k, zh, en in [
    ("security", "安保", "Security"), ("research", "研究", "Research"), ("welfare", "福利", "Welfare"),
    ("engineering", "工程", "Engineering"), ("maintenance", "维护", "Maintenance"), ("information", "情报", "Information"),
    ("execution", "执行", "Execution"), ("legislation", "订法", "Legislation"), ("none", "无部门", "No Department"), ("", "—", "—")]:
    add("profession." + k, zh, en)
for k, zh, en in [("archer", "射手", "Archer"), ("warrior", "战士", "Warrior"), ("tank", "坦克", "Tank"),
                  ("caster", "法师", "Caster"), ("support", "辅助", "Support"), ("assassin", "刺客", "Assassin"), ("fighter", "斗士", "Fighter")]:
    add("role." + k, zh, en)
# 载荷结算规则(不是物品类型；物品类型 = 武器大类)
for k, zh, en in [("bullet", "固定值", "Fixed"), ("blade", "放大", "Scaling"), ("amulet", "双模", "Dual-mode"),
                  ("potion", "浮动", "Variance"), ("chip", "改写", "Rewrite"), ("tome", "学习", "Learning")]:
    add("class." + k, zh, en)
add("classrule.bullet", "固定值：不吃触发数值，触发器只当扳机。", "Fixed value: ignores the trigger value; the trigger is just the switch.")
add("classrule.blade", "放大：吃触发数值并按倍率放大。", "Scaling: multiplies the trigger value.")
add("classrule.amulet", "双模：对友军和对敌人效果不同。", "Dual-mode: does different things to allies and enemies.")
add("classrule.potion", "浮动：5% 大成功(×2) / 5% 大失败(无效)。", "Variance: 5% great success (×2) / 5% fail (nothing).")
add("classrule.chip", "改写：不直接打数字，改写同一次触发里排在它之后的载荷。", "Rewrite: deals no numbers itself, it rewrites the payloads after it in the same firing.")
add("classrule.tome", "学习：每次发动都会成长。", "Learning: grows stronger with every use.")

# 武器大类(= 装备类型)
for k, zh, en, full_zh, full_en, dzh, den in [
    ("sword", "单手剑", "Sword", "单手近战武器", "One-handed melee", "例如剑。出手利落；持盾的棋子会同时举盾。", "e.g. swords. Quick, clean swings; shield bearers keep their shield up."),
    ("polearm", "矛", "Spear", "双手长武器", "Polearm", "例如枪、矛。近战里射程最长。平时抡枪下劈；目标身后同一直线上还有敌人时改为贯穿突刺，一次刺中两个。",
     "e.g. spears. The longest melee reach. Normally a downward swing; when another enemy stands in line behind the target, a piercing thrust hits both."),
    ("heavy", "双手剑", "Greatsword", "双手重武器", "Two-handed heavy", "例如大剑。单个敌人时蓄力下劈；射程内有 2 个以上敌人时改为旋斩，最多斩中 3 个。",
     "e.g. greatswords. A charged cleave on a lone enemy; with 2+ enemies in reach, a spinning slash that hits up to 3."),
    ("dual", "双匕", "Daggers", "双持近战武器", "Dual-wield melee", "例如双匕。贴身连斩：一只手砍完，另一只手再追加一次普通攻击。",
     "e.g. twin daggers. Close-in flurries: after one blade strikes, the other follows with another normal attack."),
    ("bow", "弓", "Bow", "拉弦式远程武器", "Draw-string ranged", "例如弓。远距离。攻击间隔结束后再拉弓最多 1 秒，拉满伤害翻倍。",
     "e.g. bows. Long range. After the attack interval the archer keeps drawing for up to 1 s; a full draw doubles the damage."),
    ("crossbow", "手弩", "Hand crossbow", "单手远程武器", "One-handed ranged", "例如手弩。单手平举速射，中距离。", "e.g. hand crossbows. One-handed quick shots at mid range."),
    ("pistols", "手枪", "Pistols", "双持远程武器", "Dual-wield ranged", "例如双枪。一枪打完，另一把枪再追加一次普通攻击；单发较轻。",
     "e.g. twin pistols. After one gun fires, the other follows with another normal attack; lighter shots."),
    ("rifle", "步枪", "Rifle", "双手远程武器", "Two-handed ranged", "例如步枪。射程最远、单发最重。端着枪连射，剩余弹量打空后要花较长时间装弹。",
     "e.g. rifles. Longest range, heaviest shots. Fires in a steady stream while shouldered; an empty magazine needs a long reload."),
    ("focus", "法器", "Focus", "法器", "Focus", "例如魔典、水晶球。普通攻击是魔法弹，落点爆炸、不分敌我地溅射；会挑收益最高的落点(可以直接打地板)。",
     "e.g. grimoires, crystal balls. Magic bolts that explode and splash friend and foe alike; aims for the best-value spot (even the ground).")]:
    add("wclass.%s.name" % k, zh, en)
    add("wclass.%s.full" % k, full_zh, full_en)      # 内部用的完整分类名(不在界面显示)
    add("wclass.%s.desc" % k, dzh, den)
add("wclass.unarmed.name", "空手", "Unarmed")
add("wclass.unarmed.desc", "没有武器，不能攻击。", "No weapon: cannot attack.")
for k, zh, en in [
    ("white", "颜色：只能给白色单位。", "Color: white units only."),
    ("red", "颜色：红、白单位可用。", "Color: red, white units."),
    ("blue", "颜色：蓝、白单位可用。", "Color: blue, white units."),
    ("green", "颜色：绿、白单位可用。", "Color: green, white units."),
    ("purple", "颜色：紫、红、蓝、白单位可用。", "Color: purple, red, blue, white units."),
    ("yellow", "颜色：黄、红、绿、白单位可用。", "Color: yellow, red, green, white units."),
    ("cyan", "颜色：青、蓝、绿、白单位可用。", "Color: cyan, blue, green, white units."),
    ("black", "颜色：万用，任何颜色的单位都能用。", "Color: universal, any color can use it.")]:
    add("equip_compat." + k, zh, en)
for k, zh, en in [("physical", "物理", "physical"), ("magic", "魔法", "magic"), ("true", "真实", "true")]:
    add("dmgkind." + k, zh, en)

STATS = [
    ("attack_power", "攻击力", "Attack", "攻击", "ATK"), ("ability_power", "法术强度", "Ability Power", "法强", "AP"),
    ("defense", "防御力", "Defense", "防御", "DEF"), ("magic_resistance", "魔法抗性", "Magic Resist", "魔抗", "MRES"),
    ("max_health", "最大生命值", "Max Health", "生命", "HP"), ("health_regen_per_second", "生命回复", "Health Regen", "回复", "Regen"),
    ("physical_lifesteal", "物理吸血", "Physical Lifesteal", "吸血", "Lifesteal"), ("spell_lifesteal", "法术吸血", "Spell Lifesteal", "法吸", "Spell LS"),
    ("omnivamp", "全能吸血", "Omnivamp", "全吸", "Omni"), ("crit_chance", "暴击率", "Crit Chance", "暴击", "Crit"),
    ("crit_damage", "暴击伤害", "Crit Damage", "暴伤", "Crit Dmg"), ("physical_flat_penetration", "物理固定穿透", "Physical Flat Pen", "物穿", "PhysPen"),
    ("physical_percent_penetration", "物理百分比穿透", "Physical % Pen", "物穿%", "Phys%"), ("magic_flat_penetration", "法术固定穿透", "Magic Flat Pen", "法穿", "MagPen"),
    ("magic_percent_penetration", "法术百分比穿透", "Magic % Pen", "法穿%", "Mag%"), ("move_speed", "移动速度", "Move Speed", "移速", "SPD"),
    ("attack_base_interval_seconds", "攻击间隔", "Attack Interval", "间隔", "Interval"), ("attack_speed_multiplier", "攻击速度", "Attack Speed", "攻速", "AtkSpd"),
    ("physical_damage_pct", "物理伤害增幅", "Physical Damage %", "物伤%", "Phys%"), ("magic_damage_pct", "魔法伤害增幅", "Magic Damage %", "魔伤%", "Mag%"),
    ("true_damage_pct", "真实伤害增幅", "True Damage %", "真伤%", "True%"), ("na_damage_pct", "普攻伤害增幅", "Attack Damage %", "普攻%", "Atk%"),
    ("skill_damage_pct", "技能伤害增幅", "Skill Damage %", "技能%", "Skill%"), ("dot_damage_pct", "持续伤害增幅", "DoT Damage %", "持续%", "DoT%"),
    ("attack_range", "攻击范围", "Attack Range", "射程", "RNG"), ("damage_dealt_pct", "伤害增幅", "Damage Amp", "增幅%", "Amp%"),
    ("damage_dealt_flat", "固定增伤", "Flat Damage Done", "固增", "FlatDmg"), ("damage_taken_pct", "伤害减免", "Damage Reduction", "减免%", "DR%"),
    ("damage_taken_flat", "固定减伤", "Flat Damage Reduction", "固减", "FlatRed"), ("healing_done_pct", "治疗加成", "Healing Done %", "治疗+", "Heal+"),
    ("healing_received_pct", "受治疗加成", "Healing Received %", "受疗+", "Recv+"),
    ("reload_time_pct", "装弹时间", "Reload Time", "装弹", "Reload"),
    ("shield_received_pct", "获得护盾", "Shield Received", "护盾+", "Shld+"), ("passive_charges_bonus", "被动充能", "Passive Charges", "充能+", "Chg+"), ("summon_star_bonus", "召唤物星级", "Summon Star", "召唤★+", "Smn★+"), ("dot_taken_flat", "受到持续伤害", "DoT Taken", "受持伤+", "DoT+"), ("crit_overflow_cd", "溢出暴击转爆伤", "Crit Overflow → Crit Damage", "溢暴×", "OvCrit×"), ("damage_taken_amp", "承受伤害增幅", "Damage Taken Amp", "易伤+", "Vuln+"), ("na_dodge", "普攻闪避", "Attack Dodge", "闪避+", "Dodge+"), ("backstab_amp", "背后攻击增幅", "Backstab Amp", "背击+", "Back+"), ("haste", "计时加速", "Haste", "急速+", "Haste+"), ("full_draw_extra_targets", "满弦额外目标", "Full-Draw Extra Targets", "满弦+", "Draw+"),
    ("na_damage_taken_flat", "普攻伤害减免", "Normal Attack Damage Reduction", "普减", "NA-"),
    ("na_damage_per_ap_pct", "普攻每点法强增伤", "NA Damage per AP", "普法", "NA/AP"),
    ("amp_efficacy", "伤害增幅效能", "Damage Amp Efficacy", "增幅效能", "AmpEff"), ("dr_efficacy", "伤害减免效能", "Damage Reduction Efficacy", "减免效能", "DREff")]
for k, zh, en, zs, es in STATS:
    add("stat." + k, zh, en)
    add("stat_short." + k, zs, es)

# ------------------------------------------------------------------ 关键词
KW = [
    ("basic", "基本", "Basic", "没有冷却和充能限制：触发器一响，能力就发动。", "No cooldown or charge limit: fires whenever its trigger fires."),
    ("multi_attack", "群攻", "Multi Attack", "触发器给出多个目标时，本能力最多作用于前 N 个；没有该词条只作用于第一个。", "When the trigger supplies several targets, this ability affects the first N; without it only the first target is used."),
    ("charged", "充能", "Charged", "拥有 N 层充能，每次发动消耗 1 层，按冷却回复。", "Holds N charges; each use spends one and they recover over the cooldown."),
    ("pursuit", "追击", "Pursuit", "发动后立刻再打 N 次同样的普通攻击(副本不会再触发追击)。", "After firing, immediately repeat the normal attack N more times (copies never chain pursuit)."),
    ("chant", "吟唱", "Chant", "先吟唱 N 秒(期间不能移动和攻击，被眩晕会中断)，吟唱结束时释放；吟唱越久效果越强。", "Channel for N seconds (cannot move or attack; stun interrupts), then release. Longer chant, stronger effect."),
    ("stacking", "叠加", "Stacking", "状态最多叠加 N 层。", "The status stacks up to N times."),
    ("splash", "溅射", "Splash", "对目标周围(半径 N×1.2 米，不分敌我)的所有单位造成 50% 的效果。", "Applies 50% of the effect to every unit around the target (radius N×1.2 m, friend or foe)."),
    ("amplify", "增幅", "Amplify", "数值型参数，可被触发器或其他效果引用。", "A numeric parameter that triggers and other effects can read."),
    ("worlds", "无数世界", "Countless Worlds",
     "掷出 2d10 后按结果发动：奇数——所有敌人随机交换位置；偶数——所有敌人身上施加一个随机通用负面状态(燃烧 / 寒气 / 中毒 / 麻痹)。"
     "小于 10——对所有敌人造成小额(攻击力 + 法术强度)的魔法伤害；大于等于 10——中等的物理普攻伤害；大于等于 20——高额的真实普攻伤害。"
     "如果两颗骰子加起来是 2：所有人随机交换位置、所有人身上施加随机通用负面状态、所有人受到高额魔法伤害，不分敌我。",
     "Roll 2d10, then: odd — all enemies swap places at random; even — all enemies get one random common debuff (Burning / Chill / Poison / Paralysis). "
     "Under 10 — small magic damage (attack + ability power) to all enemies; 10 or more — medium physical normal-attack damage; 20 or more — heavy true "
     "normal-attack damage. If the two dice add up to 2: everyone swaps places, everyone gets a random common debuff, and everyone takes heavy magic damage, "
     "friend or foe."),
    ("summon", "召唤", "Summon", "在身旁召唤单位，继承召唤者的星级。", "Summons a unit next to the source, inheriting its star level."),
    ("eternal", "永恒", "Eternal", "对于本应在战斗结束时清空的数值，不受战斗结束影响，可跨战斗保留。",
     "Values that would normally reset when the battle ends are unaffected and carry over between battles."),
    ("crit", "暴击", "Crit", "效果可以暴击，使用自身的暴击率与暴击伤害。", "The effect can crit using the source's crit chance and crit damage."),
    ("limited", "限制", "Limited", "只在满足条件(限定的事件)时发动。", "Only fires when its condition (a specific kind of event) is met."),
    ("awakening", "觉醒", "Awakening", "完成指定任务前不会生效；完成后触发觉醒并永久生效。", "Inactive until its task is completed; then it awakens for the rest of the battle."),
    ("performance", "演奏", "Performance", "效果在吟唱开始时(而非吟唱结束时)施加，并在吟唱过程中一直维持。智能选择较关键的目标发动：提供增益，或者造成减益；"
     "同一种效果不能连续发动两次。可选：① 攻击力 / 法术强度最高的友方：攻击力或法术强度提升(选较优的一项)；② 生命最低的敌人：维持【燃烧】；"
     "③ 本场输出最高的敌人：维持【寒气】(每秒叠一个)；④ 生命比例最低的友方：维持【再生】(每秒叠一个)；⑤ 靠近我方后排的敌方近战：击退并维持减速；"
     "⑥ 本场回复生命最多的敌人：维持受到的治疗减少；⑦ 本场承受伤害最多的敌人：维持护甲与魔法抗性削减。",
     "The effect applies when the chant starts (not when it ends) and is sustained throughout the chant. Picks the most important target on its own — a buff or a debuff; "
     "the same effect can't be used twice in a row. Options: ① the ally with the highest attack / ability power: attack or ability power boost (whichever is better); "
     "② the enemy with the lowest health: sustained 【Burning】; ③ the enemy with the most damage dealt this battle: sustained 【Chill】 (one more each second); "
     "④ the ally with the lowest health ratio: sustained 【Regeneration】 (one more each second); ⑤ an enemy melee unit close to your backline: knocked back and kept slowed; "
     "⑥ the enemy healed the most this battle: sustained healing reduction; ⑦ the enemy that took the most damage this battle: sustained armor and magic resist reduction."),
    ("learning", "学习", "Learning", "每次触发该效果时叠加一层学习计数。会在战斗结束后清空。",
     "Each time this effect triggers it adds one learning count. Cleared when the battle ends.")]
for k, zh, en, dzh, den in KW:
    add("keyword." + k, zh, en)
    add("keyword_desc." + k, dzh, den)

# ------------------------------------------------------------------ 触发器措辞
TIM = [
    ("OnBattleStart", "战斗开始时", "at battle start"), ("OnBattleFrame", "每 0.25 秒", "every 0.25 s"), ("OnBattleEnd", "战斗结束时", "at battle end"),
    ("OnNormalAttackPerform", "进行普通攻击时", "when performing a normal attack"), ("OnNormalAttackHit", "普通攻击命中时", "on normal attack hit"),
    ("OnHitByNormalAttack", "被普通攻击命中时", "when hit by a normal attack"), ("OnDamageDealt", "造成伤害时", "when dealing damage"),
    ("OnDamageTaken", "受到伤害时", "when taking damage"), ("OnHealApplied", "治疗生效时", "when a heal lands"),
    ("OnHealOverflow", "治疗溢出时", "when a heal overflows"), ("OnShieldBroken", "护盾破碎时", "when the shield breaks"),
    ("OnUnitKilled", "击杀敌人时", "on killing an enemy"), ("OnUnitDied", "自身阵亡时", "on own death"),
    ("OnAllyUnitKilled", "友军击杀敌人时", "when an ally kills an enemy"), ("OnAllyUnitDied", "友军阵亡时", "when an ally dies"),
    ("OnBeforeDeath", "即将阵亡时", "just before death"), ("OnTargeting", "锁定新目标时", "when locking a new target"),
    ("OnAwakeningCompleted", "觉醒完成时", "when awakening completes"), ("OnSummonCompleted", "召唤完成时", "when a summon completes"),
    ("OnReloadComplete", "装弹完成时", "when a reload completes"), ("OnDashEnd", "冲锋落地后", "after a dash lands"),
    ("OnStatusOverflow", "状态满层后再获得层数时", "when a maxed-out status gains more stacks"),
    ("OnPassiveActivated", "发动被动技能时", "when a passive skill is used")]
for k, zh, en in TIM:
    add("timing." + k, zh, en)
for k, zh, en in [
    ("self", "自身", "itself"), ("current_attack_target", "当前攻击目标", "the current attack target"),
    ("event_target", "事件目标(被打者/受疗者)", "the event target"), ("event_source", "事件来源", "the event source"),
    ("all_enemies", "全体敌人", "all enemies"), ("all_allies", "全体友军", "all allies"),
    ("nearby_enemy", "周围的敌人", "nearby enemies"), ("nearby_ally", "周围的友军", "nearby allies"), ("nearby_any", "周围的单位", "nearby units"),
    ("random_enemy", "随机敌人", "a random enemy"), ("target", "目标", "the target"),
    ("nearby_units", "周围的单位", "nearby units"), ("nearby_event_target_units", "目标周围的单位", "units around the target")]:
    add("target." + k, zh, en)
add("desc.every_seconds", "每 %s 秒", "every %ss")
add("desc.every_n", "每第 %d 次", "every %d× ")
add("desc.payload_equipment", "装备载荷", "the equipped payload")
add("desc.payload_effect", "效果", "the effect")
add("desc.trigger_sentence", "%s，对%s触发%s(触发数值 = %s)", "%s → on %s fire %s (trigger value = %s)")
add("desc.trigger_value_x", "触发数值×%s", "trigger value ×%s")
add("desc.on_ally", "对友军：%s", "on allies: %s")
add("desc.on_enemy", "对敌人：%s", "on enemies: %s")
add("desc.chip_maxhp", "把同一次触发中排在它之后的载荷的触发数值，改写为目标最大生命的 %s%%", "rewrites the trigger value of the payloads after it into %s%% of the target's max health")
add("desc.chip_mult", "使同一次触发中排在它之后的载荷的触发数值 ×%s", "multiplies the trigger value of the payloads after it by ×%s")
add("desc.extra", "同时对%s：%s", "also on %s: %s")
add("desc.pre_status", "自己先获得一个【%s】，然后", "first gains one 【%s】, then ")
add("desc.overheal_shield", "；溢出转为护盾(最多到最大生命的 %s%%)", "; overheal becomes shield (up to %s%% of max health)")
add("desc.as_normal_attack", "(视为普攻伤害)", " (counts as normal-attack damage)")
add("desc.cooldown", "冷却 %s 秒：", "%s s cooldown: ")
add("desc.low_hp_mult", "；触发时自己血量低于 %s%%：×%s", "; ×%s if his health is below %s%% when it triggers")
add("desc.status_haste", "攻速状态", "attack-speed stack")
add("desc.scale_missing", "(自身每损失生命，伤害最多 +%s%%)", "(up to +%s%% as its own health drops)")
for k, zh, en in [
    ("attack_ratio", "攻击力×%s", "attack ×%s"), ("ability_power_ratio", "法强×%s", "ability power ×%s"),
    ("attack_times_ability_power_pct", "攻击力×(1+法强/100)×%s", "attack×(1+AP/100)×%s"), ("defense_ratio", "防御×%s", "defense ×%s"),
    ("max_health_ratio", "最大生命×%s", "max health ×%s"), ("current_health_ratio", "当前生命×%s", "current health ×%s"),
    ("event_value", "事件数值×%s", "event value ×%s"), ("event_target_stat_ratio", "目标属性×%s", "target stat ×%s"),
    ("source_missing_health_ratio", "已损失生命×%s", "missing health ×%s"), ("source_status_stacks_times_stat", "状态层数×属性×%s", "stacks×stat×%s")]:
    add("value." + k, zh, en)
add("value.ability_keyword_value", "【%s】数值×%s", "【%s】 value ×%s")
for k, zh, en in [
    ("physical_damage", "造成 %s 物理伤害", "deal %s physical damage"), ("magic_damage", "造成 %s 魔法伤害", "deal %s magic damage"),
    ("true_damage", "造成 %s 真实伤害", "deal %s true damage"), ("heal", "回复 %s 生命", "heal %s"), ("shield", "提供 %s 护盾", "grant %s shield"),
    ("stat_status", "施加属性状态 %s", "apply a stat status %s"), ("flag_status", "施加状态 %s", "apply a status %s"),
    ("health_cost_damage", "消耗当前生命，造成 %s 伤害", "spend current health to deal %s damage"), ("summon", "召唤单位 %s", "summon %s"),
    ("taunt", "嘲讽敌人 %s", "taunt enemies %s"), ("dash_strike", "冲锋斩 %s", "dash strike %s"), ("reset_uses", "重置可用次数", "reset uses"), ("random_status", "获得随机状态 %s", "gain a random status %s"), ("create_field", "开出稻田(站在上面每次回复 +%s)", "open a paddy field (+%s per heal on it)"), ("blink", "闪现到最佳位置 %s", "blink to the best spot %s"),
    ("grant_gold", "获得 %s 金币", "gain %s gold"), ("permanent_growth", "永久成长 %s", "grow permanently %s"), ("none", "规则型效果", "a rule effect"),
    ("oath_bestow", "赋予誓约，生命上限 +50%% 触发数值(%s)", "grant an oath, max health +50%% of the trigger value (%s)"),
    ("max_health_up", "生命上限 +%s", "max health +%s"), ("heal_to_full", "回复生命至上限", "restore to full health"),
    ("oath_bind", "绑定稀有度 5 的棋子", "bind to a rarity-5 piece"), ("dispel", "驱散 %s", "dispel %s"),
    ("status_detonate", "引爆燃烧 %s", "detonate Burning %s"), ("consume_status", "吞掉燃烧", "swallow Burning"), ("entangle", "缠住目标", "entangle the target"),
    ("create_orbs", "制造 %s 个白色晶球", "create %s white orbs"), ("hunter_notes", "针对目标的闪避 / 增伤 / 穿甲", "dodge / damage / penetration against the target"),
    ("fish_pull", "把目标钓到面前", "reel the target in"), ("rainbow_missiles", "施放虹光飞弹", "fire prismatic missiles"),
    ("familiar_marks", "攒使魔标记", "gather familiar marks"), ("rainbow_spark", "随机造成 %s 点物理 / 法术 / 真实持续伤害", "deal %s physical / magic / true-over-time damage at random"), ("instant_attack", "立刻射出一发普攻(× %s%%)", "an instant normal attack (× %s%%)"), ("status_stack_heal", "消耗层数回复生命", "spend stacks to heal"), ("empower_shots", "装填大口径子弹(基础伤害 +%s)", "load big-caliber rounds (+%s base damage)"), ("edict", "施加律令(每层 %s%%)", "apply an Edict (%s%% per stack)"), ("weapon_throw", "投掷武器 %s", "hurl the weapon %s"),
    ("status_cost_heal", "失去一层状态并回复生命", "lose a stack and restore health"),
    ("blade_storm", "转圈乱掷飞刀", "spin and fling knives"), ("starfall_impact", "落地：获得 %s 护盾，范围内敌人受一半伤害", "landing: gain a %s shield, enemies in range take half as damage"),
    ("aura_taunt", "嘲讽范围内的敌人", "taunt enemies in range"), ("death_delay", "锁血", "hold at death's door"),
    ("hp_loss_pct", "流失当前生命的百分比", "lose a share of current health"),
    ("adapt_magazine", "按目标换装下一个弹匣", "load the next magazine for the target"), ("bonus_shots", "立刻连开两枪", "fire two shots on the spot"),
    ("lose_stack", "失去一层状态", "lose a stack"), ("paint", "换上颜料", "put on paint"), ("magi_finale", "少女幻终的终结一击", "the Grand Finale's last strike"), ("knockback", "击退 %s 米", "knock back %s m"), ("mislead", "施加误导", "mislead"), ("golden_arrow", "回 1 点充能 + 黄金的指引", "restore 1 charge + Golden Guidance"),
    ("team_revive", "复活所有具有充能的友方单位", "revive every ally with charges"), ("perform_tick", "维持演奏", "sustain the performance"),
    ("perform_echo", "让演奏的效果永久持续", "make the performance's effects permanent"), ("regen", "施加再生", "apply Regeneration"), ("bleed", "叠加失血(= 血欲层数)", "apply Bleeding (= Bloodlust stacks)"),
    ("blood_feast", "获得血宴", "gain Blood Feast"), ("kin_consume", "消耗 12 层血欲", "spend 12 Bloodlust"),
    ("blood_rupture", "吟唱几秒打几下法术伤害 %s + 崩裂", "one hit of %s magic damage per second chanted + Fracture"),
    ("infuse", "叠加浸染(每 150 点 1 层)", "apply Infusion (1 stack per 150)"), ("infusion_pop", "浸染：回复攻击者并伤害持有者", "Infusion: heal the attacker, hurt the holder"), ("ignite_embers", "在目标脚下点燃余烬", "ignite an ember tile under the target"),
    ("spread_embers", "余烬向旁边蔓延", "spread the embers"), ("refresh_once", "刷新“每场战斗限一次”的技能", "refresh once-per-battle skills"), ("medium_summon", "召唤幽灵 / 幽灵犬", "summon a ghost / ghost hound"),
    ("medium_wisp", "召唤不分敌我的幽灵", "summon a ghost that attacks anyone"), ("medium_funeral", "少女幻葬的幽灵", "the Grand Requiem's ghosts"),
    ("summon_ghost_behind", "在目标背后召唤幽灵(首击 +%s)", "summon a ghost behind the target (first hit +%s)"), ("spy_hush", "少女幻嘘的眩晕", "the Grand Hush's stun"),
    ("grant_reward", "获得 %s 点经验和金币", "gain %s experience and gold"), ("blink_strike", "瞬移并连续普攻(每 100 触发数值 1 次 = %s 次)", "teleport and strike repeatedly (1 per 100 trigger value = %s)")]:
    add("effect." + k, zh, en)

# ------------------------------------------------------------------ 状态名
for k, zh, en in [("rapid_fire", "连射", "Rapid Fire"), ("quick_reload", "快速装填", "Quick Reload"), ("turtle", "缩头", "Turtling"), ("hardwork", "吃苦耐劳", "Hard Work"), ("paddy", "稻田", "Paddy Field"),
                  ("garbled_spell", "乱念的咒语", "Garbled Incantation"), ("wolf_hunt", "狼狩", "Wolf Hunt"),
                  ("idol_guard", "护星", "Star Guard"), ("first_star_light", "初星之光", "First-Star Light"),
                  ("guardian_wisdom", "监护人的智慧", "Guardian's Wisdom"), ("guardian_wisdom_crit", "监护人的力量", "Guardian's Strength"), ("witch_fire", "魔女之火", "Witch's Fire"), ("witch_ice", "魔女之冰", "Witch's Ice"), ("idol_song_as", "舞与歌·攻速", "Dance and Song · Speed"), ("idol_song_ap", "舞与歌·攻击", "Dance and Song · Attack"), ("knowledge_bombard", "知识轰炸", "Knowledge Bombardment"),
                  ("burning", "燃烧", "Burning"),
                  ("amp_link", "增幅链路", "Amp Link"), ("amp_field", "增幅力场", "Amp Field"),
                  ("sloth_preheat", "预热", "Preheat"), ("lust_bind", "色欲的侵蚀", "Lust's Erosion"), ("lust_regrowth", "蠕生", "Writhing Growth"),
                  ("glut_meltdown", "崩解", "Collapse"), ("elite_vanity", "虚荣", "Vanity"),
                  ("envy_spite", "妒恨", "Spite"), ("greed_hoard", "贪婪", "Greed"), ("melancholy_listless", "忧郁", "Melancholy"),
                  ("melancholy_drown", "溺于悲伤", "Drowned in Sorrow"), ("melancholy_gloom", "泪雨", "Rain of Tears"),
                  ("pride_favor", "傲慢的恩赐", "Pride's Favor"), ("pride_grace", "众星拱月", "Court of Stars"),
                  ("dragon_ember", "龙之余烬", "Dragon's Ember"), ("ember_wither", "龙焰灼痕", "Dragonfire Scar"),
                  ("chill", "寒气", "Chill"), ("frozen", "冻结", "Frozen"), ("regen", "再生", "Regeneration"), ("regen_eternal", "再生", "Regeneration"),
                  ("infusion", "浸染", "Infusion"),
                  ("focus_breath", "集中呼吸", "Focused Breathing"), ("commando_mark", "标定", "Marked"), ("battle_sense", "战场感知", "Battle Sense"),
                  ("purple_charge", "紫电·蓄能", "Violet Charge"), ("yellow_edge", "金锐", "Gilded Edge"), ("cyan_tide", "沧澜", "Cerulean Tide"),
                  ("shadow_veil", "凝暗", "Gathered Dark"), ("shadow_slay", "诛影", "Shadow Slay"), ("shadow_rot", "诛影·蚀", "Shadow Rot"),
                  ("lily_petal", "花瓣", "Petal"), ("lily_stamen", "花蕊", "Stamen"), ("lily_bloom", "花", "Bloom"),
                  ("brave_dream", "梦想", "Dream"), ("brave_future", "未来", "Future"),
                  ("form_lion", "狮子形态", "Lion Form"), ("form_spider", "巨蜘蛛形态", "Giant Spider Form"), ("form_toad", "巨蟾蜍形态", "Giant Toad Form"),
                  ("poison", "中毒", "Poison"), ("toad_bind", "长舌缠绕", "Tongue Bind"), ("verdant_haste", "翠绿之林", "Verdant Grove"),
                  ("petrified", "石化", "Petrified"), ("ancient_awake", "自久远的过去而来", "From the Distant Past"), ("blood_rite", "血色仪式", "Blood Rite"), ("despair", "沮丧", "Despair"), ("edge_rally", "锋芒", "Rallied"), ("puppet_strings", "牵丝", "Puppet Strings"), ("requiem_soul", "殉魂", "Requiem Soul"), ("keen_eye", "锐眼", "Keen Eye"), ("prism_shatter", "碎光", "Shattered Light"), ("star_mark", "星痕", "Star Mark"), ("chord_resonance", "共鸣", "Resonance"), ("crystal_wall", "晶壁", "Crystal Wall"), ("gunsmoke", "硝烟", "Gunsmoke"), ("chakram_slow", "迟滞", "Hindered"), ("good_luck", "好运", "Good Luck"), ("bad_luck", "厄运", "Bad Luck"), ("exposed", "破绽", "Exposed"), ("armor_crack", "碎甲", "Cracked Armor"), ("elation", "亢奋", "Elation"), ("crescendo", "渐强", "Crescendo"), ("form_demon", "恶魔形态", "Demon Form"), ("form_angel", "天使形态", "Angel Form"),
                  ("phantom_rule", "逆时幻影", "Rewound Phantom"), ("sever_scar", "斩断之痕", "Severed"), ("selfless_scar", "无我之痕", "Selfless Cut"),
                  ("money_bag", "钱袋", "Coin Purse"), ("true_dice", "真骰", "Loaded Dice"), ("quake_stance", "裂地猛击", "Earthsplitter"), ("lightning_call", "引雷", "Call Lightning"), ("paralysis", "麻痹", "Paralysis"),
                  ("funeral", "送葬", "Funeral"), ("funeral_scar", "送葬之痕", "Funeral Scar"), ("death_wish", "致向死的渴望", "Longing for Death"),
                  ("intox", "沉醉", "Enthralled"), ("dream_amp", "沉沦之梦·增幅", "Sinking Dream · Amp"), ("dream_sink", "沉沦之梦·沉沦", "Sinking Dream · Sink"),
                  ("bloodlust", "血欲", "Bloodlust"), ("bleed", "失血", "Bleeding"), ("blood_feast", "血宴", "Blood Feast"), ("blood_crack", "崩裂", "Fracture"),
                  ("bard_might_atk", "乐奏·激昂", "Performance · Fervor"), ("bard_might_ap", "乐奏·灵感", "Performance · Inspiration"),
                  ("bard_slow", "乐奏·迟缓", "Performance · Lull"), ("bard_wound", "乐奏·哀伤", "Performance · Lament"), ("bard_shred", "乐奏·破音", "Performance · Discord"),
                  ("lute_rapture", "无声琴·共鸣", "Silent Lute · Resonance"), ("lute_dissonance", "无声琴·失谐", "Silent Lute · Dissonance"),
                  ("dark_oath", "暗色誓约", "Dark Oath"), ("light_oath", "光色誓约", "Light Oath"), ("max_health_up", "生命上限提升", "Max Health Up"),
                  ("glory", "光荣", "Glory"), ("flame_banner", "赤焰战旗", "Flame Banner"), ("hunter", "狩猎者", "Hunter"),
                  ("dragged_down", "拖后腿", "Dead Weight"), ("slacking", "摸鱼", "Slacking Off"), ("weak", "弱体", "Enfeebled"),
                  ("edict_hp_up", "律令·固命", "Edict · Vigor"), ("edict_ap_up", "律令·通法", "Edict · Insight"), ("edict_atk_up", "律令·增力", "Edict · Might"),
                  ("edict_hp_down", "律令·衰命", "Edict · Wither"), ("edict_ap_down", "律令·封法", "Edict · Seal"), ("edict_atk_down", "律令·缚力", "Edict · Bind"),
                  ("big_caliber", "大口径子弹", "Big-Caliber Rounds"), ("fastest_gun", "开枪最快之人", "Fastest Gun Alive"),
                  ("sword_scar", "剑痕", "Sword Scar"), ("rekindle", "重燃", "Rekindle"), ("hunter_notes", "猎人笔记", "Hunter's Notes"),
                  ("sky_vision", "天空视野", "Sky Sight"), ("familiar_bond", "脆弱使魔", "Fragile Familiar"), ("rainbow_rot", "虹光灼痕", "Prism Sear"), ("perfect_clock", "完美时计", "Perfect Timepiece"), ("outer_form", "外神之貌", "Visage of the Outer God"),
                  ("adaptive_retrofit", "适应改造", "Adaptive Retrofit"), ("finished_product", "成品完工", "Finished Product"),
                  ("emergency_maintenance", "紧急维护", "Emergency Maintenance"),
                  ("paint", "颜料", "Paint"), ("girl_finale", "少女幻终", "A Girl's Grand Finale"),
                  ("lightning_runner", "闪电跑者", "Lightning Runner"), ("lightning_phase", "穿行", "Phasing"), ("flying_kick", "飞身踢", "Flying Kick"),
                  ("misled", "误导", "Misled"), ("stun", "眩晕", "Stun"), ("spy_domain", "少女幻嘘", "A Girl's Grand Hush"),
                  ("golden_arrow", "金矢", "Golden Arrow"), ("golden_guidance", "黄金的指引", "Golden Guidance"),
                  ("medium_domain", "少女幻葬", "A Girl's Grand Requiem"), ("spectral", "魂体存在", "Spectral"), ("silent_strike", "无声无息", "Without a Sound")]:
    add("status." + k, zh, en)

# ------------------------------------------------------------------ 特殊标签(以后会作为第三种羁绊标签)
for k, zh, en in [("blaze", "如火", "Like Fire"), ("clan", "宗族", "Clan")]:
    add("special." + k, zh, en)

# ------------------------------------------------------------------ 特效字
for k, zh, en in [("taunt", "嘲讽!", "Taunt!"), ("awakened", "觉醒!", "Awakened!"), ("pursuit", "追击", "Pursuit"), ("reload", "装弹", "Reload"), ("overheal", "溢出", "Overheal"),
                  ("trait", "羁绊", "Trait"), ("damage_word", "伤害", "damage"), ("heal_word", "治疗", "heal"), ("died", "阵亡", "fell")]:
    add("fx." + k, zh, en)

# ------------------------------------------------------------------ 界面
UI = [
    ("title", "超次元工坊", "Hyperdimensional Workshop"), ("subtitle", "工坊主，发动卡车吧 · Demo", "Start the truck, Workshop Master · Demo"),
    ("new_game", "开始游戏", "Start Game"), ("gallery", "模型展示", "Model Gallery"), ("language", "中文 / English", "中文 / English"),
    ("quit", "退出", "Quit"), ("loading", "正在加载…", "Loading…"),
    ("title_hint", "[color=#9aa3b5]你是工坊主。你的工坊是一辆能穿越次元的重型卡车，货厢里是无边的多元空间，住着模仿人类职业制造的人形机械生命——「节点」。\n所有效果都由触发器触发：节点提供触发器，武器提供效果载荷，配对才会生效。[/color]",
     "[color=#9aa3b5]You are the Workshop Master. Your workshop is a heavy truck that crosses dimensions; its cargo box holds an endless multiverse full of humanoid machine lifeforms modeled on human trades — the Nodes.\nEvery effect is fired by a trigger: Nodes own triggers, weapons carry payloads, only a pair takes effect.[/color]"),
    ("paused", "已暂停", "Paused"), ("resume", "继续", "Resume"), ("restart", "重新开始", "Restart"), ("to_title", "返回标题", "Back to Title"),
    ("controls_hint", "[color=#9aa3b5]左键拖动棋子/武器 · 右键拖动旋转 · 中键或 WASD 平移 · 滚轮缩放\n空格 开战/暂停/继续 · R 刷新 · L 锁定 · X 升级 · C 车间 · F 重置视角 · Esc 菜单[/color]",
     "[color=#9aa3b5]LMB drag pieces/weapons · RMB drag rotate · MMB or WASD pan · wheel zoom\nSpace start/pause/continue · R reroll · L lock · X level up · C workshop · F reset camera · Esc menu[/color]"),
    ("victory", "作战胜利", "Victory"), ("defeat", "作战失败", "Defeat"), ("round", "%s · 节点 %d / %d", "%s · Node %d / %d"), ("duration", "用时 %s", "Time %s"),
    ("truck", "卡车耐久", "Truck"), ("truck_damage", "敌人涌入卡车：耐久 -%d", "Enemies raided the truck: -%d durability"),
    ("raid", "敌人涌入卡车！", "The truck is being raided!"), ("cargo", "仓库", "Storage"), ("cargo_hint", "拖到场上出战 · 拖回这里收纳", "drag onto the field · drag back here to store"),
    ("storage_drop", "拖到这里收纳", "Drop here to store"), ("storage_empty", "仓库是空的", "Storage is empty"),
    ("map_node", "节点 %d", "Node %d"), ("map_done", "已通过", "Cleared"), ("map_here", "下一站", "Next stop"), ("map_later", "未到达", "Ahead"),
    ("map_click", "点击出发", "Click to set off"), ("map_enemies", "遭遇", "Encounter"), ("map_orbs", "晶球掉落", "Orb drops"),
    ("map_income", "到达时收入 +%d 金币", "On arrival: +%d gold"), ("map_final", "终点：彩虹水晶祭坛", "Destination: the rainbow-crystal altar"),
    ("map_boss", "首领", "Boss"),
    ("node_type_short.reward", "奖励", "Reward"), ("command", "指挥", "Command"), ("deploy_cap", "上场 %d/%d", "Deployed %d/%d"),
    ("operation", "作战", "Operation"), ("result_stats", "作战记录", "Combat record"), ("menu_title", "终端", "Terminal"),
    ("node_type.reward", "奖励节点", "Reward node"), ("node_type.reward.desc", "击败守卫，拾取它们掉落的晶球。", "Defeat the guards and pick up the orbs they drop."),
    ("loot_title", "点击晶球领取战利品", "Click the orbs to claim your loot"), ("loot_continue", "继续前进", "Drive on"),
    ("loot_gold", "+%d 金币", "+%d gold"), ("loot_unit", "获得节点：%s", "New Node: %s"), ("loot_weapon", "获得武器：%s", "New weapon: %s"),
    ("orb.white", "白色晶球", "White orb"), ("orb.blue", "蓝色晶球", "Blue orb"), ("orb.gold", "金色晶球", "Gold orb"), ("orb.rainbow", "彩色晶球", "Rainbow orb"),
    ("orbs_dropped", "掉落晶球 ×%d", "Orbs dropped ×%d"), ("game_over", "游戏结束", "Game Over"),
    ("chapter_clear", "%s 完成", "%s complete"), ("chapter_clear_hint", "第一章与卡车改装尚在制作中。感谢游玩！", "Chapter 1 and truck modifications are still in the works. Thanks for playing!"),
    ("truck_destroyed", "卡车损毁", "Truck destroyed"), ("run_summary2", "到达 %s · 卡车耐久 %d / %d", "Reached %s · truck %d / %d"),
    ("gold_from_units", "战斗金币 +%d", "Battle gold +%d"), ("life_lost", "失去 1 点生命(剩余 %d)", "Lost 1 life (%d left)"),
    ("next_income", "下回合收入：基础 +%d，利息 +%d", "Next round: base +%d, interest +%d"),
    ("choose_reward", "选择一件奖励武器", "Choose a reward weapon"), ("skip_reward", "放弃奖励", "Skip reward"), ("take", "选择", "Take"), ("continue", "继续", "Continue"),
    ("run_won", "通关!", "Cleared!"), ("run_lost", "挑战失败", "Run Failed"), ("run_summary", "抵达第 %d / %d 回合 · 剩余生命 %d", "Reached round %d / %d · %d lives left"),
    ("ally", "我方", "Ally"), ("enemy", "敌方", "Enemy"), ("phase.map", "地图", "Map"), ("phase.loot", "拾取战利品", "Loot"), ("inventory", "武器库", "Armory"), ("drag_to_equip", "拖到棋子身上替换武器", "drag onto a piece to swap"),
    ("inventory_empty", "还没有武器", "No weapons yet"), ("shop", "节点制造", "Fabrication"), ("shop_drop_sell", "拖到这里出售", "Drop here to sell"), ("start_battle", "开始作战", "Start"), ("skip", "跳过", "Skip"),
    ("reroll", "刷新 %d", "Reroll %d"), ("lock", "锁定", "Lock"), ("locked", "已锁定", "Locked"), ("buy_xp", "升级  %d金 → +%d经验", "Level up  %dg → +%dXP"),
    ("odds_title", "制造概率", "Fabrication odds"), ("odds_level", "等级", "Level"), ("odds_now", "当前", "Now"),
    ("odds_hint", "每个栏位各自按当前等级的概率决定费用；升级可以提高高费节点的概率", "Each slot rolls its cost tier by the current level's odds; level up for higher-cost Nodes"),
    ("income_hint", "每回合收入 %d + 利息 %d", "Per round: %d + interest %d"), ("sold", "已制造", "BUILT"), ("sell_for", "出售 (+%d 金币)", "Sell (+%d gold)"), ("unequip_drop", "放回武器库(卸下)", "Back to the armory (unequip)"),
    ("tip.drag_weapon", "拖到别的节点身上换人带 · 拖回下方武器库卸下 · 点击固定详情 · 右键卸下", "Drag onto another Node to hand it over · drag back to the armory to unequip · click to pin · right-click to unequip"),
    ("level", "Lv.%d · 上场 %d", "Lv.%d · deploy %d"), ("gold_word", "金币", "gold"), ("no_traits", "把不同颜色的棋子放上场，触发羁绊", "Field pieces of different colors to trigger traits"),
    ("battle_go", "作战开始", "Operation start"),
    ("tutorial", "把节点拖到卡车周围的格子上，把武器拖到节点身上替换它的基础武器，然后点「开始作战」", "Drag Nodes onto the cells around the truck, drag weapons onto them to replace their basic weapon, then hit Start"),
    ("fits", "✔ 该棋子可以使用", "✔ This piece can use it"), ("tip.payload_note", "武器的效果只是不完整的载荷：必须由棋子自己的触发器触发才会生效。", "A weapon's effect is only an incomplete payload: it does nothing until the piece's own trigger fires it."),
    ("trait.members", "成员", "Members"),
    ("card.stats", "属性", "Stats"), ("card.passives", "被动", "Passives"), ("card.triggers", "触发器 → 武器效果", "Triggers → Weapon effect"),
    ("card.equipment", "武器", "Weapon"), ("card.payload", "效果", "Effect"), ("card.mods", "属性加成", "Stat bonuses"),
    ("card.weapon_basic", "基础武器", "Basic weapon"), ("card.allowed", "可用武器：%s", "Can use: %s"), ("card.allowed_any", "可用武器：不限", "Can use: any"),
    ("card.weapon_line", "射程 %s · 普攻 ×%s %s · 间隔 %s秒", "Range %s · attack ×%s %s · every %ss"),
    ("card.basic_note", "朴素的基础武器：只提供射程、普攻倍率和攻击动作，没有效果。", "A plain basic weapon: only range, attack multiplier and attack moves, no effect."),
    ("card.unarmed", "空手：不能攻击", "Unarmed: cannot attack"),
    ("card.no_equipment", "只有基础武器：这个触发器目前不会产生任何效果", "Basic weapon only: this trigger currently does nothing"),
    ("card.unlock_star", "%s解锁", "unlocks at %s"),
    ("card.by_ap", "(按法强)", " (by AP)"),
    ("card.hint_edit", "武器图标：拖到别的节点身上换人带，拖回武器库卸下；左键固定详情，右键卸下", "Weapon icon: drag onto another Node to hand it over, or back to the armory to unequip; left-click to pin details, right-click to unequip"),
    ("tip.click_pin", "点击固定详情", "Click to pin"),
    ("tip.pinned", "已固定 · 指着蓝字看关键词 · 点空白处或 Esc 关闭", "Pinned · hover blue words for keywords · click elsewhere or Esc to close"),
    ("phase.prepare", "备战阶段", "Preparation"), ("phase.battle", "战斗中", "In battle"), ("phase.reward", "领取奖励", "Reward"), ("phase.over", "结束", "Over"),
    ("phase.rest", "修整", "Rest"), ("phase.event", "事件", "Event"), ("phase.shop", "商店", "Shop"), ("phase.chapter_end", "章节完成", "Chapter clear"), ("phase.branch", "选择路线", "Choose route"),
    ("err.not_now", "现在不能这样做", "Can't do that right now"), ("err.bad_cell", "这里不能放置", "Can't place here"),
    ("err.board_full", "上场人数已满，升级可以增加上场人数", "Board is full — level up for more slots"),
    ("err.color_mismatch", "颜色不兼容：这把武器不能给该棋子", "Color mismatch: this weapon can't go on that piece"),
    ("err.weapon_class", "武器类型不符：该棋子不能使用这类武器", "Wrong weapon type: this piece can't use that kind of weapon"),
    ("err.base_weapon", "这是基础武器，不能卸下", "That is the basic weapon — nothing to unequip"),
    ("err.bad_target", "没有可装备的目标", "No valid target"),
    ("err.no_gold", "金币不足", "Not enough gold"), ("err.sold", "这个节点已经制造过了", "Already built"), 
    ("codex.title", "图鉴", "Codex"),
    ("codex.subtitle", "只收录已按新设计重构的内容", "Reworked content only"),
    ("codex.close", "关闭", "Close"),
    ("codex.tab_units", "节点", "Nodes"), ("codex.tab_weapons", "武器", "Weapons"),
    ("codex.tab_traits", "羁绊", "Traits"), ("codex.tab_keywords", "关键词", "Keywords"),
    ("codex.empty", "这里还没有内容。", "Nothing here yet."),
    ("codex.empty_traits", "羁绊还没有开始重构。重构完成的羁绊会出现在这里。", "Traits haven't been reworked yet. Reworked traits will show up here."),
    ("codex.drag_hint", "拖动展台旋转", "Drag the stage to rotate"),
    ("codex.pose_idle", "待机", "Idle"), ("codex.pose_fidget", "小动作", "Fidget"),
    ("codex.pose_victory", "胜利", "Victory"), ("codex.pose_attack", "攻击", "Attack"),
    ("codex.star", "星级", "Star"), ("codex.weapon", "武器", "Weapon"), ("codex.weapon_basic", "基础武器", "Basic weapon"),
    ("codex.profile", "档案", "Profile"), ("codex.exclusive_weapon", "专属武器", "Exclusive weapon"),
    ("codex.open_entry", "查看条目", "Open entry"),
    ("codex.owner", "专属于", "Belongs to"), ("codex.owner_note", "她的专属武器，但谁都能装", "Her exclusive weapon — anyone can equip it"),
    ("codex.payload", "武器效果", "Weapon effect"),
    ("codex.rule", "结算规则：武器效果的数值怎么算", "Settlement rule: how the weapon effect's value is computed"),
    ("codex.keyword", "关键词", "Keyword"),
    ("codex.meaning", "说明", "Definition"), ("codex.used_by", "出现在", "Used by"),
    ("fx.uses_reset", "血战·再来！", "Blood Fury · Again!"),
    ("fx.summon_star", "护星节点 ★%s", "Node Warrior ★%s"),
    ("err.forbidden_rule", "她不能装备这种结算规则的武器(【双模】)", "She can't equip weapons with that rule (【Dual Mode】)"),
    ("fx.garbled.attack_speed", "乱念·攻速 +%s%%", "Garbled · AtkSpd +%s%%"),
    ("fx.garbled.ability_power", "乱念·法强 +%s", "Garbled · AP +%s"),
    ("fx.garbled.damage", "乱念·增伤 +%s%%", "Garbled · Dmg +%s%%"), ("fx.detonate", "引爆!", "Detonate!"), ("fx.oath_save", "誓约!", "Oath!"), ("fx.vendetta", "血仇", "Vendetta"), ("fx.oath_bind", "誓绶", "Oath-bound"), ("fx.vanity_lost", "虚荣散去", "Vanity fades"), ("fx.vanity", "虚荣!", "Vanity!"),
    ("fx.cleanse", "净化", "Cleansed"), ("fx.miss", "打空", "Miss"), ("fx.orb_made", "+%s", "+%s"), ("fx.slacking", "摸鱼中…", "slacking…"),
    ("fx.quarry", "狩猎对象", "Quarry"), ("fx.glory", "光荣 ×%s", "Glory ×%s"), ("fx.glory_save", "光荣!", "Glory!"), ("fx.immune", "免疫", "Immune"),
    ("fx.banner", "战旗 +%s%%", "Banner +%s%%"), ("fx.dodge", "闪避", "Dodge"), ("fx.blink", "闪烁", "Blink"), ("fx.outer_form", "外神之貌", "Outer God"), ("fx.mag_physical", "物理弹匣", "Physical rounds"), ("fx.mag_magic", "魔法弹匣", "Magic rounds"),
    ("fx.mag_true", "真实弹匣", "True rounds"), ("fx.paint_red", "红色颜料", "Red Paint"), ("fx.paint_blue", "蓝色颜料", "Blue Paint"), ("fx.finale", "少女幻终", "Grand Finale"), ("fx.kick", "飞身踢 ×%s", "Flying Kick ×%s"), ("fx.misled", "误导!", "Misled!"), ("fx.misled_resist", "误导(免疫自相残杀)", "Misled (immune to friendly fire)"),
    ("fx.stun", "眩晕", "Stunned"), ("fx.hush", "少女幻嘘", "Grand Hush"), ("fx.requiem", "少女幻葬", "Grand Requiem"), ("fx.kin_tale", "至亲的故事", "Tale of Kin"), ("fx.absolve", "斩杀", "Absolved"), ("fx.double_bird", "一石二鸟", "Two Birds"), ("fx.mark", "标定", "Marked"), ("fx.temper", "淬血", "Blood Temper"), ("fx.cover", "掩护", "Cover"), ("fx.breath_reset", "呼吸被打乱", "Breath Broken"), ("fx.aim", "瞄准", "Aiming"), ("fx.light_boost", "照亮长夜", "Light the Night"), ("fx.burn_blossom", "焚花", "Burning Blossoms"), ("fx.freeze", "冻结!", "Frozen!"), ("fx.echo", "不绝的回响", "Endless Echo"), ("fx.stamen", "花蕊 %s", "Stamen %s"), ("fx.bloom", "花开", "In Bloom"), ("fx.holy_slay", "圣剑！", "Holy Sword!"), ("fx.gentle", "温柔地", "Gently"), ("fx.funeral", "送葬", "Funeral"), ("fx.dice", "%d+%d%s = %d", "%d+%d%s = %d"), ("fx.dice_chaos", "大失败！", "Critical Fail!"), ("fx.awake", "苏醒 +%d", "Awakened +%d"), ("fx.lock", "万物闭锁", "Lock All Things"), ("fx.flip_demon", "表里之间 · 恶魔", "Demon Side"), ("fx.flip_angel", "表里之间 · 天使", "Angel Side"), ("fx.crescendo", "渐强 +%d", "Crescendo +%d"), ("fx.charge_refill", "+1 充能", "+1 Charge"), ("fx.next_movement", "下一乐章", "Next Movement"), ("fx.gate", "深空之门", "Deep-Space Gate"), ("fx.selfless", "无我", "Selfless"), ("fx.mass_copy", "量产型号", "Mass Production"), ("fx.miracle", "奇迹", "Miracle"), ("fx.pickpocket", "+%d 金币", "+%d gold"), ("fx.bag", "钱袋 %d", "Purse %d"), ("fx.bag_double", "翻倍！%d", "Doubled! %d"), ("fx.bag_clear", "钱袋空了", "Purse emptied"), ("fx.bag_cash", "钱袋 +%d 金币", "Purse +%d gold"), ("fx.quake", "裂地猛击", "Earthsplitter"), ("fx.holy_mend", "圣疗", "Holy Mending"), ("fx.paralyzed", "麻痹", "Paralyzed"), ("fx.weather_rain", "变天 · 下雨", "Rain"), ("fx.weather_sunny", "变天 · 晴天", "Clear Skies"), ("fx.weather_fog", "变天 · 起雾", "Fog"), ("fx.form_lion", "狮子形态", "Lion Form"), ("fx.form_spider", "巨蜘蛛形态", "Giant Spider"), ("fx.form_toad", "巨蟾蜍形态", "Giant Toad"), ("fx.form_base", "基础形态", "Base Form"), ("fx.will_live", "求生", "Will to Live"), ("fx.fly_again", "再度飞翔", "Fly Again"), ("fx.future", "未来", "Future"),
    ("fx.perform.might", "激昂", "Fervor"), ("fx.perform.burn", "灼音", "Searing Note"), ("fx.perform.chill", "寒音", "Chill Note"),
    ("fx.perform.regen", "愈音", "Healing Note"), ("fx.perform.repel", "震音", "Shock Note"), ("fx.perform.wound", "哀音", "Lament"), ("fx.perform.shred", "破音", "Discord"), ("fx.wither", "-%d 上限", "-%d max"), ("fx.greed", "金焰", "Gilded Flame"),
    ("fx.edict", "傲慢敕令", "Edict of Pride"), ("fx.charge_up", "充能 +1", "Charge +1"), ("fx.revive", "复活!", "Revived!"),
    ("fx.true_heart", "少女真心", "True Heart"), ("fx.refresh", "再一次!", "Once more!"),
    ("err.unique", "该节点是唯一的", "That node is unique"), ("fx.backstab", "背刺!", "Backstab!"), ("fx.xp", "经验 +%s", "EXP +%s"), ("fx.starfall", "渡星而来", "Starfall"), ("fx.familiar", "使魔 %s/6", "Familiar %s/6"), ("fx.hooked", "上钩!", "Hooked!"), ("fx.notes", "笔记 +%s%%", "Notes +%s%%"), ("fx.rekindle", "重燃 ×%s", "Rekindle ×%s"), ("fx.afterglow", "残光", "Afterglow"),
    ("err.not_wearable", "这件物品不能佩戴", "This item can't be worn"),
    ("err.flag_on_enemy", "把狩猎旗标拖到敌人身上", "Drag the Hunting Flag onto an enemy"),
    ("tip.drag_flag", "拖到敌人身上：标记为狩猎对象", "Drag onto an enemy to mark it as the quarry"),
    # 详细战报(结算界面)
    ("report.tab_dealt", "输出", "Dealt"), ("report.tab_taken", "承伤", "Taken"), ("report.tab_heal", "治疗", "Healing"), ("report.tab_shield", "护盾", "Shields"),
    ("report.col_unit", "单位", "Unit"), ("report.col_total", "数值", "Amount"), ("report.col_share", "占比", "Share"), ("report.col_kills", "击杀", "Kills"),
    ("report.col_life", "存活", "Status"), ("report.col_source", "来源", "Source"), ("report.col_type", "类型", "Type"), ("report.col_hits", "次数", "Hits"),
    ("report.col_crit", "暴击", "Crit"), ("report.col_casts", "次数", "Casts"), ("report.col_over", "溢出", "Overheal"), ("report.col_attacker", "攻击者", "Attacker"),
    ("report.dps", "秒伤", "DPS"), ("report.alive", "存活", "Alive"), ("report.fell", "阵亡", "Fell"), ("report.summon", "召唤物", "summon"),
    ("report.team_total", "全队合计", "Team total"), ("report.per_sec", "每秒 %s", "%s / s"),
    ("report.by_source", "来源技能", "Sources"), ("report.by_target", "目标", "Targets"), ("report.heal_targets", "治疗对象", "Healed"),
    ("report.shield_targets", "护盾对象", "Shielded"), ("report.by_attacker", "伤害来源", "Damage from"), ("report.breakdown", "承伤去向", "Breakdown"),
    ("report.absorbed", "护盾吸收", "Absorbed by shields"), ("report.hp_lost", "实际扣血", "Health lost"), ("report.mitigated", "被抵挡", "Mitigated"),
    ("report.healed", "受到治疗", "Healing received"), ("report.shielded", "受到护盾", "Shields received"),
    ("report.mitigated_note", "被抵挡 = 护甲 / 魔抗 / 减伤 / 普攻固定减免挡掉的伤害(不计入承伤)。承伤 = 护盾吸收 + 实际扣血 + 致命一击溢出的部分。",
     "Mitigated = damage stopped by armor / magic resist / reductions / flat attack reduction (not counted as taken). Taken = absorbed + health lost + overkill on the killing blow."),
    ("report.mixed", "混合", "mixed"), ("report.empty", "这一项没有记录", "Nothing recorded"),
    ("report.by_cat", "伤害分类", "By category"), ("report.cat_normal_attack", "普攻", "Attacks"), ("report.cat_skill", "技能", "Skills"),
    ("report.cat_dot", "持续", "Over time"),
    ("report.kind_na", "普攻", "ATK"), ("report.kind_passive", "被动", "PSV"), ("report.kind_weapon", "武器", "WPN"), ("report.kind_trait", "羁绊", "TRT"),
    ("report.kind_status", "状态", "STS"), ("report.kind_terrain", "地形", "MAP"), ("report.kind_regen", "回复", "RGN"), ("report.kind_other", "其他", "ETC"),
    ("starfall.title", "星旅节点 · 预计落点", "Node Astronaut · predicted landing"), ("starfall.desc",
     "仓库里的星旅节点会在战斗开始时坠落到这里(场上已经有星旅节点就不会)。圈里现在有 %s 个敌人：落地护盾和伤害按圈里的敌人数算。",
     "The Node Astronaut in storage crashes down here when the battle starts (not if one is already on the field). %s enemies are inside the circle now: "
     "her landing shield and damage scale with the enemies in it."),
    ("report.src_na", "普通攻击", "Normal attack"), ("report.src_lifesteal", "吸血", "Lifesteal"), ("report.src_other", "其他", "Other"), ("report.env", "环境", "Environment"),
    ("report.terrain_burning_ruin", "燃烧废墟", "Burning Ruins"), ("report.terrain_ember", "余烬地块", "Embers"), ("report.terrain_tram", "电车", "The Tram"),
    ("report.terrain_fire_arc", "喷泉火弧", "Fountain Fire Arcs"),
    ("report.src.node_druid_arrow", "监护人的光箭", "Guardian's Light Arrow"), ("report.src.node_noble_stamen", "花蕊", "Stamen"), ("report.src.node_brave_holy", "勇者，圣剑", "Holy Sword"), ("report.src.node_angel_funeral", "送葬", "Funeral"), ("report.src.node_warden_venom", "中毒", "Poison"), ("report.src.node_samurai_rekindle", "重燃", "Rekindle"),
    ("speed_label", "倍速", "Speed"), ("speed_tip", "战斗倍速(开战时生效，之后每场沿用) · 数字键 1~5", "Battle speed (applies when the battle starts and sticks) · keys 1–5"),
    ("card.special_tag", "特殊标签", "Special tag"), ("card.token", "特殊物品 · 不可佩戴", "Special item · can't be worn"),
    ("err.max_level", "已达到最高等级", "Max level reached"), ("err.empty_board", "卡车周围没有节点，先把节点拖到格子上", "No Nodes around the truck — drag some onto the grid"),
]
for k, zh, en in UI:
    add("ui." + k, zh, en)

# ------------------------------------------------------------------ 章节
add("chapter.ch0.name", "第零章：白之章", "Chapter 0: The White Chapter")
add("chapter.ch0.short", "白之章", "White Chapter")
add("chapter.ch0.desc", "白色的宗教遗迹。大理石与石英的断壁残垣一路延伸到天边，尽头是闪耀着彩虹色能量水晶的祭坛。",
    "White religious ruins. Broken walls of marble and quartz stretch to the horizon; at the end stands an altar ablaze with rainbow energy crystals.")

add("chapter.ch1_red.name", "第一章-A：红之章", "Chapter 1-A: The Red Chapter")
add("chapter.ch1_red.short", "红之章", "Red Chapter")
add("chapter.ch1_red.desc", "黑夜里燃烧的城市废墟。倒塌的学校、居民区、市中心与工厂区一直烧到天边，余烬像雪一样落下。卡车的行动力有限，规划好路线。",
    "A ruined city burning through the night. Collapsed schools, homes, downtown towers and factories smoulder to the horizon while embers fall like snow. The truck's action points are limited — plan your route.")
add("chapter.ch1_blue.name", "第一章-B：蓝之章", "Chapter 1-B: The Blue Chapter")
add("chapter.ch1_blue.short", "蓝之章", "Blue Chapter")
add("chapter.ch1_blue.desc", "蓝色穹顶包围的箱庭：穹顶下是一座白色的未来都市，天光透过穹顶洒下来，整座城泡在蓝光里。首领在城北那座巨大的信标之下。",
    "A box garden sealed under a blue dome: a white city of the future, with daylight pouring through the glass and soaking everything in blue. The boss waits beneath the colossal beacon in the north.")
add("chapter.ch1_green.name", "第一章-C：绿之章", "Chapter 1-C: The Green Chapter")
add("chapter.ch1_green.short", "绿之章", "Green Chapter")
add("chapter.ch2_purple.name", "第二章-A：紫之章", "Chapter 2-A: The Purple Chapter")
add("chapter.ch2_purple.short", "紫之章", "Purple Chapter")
add("chapter.ch2_purple.desc", "漂在云海上的和风空岛，紫色的夜。北方立着九条巨大的冰质狐狸尾巴，一道斜着的巨大剑痕把岛斩成两半，只有几座桥能过去；"
    "岛正中央的紫色冰山下是首领。到处是坚冰，战场上的寒雾会一层层地叠上【寒气】，站久了会冻住。",
    "A Japanese sky island adrift on a sea of clouds, under a purple night. Nine colossal icy fox tails rise in the north; a giant diagonal sword scar "
    "cuts the island in two, crossable only by a few bridges. The boss waits beneath the purple iceberg at the island's heart. Hard ice everywhere; "
    "frost on the battlefield piles up 【Chill】 until whoever lingers freezes.")
add("chapter.ch2_yellow.name", "第二章-B：黄之章", "Chapter 2-B: The Yellow Chapter")
add("chapter.ch2_yellow.short", "黄之章", "Yellow Chapter")
add("chapter.ch2_cyan.name", "第二章-C：青之章", "Chapter 2-C: The Cyan Chapter")
add("chapter.ch2_cyan.short", "青之章", "Cyan Chapter")

# ------------------------------------------------------------------ 方格网章节(第一章起)：节点类型 / 零件 / 改装(占位) / 界面
for k, zh, en, short_zh, short_en, dzh, den in [
    ("start", "起点", "Start", "起点", "Start", "卡车出发的地方。", "Where the truck set out."),
    ("fight", "普通作战", "Battle", "作战", "Battle", "遭遇大罪的余烬。离起点越远，战斗强度越高；强度 18 以上是强怪池。", "Embers of the deadly sins. The further from the start, the higher the battle intensity; 18 and up draws from the strong pool."),
    ("elite", "精英作战", "Elite Battle", "精英", "Elite", "强大的精英怪带着手下。掉落金色晶球。", "A powerful elite with escorts. Drops a gold orb."),
    ("boss", "首领", "Boss", "首领", "Boss", "本章的首领。打倒它进入下一层。行动力用完之前要赶到这里。", "The chapter boss. Defeat it to move on to the next layer. Get here before you run out of action points."),
    ("rest", "修整", "Rest Stop", "修整", "Rest", "二选一：维修卡车，或者把一个 1 星节点直接升到 2 星。", "Choose one: repair the truck, or promote a 1-star Node straight to 2 stars."),
    ("event", "事件", "Event", "事件", "Event", "不期而遇：一幕奇景和几个选择，各有各的代价与收益。", "An unexpected encounter: a strange scene and a few choices, each with its own price and reward."),
    ("shop_black", "黑市", "Black Market", "黑市", "Market", "流动商贩的地下集市：武器、卡车零件、卡车维修。可以反复光顾。", "A roving trader's underground market: weapons, truck parts and truck repairs. You can come back any time."),
    ("shop_parts", "零件铺", "Parts Dealer", "零件铺", "Parts", "只做卡车零件生意：买零件，也回收零件。可以反复光顾。", "Deals only in truck parts — buys and sells them. You can come back any time."),
    ("hunt", "追猎", "The Hunt", "追猎", "Hunt", "行动力耗尽，首领的强化版追了上来。", "Out of action points — an empowered boss has caught up with you.")]:
    add("ui.node_type." + k, zh, en)
    add("ui.node_type_short." + k, short_zh, short_en)
    add("ui.node_type.%s.desc" % k, dzh, den)

for k, zh, en, dzh, den in [
    ("jerrycan", "备用油桶", "Jerry Can", "立刻获得 2 点行动力。", "Gain 2 action points right away."),
    ("offroad_tire", "越野轮胎", "Off-road Tires", "沿上下左右直线跳到 2 格以内的节点(可以越过未完成的节点、没有路也行)，消耗 1 点行动力。",
     "Jump in a straight line to a node up to 2 grid points away (over unfinished nodes, even without a road). Costs 1 action point."),
    ("spring_jack", "液压弹跳器", "Hydraulic Jack", "跳到周围一圈 8 格里的任意节点(斜着也行)，消耗 1 点行动力。", "Jump to any node in the 8 surrounding grid points (diagonals too). Costs 1 action point."),
    ("scout_drone", "侦察无人机", "Scout Drone", "观测卡车周围 2 格以内的所有节点。", "Reveal every node within 2 grid points of the truck.")]:
    add("part.%s.name" % k, zh, en)
    add("part.%s.desc" % k, dzh, den)

# ------------------------------------------------------------------ 事件(game/data/events.json，tools/author_events.py)
# event.<id>.title / body / opt.<选项> / res.<结果>；正文里的换行 = 分段
def event(eid, title, body, opts, res):
    add("event.%s.title" % eid, title[0], title[1])
    add("event.%s.body" % eid, body[0], body[1])
    for k, (zh, en) in opts.items():
        add("event.%s.opt.%s" % (eid, k), zh, en)
    for k, (zh, en) in res.items():
        add("event.%s.res.%s" % (eid, k), zh, en)


event("burning_fountain", ("燃烧喷泉", "The Burning Fountain"),
      ("路过公园的遗址时，你见识到一幕奇景。\n"
       "公园中心，原本喷出清凉水花的喷泉，此刻却持续喷出着三人多高的冲天火柱……\n"
       "那火焰模仿着曾经取悦人类的景色，划出美妙的曲线洒落。\n"
       "荒唐的非日常光景里，蕴含着可以吞噬任何人类的高温。\n"
       "要怎么做？",
       "Passing the ruins of a park, you witness a strange sight.\n"
       "At the park's center, the fountain that once sprayed cool water now pours out a pillar of fire three people tall...\n"
       "The flames imitate the scenery that once delighted humans, falling in graceful arcs.\n"
       "Within this absurd, unreal scene lies a heat that could devour any human.\n"
       "What will you do?"),
      {"collect": ("冒险收集火焰样本。", "Risk it and collect a sample of the flames."),
       "destroy": ("这是邪恶的东西。破坏喷泉。", "This thing is evil. Destroy the fountain."),
       "study": ("尝试理解其中的原理。", "Try to understand how it works.")},
      {"collect": ("你把卡车倒到池边，节点们举着隔热板把收集罐伸进火里。一道火弧扫过车厢，在漆面上烫出一大片焦黑——但罐子里已经装满了跳动的燃素。",
                   "You back the truck up to the basin while the Nodes hold up heat shields and push the canisters into the fire. An arc of flame sweeps across the cargo box and scorches the paint black — but the canisters are full of dancing phlogiston."),
       "destroy_gold": ("一发精准的射击打断了喷口下面的供火管。火柱晃了晃，塌成一滩余烬。烧干的池底露出一层被烤得发亮的硬币——曾经有很多人在这里许过愿。",
                        "One precise shot severs the feed pipe under the nozzle. The pillar of fire wavers and collapses into embers. The dried-out basin reveals a layer of coins baked to a shine — many people once made wishes here."),
       "destroy_fight": ("喷泉应声碎裂——火柱却没有熄灭。它在半空中扭曲、凝聚，烧红的人影一个接一个从火里走了出来。\n它们不喜欢被打扰。",
                         "The fountain shatters — but the pillar of fire does not go out. It twists and gathers in midair, and red-hot figures step out of the flames one after another.\nThey do not like being disturbed."),
       "study": ("节点们围着喷泉记录了很久：火弧的轨迹、温度的起伏、喷口的节律。没人能完全说清这是怎么回事，但每个人都学到了点东西。",
                 "The Nodes spend a long while around the fountain taking notes: the paths of the arcs, the rise and fall of the heat, the rhythm of the nozzle. Nobody can fully explain it, but everyone learns something.")})
event("last_tram", ("末班电车", "The Last Tram"),
      ("卡车拐上一条嵌着铁轨的大街时，脚下的路面开始震动。\n"
       "一节路面电车从街道尽头驶来。车厢里灌满了火，车窗一格一格地亮着，每扇窗后都立着黑色的人影。\n"
       "它在烧得只剩骨架的站台前准点停下。车门打开，广播沙哑地报了一声站名——没有人下车，也没有人上车。\n"
       "这座城市已经没有乘客了，火焰却还记得它的时刻表。\n"
       "要怎么做？",
       "As the truck turns onto an avenue with rails set into the asphalt, the road begins to tremble.\n"
       "A streetcar comes rolling in from the far end of the street. The car is filled with fire; its windows glow one by one, and behind every pane stands a black figure.\n"
       "It stops right on time at a platform burned down to its frame. The doors open and a hoarse announcement calls the name of the stop — nobody gets off, and nobody gets on.\n"
       "This city has no passengers left, yet the fire still remembers its timetable.\n"
       "What will you do?"),
      {"follow": ("跟在它后面走。", "Follow in its wake."),
       "board": ("上车。行李架上还有东西。", "Board it. There is still luggage on the racks."),
       "watch": ("目送它离开，再看看站牌。", "Watch it leave, then read the stop sign.")},
      {"follow": ("车门合上，叮叮两声，电车重新开动。它一路撞开横在轨道上的瓦砾和废车，卡车咬着它的尾灯跟了上去。\n"
                  "拖在车尾的火舌把驾驶室的漆燎起了一片泡——但前面的路是通的。",
                  "The doors close, the bell rings twice, and the streetcar pulls out. It rams aside the rubble and wrecks lying across the rails, and the truck follows right on its tail lights.\n"
                  "The tongue of fire trailing behind it blisters the paint on the cab — but the road ahead is clear."),
       "board_fight": ("节点们刚踏进车门，一整车的人影同时转过了头。\n"
                       "吊环还在摇晃。它们一个接一个走下车，在站台上站成一排。\n"
                       "这班车早就满员了。",
                       "The moment the Nodes step through the door, every figure in the car turns its head at once.\n"
                       "The hand straps are still swinging. One after another they step off and line up on the platform.\n"
                       "This car has been full for a long time."),
       "watch": ("车门合上，电车拖着一长串火星开进街道深处，在下一个路口转弯，不见了。\n"
                 "站牌上的路线图还没有烧完。节点们照着它，把附近几条街的情况一一标到了地图上。",
                 "The doors close and the streetcar rolls off down the street trailing a long string of sparks, turns at the next junction, and is gone.\n"
                 "The route map on the stop sign has not burned away yet. Following it, the Nodes mark the nearby streets on the map one by one.")})
event("quiet_street", ("寂静的街道", "A Quiet Street"),
      ("卡车驶过一条烧空了的商店街。\n卷帘门半开着，招牌在风里吱呀作响，除此之外什么也没有。",
       "The truck rolls down a burned-out shopping street.\nShutters hang half open and signs creak in the wind. Other than that, there is nothing."),
      {"leave": ("继续前进。", "Keep moving.")},
      {"leave": ("你们没有停留。", "You don't linger.")})

# ---------------------------------------------------------------- 第二批(2026-10-06)：通用事件(docs/EVENTS_BATCH2.md)
event("gacha_machine", ("扭蛋机", "The Gacha Machine"),
      ("整条街都停电了，只有游戏厅门口那台扭蛋机还亮着。\n"
       "玻璃罩里塞满了彩色的蛋，投币口下面压着一张手写的纸条：「只收金币」。\n"
       "机器背后没有电线。它不知道靠什么在转。",
       "The whole street is dark; only the gacha machine outside the arcade is still lit.\n"
       "The glass dome is packed with colored capsules, and a handwritten note is wedged under the coin slot: \"Gold coins only.\"\n"
       "There is no cable behind the machine. Whatever keeps it running, it isn't electricity."),
      {"pull": ("投币。", "Drop in a coin."), "shake": ("用力晃它。", "Give it a hard shake."), "walk": ("走开。", "Walk away.")},
      {"ball_white": ("机器嗡嗡地转了一圈，出口咔哒一声掉出一颗白色的蛋。", "The machine whirs through a turn and a white capsule clunks out of the chute."),
       "ball_blue": ("灯光转了两圈才停。出口掉出一颗蓝色的蛋，比看起来沉得多。", "The lights go around twice before stopping. A blue capsule drops out — heavier than it looks."),
       "eat": ("投币口把金币吞了进去，机器安静了几秒，什么也没有掉出来。纸条上又多了一行字：「谢谢惠顾」。",
               "The slot swallows the coin. The machine goes quiet for a few seconds and nothing comes out. The note has grown a new line: \"Thank you for playing.\""),
       "ball_gold": ("所有的灯一起亮了起来。出口掉出一颗金色的蛋，玻璃罩里的其他蛋都往后缩了缩。",
                     "Every light comes on at once. A gold capsule drops out, and all the other capsules in the dome shrink back a little."),
       "shake_ball": ("节点们抱着机器摇了几下，一颗卡住的白色的蛋掉了出来。然后机器里有什么东西断了，灯灭了。",
                      "The Nodes grab the machine and rock it; a stuck white capsule falls out. Then something inside snaps, and the lights go dead."),
       "shake_hit": ("机器纹丝不动。倒车去顶它的时候，卡车的后保险杠撞瘪了一块——机器的灯灭了，再也没有亮起来。",
                     "The machine doesn't budge. Backing the truck into it dents the rear bumper — the lights go out and never come back."),
       "walk": ("你们没有投币。走出几步回头看，机器的灯光好像比刚才暗了一点。", "You keep your coins. A few steps on, you glance back: the lights seem a little dimmer than before.")})
event("dig_site", ("挖掘现场", "The Dig Site"),
      ("路边有一个挖了一半的坑。铁锹还插在土里，旁边是一台烧坏的挖掘机。\n"
       "有人在这里挖过什么东西，没挖完就走了——或者没来得及走。\n"
       "坑底露出一角木箱。卡车的绞盘够得着。",
       "There's a half-dug pit by the road. A shovel is still stuck in the dirt, next to a burned-out excavator.\n"
       "Someone was digging for something here and left before finishing — or never got the chance to leave.\n"
       "The corner of a wooden crate shows at the bottom. The truck's winch could reach it."),
      {"dig": ("再挖一层。", "Dig one more layer."), "pack_up": ("收工。", "Pack up.")},
      {"dig1": ("绞盘拖开第一层土，底下是一箱还没发芽的种子，用油纸包得好好的。车厢蹭掉了一块漆。",
                "The winch drags off the first layer. Underneath is a crate of seeds, still wrapped in oilpaper and not yet sprouting. The cargo box loses a strip of paint."),
       "dig2": ("第二层土是湿的。箱子里是整整齐齐的矿泉水瓶，瓶里的东西在往上流。",
                "The second layer is damp. The crate holds neat rows of mineral-water bottles, and whatever is inside them flows upward."),
       "dig3_gold": ("第三层。箱子沉得绞盘的电机冒了烟——里面是一箱硬币。", "Third layer. The crate is so heavy the winch motor smokes — it's full of coins."),
       "dig3_empty": ("第三层。箱子很轻，撬开是空的，只有一张字条：「别再往下了」。", "Third layer. The crate is light; prised open, it's empty except for a note: \"Don't go any deeper.\""),
       "dig4_orb": ("第四层的土是温的。箱子里躺着一颗七彩的晶球，像一颗还在跳的心脏。", "The fourth layer is warm. Inside the crate lies a rainbow orb, pulsing like a heart that hasn't stopped."),
       "dig4_collapse": ("第四层。坑壁塌了，半辆卡车滑进坑里。节点们花了一个小时才把它拖出来。",
                         "Fourth layer. The pit wall gives way and half the truck slides in. It takes the Nodes an hour to drag it out."),
       "pack_up": ("你们把铁锹插回土里。坑底的箱子又被盖住了。", "You stick the shovel back in the dirt. The crate at the bottom is covered again.")})
event("entropy_well", ("负熵井", "The Entropy Well"),
      ("公路边有一口井。井口结着冰，井绳自己在动。\n"
       "井里的水往上流，在井口上方停成一个发蓝光的水球，然后一滴一滴地落回去。\n"
       "打上来的东西不是水。",
       "There's a well by the highway. Ice has formed on its rim, and the rope moves by itself.\n"
       "The water flows upward, hangs above the mouth as a blue-glowing sphere, then drips back down.\n"
       "What comes up in the bucket isn't water."),
      {"draw": ("再打一桶。", "Draw another bucket."), "drink": ("让一个节点喝一口。", "Let a Node take a sip."), "cover": ("盖上井盖。", "Put the lid back on.")},
      {"draw": ("一桶液态负熵。它顺着桶沿往上爬，在车厢的铁皮上蚀出一片白霜。", "A bucket of liquid negentropy. It climbs over the rim and etches a patch of white frost into the cargo box's steel."),
       "drink_boon": ("那个节点喝了一口，打了个寒战。之后的几天里，他出手的时候周围的空气会一起变冷。",
                      "The Node takes a sip and shivers. For days afterwards, the air around them goes cold whenever they strike."),
       "drink_lost": ("那个节点喝了一口，看着井里，然后沿着井绳爬了下去。你们等到天亮，井绳一直在动。",
                      "The Node takes a sip, looks into the well, then climbs down the rope. You wait until dawn. The rope never stops moving."),
       "cover": ("井盖合上的时候，里面传来一声像是叹气的水声。", "As the lid closes, something inside makes a sound like water sighing.")})
event("toll_gate", ("路障", "The Toll Gate"),
      ("两辆横过来的废车、一排沙袋，路被堵死了。\n"
       "沙袋后面亮起一盏探照灯，照得人睁不开眼。对方没有露面，只有一个声音喊话：留下东西，就放行。\n"
       "他们不想打。他们也没必要打。",
       "Two wrecks across the road and a row of sandbags: the way is blocked.\n"
       "A searchlight snaps on behind the sandbags, too bright to look at. Nobody shows themselves; a voice calls out: leave something, and you pass.\n"
       "They don't want a fight. They don't need one."),
      {"pay": ("交钱。", "Pay them."), "hand_weapon": ("交一把武器。", "Hand over a weapon."), "force": ("硬闯。", "Ram through."), "turn": ("掉头。", "Turn around.")},
      {"pay": ("一袋金币从车窗递出去。探照灯熄了，沙袋让开一条缝。", "A bag of coins goes out the window. The searchlight dies and the sandbags part just wide enough."),
       "hand_weapon": ("武器库里的一把武器被递了出去。探照灯后面传来一声口哨。", "A weapon from the armory goes over the sandbags. Someone behind the searchlight whistles."),
       "force": ("卡车撞开了废车，车头上留了一道深深的凹痕。绕开散落的碎片又花了不少时间。",
                 "The truck rams the wrecks aside, leaving a deep dent in the bonnet. Weaving around the scattered debris costs more time."),
       "turn": ("你们掉头绕了很远的路。探照灯在身后晃了很久。", "You turn around and take the long way. The searchlight follows you for a long while.")})
event("blowout", ("爆胎", "Blowout"),
      ("砰的一声。所有人都看向同一个方向。\n"
       "卡车右后轮的胎面裂开一道大口子，轮毂已经压在了柏油上。\n"
       "这段路两边什么都没有。",
       "A bang. Everyone looks the same way.\n"
       "The rear right tire has split wide open; the rim is already sitting on the asphalt.\n"
       "There's nothing on either side of this road."),
      {"spare": ("换备胎。", "Fit the spare."), "rim": ("用轮毂开。", "Drive on the rim."), "part": ("拆一个零件顶上。", "Cannibalize a part.")},
      {"spare": ("千斤顶、扳手、备胎。等卡车重新落地，天色已经变了。", "Jack, wrench, spare. By the time the truck is back on the ground, the light has changed."),
       "rim": ("轮毂一路在路面上刮出火花。等找到能换胎的地方，整条后轴都该换了。", "The rim throws sparks the whole way. By the time there's somewhere to change the tire, the whole rear axle needs replacing."),
       "part": ("节点们拆掉了一个零件，用它的材料把轮胎勉强补好了。", "The Nodes strip a part and patch the tire with what's left of it.")})
event("spoiled_supplies", ("变质的补给", "Spoiled Supplies"),
      ("车厢门一开，一股酸味冲了出来。\n"
       "车间的密封罐不知道什么时候开了一道缝，几个罐子倒在地上冒烟，地板上的东西还在往四周爬。",
       "When the cargo door opens, a sour smell rolls out.\n"
       "One of the workshop's sealed canisters has cracked somewhere along the way. Several lie on the floor smoking, and what spilled is still creeping outward."),
      {"dump": ("倒掉坏的那批。", "Dump the bad batch."), "sort": ("花时间分拣。", "Take the time to sort it."), "ignore": ("不管它。", "Leave it.")},
      {"dump": ("最多的那种材料倒掉了一半。地板擦干净了。", "Half of your most plentiful material goes over the side. The floor comes clean."),
       "sort": ("节点们一罐一罐地检查，扔掉了每种材料里坏掉的那一份。天黑了才弄完。", "The Nodes check every canister and throw out the spoiled share of each. It's dark before they finish."),
       "ignore": ("半夜里车厢传来一声闷响。早上看，一面车壁被炸得向外鼓起。", "In the night there's a muffled thump from the cargo box. In the morning, one wall bulges outward.")})
event("ash_storm", ("余烬风暴", "Ash Storm"),
      ("风把整座城市的灰烬都卷起来了。\n"
       "能见度只剩几米，雨刷在挡风玻璃上刮出两道红色的弧线。\n"
       "灰烬里有火星，火星里有别的东西在动。",
       "The wind has lifted the ashes of the whole city.\n"
       "Visibility is down to a few meters; the wipers smear two red arcs across the windshield.\n"
       "There are sparks in the ash, and in the sparks, other things moving."),
      {"drive": ("顶风开。", "Drive into it."), "wait": ("停车等。", "Pull over and wait."), "dark": ("关掉所有仪器。", "Shut everything down.")},
      {"drive": ("卡车顶着风走了一夜。早上漆面被灰烬磨得发白，车窗上全是裂纹。", "The truck pushes through the storm all night. By morning the paint is sanded pale and every window is crazed with cracks."),
       "wait": ("你们停在一堵墙下面等风过去。等了很久。", "You pull up under a wall and wait for it to blow over. It takes a long time."),
       "dark": ("灯、雷达、引擎，全部关掉。黑暗里有东西贴着车壁走过去了，不止一个。它们记住了卡车的气味。",
                "Lights, radar, engine — all off. Things pass along the side of the truck in the dark, more than one. They have your scent now.")})
event("lost_armory", ("失落的军火库", "The Lost Armory"),
      ("公路边的土坡里半埋着一扇钢门。门缝里透出灯光。\n"
       "门上的电子锁还亮着，键盘旁边贴着一张褪色的告示：「仅限 5 级以上人员」。\n"
       "锁的不是人。是等级。",
       "A steel door sits half buried in the embankment beside the highway. Light leaks through the crack.\n"
       "The electronic lock is still live. A faded notice beside the keypad reads: \"Level 5 personnel and above only.\"\n"
       "It isn't people the lock is keeping out. It's rank."),
      {"hack": ("破解电子锁。", "Crack the lock."), "blast": ("炸开门。", "Blow the door."), "door": ("只拿门口的。", "Take what's by the door.")},
      {"hack": ("锁认下了你们的等级。门后的架子上还剩一件没人领走的武器，抽屉里是一叠没发出去的薪水。",
                "The lock accepts your rank. One unclaimed weapon is still on the rack inside, and a drawer holds a stack of wages nobody collected."),
       "blast": ("一发精准的射击打烂了门锁。冲击波震塌了半边土坡，卡车被埋了一半——但架子上的武器拿到了。",
                 "One precise shot wrecks the lock. The blast brings down half the embankment onto the truck — but the weapon on the rack is yours."),
       "door": ("门口的柜子里有几把零钱。你们没有碰那扇门。", "There's loose change in the cabinet by the door. You leave the door alone.")})
event("wandering_mechanic", ("流浪技师", "The Wandering Mechanic"),
      ("一辆改装得面目全非的皮卡停在路边，焊枪的蓝光在车顶上一闪一闪。\n"
       "戴焊接面罩的人掀开面罩，看了一眼卡车，叹了口气。\n"
       "「这车还能开，真是奇迹。」",
       "A pickup modified past recognition sits by the road; the blue flicker of a welding torch plays over its roof.\n"
       "The welder lifts her mask, looks the truck over, and sighs.\n"
       "\"It's a miracle this thing still runs.\""),
      {"overhaul": ("请她大修。", "Hire her for an overhaul."), "part": ("换个零件。", "Trade for a part."), "join": ("请她上车。", "Ask her to come along.")},
      {"overhaul": ("她干了一整夜。早上的卡车比出厂的时候还结实，车架上多焊了一圈加强梁。",
                    "She works through the night. By morning the truck is sturdier than it was from the factory, with an extra ring of bracing welded onto the frame."),
       "part": ("她从皮卡的货斗里翻出一个零件，拍了拍灰递过来。", "She digs a part out of the pickup's bed, slaps the dust off and hands it over."),
       "join": ("她看了看自己的皮卡，又看了看卡车，把焊枪别在腰上爬上了车厢。", "She looks at her pickup, then at the truck, hooks the torch on her belt and climbs into the cargo box.")})
event("orb_rain", ("晶球雨", "Orb Rain"),
      ("夜空里划过一道流星。不是流星——是谁家的仓库在天上炸了。\n"
       "路边的田野上落了一地发光的晶球，有的还在往沟里滚。\n"
       "远处还有更大的一颗，正拖着光慢慢地滚远。",
       "A meteor streaks across the night sky. Not a meteor — somebody's warehouse has blown up in the air.\n"
       "The field beside the road is littered with glowing orbs; some are still rolling toward the ditch.\n"
       "Further off, a bigger one is slowly rolling away, trailing light."),
      {"near": ("捡近的。", "Grab the nearest."), "big": ("捡大的。", "Go for the big ones."), "chase": ("去追还在滚的那颗。", "Chase the one still rolling.")},
      {"near": ("三颗蓝色的晶球，还带着落地时的余温。", "Three blue orbs, still warm from the fall."),
       "big": ("节点们追着最亮的那几颗跑了半个田野。回来的时候天已经亮了，一颗金的、一颗白的。",
               "The Nodes chase the brightest ones across half the field. They come back at dawn with a gold one and a white one."),
       "chase_orb": ("那颗球在沟边停下来等了你们一会儿。七彩的光从它里面透出来。", "The orb stops at the edge of the ditch, as if waiting for you. Seven colors shine out from inside it."),
       "chase_lost": ("那颗球滚进了沟里，光灭了。沟底什么也没有。", "The orb rolls into the ditch and its light goes out. There's nothing at the bottom.")})
event("old_altar", ("古老的祭坛", "The Old Altar"),
      ("公路正中央立着一座祭坛，和启程那天在城外见过的是同一种。\n"
       "它不属于这一章。它不属于任何一章。\n"
       "祭坛上的凹槽和卡车的油箱口一个尺寸。",
       "An altar stands in the middle of the highway — the same kind you saw outside the city on the day you set out.\n"
       "It doesn't belong to this chapter. It doesn't belong to any chapter.\n"
       "The hollow on top is exactly the size of the truck's fuel cap."),
      {"offer_gold": ("献上金币。", "Offer gold."), "offer_hp": ("献上卡车的耐久。", "Offer the truck's durability."), "offer_mats": ("献上材料。", "Offer materials."), "study": ("研究它。", "Study it.")},
      {"offer_gold": ("金币落进凹槽就不见了。最强的那个节点忽然站直了——以后每一击都比从前重。",
                      "The coins vanish into the hollow. Your strongest Node suddenly stands straighter — every blow from now on lands harder."),
       "offer_hp": ("卡车的一块装甲板被祭坛吸了过去。作为交换，一个节点身上的光变成了两道。",
                    "A plate of the truck's armor is pulled onto the altar. In exchange, the light on one Node splits into two."),
       "offer_mats": ("三种材料在凹槽里混成一团，然后祭坛亮了。这一章剩下的路上，节点制造的手气都变好了。",
                      "The three materials blend together in the hollow, and the altar lights up. For the rest of this chapter, fabrication rolls run in your favor."),
       "study": ("节点们围着祭坛看了很久，抄下了上面的纹路。", "The Nodes study the altar for a long time and copy down the patterns on it.")})
event("old_friend", ("旧友", "An Old Friend"),
      ("路边坐着一个人，坐在一只行李箱上，脚边放着一只长长的武器箱。\n"
       "是以前车队的人。他说他不打算再上路了，但东西可以留给你们。",
       "Someone is sitting by the road on a suitcase, a long weapon case at their feet.\n"
       "It's one of the old convoy. He says he's done with the road, but what he has can go with you."),
      {"take_weapon": ("收下武器。", "Take the weapon."), "favor": ("收下人情。", "Accept the favor."), "join": ("劝他一起走。", "Talk him into coming.")},
      {"take_weapon": ("武器箱里的东西保养得很好。他说这是他最后一次擦它。", "Whatever is in the case has been well looked after. He says this was the last time he'd clean it."),
       "favor": ("他写了几个地址给你们——这条路上还有人欠他的。这一章剩下的每一站，都会有人多留一点东西给卡车。",
                 "He writes down a few addresses — people along this road still owe him. At every stop left in this chapter, someone leaves a little extra for the truck."),
       "join_yes": ("他沉默了很久，然后把行李箱扔上了车。", "He's quiet for a long time, then throws the suitcase into the truck."),
       "join_no": ("他摇了摇头，但把自己知道的路况都讲给了你们。", "He shakes his head, but tells you everything he knows about the road ahead.")})

for k, zh, en in [
    ("header", "不期而遇", "Unexpected encounter"), ("rarity", "稀有度", "Rarity"),
    ("repeat_n", "第 %d / %d 次", "Try %d / %d"), ("repeat_done", "已经试过 %d 次了", "Already tried %d times"),
    ("closed", "这个选项已经不能选了", "This option is no longer available"), ("back", "回到现场", "Back to the scene"), ("hidden", "？？？", "???"),
    ("req_gold", "需要：金币 ≥ %d", "Requires gold ≥ %d"), ("req_mat", "需要：%s ≥ %d", "Requires %s ≥ %d"), ("req_mat_all", "需要：三种材料各 ≥ %d", "Requires ≥ %d of each material"),
    ("req_level", "需要：等级 ≥ %d", "Requires level ≥ %d"), ("req_ap", "需要：行动力 ≥ %d", "Requires action points ≥ %d"),
    ("req_roster", "需要：至少 %d 个节点", "Requires at least %d Nodes"), ("req_weapon", "需要：武器库里有武器", "Requires a weapon in the armory"),
    ("req_part", "需要：零件箱里有零件", "Requires a part in the parts box"), ("req_picked", "需要：先「%s」%d 次", "Requires \"%s\" %d times first"),
    ("req_picked_below", "需要：「%s」少于 %d 次", "Requires \"%s\" fewer than %d times"), ("req_now", "(现在 %d)", "(now %d)"),
    ("eff_gold_lose", "失去 %d 金币", "Lose %d gold"), ("eff_mat_lose", "失去 %s ×%d", "Lose %s ×%d"), ("eff_mat_half", "失去最多的那种材料的一半", "Lose half of your most plentiful material"),
    ("eff_truck_heal", "回复 %d 卡车耐久", "Restore %d truck durability"), ("eff_truck_full", "卡车耐久回满", "Fully repair the truck"),
    ("eff_truck_max", "卡车耐久上限 +%d", "Truck durability cap +%d"), ("eff_truck_max_lose", "卡车耐久上限 -%d", "Truck durability cap -%d"),
    ("eff_unit", "获得一个 %d 费的随机节点", "Gain a random %d-cost Node"), ("eff_unit_named", "获得节点：%s", "Gain the Node %s"),
    ("eff_weapon", "获得一把 ≤ %d 费的随机武器", "Gain a random weapon (≤ %d cost)"), ("eff_weapon_named", "获得武器：%s", "Gain the weapon %s"),
    ("orb_rainbow", "七彩晶球", "rainbow orb"), ("eff_perm", "%s永久 +%d%% 伤害", "%s permanently deals +%d%% damage"),
    ("who_random", "随机一个节点", "A random Node"), ("who_strongest", "最强的节点", "Your strongest Node"), ("who_cheapest", "最便宜的节点", "Your cheapest Node"),
    ("eff_star_up", "一个 1 星节点(≤ %d 费)升到 2 星", "A 1★ Node (≤ %d cost) rises to 2★"), ("eff_lose_unit", "失去%s", "Lose %s"),
    ("eff_lose_weapon", "失去武器库里的一把随机武器", "Lose a random weapon from the armory"), ("eff_lose_part", "失去一个随机零件", "Lose a random part"),
    ("eff_part", "获得一个随机卡车零件", "Gain a random truck part"), ("eff_part_named", "获得零件：%s", "Gain the part %s"),
    ("got_unit", "节点加入：%s", "Node joined: %s"), ("got_weapon", "得到武器：%s", "Weapon gained: %s"), ("got_orb", "%s开出：%s", "%s held: %s"),
    ("got_perm", "%s 永久 +%d%% 伤害", "%s: permanently +%d%% damage"), ("got_star_up", "%s 升到了 2 星", "%s rose to 2★"),
    ("lost_unit", "失去了节点：%s", "Node lost: %s"), ("lost_weapon", "失去了武器：%s", "Weapon lost: %s"), ("lost_part", "失去了零件：%s", "Part lost: %s"),
    ("got_part", "得到零件：%s", "Part gained: %s"),
    ("req_ranged", "需要：一名手持远程武器、攻击力 ≥ %d 的节点", "Requires a Node holding a ranged weapon with attack ≥ %d"),
    ("req_ranged_met", "%s(攻击力 %d)", "%s (attack %d)"), ("req_ranged_none", "(现在没有)", "(none right now)"),
    ("req_ranged_best", "(最高：%s 攻击力 %d)", "(best: %s, attack %d)"),
    ("req_truck", "需要：卡车耐久高于 %d", "Requires truck durability above %d"),
    ("eff_truck", "失去 %d 卡车耐久", "Lose %d truck durability"), ("eff_gold", "获得 %d 金币", "Gain %d gold"),
    ("eff_xp", "获得 %d 经验", "Gain %d XP"), ("eff_mat", "获得 %s ×%d", "Gain %s ×%d"),
    ("eff_ap", "获得 %d 行动力", "Gain %d action points"), ("eff_ap_lose", "失去 %d 行动力", "Lose %d action points"),
    ("eff_reveal", "观测周围 %d 格内的节点", "Scout the nodes within %d cells"), ("orb_n", "%s ×%d", "%s ×%d"),
    ("eff_battle", "一场艰难的战斗(胜利后额外掉落%s)", "A hard battle (extra loot on victory: %s)"),
    ("eff_none", "什么也不会发生", "Nothing happens"), ("eff_chance", "%d%%：%s", "%d%%: %s"),
    ("orb_gold", "金色晶球", "gold orb"), ("orb_blue", "蓝色晶球", "blue orb"), ("orb_white", "白色晶球", "white orb"),
    ("result", "结果", "Outcome"), ("continue", "继续", "Continue"), ("fight", "迎战", "Fight"),
    ("battle_banner", "事件战斗", "Event Battle")]:
    add("ui.event." + k, zh, en)
add("ui.err.event_requirement", "条件不满足", "Requirement not met")
# 事件战斗的专属战场(author_events.ARENAS)：名字 + 战场机制的说明(数值要和 ARENAS.hazards / author_chapters 的 TRAM_HIT、FIRE_ARC_HIT 对上，test_events 会查)
for k, zh, en in [
    ("arena.tram_stop.name", "电车站", "The Tram Stop"),
    ("arena.tram_stop.rule", "开战 6 秒后发第一班车，之后[b]每 13 秒一班[/b]：电车沿铁轨冲过整个战场(道口的红灯提前 3 秒亮起)。"
     "轨道上的单位[b]不分敌我[/b]都会被撞开，受到 [color=#ffd36b]20% 最大生命 + 120[/color] 点物理伤害，并【燃烧】4 秒。",
     "The first tram leaves 6 s into the battle, then [b]one every 13 s[/b]: it charges down the rails across the whole field (the crossing lights come on 3 s ahead). "
     "Anything on the track, [b]friend or foe[/b], is knocked aside, takes physical damage equal to [color=#ffd36b]20% of its max health + 120[/color] and 【Burns】 for 4 s."),
    ("arena.fountain_park.name", "公园喷泉", "The Park Fountain"),
    ("arena.fountain_park.rule", "开战 5 秒后喷泉第一次喷发，之后[b]每 9 秒一次[/b]：7 道火弧落在喷泉周围的落火点上。"
     "砸到的单位[b]不分敌我[/b]受到 [color=#ffd36b]80[/color] 点法术伤害，落火点重新烧成余烬地块。紧挨着喷泉的单位每秒被点燃。",
     "The fountain first erupts 5 s into the battle, then [b]every 9 s[/b]: seven arcs of fire land on the scorch marks around it. "
     "Anything they hit, [b]friend or foe[/b], takes [color=#ffd36b]80[/color] magic damage, and the scorch marks burn again as ember patches. Pieces right next to the fountain are set alight every second."),
    ("hazard.tram.label", "下一班电车", "Next tram"), ("hazard.tram.now", "电车进站", "Tram passing"),
    ("hazard.fountain.label", "喷泉喷发", "Eruption"), ("hazard.fountain.now", "喷发", "Erupting"),
    ("ui.arena.rule", "战场机制", "Battlefield rule")]:
    add(k, zh, en)
add("ui.err.event_choose", "先做出选择", "Make a choice first")
# 事件留下的局内状态(Run.flags，Events.FLAG_IDS)：名字 / 说明(%d = 数值) / 选项上的效果文字
for k, zh, en, dzh, den, gzh, gen in [
    ("next_battle_intensity", "风暴里的敌人", "Things in the Storm", "下一场作战的敌人强度 +%d", "Next battle: enemy intensity +%d",
     "诅咒：下一场敌人强度 +%d", "Curse: next battle's enemies +%d intensity"),
    ("shop_odds_shift", "祭坛的祝福", "The Altar's Blessing", "本章节点制造按高 %d 级的概率抽", "This chapter, fabrication rolls as if %d level higher",
     "祝福：本章节点制造按高 %d 级的概率抽", "Blessing: fabrication rolls as if %d level higher this chapter"),
    ("income_bonus", "旧友的人情", "An Old Friend's Favor", "本章每个节点的收入 +%d 金币", "This chapter, every node pays +%d gold",
     "祝福：本章每个节点的收入 +%d 金币", "Blessing: every node this chapter pays +%d gold")]:
    add("ui.flag.%s.name" % k, zh, en)
    add("ui.flag.%s.desc" % k, dzh, den)
    add("ui.flag.%s.gain" % k, gzh, gen)


# ------------------------------------------------------------------ 车间(装备制造)：三种材料 + 界面
for k, zh, en, dzh, den in [
    ("red", "燃素", "Phlogiston", "一团永不熄灭的火。投进车间，产物偏向红色系。", "A clump of fire that never goes out. In the workshop it pulls the result toward red."),
    ("green", "有机物", "Organic Matter", "一粒正在发芽的种子。投进车间，产物偏向绿色系。", "A seed in the middle of sprouting. In the workshop it pulls the result toward green."),
    ("blue", "液态负熵", "Liquid Negentropy", "装在矿泉水瓶里的负熵。投进车间，产物偏向蓝色系。", "Negentropy bottled like mineral water. In the workshop it pulls the result toward blue.")]:
    add("material.%s.name" % k, zh, en)
    add("material.%s.desc" % k, dzh, den)

for k, zh, en in [
    ("title", "车间", "Workshop"), ("subtitle", "用材料定向制造装备：配比决定颜色，用量决定稀有度", "Build gear from materials: the mix sets the color, the amount sets the rarity"),
    ("open", "车间", "Workshop"), ("materials", "车间材料", "Workshop materials"), ("open_hint", "点击打开车间(C)", "Click to open the workshop (C)"),
    ("tab_craft", "制造", "Fabricate"), ("tab_salvage", "分解", "Salvage"),
    ("kind.weapon", "武器", "Weapons"), ("kind.gear", "其他装备", "Other gear"), ("locked", "尚未开放", "Not yet"),
    ("step_kind", "装备种类", "Type"), ("step_cats", "门类", "Categories"), ("cats_hint", "至少选 %d 种 · 已选 %d 种", "Pick at least %d · %d picked"),
    ("cat_count", "%d 种", "%d items"), ("all", "全选", "All"), ("none", "清空", "Clear"), ("team", "按阵容", "Match team"),
    ("step_mats", "投入材料", "Materials"), ("owned", "持有 %d", "Have %d"), ("total", "合计", "Total"),
    ("total_hint", "至少 %d 份、最多 %d 份；投得越多越容易出高费装备", "%d to %d in total; the more you add, the pricier the result"),
    ("mix", "配比", "Mix"), ("mix_hint", "三角形里的位置 = 三种材料的配比；颜色 = 那个配比最可能造出的装备颜色", "The dot is your mix of the three materials; the shading is the gear color that mix most likely makes"),
    ("step_forecast", "产出预测", "Forecast"), ("color_odds", "颜色", "Color"), ("rarity_odds", "稀有度", "Rarity"), ("cost_n", "%d 费", "Cost %d"),
    ("items", "可能的产物", "Possible results"), ("items_more", "…另有 %d 种", "…and %d more"), ("craft", "制造", "Fabricate"),
    ("empty_forecast", "选好门类、投入材料后，这里会显示产出的概率", "Pick categories and add materials to see the odds here"),
    ("result", "制造完成", "Fabricated"), ("result_hint", "已放进武器库", "Sent to the Armory"), ("again", "继续", "Continue"),
    ("salvage_hint", "把用不上的武器拆成材料(装备在节点身上的要先卸下)", "Break unwanted weapons down into materials (unequip them first)"),
    ("salvage_empty", "武器库里没有武器", "The Armory is empty"), ("salvage_pick", "选一件武器", "Pick a weapon"),
    ("salvage_btn", "分解", "Salvage"), ("salvage_gain", "可得材料", "Yields"), ("salvaged", "分解完成：%s", "Salvaged: %s"),
    ("rules", "规则", "Rules"),
    ("rules_text", "◆ 产物只会是选中门类里的装备，所以至少要选 %d 种。\n"
                   "◆ [b]颜色[/b]看三种材料的[b]配比[/b]：燃素偏红、有机物偏绿、液态负熵偏蓝；两种对半偏向二次色(黄 / 紫 / 青)，三种均匀偏向无色(黑，谁都能装)。配比一点点变，概率也一点点变。\n"
                   "◆ [b]稀有度[/b]看材料的[b]总数[/b]：大约每多 7 份，平均费用 +1。\n"
                   "◆ 材料来自晶球(每个晶球附带 1~3 份)和分解武器。",
     "◆ The result is always gear from the chosen categories, so pick at least %d.\n"
     "◆ [b]Color[/b] follows the [b]mix[/b]: phlogiston leans red, organics green, negentropy blue; half-and-half leans to the secondary color (yellow / purple / cyan), "
     "an even three-way mix leans colorless (black — anyone can use it). A small change in the mix is a small change in the odds.\n"
     "◆ [b]Rarity[/b] follows the [b]total[/b]: roughly every 7 more materials adds +1 to the average cost.\n"
     "◆ Materials come from orbs (1–3 each) and from salvaging weapons.")]:
    add("ui.workshop." + k, zh, en)
for k, zh, en in [
    ("err.craft_locked", "这类装备还不能制造", "This kind of gear can't be made yet"), ("err.craft_categories", "门类选得不够", "Pick more categories"),
    ("err.craft_materials", "材料不够", "Not enough materials"), ("err.craft_too_few", "投入的材料太少", "Add more materials"),
    ("err.craft_too_many", "投入的材料太多", "Too many materials"), ("err.craft_nothing", "选中的门类里没有能造的装备", "Nothing in those categories can be made"),
    ("err.salvage_missing", "武器库里没有这件武器", "That weapon isn't in the Armory"), ("loot_material", "获得材料：%s", "Materials: %s")]:
    add("ui." + k, zh, en)

# 卡车改装(tools/author_mods.py → mods.json)：开局三选一的初始改装(规则见 game/sim/truck_layout.gd) + 第一批 12 个
import author_mods as _mods
_pc = lambda v: int(round(v * 100))
for k, zh, en, zd, ed in [
    ("powder_boost", "火药加量", "Extra Powder",
     "所有[b]远程节点[/b]的普攻伤害增幅 +25%。", "All [b]ranged[/b] Nodes deal +25% normal-attack damage."),
    ("weapon_calibration", "武器校准", "Weapon Calibration",
     "所有[b]远程节点[/b]暴击率 +%d%%、暴击伤害 +%d%%。" % (_pc(_mods.A_CRIT), _pc(_mods.A_CRIT)),
     "All [b]ranged[/b] Nodes gain +%d%% critical chance and +%d%% critical damage." % (_pc(_mods.A_CRIT), _pc(_mods.A_CRIT))),
    ("light_armor", "护甲轻量化", "Lightened Armor",
     "所有[b]近战节点[/b]攻击速度 +%d%%。" % _pc(_mods.B_ASPD), "All [b]melee[/b] Nodes attack %d%% faster." % _pc(_mods.B_ASPD)),
    ("hardened_alloy", "硬化合金", "Hardened Alloy",
     "所有[b]近战节点[/b]承受的伤害 -%d%%(最终减免)。" % _pc(_mods.C_DR), "All [b]melee[/b] Nodes take %d%% less damage (final reduction)." % _pc(_mods.C_DR)),
    ("arcane_basics", "魔力基础研究", "Arcane Fundamentals",
     "所有节点法术强度 +%d。" % _mods.D_AP, "All Nodes gain +%d ability power." % _mods.D_AP),
    ("anti_resist", "反抗性干扰", "Anti-Resistance Jamming",
     "所有敌人法术抗性 -%d。" % _mods.E_MR, "All enemies lose %d magic resistance." % _mods.E_MR),
    ("sharp_arms", "锐利武装", "Honed Arms",
     "所有武器的普攻倍率 +基础值的三分之一(普攻的触发数值 ×4/3，吃普攻倍率的效果一起受益)。",
     "Every weapon's normal-attack multiplier rises by a third of its base value (normal-attack trigger values ×4/3)."),
    ("arcane_growth", "魔力增长技巧", "Arcane Growth Technique",
     "战斗中，没有关键词[学习]的法典(法器武器的效果)获得[学习]。法典每有 1 层学习计数，从触发器处接收的触发数值 +%d%%。" % _pc(_mods.GROWTH_PER_LEARNING),
     "In battle, codices (focus-weapon payloads) without [Learning] gain [Learning]. Each learning count raises the trigger value a codex receives by %d%%." % _pc(_mods.GROWTH_PER_LEARNING)),
    ("time_management", "时间管理", "Time Management",
     "所有节点被动和装备效果的[叠加]数 +%d%%(向下取整，至少 +1)。" % _pc(_mods.STACK_BONUS_PCT),
     "The [Stacking] count of every Node passive and weapon effect rises by %d%% (rounded down, at least +1)." % _pc(_mods.STACK_BONUS_PCT)),
    ("pearl_field", "珠光力场", "Pearlescent Field",
     "[暴击]。所有节点的所有非持续伤害都获得暴击能力；本来就能暴击的可以再暴击一次。",
     "[Critical]. Every non-periodic damage dealt by Nodes can critically strike; damage that already could may crit a second time."),
    ("potent_dose", "强效药物", "Potent Dose",
     "开战时及之后每 %d 秒，所有节点下一次施加[叠加]状态时额外多叠 1 层。" % (_mods.DOSE_INTERVAL_FRAMES // 4),
     "At the start of battle and every %d s after, each Node's next [Stacking] status application adds one extra stack." % (_mods.DOSE_INTERVAL_FRAMES // 4)),
    ("cast_guard", "针对性保护", "Targeted Protection",
     "吟唱中的节点承受的伤害，%d%% 改由其他节点平均分摊(分摊的部分不吃护甲、护盾和减伤)。" % _pc(_mods.GUARD_SHARE),
     "%d%% of the damage a chanting Node takes is shared equally by the other Nodes (the shared part ignores armor, shields and reductions)." % _pc(_mods.GUARD_SHARE)),
    ("truck_zone", "机动工坊", "Mobile Workshop",
     "备战时卡车可以在初始部署区(9 × 6)内[b]移动[/b]或[b]旋转[/b]，部署区[b]跟着卡车一起[/b]移动 / 旋转，上面的节点也一起挪(卡车在部署区里的相对位置不变)。\n拖动卡车 = 移动；按 [b]T[/b] 或点「旋转卡车」= 顺时针转 90°。",
     "While preparing, the truck can [b]move[/b] or [b]rotate[/b] inside the initial deploy zone (9 × 6); the deploy zone [b]moves and rotates with it[/b], Nodes included (the truck keeps its place inside the zone).\nDrag the truck to move it; press [b]T[/b] or hit Rotate Truck to turn it 90°."),
    ("truck_free", "活动底盘", "Free Chassis",
     "备战时卡车可以在初始部署区(9 × 6)内[b]移动[/b]或[b]旋转[/b]，部署区[b]不动[/b]：卡车可以停到部署区的一侧，把另一侧整个让给节点(被卡车压住的节点会挪开)。\n拖动卡车 = 移动；按 [b]T[/b] 或点「旋转卡车」= 顺时针转 90°。",
     "While preparing, the truck can [b]move[/b] or [b]rotate[/b] inside the initial deploy zone (9 × 6); the zone [b]stays put[/b], so the truck can park on one side and leave the rest to your Nodes (Nodes under the truck step aside).\nDrag the truck to move it; press [b]T[/b] or hit Rotate Truck to turn it 90°."),
    ("truck_wide", "拓宽阵地", "Wider Ground",
     "卡车固定在正中央不能动，但初始部署区[b]上下左右各加 1 排[/b](11 × 8，共 82 格)。",
     "The truck stays parked in the middle, but the initial deploy zone grows by [b]one row on every side[/b] (11 × 8, 82 cells)."),
]:
    add("mod.%s.name" % k, zh, en)
    add("mod.%s.desc" % k, zd, ed)

for k, zh, en in [
    ("err.near_enemies", "只能部署在敌人身边一圈", "Can only be deployed right next to an enemy"),
    ("err.no_ap", "行动力不够", "Not enough action points"), ("err.unreachable", "去不了：中间隔着还没完成的节点", "Can't get there: an unfinished node is in the way"),
    ("err.no_refresh", "这次进店已经不能再刷新了", "No more refreshes on this visit"), ("err.parts_full", "零件箱满了", "The parts box is full"),
    ("err.truck_full", "卡车耐久是满的", "The truck is already at full durability"), ("err.locked", "尚未开放", "Not available yet"),
    ("ap", "行动力", "Action Points"), ("ap_en", "ACTION POINTS", "ACTION POINTS"), ("steps", "已走 %d 步", "%d steps taken"),
    ("ap_cost", "行动力 -%d", "AP -%d"), ("ap_here", "就在这里", "You are here"), ("ap_short", "行动力不够(需要 %d)", "Not enough AP (needs %d)"),
    ("ap_hunt", "行动力耗尽：追猎", "Out of AP: the Hunt"), ("ap_boss_dist", "离首领 %d 步", "%d steps to the boss"),
    ("map_unknown", "未观测", "Unobserved"), ("map_unknown.desc", "还看不清这里有什么。从已完成的节点走到它旁边就能看见。", "You can't make out what's here yet. Reach a finished node next to it to see."),
    ("map_cleared", "空地", "Clearing"), ("map_cleared.desc", "已经完成的节点：可以穿行，经过也要花行动力。", "A finished node: you may pass through, but passing still costs action points."),
    ("map_go", "点击前往", "Click to go"), ("map_reenter", "点击再次进入", "Click to enter again"), ("map_retry", "点击重新挑战", "Click to challenge again"),
    ("danger", "危险度", "Danger"), ("danger_weak", "普通", "normal"), ("danger_strong", "强怪", "strong"),
    ("parts", "零件", "Parts"), ("parts_en", "TRUCK PARTS", "TRUCK PARTS"), ("parts_empty", "零件箱是空的", "No parts"), ("part_pick", "选择目标格点(右键取消)", "Pick a target (right-click to cancel)"),
    ("part_use", "使用", "Use"), ("part_sell", "卖出 +%d", "Sell +%d"),
    ("rest_title", "修整", "Rest Stop"), ("rest_repair", "维修卡车", "Repair the Truck"), ("rest_repair.desc", "卡车耐久 +%d", "Truck durability +%d"),
    ("rest_upgrade", "强化节点", "Promote a Node"), ("rest_upgrade.desc", "把一个 1 星节点直接升到 2 星(本章最多 %d 费)", "Promote a 1-star Node straight to 2 stars (up to cost %d in this chapter)"),
    ("rest_none", "没有可以强化的 1 星节点", "No 1-star Node to promote"),
    ("event_title", "不期而遇", "Unexpected Encounter"), ("event_placeholder", "这里本该发生一些事……但事件还没有写。", "Something should happen here… but events are not written yet."),
    ("continue", "继续", "Continue"), ("leave", "离开", "Leave"), ("refresh_n", "刷新 %d", "Refresh %d"), ("sold_out", "已售出", "Sold"),
    ("shop_repair", "卡车维修 +%d", "Truck Repair +%d"), ("shop_weapons", "武器", "Weapons"), ("shop_parts_buy", "出售中的零件", "Parts for Sale"), ("shop_parts_sell", "回收你的零件", "Sell Your Parts"),
    ("mod_title", "卡车改装", "Truck Mod"), ("mod_hint", "进入下一章前给工坊卡车选一项改装：三选一里至少有一项是下一章的颜色；稀有度越高越少见", "Before the next chapter, pick one mod for the truck: at least one of the three matches the next chapter's color; higher rarities are rarer"),
    ("mods", "改装", "Mods"), ("mod_rarity", "稀有度 %d", "Rarity %d"), ("mod_none", "还没有改装", "No mods yet"),
    ("start_mod_title", "初始改装", "Starting Mod"), ("start_mod_hint", "出发前给工坊卡车选一项初始改装：决定备战时卡车能不能移动 / 旋转、部署区多大", "Before setting out, pick one starting mod for the truck: it decides whether the truck can move or turn while preparing, and how big the deploy zone is"),
    ("truck_rotate", "旋转卡车", "Rotate Truck"), ("truck_rotate_tip", "顺时针转 90°(T)；拖动卡车可以移动它(只能停在初始部署区内)", "Turn 90° clockwise (T); drag the truck to move it (it must stay inside the initial deploy zone)"),
    ("truck_hint", "拖动卡车可以移动它，按 T 旋转", "Drag the truck to move it, press T to rotate"),
    ("err.truck_fixed", "这辆卡车的改装不能移动卡车", "This truck's mod doesn't allow moving it"),
    ("branch_title", "选择路线", "Choose Your Route"), ("branch_hint", "下一章有三条分支", "The next chapter has three branches"), ("branch_locked", "尚未开放", "Coming soon"),
    ("over_next_layer", "下一层(第二章)尚未制作。", "The next layer (Chapter 2) is not made yet."),
    ("hunt_banner", "追猎！", "The Hunt!"), ("hunt_hint", "行动力耗尽，首领追上来了：赢下这场也算通过本章，下一章初始行动力 -1", "Out of action points — the boss has caught up. Winning still clears the chapter, but next chapter starts with 1 less AP"),
    ("burning_hint", "燃烧：负面状态，每秒受到 25 点法术伤害；每次施加独立计时(身上可以同时有好几个)；可驱散", "Burning: a debuff dealing 25 magic damage per second; every application is timed separately (several can stack up); dispellable"),
    ("intensity", "战斗强度", "Battle intensity"),
    ("terrain.burning", "燃烧废墟", "Burning Ruin"), ("terrain.burning.desc", "占格，不可通行。紧挨着它的棋子(敌我都算)每秒被施加一个 2 秒的【燃烧】。", "Blocks its cells. Pieces right next to it (both sides) gain a 2 s 【Burning】 every second."),
    ("terrain.ember", "余烬地块", "Embers"), ("terrain.ember.desc", "不占格。第一个踩上去的棋子【燃烧】5 秒，然后这块余烬熄灭、清空。", "Doesn't block. The first piece to step on it starts 【Burning】 for 5 s; then the embers go out for good."),
    ("terrain.ash", "死灰废墟", "Dead-Ash Ruin"), ("terrain.ash.desc", "占格，不可通行，没有其他效果。高的还挡远程视线与弹道。", "Blocks its cells; no other effect. Tall ones also block line of sight and projectiles."),
    ("terrain.ice", "坚冰", "Hard Ice"), ("terrain.ice.desc", "占格，不可通行，没有其他效果。高的还挡远程视线与弹道。", "Blocks its cells; no other effect. Tall ones also block line of sight and projectiles."),
    ("terrain.frost", "寒雾地块", "Frost"), ("terrain.frost.desc", "不占格。站在上面的棋子(敌我都算)每秒被施加一个 4.5 秒的【寒气】；一直站着，第 5 秒就会冻住。", "Doesn't block. Pieces standing in it (both sides) gain a 4.5 s 【Chill】 every second; linger and you freeze on the fifth second."),
    ("chill_hint", "寒气：负面状态，每个降低 10% 攻击速度；每次施加独立计时；身上的寒气合计超过 40% 时全部消耗，变为【冻结】5 秒(眩晕)；可驱散", "Chill: a debuff, each lowers attack speed by 10%; every application is timed separately; when the chill on a unit adds up to more than 40% it is all consumed and becomes 【Frozen】 for 5 s (a stun); dispellable"),
]:
    add("ui." + k, zh, en)

# ------------------------------------------------------------------ 测试场(标题画面「测试场」；平衡测试用的工具)
for k, zh, en in [
    ("arena", "测试场", "Test Range"), ("arena_title", "平衡测试场", "Balance Test Range"), ("arena_phase", "布阵", "Setting up"),
    ("arena_back", "返回标题", "To Title"),
    ("arena_tab_allies", "我方", "Allies"), ("arena_tab_enemies", "敌方", "Enemies"), ("arena_tab_test", "测试", "Test"),
    ("arena_star_add", "加入时的星级", "Star when added"), ("arena_auto_weapon", "自动装专属武器", "Auto-equip exclusive weapon"),
    ("arena_traits", "羁绊生效", "Traits on"),
    ("arena_hint_allies", "点头像加进仓库；拖到格子上直接上场。点场上 / 仓库里的棋子来改星级和武器(武器也可以从下面拖到棋子身上)。",
     "Click a portrait to add it to storage, or drag it onto a cell to deploy it. Click a node on the field or in storage to change its star and weapon "
     "(you can also drag a weapon onto a node)."),
    ("arena_selected", "选中的棋子", "Selected node"), ("arena_pick_hint", "点一个棋子来改星级 / 武器", "Click a node to change its star / weapon"),
    ("arena_on_board", "场上", "On the field"), ("arena_weapon", "武器", "Weapon"), ("arena_basic", "基础武器", "Basic"), ("arena_remove", "移除", "Remove"),
    ("arena_clear_allies", "清空我方", "Clear allies"),
    ("arena_hint_enemies", "点头像加一只怪(按方位出生)；拖到战场上的空地 = 放在那里；场上的怪也能拖着换位置。",
     "Click a portrait to add a monster (it spawns by direction); drag it onto open ground to place it there. Monsters on the field can be dragged too."),
    ("arena_random", "按战斗强度随机配怪", "Random monsters by intensity"), ("arena_kind_fight", "普通", "Normal"), ("arena_kind_elite", "精英", "Elite"),
    ("arena_kind_boss", "首领", "Boss"), ("arena_generate", "生成", "Generate"),
    ("arena_total", "怪物强度总值", "Total monster points"), ("arena_points", "%s 点", "%s pts"), ("arena_clear_enemies", "清空敌方", "Clear enemies"),
    ("arena_no_enemy", "先放几只怪", "Add some monsters first"),
    ("arena_map", "地图", "Map"), ("arena_map_terrain", "红之章地形", "Red terrain"), ("arena_map_flat", "空地", "Open ground"), ("arena_map_reroll", "换一张", "New map"),
    ("arena_count", "战斗场数", "Number of battles"), ("arena_start_one", "开始战斗", "Fight"), ("arena_start_many", "模拟 %d 场", "Simulate %d"),
    ("arena_sim_hint", "1 场 = 播放战斗画面；多场 = 无画面地模拟，打完给出胜率和每个单位的平均数据。",
     "1 battle = watch it play out; more = simulate without visuals, then show the win rate and per-unit averages."),
    ("arena_running_title", "运行中", "Running"), ("arena_running", "模拟中 %d / %d 场(胜 %d)", "Simulating %d / %d (won %d)"), ("arena_stop", "停止", "Stop"),
    ("arena_result", "模拟结果", "Results"), ("arena_winrate", "胜率", "Win rate"), ("arena_ci", "90%% 区间 %d%% ~ %d%%", "90%% range %d%% – %d%%"),
    ("arena_avg_time", "平均时长", "Avg time"), ("arena_avg_truck", "卡车受损", "Truck damage"), ("arena_avg_alive", "我方存活", "Allies left"),
    ("arena_avg_foes", "敌方存活", "Enemies left"), ("arena_dmg_head", "每场平均：输出 / 承伤 / 治疗 + 护盾", "Per battle: damage / taken / heal + shield"),
    ("arena_probe", "强度阈值测试", "Intensity Threshold Test"),
    ("arena_probe_hint", "用场上这套阵容从低往高打随机配怪(和游戏里普通作战同一套)，每个强度打到足以判断为止，胜率到 70% 算通过，给出最高通过的战斗强度。",
     "Takes the lineup on the field and fights random monsters (same generator as normal fights) from low to high intensity, as many battles as each step "
     "needs; 70% wins passes. Reports the highest intensity passed."),
    ("arena_probe_auto", "自动调站位", "Auto positions"), ("arena_probe_mine", "按我的摆放", "Keep my positions"),
    ("arena_probe_fast", "快速(每档最多 40 场)", "Quick (≤ 40 per step)"), ("arena_probe_full", "精确(每档最多 120 场)", "Precise (≤ 120 per step)"),
    ("arena_probe_start", "开始测试", "Run the test"), ("arena_probe_now", "强度 %d：%d / %d 胜(%s)", "Intensity %d: %d / %d won (%s)"),
    ("arena_probe_best", "最高通过强度", "Highest passed"), ("arena_probe_next_fail", "强度 %d 不通过", "Intensity %d failed"),
    ("arena_probe_fights", "共打了 %d 场", "%d battles in total"),
    ("arena_pass", "通过", "pass"), ("arena_fail", "不通过", "fail"), ("arena_edge", "边缘", "edge"),
    ("arena_deploy_front", "前压", "front"), ("arena_deploy_compact", "抱团", "huddle"), ("arena_deploy_guard", "护卫", "guard"),
    ("arena_deploy_mine", "我的摆放", "mine"),
]:
    add("ui." + k, zh, en)

# ------------------------------------------------------------------ 单位(节点：英文 Node+名词，中文 = 这个名词所做的"动作"+节点)
def _colon(text, zh):
    """技能说明的统一格式："[b]技能名[/b]：说明"。名字后面没冒号的自动补上；
    已经是"[b]名[/b]【关键词…】：说明"(关键词头之后有冒号)的保持原样；"[b]名[/b](续)说明"补在括号后面"""
    import re
    m = re.match(r'(\[b\][^\[]*\[/b\])(.*)$', text, re.S)
    if not m:
        return text
    head, rest = m.group(1), m.group(2)
    sep = "：" if zh else ": "
    if rest.startswith(("：", ":")) or rest.strip() == "":
        return text
    if re.match(r'\s*((?:【[^】]*】\s*)+)[：:]', rest):
        return text
    p = re.match(r'(\s*[（(][^）)]*[）)])(.*)$', rest, re.S)
    if p:
        tail = p.group(2)
        if tail.strip() == "" or tail.startswith(("：", ":")):
            return text
        return head + p.group(1) + sep + tail.lstrip()
    return head + sep + rest.lstrip()


def unit(id, zh, en, dzh, den, passives=None, note=None, normal=None, triggers=None):
    add("unit.%s.name" % id, zh, en)
    add("unit.%s.desc" % id, dzh, den)
    for aid, (pzh, pen) in (passives or {}).items():
        add("unit.%s.passive.%s" % (id, aid), _colon(pzh, True), _colon(pen, False))
    # 触发器的手写说明(有就代替卡片上自动拼的"每第 N 次…触发装备"句子；自动句子说不清的复合条件用它)
    for tid, (tzh, ten) in (triggers or {}).items():
        add("unit.%s.trigger.%s" % (id, tid), _colon(tzh, True), _colon(ten, False))
    if note:
        add("unit.%s.note" % id, note[0], note[1])
    if normal:
        add("unit.%s.normal" % id, normal[0], normal[1])


unit("node_archer", "速射节点", "Node Archer", "工程部的妹妹辈。擅长追击敌方最脆弱的部分，射击熟练到能连射出多发弩箭。",
     "A younger Engineering Department girl. She hunts the enemy's weakest link and shoots fast enough to loose several bolts in a row.",
     {"node_archer_rapid_fire_buff": ("[b]连射[/b]【叠加 3】：每发动 2 次普通攻击，获得 1 层【连射】。"
                                      "【连射】：持续 3 秒，每层攻击速度 +{★25%/45%/65%}；重复获得时刷新持续时间、效果叠加；可被驱散。",
                                      "[b]Rapid Fire[/b] 【Stacking 3】: every 2 normal attacks performed, gain 1 stack of Rapid Fire. "
                                      "Rapid Fire lasts 3 s; each stack grants +{★25%/45%/65%} attack speed; re-applying refreshes the duration and adds a stack; can be dispelled."),
      "node_archer_quick_reload": ("[b]快速装填[/b]：持用步枪时，装弹时间减半，每次装弹完成也获得 1 层【连射】。",
                                   "[b]Quick Reload[/b]: while holding a rifle, reload time is halved, and every completed reload also grants 1 stack of Rapid Fire.")},
     triggers={"node_archer_mod_arrowhead": ("[b]改装箭头[/b]：每第 3 次普通攻击命中，或步枪装弹后的第一次普通攻击命中时，对这次普攻的目标触发装备，触发数值 [color=#ffd36b]10[/color]。",
                                             "[b]Modified Arrowheads[/b]: every 3rd normal attack hit, or the first normal attack hit after a rifle reload, triggers the weapon on that attack's target (trigger value [color=#ffd36b]10[/color]).")})
unit("node_darkknight", "守誓节点", "Node Darkknight", "猫耳红发的少年骑士，安保部的誓约者。发誓为倒下的同伴复仇，也发誓守护一些最高洁而宝贵的东西。",
     "A red-haired, cat-eared boy knight — the Security Department's oathbound. He has sworn to avenge fallen comrades, and also to protect a few of the most precious things.",
     {"node_darkknight_vendetta": ("[b]誓血仇[/b]【觉醒：战斗中有队友被击杀】：每次普通攻击时，流失最大生命值的 10%，将这些生命值的 ×{★2.5/3.5/5} 倍化作伤害，附加在这次普通攻击上(物理伤害，打在这次普攻的目标身上；最多流失到剩 1 点生命)。"
                                   "会优先索敌造成那次击杀的敌人。",
                                   "[b]Blood Vendetta[/b] 【Awakening: an ally is killed in battle】: every normal attack drains 10% of his max health and adds {★2.5/3.5/5}× that much as damage to the attack "
                                   "(physical, on the attack's target; it never drains him below 1 health). He prioritizes the enemy that made that kill."),
      "node_darkknight_bind": ("[b]誓绶身[/b]【觉醒：战斗中，队伍里有稀有度 5 的棋子】【召唤】：战斗开始时，绑定最近的稀有度 5 的棋子。自身视为它的召唤物，并额外获得它的星级。"
                               "战斗中，它承受的所有普通攻击都无视距离转移到守誓节点身上(是真正的普攻事件：以普攻命中为条件、以普攻对象为目标的触发器在守誓节点身上触发)。",
                               "[b]Oath-bound Body[/b] 【Awakening: the team has a rarity-5 piece in battle】【Summon】: at the start of battle he binds to the nearest rarity-5 piece, "
                               "counts as its summon and gains its star level on top of his own. In battle, every normal attack it takes is moved to him regardless of distance "
                               "(as a real normal-attack event: on-hit triggers that target the attacked unit fire on him).")},
     triggers={"node_darkknight_oath_hour": ("[b]起誓之时[/b]：自身完成任意【觉醒】任务后触发。目标 = 自身，触发数值 = 最大生命值的 [color=#ffd36b]{★40%/50%/60%}[/color]。",
                                             "[b]Hour of the Oath[/b]: triggers whenever he completes any 【Awakening】 task. Target: himself; trigger value = [color=#ffd36b]{★40%/50%/60%}[/color] of his max health.")})
unit("node_gladiator", "狩胜节点", "Node Gladiator", "猫耳红发的角斗士，安保部的常胜者。被她盯上的猎物从来逃不掉——标枪先到，她紧随其后。",
     "A red-haired, cat-eared gladiator, the Security Department's undefeated champion. Nothing she marks as prey ever escapes — first the javelin, then her.",
     {"node_gladiator_throw": ("[b]必胜[/b]【暴击】：于备战阶段上场时，向武器库中添加专属物品【狩猎旗标】。"
                               "战斗开始时，向狩猎对象投掷手中的武器，造成攻击力 {★200%/250%/300%} 的物理伤害(视为普攻伤害)，然后立刻位移到目标身边。"
                               "场上存在狩猎对象时，只会以狩猎对象为索敌目标；否则将敌方本场战斗中至今为止造成伤害最多的存活单位设为狩猎对象(一样多时取攻击力 + 法术强度最高的，再一样取离她最近的)。"
                               "【狩猎旗标】：不可佩戴的特殊物品。拖到敌人身上，该敌人会被标记为狩猎对象，用完回到武器库；多个狩胜节点共用一个标记。",
                               "[b]Certain Victory[/b] 【Crit】: when she is put on the field during preparation, a 【Hunting Flag】 is added to the armory. "
                               "At the start of battle she hurls the weapon in her hands at her quarry for {★200%/250%/300%} of her attack as physical damage "
                               "(counts as normal-attack damage), then instantly closes in beside it. While her quarry is on the field she targets nothing else; "
                               "otherwise the living enemy that has dealt the most damage this battle becomes her quarry (on a tie, the one with the highest attack + ability power, then the nearest). "
                               "【Hunting Flag】: a special item that can't be worn. Drag it onto an enemy to mark it as the quarry; it returns to the armory afterwards. "
                               "Several Node Gladiators share one mark."),
      "node_gladiator_glory": ("[b]凯旋[/b]【叠加 10】：造成击杀时，获得 {★1/1/2} 层【光荣】；击杀狩猎对象时改为获得 {★3/3/6} 层。"
                               "【光荣】：可叠加，无限持续时间，不可驱散。每层使普攻物理伤害附带原伤害 10% 的魔法伤害。"
                               "达到 5 层时，免疫可驱散的负面状态。达到 8 层时，本应阵亡时改为失去 1 层【光荣】，并回复 25% 生命值。"
                               "达到 10 层时，如果再获得层数，会立刻对下一个狩猎对象发动【必胜】的投掷(攻击范围无限)。",
                               "[b]Triumph[/b] 【Stacking 10】: each kill grants {★1/1/2} stack(s) of 【Glory】; killing her quarry grants {★3/3/6} instead. "
                               "【Glory】: stacks, lasts forever, can't be dispelled. Each stack makes her physical normal-attack damage carry 10% of the original damage "
                               "as extra magic damage. At 5 stacks she is immune to dispellable negative effects. At 8 stacks, when she would die she loses one "
                               "stack instead and restores 25% of her health. At 10 stacks, gaining more makes her immediately hurl her weapon at the next quarry "
                               "as in 【Certain Victory】 (unlimited range).")},
     triggers={"node_gladiator_triumph": ("[b]我已得胜[/b]：造成击杀时触发。目标 = 自身，触发数值 = [color=#ffd36b]{★10/15/20}[/color] × 被击杀者的星级(精英视为 2 倍，首领视为 3 倍)。",
                                          "[b]I Have Won[/b]: triggers on every kill. Target: herself; trigger value = [color=#ffd36b]{★10/15/20}[/color] × the victim's star level "
                                          "(elites count double, bosses triple).")})
unit("node_basic", "空白节点", "Node Basic", "还什么都没写进去的空白节点。不会打架，也不会走路，好在不占位置——只是站在那里，就让大家都有点提不起劲。",
     "A blank node with nothing written into it yet. It can't fight and won't walk, but at least it takes no slot — it just stands there, and somehow everyone feels a little less motivated.",
     {"node_basic_slack": ("[b]摸鱼[/b]：战斗中，不进行普通攻击，不移动。空白节点不占用队伍上阵人数限制。",
                           "[b]Slacking Off[/b]: in battle it never performs normal attacks and never moves. Node Basic doesn't count toward the team's deploy limit."),
      "node_basic_drag": ("[b]拖后腿[/b]：每上阵一个空白节点，所有队友的伤害减免和伤害增幅降低 10%(可以为负数)。"
                          "(上阵 N 个空白节点时，每一个都让所有队友降低 N × 10%。)",
                          "[b]Dead Weight[/b]: for every Node Basic deployed, all teammates lose 10% damage reduction and 10% damage bonus (it can go negative). "
                          "(With N of them deployed, each one lowers every teammate by N × 10%.)")},
     triggers={"node_basic_survive": ("[b]能活下来就算成功[/b]：战斗结束时触发(倒下了就触发不了)。目标 = 自身，触发数值 = [color=#ffd36b]{★1/2/4}[/color]。",
                                      "[b]Surviving Counts as Success[/b]: triggers when the battle ends (not if it has fallen). Target: itself; trigger value = [color=#ffd36b]{★1/2/4}[/color].")})
unit("node_taoist", "清心节点", "Node Taoist", "绿发狐耳的小道士，福利部的符箓师。一张符清心安神，一张符叫人手脚发软——说是道法自然，其实全看她心情。",
     "A green-haired, fox-eared little Taoist, the Welfare Department's talisman master. One talisman calms the heart, another turns the enemy's limbs to jelly — 'following the Way', she says, though it's really just her mood.",
     {"node_taoist_qingxin_heal": ("[b]清心符[/b]：每 {★5/4/3} 秒，为一个队友治疗 {★150/220/320} 生命值，然后清除其身上至多 3 个可驱散的负面状态"
                                   "(优先负面状态较多的，其次当前生命较低的)。",
                                   "[b]Heart-Calming Talisman[/b]: every {★5/4/3} s, heals one teammate for {★150/220/320} health, then removes up to 3 "
                                   "dispellable negative effects from it (prefers the one with the most negative effects, then the one with the least current health)."),
      "node_taoist_weak_dmg": ("[b]弱体符[/b]【叠加 3】：每 {★4/4/3} 秒，对当前物理输出最高的敌人造成 {★60/60/100} 魔法伤害，然后施加一层【弱体】。"
                               "【弱体】：负面状态，可驱散，可叠加，持续 7 秒；每层攻击速度、攻击力 -7%。",
                               "[b]Enfeebling Talisman[/b] 【Stacking 3】: every {★4/4/3} s, deals {★60/60/100} magic damage to the enemy with the highest "
                               "physical output so far, then applies a stack of 【Enfeebled】. 【Enfeebled】: negative, dispellable, stacks, lasts 7 s; "
                               "each stack gives -7% attack speed and -7% attack.")},
     triggers={"node_taoist_daofa": ("[b]道法自然[/b]：发动任意被动技能时触发。目标 = 那个被动技能的目标，触发数值 [color=#ffd36b]10[/color]。",
                                     "[b]Follow the Way[/b]: triggers whenever she uses any passive skill. Target: that skill's target; trigger value [color=#ffd36b]10[/color].")})
unit("node_cowboy", "浪游节点", "Node Cowboy", "马耳绿发的浪游牛仔，情报部的跑腿。拔枪比谁都快，打不打得中另说——所以他总爱贴到对方脸上再开火。",
     "A green-haired, horse-eared wandering cowboy, the Information Department's errand runner. Nobody draws faster; hitting is another matter — so he likes to fire from right in your face.",
     {"node_cowboy_fastest": ("[b]开枪最快之人[/b]【叠加 6】：普攻间隔固定为 {★0.166/0.133/0.1} 秒，不受攻击速度影响。但是，手枪也需要换弹(1.5 秒)，"
                              "弹药数为本技能的叠加数。对距离超过 1 米的目标，普攻有 25% 概率打空，不造成任何伤害。",
                              "[b]Fastest Gun Alive[/b] 【Stacking 6】: his normal-attack interval is fixed at {★0.166/0.133/0.1} s and ignores attack speed. "
                              "But the gun still needs reloading (1.5 s), and the magazine holds as many rounds as this skill's stacks. Against targets more than "
                              "1 m away, each normal attack has a 25% chance to miss and deal no damage."),
      "node_cowboy_roam": ("[b]随心所欲[/b]：备战时可以被部署在战场上任何没有地形占着的格子，而不是只能在我方部署区内。",
                           "[b]As He Pleases[/b]: during preparation he can be deployed on any cell of the battlefield not taken by terrain, not just inside your deploy zone.")},
     triggers={"node_cowboy_loader": ("[b]装弹器[/b]：换弹时触发。目标 = 自身，触发数值 = 攻击力的 [color=#ffd36b]{★15%/25%/30%}[/color]。",
                                      "[b]Speedloader[/b]: triggers on reload. Target: himself; trigger value = [color=#ffd36b]{★15%/25%/30%}[/color] of his attack.")})
unit("node_samurai", "炽照节点", "Node Samurai", "墨绿长发、额上带疤的武士，安保部的斩恶之刃。刀很少离鞘——离鞘时，眼前的东西已经被斩开了好几道。",
     "A scarred samurai with long dark-green hair, the Security Department's blade against evil. His sword rarely leaves its sheath — and when it does, whatever stands before him has already been cut several times.",
     {"node_samurai_zhan": ("[b]斩恶[/b]【追击 {★2/3/4}】：普通攻击是一轮拔刀连斩，每次命中后再连斩 {★2/3/4} 下(每一下都是完整的普通攻击)，斩完收刀回鞘。",
                            "[b]Smite Evil[/b] 【Pursuit {★2/3/4}】: his normal attack is a drawing flurry — after each hit he cuts {★2/3/4} more times "
                            "(each one a full normal attack), then sheathes the blade."),
      "node_samurai_undying": ("[b]不灭[/b]【叠加 10】：造成普攻伤害时，为自身叠加一层【重燃】。"
                               "【重燃】：可叠加，可驱散，无持续时间。下次承受普攻伤害或技能伤害时(持续伤害不算)，每层回复 {★0/15/25} 点生命值，然后消耗全部层数。",
                               "[b]Undying[/b] 【Stacking 10】: whenever he deals normal-attack damage he gains a stack of 【Rekindle】. "
                               "【Rekindle】: stacks, can be dispelled, no duration. The next time he takes normal-attack or skill damage (not damage over time), he restores {★0/15/25} health "
                               "per stack, then all stacks are used up.")},
     triggers={"node_samurai_canguang": ("[b]残光[/b]：普通攻击(含追击)每命中一下，给目标叠一层【剑痕】。"
                                         "【剑痕】：可叠加(层数上限 = 不灭的【叠加】，1 星时视为 10)，可驱散的负面状态，持续 0.75 秒，重复叠加时刷新。"
                                         "到期或叠到上限时消耗并触发——每层各触发一次。目标 = 剑痕的持有者，"
                                         "触发数值 = 攻击力的 [color=#ffd36b]{★15%/20%/25%}[/color] × (100 + 引爆时的层数 × 5)%。",
                                         "[b]Afterglow[/b]: every normal-attack hit (pursuit included) leaves a stack of 【Sword Scar】 on the target. "
                                         "【Sword Scar】: stacks (up to Undying's 【Stacking】; 10 at 1★), a dispellable negative effect lasting 0.75 s, refreshed on each new stack. "
                                         "When it runs out or fills up it is used up and triggers — once per stack. Target: the scar's holder; "
                                         "trigger value = [color=#ffd36b]{★15%/20%/25%}[/color] of his attack × (100 + 5 × the stacks at the burst)%.")})
unit("node_hunter", "追猎节点", "Node Hunter", "绿毛的猴族弓手，工程部的野外调查员。开打之前他总要先蹲着记几页笔记——记完之后，对面的一举一动他都看得穿。",
     "A green-furred monkey archer, the Engineering Department's field surveyor. Before any fight he crouches to jot down a few pages of notes — and once they're done, he can read the enemy's every move.",
     {"node_hunter_notes": ("[b]猎人笔记[/b]【吟唱 6】：战斗开始时，找出本场威胁最高的敌人(有首领锁首领，有精英锁精英，否则按预估输出)，"
                            "花至多 6 秒准备与之战斗(站着不动、不攻击)。准备结束或被打断时，每准备了 1 秒，针对该敌人获得 {★10%/11%/11%} 普攻闪避率、"
                            "伤害增幅与百分比护甲穿透(闪避率最多 95%)。之后优先攻击它。",
                            "[b]Hunter's Notes[/b] 【Chant 6】: at the start of battle he picks out the most threatening enemy (the boss if there is one, "
                            "then an elite, otherwise the one with the highest expected damage) and spends up to 6 s preparing for it (standing still, "
                            "not attacking). When the preparation ends or is interrupted, for every second spent he gains {★10%/11%/11%} dodge chance against "
                            "its normal attacks, damage amplification and percent armor penetration against it (dodge capped at 95%). He targets it first afterwards."),
      "node_hunter_catch": ("[b]意外渔获[/b]：猎人笔记的准备没被打断时，准备结束时把那个敌人钓到面前，嘲讽它 3 秒，"
                            "并让所有攻击范围够得着它的队友把当前目标改成它。",
                            "[b]Unexpected Catch[/b]: if Hunter's Notes wasn't interrupted, when the preparation ends he reels that enemy in right in front of him, "
                            "taunts it for 3 s, and every teammate whose attack range reaches it switches its current target to it.")},
     triggers={"node_hunter_agile": ("[b]灵敏身法[/b]：猎人笔记的针对性闪避每成功闪开一次普攻时触发。目标 = 攻击者，触发数值 = [color=#ffd36b]{★100/150/200}[/color]。",
                                     "[b]Nimble Footwork[/b]: triggers every time Hunter's Notes' targeted dodge avoids a normal attack. "
                                     "Target: the attacker; trigger value = [color=#ffd36b]{★100/150/200}[/color].")})
unit("node_wizard", "巫术节点", "Node Wizard", "背着一对黑羽翼的鸦羽巫师，研究部的首席咒术师。咒文一句接一句念个不停，念完一段，天上就落下一阵七彩的飞弹。",
     "A black-winged raven wizard, the Research Department's chief spellwright. He chants one incantation after another — and every time one ends, a rain of rainbow missiles falls from the sky.",
     {"node_wizard_missiles": ("[b]虹光飞弹[/b]【增幅 {★2/2/3}】【吟唱 5】【追击 = 增幅 × 实际吟唱秒数，取整】：开局吟唱，每轮吟唱结束后立刻开始下一轮"
                               "(被打断时按已经吟唱的秒数施放，能行动后重新开始)。吟唱完成后施放一发魔法飞弹，并追加数发；每发飞弹先在天上飞一会儿，"
                               "分别全场随机锁定目标，造成法术强度 {★45%/110%/190%} 的伤害。颜色在红、蓝、绿、白之中随机：红 = 改为物理伤害，并施加 8 秒【燃烧】；"
                               "蓝 = 伤害 ×1.2(法术)；绿 = 改为瞄准队友，回复等量生命；白 = 改为真实伤害。",
                               "[b]Prismatic Missiles[/b] 【Amplify {★2/2/3}】【Chant 5】【Pursuit = Amplify × seconds actually chanted, rounded down】: he starts chanting "
                               "at the start of battle and begins the next chant the moment one ends (an interrupted chant still fires for the seconds chanted; he starts "
                               "again once he can act). When a chant completes he fires a magic missile plus the extra ones; each flies around the sky for a moment, "
                               "locks onto a random target anywhere on the field and deals {★45%/110%/190%} of his ability power. Each missile's color is random: "
                               "red = physical damage instead, plus an 8 s 【Burning】; blue = ×1.2 damage (magic); green = aims at a teammate instead and heals that much; "
                               "white = true damage instead."),
      "node_wizard_familiar": ("[b]黑羽使魔[/b]【召唤】(4 费：不用 2 星解锁)：自己造成普攻伤害、持续伤害、技能伤害、法术伤害、物理伤害、真实伤害、治疗时，"
                               "分别获得一种标记(同一种只算一个)。集齐其中六种时立刻全部消耗，召唤一只鸟。鸟最多同时存在 5 只。",
                               "[b]Black-Feathered Familiar[/b] 【Summon】 (rarity 4: no 2★ unlock needed): whenever he deals normal-attack, damage-over-time, skill, magic, "
                               "physical or true damage, or heals, he gains that kind of mark (one of each). As soon as he holds six different kinds, they are all used "
                               "up and he summons a bird. Up to 5 birds at once.")},
     triggers={"node_wizard_beak": ("[b]使魔之喙[/b]：自己的鸟普攻命中时触发。目标 = 鸟打的敌人，触发数值 = [color=#ffd36b]10[/color]。",
                                    "[b]Familiar's Beak[/b]: triggers whenever one of his birds lands a normal attack. Target: the enemy the bird hit; "
                                    "trigger value = [color=#ffd36b]10[/color].")})
unit("node_bird", "鸟", "Bird", "巫术节点召来的渡鸦使魔。羽毛蓝黑、眼睛像蓝宝石，脖子上挂着主人给的银项圈。它在天上看得见整个战场。",
     "A raven familiar summoned by Node Wizard — blue-black feathers, sapphire eyes, and the silver collar its master gave it. From the sky it sees the whole battlefield.",
     {"node_bird_bond": ("[b]脆弱使魔[/b]：生命值极低，移动速度很快；攻击力额外增加召唤者法术强度的 10%。视为持用双持近战武器(近战追击)。",
                         "[b]Fragile Familiar[/b]: very low health, very fast; its attack is increased by 10% of its summoner's ability power. "
                         "Counts as wielding dual melee weapons (melee pursuit)."),
      "node_bird_eye": ("[b]俯瞰黑瞳[/b]【叠加 3】：存活期间，为战场上所有队友维持 1 层【天空视野】(每只鸟只维持 1 层)。"
                        "【天空视野】：可叠加，不可驱散。每层使普攻伤害和技能伤害 + {★4/6/9} 点(固定值，加在原始伤害上)。",
                        "[b]Dark Eye Above[/b] 【Stacking 3】: while alive it keeps 1 stack of 【Sky Sight】 on every teammate on the field (one stack per bird). "
                        "【Sky Sight】: stacks, can't be dispelled. Each stack adds {★4/6/9} to normal-attack and skill damage (flat, added to the raw damage).")})
unit("node_tinker", "改修节点", "Node Tinker", "紫发的机械臂工匠，工程部的现场改装师。打着打着就把自己的枪拆了重装——下一个弹匣永远比上一个更合用。",
     "A purple-haired tinker with a brass mechanical arm, the Engineering Department's field modder. He strips and rebuilds his gun mid-fight — the next magazine always fits the job better than the last.",
     {"node_tinker_retrofit": ("[b]即时改装[/b]【叠加 3】：每 2 秒给自己附加一层【适应改造】；叠到 3 层后再叠加时，改为立刻连开两枪普通攻击(消耗子弹)。"
                               "【适应改造】：可叠加，不可驱散，无限持续。每层暴击率 +{★8%/10%/12%} × (100 + 法术强度)%。每次换弹时，"
                               "按对当前目标的预计伤害，让下一个弹匣改为造成物理或魔法伤害里更高的那种(自适应)。",
                               "[b]Field Refit[/b] 【Stacking 3】: every 2 s he gains a stack of 【Adaptive Retrofit】; once at 3 stacks, each further stack instead "
                               "fires two normal attacks on the spot (using up ammo). 【Adaptive Retrofit】: stacks, can't be dispelled, lasts forever. "
                               "Each stack: +{★8%/10%/12%} × (100 + ability power)% crit chance. On every reload he predicts the damage against his current target "
                               "and loads the next magazine with whichever of physical or magic damage would hit harder (adaptive)."),
      "node_tinker_finish": ("[b]成品完工[/b]：【适应改造】叠到 3 层或更多之后，之后所有弹匣造成的伤害改为真实伤害，并同时享受物理伤害和魔法伤害的加成"
                             "(伤害增幅、吸血都算两种)。之后层数降到 3 层以下也不会失效。",
                             "[b]Finished Product[/b]: once 【Adaptive Retrofit】 has reached 3 or more stacks, every magazine after that deals true damage and gets the bonuses "
                             "of both physical and magic damage (damage amplification and lifesteal of both kinds). Dropping below 3 stacks later doesn't undo it.")},
     triggers={"node_tinker_emergency": ("[b]应急道具[/b]：生命值低于 50% 时触发(最小间隔 3 秒)，触发时失去一层【适应改造】(没有就不触发)。"
                                         "目标 = 自身，触发数值 = [color=#ffd36b]{★200%/300%/400%}[/color] × (100 + 法术强度)。",
                                         "[b]Emergency Kit[/b]: triggers when his health is below 50% (at most once every 3 s), spending a stack of 【Adaptive Retrofit】 "
                                         "(no stack, no trigger). Target: himself; trigger value = [color=#ffd36b]{★200%/300%/400%}[/color] × (100 + ability power).")})
unit("node_astronaut", "星旅节点", "Node Astronaut", "蓝发的章鱼宇航员，维护部的星际巡检员。她扛着一面谁也不认识的星星的旗帜，从天而降——没人知道她真正的样子。",
     "A blue-haired octopus astronaut, the Maintenance Department's interstellar inspector. She falls from the sky carrying the flag of a star no one remembers — and no one knows what she really looks like.",
     {"node_astronaut_starfall": ("[b]渡星而来[/b]【溅射 2】：即使在仓库里也计入羁绊人数、享受羁绊加成。战斗开始时，如果她在仓库里且场上还没有星旅节点，"
                                  "就离开仓库、坠落在敌人最密集的地方(不占上阵人数；备战时会标出预计落点)，立刻获得 溅射范围内敌人数 × {★100/150/220} × (100 + 法术强度)% 的护盾，"
                                  "并对范围内的敌人各造成这个数值一半的法术伤害(没有主目标)。",
                                  "[b]From Across the Stars[/b] 【Splash 2】: counts toward traits and gets their bonuses even while in storage. At the start of battle, if she is in storage "
                                  "and there's no Node Astronaut on the field yet, she leaves storage and crashes down where the enemies are packed tightest (taking no deployment slot; "
                                  "the predicted landing spot is marked while preparing). She instantly gains a shield of enemies in Splash range × {★100/150/220} × (100 + ability power)%, "
                                  "and every enemy in range takes half that as magic damage (there is no main target)."),
      "node_astronaut_aura": ("[b]外神之貌[/b](4 费：不用 2 星解锁)：存活期间，持续嘲讽渡星而来溅射范围内的敌人，受她嘲讽的敌人每秒失去一个可驱散的非负面状态。"
                              "即将阵亡时，改为继续存活 {★2.5/3/4} 秒——期间无法被治疗、也无法被击杀，结束时必定死亡。",
                              "[b]Visage of the Outer God[/b] (rarity 4: no 2★ unlock needed): while alive she keeps every enemy within From Across the Stars' Splash range taunted, "
                              "and each enemy under her taunt loses one dispellable non-negative effect per second. When she would die, she instead lives on for {★2.5/3/4} s — "
                              "she can't be healed or killed during that time, and dies for certain when it ends.")},
     triggers={"node_astronaut_true_form": ("[b]真实形态[/b]：外神之貌锁血期间，每 {★0.5/0.4/0.25} 秒对渡星而来溅射范围内的所有敌人触发。"
                                            "触发数值 = 溅射范围内敌人数 × [color=#ffd36b]50[/color] × (100 + 法术强度)%。",
                                            "[b]True Form[/b]: while Visage of the Outer God holds her at death's door, triggers every {★0.5/0.4/0.25} s against every enemy in "
                                            "From Across the Stars' Splash range. Trigger value = enemies in Splash range × [color=#ffd36b]50[/color] × (100 + ability power)%.")})
unit("node_maid", "清扫节点", "Node Maid", "红发猫耳的女仆，工程部的清扫主管。怀表停下的那一瞬间，她已经把飞刀摆满了半空——等表针再走起来，屋子就干净了。",
     "A red-haired, cat-eared maid, the Engineering Department's head of cleaning. In the instant her pocket watch stops she has already filled the air with knives — and when the hands move again, the room is spotless.",
     {"node_maid_clock": ("[b]完美时计[/b]：暴击率 100%。自己发射的飞行道具(飞刀、子弹)先在半空中停住(停在自己和目标之间错落的位置)，"
                          "停住期间每秒伤害 +{★20%/45%/90%}。瞄准同一个敌人的所有飞行道具加起来足以击杀它时，一起继续飞行并造成伤害。"
                          "停住的飞行道具照样追踪目标，不会被躲开、也不会被掩体挡住；目标阵亡时，瞄准它的飞行道具随之消失；自己倒下时，停住的飞行道具掉落在地。",
                          "[b]Perfect Timepiece[/b]: 100% crit chance. Her projectiles (knives, bullets) first stop in mid-air (at staggered spots between her and the target) "
                          "and gain +{★20%/45%/90%} damage for every second they stay stopped. Once all the projectiles aimed at one enemy add up to enough to kill it, "
                          "they all resume flying and hit. Stopped projectiles still home in — they can't be dodged or blocked by cover; if the target dies, the ones "
                          "aimed at it vanish; if she falls, the stopped ones drop to the ground."),
      "node_maid_storm": ("[b]清洁世界[/b]【群攻 3】(4 费：不用 2 星解锁)：使用双持近战武器时，改为投掷飞刀进行远程攻击，射程与双持远程武器相同。"
                          "战斗开始时及之后每 10 秒，原地旋转着向全场不被掩体阻挡的数名敌人(不限射程，近的优先，至多【群攻】个)乱掷飞刀，"
                          "对每个敌人各发动 2 次普通攻击。",
                          "[b]Clean Sweep[/b] 【Multi Attack 3】 (rarity 4: no 2★ unlock needed): with dual melee weapons she throws knives instead, attacking at range — "
                          "the same range as dual ranged weapons. At the start of battle and every 10 s after, she spins on the spot, "
                          "flinging knives at several enemies anywhere on the field that aren't behind cover (no range limit, nearest first, up to the 【Multi Attack】 count), "
                          "making 2 normal attacks against each.")},
     triggers={"node_maid_guard": ("[b]女仆护身术[/b]：被拿近战武器的敌人近身时触发(同一个敌人走开后再靠近才算下一次)。"
                                   "目标 = 那个敌人，触发数值 = 攻击力 × 暴击伤害。",
                                   "[b]Maid's Self-Defense[/b]: triggers when an enemy with a melee weapon gets in close (the same enemy has to back off and come again to count again). "
                                   "Target: that enemy; trigger value = attack × crit damage.")})
unit("node_berserker", "狂猎节点", "Node Berserker", "狼耳的双刀少年，安保部的猎手。一闻到血味就扑进敌阵最密的地方，越是被逼到绝境越凶。",
     "A wolf-eared twin-blade boy, the Security Department's hunter. At the smell of blood he dives into the thickest crowd of enemies — and fights hardest when cornered.",
     {"node_berserker_hunt": ("[b]狼狩[/b]【群攻 3】【暴击】：攻击范围 +20%，拥有 10% 物理吸血。可用时自动发动(战斗开始时就可用，每场一次)："
                              "直线冲锋到落地后身边能砍到最多敌人的位置(无视碰撞)，立刻对身边一圈的敌人造成攻击力 ×{★4/4.5/5} 的物理伤害。",
                              "[b]Wolf Hunt[/b] 【Multi Attack 3】【Crit】: +20% attack range and 10% physical lifesteal. Fires automatically whenever available "
                              "(available at battle start, once per battle): dashes in a straight line (ignoring collision) to the spot where he can cut the most enemies, "
                              "then deals attack ×{★4/4.5/5} physical damage to the enemies around him."),
      "node_berserker_bloodlust": ("[b]血战[/b]每次击杀敌人后，重置【狼狩】和【再来一次】的可用次数；【狼狩】冲锋落地后，立刻嘲讽身边 2.6 米内的所有敌人 3 秒。",
                                   "[b]Blood Fury[/b] every kill resets the uses of 【Wolf Hunt】 and 【One More Time】; after Wolf Hunt lands he taunts every enemy within 2.6 m for 3 s.")},
     triggers={"node_berserker_once_more": ("[b]再来一次[/b]即将被击杀时触发(每场一次)：结算完之前不会倒下，结算完血量仍不够才倒下。"
                                            "目标 = 身边一圈的敌人(受武器效果的【群攻】限制)，触发数值 = 攻击力 ×[color=#ffd36b]{★3.5/4.5/5}[/color]。",
                                            "[b]One More Time[/b] triggers when he is about to be killed (once per battle): he can't fall until it has fully resolved, "
                                            "and only falls if his health still isn't enough afterwards. Targets: the enemies around him (limited by the weapon effect's 【Multi Attack】); "
                                            "trigger value = attack ×[color=#ffd36b]{★3.5/4.5/5}[/color].")})
unit("node_druid", "和星节点", "Node Druid", "长须的精灵德鲁伊，研究部的老前辈，也是初星们的监护人。只要他在，孩子们就不会出事。",
     "A long-bearded elf druid, a veteran of the Research Department and the guardian of the First Stars. As long as he's around, the kids will be fine.",
     {"node_druid_guardian": ("[b]初星的监护人[/b]【召唤】：战斗开始时，如果我方场上还没有护星节点，就召唤他(已经有了就把星级加给他)。"
                              "只要自己在场，所有友方初星系节点(会尝试召唤护星节点的棋子，以及护星节点)都保持【初星之光】："
                              "承受伤害时最终减免 {★15%/25%/33%}，对来自友军的伤害减免效能 ×3；不叠加、不可驱散。",
                              "[b]First Stars' Guardian[/b] 【Summon】: at battle start, summons Node Warrior if your side doesn't have one yet (otherwise adds his star level to him). "
                              "While he is on the field, every allied First-Star node (units that try to summon Node Warrior, and Node Warrior) keeps 【First-Star Light】: "
                              "{★15%/25%/33%} less final damage taken, three times as effective against damage from allies; doesn't stack, can't be dispelled."),
      "node_druid_wisdom_heal": ("[b]监护人的智与力[/b]【暴击】【增幅 2/2/4】：获得 增幅 × 10% 的治疗量加成(当前 {★20%/20%/40%})，以及等同于自身治疗量加成的暴击率。"
                                 "每 5 秒向生命值最低的敌人射出一支光箭，命中时造成 攻击力 × (100 + 法术强度)% 的物理伤害，"
                                 "然后为当前血量最少的非满血队友回复等量生命。",
                                 "[b]Guardian's Wisdom and Strength[/b] 【Crit】【Amplify 2/2/4】: gains Amplify × 10% healing bonus (now {★20%/20%/40%}) and crit chance equal to "
                                 "his total healing bonus. Every 5 s he shoots a light arrow at the enemy with the lowest health; on hit it deals attack × (100 + ability power)% "
                                 "physical damage, then heals the teammate with the least current health (not at full) for the same amount.")},
     triggers={"node_druid_smile_start": ("[b]监护人的微笑[/b]开局及其后每 3 秒触发一次。目标 = 全体友方初星系节点，"
                                          "触发数值 = 攻击力 × (100 + 法术强度)% × [color=#ffd36b]{★100%/180%/220%}[/color]。",
                                          "[b]Guardian's Smile[/b] triggers at the start of the battle and every 3 s after. Targets: every allied First-Star node; "
                                          "trigger value = attack × (100 + ability power)% × [color=#ffd36b]{★100%/180%/220%}[/color]."),
               "node_druid_smile": ("[b]监护人的微笑[/b](每 3 秒的那几次，同上)", "[b]Guardian's Smile[/b] (the every-3-seconds part, same as above)")})
unit("node_witch", "灾星节点", "Node Witch", "猫耳的魔女，研究部的禁术研究员。她召来的流星不分敌我，所以总拿护星节点当靶子。",
     "A cat-eared witch, the Research Department's forbidden-arts researcher. Her meteors don't care whose side you're on — so she keeps using Node Warrior as the target.",
     {"node_witch_star": ("[b]初星的魔女[/b]【召唤】：战斗开始时，如果我方场上还没有护星节点，就召唤他(已经有了就把星级加给他)。"
                          "她无法移动，但能无视攻击距离和掩体，攻击任何队友射程内的敌人；普攻从天上召唤火流星，伤害按法术强度计算(来自模版的攻击力 1:1 转成了法术强度)。"
                          "拿法器时普攻照常【溅射】，拿双手长武器时每一下都是【群攻 2】。",
                          "[b]First-Star Witch[/b] 【Summon】: at battle start, summons Node Warrior if your side doesn't have one yet (otherwise adds her star level to him). "
                          "She can't move, but ignores attack range and cover to strike any enemy within any teammate's attack range; her normal attacks call down "
                          "fire meteors and scale with ability power (her template attack is converted 1:1 into ability power). With a focus they 【Splash】 as usual; "
                          "with a two-handed long weapon every attack is 【Multi Attack 2】."),
      "node_witch_fire": ("[b]魔女的火与冰[/b]不能装备【双模】武器，但可以装备红色武器。装备红色武器时，伤害类行动每以【溅射】或【群攻】命中一个目标，"
                          "最终伤害 +{★8%/8%/15%}(友方目标算 2 个)。装备蓝色武器时，施加的【叠加】状态额外多叠 {★1/1/2} 层。",
                          "[b]Witch's Fire and Ice[/b] can't equip 【Dual Mode】 weapons, but can equip red ones. With a red weapon, each target a damaging action hits "
                          "through 【Splash】 or 【Multi Attack】 adds {★8%/8%/15%} final damage (allies count as 2). With a blue weapon, 【Stacking】 statuses she applies "
                          "gain {★1/1/2} extra stacks.")},
     triggers={"node_witch_smile": ("[b]魔女的笑与泪[/b]每 5 秒触发一次。以 6 米内人最多的召唤物队友为中心，6 米内的所有人(不分敌我，不含自己)为目标"
                                    "(受武器效果的【群攻】限制，中心的队友本人最优先)，触发数值 = 法术强度 ×[color=#ffd36b]{★1.3/2.25/3.2}[/color]。"
                                    "没有召唤物队友时，改以非召唤物队友为中心，触发数值减为三分之一。",
                                    "[b]Witch's Smile and Tears[/b] triggers every 5 s. Centered on the summoned teammate with the most people within 6 m, it targets everyone "
                                    "within 6 m (friend or foe, not herself; limited by the weapon effect's 【Multi Attack】, the center teammate first); trigger value = "
                                    "ability power ×[color=#ffd36b]{★1.3/2.25/3.2}[/color]. With no summoned teammate, a non-summoned teammate becomes the center and the value drops to a third.")})
unit("node_dancer", "舞星节点", "Node Dancer", "初生的偶像，一位舞蹈师。和她的护星节点一起守在前线，笑着为队友伴舞，含着泪也要把舞跳完。",
     "A newborn idol and dancer. She holds the front with her Node Warrior, dancing for her allies with a smile — and finishing the dance through tears.",
     {"node_dancer_idol": ("[b]初星的偶像[/b]【召唤】：战斗开始时，如果我方场上还没有护星节点，就召唤他；已经有了，就把自己的星级加给他(他同时算所有尝试召唤他的人的召唤物)。",
                           "[b]First-Star Idol[/b] 【Summon】: at battle start, summons Node Warrior if your side doesn't have one yet; if it does, she adds her star level to him "
                           "(he counts as the summon of everyone who tries to summon him)."),
      "node_dancer_dance": ("[b]偶像的舞与歌[/b]【增幅 2/2/4】：使用双持武器时，开战后立刻拉着护星节点向前冲刺 3.5 米，然后护星节点获得 增幅 × 5% 的伤害减免"
                            "(当前 {★10%/10%/20%})，并嘲讽 5 米内的所有敌人 4 秒。攻击距离大于 2 米时，所有队友获得每点增幅 {★6%/8%/10%} 的攻击速度和攻击力。",
                            "[b]Idol's Dance and Song[/b] 【Amplify 2/2/4】: with twin blades, right after the battle starts she dashes 3.5 m forward pulling Node Warrior along; "
                            "he then gains Amplify × 5% damage reduction (now {★10%/10%/20%}) and taunts every enemy within 5 m for 4 s. "
                            "With attack range over 2 m, all teammates gain {★6%/8%/10%} attack speed and attack per point of Amplify.")},
     triggers={"node_dancer_smile": ("[b]偶像的笑与泪[/b]发动普通攻击时触发。血量高于 50%：目标 = 所有队友(受武器效果的【群攻】限制，攻击力高的优先)，"
                                     "触发数值 = (舞与歌的增幅 + 1) × 10 = [color=#ffd36b]{★10/30/50}[/color](1 星时增幅视为 0)。",
                                     "[b]Idol's Smile and Tears[/b] triggers on each normal attack performed. Above 50% health: targets all teammates (limited by the weapon effect's "
                                     "【Multi Attack】, highest attack first); trigger value = (Dance and Song's Amplify + 1) × 10 = [color=#ffd36b]{★10/30/50}[/color] (Amplify counts as 0 at 1★)."),
               "node_dancer_tears": ("[b]偶像的笑与泪[/b](续)血量不高于 50%：目标 = 当前索敌目标，触发数值 = 攻击力 × 0.15 × (增幅 + 1) = 攻击力 × [color=#ffd36b]{★0.15/0.45/0.75}[/color]。",
                                     "[b]Idol's Smile and Tears[/b] (cont.) at 50% health or below: targets her current target; trigger value = attack × 0.15 × (Amplify + 1) = "
                                     "attack × [color=#ffd36b]{★0.15/0.45/0.75}[/color].")})
unit("node_warrior", "护星节点", "Node Warrior", "舞星节点的护卫。永远站在偶像身前，替她挡下一切。",
     "Node Dancer's guardian. He always stands in front of his idol and takes every blow for her.",
     None, ("[b]初星的剑与盾[/b]同时算作所有尝试召唤他的舞星节点的召唤物：从每一位那里获得星级(相加)，最多 9 星，4 星以上每星提升更多。"
            "不享受羁绊，不能更换武器，不进入卡池。",
            "[b]First Star's Sword and Shield[/b] counts as the summon of every Node Dancer who tries to summon him: he gains star levels from each of them (added up), "
            "up to 9★, and each star above 4 gives more. No traits, can't change weapons, not in the shop pool."))
unit("node_nurse", "护理节点", "Node Nurse", "红发精灵耳的小护士，福利部的看护员。她的针剂瞄准的永远是伤得最重的那个人——被她护理的人会受一整个部门的羡慕。",
     "A red-haired, elf-eared little nurse from the Welfare Department. Her syringe always aims at whoever is hurt the worst — and whoever she cares for is envied by a whole department.",
     {"node_nurse_general_care": ("[b]广义治疗[/b]：普通攻击索敌友方当前生命值最低的非满血目标(队友都满血时才攻击敌人)；"
                                  "对友方本应造成普攻伤害时，改为根据其最终伤害值的 {★110%/120%/130%} 提供相应的治疗量"
                                  "(最终伤害值只计算暴击、增伤、易伤这些提升伤害的效果，不计算护甲、魔抗等任何减少伤害的效果)。"
                                  "\"对友方\"意味着：法器普攻的溅射中，溅射到敌人的那部分不会被转化为治疗。",
                                  "[b]Care in the Broad Sense[/b]: normal attacks target the ally with the lowest current health that isn't at full "
                                  "(she only attacks enemies when every teammate is at full health). Normal-attack damage that would hit an ally "
                                  "heals it instead for {★110%/120%/130%} of that damage's final value (final value counts only what raises damage — "
                                  "crits, damage bonuses, vulnerability — never armor, magic resistance or any other reduction). \"An ally\" means: "
                                  "the part of a focus splash that lands on enemies is not turned into healing."),
      "node_nurse_one_on_one": ("[b]一对一看护[/b]【充能 2】：冷却 5 秒。为具有负面状态的队友提供治疗时，驱散其所持有的持续时间最长的 {★1/1/3} 个可驱散负面状态。"
                                "对无负面状态的队友不触发(不消耗充能)。",
                                "[b]One-on-One Care[/b] 【Charged 2】: 5 s cooldown. When she heals a teammate that has negative effects, dispels its "
                                "{★1/1/3} dispellable negative effect(s) with the longest remaining duration. Doesn't trigger on teammates without "
                                "negative effects (no charge is spent).")},
     triggers={"node_nurse_potion_fill": ("[b]药水填充[/b]：每第 3 次普通攻击时触发。目标 = 这次普攻的对象(队友或敌人)，触发数值 = 攻击力的 [color=#ffd36b]{★150%/175%/200%}[/color]。",
                                          "[b]Potion Refill[/b]: triggers on every 3rd normal attack. Target: that attack's target (teammate or enemy); "
                                          "trigger value = [color=#ffd36b]{★150%/175%/200%}[/color] of her attack.")})
unit("node_peasant", "耕植节点", "Node Peasant", "牛耳的农家少女，扛着钉耙下田的维护部成员。越挨打越有干劲。",
     "A cow-eared farm girl from the Maintenance Department who takes her rake into the fields. The harder she's hit, the harder she works.",
     {"node_peasant_hardwork": ("[b]吃苦耐劳[/b]【叠加 5】：承受普通攻击时获得 1 层【吃苦耐劳】。【吃苦耐劳】：持续 2 秒，每层受到的普通攻击伤害 -{★15/16/18}；"
                                "重复获得时刷新持续时间、效果叠加；可被驱散。",
                                "[b]Hard Work[/b] 【Stacking 5】: taking a normal attack grants 1 stack of Hard Work. Hard Work lasts 2 s; each stack reduces normal attack damage taken by {★15/16/18}; "
                                "re-applying refreshes the duration and adds a stack; can be dispelled."),
      "node_peasant_toughness": ("[b]韧性[/b]【吃苦耐劳】每层额外每秒回复 {★0.1%/0.1%/0.15%} 最大生命(每层每 0.75 秒各回复一次)。",
                                 "[b]Grit[/b] each stack of Hard Work also restores {★0.1%/0.1%/0.15%} max health per second (each stack heals separately every 0.75 s).")},
     triggers={"node_peasant_harvest": ("[b]收获时刻[/b]生命首次低于 50% 时触发。目标 = 自身，触发数值 = 自身最大生命的 [color=#ffd36b]20%[/color]。",
                                        "[b]Harvest Time[/b] triggers the first time her health drops below 50%. Target: herself; trigger value = [color=#ffd36b]20%[/color] of her max health.")})
unit("node_student", "求知节点", "Node Student", "戴眼镜、顶着光环的研究部学生。一边念一边记，念错了也照样生效，学得越多越强。",
     "A bespectacled Research Department student with a halo. She reads spells aloud while taking notes; even the garbled ones work, and she grows with everything she learns.",
     {"node_student_study": ("[b]学力增长中[/b]【永恒】：每场战斗结束后(中途倒下也算)，永久获得 1 + 所携带武器本场学习计数 ×{★1/1/2} 点法术强度"
                             "(携带没有【学习】的武器也有保底的 1 点)。3 星的倍数不追溯 3 星之前的成长；升星时取三份材料里最高的那份。",
                             "[b]Still Studying[/b] 【Eternal】: after every battle (even if she fell), permanently gains 1 + her weapon's learning count this battle ×{★1/1/2} "
                             "ability power (a weapon without 【Learning】 still gives the minimum 1). The 3★ multiplier doesn't apply retroactively; "
                             "when she stars up she keeps the highest of the three copies."),
      "node_student_bombard": ("[b]知识轰炸[/b]普通攻击造成法术伤害，且每点法术强度使普通攻击伤害 +{★1%/1%/1.5%}。",
                               "[b]Knowledge Bombardment[/b] normal attacks deal magic damage, and each point of ability power adds {★1%/1%/1.5%} normal attack damage.")},
     triggers={"node_student_recite": ("[b]把咒语念出来！[/b]每 3 秒触发一次。目标 = 当前索敌目标，触发数值 = [color=#ffd36b]{★370/560/580}[/color] × (100 + 法术强度)%。",
                                       "[b]Read It Out Loud![/b] triggers every 3 s. Target: her current target; trigger value = [color=#ffd36b]{★370/560/580}[/color] × (100 + ability power)%.")})
unit("node_shielder", "架盾节点", "Node Shielder", "鼠耳的维护部少女，扛着比自己还高的防暴盾。遇到危险第一反应是缩到盾后面。",
     "A mouse-eared Maintenance Department girl hauling a riot shield taller than herself. Her first instinct in danger is to duck behind it.",
     {"node_shielder_shield_charge": ("[b]护盾充能[/b]【增幅 1/2/3】：以 {★50/100/150} 点护盾开始战斗，此后每秒获得 {★10/20/30} 点护盾。",
                                      "[b]Shield Charge[/b] 【Amplify 1/2/3】: starts the battle with {★50/100/150} shield, then gains {★10/20/30} shield every second."),
      "node_shielder_turtle": ("[b]鼠鼠缩头！[/b]没有护盾时缩到盾后面：不移动、不普通攻击，但基础防御 +{★20/20/40}，来自护盾充能的护盾翻倍。"
                               "持续到护盾超过 100 为止，一旦开始至少持续 5 秒。",
                               "[b]Mouse Mode![/b]: with no shield left she ducks behind the shield — no moving, no normal attacks, but base defense +{★20/20/40} "
                               "and Shield Charge gives double. Lasts until her shield exceeds 100, and at least 5 s once started.")},
     triggers={"node_shielder_my_shield": ("[b]盾，我的盾！[/b]护盾破碎时触发。目标 = 自身与周围一圈的敌人(受武器效果的【群攻】限制，自身最优先)，触发数值 [color=#ffd36b]{★25/50/75}[/color]。",
                                           "[b]My Shield![/b]: triggers when her shield breaks. Targets: herself and the enemies around her (limited by the weapon effect's 【Multi Attack】, herself first), trigger value [color=#ffd36b]{★25/50/75}[/color].")})
unit("node_magi", "幻彩节点", "Node Magi", "淡紫双马尾的魔法少女，安保部的现场画师。她挥一下镰刀就换一种颜色——颜料用完的那一刻，世界只剩下黑白。",
     "A lilac twin-tailed magical girl, the Security Department's field painter. Every swing of her scythe changes the color — and the moment the paint runs out, the world turns black and white.",
     {"node_magi_colors": ("[b]闪耀色彩[/b]【充能 9】：开战时充能全满。攻击间隔大幅延长(2.4 秒一次)。还有充能时，每造成一次伤害消耗 1 层充能，获得对应的【颜料】："
                           "造成物理伤害 → 【蓝色颜料】，造成魔法伤害 → 【红色颜料】。"
                           "【红色 / 蓝色颜料】：不可叠加，不可驱散。提供 (200 + 2 × 法术强度 + {★0/50/100})% 的物理 / 魔法伤害增幅，并把下一次伤害强制转换成物理 / 魔法伤害；"
                           "那一次伤害结算时消耗颜料。",
                           "[b]Shining Colors[/b] 【Charged 9】: starts the battle fully charged. Her attack interval is greatly lengthened (one every 2.4 s). While charges remain, "
                           "each instance of damage she deals spends 1 charge and gives her the matching 【Paint】: physical damage → 【Blue Paint】, magic damage → 【Red Paint】. "
                           "【Red / Blue Paint】: doesn't stack, can't be dispelled. Grants (200 + 2 × ability power + {★0/50/100})% physical / magic damage amplification "
                           "and forces her next damage to become physical / magic; that damage uses up the paint."),
      "node_magi_finale": ("[b]少女幻终[/b]【吟唱 9】【溅射 5】：闪耀色彩的充能归零时开始吟唱。吟唱期间持续嘲讽溅射范围内的敌人，获得 80% 伤害减免，"
                           "每 0.25 秒对溅射范围内所有其他人(不分敌我)造成 攻击力 × {★0.3/0.3/0.45} × (10 + 0.1 × 法术强度)% 的真实伤害。"
                           "吟唱结束后，对溅射范围内所有其他人造成 攻击力 × {★0.3/0.3/0.45} × (500 + 5 × 法术强度)% × 实际吟唱秒数 的真实伤害，然后强制阵亡。",
                           "[b]A Girl's Grand Finale[/b] 【Chant 9】【Splash 5】: when Shining Colors runs out of charges, she starts chanting. While chanting she keeps every enemy "
                           "in Splash range taunted, takes 80% less damage, and every 0.25 s deals attack × {★0.3/0.3/0.45} × (10 + 0.1 × ability power)% true damage to "
                           "everyone else in Splash range (friend or foe). When the chant ends she deals attack × {★0.3/0.3/0.45} × (500 + 5 × ability power)% × seconds actually "
                           "chanted as true damage to everyone else in Splash range, then falls.")},
     triggers={"node_magi_paint": ("[b]颜料[/b]：普通攻击造成伤害时触发。目标 = 身边一圈的敌人(受【群攻】限制)，"
                                   "触发数值 = 攻击力 × [color=#ffd36b]{★0.8/1/1.2}[/color] × (100 + 法术强度)%。",
                                   "[b]Paint[/b]: triggers when her normal attack deals damage. Targets: the enemies around her (limited by 【Multi Attack】); "
                                   "trigger value = attack × [color=#ffd36b]{★0.8/1/1.2}[/color] × (100 + ability power)%.")})
unit("node_runner", "迅游节点", "Node Runner", "紫色刺头、圆鼠耳的跑者，情报部跑得最快的那个。他从不停下来——停下来的时候，大概已经有人被踢飞了。",
     "A spiky-haired, round-eared runner with violet hair — the fastest legs in the Information Department. He never stops; by the time he does, someone has already been kicked across the field.",
     {"node_runner_lightning": ("[b]闪电跑者[/b]：移动时可以穿过地形和其他人。攻击力按比例转化为移动速度：每 1 秒，移动速度提升 攻击力 × {★0.03%/0.05%/0.07%}(一直累加)。",
                                "[b]Lightning Runner[/b]: passes through terrain and other units while moving. Attack converts into move speed: every second, "
                                "move speed rises by attack × {★0.03%/0.05%/0.07%} (keeps adding up)."),
      "node_runner_kick": ("[b]飞身踢[/b]【暴击】：持续移动，始终以最远的敌人为索敌目标。跑到目标面前时对它发动攻击，造成 攻击力 × (100 + 法术强度)% × (路程 / 6 米)^1.5 的物理普攻伤害"
                           "(路程 = 两次攻击之间跑过的距离：跑得越远，每米加得越多)，然后重新索敌并折返向新目标。下一个目标不到 3 米远(只剩一个敌人 / 敌人挤在一起)时，先去卡车借力再折返。",
                           "[b]Flying Kick[/b] 【Crit】: keeps moving and always targets the farthest enemy. On reaching it he attacks, dealing attack × (100 + ability power)% × "
                           "(distance / 6 m)^1.5 physical normal-attack damage (distance = how far he ran since the last attack: the farther, the more each meter adds), "
                           "then picks a new target and doubles back. If the next target is under 3 m away (only one enemy left, or they're bunched up), he springs off the truck first.")},
     triggers={"node_runner_shoe": ("[b]别粘我鞋底上[/b]：飞身踢造成伤害时触发。目标 = 被踢的敌人，触发数值 = 攻击力 × (100 + 法术强度)% × (路程 / 6 米)^1.5(与这一脚相同)。",
                                    "[b]Don't Stick to My Soles[/b]: triggers when Flying Kick deals damage. Target: the enemy kicked; trigger value = attack × (100 + ability power)% × "
                                    "(distance / 6 m)^1.5 (same as the kick).")})
unit("node_spy", "幻形节点", "Node Spy", "银白长波浪发、一身黑西装的情报部特工。她总是站在敌人身边——等你认出她的时候，你已经在对着自己人挥刀了。",
     "A silver-haired agent in a black suit from the Information Department. She always stands right beside the enemy — by the time you recognize her, you're already swinging at your own side.",
     {"node_spy_shift": ("[b]千变万化[/b]【充能 9】：开战时充能全满。只能部署在任意敌人周围一圈的格子上(取代正常的部署区)。"
                         "被敌人索敌且还有充能时，消耗 1 层充能，给那个敌人施加【误导】。"
                         "【误导】：可驱散，不可叠加，负面状态，持续 4 秒。立刻取消当前索敌，强制改为索敌它自己的一个队友(自相残杀)。精英与首领免疫自相残杀，但依旧会重新索敌。",
                         "[b]Thousand Faces[/b] 【Charged 9】: starts the battle fully charged. Can only be deployed on the cells around an enemy (instead of the usual deployment zone). "
                         "When an enemy targets her while she has charges, she spends 1 charge to put 【Misled】 on that enemy. "
                         "【Misled】: dispellable, doesn't stack, debuff, lasts 4 s. Drops its current target at once and is forced to target one of its own allies (friendly fire). "
                         "Elites and bosses are immune to the friendly fire but still pick a new target."),
      "node_spy_hush": ("[b]少女幻嘘[/b]【吟唱 9】【溅射 5】：千变万化的充能归零时开始吟唱。吟唱期间对溅射范围内所有人(不分敌我)维持【误导】。"
                        "吟唱结束后，对溅射范围内所有人施加【眩晕】，持续 实际吟唱秒数 × {★30%/30%/50%} 秒，然后强制阵亡。"
                        "【眩晕】：可驱散，不可叠加，负面状态。无法移动、无法攻击，打断吟唱，“每 x 秒”的触发器暂停计时。精英与首领从眩晕中恢复的速度加倍。",
                        "[b]A Girl's Grand Hush[/b] 【Chant 9】【Splash 5】: when Thousand Faces runs out of charges, she starts chanting. While chanting she keeps everyone "
                        "in Splash range (friend or foe) 【Misled】. When the chant ends she puts everyone in Splash range to 【Stun】 for seconds actually chanted × {★30%/30%/50%}, then falls. "
                        "【Stun】: dispellable, doesn't stack, debuff. Can't move or attack, interrupts chants, and pauses every-x-seconds triggers. Elites and bosses recover twice as fast.")},
     triggers={"node_spy_harvest": ("[b]小小收获[/b]：战斗结束时触发(倒下了就不触发)。目标 = 自身，触发数值 = 千变万化已消耗的充能数 × [color=#ffd36b]{★1/1/2}[/color]。",
                                    "[b]A Little Harvest[/b]: triggers when the battle ends (not if she has fallen). Target: herself; trigger value = charges of Thousand Faces spent × "
                                    "[color=#ffd36b]{★1/1/2}[/color].")})
unit("node_medium", "幻灵节点", "Node Medium", "深紫长发、猫耳猫尾的通灵少女，研发部的灵媒。她身边总跟着看不见的朋友——等你看见它们的时候，它们已经在你背后了。",
     "A violet-haired, cat-eared medium from the Research Department. Invisible friends always follow her — by the time you can see them, they're already behind you.",
     {"node_medium_partner": ("[b]无形伙伴[/b]【充能 9】【召唤】：开战时充能全满。开局以及每 4 秒，消耗 1 层充能，在当前目标背后召唤一个【幽灵】。"
                              "取代原有的普通攻击：每次普通攻击时消耗 1 层充能，在目标的位置召唤一只【幽灵犬】，令它发动普通攻击。",
                              "[b]Unseen Friends[/b] 【Charged 9】【Summon】: starts the battle fully charged. At the start and every 4 s she spends 1 charge to summon a 【Ghost】 "
                              "behind her current target. Replaces her normal attack: each normal attack spends 1 charge to summon a 【Ghost Hound】 at the target, which attacks at once."),
      "node_medium_funeral": ("[b]少女幻葬[/b]【吟唱 9】【溅射 5】【召唤】：无形伙伴的充能归零时开始吟唱。吟唱期间每秒在溅射范围内随机一个人背后召唤一个幽灵——"
                              "这些幽灵没有【魂体存在】，攻击不分敌我，但无法离开溅射范围。吟唱结束后，每有 3 秒吟唱时间，就在战场随机位置召唤 吟唱期间全场阵亡的单位数 个幽灵。然后强制阵亡。",
                              "[b]A Girl's Grand Requiem[/b] 【Chant 9】【Splash 5】【Summon】: when Unseen Friends runs out of charges, she starts chanting. Every second of the chant she "
                              "summons a ghost behind someone random in Splash range — these ghosts lack 【Spectral】, attack friend and foe alike, and can't leave Splash range. "
                              "When the chant ends, for every 3 s chanted she summons, at random spots on the field, as many ghosts as units died during the chant. Then she falls.")},
     triggers={"node_medium_last_wish": ("[b]遗愿[/b]：友方召唤物阵亡时触发。目标 = 离该召唤物最近的敌人，触发数值 = 该召唤物的最大生命值。",
                                         "[b]Last Wish[/b]: triggers when an allied summon dies. Target: the enemy nearest to it; trigger value = that summon's max health.")})
unit("node_dog", "幽灵犬", "Ghost Hound", "幻灵节点的伙伴，一只金毛寻回犬的灵体。扑上去咬一口，就摇着尾巴散成紫色的灵火。",
     "Node Medium's companion, the spirit of a golden retriever. One pounce, one bite — then it wags itself away into violet wisps.",
     {"node_dog_partner": ("[b]最好的伙伴[/b]：普通攻击额外造成 召唤者普通攻击伤害 × 100% 的魔法伤害。",
                           "[b]Best Friend[/b]: its normal attack also deals magic damage equal to 100% of its summoner's normal attack damage."),
      "node_dog_spectral": ("[b]魂体存在[/b]：无法被选中，不受伤害，普通攻击一次后立刻阵亡。",
                            "[b]Spectral[/b]: can't be targeted, takes no damage, and vanishes right after its first normal attack.")})
unit("node_ghost", "幽灵", "Ghost", "骷髅脸、紫兜帽的小幽灵。它从不正面出手。",
     "A little skull-faced ghost in a violet hood. It never strikes from the front.",
     {"node_ghost_silent": ("[b]无声无息[/b]：从背后发动的普通攻击必定暴击，且造成真实伤害。",
                            "[b]Without a Sound[/b]: normal attacks from behind always crit and deal true damage."),
      "node_ghost_spectral": ("[b]魂体存在[/b]：无法被选中，不受伤害，普通攻击一次后立刻阵亡。",
                              "[b]Spectral[/b]: can't be targeted, takes no damage, and vanishes right after its first normal attack.")})
unit("node_leader", "真望节点", "Node Leader", "青绿长发、一身白色军装的指挥官，工程部的旗手。她的箭从不射向敌人——只要身边还有人在等她。",
     "A teal-haired commander in a white uniform, the Engineering Department's standard-bearer. Her arrows never fly at the enemy — not while someone beside her is still waiting for one.",
     {"node_leader_arrows": ("[b]引导之矢[/b]【叠加 9】：进入战斗时具有 9 层【金矢】。"
                             "【金矢】：可叠加，不可驱散，无限持续。持有时普通攻击锁定友方单位(优先锁定符合条件、没有【黄金的指引】的队友)；每层获得 {★3%/4%/5%} 伤害减免。"
                             "普通攻击时消耗一层，给一名具有冷却时间最长、且充能不满的【充能】效果的其他友方单位回复 1 点充能，并令其获得一层【黄金的指引】。"
                             "【黄金的指引】：可叠加(上限同引导之矢)，不可驱散，无限持续。持有者所有“敌我不分”的效果改为“仅限敌人”(包括溅射、群攻)；每层获得 {★3%/4%/5%} 伤害减免。",
                             "[b]Guiding Arrows[/b] 【Stacking 9】: enters battle with 9 【Golden Arrows】. "
                             "【Golden Arrow】: stacks, can't be dispelled, lasts forever. While she has any, her normal attacks lock onto allies (preferring eligible allies without "
                             "【Golden Guidance】); each stack grants {★3%/4%/5%} damage reduction. Each normal attack spends one to give 1 charge to another ally whose 【Charged】 "
                             "effect with the longest cooldown isn't full, and grants it a stack of 【Golden Guidance】. "
                             "【Golden Guidance】: stacks (same cap as Guiding Arrows), can't be dispelled, lasts forever. Every friend-or-foe effect of the holder becomes enemies-only "
                             "(splash and multi-attack included); each stack grants {★3%/4%/5%} damage reduction."),
      "node_leader_heart": ("[b]少女真心[/b]【觉醒：战斗中我方总共具有至少 27 层充能】：每场战斗限一次。全体友方阵亡时，立刻复活所有具有【充能】的友方单位，"
                            "并令其被动效果(不包括武器效果)具有全部充能；被复活的友军每有 1 点充能上限，回复其 10% 的生命值。即便自身未存活也能触发。",
                            "[b]A Girl's True Heart[/b] 【Awakening: your side holds at least 27 charges in total during a battle】: once per battle. When every ally has fallen, "
                            "instantly revive every allied unit that has 【Charged】 effects and fully recharge their passives (not weapon effects); each revived ally regains 10% "
                            "health per point of maximum charges. Works even if she has fallen herself.")},
     triggers={"node_leader_courage": ("[b]勇气[/b]：自身阵亡时触发。目标 = 自身，触发数值 [color=#ffd36b]{★100/150/200}[/color]。",
                                       "[b]Courage[/b]: triggers when she falls. Target: herself; trigger value [color=#ffd36b]{★100/150/200}[/color].")})
unit("node_bard", "心音节点", "Node Bard", "金色长发、精灵耳朵、背着一对蝴蝶翅膀的吟游诗人，福利部的乐师。她的琴声里藏着整支队伍的心跳。",
     "A golden-haired, elf-eared bard with butterfly wings — the Welfare Department's musician. Her lute carries the heartbeat of the whole team.",
     {"node_bard_perform": ("[b]纤心的乐奏[/b]【吟唱 4】【双模】【演奏】：战斗开始时及每 4 秒，进行一段演奏。演奏结束时，对这段演奏的对象施加 "
                            "吟唱秒数 × {★20/30/45} × (100 + 法术强度)% 的治疗(友方)或法术伤害(敌方)。",
                            "[b]Delicate Heart's Performance[/b] 【Chant 4】【Dual Mode】【Performance】: at the start of battle and every 4 s, she plays a piece. "
                            "When the piece ends, its target receives seconds chanted × {★20/30/45} × (100 + ability power)% as healing (ally) or magic damage (enemy)."),
      "node_bard_echo": ("[b]不绝的回响[/b]：自身阵亡时，当时演奏所维持的效果此后永久持续；如果其中不包括“攻击力 / 法术强度提升”，一并施加之。",
                         "[b]Endless Echo[/b]: when she falls, whatever her current piece is sustaining lasts forever; if that doesn't include the attack / ability power boost, "
                         "she grants it too.")},
     triggers={"node_bard_critique": ("[b]艺术性批判[/b]：吟唱开始时触发。目标 = 这段演奏的对象，触发数值 [color=#ffd36b]{★60/90/130}[/color]"
                                      "(会造成伤害 / 负面效果的装备效果不会打到队友)。",
                                      "[b]Artistic Critique[/b]: triggers when she starts chanting. Target: the piece's target; trigger value [color=#ffd36b]{★60/90/130}[/color] "
                                      "(weapon effects that would hurt don't hit allies).")})
unit("node_perfume", "调香节点", "Node Perfume", "青绿长发、头顶一对鹿角的调香师，福利部的熏香师。她走过的地方，伤口都会慢慢合上。",
     "A teal-haired perfumer with a pair of antlers — the Welfare Department's incense keeper. Wherever she passes, wounds slowly close.",
     {"node_perfume_scent": ("[b]飘香[/b]【叠加 3】：在场时，所有友方【再生】的效能 × 叠加数(3 倍)。战斗开始时及每 {★6/4/3} 秒，为全体友军施加 1 个【再生】，持续 10 秒。",
                             "[b]Wafting Scent[/b] 【Stacking 3】: while she is on the field, every ally's 【Regeneration】 is multiplied by the stacking value (×3). "
                             "At the start of battle and every {★6/4/3} s, gives every ally 1 【Regeneration】 for 10 s."),
      "node_perfume_eternal": ("[b]恒古[/b]：自身在场时，为全体友军维持 1 个【再生】。",
                               "[b]Everlasting[/b]: while she is on the field, every ally keeps 1 【Regeneration】.")},
     triggers={"node_perfume_burn": ("[b]焚花[/b]：每 8 秒触发。目标 = 全体敌人(受群攻限制)，触发数值 = 本场为友方施加的治疗量总和。",
                                     "[b]Burning Blossoms[/b]: triggers every 8 s. Targets: every enemy (limited by Multi-Attack); trigger value = all the healing she has given allies this battle.")})
unit("node_vampire", "血嗜节点", "Node Vampire", "青绿短发、红色竖瞳的吸血鬼剑士，安保部的宗族之子。他永远饥渴，却从未失去理智——为了同伴。",
     "A teal-haired vampire swordsman with slit red eyes, a child of the clan in the Security Department. Forever hungry, yet never lost to madness — for his companions' sake.",
     {"node_vampire_lust": ("[b]关于那位永不饱餐的血魔，[/b]【叠加 12】：每 1 秒，叠加 {★2/2/3} 层【血欲】。"
                            "【血欲】：可叠加，无法驱散，无限持续。造成 / 承受非持续伤害时，每有一层，就对目标叠加一层【失血】。"
                            "【失血】：可叠加(与本技能共用叠加数)，可驱散，持续 10 秒，负面状态。每层每 0.25 秒承受 {★0.6/1/1.8} 点物理持续伤害，并为血嗜节点回复最终伤害量的生命值。",
                            "[b]Of the blood fiend who is never sated,[/b] 【Stacking 12】: every second, gains {★2/2/3} stacks of 【Bloodlust】. "
                            "【Bloodlust】: stacks, can't be dispelled, lasts forever. Whenever he deals or takes non-DoT damage, each stack gives the other side a stack of 【Bleeding】. "
                            "【Bleeding】: stacks (shares this skill's stacking value), dispellable, lasts 10 s, a debuff. Each stack deals {★0.6/1/1.8} physical damage over time every 0.25 s "
                            "and heals Node Vampire for the final damage dealt."),
      "node_vampire_feast": ("[b]却也永不堕入疯狂的伙伴，[/b]【叠加 12】：在场时，全场每有 150 点持续伤害被造成，就获得 1 层【血宴】。"
                             "【血宴】：可叠加，无法驱散，无限持续。每层提供 4% 持续伤害增幅和 3 点固定伤害减免。",
                             "[b]yet a companion who never falls into madness,[/b] 【Stacking 12】: while he is on the field, every 150 damage over time dealt anywhere gives him 1 stack of 【Blood Feast】. "
                             "【Blood Feast】: stacks, can't be dispelled, lasts forever. Each stack grants 4% damage-over-time amplification and 3 flat damage reduction.")},
     triggers={"node_vampire_kin": ("[b]也是我等的至亲的故事。[/b]：【血欲】达到 12 层时，消耗 12 层触发。目标 = 一个半径 6 米的圆中的所有敌人(受群攻限制)，"
                                    "触发数值 [color=#ffd36b]血宴层数 × 攻击力 × (100 + 法术强度)%[/color]。武器在冷却时不会触发，也不消耗血欲，冷却好了才触发。",
                                    "[b]is also the tale of our dearest kin.[/b]: when 【Bloodlust】 reaches 12, consumes 12 stacks to trigger. Targets: every enemy in a circle of 6 m radius "
                                    "(limited by Multi-Attack); trigger value [color=#ffd36b]Blood Feast stacks × attack × (100 + ability power)%[/color]. While the weapon is on cooldown it doesn't "
                                    "trigger or spend Bloodlust; it triggers once the cooldown is over.")})
unit("node_absolver", "灭罪节点", "Node Absolver", "金色波浪长发、精灵长耳、身后悬着太阳光环的白袍圣女，订法部的裁决者。她从不睁眼看罪人——光会替她去看。",
     "A white-robed saint with long golden waves, elf ears and a sun halo at her back — the Legislation Department's judge. She never opens her eyes to the guilty; "
     "the light looks for her.",
     {"node_absolver_light": ("[b]她是唯一的光[/b]【吟唱 99】【溅射 2】：在战斗中永远吟唱(被打断后，能行动时立刻重新开始)。吟唱期间，召唤一道从天空中降临的光束："
                              "降临在敌方最强的单位所在的位置，之后持续锁定敌方伤害最高的单位，只能缓慢移动过去(移动时不会避让友军)。"
                              "光束每 0.25 秒对中心的主目标造成 {★25%/40%/70%} × 攻击力 × (100 + 法术强度)% 的法术伤害；即使没有主目标也会溅射。",
                              "[b]She Is the Only Light[/b] 【Chant 99】【Splash 2】: she chants for the whole battle (if interrupted, she starts again as soon as she can act). "
                              "While chanting, she calls down a beam of light from the sky: it lands where the strongest enemy stands, then keeps locking onto the enemy that has "
                              "dealt the most damage, moving there only slowly (it doesn't avoid allies on the way). Every 0.25 s the beam deals "
                              "{★25%/40%/70%} × attack × (100 + ability power)% magic damage to the main target at its center; it splashes even with no main target."),
      "node_absolver_night": ("[b]她将照亮长夜[/b]：每吟唱 0.5 秒，光束的倍率和溅射范围提高 3%；被打断时重置。造成击杀时，直接获得 2 秒的提升。",
                              "[b]She Will Light the Long Night[/b]: every 0.5 s of chanting raises the beam's multiplier and splash range by 3%; resets when interrupted. "
                              "Each kill instantly grants 2 seconds' worth.")},
     triggers={"node_absolver_purge": ("[b]她必尽灭邪恶[/b]：光束每持续 0.25 秒触发一次。目标 = 光束溅射范围中的所有敌人(受群攻限制)，"
                                       "触发数值 [color=#ffd36b]{★0.1/0.15/0.25} × 攻击力 × (100 + 法术强度)%[/color]。",
                                       "[b]She Shall Purge All Evil[/b]: triggers every 0.25 s the beam lasts. Targets: every enemy in the beam's splash range (limited by Multi-Attack); "
                                       "trigger value [color=#ffd36b]{★0.1/0.15/0.25} × attack × (100 + ability power)%[/color].")})
unit("node_sniper", "屏息节点", "Node Sniper", "金色长直发、一对猫耳、黑色战术服外罩黑披风的狙击手，工程部的远程观察员。她开枪之前，从不呼吸。",
     "A sniper with long straight golden hair, cat ears, black tactical gear and a black cape — the Engineering Department's long-range observer. "
     "She never breathes before she fires.",
     {"node_sniper_aim": ("[b]瞄准眉心[/b]【吟唱 10】：具有更高的基础攻击力。每次普通攻击时，作为吟唱，最多额外瞄准 10 秒，期间每秒提升 {★40%/60%/100%} 攻击力；攻击后重置。",
                          "[b]Between the Eyes[/b] 【Chant 10】: higher base attack. Each normal attack, as a chant, she can aim for up to 10 extra seconds, gaining "
                          "{★40%/60%/100%} attack per second; resets after the attack."),
      "node_sniper_breath": ("[b]集中呼吸[/b]：如果身周没有敌人，每秒获得 {★5%/8%/12%} 暴击率。暴击率溢出时，改为获得两倍的暴击伤害。被纳入近战敌人的攻击范围时重置。",
                             "[b]Focused Breathing[/b]: while no enemy is near her, gains {★5%/8%/12%} crit chance per second. Crit chance beyond 100% becomes twice as much "
                             "crit damage instead. Resets when she comes within a melee enemy's reach.")},
     triggers={"node_sniper_double": ("[b]一石二鸟[/b]：造成击杀时触发。目标 = 距被击杀者最近的敌人，触发数值 [color=#ffd36b]这次击杀溢出的伤害[/color]。",
                                      "[b]Two Birds, One Stone[/b]: triggers when she kills. Target: the enemy nearest the one killed; trigger value "
                                      "[color=#ffd36b]the overkill damage of that kill[/color].")})
unit("node_commando", "止息节点", "Node Commando", "金色短波波头、异色瞳、头戴耳机的突击队员，安保部的近身掩护。她冲进去的地方，就是屏息节点下一枪落下的地方。",
     "A short-bobbed blonde commando with mismatched eyes and a headset — the Security Department's close cover. Wherever she dives in is where Node Sniper's next shot lands.",
     {"node_commando_period": ("[b]画上句点[/b]：索敌时使用突进——将该敌人向远离它当前目标的方向击退 2 米，冲刺到它背后恰好在攻击范围内的位置，立刻普通攻击，"
                               "然后强制该敌人索敌自己，并对其施加【标定】。索敌目标不持有【标定】时，重新使用突进。"
                               "【标定】：无法驱散，不可叠加，负面状态。该敌人承受的伤害，其伤害增幅 +{★15%/20%/30%}。标定累计达到 3 秒时，令我方攻击力最高的远程友军立刻对该敌人打出"
                               "一发免费的普通攻击弹道(计入当次普攻的一切加成，但不消耗任何资源，也不视为攻击)；该弹道命中时，标定被消耗。",
                               "[b]Full Stop[/b]: when she picks a target, she lunges — knocking it 2 m away from whatever it is targeting, dashing to the spot right behind it "
                               "at the edge of her attack range, attacking at once, then forcing it to target her and applying 【Marked】. Whenever her target isn't 【Marked】, she lunges again. "
                               "【Marked】: can't be dispelled, doesn't stack, a debuff. Damage the enemy takes gets +{★15%/20%/30%} damage amplification. Once it has been Marked for 3 s, "
                               "your ranged ally with the highest attack instantly fires a free normal-attack shot at it (with every bonus that attack would get, but spending nothing "
                               "and not counting as an attack); when that shot hits, the mark is consumed."),
      "node_commando_cover": ("[b]掩护支援[/b]：冷却 5 秒【充能 2】。有近战敌人靠近我方攻击力最高的远程友军 2.8 米以内时，立刻改为索敌该近战敌人。",
                              "[b]Covering Support[/b]: 5 s cooldown 【Charged 2】. When a melee enemy comes within 2.8 m of your ranged ally with the highest attack, "
                              "she immediately switches her target to it.")},
     triggers={"node_commando_assault": ("[b]突击[/b]：发动突进时触发。目标 = 突进对象，触发数值 [color=#ffd36b]{★100%/150%/220%} × 攻击力[/color]。",
                                         "[b]Assault[/b]: triggers when she lunges. Target: the lunge's target; trigger value [color=#ffd36b]{★100%/150%/220%} × attack[/color].")})
unit("node_knight_errant", "踏影节点", "Node Knight-errant", "青色乱发、黑金长袍的游侠，情报部的影中刃。他从不在敌人眼前出剑——他出现的时候，已经在你身后了。",
     "A wandering swordsman with messy teal hair and a black-and-gold robe — the Information Department's blade in the shadows. He never draws in front of you; "
     "by the time he appears, he's already behind you.",
     {"node_ke_backlight": ("[b]逆光[/b]：冷却 8 秒【充能 1】【叠加 3】，开战拥有 1 层充能。当前目标不是远程敌人时，瞬移到一个远程敌人背后，并索敌该远程敌人，然后获得 1 层【凝暗】。"
                            "【凝暗】：可以叠加，可以驱散，无限持续。持有时，除非持有者已经是场上最后的合法目标，否则不能被敌人索敌。每层提供背后攻击时 {★25%/45%/65%} 的伤害增幅。",
                            "[b]Backlight[/b]: 8 s cooldown 【Charged 1】【Stacking 3】, starts the battle with 1 charge. When his current target isn't a ranged enemy, he teleports "
                            "behind a ranged enemy, targets it, then gains 1 stack of 【Gathered Dark】. 【Gathered Dark】: stacks, dispellable, lasts forever. While he has it, enemies "
                            "can't target him unless he is the last legal target left. Each stack grants {★25%/45%/65%} damage amplification on attacks from behind."),
      "node_ke_ink": ("[b]墨刃[/b]：每 5 秒，对当前目标造成 {★200%/200%/300%} × 攻击力 × (100 + 法术强度)% 的魔法伤害。",
                      "[b]Ink Blade[/b]: every 5 s, deals {★200%/200%/300%} × attack × (100 + ability power)% magic damage to his current target.")},
     triggers={"node_ke_temper": ("[b]淬血[/b]：发动逆光时，对自身造成 {★50%/60%/80%} × 攻击力 × (100 + 法术强度)% 的真实持续伤害并触发。目标 = 自身，"
                                  "触发数值 [color=#ffd36b]本次流失的生命值[/color]。没有武器效果 / 武器效果在冷却时不会触发，也不消耗生命值。",
                                  "[b]Blood Temper[/b]: when he uses Backlight, deals {★50%/60%/80%} × attack × (100 + ability power)% true damage over time to himself and triggers. "
                                  "Target: himself; trigger value [color=#ffd36b]the health lost this time[/color]. If the weapon has no effect or it's on cooldown, it doesn't "
                                  "trigger and costs no health.")})
unit("node_noble", "正行节点", "Node Noble", "金色波浪长发、银甲金边、浑身缠着花藤与小花的花骑士，维护部的守护者。百合开在她的盾上，也开在她身后的每一个人身上。",
     "A flower knight with golden waves of hair and gold-trimmed silver armor, wound all over with flowering vines — the Maintenance Department's guardian. "
     "The lily blooms on her shield, and on everyone standing behind her.",
     {"node_noble_lily": ("[b]正色百合[/b]【叠加 12】：每 3 秒获得 1 层【花瓣】。每次队友造成击杀获得 1 层【花瓣】。每 3 次普攻获得 1 层【花瓣】。"
                          "每次有队友阵亡获得 3 层【花瓣】。每次为队友提供治疗获得 2 层【花瓣】。"
                          "【花瓣】：可叠加，不可驱散，无限持续。每层提供 {★3%/4%/5%} 治疗量加成。到达 4 层时，获得 {★300/450/700} 最大生命值。"
                          "到达 8 层时，获得 {★20/30/45} 防御力与魔法抗性。",
                          "[b]True-Colored Lily[/b] 【Stacking 12】: gains 1 【Petal】 every 3 s, 1 whenever a teammate gets a kill, 1 every 3 normal attacks, "
                          "3 whenever a teammate falls, and 2 whenever she heals a teammate. "
                          "【Petal】: stacks, can't be dispelled, lasts forever. Each stack grants {★3%/4%/5%} healing bonus. At 4 stacks she gains {★300/450/700} max health; "
                          "at 8 stacks, {★20/30/45} armor and magic resistance."),
      "node_noble_rebloom": ("[b]再绽之花[/b]【群攻 9】【吟唱 3】【叠加 3】：【花瓣】达到 12 层时，开始吟唱，每秒消耗 4 层【花瓣】，并获得 1 层【花蕊】。"
                             "累积消耗 12 层【花瓣】后，获得【花】。"
                             "【花蕊】：可叠加，不可驱散，无限持续。普攻伤害获得等同于治疗量加成的最终伤害加成。普攻时，消耗一层，使用延长过的光剑(装备单手剑时)/"
                             "光矛(装备矛时)/光炮(装备法器时)，在大面积锥形范围(身前 120°、4.5 米)内造成原普攻的 {★250%/300%/400%} 伤害，"
                             "然后为全场受伤的友军智能分配等同于伤害量的治疗量。"
                             "【花】：不可叠加，不可驱散，无限持续。提供满层的【花瓣】加成。",
                             "[b]Bloom Anew[/b] 【Multi-Attack 9】【Chant 3】【Stacking 3】: when 【Petal】 reaches 12 stacks she starts chanting, spending 4 【Petal】 "
                             "and gaining 1 【Stamen】 each second. Once she has spent 12 【Petal】 in total, she gains 【Bloom】. "
                             "【Stamen】: stacks, can't be dispelled, lasts forever. Her normal-attack damage gains a final damage bonus equal to her healing bonus. "
                             "On a normal attack she spends one and wields an extended sword of light (with a sword) / spear of light (with a spear) / "
                             "cannon of light (with a focus), dealing {★250%/300%/400%} of that normal attack to enemies in a huge cone (120° in front, 4.5 m), "
                             "then smartly shares out healing equal to the damage dealt among every wounded ally on the field. "
                             "【Bloom】: doesn't stack, can't be dispelled, lasts forever. Grants the full-stack 【Petal】 bonuses.")},
     triggers={"node_noble_knight": ("[b]百合骑士的骑士[/b]：有敌人被纳入自身 3 米内范围，或者在自身 3 米内范围内停留达到 2 秒时触发。目标 = 该敌人，"
                                     "触发数值 [color=#ffd36b]攻击力 × 治疗量加成 × {★350%/400%/500%}[/color]。",
                                     "[b]Knight of the Lily Knight[/b]: triggers when an enemy comes within 3 m of her, or has stayed within 3 m for 2 s. "
                                     "Target: that enemy; trigger value [color=#ffd36b]attack × healing bonus × {★350%/400%/500%}[/color].")})
unit("node_brave", "执剑节点", "Node Brave", "长春花蓝长发、象牙白龙角、拖着一条龙尾的骑士，安保部唯一的勇者。她说过要和大家一起，把梦想一直带到未来去。",
     "A knight with long periwinkle hair, ivory dragon horns and a dragon's tail — the Security Department's one and only hero. She promised to carry "
     "everyone's dream all the way into the future, together.",
     {"node_brave_holy": ("[b]勇者，圣剑[/b]：开战时及每 5 秒，对当前目标发动。直接击杀普通怪物；否则造成 {★6%/9%/14%} × (100 + 法术强度)% 的百分比真实伤害"
                          "(按目标的最大生命值计算)。",
                          "[b]The Hero's Holy Sword[/b]: at the start of battle and every 5 s, strikes her current target. A common monster is slain outright; "
                          "anything else takes {★6%/9%/14%} × (100 + ability power)% of its max health as true damage."),
      "node_brave_dream": ("[b]梦想，未来[/b]：免疫负面状态。队友提供的所有属性提升类状态效果变为 {★1.5/1.75/2} 倍。"
                           "阵亡时，将所持有的属性提升扩散至全体队友，持续时间无限。",
                           "[b]A Dream, a Future[/b]: immune to debuffs. Every stat-boosting status a teammate gives her is {★1.5/1.75/2}× as strong. "
                           "When she falls, the stat boosts she holds spread to every teammate, lasting forever.")},
     triggers={"node_brave_fly": ("[b]与你，再度飞翔[/b]：每 10 秒触发。目标 = 自身与攻击力最高的已阵亡队友(受群攻限制)，"
                                  "触发数值 [color=#ffd36b]{★300%/450%/700%} × (100 + 法术强度)[/color]。",
                                  "[b]To Fly Again, With You[/b]: triggers every 10 s. Targets: herself and the fallen teammate with the highest attack "
                                  "(limited by Multi-Attack); trigger value [color=#ffd36b]{★300%/450%/700%} × (100 + ability power)[/color].")})
unit("node_pacifist", "共歌节点", "Node Pacifist", "红色卷发、坐着轮椅的人鱼歌姬，福利部的随军歌手。她的歌不分敌我——听到的人都会沉醉其中，哪怕是在战场上。",
     "A red-haired mermaid singer in a wheelchair — the Welfare Department's field vocalist. Her songs make no distinction between friend and foe: "
     "whoever hears them is enthralled, even on a battlefield.",
     {"node_pacifist_gentle": ("[b]温柔地[/b]：开局 10 秒期间，所有单位受到的伤害最终降低 {★50%/75%/87.5%}，不分敌我。",
                               "[b]Gently[/b]: for the first 10 s of battle, all damage every unit takes is finally reduced by {★50%/75%/87.5%}, friend or foe."),
      "node_pacifist_song": ("[b]美妙地[/b]【永恒】【叠加 20】：替代常规普通攻击，普通攻击为所有其他人，不分敌我地施加一层【沉醉】。"
                             "【沉醉】：可以叠加，不可驱散，跨战斗持续。每层伤害减免降低 {★2%/2%/2.5%}，伤害增幅提高 {★4%/5%/6%}。",
                             "[b]Beautifully[/b] 【Eternal】【Stacking 20】: replaces her normal attack — each normal attack gives everyone else, friend or foe, "
                             "a stack of 【Enthralled】. 【Enthralled】: stacks, can't be dispelled, carries over between battles. Each stack lowers damage reduction "
                             "by {★2%/2%/2.5%} and raises damage amplification by {★4%/5%/6%}.")},
     triggers={"node_pacifist_kind": ("[b]善良地[/b]：每 5 秒，对所有持有【沉醉】的目标触发(受群攻限制)。触发数值 [color=#ffd36b]{★20/30/45} × 目标的沉醉层数[/color]。",
                                      "[b]Kindly[/b]: every 5 s, triggers on every target that has 【Enthralled】 (limited by Multi-Attack). Trigger value "
                                      "[color=#ffd36b]{★20/30/45} × the target's Enthralled stacks[/color].")})
unit("node_angel", "白羽节点", "Node Angel", "浅蓝长发、背着一对白色大羽翼的天使枪手，福利部的送行人。她的子弹会治好你——也会为你记下离开的日子。",
     "An angel gunner with long pale-blue hair and a pair of great white wings — the Welfare Department's escort to the other side. Her bullets heal you, "
     "and count down the days until you leave.",
     {"node_angel_funeral": ("[b]致向死的渴望[/b]【叠加 10】：每第二发普通攻击(持用双枪时，则是追击打出的那发)指向生命值低于 97% 的友军，为目标回复其 3% 的最大生命值"
                             "(没有合法友军则只打敌人)。所有普通攻击施加 1 层【送葬】。"
                             "【送葬】：可以叠加，不可驱散，负面状态。持有 10 层时，普通怪物和棋子将立刻死亡，且不触发阵亡效果；否则失去 {★12%/18%/25%} 生命值上限，并消耗送葬状态。",
                             "[b]To the Longing for Death[/b] 【Stacking 10】: every second normal attack (with dual pistols, the pursuit shot) goes to an ally below 97% health "
                             "and heals it for 3% of its max health (if there's no such ally it just hits enemies). Every normal attack applies 1 stack of 【Funeral】. "
                             "【Funeral】: stacks, can't be dispelled, a debuff. At 10 stacks, common monsters and nodes die at once without triggering on-death effects; "
                             "anything else loses {★12%/18%/25%} of its max health and the stacks are spent."),
      "node_angel_will": ("[b]致求生的意志[/b]：持有【送葬】的友军，承受致命伤害时不会阵亡，但该伤害每有 {★250/250/150} 点，就额外叠加 1 层【送葬】。",
                          "[b]To the Will to Live[/b]: allies holding 【Funeral】 don't fall to lethal damage; instead, every {★250/250/150} points of that damage "
                          "adds another stack of 【Funeral】.")},
     triggers={"node_angel_requiem": ("[b]致将亡而未亡者[/b]：每 5 秒，连续触发 4 次。触发目标为【送葬】层数最多的敌人，触发数值 [color=#ffd36b]10[/color]。",
                                      "[b]To Those Dying Yet Not Dead[/b]: every 5 s, triggers 4 times in a row. Target: the enemy with the most 【Funeral】 stacks; "
                                      "trigger value [color=#ffd36b]10[/color].")})
unit("node_arcanist", "奇兴节点", "Node Arcanist", "紫发红眼、长着龙角和蝙蝠翼的骰子术士，研究部的赌徒。她说每一掷都通向另一个世界——只是不保证是好的那个。",
     "A purple-haired, red-eyed dice mage with dragon horns and bat wings — the Research Department's gambler. She says every roll opens onto another world; "
     "she just doesn't promise it'll be a good one.",
     {"node_arcanist_worlds": ("[b]自无数个世界之中[/b]【增幅 {★2/3/4}】：每 {★4.5/4/3} 秒，投 2d10 + 增幅数 + 已阵亡的队友人数，发动【无数世界】。",
                               "[b]From Countless Worlds[/b] 【Amplify {★2/3/4}】: every {★4.5/4/3} s, rolls 2d10 + Amplify + the number of fallen allies "
                               "and triggers 【Countless Worlds】."),
      "node_arcanist_petrify": ("[b]自久远的过去而来[/b]：以【石化】状态开始战斗，具有 80% 伤害减免。已阵亡的友军达到仍存活的友军人数时，结束石化，"
                                "并获得 当前时间 × {★3/3/6} 的法术强度和攻击力。【石化】：特殊的眩晕状态，无法被驱散。",
                                "[b]From the Distant Past[/b]: starts the battle 【Petrified】 with 80% damage reduction. Once the fallen allies are as many as "
                                "the living ones, the petrification ends and she gains (seconds elapsed) × {★3/3/6} ability power and attack. "
                                "【Petrified】: a special stun that can't be dispelled.")},
     triggers={"node_arcanist_strike": ("[b]掷向命运[/b]：每 5 秒触发。目标 = 以当前目标为中心(2 米)的所有敌人，触发数值 "
                                        "[color=#ffd36b]{★100%/130%/180%} × 攻击力 × (100 + 法术强度)%[/color]。",
                                        "[b]Toss to Fate[/b]: triggers every 5 s. Targets: every enemy within 2 m of her current target; trigger value "
                                        "[color=#ffd36b]{★100%/130%/180%} × attack × (100 + ability power)%[/color].")})
unit("node_cultist", "锁芯节点", "Node Cultist", "绿发尖耳、拖着一条粗蛇尾的钥匙守护者，研究部的秘仪师。她扛着一把比人还高的钥匙——据说它锁得上世间万物，也打得开不该打开的门。",
     "A green-haired, sharp-eared keykeeper trailing a thick serpent tail — the Research Department's ritualist. She shoulders a key taller than she is; "
     "they say it can lock anything in the world, and open doors that should stay shut.",
     {"node_cultist_lock": ("[b]万物闭锁[/b]：每普通攻击 3 次，智能选择一个圆形区域(半径 2.2 米)，对里面所有敌人造成 [color=#ffd36b]{★350/560/910}[/color] 魔法伤害，"
                            "附带 {★2/2.5/3} 秒【眩晕】。开局已累计 1 次计数。",
                            "[b]Lock All Things[/b]: every 3 normal attacks, picks the best circular area (2.2 m radius) and deals "
                            "[color=#ffd36b]{★350/560/910}[/color] magic damage to every enemy inside, 【Stunning】 them for {★2/2.5/3} s. "
                            "Starts the battle with 1 attack already counted."),
      "node_cultist_rite": ("[b]血色仪式[/b]：在场时，自身维持【血色仪式】：每秒受到 12 点真实持续伤害，且无法被治疗。"
                            "我方施加的所有【眩晕】持续时间提升 {★25%/40%/60%}。",
                            "[b]Blood Rite[/b]: while she's on the field she keeps 【Blood Rite】 on herself: 12 true damage per second, and she can't be healed. "
                            "Every 【Stun】 her team applies lasts {★25%/40%/60%} longer.")},
     triggers={"node_cultist_gate": ("[b]打开深空之门[/b]：场上所有单位累计被【眩晕】的时间每达到 8 秒触发一次。触发目标为所有曾被眩晕过的敌人，"
                                     "触发数值 [color=#ffd36b]{★300/450/700}[/color]。",
                                     "[b]Open the Deep-Space Gate[/b]: triggers each time the total time units on the field have spent 【Stunned】 reaches another 8 s. "
                                     "Targets: every enemy that has been stunned this battle; trigger value [color=#ffd36b]{★300/450/700}[/color].")})
unit("node_pianist", "变奏节点", "Node Pianist", "青发尖耳、长着小恶魔角和蝙蝠翼的钢琴家，研究部的演奏者。她弹的每一首曲子都有表里两面——听众只能听见其中一面。",
     "A cyan-haired pianist with little demon horns and bat wings — the Research Department's performer. Every piece she plays has two sides, "
     "and her audience only ever hears one of them.",
     {"node_pianist_form": ("[b]表里之间[/b]：战斗外头顶有按钮，可以在【恶魔形态】和【天使形态】之间切换(初始为恶魔形态)，两种形态的部门和被动 2 不同。"
                            "恶魔形态：研究部，伤害增幅 +{★20%/30%/45%}。天使形态：福利部，治疗量加成 +{★20%/30%/45%}。"
                            "每场战斗限一次：阵亡时，恢复所有生命值，并切换为另一形态。",
                            "[b]Between Front and Back[/b]: out of battle a button above her switches between 【Demon Form】 and 【Angel Form】 (she starts as a demon); "
                            "the two forms have different departments and Passive 2. Demon: Research, +{★20%/30%/45%} damage. Angel: Welfare, +{★20%/30%/45%} healing. "
                            "Once per battle, when she falls she restores all her health and switches to the other form."),
      "node_pianist_grief": ("[b](魔) 悲怆[/b]【叠加 9】：开局及每 3 秒，对所有敌人施加一层【沮丧】。有敌人阵亡时，立即令所有敌人额外叠加 2 层。"
                             "【沮丧】：可以叠加，可以驱散，负面状态，无限持续。每层每秒承受 [color=#ffd36b]{★8/10/16} × (100 + 法术强度)%[/color] 魔法持续伤害，"
                             "并失去 层数 × {★2%/2.5%/3.5%} 的攻击速度和“每数秒”计时器充能速度。",
                             "[b](Demon) Pathétique[/b] 【Stacking 9】: at the start and every 3 s, gives every enemy a stack of 【Despair】; whenever an enemy falls, "
                             "every enemy gains 2 more at once. 【Despair】: stacks, can be dispelled, negative, lasts forever. Each stack deals "
                             "[color=#ffd36b]{★8/10/16} × (100 + ability power)%[/color] magic damage per second, and the holder loses stacks × {★2%/2.5%/3.5%} "
                             "attack speed and \"every few seconds\" timer speed."),
      "node_pianist_passion": ("[b](天) 热情[/b]【叠加 9】：开局及每 3 秒，对所有友军施加一层【亢奋】。有队友阵亡时，立即令所有队友额外叠加 2 层。"
                               "【亢奋】：可以叠加，可以驱散，无限持续。每层每秒回复 [color=#ffd36b]{★1.5/2/3.5} × (100 + 法术强度)%[/color] 生命，"
                               "并提升 层数 × {★1%/1.2%/1.8%} 的攻击速度和“每数秒”计时器充能速度。",
                               "[b](Angel) Appassionata[/b] 【Stacking 9】: at the start and every 3 s, gives every ally a stack of 【Elation】; whenever an ally falls, "
                               "every ally gains 2 more at once. 【Elation】: stacks, can be dispelled, lasts forever. Each stack heals "
                               "[color=#ffd36b]{★1.5/2/3.5} × (100 + ability power)%[/color] per second and grants stacks × {★1%/1.2%/1.8%} "
                               "attack speed and \"every few seconds\" timer speed.")},
     triggers={"node_pianist_next": ("[b]下一乐章[/b]：她尝试叠加的状态已经叠到上限时，对自身触发。触发数值 "
                                     "[color=#ffd36b]{★300/450/700} × (100 + 法术强度)%[/color]。",
                                     "[b]Next Movement[/b]: triggers on herself whenever a status she tries to stack is already at its cap. Trigger value "
                                     "[color=#ffd36b]{★300/450/700} × (100 + ability power)%[/color].")})
unit("node_killer", "无我节点", "Node Killer", "墨绿长发、手脚爬着紫色诅咒纹的咒刃武士，安保部的斩首者。平时她连刀都不拔——只有舍弃掉另一个自己的那一场，刀才出鞘。",
     "A cursed swordswoman with long dark-green hair and purple curse marks crawling up her limbs — the Security Department's executioner. "
     "Most days she doesn't even draw her blade; it only leaves the scabbard in a battle she has given up another self for.",
     {"node_killer_phantom": ("[b]逆时幻影[/b]【追击 {★1/1/2}】【召唤】：普通攻击会连续攻击。在索敌目标附近召唤一个血量极低的幻影，每次被消灭后，"
                              "会在她的下一次普攻之后再次召唤出来。她普攻时，幻影也会普攻一次，以无我节点的普攻计算事件和伤害。",
                              "[b]Rewound Phantom[/b] 【Pursuit {★1/1/2}】【Summon】: her normal attacks strike in succession. She summons a phantom with very "
                              "low health near her target; each time it is destroyed, it comes back after her next normal attack. Whenever she attacks, the "
                              "phantom attacks once too — counted as Node Killer's own normal attack for events and damage."),
      "node_killer_selfless": ("[b]无我[/b]：如果仓库里还有别的无我节点，备战时她身上会出现按钮。点击后移除一个仓库里的无我节点(优先星级最低的)，"
                               "下一场战斗开始时移除所有普通敌人，并使敌方精英 / 首领失去 {★20%/35%/50%} 的最大生命值。那一场她会拔刀。",
                               "[b]Selfless[/b]: if there is another Node Killer in storage, a button appears on her during preparation. Pressing it removes "
                               "one Node Killer from storage (lowest star first); when the next battle starts, every normal enemy is removed and enemy elites / "
                               "bosses lose {★20%/35%/50%} of their max health. In that battle she draws her blade.")},
     triggers={"node_killer_strike": ("[b]无我之刃[/b]：普通攻击命中时触发。目标 = 普攻目标，触发数值 [color=#ffd36b]{★60/90/140}[/color]。",
                                      "[b]Selfless Edge[/b]: triggers when her normal attack hits. Target: the attack's target; trigger value "
                                      "[color=#ffd36b]{★60/90/140}[/color].")})
unit("killer_phantom", "逆时幻影", "Rewound Phantom", "无我节点从倒转的时间里拖出来的自己。一碰就散，但总会在她下一次挥刀之后回来。",
     "A version of Node Killer dragged back out of rewound time. It breaks at a touch, but always returns after her next swing.",
     {})
unit("node_sister", "心连节点", "Node Sister", "瓷白球关节的人偶修女，福利部的量产型号。她倒下了，还有下一个她——每一个都在为同伴祈祷。",
     "A porcelain, ball-jointed clockwork nun — the Welfare Department's mass-production model. When one of her falls there is always another, "
     "and every one of them prays for her companions.",
     {"node_sister_mass": ("[b]量产型号[/b]【召唤】：开战及每 {★8/7/5} 秒，召唤一个自身的复制。复制品没有【量产型号】，并装备基础单手剑。",
                           "[b]Mass Production[/b] 【Summon】: at the start of battle and every {★8/7/5} s, summons a copy of herself. "
                           "Copies don't have Mass Production and wield a basic sword."),
      "node_sister_pray": ("[b]治疗祈愿[/b]：每 {★5/5/3} 秒，对生命比例最低的友军回复 {★120/120/200} × (100 + 法术强度)% 的生命，"
                           "并清除其一个持续时间最长的负面状态。友军都满血时不计时。复制品也有治疗祈愿。",
                           "[b]Healing Prayer[/b]: every {★5/5/3} s, heals the ally with the lowest health ratio for {★120/120/200} × (100 + ability power)% "
                           "and removes the debuff on them with the longest time left. The timer only runs while an ally is hurt. Copies have it too.")},
     triggers={"node_sister_miracle": ("[b]奇迹[/b]：每阵亡 2 只心连节点(复制品也算)时触发。目标 = 一个已阵亡的友方单位(优先非召唤物)，"
                                       "触发数值 [color=#ffd36b]{★150/220/350} × (100 + 法术强度)%[/color]。",
                                       "[b]Miracle[/b]: triggers every time 2 Node Sisters (copies included) fall. Target: one fallen ally (non-summons first); "
                                       "trigger value [color=#ffd36b]{★150/220/350} × (100 + ability power)%[/color].")})
unit("node_rogue", "巧运节点", "Node Rogue", "银发尖耳、围着红围巾的小偷，情报部的跑腿。手指一翻就多一枚金币——运气这东西，他总是比别人多掷一次。",
     "A silver-haired, pointy-eared thief in a red scarf — the Information Department's errand runner. A flick of his fingers and there's one more coin; "
     "when it comes to luck, he always gets one more roll than everyone else.",
     {"node_rogue_pickpocket": ("[b]妙手[/b]：每次普通攻击，有 {★2%/3%/5%} 的概率获得 1 金币(战斗结束后入账)。",
                                "[b]Sleight of Hand[/b]: each normal attack has a {★2%/3%/5%} chance to gain 1 gold (paid out after the battle)."),
      "node_rogue_dice": ("[b]真骰[/b]：更高机率遇到高稀有度事件。玩家在事件中需要判定有明确好坏的概率时，重投 1 次取好的结果。"
                          "自身在战斗中判断概率时也生效(暴击、闪避、被打断 / 打空、药剂的大成功 / 大失败等)。",
                          "[b]Loaded Dice[/b]: rarer events turn up more often. Whenever an event rolls an outcome that is clearly good or bad, "
                          "it is rerolled once and the better result is kept. Also applies to his own rolls in battle (crits, dodges, "
                          "being interrupted or missing, potion great successes / failures, and so on).")},
     triggers={"node_rogue_fortune": ("[b]鸿运，大概吧[/b]：妙手获得金币时触发。目标 = 自身，触发数值 [color=#ffd36b]{★1/1/2}[/color]。",
                                      "[b]Good Fortune, Probably[/b]: triggers when Sleight of Hand gains gold. Target: himself; trigger value "
                                      "[color=#ffd36b]{★1/1/2}[/color].")})
unit("node_paladin", "圣战节点", "Node Paladin", "蓝发蓝胡子、穿白金重甲的锤骑士，安保部的前排。他一锤砸下去，地面连同上面的东西一起裂开。",
     "A blue-haired, blue-bearded hammer knight in white-and-gold plate — the Security Department's front line. When his hammer comes down, "
     "the ground splits, along with everything standing on it.",
     {"node_paladin_slam": ("[b]裂地猛击[/b]：每 5 秒，智能地对锥形范围内的所有敌人造成 {★300/450/700} × (100 + 法术强度)% 的魔法伤害，并破坏范围内的地形"
                            "(断壁残垣、燃烧废墟碎掉，余烬熄灭，寒雾散开)。到点时附近没有敌人就蓄着，有敌人进入范围立刻砸下。",
                            "[b]Earthsplitter[/b]: every 5 s, smartly deals {★300/450/700} × (100 + ability power)% magic damage to every enemy in a cone "
                            "and shatters the terrain in it (ruins and burning ruins break, embers go out, frost mist clears). "
                            "If no enemy is in reach when it's ready, he holds it and strikes the moment one comes close."),
      "node_paladin_heal": ("[b]圣疗[/b]：每 4 秒，对生命比例最低的友军回复 {★150/220/350} × (100 + 法术强度)% 的生命。友军都满血时不计时。",
                            "[b]Holy Mending[/b]: every 4 s, heals the ally with the lowest health ratio for {★150/220/350} × (100 + ability power)%. "
                            "The timer only runs while an ally is hurt.")},
     triggers={"node_paladin_holywar": ("[b]神圣战争[/b]：裂地猛击造成伤害时触发。目标 = 受到伤害的敌人，触发数值 [color=#ffd36b]{★100/130/180} × (100 + 法术强度)%[/color]。",
                                        "[b]Holy War[/b]: triggers when Earthsplitter deals damage. Targets: the enemies it damaged; trigger value "
                                        "[color=#ffd36b]{★100/130/180} × (100 + ability power)%[/color].")})
unit("node_psychic", "导向节点", "Node Psychic", "金发猫耳、穿藏青水手服的雷电魔导士，研究部的向导。她念完咒语，闪电就在敌人之间来回跳。",
     "A blonde, cat-eared thunder mage in a navy sailor uniform — the Research Department's guide. When she finishes her incantation, "
     "lightning leaps back and forth between her enemies.",
     {"node_psychic_call": ("[b]引雷[/b]【吟唱 3】：普通攻击需要吟唱(最多 3 秒，吟唱满时倍率 ×2)，然后发射在敌人之间弹跳 {★4/4/5} 次的连锁闪电，"
                            "每一跳仍然享受武器的基础效果和倍率。可以弹跳同一目标，但必须先弹跳到其他人身上。",
                            "[b]Call Lightning[/b] 【Chant 3】: her normal attacks must be chanted (up to 3 s; ×2 when fully chanted), then she releases "
                            "a chain lightning that bounces {★4/4/5} times between enemies; every jump still gets the weapon's base effects and multiplier. "
                            "It can hit the same target again, but must jump to someone else first."),
      "node_psychic_weather": ("[b]变天[/b]：根据当前章节获得不同效果。白之章：无效果。红之章：战场天气变为下雨，所有人被施加的【燃烧】持续时间减半。"
                               "紫之章：战场天气变为晴天，所有【寒气】的攻速削减效果减半。蓝之章：战场天气变为起雾，敌我双方使用远程武器(法器除外)的普通攻击有 25% 的概率被闪避。",
                               "[b]Change the Weather[/b]: the effect depends on the current chapter. White: none. Red: it starts to rain — 【Burning】 "
                               "applied to anyone lasts half as long. Purple: the skies clear — every 【Chill】 slows attack speed only half as much. "
                               "Blue: fog rolls in — normal attacks from ranged weapons (focuses excepted), friend or foe, have a 25% chance to be dodged.")},
     triggers={"node_psychic_flash": ("[b]电闪[/b]：普通攻击弹跳结束时触发。目标 = 本次命中的所有敌人，触发数值 [color=#ffd36b]攻击力 × {★120%/140%/170%}[/color]。",
                                      "[b]Lightning Flash[/b]: triggers when her normal attack finishes bouncing. Targets: every enemy it hit; trigger value "
                                      "[color=#ffd36b]attack × {★120%/140%/170%}[/color].")})
unit("node_warden", "守林节点", "Node Warden", "橄榄绿短发、狮耳狮尾、披着毛皮与绿叶的荒野萨满，研究部的森林守护者。倒下一次，她就换一副野兽的模样再站起来。",
     "A wild shaman with short olive hair, a lion's ears and tail, and a cloak of fur and leaves — the Research Department's forest guardian. "
     "Each time she falls, she rises again in the shape of another beast.",
     {"node_warden_fury": ("[b]护林狂怒[/b]：在变身状态下，攻击形态与所携带的武器无关。以【狮子形态】进入战斗，普攻倍率以生命值计算(最大生命值的 6%)，"
                           "普攻具有【追击 {★1/1/2}】。第一次阵亡时，改为【巨蜘蛛形态】，攻击叠加【中毒】，持续 5 秒。第二次阵亡时，改为【巨蟾蜍形态】，"
                           "拥有额外 {★40/60/90} 护甲和魔法抗性，普攻施加类似色欲的余烬所施加的束缚状态。第三次阵亡后，以基础形态战斗。"
                           "【中毒】：独立施加，可以驱散，负面状态。每秒造成 {★15/22/35} × (100 + 法术强度)% 的魔法持续伤害。",
                           "[b]Forest Fury[/b]: while transformed, her attacks don't depend on the weapon she carries. She enters battle in 【Lion Form】: her normal attacks "
                           "scale with health (6% of max health) and have 【Pursuit {★1/1/2}】. The first time she falls she becomes 【Giant Spider】: attacks apply "
                           "【Poison】 for 5 s. The second time, 【Giant Toad】: {★40/60/90} extra armor and magic resistance, and normal attacks bind like the "
                           "Ember of Lust's grip. After the third, she fights in her base form. 【Poison】: applied separately each time, dispellable, a debuff. "
                           "Deals {★15/22/35} × (100 + ability power)% magic damage per second."),
      "node_warden_will": ("[b]荒野意志[/b]：每次切换形态时(包括开局)，恢复 1 生命值，获得最大生命值 × {★35%/45%/60%} × (100 + 法术强度)% 的护盾。",
                           "[b]Will of the Wild[/b]: each time she changes form (including at the start), she recovers 1 health and gains a shield of max health × {★35%/45%/60%} × "
                           "(100 + ability power)%.")},
     triggers={"node_warden_blood": ("[b]原初血脉[/b]：切换形态时(包括开局)触发。目标 = 自身，触发数值 [color=#ffd36b]最大生命值 × {★8%/12%/18%} × (100 + 法术强度)%[/color]。",
                                     "[b]Primal Blood[/b]: triggers when she changes form (including at the start). Target: herself; trigger value "
                                     "[color=#ffd36b]max health × {★8%/12%/18%} × (100 + ability power)%[/color].")})
unit("node_vine", "缠绕节点", "Node Vine", "维护部的绿色坦克。挨打越多，越是茁壮。",
     "A green Maintenance Department tank. The more it is hit, the stronger it grows.",
     {"node_vine_thorns_ability": ("[b]荆棘[/b]：每被普通攻击命中 3 次，对攻击者造成 40/70/110 魔法伤害。", "[b]Thorns[/b]: every 3rd hit taken deals 40/70/110 magic damage to the attacker.")})
unit("node_bounty", "悬赏节点", "Node Bounty", "情报部的赏金枪手。每一次击杀都会变成金币。",
     "An Information Department bounty hunter. Every kill turns into gold.",
     {"node_bounty_gold": ("[b]悬赏[/b]：击杀敌人时，获得 1 金币。", "[b]Bounty[/b]: gains 1 gold whenever it kills an enemy.")},
     ("[b]赏金枪手[/b]：双枪连射，射速越快，「每第 4 次命中」的武器效果来得越勤。", "[b]Gunslinger[/b]: rapid twin-pistol fire makes its every-4th-hit weapon effect come around fast."))
unit("sample_archer", "示例射手", "Sample Archer", "验收用 1 费射手。每第四次普攻追击，第六次普攻触发装备。", "1-cost acceptance archer. Every 4th attack pursues, every 6th triggers equipment.",
     {"sample_archer_pursuit": ("每第 4 次普通攻击命中获得【追击 1】。", "Every 4th normal attack hit gains 【Pursuit 1】.")})
unit("sample_darkknight", "示例黑骑士", "Sample Darkknight", "验收用 2 费战士。被普攻命中会治疗并叠加防御，第三次被命中触发装备。", "2-cost acceptance warrior. Hits taken heal and stack defense; the 3rd triggers equipment.",
     {"sample_darkknight_heal": ("每被命中 6 次治疗自身 50。", "Every 6th hit taken heals 50."),
      "sample_darkknight_stacking_defense": ("每被命中 2 次防御 +10，【叠加 3】。", "Every 2nd hit taken gives +10 defense, 【Stacking 3】.")})

# ------------------------------------------------------------------ 遭遇里的小怪(不是节点)
unit("mob_sentinel", "遗迹卫兵", "Ruin Sentinel", "白色遗迹里游荡的石质卫兵，举盾挡在路上。", "A stone sentinel that roams the white ruins, shield raised against intruders.",
     {"mob_sentinel_guard_up": ("[b]坚壁[/b]：每被普通攻击命中 3 次，防御 +6，【叠加 3】。", "[b]Stone Wall[/b]: every 3rd hit taken gives +6 defense, 【Stacking 3】.")})
unit("mob_archer", "石英弓手", "Quartz Archer", "石英雕成的弓手，躲在断墙后放冷箭。", "An archer carved from quartz, sniping from behind broken walls.",
     {"mob_archer_volley_pursuit": ("[b]齐射[/b]：每第 5 次普通攻击命中获得【追击 1】。", "[b]Volley[/b]: every 5th hit gains 【Pursuit 1】.")})
unit("mob_acolyte", "白袍侍僧", "White Acolyte", "仍在为早已沉默的神明祈祷的侍僧。", "An acolyte still praying to a god that has long fallen silent.",
     {"mob_acolyte_prayer_heal": ("[b]祷告[/b]：每 4 秒为生命比例最低的友军回复 45 生命。", "[b]Prayer[/b]: every 4 s heals the most wounded ally for 45.")})
# 第一章·红之章：大罪的余烬(普通怪物)
unit("mob_ember_wrath", "愤怒的余烬", "Ember of Wrath", "从烧塌的城市里站起来的怒火。手里永远托着一团火，看见什么就点着什么。",
     "Rage that rose from the collapsed city. It always holds a fire in its hand and sets alight whatever it sees.",
     {"mob_ember_wrath_spread": ("[b]愤怒的延烧[/b]：每 3 秒，选择一个随机的、身上没有燃烧的敌人，使其【燃烧】7 秒。",
                                 "[b]Spreading Wrath[/b]: every 3 s, sets a random enemy that isn't burning 【Burning】 for 7 s."),
      "mob_ember_wrath_release": ("[b]解放[/b]：每 5 秒，引爆一个身上有燃烧的敌人：对它立刻造成其剩余时间最长的那个燃烧的全部剩余伤害(每秒伤害 × 剩余秒数)的 {★120%/160%/220%}，然后结束那个燃烧。",
                                  "[b]Release[/b]: every 5 s, detonates a burning enemy: instantly deals {★120%/160%/220%} of all the damage its longest-lasting Burning has left (damage per second × seconds left), then ends that Burning.")})
unit("mob_ember_sloth", "怠惰的余烬", "Ember of Sloth", "懒得动弹的炉膛机器。一开始慢吞吞的，越打越热，炮口越来越红。",
     "A furnace machine too lazy to move. It starts sluggish, then heats up with every shot until its barrel glows red.",
     {"mob_ember_sloth_warmup": ("[b]怠惰的升温[/b]【叠加 8】：初始攻速 -60%。每次普通攻击获得 1 层【预热】：每层攻速 +{★12%/15%/20%}(可叠加，可驱散，持续整场战斗)。",
                                 "[b]Slothful Warm-up[/b] 【Stacking 8】: starts at -60% attack speed. Each normal attack grants 1 stack of 【Preheat】: +{★12%/15%/20%} attack speed per stack (stackable, dispellable, lasts the whole battle)."),
      "mob_ember_sloth_ignite": ("[b]引火[/b]：预热还没满时，普通攻击会挑身上燃烧最多(或者刚好够把预热叠满)的敌人，命中时吞掉它身上的全部燃烧，每吞掉一个额外获得 1 层预热。",
                                 "[b]Kindle[/b]: while Preheat isn't full, its normal attacks pick the enemy with the most Burning (or just enough to fill Preheat); on hit it swallows all of that enemy's Burning and gains 1 extra Preheat per Burning swallowed.")})
unit("mob_ember_lust", "色欲的余烬", "Ember of Lust", "一团纠缠的炽热触手。缠上谁就再也不松开，和对方一起烧。",
     "A knot of red-hot tentacles. Whatever it wraps around, it never lets go — and they burn together.",
     {"mob_ember_lust_heat": ("[b]色欲的热意[/b]：普通攻击命中时，与攻击对象一起进入【色欲的侵蚀】并一直维持：被缠住 / 正缠着对方的双方都无法移动，强制以彼此为目标；双方每秒各被施加一个持续 2 秒的【燃烧】。不可净化，不可驱散。",
                              "[b]Lustful Heat[/b]: on a normal attack hit, it and its target both fall under 【Lust's Erosion】 and stay that way: the entangled pair can't move and must target each other, and each gains a 2 s 【Burning】 every second. Can't be cleansed or dispelled."),
      "mob_ember_lust_regrowth": ("[b]蠕生[/b]：自己承受的【燃烧】伤害改为回复两倍的生命。",
                                  "[b]Writhing Growth[/b]: 【Burning】 damage it takes heals it for twice the amount instead.")})
unit("mob_ember_glut", "暴食的余烬", "Ember of Gluttony", "吞下了刀剑和盾牌的熔岩肉山。被打得越狠，喷出的赤油就越多。",
     "A molten heap that swallowed swords and shields. The harder you hit it, the more burning oil it spews.",
     {"mob_ember_glut_oil": ("[b]暴食的赤油[/b]【溅射 3】：每承受 3 次普通攻击，对自己造成最大生命 5% 的法术伤害(这个伤害会溅射：周围不分敌我受一半)，并使被波及的所有单位【燃烧】8 秒。",
                             "[b]Gluttonous Oil[/b] 【Splash 3】: every 3rd normal attack it takes, it deals 5% of its max health as magic damage to itself (this splashes: everyone nearby, friend or foe, takes half) and sets everything caught 【Burning】 for 8 s."),
      "mob_ember_glut_collapse": ("[b]崩解[/b]【吟唱 2】：生命低于 33% 时，蓄力 2 秒，然后每秒对自己触发一次暴食的赤油，直到倒下。",
                                  "[b]Collapse[/b] 【Chant 2】: below 33% health it charges for 2 s, then triggers Gluttonous Oil on itself every second until it falls.")})
unit("elite_ember_vanity", "虚荣的余烬", "Ember of Vanity", "盘踞在烧塌的都市中心的熔岩巨龙，浑身挂满抢来的金链与宝石。只要还有人在看，它就不肯熄灭。",
     "A molten dragon coiled at the heart of the burned-out city, draped in stolen gold chains and gems. As long as anyone is watching, it refuses to go out.",
     {"elite_vanity_corona": ("[b]虚荣的日冕[/b]【叠加 3】：战斗开始时获得 3 层【虚荣】。",
                              "[b]Corona of Vanity[/b] 【Stacking 3】: at the start of battle, gains 3 stacks of 【Vanity】."),
      "elite_vanity_blaze": ("[b]煌然[/b]：普通攻击施加 1 次【燃烧】，持续 {★3/4/5} 秒；带有【虚荣】时改为施加 3 次。",
                             "[b]Resplendence[/b]: normal attacks apply 【Burning】 once for {★3/4/5} s; with 【Vanity】 they apply it 3 times.")})
add("status.elite_vanity.desc",
    "可叠加，但效果不叠加(1 层和 3 层一样，层数只标记驱散进度)；可驱散，每次最多驱散 1 层，3 层都被驱散后结束；持续 20 秒。"
    "体型翻倍，最大生命、攻击力、防御力、法术抗性翻倍，受到的伤害 -50%，造成的伤害 +100%；普通攻击变成龙息：对一条宽 2 米的射线上的所有敌人造成伤害，自动选择能烧到最多敌人的方向。"
    "(没有虚荣时是单体爪击)",
    "Stacks, but the effect doesn't (1 stack = 3 stacks; stacks only track dispel progress). Dispellable, at most 1 stack per dispel; ends when all 3 are gone. Lasts 20 s. "
    "Doubles its size, max health, attack, armor and magic resist; takes 50% less damage and deals 100% more; normal attacks become a dragon breath that hits every enemy on a 2 m wide ray, aimed to burn as many as possible. "
    "(Without Vanity it claws a single target.)")
unit("mob_ember_envy", "嫉妒的余烬", "Ember of Envy", "一只拖着触须、浮在半空的熔岩眼球。它只盯着最耀眼的那个人，一直盯到对方烧起来为止。",
     "A molten eyeball drifting on trailing tendrils. It only ever stares at whoever shines brightest — and keeps staring until they catch fire.",
     {"mob_ember_envy_gaze": ("[b]嫉妒的凝视[/b]：普通攻击是一道一直维持着的射线(每 0.5 秒命中一次)，总是瞄准我方本场造成伤害最多的单位；每命中 3 次，使目标【燃烧】2 秒。",
                              "[b]Envious Gaze[/b]: its normal attack is a sustained beam (hits every 0.5 s) that always aims at your unit with the most damage dealt this battle; every 3rd hit sets the target 【Burning】 for 2 s."),
      "mob_ember_envy_spite": ("[b]妒恨[/b]【叠加 6】：射线每次命中，使目标获得 1 层【妒恨】：每层造成的伤害 -3%，持续 3 秒，可驱散。",
                               "[b]Spite[/b] 【Stacking 6】: each beam hit gives the target 1 stack of 【Spite】: -3% damage dealt per stack for 3 s; dispellable.")})
unit("mob_ember_greed", "贪婪的余烬", "Ember of Greed", "一本摊开的黑色魔典，金色包角上嵌着紫宝石，书页上烧着紫火。它把周围所有的火都吞进书里，再一口气吐出来。",
     "An open black grimoire with gold corners and violet gems, its pages burning with purple fire. It swallows every flame around it into its pages, then spits them all out at once.",
     {"mob_ember_greed_devour": ("[b]贪婪的吞噬[/b]【叠加 10】：每 2 秒，吞掉周围 4.5 米内所有单位(不分敌我)身上的全部【燃烧】，每吞掉一个获得 1 层【贪婪】(可驱散)。",
                                 "[b]Greedy Devouring[/b] 【Stacking 10】: every 2 s, swallows every 【Burning】 on all units within 4.5 m (friend or foe) and gains 1 stack of 【Greed】 per Burning swallowed (dispellable)."),
      "mob_ember_greed_burst": ("[b]金焰[/b]【溅射 2】：有【贪婪】时，普通攻击命中后消耗全部贪婪，对目标及其周围 2.4 米内的队友各造成 层数 × 攻击力 × 45% 的魔法伤害。",
                                "[b]Gilded Flame[/b] 【Splash 2】: with 【Greed】, a normal attack hit spends all of it to deal stacks × 45% attack as magic damage to the target and each of its allies within 2.4 m."),
      "mob_ember_greed_squander": ("[b]挥霍[/b]：金焰波及的每个敌人重新【燃烧】3 秒。",
                                   "[b]Squander[/b]: every enemy caught by Gilded Flame is set 【Burning】 again for 3 s.")})
# ---------------------------------------------------------------- 第一章-B·蓝之章：机械造物(命名 = 产品编号 + 功能)
unit("mob_sg_sentry", "SG-07 哨戒炮台", "SG-07 Sentry Turret",
     "穹顶城的标准哨戒单元：一根白色的立柱顶着方形的双管炮塔，琥珀色的瞄准镜一直在扫。它不会移动，但火控系统吃得下任何增幅。",
     "The dome city's standard sentry unit: a square twin-barrel turret on a white column, its amber sight always sweeping. It never moves, but its fire control drinks up any amplification it is given.",
     {"mob_sg_fire": ("[b]火控终端[/b]【增幅 {★2/2/3}】：普通攻击命中时，额外造成 攻击力 × 25% × 增幅 的法术伤害。",
                      "[b]Fire Control Terminal[/b] 【Amplify {★2/2/3}】: on a normal attack hit, deals an extra attack × 25% × Amplify as magic damage.")})
unit("mob_rx_relay", "RX-03 增幅中继", "RX-03 Amp Relay",
     "背着天线盘的细长仿生人。它自己打不了几下，它的工作是把增幅广播给周围的每一台机器。",
     "A slender android carrying an antenna dish. It barely fights itself; its job is to broadcast amplification to every machine around it.",
     {"mob_rx_broadcast": ("[b]中继广播[/b]【增幅 {★2/2/3}】：每 4 秒，6 米内的所有友军获得【增幅链路】5 秒：被动技能的增幅 +增幅(本技能的基础值，不吃增幅的加成)。",
                           "[b]Relay Broadcast[/b] 【Amplify {★2/2/3}】: every 4 s, all allies within 6 m gain 【Amp Link】 for 5 s: their passives' Amplify +Amplify (this skill's base value; not boosted by amplification).")})
unit("mob_hv_carrier", "HV-12 场域载具", "HV-12 Field Carrier",
     "悬浮的白色装甲车。车顶的发射环会把增幅力场投射到它开火的地方——场里的机器都更危险，站在里面的人也一样。",
     "A hovering white armored carrier. The emitter ring on its roof projects an amplification field wherever it fires — every machine inside is more dangerous, and so is anyone standing in it.",
     {"mob_hv_field": ("[b]增幅力场[/b]【增幅 {★2/2/3}】：开战时在脚下部署半径 2.5 米、持续 6 秒的增幅力场，之后每第 4 次普攻命中把同样的力场投射到目标脚下：场内所有单位(不分敌我)被动技能的增幅 +增幅(本技能的基础值)。",
                       "[b]Amp Field[/b] 【Amplify {★2/2/3}】: at the start of battle lays an amplification field (radius 2.5 m, 6 s) underfoot, then every 4th normal-attack hit projects the same field under the target: every unit inside, friend or foe, gets +Amplify (this skill's base value) to its passives' Amplify.")})
unit("mob_ax_assault", "AX-01 突击仿生人", "AX-01 Assault Android",
     "穹顶城的量产突击单元，两条小臂上各一片振动刃。每三刀里有一刀是真正的全功率输出。",
     "The dome city's mass-produced assault unit, a vibro-blade on each forearm. One cut in three is the real full-power stroke.",
     {"mob_ax_protocol": ("[b]输出协议[/b]【增幅 {★1/1/2}】：每第 3 次普通攻击命中，追加 攻击力 × 60% × 增幅 的物理伤害。",
                          "[b]Output Protocol[/b] 【Amplify {★1/1/2}】: every 3rd normal attack hit deals an extra attack × 60% × Amplify as physical damage.")})
unit("elite_ember_melancholy", "忧郁的余烬", "Ember of Melancholy", "在烧焦的街道上空缓缓漂浮的熔岩水母。它从不出手，只是把靠近的人都拖进自己的悲伤里。",
     "A lava jellyfish drifting slowly above the scorched streets. It never strikes — it just drags whoever comes near into its sorrow.",
     {"elite_melancholy_listless": ("[b]忧郁之潮[/b]【溅射 2】：不会攻击。每秒嘲讽周围 2.4 米内的敌人，持续 1.2 秒。",
                                    "[b]Tide of Melancholy[/b] 【Splash 2】: never attacks. Every second, taunts enemies within 2.4 m for 1.2 s."),
      "elite_melancholy_drown": ("[b]溺于悲伤[/b]：除了自己还有活着的友方单位时，受到的伤害 -50%。",
                                 "[b]Drowned in Sorrow[/b]: while any other ally is alive, takes 50% less damage."),
      "elite_melancholy_rain": ("[b]泪雨[/b]：周围 2.4 米内的敌人攻击速度 -25%(每秒刷新，持续 1.5 秒，可驱散)。",
                                "[b]Rain of Tears[/b]: enemies within 2.4 m get -25% attack speed (refreshed every second, lasts 1.5 s, dispellable).")})
unit("elite_ember_pride", "傲慢的余烬", "Ember of Pride", "戴着白色面具、顶着黑金尖冠的熔岩女王。她从不亲自弯腰——自有臣下替她燃烧。",
     "A molten queen in a white mask and a spiked black-and-gold crown. She never stoops to fight herself — her subjects burn in her place.",
     {"elite_pride_summon": ("[b]王座的召唤[/b]【召唤】：战斗开始时和之后每 8 秒，在身前召唤一只随机的余烬小怪(继承星级)；她召唤的小怪最多同时存在 3 只。",
                             "[b]Summons of the Throne[/b] 【Summon】: at the start of battle and every 8 s after, summons a random Ember minion in front of her (inheriting her star level); at most 3 of her summons at a time."),
      "elite_pride_edict": ("[b]傲慢敕令[/b]：每 4 秒，所有其他友方单位获得【傲慢的恩赐】，持续 4.5 秒：攻击力 +30%，攻击速度 +30%，受到的伤害 -20%。可驱散。",
                            "[b]Edict of Pride[/b]: every 4 s, every other ally gains 【Pride's Favor】 for 4.5 s: +30% attack, +30% attack speed, 20% less damage taken. Dispellable."),
      "elite_pride_grace": ("[b]众星拱月[/b]：【傲慢的恩赐】期间每秒回复 3% 最大生命。",
                            "[b]Court of Stars[/b]: while under 【Pride's Favor】, allies regenerate 3% max health per second.")})
unit("boss_ember_dragon", "龙的余烬", "Ember of the Dragon", "烧尽的都市最深处，披着黑金铠甲的龙之少女。她每走一步，脚下的余烬就再也不会熄灭。",
     "The dragon girl in black-and-gold armor at the very heart of the burned city. Wherever she steps, the embers will never go out again.",
     {"boss_dragon_heart": ("[b]龙之余烬[/b]：她在场时，余烬地块不会熄灭(踩上去照样【燃烧】，一直站在上面每 2.5 秒再烧一次)；"
                            "所有【燃烧】不再造成法术伤害，改为每秒直接移除 25 点生命上限(连同这部分生命，无视法术抗性与护盾，无法治疗回来)。她自己免疫燃烧。",
                            "[b]Dragon's Ember[/b]: while she is on the field, ember tiles never go out (stepping on one still sets you 【Burning】, and standing on it burns again every 2.5 s); "
                            "every 【Burning】 stops dealing magic damage and instead removes 25 max health per second (along with that much health — ignores magic resist and shields, and can't be healed back). She is immune to Burning."),
      "boss_dragon_ignite": ("[b]燎原[/b]：每 5 秒，在 3 个随机敌人脚下各点燃一格余烬；每 3 秒，随机 2 块燃烧的余烬各向旁边蔓延一格(场上最多 60 格)。",
                             "[b]Wildfire[/b]: every 5 s, ignites an ember tile under each of 3 random enemies; every 3 s, 2 random burning tiles each spread to a neighboring cell (60 cells at most)."),
      "boss_dragon_glaive": ("[b]龙焰薙刀[/b]：普通攻击(含长柄的贯穿)打到的每个敌人【燃烧】{★3/4/5} 秒。",
                             "[b]Dragonflame Glaive[/b]: every enemy her normal attacks hit (pierce included) is set 【Burning】 for {★3/4/5} s.")})
add("status.dragon_ember.desc",
    "龙的余烬在场时：余烬地块不会熄灭；所有燃烧改为每秒移除生命上限；她免疫燃烧。",
    "While the Ember of the Dragon is on the field: ember tiles never go out; all Burning removes max health each second instead; she is immune to Burning.")
add("status.ember_wither.desc",
    "被龙的余烬的燃烧烧掉的生命上限(这场战斗里回不来)。",
    "Max health burned away by the Ember of the Dragon's fire (gone for the rest of this battle).")
add("status.pride_favor.desc", "攻击力 +30%，攻击速度 +30%，受到的伤害 -20%。", "+30% attack, +30% attack speed, 20% less damage taken.")
add("status.melancholy_drown.desc", "受到的伤害 -50%(还有别的友方单位活着时)。", "Takes 50% less damage (while another ally is alive).")
unit("boss_cinder_colossus", "燃烬巨像(占位首领)", "Cinder Colossus (placeholder boss)", "【占位·首领】从燃烧都市深处、工厂区熔炉里爬出来的巨像。", "[Placeholder boss] A colossus that crawled out of a furnace deep in the burning factory district.",
     {"boss_cinder_colossus_quake_dmg": ("[b]震地[/b]：每第 5 次普通攻击时，对周围 3 米内的敌人造成 攻击力×160% 的魔法伤害并使其【燃烧】。",
                                         "[b]Quake[/b]: every 5th normal attack deals 160% attack as magic damage to enemies within 3 m and sets them 【Burning】.")})
unit("mob_guardian", "祭坛守卫", "Altar Guardian", "守护彩虹水晶祭坛的巨型石像。", "A giant stone statue guarding the rainbow crystal altar.",
     {"mob_guardian_ward_shield": ("[b]圣盾[/b]：每被普通攻击命中 4 次，获得最大生命 5% 的护盾。", "[b]Holy Ward[/b]: every 4th hit taken grants a shield of 5% max health.")})

# ------------------------------------------------------------------ 装备
def equip(id, zh, en, dzh, den):
    add("equipment.%s.name" % id, zh, en)
    add("equipment.%s.desc" % id, dzh, den)


# 基础武器：朴素，没有效果
equip("basic_sword", "铁剑", "Iron Sword", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_polearm", "木枪", "Wooden Spear", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_heavy", "铁大剑", "Iron Greatsword", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_dual", "铁匕首", "Iron Daggers", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_bow", "木弓", "Wooden Bow", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_crossbow", "木手弩", "Wooden Hand Crossbow", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_pistols", "燧发双枪", "Flintlock Pistols", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_rifle", "燧发步枪", "Flintlock Rifle", "朴素的基础武器。", "A plain basic weapon.")
equip("basic_focus", "学徒魔典", "Apprentice Grimoire", "朴素的基础武器。", "A plain basic weapon.")
# 带效果的武器
equip("sample_arcane_edge", "奥术刃", "Arcane Edge", "造成触发数值 4 倍的魔法伤害。", "Deals 4× the trigger value as magic damage.")
equip("sample_splash_potion", "溅射魔瓶", "Splash Flask", "溅射 2：回复触发数值 50% 的生命——治疗落在触发器指定的目标上(不分敌我)。", "Splash 2: heals 50% of the trigger value on whoever the trigger targets, friend or foe.")
equip("colorless_bow", "无色长弓", "Colorless Bow", "固定造成 30 点真实伤害，不吃触发数值。", "Deals a fixed 30 true damage, ignoring the trigger value.")
equip("frenzy_daggers", "亢奋双刃", "Frenzy Daggers", "固定造成 25 点物理伤害(可暴击)，并让自身攻速叠层。", "Deals a fixed 25 physical damage (can crit) and stacks attack speed on the wielder.")
equip("root_greatsword", "根须大剑", "Rootwood Greatsword", "固定造成 50 点物理伤害，并为自身回复 30 生命。", "Deals a fixed 50 physical damage and heals the wielder for 30.")
equip("desperation_greatsword", "绝境大剑", "Desperation Greatsword", "触发数值 ×2 的物理伤害；自身损失的生命越多，伤害越高。", "Deals 2× trigger value as physical damage; the lower the wielder's health, the harder it hits.")
equip("annual_ring_spear", "年轮长枪", "Annual Ring Spear", "触发数值 ×1 的物理伤害；每次发动使自身永久 +2 防御。", "Deals 1× trigger value as physical damage; each use permanently grants +2 defense.")
equip("ice_lance_tome", "冰枪魔典", "Ice Lance Grimoire", "触发数值 ×0.5 的魔法伤害，溅射 1；每次发动学习 +1，伤害 +8%。", "0.5× trigger value magic damage, splash 1; each use learns +1 for +8% damage.")
equip("fireball_tome", "火球魔典", "Fireball Grimoire", "触发数值 ×3 的魔法伤害，溅射 1；每次发动学习 +1，伤害 +12%。", "3× trigger value magic damage, splash 1; each use learns +1 for +12% damage.")
equip("blackblade", "黑剑", "Blackblade",
      "守誓节点的血色大剑(谁都能装)。赋予触发目标【暗色誓约】，然后为其提升相当于触发数值 50% 的生命上限；如果触发目标是召唤物，再赋予【光色誓约】，并再提升一次触发数值 50% 的生命上限(提升的那部分生命立刻回复)。"
      "【暗色誓约】：不可叠加，不可驱散，永久。【觉醒：击杀战斗中击杀过队友的敌人】：普攻间隔减半，伤害 +100%。"
      "【光色誓约】：不可叠加，不可驱散，永久。【觉醒：承受 20 次普攻】：自身、自身的召唤者即将阵亡时，立刻为其回复生命至上限(各一次)。",
      "Node Darkknight's blood-red greatsword (anyone can use it). Grants the trigger target 【Dark Oath】, then raises its max health by 50% of the trigger value; "
      "if the target is a summon, also grants 【Light Oath】 and raises max health by another 50% of the trigger value (the added health is restored at once). "
      "【Dark Oath】: doesn't stack, can't be dispelled, permanent. 【Awakening: kill an enemy that killed an ally this battle】: normal-attack interval halved, +100% damage. "
      "【Light Oath】: doesn't stack, can't be dispelled, permanent. 【Awakening: take 20 normal attacks】: when it or its summoner is about to die, restore that one to full health (once each).")
equip("order_sword", "秩序之剑", "Sword of Order", "双模：对友军提供触发数值 ×1.5 的护盾，对敌人造成触发数值 ×1 的魔法伤害。", "Dual-mode: 1.5× trigger value shield on allies, 1× trigger value magic damage on enemies.")
equip("energy_halberd", "能量长戟", "Energy Halberd", "双模：对友军提供触发数值 ×2 的护盾，对敌人造成触发数值 ×2 的魔法伤害。", "Dual-mode: 2× trigger value shield on allies, 2× trigger value magic damage on enemies.")
equip("healing_orb", "治愈水晶球", "Healing Crystal Ball", "回复触发数值 ×1 的生命；5% 大成功(×2)，5% 大失败(无效)。", "Heals 1× trigger value; 5% great success (×2), 5% fail (nothing).")
equip("wildfire_pistols", "燎原双枪", "Wildfire Pistols", "触发数值 ×1.2 的魔法伤害，溅射 2；5% 大成功(×2)，5% 大失败。", "1.2× trigger value magic damage, splash 2; 5% great success (×2), 5% fail.")
equip("harvest_rake", "丰收", "Bountiful Harvest", "耕植节点的钉耙(谁都能装)。冷却 20 秒：在触发目标脚下开出半径 1.2 米的【稻田】，持续 8 秒。"
      "【稻田】：不能被选中、不能被破坏、不分敌我；站在上面的任何单位每次回复生命时，额外回复触发数值 10% 的固定值。",
      "Node Peasant's rake (anyone can use it). 20 s cooldown: opens a 1.2 m 【Paddy Field】 under the trigger target for 8 s. "
      "【Paddy Field】: can't be targeted or destroyed, belongs to no side; every heal received by anyone standing on it gains a flat 10% of the trigger value.")
equip("sturdy_cane", "硬质手杖", "Sturdy Cane",
      "和星节点的手杖(谁都能装)。治疗量加成 +30%。【基本】【群攻 4】：为触发目标回复触发数值 ×1 的生命，溢出的治疗转化为护盾(护盾最多补到目标最大生命的 15%)。",
      "Node Druid's walking staff (anyone can use it). +30% healing bonus. 【Basic】【Multi Attack 4】: heals the trigger targets for 1× trigger value; "
      "overheal turns into shield (up to 15% of the target's max health).")
equip("meteor_staff", "流星爆魔杖", "Meteor Blast Staff",
      "灾星节点的长柄魔杖(谁都能装)。法术强度 +120，法术固定穿透 +40。冷却 8 秒【充能 2】【群攻 12】【溅射 3】(群攻打到的每个目标都会溅射)："
      "向触发目标召唤流星，落地后爆炸，造成触发数值 ×1.85 的魔法伤害。充能从 0 开始(开战第 8 秒才有第一层)。",
      "Node Witch's long staff (anyone can use it). +120 ability power, +40 flat magic penetration. 8 s cooldown 【Charged 2】【Multi Attack 12】【Splash 3】 "
      "(every multi-attack target splashes): calls a meteor down on each trigger target that explodes on landing for 1.85× trigger value magic damage. "
      "Charges start at 0 (the first one is ready 8 s into the battle).")
equip("dance_fans", "舞扇", "Dancing Fans",
      "舞星节点的一对舞扇(谁都能装)。攻击距离 +2、攻速 +10%；离目标远时甩出划弧线的魔力飞环。【基本】【双模】【群攻 10】：对队友回复触发数值 ×1.5 的生命，对敌人造成触发数值 ×1.5 的真实伤害。",
      "Node Dancer's pair of dancing fans (anyone can use them). +2 attack range, +10% attack speed; from afar she flings arcing rings of magic. "
      "【Basic】【Dual Mode】【Multi Attack 10】: heals teammates for 1.5× trigger value, deals 1.5× trigger value true damage to enemies.")
equip("wolf_blades", "狼双刃", "Wolf Fangs",
      "狂猎节点的狼牙双刀(谁都能装)。冷却 15 秒【暴击】【群攻 3】：造成触发数值 ×2 的物理伤害；如果触发时自己的血量低于 10%，伤害 ×3。",
      "Node Berserker's wolf-fang twin blades (anyone can use them). 15 s cooldown 【Crit】【Multi Attack 3】: deals 2× trigger value physical damage; "
      "if his health is below 10% when it triggers, the damage is tripled.")
equip("spell_notes", "咒语笔记", "Spell Notes",
      "求知节点的法典(谁都能装)。冷却 3 秒。【学习】。使触发者获得一个【乱念的咒语】，然后对触发目标造成触发数值 ×1 的法术伤害。"
      "【乱念的咒语】：每次获得都相互独立(不叠加、不刷新、不合并)，持续 6 秒，可被驱散；随机为以下之一，强度按这次发动时的学习计数 N："
      "攻速 +3%×N、法术强度 +3×N、伤害 +2%×N。",
      "Node Student's grimoire (anyone can use it). 3 s cooldown. 【Learning】. Grants the wielder one 【Garbled Incantation】, then deals 1× trigger value "
      "as magic damage to the trigger target. 【Garbled Incantation】: every copy is independent (no stacking, refreshing or merging), lasts 6 s, "
      "can be dispelled; it is one of the following at random, scaled by this activation's learning count N: attack speed +3%×N, "
      "ability power +3×N, or damage +2%×N.")
equip("dual_use_stunner", "两用电击器", "Dual-Use Stunner", "架盾节点的电击器(谁都能装)。攻击范围归零，只能打贴身的敌人；获得的护盾 +20%。",
      "Node Shielder's stun gun (anyone can use it). Attack range drops to zero — it only hits enemies in contact; shields received +20%.")
equip("rapidfire_arbalest", "连射弩", "Repeating Arbalest", "速射节点的连弩(谁都能装)。固定造成 25 点物理伤害，并【追击 1】再来一发。",
      "Node Archer's repeating crossbow (anyone can use it). Deals a fixed 25 physical damage, then 【Pursuit 1】 fires once more.")
equip("heart_syringe", "爱心针剂", "Heart Syringe",
      "护理节点的大针筒(谁都能装)。攻击力 +15，攻速 +15%；普通攻击射出针剂飞镖。冷却 1.5 秒【溅射 1.5】【暴击】：对触发目标造成触发数值 ×1 的物理伤害，"
      "该伤害视为普攻伤害(受到普攻伤害的减免对它生效；打在友方身上时会被护理节点的【广义治疗】转为治疗，溅射到敌人的部分照常造成伤害)。",
      "Node Nurse's big syringe (anyone can use it). +15 attack, +15% attack speed; normal attacks shoot syringe darts. "
      "1.5 s cooldown 【Splash 1.5】【Crit】: deals 1× trigger value physical damage to the trigger target; it counts as normal-attack damage "
      "(normal-attack damage reduction applies to it; on allies, Node Nurse's 【Care in the Broad Sense】 turns it into healing, while the part that splashes onto enemies still deals damage).")
equip("flame_banner", "赤焰战旗", "Crimson Flame Banner",
      "狩胜节点的燃烧战旗(谁都能装)。暴击率 +20%，暴击伤害 +40%。冷却 5 秒【暴击】【溅射 6】：为触发目标施加每 1 点触发数值 +1% 攻击力及攻速的强化"
      "(永久，重复获得时累加)；溅射出去的强化数值只有四分之一，只影响触发目标的队友，不会影响敌人。",
      "Node Gladiator's burning war banner (anyone can use it). +20% crit chance, +40% crit damage. 5 s cooldown 【Crit】【Splash 6】: "
      "grants the trigger target +1% attack and attack speed per point of trigger value (permanent; repeated grants add up); "
      "the splashed part is only a quarter as strong and only reaches the trigger target's teammates, never enemies.")
equip("hunt_flag", "狩猎旗标", "Hunting Flag",
      "狩胜节点上场时放进武器库的特殊物品，不可佩戴。拖到敌人身上：开战时狩胜节点会把它当作狩猎对象。用完回到武器库(再拖一次可以换人)；多个狩胜节点共用一面。",
      "A special item Node Gladiator puts in the armory while she is on the field; it can't be worn. Drag it onto an enemy: when the battle starts "
      "Node Gladiator treats it as her quarry. It returns to the armory after use (drag again to pick someone else); several Node Gladiators share one flag.")
equip("work_helper", "打工小帮手", "Little Work Helper",
      "空白节点的扳手(只有白色棋子能装备)。没有属性加成。效果：制造触发数值个白色晶球。",
      "Node Basic's wrench (only white pieces can equip it). No stat bonuses. Effect: creates as many white orbs as the trigger value.")
equip("talisman_edict", "如律所令", "Edict Talisman",
      "清心节点手里的黄符。治疗量加成 +20%，伤害增幅 +10%。【基本】【叠加 3】【固定值】【双模】：为目标施加一层【律令】，根据目标的阵营和定位，"
      "智能提升或降低它的最大生命值 / 法术强度 / 攻击力其中一种(每层固定 10%)：队友里的坦克提升最大生命，靠法术强度输出的提升法术强度，其余提升攻击力；敌人同理降低。"
      "【律令】：可叠加，可驱散，持续 7 秒；共 6 种变体，其中 3 种降低型属于负面状态。",
      "The yellow talisman in Node Taoist's hand. +20% healing bonus, +10% damage bonus. 【Basic】【Stacking 3】【Fixed】【Dual Mode】: applies a stack of "
      "【Edict】 to the target, smartly raising or lowering one of its max health / ability power / attack depending on its side and role (a fixed 10% per stack): "
      "allied tanks get max health, allies that fight with ability power get ability power, everyone else gets attack; enemies get the same stat lowered. "
      "【Edict】: stacks, dispellable, lasts 7 s; 6 variants, the 3 lowering ones are negative effects.")
equip("fleeting_revolver", "转瞬即逝", "Fleeting",
      "浪游节点的左轮手枪(谁都能装)。攻击范围大幅缩短(浪游节点拿着它正好在 1 米以内)，暴击伤害 +25%。【基本】：为触发目标施加【大口径子弹】。"
      "【大口径子弹】：不可叠加，不可驱散，持续时间无限。接下来 6 次普通攻击必定暴击，且基础伤害(计算所有增减伤之前的)增加触发数值 ×1 点；"
      "次数耗尽后，普通攻击改为必定不能暴击，且伤害 -30%。再次获得时重置必暴普攻的次数。",
      "Node Cowboy's revolver (anyone can use it). Attack range is cut way down (in his hands it's just under 1 m); +25% crit damage. "
      "【Basic】: grants the trigger target 【Big-Caliber Rounds】. 【Big-Caliber Rounds】: doesn't stack, can't be dispelled, lasts forever. "
      "The next 6 normal attacks always crit and their base damage (before any bonus or reduction) gains 1× the trigger value; once they're used up, "
      "normal attacks can never crit and deal 30% less damage. Gaining it again resets the guaranteed crits.")
equip("blazing_glow", "炽霞", "Blazing Glow",
      "炽照节点的太刀(谁都能装)，配一把黑鞘。攻击速度 +50%(炽照节点的拔刀连斩因此 0.75 秒以内一轮，剑痕续得上)。"
      "【基本】：对触发目标造成 触发数值 × 1 点物理伤害(视为普攻伤害)。0.1 秒内每已触发一次，这个倍数 × 1.05(一次引爆 10 层剑痕：× 1、1.05、1.05² …)。",
      "Node Samurai's tachi (anyone can use it), with a black scabbard. +50% attack speed (enough for his drawing flurry to come round within 0.75 s, "
      "so the scars keep going). 【Basic】: deals trigger value × 1 physical damage to the trigger target (counts as normal-attack damage). "
      "For every time it has already triggered within the last 0.1 s, the multiplier is × 1.05 (a 10-stack scar burst: × 1, 1.05, 1.05² …).")
equip("easy_shortbow", "易用短弓", "Handy Shortbow",
      "追猎节点的反曲短弓(谁都能装)。最大生命值 +150，攻击力 +20。冷却 1 秒【充能 3】：让触发者以一发免前后摇的普通攻击立刻攻击触发目标；"
      "触发数值每有 100 点，这一发造成原伤害的 100%。",
      "Node Hunter's recurve shortbow (anyone can use it). +150 max health, +20 attack. 1 s cooldown 【Charged 3】: the trigger holder instantly shoots "
      "the trigger target with a normal attack that skips wind-up and recovery; for every 100 trigger value, that shot deals 100% of the normal damage.")
equip("rainbow_flower", "虹光花", "Prism Bloom",
      "巫术节点的魔杖，顶端开着一朵七彩的花(谁都能装)。法术强度 +100，携带者被动技能的【增幅】+1。"
      "【基本】【固定值】【追击 2】：从 5 点物理伤害(视为普攻伤害)、5 点法术伤害(技能伤害)、5 点真实持续伤害(1 秒后结算)中随机造成一种(每一下各自随机)。",
      "Node Wizard's wand, a rainbow flower blooming at its tip (anyone can use it). +100 ability power; the wearer's passive skills get +1 【Amplify】. "
      "【Basic】【Fixed】【Pursuit 2】: deals one of these at random (each hit rolls again): 5 physical damage (counts as normal-attack damage), "
      "5 magic damage (skill damage), or 5 true damage over time (lands 1 s later).")
equip("drive_cannon", "驱动加农", "Drive Cannon",
      "改修节点的步枪(谁都能装)：木托黄铜件，枪管里流着一道紫光。物理伤害增幅 +20%，魔法伤害增幅 +20%。"
      "冷却 2.5 秒：让触发目标获得 3 秒【紧急维护】——可驱散、不可叠加；提供 25% 物理吸血与 25% 法术吸血；获得的瞬间立刻回复 触发数值 × 50% 的生命。",
      "Node Tinker's rifle (anyone can use it): wooden stock, brass fittings, a purple glow running down the barrel. +20% physical damage, +20% magic damage. "
      "2.5 s cooldown: the trigger target gains 【Emergency Maintenance】 for 3 s — dispellable, doesn't stack; 25% physical lifesteal and 25% spell lifesteal; "
      "the moment it's gained, it heals trigger value × 50%.")
equip("forgotten_star_flag", "某已不知名的星星的旗帜", "Flag of a Forgotten Star",
      "星旅节点扛着的旗(谁都能装)：白底蓝边，金色的盾徽，没人认得是哪颗星星的。获得护盾量 +30%，法术强度 +60。"
      "【基本】【群攻 99】【增幅 2】【固定值】：令触发目标流失当前生命的 2% × 增幅，或触发数值每 100 点 1% × 增幅，取高的那个(流失不被护盾挡、不吃增减伤)。",
      "The flag Node Astronaut carries (anyone can use it): white with a blue border and a golden crest — no one recognizes which star it belongs to. "
      "+30% shields received, +60 ability power. 【Basic】【Multi Attack 99】【Amplify 2】【Fixed】: the trigger target loses 2% × Amplify of its current health, "
      "or 1% × Amplify per 100 trigger value, whichever is higher (health loss ignores shields and damage modifiers).")
equip("prism_scythe", "幻彩镰刀", "Prism Scythe",
      "幻彩节点的镰刀(谁都能装)：长柄、发光的紫色月牙刃。看起来是长柄武器，其实是双手重武器。攻击力 +30，法术强度 +30。"
      "冷却 2.5 秒【群攻 3】：造成 触发数值 × 1 的物理伤害。",
      "Node Magi's scythe (anyone can use it): a long shaft and a glowing violet crescent blade. It looks like a polearm but counts as a two-handed heavy weapon. "
      "+30 attack, +30 ability power. 2.5 s cooldown 【Multi Attack 3】: deals trigger value × 1 physical damage.")
equip("lightning_gloves", "闪电手套", "Lightning Gloves",
      "迅游节点的手套(谁都能装)：露指手套、指节护板，手背上一圈发光的紫色能量环。移动速度 +20%。"
      "冷却 2 秒：造成 触发数值 × 80% 的魔法伤害，并把目标往远离触发者的方向击退 触发数值 × 0.004 米(最多 3 米)。",
      "Node Runner's gloves (anyone can use them): fingerless, with knuckle plates and a glowing violet energy ring on the back of each hand. +20% move speed. "
      "2 s cooldown: deals trigger value × 80% magic damage and knocks the target away from the user by trigger value × 0.004 m (up to 3 m).")
equip("myriad_words", "万语千言", "Myriad Words",
      "幻形节点的书简(谁都能装)：两捆白色的竹简，上面是谁也读不懂的文字。携带者被动技能的【充能】+2。效果：获得 触发数值 点经验和金币。",
      "Node Spy's bamboo slips (anyone can use them): two white bundles covered in writing no one can read. +2 【Charged】 on the wielder's passives. "
      "Effect: gain trigger value experience and gold.")
equip("necro_grimoire", "魔典", "Grimoire",
      "幻灵节点的魔典(谁都能装)：黑色封面、金色包角，封面上一颗紫宝石，翻开就有骷髅灵火飘出来。携带者作为召唤者时视为 +1 星。"
      "冷却 5 秒【充能 2】【召唤】：在触发目标背后召唤一只幽灵，令它的首次攻击额外造成 触发数值 × 0.03 的伤害。",
      "Node Medium's grimoire (anyone can use it): black covers, gold corners and a violet gem; skull wisps drift out when it opens. "
      "The wielder counts as +1 star for whatever she summons. 5 s cooldown 【Charged 2】【Summon】: summons a ghost behind the trigger target whose first attack "
      "deals extra damage equal to trigger value × 0.03.")
equip("farthest_string", "至远的弓弦", "Farthest String",
      "真望节点的弓(谁都能装)：深色木弓臂上缠满金色卷草，握把上一颗青色宝石，弓弦泛着青白的光。拉满弦的普通攻击额外选择两个目标。"
      "冷却 99 秒【充能 9】【固定值】：战斗开始时具有全部充能。刷新触发目标“每场战斗限一次”的技能，使之可以再触发一次。",
      "Node Leader's bow (anyone can use it): dark limbs wound with golden scrollwork, a cyan gem in the grip, a string that glows pale cyan. Fully drawn normal attacks "
      "pick two extra targets. 99 s cooldown 【Charged 9】【Fixed】: starts the battle fully charged. Refreshes the trigger target's once-per-battle skills so they can trigger again.")
equip("silent_lute", "无声琴", "Silent Lute",
      "心音节点的鲁特琴(谁都能装)：深色琴身上镶满蓝紫宝石。法术强度 +20；冷却 6 秒【双模】【固定值】：对队友施加 6% 伤害增幅，对敌人施加 -6% 伤害减免，持续 6 秒；"
      "触发者在吟唱时(拉弦蓄力也算吟唱)效果翻倍。",
      "Node Bard's lute (anyone can use it): a dark body studded with blue and violet gems. +20 ability power; 6 s cooldown 【Dual Mode】【Fixed】: grants an ally "
      "6% damage amplification, or gives an enemy -6% damage reduction, for 6 s; doubled if the wielder is chanting (drawing a bowstring counts).")
equip("old_censer", "旧香炉", "Old Censer",
      "调香节点的青铜香炉(谁都能装)：镂空的盖子里冒着青烟。治疗量 +15%；冷却 8 秒【群攻 6】【叠加 6】：每 150 点触发数值，为目标叠加 1 层【浸染】，持续 8 秒。",
      "Node Perfume's bronze censer (anyone can use it): teal smoke curls from its pierced lid. +15% healing; 8 s cooldown 【Multi-Attack 6】【Stacking 6】: "
      "every 150 points of trigger value gives the target 1 stack of 【Infusion】 for 8 s.")
add("status.infusion.desc",
    "可叠加，可驱散，负面状态。受到普通攻击时消耗 1 层：为攻击者回复 40 点生命，然后对持有者造成等量的法术伤害。",
    "Stacks, dispellable, a debuff. When hit by a normal attack, consumes 1 stack: heals the attacker for 40, then deals that much magic damage to the holder.")
add("status.chill.desc",
    "每次施加独立，可驱散，负面状态。每个降低 10% 攻击速度；身上的寒气降低的攻速加起来超过 40% 时，全部消耗，变为【冻结】，持续 5 秒。",
    "Each application is separate; dispellable; a debuff. Each lowers attack speed by 10%. When the chill on a unit adds up to more than 40%, all of it is consumed "
    "and becomes 【Frozen】 for 5 s.")
add("status.frozen.desc",
    "不可叠加，可驱散，负面状态。效果等同于眩晕。精英 / 首领从冻结中恢复的速度不会更快，但同一单位每场战斗每次被冻结的时长减半(5 → 2.5 → 1.25 秒……)；重复施加叠加持续时间。",
    "Doesn't stack; dispellable; a debuff. Works like a stun. Elites / bosses don't recover from it faster, but each freeze a unit takes in a battle lasts half as long "
    "as the last (5 → 2.5 → 1.25 s…); re-applying adds to the duration.")
add("status.regen.desc",
    "每次施加独立，可驱散。每个每秒回复 10 点生命(算施加者的治疗)。",
    "Each application is separate; dispellable. Each heals 10 health per second (counted as the applier's healing).")
equip("clotted_blood", "凝血", "Clotted Blood",
      "血嗜节点的结晶血刃(谁都能装)：黑边暗红的刃身上交错着发亮的血纹。持续伤害增幅 +25%，物理穿透 +20；冷却 7 秒【群攻 8】【叠加 6】【吟唱 3】："
      "吟唱结束时，对所有触发目标造成吟唱秒数次、每次 触发数值 × 12% 的法术伤害(技能伤害)，每次伤害叠加一层【崩裂】。",
      "Node Vampire's crystallised blood blade (anyone can use it): glowing blood veins cross its dark, black-edged blade. +25% damage over time, +20 armor penetration; "
      "7 s cooldown 【Multi-Attack 8】【Stacking 6】【Chant 3】: when the chant ends, hits every trigger target once per second chanted for trigger value × 12% magic damage "
      "(skill damage); each hit adds a stack of 【Fracture】.")
add("status.blood_crack.desc", "可叠加，可驱散，负面状态。每层使受到的每一跳持续伤害 +2(固定值)。", "Stacks, dispellable, a debuff. Each stack adds 2 (flat) to every tick of damage over time taken.")
add("status.bloodlust.desc", "可叠加，无法驱散，无限持续。造成 / 承受非持续伤害时，每有一层，就对目标叠加一层【失血】。",
    "Stacks, can't be dispelled, lasts forever. Whenever the holder deals or takes non-DoT damage, each stack gives the other side a stack of 【Bleeding】.")
add("status.bleed.desc", "可叠加，可驱散，持续 10 秒，负面状态。每层每 0.25 秒承受物理持续伤害，并为施加者回复最终伤害量的生命值。",
    "Stacks, dispellable, lasts 10 s, a debuff. Each stack deals physical damage over time every 0.25 s and heals the applier for the final damage dealt.")
add("status.focus_breath.desc", "可叠加，无法驱散，无限持续。每层提供暴击率(屏息节点：暴击率溢出的部分改为两倍的暴击伤害)。被近战敌人够得着时整个清掉。",
    "Stacks, can't be dispelled, lasts forever. Each stack grants crit chance (Node Sniper: crit chance beyond 100% becomes twice as much crit damage). "
    "Cleared entirely when a melee enemy can reach her.")
add("status.blood_feast.desc", "可叠加，无法驱散，无限持续。每层提供 4% 持续伤害增幅和 3 点固定伤害减免。",
    "Stacks, can't be dispelled, lasts forever. Each stack grants 4% damage-over-time amplification and 3 flat damage reduction.")
equip("light_heart", "光之心", "Heart of Light",
      "灭罪节点捧着的黄色水晶球(谁都能装)：球心亮着一点不灭的光。攻击力 +15，法术强度 +40；【基本】【群攻 6】："
      "如果触发目标的当前生命低于 12 × 触发数值，斩杀之(不触发目标的阵亡时效果)。",
      "The yellow crystal orb Node Absolver holds (anyone can use it): a light that never goes out burns at its heart. +15 attack, +40 ability power; "
      "【Basic】【Multi-Attack 6】: if a trigger target's current health is below 12 × trigger value, it is executed (its on-death effects don't trigger).")
equip("black_battlefield", "黑色战场", "Black Battlefield",
      "屏息节点的黑色狙击枪(谁都能装)：长枪管、大口径制退器、蓝色镜片的瞄准镜。弹匣只有【叠加 1】(每打一枪就要换弹)，相对的普通攻击倍率很高(×2.8，步枪 ×1.6)。"
      "攻击距离 +99，物理穿透 +30；【基本】【暴击】：对触发目标造成 触发数值 × 50% 的物理伤害。",
      "Node Sniper's black sniper rifle (anyone can use it): a long barrel, a heavy muzzle brake and a blue-lensed scope. Its magazine is only 【Stacking 1】 "
      "(reload after every shot), but its normal attacks hit very hard (×2.8; rifles ×1.6). +99 attack range, +30 armor penetration; "
      "【Basic】【Crit】: deals trigger value × 50% physical damage to the trigger target.")
equip("black_mission", "黑色任务", "Black Mission",
      "止息节点的黑色微冲(谁都能装)：折叠枪托、顶上一条导轨、长弹匣。法术抗性 +15，防御力 +15；冷却 2 秒【充能 3】：对目标发动一次普通攻击，"
      "然后令携带者获得【战场感知】。",
      "Node Commando's black SMG (anyone can use it): a folding stock, a top rail and a long magazine. +15 magic resistance, +15 armor; 2 s cooldown 【Charged 3】: "
      "performs a normal attack on the target, then grants the wielder 【Battle Sense】.")
add("status.battle_sense.desc", "可驱散，不可叠加，持续 3 秒。每 10 点触发数值获得 1% 普攻闪避率。",
    "Dispellable, doesn't stack, lasts 3 s. Grants 1% normal-attack dodge chance per 10 points of trigger value.")
add("status.commando_mark.desc", "无法驱散，不可叠加，负面状态。承受的伤害的伤害增幅提高。累计 3 秒时，止息节点一方攻击力最高的远程友军对它打出一发免费的普攻弹道，命中时消耗。",
    "Can't be dispelled, doesn't stack, a debuff. Damage it takes gets extra damage amplification. After 3 s, the ranged ally with the highest attack on Node Commando's side "
    "fires a free normal-attack shot at it, which consumes the mark on hit.")
equip("cyan_shadow", "青影", "Cyan Shadow",
      "踏影节点的青色长剑(谁都能装)：刃身亮着青光，金色十字护手嵌着青宝石，柄尾垂着青色流苏。攻击力 +20，法术强度 +30；冷却 8 秒【充能 1】【叠加 3】，"
      "开战拥有 1 层充能：获得 1 层【诛影】。",
      "Node Knight-errant's teal longsword (anyone can use it): the blade glows teal, a cyan gem sits in the gold cross-guard, and a teal tassel hangs from the pommel. "
      "+20 attack, +30 ability power; 8 s cooldown 【Charged 1】【Stacking 3】, starts the battle with 1 charge: gains 1 stack of 【Shadow Slay】.")
add("status.shadow_slay.desc", "可驱散，可叠加，无限持续。普攻伤害和技能伤害附带每层 25% × 触发数值点魔法持续伤害(2 秒内结算完)。",
    "Dispellable, stacks, lasts forever. Normal-attack and skill damage carry 25% × trigger value magic damage over time per stack (dealt over 2 s).")
add("status.shadow_veil.desc", "可叠加，可驱散，无限持续。持有时，除非已经是场上最后的合法目标，否则不能被敌人索敌。每层提供背后攻击时的伤害增幅。",
    "Stacks, dispellable, lasts forever. While held, enemies can't target the holder unless it's the last legal target left. Each stack grants damage amplification on attacks from behind.")
add("status.shadow_rot.desc", "可驱散，负面状态。持续 2 秒，每 0.5 秒承受一跳魔法持续伤害。", "Dispellable, a debuff. Deals magic damage over time every 0.5 s for 2 s.")
equip("blink_blade", "闪烁刀刃", "Blink Blade",
      "清扫节点的飞刀(谁都能装)：银色双刃，红宝石护手。暴击伤害 +40%，攻击力 +30。冷却 20 秒【充能 2】，开战时已有 1 层充能："
      "让触发者瞬移(没有中间的冲刺过程)到刚好能攻击到触发目标的位置，原本以她为目标的敌人重新索敌；然后立刻对触发目标发动普通攻击，"
      "触发数值每有 100 点 1 次。",
      "Node Maid's throwing knives (anyone can use them): silver double edges, ruby guards. +40% crit damage, +30 attack. 20 s cooldown 【Charged 2】, "
      "with 1 charge ready at the start of battle: the trigger holder teleports (no dash in between) to a spot where she can just reach the trigger target, "
      "and enemies that were targeting her pick new targets; she then immediately makes normal attacks against the trigger target — 1 for every 100 trigger value.")
equip("true_flower", "正花", "True Flower",
      "正行节点的长枪(谁都能装)：枪杆上缠绕着花藤与花瓣，末端绽放着一朵百合。攻击速度 +15%，伤害减免 +10%；冷却 1 秒【充能 3】："
      "对目标造成 触发数值 × 150% 的魔法普攻伤害，然后为装备者回复 触发数值 × 60% 的生命值。",
      "Node Noble's spear (anyone can use it): flowering vines and petals wind up the shaft, and a lily blooms at its tip. +15% attack speed, +10% damage reduction; "
      "1 s cooldown 【Charged 3】: deals trigger value × 150% magic normal-attack damage to the target, then heals the wielder for trigger value × 60%.")
add("status.lily_petal.desc", "可叠加，不可驱散，无限持续。每层提供治疗量加成；4 层起提供最大生命值，8 层起提供防御力与魔法抗性。有【花】时不再另算(花已经给了满层的加成)。",
    "Stacks, can't be dispelled, lasts forever. Each stack grants healing bonus; from 4 stacks it also grants max health, from 8 armor and magic resistance. "
    "Doesn't count while 【Bloom】 is up (Bloom already grants the full-stack bonuses).")
add("status.lily_stamen.desc", "可叠加，不可驱散，无限持续。普攻伤害获得等同于治疗量加成的最终伤害加成。普攻时消耗一层：这一下变成延长过的光剑 / 光矛 / 光炮，"
    "在大面积锥形范围内造成原普攻的数倍伤害，再把伤害量当作治疗量智能分配给全场受伤的友军。",
    "Stacks, can't be dispelled, lasts forever. Normal-attack damage gains a final damage bonus equal to the healing bonus. A normal attack spends one: "
    "it becomes an extended sword / spear / cannon of light that hits a huge cone for several times the normal attack, and the damage dealt is shared out "
    "as healing among every wounded ally.")
add("status.lily_bloom.desc", "不可叠加，不可驱散，无限持续。提供满层的【花瓣】加成。", "Doesn't stack, can't be dispelled, lasts forever. Grants the full-stack 【Petal】 bonuses.")
add("effect.lily_rebloom", "吟唱再绽之花(每秒 4 层花瓣 → 1 层花蕊)", "chant Bloom Anew (4 Petals → 1 Stamen per second)")
add("effect.lily_tick", "再绽之花的每一秒", "each second of Bloom Anew")
add("effect.lily_cone_heal", "消耗花蕊，把伤害量智能分配成治疗", "spend a Stamen and share the damage out as healing")
equip("hope", "希望", "Hope",
      "执剑节点的骑士剑(谁都能装)：银色的剑身上镶着金十字，金色护手正中嵌着一颗大蓝宝石。法术强度 +30，最大生命值 +300；冷却 9 秒【群攻 2】："
      "为触发目标回复 1 × 触发数值 的生命值。若其已阵亡，则令其以该生命值复活。",
      "Node Brave's knightly sword (anyone can use it): a gold cross inlaid on the silver blade, a large sapphire set in the gold guard. "
      "+30 ability power, +300 max health; 9 s cooldown 【Multi-Attack 2】: heals each trigger target for 1 × trigger value. "
      "If it has fallen, it is revived with that much health.")
add("status.brave_dream.desc", "无法驱散，无限持续。免疫负面状态；队友提供的属性提升类状态效果变为数倍。",
    "Can't be dispelled, lasts forever. Immune to debuffs; stat-boosting statuses from teammates are multiplied.")
add("status.brave_future.desc", "无法驱散，无限持续。执剑节点阵亡时留下的属性提升(她当时持有的全部属性提升加在一起)。",
    "Can't be dispelled, lasts forever. The stat boosts Node Brave left behind when she fell (everything she held, added together).")
add("effect.holy_sword", "圣剑：直接击杀普通怪物，否则造成最大生命 %s 倍的真实伤害", "Holy Sword: slay a common monster outright, or deal %s× its max health as true damage")
add("effect.brave_legacy", "把持有的属性提升扩散给全体队友", "spread the stat boosts she holds to every teammate")
equip("sinking_dream", "沉沦之梦", "Sinking Dream",
      "共歌节点的麦克风(谁都能装)：深棕色的握柄，金箍上镶着蓝宝石，柄尾垂着金十字和白流苏。攻击速度 +20%；冷却 4 秒【群攻 10】【双模】："
      "根据触发目标的阵营，令队友的伤害增幅效能提高(每 1.5 点触发数值 1%)，令敌人的伤害减免效能提高(每 1.5 点触发数值 1%)，持续 5.5 秒。",
      "Node Pacifist's microphone (anyone can use it): a dark-brown grip, a gold band set with a sapphire, a gold cross and white tassel hanging from the end. "
      "+20% attack speed; 4 s cooldown 【Multi-Attack 10】【Dual Mode】: depending on the trigger target's side, raises a teammate's damage amplification efficacy "
      "(1% per 1.5 trigger value) or an enemy's damage reduction efficacy (1% per 1.5 trigger value), for 5.5 s.")
add("status.intox.desc", "可以叠加，不可驱散，跨战斗持续。每层降低伤害减免、提高伤害增幅。",
    "Stacks, can't be dispelled, carries over between battles. Each stack lowers damage reduction and raises damage amplification.")
add("status.dream_amp.desc", "可驱散。伤害增幅效能提高：伤害增幅 × (1 + 效能)。", "Dispellable. Damage amplification efficacy up: damage amplification × (1 + efficacy).")
add("status.dream_sink.desc", "可驱散，负面状态。伤害减免效能提高：伤害减免 × (1 + 效能)——伤害减免是负的(沉醉)时会变得更负。",
    "Dispellable, a debuff. Damage reduction efficacy up: damage reduction × (1 + efficacy) — when it's negative (Enthralled) it gets even more negative.")
add("effect.gentle_field", "开局一段时间所有单位受到的伤害最终降低", "for a while at the start, all damage every unit takes is reduced")
add("effect.intox_song", "给所有其他人叠一层沉醉", "give everyone else a stack of Enthralled")
equip("butterfly", "飞蝶", "Butterfly",
      "白羽节点的一对手枪(谁都能装)：右手白、左手黑，枪身金饰，握把上嵌着金十字。攻击速度 +20%；【基本】：对触发目标发动普通攻击(受双持远程武器的追击影响)，"
      "该次普通攻击至多造成触发数值的伤害。",
      "Node Angel's pair of pistols (anyone can use them): white in the right hand, black in the left, gold trim, a gold cross set in each grip. "
      "+20% attack speed; 【Basic】: makes a normal attack on the trigger target (dual-pistol pursuit applies); that normal attack deals at most "
      "the trigger value in damage.")
add("status.funeral.desc", "可以叠加，不可驱散，负面状态。叠满时：普通怪物和棋子立刻死亡且不触发阵亡效果；精英 / 首领失去一部分生命值上限，并消耗送葬。",
    "Stacks, can't be dispelled, a debuff. When full: common monsters and nodes die at once without on-death effects; elites / bosses lose part of their max health "
    "and the stacks are spent.")
add("status.funeral_scar.desc", "无法驱散。送葬叠满时失去的生命值上限(累计)。", "Can't be dispelled. Max health lost to full Funeral stacks (cumulative).")
add("status.death_wish.desc", "打向队友的普通攻击改为回复其最大生命值的一小部分。", "Normal attacks that hit an ally heal a small share of its max health instead.")
add("effect.angel_heal", "回复目标 3% 的最大生命值", "heal 3% of the target's max health")
add("effect.funeral_mark", "叠加一层送葬", "apply a stack of Funeral")
add("effect.funeral_save", "不阵亡，改为叠加送葬", "survive, gaining Funeral instead")
equip("chaos_dice", "乱数", "Randomness",
      "奇兴节点的骰子法杖(谁都能装)：黑杖金箍，顶上的金环里托着一颗大白骰子。伤害增幅 +20%，攻击范围 +1；冷却 4 秒【群攻 3】："
      "随机对目标造成 0.05 × 1d20 × 3 × 触发数值 的伤害——1d20 为 1~5 物理、6~15 法术、16~20 真实。如果当前已阵亡的友军数大于等于仍存活的友军，则必定掷出 20。",
      "Node Arcanist's dice staff (anyone can use it): a black staff bound in gold, a big white die held in the golden ring at its head. +20% damage, "
      "+1 range; 4 s cooldown 【Multi 3】: deals 0.05 × 1d20 × 3 × trigger value to each target at random — physical on 1–5, magic on 6–15, true on 16–20. "
      "If the fallen allies are at least as many as the living ones, it always rolls 20.")
add("status.petrified.desc", "无法驱散。特殊的眩晕：不能行动，伤害减免 80%。", "Can't be dispelled. A special stun: can't act, 80% damage reduction.")
add("status.ancient_awake.desc", "无法驱散。从石化中苏醒，获得了法术强度和攻击力。", "Can't be dispelled. Woke from petrification with extra ability power and attack.")
add("effect.world_dice", "掷 2d10，发动无数世界", "roll 2d10 for Countless Worlds")
add("effect.petrify_wake", "结束石化，按时间获得法强和攻击力", "end petrification, gain ability power and attack by time")
add("effect.dice_damage", "掷 1d20 造成随机类型的伤害", "roll 1d20 for random-type damage")
equip("twin_candelabra", "双生烛台", "Twin Candelabra",
      "一座双头烛台：一支烛火是暖金色，一支是冷紫色——照在朋友身上是暖的，照在敌人身上是冷的。"
      "法术强度 +10；冷却 3 秒【双模】：对友方回复 触发数值 × 40% 生命；对敌方造成 触发数值 × 40% 魔法伤害。",
      "A two-headed candelabra: one flame burns warm gold, the other cold violet — warm on friends, cold on foes. "
      "+10 ability power; 3 s cooldown 【Dual-mode】: an ally heals for trigger value × 40%; an enemy takes trigger value × 40% magic damage.")
equip("rally_blade", "号令短剑", "Rallying Blade",
      "军官的短佩剑，剑柄挂着一条青色飘带。举起来的时候，身边的人会跟着往前冲。"
      "攻击力 +15，生命 +120；冷却 2 秒【群攻 3】【固定值】：触发目标获得 1 层【锋芒】(8 秒，最多 4 层)：每层攻击力 +6%、攻击速度 +6%。",
      "An officer's short sword with a cyan streamer on the hilt. Raise it, and the people around you charge. "
      "+15 attack, +120 health; 2 s cooldown 【Multi 3】【Fixed】: the trigger target gains a stack of 【Rallied】 (8 s, up to 4): +6% attack and +6% attack speed per stack.")
equip("spotter_rifle", "标定步枪", "Spotter's Rifle",
      "枪身上架着黄铜测距瞄准镜，枪口下一枚黄色的标定灯。先打一发，再让所有人往那儿打。"
      "攻击速度 +15%；冷却 1.5 秒【固定值】：对触发目标造成 120 物理伤害，并施加【破绽】(4 秒)：受到的伤害 +15%。",
      "A rifle with a brass rangefinder scope and a yellow marking lamp under the muzzle. Shoot once — then everyone shoots there. "
      "+15% attack speed; 1.5 s cooldown 【Fixed】: deals 120 physical damage to the trigger target and inflicts 【Exposed】 (4 s): it takes 15% more damage.")
equip("rockbreaker", "碎岩巨剑", "Rockbreaker",
      "像是从岩壁里直接凿出来的大剑，裂纹里透着冷蓝色的光。砸下去的不只是人，还有他们身上的甲。"
      "攻击力 +30，法术强度 +30，护甲 +15；冷却 4 秒【群攻 4】：对触发目标造成 触发数值 × 150% 物理伤害，并施加 1 层【碎甲】(8 秒，最多 3 层)：每层护甲与魔法抗性 -20。",
      "A greatsword that looks hewn straight out of a cliff, cold blue light seeping through its cracks. It breaks armor as well as bones. "
      "+30 attack, +30 ability power, +15 armor; 4 s cooldown 【Multi 4】: deals trigger value × 150% physical damage to the trigger targets and adds a stack of 【Cracked Armor】 "
      "(8 s, up to 3): -20 armor and magic resist per stack.")
equip("waning_moon", "蚀月", "Waning Moon",
      "一把弯成月牙的单刃弯刀，刀背嵌着一枚满月。每划一刀，月就更亮一分。"
      "攻击速度 +15%，暴击率 +5%；冷却 1 秒，两段效果：①【固定值】【学习】对触发目标造成 50 魔法伤害，本场每学习一次 +8%(最多 15 次)；"
      "② 再造成 触发数值 × 20% 魔法伤害。扣得越勤越强。",
      "A crescent saber with a full moon set into its spine. Every cut makes the moon a little brighter. "
      "+15% attack speed, +5% crit chance; 1 s cooldown, two parts: ① 【Fixed】【Learning】 deals 50 magic damage to the trigger target, "
      "+8% for every time it has learned this battle (up to 15); ② plus trigger value × 20% magic damage. The more often it fires, the stronger it gets.")
equip("puppet_lantern", "牵丝提灯", "Puppeteer's Lantern",
      "木偶师的提灯，灯下垂着几根银丝。它照着的东西会动起来——而且动得比原来更快。"
      "法术强度 +15；冷却 4 秒：携带者的所有召唤物获得【牵丝】(5 秒)：攻击力 +25%、攻击速度 +25%，并回复 触发数值 × 30% 生命。",
      "A puppeteer's lantern with silver threads hanging beneath it. Whatever it shines on moves — faster than before. "
      "+15 ability power; 4 s cooldown: all of the holder's summons gain 【Puppet Strings】 (5 s): +25% attack and attack speed, and heal for trigger value × 30%.")
equip("requiem_banner", "殉魂幡", "Requiem Banner",
      "一面手持的青白色短柄招魂幡，杆头挂着青铜铃。被它点过名的，倒下时也不会安静地走。"
      "生命 +150，法术强度 +20；冷却 2 秒【固定值】：携带者的所有召唤物获得【殉魂】：最大生命 +30%；它阵亡时，对 2 米内的敌人造成 它的最大生命 × 50% 的魔法伤害。",
      "A pale hand-held requiem banner with a bronze bell at its tip. Whoever it names does not go quietly. "
      "+150 health, +20 ability power; 2 s cooldown 【Fixed】: all of the holder's summons gain 【Requiem Soul】: +30% max health; when one falls, "
      "it deals its max health × 50% as magic damage to enemies within 2 m.")
equip("crimson_fang", "猩红獠牙", "Crimson Fangs",
      "一对兽牙形的短刃，刃根渗着暗红。咬中要害的时候，最痛。"
      "暴击率 +15%，暴击伤害 +30%；冷却 1.5 秒【暴击】：对触发目标造成 触发数值 × 70% 物理伤害，可以暴击。",
      "A pair of fang-shaped blades, dark red seeping at the roots. They hurt most when they find the vitals. "
      "+15% crit chance, +30% crit damage; 1.5 s cooldown 【Crit】: deals trigger value × 70% physical damage to the trigger target; it can crit.")
equip("keeneye_rifle", "锐眼步枪", "Keen-Eye Rifle",
      "一支深紫色的长步枪，黄铜瞄准镜的镜头是一只睁开的眼睛。用它的人总能看见对手最薄弱的那一点。"
      "暴击率 +15%，暴击伤害 +25%；暴击率超过 100% 的部分 1:1 转为暴击伤害；冷却 3 秒【双模】：对友方施加【锐眼】(5 秒：暴击率 +30%、暴击伤害 +30%)；"
      "对敌方造成 触发数值 × 80% 物理伤害【暴击】。",
      "A long deep-violet rifle whose brass scope lens is an open eye. Whoever holds it always sees the weakest point. "
      "+15% crit chance, +25% crit damage; crit chance above 100% turns into crit damage 1:1; 3 s cooldown 【Dual-mode】: an ally gains 【Keen Eye】 (5 s: +30% crit chance, +30% crit damage); "
      "an enemy takes trigger value × 80% physical damage 【Crit】.")
equip("echo_blade", "回响刃", "Echo Blade",
      "一把哑光黑的短剑，剑脊上一排青色的电容格。挥出去的力气，会有一部分回到你身上。"
      "攻击力 +15，被动【充能】上限 +1，“每数秒”计时器与充能回复速度 +15%；冷却 4 秒【双模】：对友方回复 触发数值 × 50% 生命；"
      "对敌方造成 触发数值 × 80% 物理伤害；同时携带者充能最不满的一个【充能】效果回复 1 层。",
      "A matte-black blade with a row of cyan capacitor cells along the spine. Part of every swing comes back to you. "
      "+15 attack, +1 max 【Charged】 on passives, +15% speed for \"every few seconds\" timers and charge recovery; 4 s cooldown 【Dual-mode】: "
      "an ally heals for trigger value × 50%; an enemy takes trigger value × 80% physical damage; either way, the holder's least-charged 【Charged】 effect regains 1 charge.")
equip("capacitor_codex", "蓄能法典", "Capacitor Codex",
      "一本封面嵌着电池的厚法典，书页边缘透着紫色的电光。存得越多，放得越狠。"
      "被动【充能】上限 +1，法术强度 +15；冷却 3 秒：对触发目标造成 触发数值 × (20% + 携带者所有【充能】效果剩余层数 × 3%) 的魔法伤害；"
      "触发目标是友方时改为回复 触发数值 × (140% + 剩余层数 × 10%) 生命。",
      "A heavy codex with a battery set into its cover, violet sparks along the page edges. The more it stores, the harder it hits. "
      "+1 max 【Charged】 on passives, +15 ability power; 3 s cooldown: deals trigger value × (20% + 3% × the charges left on all the holder's "
      "【Charged】 effects) as magic damage to the trigger target; if the target is an ally, heals it for trigger value × (140% + 10% × those charges) instead.")
# 武器的适配角色(game/core/fit_tags.gd)：触发器 / 武器的三组内置标签 + 武器提示里的"适配角色："
add("ui.card.fits", "适配角色", "Fits")
add("ui.fit.label", "适配角色：", "Fits: ")
add("ui.fit.none", "暂无(三组适配标签都对上的棋子)", "none yet (no piece matches all three fit tags)")
add("ui.fit.sep", "、", ", ")
add("ui.codex.fits_note", "触发器和这把武器的三组适配标签都对上、而且装得上的棋子", "Pieces with a trigger that matches all three of this weapon's fit tags, and that can equip it")
add("fit.tside.enemy", "对敌人", "Enemies")
add("fit.tside.ally", "对队友", "Allies")
add("fit.tside.both", "需要双模", "Needs dual-mode")
add("fit.count.multi", "对多个目标", "Several targets")
add("fit.count.single", "对单个目标", "One target")
add("fit.freq.high", "高频", "Frequent")
add("fit.freq.low", "低频", "Infrequent")
add("fit.wside.enemy", "对敌人", "Enemies")
add("fit.wside.ally", "对队友", "Allies")
add("fit.wside.dual", "提供双模", "Dual-mode")
add("fit.multi.yes", "有【群攻】", "【Multi Attack】")
add("fit.multi.no", "无【群攻】", "no 【Multi Attack】")
add("fit.multi.any", "不看触发目标", "Ignores the target")
add("fit.basic.yes", "【基本】", "【Basic】")
add("fit.basic.no", "无【基本】", "no 【Basic】")
add("status.puppet_strings.desc", "可以驱散。攻击力与攻击速度提高。", "Can be dispelled. More attack and attack speed.")
add("status.requiem_soul.desc", "无法驱散。最大生命提高；阵亡时对 2 米内的敌人造成自身最大生命一部分的魔法伤害。", "Can't be dispelled. More max health; on death, deals part of its max health as magic damage to enemies within 2 m.")
equip("kaleidoscope", "万花镜", "Kaleidoscope",
      "一支黄铜镜筒，另一头嵌着会转的碎晶。透过它看过去的人，总觉得光是从四面八方打过来的。"
      "法术强度 +20；冷却 3 秒【群攻 3】两段：① 对触发目标们各造成 60 点魔法伤害，并施加 1 层【碎光】(6 秒，叠加 2：魔抗 -15)；② 再各造成 触发数值 × 10% 的魔法伤害。",
      "A brass tube with turning crystal shards at the far end. Whoever is seen through it feels the light coming from every side. "
      "+20 ability power; 3 s cooldown 【Multi Attack 3】, two parts: ① 60 magic damage to each trigger target, plus 1 stack of 【Shattered Light】 "
      "(6 s, stacks to 2: -15 magic resist); ② trigger value × 10% magic damage to each.")
equip("stardust_orb", "星屑法球", "Stardust Orb",
      "一颗装着星屑的玻璃球，晃一下就有一粒星星飞出去。一粒不算什么，落得多了就不一样。"
      "法术强度 +15；【基本】：对触发目标造成 16 点魔法伤害，并施加 1 层【星痕】(5 秒，叠加 5：受到的伤害 +2%)。",
      "A glass orb full of stardust; give it a shake and a mote flies out. One mote is nothing. Many are something else. "
      "+15 ability power; 【Basic】: deals 16 magic damage to the trigger target and applies 1 stack of 【Star Mark】 (5 s, stacks to 5: +2% damage taken).")
equip("chord_fork", "和弦音叉", "Chord Fork",
      "一对紫铜音叉，敲一下，整支队伍的心跳都会对上拍子。"
      "生命 +100；两段【群攻 4】【双模】：①【基本】：队友获得 1 层【共鸣】(5 秒，叠加 4：攻击速度 +3%)，敌人受到 触发数值 × 30% 的魔法伤害；"
      "② 冷却 3 秒：队友获得 触发数值 × 35% 的护盾，敌人受到同样多的魔法伤害。",
      "A pair of violet-bronze tuning forks. Strike one and the whole squad's heartbeats fall into step. "
      "+100 health; two parts, 【Multi Attack 4】【Dual-mode】: ① 【Basic】: allies gain 1 stack of 【Resonance】 (5 s, stacks to 4: +3% attack speed), "
      "enemies take trigger value × 30% magic damage; ② 3 s cooldown: allies gain a shield of trigger value × 35%, enemies take as much magic damage.")
equip("ward_mirror", "晶壁手镜", "Ward Mirror",
      "一面银框的青色晶面手镜。照见的人身前会多出一层看不见的墙，墙有多厚，要看照的那一下有多用力。"
      "生命 +100，魔抗 +15；冷却 4 秒：触发目标获得 触发数值 × 70% 的护盾，以及【晶壁】(4 秒：受到的伤害 -12%)。",
      "A silver-framed cyan crystal hand mirror. Whoever it reflects gains an unseen wall, as thick as the moment that reflected them. "
      "+100 health, +15 magic resist; 4 s cooldown: the trigger target gains a shield equal to trigger value × 70%, and 【Crystal Wall】 (4 s: -12% damage taken).")
equip("erudite_case", "博闻书匣", "Erudite Case",
      "一只装满批注抄本的紫木书匣。每读完一卷，下一卷就读得更快、记得更牢。"
      "法术强度 +20；冷却 2 秒【学习】：对触发目标造成 触发数值 × 15% 的魔法伤害，每学习一次伤害 +10%(最多 15 次)。",
      "A violet-wood case full of annotated copies. Every volume finished makes the next one faster and surer. "
      "+20 ability power; 2 s cooldown 【Learning】: deals trigger value × 15% magic damage to the trigger target, +10% per learning (up to 15 times).")
add("status.prism_shatter.desc", "可以驱散。魔抗降低。", "Can be dispelled. Less magic resist.")
add("status.star_mark.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")
equip("twin_flintlock", "双子燧发枪", "Twin Flintlocks",
      "一对黄铜包角的燧发手枪，枪管长得过分。打得不快，但每一发都带着一团呛人的硝烟。"
      "攻击速度 +15%；两段：①【基本】：对触发目标造成 35 点物理伤害；② 冷却 2 秒：再造成 触发数值 × 50% 的物理伤害，并施加 1 层【硝烟】(5 秒，叠加 3：护甲 -6)。",
      "A pair of brass-capped flintlocks with absurdly long barrels. Not fast, but every shot leaves a choking cloud of smoke. "
      "+15% attack speed; two parts: ① 【Basic】: deals 35 physical damage to the trigger target; ② 2 s cooldown: deals trigger value × 50% physical damage "
      "and applies 1 stack of 【Gunsmoke】 (5 s, stacks to 3: -6 armor).")
equip("twin_chakram", "回旋双轮", "Twin Chakrams",
      "两只锯齿刃轮，扔出去会自己转回来。被它削过的人，脚步总要慢上半拍。"
      "攻击力 +20；【基本】【群攻 3】：触发目标们各受到 25 点物理伤害，并【迟滞】(3 秒：移动速度 -20%)。",
      "Two saw-edged rings that find their own way back. Whoever they graze is always half a step slower. "
      "+20 attack; 【Basic】【Multi Attack 3】: each trigger target takes 25 physical damage and is 【Hindered】 (3 s: -20% move speed).")
equip("fortune_cards", "命运双牌", "Fortune Cards",
      "两手各一扇扑克牌。给朋友抽一张好牌，给敌人抽一张坏牌——洗牌的人从来不看牌面。"
      "暴击率 +15%；冷却 2 秒【双模】：队友获得【好运】(10 秒：暴击率 +30%、攻击速度 +30%)；敌人获得【厄运】(10 秒：受到的伤害 +20%)。",
      "A fan of cards in each hand: a good card for a friend, a bad one for a foe. The dealer never looks. "
      "+15% crit chance; 2 s cooldown 【Dual-mode】: an ally gains 【Good Luck】 (10 s: +30% crit chance, +30% attack speed); "
      "an enemy gains 【Bad Luck】 (10 s: +20% damage taken).")
equip("bubble_blasters", "泡泡枪", "Bubble Blasters",
      "两把红色的玩具泡泡枪。泡泡打在身上会碎，碎掉的地方会变得更结实一点。"
      "生命 +200；【基本】：触发目标回复 35 点生命，并获得 25 点护盾。",
      "Two red toy bubble guns. A bubble bursts where it lands, and leaves that spot a little tougher. "
      "+200 health; 【Basic】: the trigger target heals 35 health and gains a 25-point shield.")
equip("resonance_bells", "共振双铃", "Resonance Bells",
      "一对刻着符文的青铜手铃。摇一下，声波在朋友身上凝成一层壳，在敌人身上震得骨头发疼。"
      "护甲 +20，魔抗 +20；冷却 2 秒【双模】【群攻 3】：队友获得 触发数值 × 150% 的护盾；敌人受到 触发数值 × 150% 的魔法伤害。",
      "A pair of rune-etched bronze hand bells. One ring, and the sound hardens into a shell on friends and rattles the bones of foes. "
      "+20 armor, +20 magic resist; 2 s cooldown 【Dual-mode】【Multi Attack 3】: allies gain a shield of trigger value × 150%; "
      "enemies take trigger value × 150% magic damage.")
add("status.gunsmoke.desc", "可以驱散。护甲降低。", "Can be dispelled. Less armor.")
add("status.chakram_slow.desc", "可以驱散。移动速度降低。", "Can be dispelled. Moves slower.")
add("status.good_luck.desc", "可以驱散。暴击率与攻击速度提高。", "Can be dispelled. More crit chance and attack speed.")
add("status.bad_luck.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")
add("status.crystal_wall.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")
add("status.chord_resonance.desc", "可以驱散。攻击速度提高。", "Can be dispelled. More attack speed.")
add("status.keen_eye.desc", "可以驱散。暴击率与暴击伤害提高。", "Can be dispelled. More crit chance and crit damage.")
add("effect.summon_aura", "强化携带者的召唤物", "empower the holder's summons")
add("effect.charge_refill", "回复充能", "restore a charge")
add("effect.charge_scaled_damage", "按剩余充能造成魔法伤害 / 治疗", "magic damage or healing scaled by charges left")
add("status.edge_rally.desc", "可以驱散。每层攻击力 +6%、攻击速度 +6%。", "Can be dispelled. +6% attack and +6% attack speed per stack.")
add("status.exposed.desc", "可以驱散。受到的伤害 +15%。", "Can be dispelled. Takes 15% more damage.")
add("status.armor_crack.desc", "可以驱散。每层护甲与魔法抗性 -20。", "Can be dispelled. -20 armor and magic resist per stack.")
equip("black_keys", "黑键", "Black Keys",
      "变奏节点的钢琴(谁都能装)：别人拿是一台托在手上的小钢琴；她本人弹的是一台黑漆金边的三角钢琴——她变成天使时，它就成了白键。"
      "法术强度 +40，攻击范围 +1；冷却 5 秒【永恒】【叠加 20】：若触发目标为本场战斗未阵亡过的友军，立刻击杀触发目标，"
      "令其获得 每 150 点触发数值 1 层【渐强】，该状态跨战斗保留。【渐强】：可以叠加，无法驱散，跨战斗持续；每层令持有者的“每数秒”计时器充能速度加快 3%。",
      "Node Pianist's piano (anyone can use it): in other hands it's a little piano held on the palm; she plays a black-lacquered, gold-trimmed grand — "
      "and when she becomes an angel, it becomes the White Keys. +40 ability power, +1 range; 5 s cooldown 【Eternal】【Stacking 20】: if the trigger target "
      "is an ally that hasn't fallen this battle, kills it outright and gives it 1 stack of 【Crescendo】 per 150 trigger value, kept between battles. "
      "【Crescendo】: stacks, can't be dispelled, lasts across battles; each stack speeds the holder's \"every few seconds\" timers by 3%.")
add("equipment.white_keys.name", "白键", "White Keys")
add("status.despair.desc", "可以驱散。每层每秒受到魔法持续伤害，攻速和“每数秒”计时器变慢。", "Can be dispelled. Magic damage per stack each second; slower attacks and timers.")
add("status.elation.desc", "可以驱散。每层每秒回复生命，攻速和“每数秒”计时器变快。", "Can be dispelled. Heals per stack each second; faster attacks and timers.")
add("status.crescendo.desc", "无法驱散，跨战斗保留。每层令“每数秒”计时器充能速度加快 3%。", "Can't be dispelled; kept between battles. Each stack speeds \"every few seconds\" timers by 3%.")
add("status.form_demon.desc", "恶魔形态：伤害增幅提高。", "Demon Form: more damage.")
add("status.form_angel.desc", "天使形态：治疗量提高。", "Angel Form: more healing.")
add("effect.pianist_form", "形态加成", "form bonus")
add("effect.pianist_flip", "回满生命并切换形态", "restore health and switch form")
add("effect.mood_stack", "叠加沮丧 / 亢奋", "stack Despair / Elation")
add("effect.black_keys", "击杀未阵亡过的友军，给予渐强", "kill an ally that hasn't fallen yet and grant Crescendo")
add("ui.form_to_angel", "切换为天使", "To Angel")
add("ui.form_to_demon", "切换为恶魔", "To Demon")
add("ui.form_tip", "表里之间：在恶魔形态(研究部)与天使形态(福利部)之间切换。", "Between Front and Back: switch between Demon Form (Research) and Angel Form (Welfare).")
equip("open_shut_key", "开与闭", "Open and Shut",
      "锁芯节点的巨钥匙(谁都能装)：暗绿长杆、金色钥匙头上嵌着红宝石。最大生命值 +350，攻击速度 +15%；冷却 6 秒【群攻 5】："
      "将触发目标向一个点大力拉拽，使之聚集，然后对其施加 每 200 点触发数值 1 秒 的【眩晕】。",
      "Node Cultist's giant key (anyone can use it): a long dark-green shaft with a golden, ruby-set bow. +350 max health, +15% attack speed; "
      "6 s cooldown 【Multi 5】: yanks the targets hard toward a single point, bunching them up, then 【Stuns】 them for 1 s per 200 trigger value.")
add("status.blood_rite.desc", "无法驱散。每秒受到真实伤害，无法被治疗；所在队伍施加的眩晕持续更久。",
    "Can't be dispelled. Takes true damage every second and can't be healed; stuns from this team last longer.")
add("effect.lock_all", "智能选一个圆形区域，造成魔法伤害并眩晕", "magic damage and a stun in the best circular area")
add("effect.gather_stun", "把目标拉到一起，然后眩晕", "pull the targets together, then stun them")
equip("kill_blade", "杀", "Kill",
      "无我节点的大太刀(谁都能装)：收在黑漆刀鞘里的长刀，墨绿柄绳、金色刀镡。攻击力 +50，攻击速度 +15%；【基本】【觉醒：场上仅剩一个敌人】【永恒】【学习】【固定值】【群攻 9】："
      "触发目标为召唤物时移除之，否则移除其 6% 的生命值上限。学习计数跨战斗累计；累计达 40 时，永久降低携带者一星，若已经是一星，移除携带者，武器返回武器库。",
      "Node Killer's ōdachi (anyone can use it): a long blade kept in a black lacquered scabbard, dark-green hilt wrap and a gold guard. +50 attack, +15% attack speed; "
      "【Basic】【Awakening: only one enemy left】【Eternal】【Learning】【Fixed】【Multi 9】: if the target is a summon, removes it; otherwise removes 6% of its max health. "
      "The learning count carries over between battles; when it reaches 40, the holder permanently loses a star — at 1 star, the holder is removed and the weapon "
      "returns to the armory.")
add("status.sever_scar.desc", "无法驱散。生命值上限被斩断了一截。", "Can't be dispelled. Part of the max health has been cut away.")
add("status.selfless_scar.desc", "无法驱散。被无我斩去了一截生命值上限。", "Can't be dispelled. Selfless cut away part of the max health.")
add("effect.phantom_strike", "召唤幻影 / 幻影跟着普攻", "summon the phantom / it attacks along")
add("effect.selfless_purge", "移除普通敌人，削减精英 / 首领生命上限", "remove normal enemies, cut elite / boss max health")
add("effect.sever", "移除召唤物 / 移除生命上限", "remove a summon / remove max health")
add("ui.selfless_btn", "无我", "Selfless")
add("ui.selfless_ready", "无我 · 就绪", "Selfless · Ready")
add("ui.selfless_tip", "移除仓库里一个无我节点(优先星级最低的)：下一场战斗开始时移除所有普通敌人，并削减精英 / 首领的生命上限。",
    "Remove one Node Killer from storage (lowest star first): when the next battle starts, all normal enemies are removed and elites / bosses lose max health.")
add("ui.selfless_done", "无我：下一场战斗开始时，她会拔刀", "Selfless: she will draw her blade when the next battle starts")
add("ui.err.selfless_ready", "下一场的无我已经准备好了", "Selfless is already set for the next battle")
add("ui.err.selfless_none", "仓库里没有别的无我节点", "There's no other Node Killer in storage")
add("ui.curse_star", "%s 的诅咒：%s 永久降为 ★%d", "The curse of %s: %s permanently drops to ★%d")
add("ui.curse_gone", "%s 的诅咒：%s 被带走了，%s 回到武器库", "The curse of %s: %s is taken away; %s returns to the armory")
equip("blessing_heart", "祝福之心", "Heart of Blessing",
      "心连节点的念珠(谁都能装)：一串藏青念珠，下面垂着镶蓝宝石的金十字。法术强度 +30；冷却 10 秒：若目标已阵亡，以 2 × 触发数值 的生命复活目标"
      "(召唤物也可以)，否则回复等量生命。",
      "Node Sister's rosary (anyone can use it): a string of navy beads with a gold cross set with a sapphire. +30 ability power; 10 s cooldown: "
      "if the target has fallen, revives it with 2 × trigger value health (summons too); otherwise heals that much.")
add("effect.mass_production", "召唤自身的复制", "summon a copy of herself")
add("effect.prayer_heal", "回复 + 清除一个负面状态", "heal + remove one debuff")
equip("coin_dagger", "匕首与金币", "Dagger & Coin",
      "巧运节点的匕首和幸运金币(谁都能装)：金护手的直刃匕首，左手里总抛着一枚金币。攻击速度 +15%；【基本】【学习】【永恒】："
      "携带者还没有【钱袋】就施加之，否则令其金币计数 + 触发数值。学习计数跨战斗保留。"
      "【钱袋】：不可叠加，不可驱散，无限持续，记录金币数量。每 2 秒，有一定概率翻倍或清空：翻倍 5% 起、清空 25% 起，学习计数越多翻倍越容易、清空越难，"
      "但会收敛——翻倍最多接近 25%、清空最少接近 5%(学习 10 次时两者都是 15%)；"
      "战斗结束时清空该状态，获得等同记录值的金币。",
      "Node Rogue's dagger and lucky coin (anyone can use them): a straight dagger with a gold guard, and a gold coin always flipping in the off hand. "
      "+15% attack speed; 【Basic】【Learning】【Eternal】: if the holder has no 【Coin Purse】 yet, gives one; otherwise adds the trigger value to its coins. "
      "The learning count carries over between battles. 【Coin Purse】: doesn't stack, can't be dispelled, lasts forever, and counts coins. "
      "Every 2 s it may double or empty: doubling starts at 5% and emptying at 25%; the more it has learned, the likelier doubling and the rarer emptying, "
      "but they level off — doubling only approaches 25% and emptying 5% (at 10 learned, both are 15%); "
      "when the battle ends it is emptied and you gain that much gold.")
add("status.money_bag.desc", "不可叠加，不可驱散，无限持续。记录金币数量；每 2 秒可能翻倍或清空，战斗结束时兑现成金币。",
    "Doesn't stack, can't be dispelled, lasts forever. Counts coins; every 2 s they may double or vanish; cashed in when the battle ends.")
add("status.true_dice.desc", "自己的概率掷两次取好的。", "His own odds are rolled twice, keeping the better one.")
add("effect.pickpocket", "概率获得金币", "chance to gain gold")
add("effect.true_dice", "概率重投取好", "reroll odds, keep the better")
add("effect.money_bag", "施加钱袋 / 往钱袋里加金币", "give a Coin Purse / add coins to it")
add("effect.money_bag_tick", "钱袋翻倍或清空", "Coin Purse doubles or empties")
add("effect.money_bag_cashout", "钱袋兑现", "cash in the Coin Purse")
equip("warhammer", "大锤", "War Hammer",
      "圣战节点的战锤(谁都能装)：深棕木柄缠着金箍，灰石锤头镶金边，两面刻着金色的日轮十字。法术强度 +30，伤害减免 +10%；"
      "冷却 4 秒【群攻 4】：施加【眩晕】，每 100 点触发数值持续 1 秒。",
      "Node Paladin's war hammer (anyone can use it): a dark wooden haft bound in gold, a grey stone head rimmed in gold with a golden sun-cross on both faces. "
      "+30 ability power, +10% damage reduction; 4 s cooldown 【Multi 4】: applies 【Stun】 for 1 s per 100 trigger value.")
add("status.quake_stance.desc", "砸地中：定在原地。", "Smashing the ground: rooted.")
add("effect.quake_slam", "砸地：锥形魔法伤害 + 破坏地形", "smash the ground: cone magic damage + shatter terrain")
add("effect.stun_from_value", "按触发数值眩晕", "stun by trigger value")
equip("emag_intro", "电磁学导论", "Introduction to Electromagnetism",
      "导向节点的法术书(谁都能装)：藏青封面、金色包角，封面上一道金色闪电，书脊挂着蓝宝石和金星坠子。攻击力 +40，普攻伤害增幅 +30%；"
      "冷却 3 秒【充能 2】【学习】【群攻 3】：施加【麻痹】8 秒。【麻痹】：不可叠加，可驱散，负面状态。持有者承受的伤害提升 每 30 点触发数值 (1 + 学习计数)%，"
      "普通攻击前摇完成时有同样的几率被打断、无法完成普攻；重复施加时取较高的数值。",
      "Node Psychic's spellbook (anyone can use it): a navy cover with gold corners and a gold lightning bolt, a sapphire and a gold star hanging from the spine. "
      "+40 attack, +30% normal attack damage; 3 s cooldown 【Charged 2】【Learning】【Multi 3】: applies 【Paralysis】 for 8 s. 【Paralysis】: doesn't stack, "
      "dispellable, a debuff. The holder takes (1 + learning count)% more damage per 30 trigger value, and has the same chance to be interrupted when a "
      "normal attack's wind-up completes; reapplying keeps the higher value.")
add("status.lightning_call.desc", "无法驱散。普通攻击需要吟唱，发射连锁闪电。", "Can't be dispelled. Normal attacks are chanted and release chain lightning.")
add("status.paralysis.desc", "不可叠加，可驱散，负面状态。承受的伤害提升；普通攻击前摇完成时有同样的几率被打断。",
    "Doesn't stack, dispellable, a debuff. Takes more damage; has the same chance to be interrupted when a normal attack's wind-up completes.")
add("effect.weather_change", "按章节改变战场天气", "change the battlefield weather by chapter")
add("effect.paralyze", "施加麻痹", "apply Paralysis")
equip("verdant_grove", "翠绿之林", "Verdant Grove",
      "守林节点的长杖(谁都能装)：缠着藤蔓的木杖，顶端的木环托着一颗绿宝珠，下面垂着红珠和白牙。最大生命值 +300，法术强度 +30；冷却 12 秒【充能 2】【学习】，"
      "开局拥有全部充能：获得每 40 点触发数值 (4 − 学习计数)% 的攻击速度，恢复每 30 点触发数值 (0 + 学习计数)% 的最大生命值。",
      "Node Warden's staff (anyone can use it): a vine-wrapped wooden staff whose ring-shaped head holds a green orb, with a red bead and a white fang hanging "
      "below. +300 max health, +30 ability power; 12 s cooldown 【Charged 2】【Learning】, starting with all charges: gains (4 − learning count)% attack speed "
      "per 40 trigger value and restores (0 + learning count)% max health per 30 trigger value.")
add("status.form_lion.desc", "无法驱散。攻击形态与武器无关：近战爪击，普攻倍率按最大生命值计算，带追击。", "Can't be dispelled. Attacks don't depend on the weapon: melee claws, scaling with max health, with Pursuit.")
add("status.form_spider.desc", "无法驱散。攻击形态与武器无关：近战毒牙，普攻命中叠加中毒。", "Can't be dispelled. Attacks don't depend on the weapon: venomous fangs; hits apply Poison.")
add("status.form_toad.desc", "无法驱散。攻击形态与武器无关：额外护甲与魔抗，普攻用长舌缠住目标。", "Can't be dispelled. Attacks don't depend on the weapon: extra armor and magic resistance; attacks bind the target with a tongue.")
add("status.poison.desc", "独立施加，可驱散，负面状态。每秒受到魔法持续伤害。", "Applied separately each time, dispellable, a debuff. Takes magic damage every second.")
add("status.toad_bind.desc", "无法驱散。和巨蟾蜍互相缠住：定在原地，只能以彼此为目标。", "Can't be dispelled. Bound to the toad: rooted, and both can only target each other.")
add("status.verdant_haste.desc", "可驱散，无限持续。攻击速度提高(每次发动累加)。", "Dispellable, lasts forever. Attack speed up (adds up with each use).")
add("effect.warden_shift", "切换形态", "change form")
add("effect.wild_will", "恢复 1 生命并获得护盾", "recover 1 health and gain a shield")
add("effect.verdant_grove", "按学习计数获得攻速 / 回复生命", "gain attack speed / restore health by learning count")
equip("calibration_rifle", "校准步枪", "Calibrated Rifle", "先把触发数值改写为目标最大生命的 3.5%，再造成等量魔法伤害。", "First rewrites the trigger value into 3.5% of the target's max health, then deals that much magic damage.")
equip("amplifier_crossbow", "增幅手弩", "Amplifier Crossbow", "先把触发数值 ×1.6，再造成其 60% 的物理伤害(可暴击)。", "First multiplies the trigger value by 1.6, then deals 60% of it as physical damage (can crit).")

# ------------------------------------------------------------------ 羁绊
def trait(id, zh, en, dzh, den, tiers):
    add("trait.%s.name" % id, zh, en)
    add("trait.%s.desc" % id, dzh, den)
    for th, (tzh, ten) in tiers.items():
        add("trait.%s.tier.%d" % (id, th), tzh, ten)


trait("faction_red", "赤锋", "Crimson Edge",
      "红色羁绊(计入红、紫、黄、黑色棋子)：攻击力与普攻伤害。",
      "Red trait (counts Red, Purple, Yellow and Black nodes): attack and normal-attack damage.",
      {2: ("攻击力 +8%，普攻伤害 +10%", "+8% attack, +10% normal-attack damage"),
       4: ("攻击力 +16%，普攻伤害 +20%", "+16% attack, +20% normal-attack damage"),
       6: ("攻击力 +28%，普攻伤害 +35%", "+28% attack, +35% normal-attack damage")})
trait("faction_blue", "蓝律", "Azure Cadence",
      "蓝色羁绊(计入蓝、紫、青、黑色棋子)：法术强度与计时加速——自己“每 x 秒”的效果和各种冷却走得更快。",
      "Blue trait (counts Blue, Purple, Cyan and Black nodes): ability power and haste — the holder's “every x s” effects and cooldowns run faster.",
      {2: ("法术强度 +8，计时加速 +5%", "+8 ability power, +5% haste"),
       4: ("法术强度 +20，计时加速 +10%", "+20 ability power, +10% haste"),
       6: ("法术强度 +35，计时加速 +16%", "+35 ability power, +16% haste")})
trait("faction_green", "繁茂", "Verdant Bloom",
      "绿色羁绊(计入绿、黄、青、黑色棋子)：攻击速度与状态叠加——施加【叠加】状态时额外多叠一层。",
      "Green trait (counts Green, Yellow, Cyan and Black nodes): attack speed and stacking — 【Stacking】 statuses the holder applies gain an extra stack.",
      {2: ("攻击速度 +10%", "+10% attack speed"),
       4: ("攻击速度 +20%，施加【叠加】状态时额外 +1 层", "+20% attack speed; 【Stacking】 statuses applied gain +1 stack"),
       6: ("攻击速度 +40%，施加【叠加】状态时额外 +1 层", "+40% attack speed; 【Stacking】 statuses applied gain +1 stack")})
trait("faction_purple", "紫电", "Violet Surge",
      "紫色羁绊(计入紫、黑色棋子；紫色棋子同时吃红、蓝羁绊)：每隔几秒蓄一次能，下一次普攻附带 (攻击力 + 法术强度) 换算的魔法伤害。",
      "Purple trait (counts Purple and Black nodes; Purple nodes also get Red and Blue): every few seconds the holder charges up, and its next normal attack "
      "adds magic damage based on (attack + ability power).",
      {2: ("每 5 秒：下一次普攻附带 (攻击力 + 法术强度) × 50% 的魔法伤害", "every 5 s: next normal attack adds (attack + AP) × 50% magic damage"),
       4: ("每 3 秒：下一次普攻附带 (攻击力 + 法术强度) × 80% 的魔法伤害", "every 3 s: next normal attack adds (attack + AP) × 80% magic damage")})
trait("faction_yellow", "金锐", "Gilded Edge",
      "黄色羁绊(计入黄、黑色棋子；黄色棋子同时吃红、绿羁绊)：每造成一次普攻 / 技能伤害，叠加一层【金锐】(攻击力提升，可叠加，无限持续)。",
      "Yellow trait (counts Yellow and Black nodes; Yellow nodes also get Red and Green): each normal-attack / skill hit adds a stack of 【Gilded Edge】 "
      "(more attack, stacks, lasts forever).",
      {2: ("每层攻击力 +1.5%，最多 8 层", "+1.5% attack per stack, up to 8"),
       4: ("每层攻击力 +2%，最多 12 层", "+2% attack per stack, up to 12")})
trait("faction_cyan", "沧澜", "Cerulean Tide",
      "青色羁绊(计入青、黑色棋子；青色棋子同时吃蓝、绿羁绊)：每隔几秒叠加一层【沧澜】(攻击速度与法术强度，可叠加，无限持续)。",
      "Cyan trait (counts Cyan and Black nodes; Cyan nodes also get Blue and Green): every few seconds the holder gains a stack of 【Cerulean Tide】 "
      "(attack speed and ability power, stacks, lasts forever).",
      {2: ("每 3 秒 +1 层：攻击速度 +3%、法术强度 +3，最多 6 层", "every 3 s +1 stack: +3% attack speed, +3 AP, up to 6"),
       4: ("每 2 秒 +1 层：攻击速度 +4%、法术强度 +4，最多 8 层；每 4 秒，自身其他可叠加的增益状态各 +1 层",
           "every 2 s +1 stack: +4% attack speed, +4 AP, up to 8; every 4 s, each of the holder's other stacking buffs gains +1 stack")})
add("status.potent_dose", "强效药物", "Potent Dose")
add("status.potent_dose.desc", "下一次施加[叠加]状态时额外多叠 1 层，然后用掉。", "The next [Stacking] status you apply gains one extra stack, then this is spent.")
add("status.purple_charge.desc", "不可叠加。下一次普攻附带 (攻击力 + 法术强度) 换算的魔法伤害，然后消耗。",
    "Doesn't stack. The next normal attack adds magic damage based on (attack + ability power), then it's consumed.")
add("status.yellow_edge.desc", "可叠加，无限持续。每层提升攻击力。", "Stacks, lasts forever. Each stack raises attack.")
add("status.cyan_tide.desc", "可叠加，无限持续。每层提升攻击速度与法术强度。", "Stacks, lasts forever. Each stack raises attack speed and ability power.")

# 通用武器 · 分批文件的文本(tools/weapons/<批>_loc.py：直接用这里的 equip / add)
import glob as _glob
for _lf in sorted(_glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "weapons", "*_loc.py"))):
    exec(compile(open(_lf, encoding="utf-8").read(), _lf, "exec"))

import sys as _sys
_sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from filelock import lock as _lock
with _lock("loc"):                 # 并行时别同时写；原子替换：别的进程启动时不会读到写了一半的文件
    for name, table in [("zh", Z), ("en", E)]:
        _dst = os.path.join(ROOT, name + ".json")
        _tmp = _dst + ".tmp%d" % os.getpid()
        with open(_tmp, "w", encoding="utf-8") as f:
            json.dump(table, f, ensure_ascii=False, indent=1, sort_keys=True)
        os.replace(_tmp, _dst)
print("loc keys:", len(Z), len(E))
