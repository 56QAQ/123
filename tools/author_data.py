"""内容编写脚本：生成 game/data 下的 JSON(单位/装备/羁绊/商店/关卡)。
运行时游戏只读 JSON；这里只是让"数值表 + 星级表"写起来短。用法: python tools/author_data.py
数据契约(与源项目一致)：
  · 单位 triggers = 触发面；passive_abilities = 被动能力(必须能与本单位某触发器按 tag 配对)
  · 装备 = 武器：weapon_class(9 大类，决定射程/普攻倍率/普攻动画) + 属性 + abilities(不完整的载荷，
    必须 required_trigger_tags 含 equipment_payload)。每个大类有一把 basic=true 的"基础武器"(无效果无属性)
  · 单位 base_weapon_class = 没装备武器时自动拿的基础武器大类；weapon_classes = 允许装备的大类(空 = 不限)
  · 羁绊 tiers.*.pairs = 触发器(tag trait_payload)+能力
"""
import glob, json, os, shutil

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "data")


def S(**kw):
    base = dict(attack_power=10.0, ability_power=0.0, defense=0.0, magic_resistance=0.0, max_health=100.0,
                health_regen_per_second=0.0, physical_lifesteal=0.0, spell_lifesteal=0.0, omnivamp=0.0,
                crit_chance=0.05, crit_damage=1.5, physical_flat_penetration=0.0, physical_percent_penetration=0.0,
                magic_flat_penetration=0.0, magic_percent_penetration=0.0, move_speed=1.0,
                attack_speed_multiplier=1.0,
                damage_dealt_pct=0.0, damage_dealt_flat=0.0, damage_taken_pct=0.0, damage_taken_flat=0.0,
                healing_done_pct=0.0, healing_received_pct=0.0)
    base.update(kw)
    # 射程与基础攻击间隔由武器大类决定(GC.WEAPON_CLASSES)，单位数值里不再写
    for k in ("attack_range", "attack_base_interval_seconds"):
        base.pop(k, None)
    return base


def W(base, allowed=None, offhand=""):
    """单位的武器字段：基础武器大类 + 可用大类(None = 只能用基础大类，[] = 不限)"""
    d = {"base_weapon_class": base, "weapon_classes": [base] if allowed is None else allowed}
    if offhand:
        d["offhand"] = offhand
    return d


def T(id, timing, tags, count=1, count_star=None, mode="fixed", ratio=1.0, ratio_star=None, flat=0.0, flat_star=None,
      rule="current_attack_target", team="enemy", radius=0.0, sort="", max_targets=0, cd_frames=0, cd_sec=None,
      max_acts=0, conds=None, kw="", stat="", status="", alt=None, unlock=1):
    d = {"id": id, "timing": timing, "event_count_threshold": count, "base_value_mode": mode,
         "base_value_ratio": ratio, "base_value_flat": flat, "target_rule": rule, "team_filter": team, "tags": tags}
    if count_star:
        d["event_count_threshold_by_star"] = count_star
    if ratio_star:
        d["base_value_ratio_by_star"] = ratio_star
    if flat_star:
        d["base_value_flat_by_star"] = flat_star
    if radius:
        d["target_radius"] = radius
    if sort:
        d["target_sort_rule"] = sort
    if max_targets:
        d["max_targets"] = max_targets
    if cd_sec is not None:
        d["cooldown_seconds"] = cd_sec
    elif cd_frames:
        d["cooldown_frames"] = cd_frames
    if max_acts:
        d["max_activations_per_battle"] = max_acts
    if conds:
        d["runtime_conditions"] = conds
    if kw:
        d["base_value_keyword"] = kw
    if stat:
        d["base_value_stat_id"] = stat
    if status:
        d["base_value_status_id"] = status
    if alt:
        d["alt_conditions"] = alt
    if unlock > 1:
        d["unlock_star"] = unlock
    return d


def A(id, cls, effect, mult=1.0, fixed=0.0, keywords=None, kv=None, kv_star=None, timings=None, tags=None, cfg=None,
      cooldown=0.0, priority=100, charges=0, unlock=1):
    d = {"id": id, "ability_class": cls, "effect_type": effect, "value_multiplier": mult, "fixed_value": fixed,
         "keywords": keywords or [], "accepted_timings": timings or [], "required_trigger_tags": tags or [],
         "effect_config": cfg or {}, "cooldown": cooldown, "priority": priority}
    if kv:
        d["keyword_values"] = kv
    if kv_star:
        d["keyword_values_by_star"] = kv_star
    if charges:
        d["max_charges"] = charges
    if unlock > 1:
        d["unlock_star"] = unlock
    return d


_WRITTEN = set()


def write(sub, id, data):
    """原子地写一个数据文件(先写临时文件再替换)：别的进程(并行的测强度 / 测试)启动时不会读到写了一半的 JSON。"""
    p = os.path.join(ROOT, sub)
    os.makedirs(p, exist_ok=True)
    dst = os.path.join(p, id + ".json")
    tmp = dst + ".tmp%d" % os.getpid()
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    os.replace(tmp, dst)
    _WRITTEN.add(os.path.normpath(dst))


def clear():
    """以前是先把 units / equipment / traits 整个删掉再写——别的进程这时候启动会少数据。现在改成原地覆盖，写完再删掉没写到的旧文件(purge_stale)。"""
    _WRITTEN.clear()


def purge_stale():
    for sub in ("units", "equipment", "traits"):
        for f in glob.glob(os.path.join(ROOT, sub, "*.json")):
            if os.path.normpath(f) not in _WRITTEN:
                os.remove(f)


NA = "OnNormalAttackHit"
HIT = "OnHitByNormalAttack"

# =====================================================================  单位
units = []

# =====================================================================  重构(2026-09-30 起)
# 重构过的内容带 "reworked": True(内容进度表 docs/CONTENT_STATUS.md 由 tools/content_status.py 生成)。约定：
#   · 稀有度 = cost；基础数值取职业模版 TEMPLATE(role, rarity)，个别棋子再微调
#   · 稀有度 1/2/3 的棋子：被动 1 一开始就有，被动 2 两星解锁(unlock_star=2，触发器与能力都标)
REWORKED = set()


def TEMPLATE(role, rarity, **kw):
    """职业模版：同职业同稀有度的基础数值。现在定了 1 费射手(= 单人 DPS 基准的来源)、1/2 费坦克、1 费施法者"""
    t = {
        ("archer", 1): dict(attack_power=104, magic_resistance=20, max_health=340, move_speed=1.4),
        ("tank", 1): dict(attack_power=52, defense=50, magic_resistance=34, max_health=1300, move_speed=1.9, attack_speed_multiplier=0.75),
        ("tank", 2): dict(attack_power=60, defense=60, magic_resistance=40, max_health=1500, move_speed=1.9, attack_speed_multiplier=0.7),
        ("tank", 4): dict(attack_power=70, defense=80, magic_resistance=60, max_health=2000, move_speed=1.9, attack_speed_multiplier=0.7),
        # 施法者：普攻很弱(伤害靠触发器 × 法术强度)，法术强度 0 起步(全靠武器与成长)，和射手一样脆
        ("caster", 0): dict(attack_power=40, ability_power=0, magic_resistance=25, max_health=380, move_speed=1.3),   # 稀有度 0(空白节点)：同 1 费
        ("caster", 1): dict(attack_power=40, ability_power=0, magic_resistance=25, max_health=380, move_speed=1.3),
        ("caster", 2): dict(attack_power=55, ability_power=0, defense=8, magic_resistance=30, max_health=700, move_speed=1.3),
        ("caster", 3): dict(attack_power=70, ability_power=0, magic_resistance=35, max_health=950, move_speed=1.3),
        ("caster", 4): dict(attack_power=80, ability_power=80, defense=10, magic_resistance=40, max_health=1150, move_speed=1.3),   # 4 费起法强不再从 0 开始
        # 战士：近战输出，比坦克脆、比射手硬
        ("warrior", 1): dict(attack_power=78, defense=30, magic_resistance=22, max_health=1100, move_speed=2.2, attack_speed_multiplier=0.85),
        ("warrior", 2): dict(attack_power=115, defense=40, magic_resistance=25, max_health=1400, move_speed=2.4, attack_speed_multiplier=0.9),
        ("warrior", 3): dict(attack_power=170, defense=55, magic_resistance=35, max_health=2000, move_speed=2.4, attack_speed_multiplier=0.9),
        ("warrior", 4): dict(attack_power=200, defense=70, magic_resistance=45, max_health=2600, move_speed=2.6, attack_speed_multiplier=0.9),
        ("archer", 2): dict(attack_power=135, defense=10, magic_resistance=22, max_health=560, move_speed=1.5),
        ("archer", 3): dict(attack_power=160, defense=12, magic_resistance=26, max_health=780, move_speed=1.5),     # 2026-10-07(白羽节点)：2 费与 4 费之间
        ("archer", 4): dict(attack_power=180, defense=15, magic_resistance=30, max_health=1000, move_speed=1.6),
        # 刺客：切后排的输出，比战士脆、跑得快
        ("assassin", 1): dict(attack_power=70, defense=10, magic_resistance=10, max_health=420, move_speed=3.0),
        ("assassin", 2): dict(attack_power=110, defense=25, magic_resistance=25, max_health=950, move_speed=2.8),
        ("assassin", 3): dict(attack_power=160, defense=30, magic_resistance=30, max_health=1250, move_speed=3.0),
        ("assassin", 4): dict(attack_power=220, defense=35, magic_resistance=35, max_health=1600, move_speed=3.2),
    }[(role, rarity)]
    t = dict(t)
    t.update(kw)
    return S(**t)


RAPID_FIRE_AS = {"1": 0.10, "2": 0.15, "3": 0.20}       # 【连射】每层攻速(随施加者星级)
POP = "OnNormalAttackPerform"

# 红 · 工程 · 1费 · 射手模版 —— 速射节点
units.append({
    "id": "node_archer", "cost": 1, "role": "archer", "template": "archer", **W("rifle", ["rifle", "crossbow", "pistols"]),
    "faction_id": "red", "profession_id": "engineering", "model": "archer", "reworked": True,
    "radius": 0.42,                     # 重构后没有"射手本能"(优先打射程内最低血)：用默认的最近目标
    "base_stats": TEMPLATE("archer", 1),
    "triggers": [
        # 被动 1 连射：每发动 2 次普攻
        T("node_archer_rapid_fire", POP, ["normal_attack", "passive_rapid_fire"], count=2, rule="self", team="ally"),
        # 被动 2 快速装填(2 星)：持步枪时开战即减半装弹时间；每次装弹完成也给 1 层连射(与被动 1 同一个能力配对)
        T("node_archer_quick_reload", "OnBattleStart", ["battle_start", "passive_quick_reload"], rule="self", team="ally",
          conds=[{"type": "source_weapon_class", "classes": ["rifle"]}], unlock=2),
        T("node_archer_reload_rapid_fire", "OnReloadComplete", ["reload", "passive_rapid_fire"], rule="self", team="ally",
          conds=[{"type": "source_weapon_class", "classes": ["rifle"]}], unlock=2),
        # 触发器 改装箭头：每第 3 次普攻命中，或步枪装弹后的第一次普攻命中；目标 = 这次普攻的目标，触发数值 10
        T("node_archer_mod_arrowhead", NA, ["normal_attack", "equipment_payload"], count=3, flat=10.0,
          alt=[{"type": "event_metadata_equals", "key": "hits_since_reload", "value": "1"}]),
    ],
    "passive_abilities": [
        A("node_archer_rapid_fire_buff", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3},
          timings=[POP, "OnReloadComplete"], tags=["passive_rapid_fire"],
          cfg={"status_id": "rapid_fire", "duration": 3.0, "flags": ["buff", "dispellable"],
               "stats_by_star": {"attack_speed_multiplier": {"pct": RAPID_FIRE_AS}}}),
        A("node_archer_quick_reload", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"],
          tags=["passive_quick_reload"], unlock=2,
          cfg={"status_id": "quick_reload", "stats": {"reload_time_pct": {"flat": -0.5}}, "flags": ["hidden"]}),
    ],
})

# 红 · 安保 · 2费 · 战士 —— 誓约节点(触发器示例：被打计数)
# 红 · 安保 · 1费 · 战士模版 —— 守誓节点(猫耳红发、黑甲紫披风的少年骑士)
# 数值目标(用户)：大多数时候他没有被动 2，所以升星提升偏高；被动 1 的觉醒不白送时，同星级单挑只打得过速射节点；
#   白送了(开战就当作有队友阵亡)，能打赢同星级的 1 费坦克；群战里表现好一些
OATH_X = {"1": 2.5, "2": 3.5, "3": 5.0}                 # 誓血仇：流失的生命(最大生命 10%)× x 当作额外伤害
OATH_Y = {"1": 0.40, "2": 0.50, "3": 0.60}              # 起誓之时：触发数值 = 最大生命 × y
units.append({
    "id": "node_darkknight", "cost": 1, "role": "warrior", "template": "warrior", **W("heavy", ["heavy", "sword", "polearm"]),
    "faction_id": "red", "profession_id": "security", "reworked": True, "target_priority": "nearest", "radius": 0.46,
    "base_stats": TEMPLATE("warrior", 1),
    "triggers": [
        # 被动 1 誓血仇【觉醒：战斗中有队友被击杀】：每次普攻时流失最大生命的 10%，× x 当作额外伤害打在这次普攻的目标上
        T("node_darkknight_vendetta", POP, ["normal_attack", "passive_vendetta"], rule="current_attack_target"),
        # 被动 2 誓绶身(2 星)【觉醒：队伍里有稀有度 5 的棋子】【召唤】：开战绑定最近的稀有度 5 棋子
        T("node_darkknight_bind", "OnBattleStart", ["battle_start", "passive_bind"], rule="self", team="any", unlock=2),
        # 触发器 起誓之时：自身完成任意[觉醒]任务后；目标 = 自身，触发数值 = 最大生命 × y
        T("node_darkknight_oath_hour", "OnAwakeningCompleted", ["awakening", "equipment_payload"], mode="max_health_ratio",
          ratio=OATH_Y["1"], ratio_star=OATH_Y, rule="self", team="any"),
    ],
    "passive_abilities": [
        A("node_darkknight_vendetta", "blade", "health_cost_damage", keywords=["basic", "awakening"], timings=[POP], tags=["passive_vendetta"],
          cfg={"awakening_key": "node_darkknight_vendetta", "awakening_tasks": [{"type": "ally_death"}],
               "health_cost_max_pct": 0.1, "damage_multiplier_by_star": OATH_X, "damage_kind": "physical", "prefer_ally_killer": True}),
        A("node_darkknight_bind", "blade", "oath_bind", keywords=["basic", "awakening", "summon"], timings=["OnBattleStart"], tags=["passive_bind"],
          cfg={"awakening_key": "node_darkknight_bind", "awakening_tasks": [{"type": "team_has_cost", "cost": 5}]}, unlock=2),
    ],
})

# 红 · 安保 · 2费 · 战士模版 —— 狂猎节点(狼耳双刀少年)
# 数值目标：单挑打得过之前重构过的每一张卡、打桩 DPS 低于速射节点；带专武时如果速射节点站得太密，能单挑杀掉 5 个
HUNT_X = {"1": 4.0, "2": 4.5, "3": 5.0}                  # 狼狩：冲锋落地斩 = 攻击力 × 这个
ONCE_X = {"1": 3.5, "2": 4.5, "3": 5.0}                  # 再来一次：触发数值 = 攻击力 × 这个
units.append({
    "id": "node_berserker", "cost": 2, "role": "warrior", "template": "warrior", **W("dual", ["dual", "heavy"]),
    "faction_id": "red", "profession_id": "security", "reworked": True, "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("warrior", 2),
    "triggers": [
        # 被动 1 狼狩：开战给属性(攻击范围 +20%、10% 物理吸血)；可用时自动发动冲锋斩(每场一次，战斗开始就可用)
        T("node_berserker_hunt_stats", "OnBattleStart", ["battle_start", "passive_hunt_stats"], rule="self", team="ally"),
        T("node_berserker_hunt", "OnBattleFrame", ["battle_frame", "passive_hunt"], mode="attack_ratio", ratio=HUNT_X["1"], ratio_star=HUNT_X,
          rule="self", team="ally", max_acts=1,
          conds=[{"type": "battle_running"}, {"type": "has_enemies"}, {"type": "source_can_act"}]),
        # 被动 2 血战(2 星)：击杀后重置狼狩与再来一次的可用次数；狼狩落地后嘲讽身边所有敌人
        T("node_berserker_bloodlust", "OnUnitKilled", ["unit_killed", "passive_bloodlust"], rule="self", team="ally", unlock=2),
        T("node_berserker_howl", "OnDashEnd", ["dash_end", "passive_howl"], rule="self", team="ally", unlock=2),
        # 触发器 再来一次：即将被击杀时(每场一次)；结算完之前不倒下，结算后血量仍 ≤ 0 才倒下。目标 = 身边一圈的敌人(受[群攻]限制)
        T("node_berserker_once_more", "OnBeforeDeath", ["before_death", "equipment_payload"], mode="attack_ratio",
          ratio=ONCE_X["1"], ratio_star=ONCE_X, rule="nearby_units", team="enemy", radius=2.4, sort="nearest", max_acts=1),
    ],
    "passive_abilities": [
        A("node_berserker_hunt_stats", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_hunt_stats"],
          cfg={"status_id": "wolf_hunt", "flags": ["hidden"],
               "stats": {"attack_range": {"pct": 0.2}, "physical_lifesteal": {"flat": 0.10}}}),
        A("node_berserker_hunt", "blade", "dash_strike", keywords=["basic", "multi_attack", "crit"], kv={"multi_attack": 3},
          timings=["OnBattleFrame"], tags=["passive_hunt"], cfg={"radius": 1.9, "speed": 15.0}),
        A("node_berserker_bloodlust", "blade", "reset_uses", keywords=["basic"], timings=["OnUnitKilled"], tags=["passive_bloodlust"], unlock=2,
          cfg={"triggers": ["node_berserker_hunt", "node_berserker_once_more"]}),
        A("node_berserker_howl", "blade", "taunt", keywords=["basic"], timings=["OnDashEnd"], tags=["passive_howl"], unlock=2,
          cfg={"radius": 2.6, "duration": 3.0}),
    ],
})

# 红 · 安保 · 2费 · 战士模版 —— 舞星节点(初生的偶像，舞扇)
# 数值目标：同条件单挑输给狂猎节点；群战(不计羁绊)在图鉴里的 3v3 中替换掉任何一个节点都能取得优异成绩(tools/team_bench.gd)
IDOL_AMP = {"1": 2, "2": 2, "3": 4}                      # 舞与歌【增幅 2/2/4】(1 星时被动 2 没解锁，视为 0)
SONG_X = {"1": 0.06, "2": 0.08, "3": 0.10}                # 舞与歌(攻击距离 > 2 米)：所有队友每点增幅 +x 攻速与攻击力
SMILE_Y = 10.0                                             # 偶像的笑与泪(血量 > 50%)：触发数值 = (增幅 + 1) × y
units.append({
    "id": "node_dancer", "cost": 2, "role": "warrior", "template": "warrior", **W("dual", ["dual", "focus"]),
    "faction_id": "red", "profession_id": "security", "model": "dancer", "reworked": True, "first_star": True, "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("warrior", 2),
    "triggers": [
        # 被动 1 初星的偶像：开战时召唤护星节点(我方已经有了就把自己的星级加给他)
        T("node_dancer_idol", "OnBattleStart", ["battle_start", "passive_idol"], rule="self", team="ally"),
        # 被动 2 舞与歌(2 星)：拿双持武器 → 开打就拉着护星节点往前冲刺；攻击距离 > 2 米 → 所有队友加攻速、攻击力
        T("node_dancer_dance", "OnBattleFrame", ["battle_frame", "passive_dance"], rule="self", team="ally", max_acts=1, unlock=2,
          conds=[{"type": "battle_running"}, {"type": "source_weapon_class", "classes": ["dual"]}, {"type": "source_can_act"}]),
        T("node_dancer_song", "OnBattleStart", ["battle_start", "passive_song"], mode="ability_keyword_value", kw="amplify",
          ratio=SONG_X["1"], ratio_star=SONG_X, rule="all_allies_except_self", team="ally", unlock=2,
          conds=[{"type": "source_attack_range_above", "value": 2.0}]),
        # 触发器 偶像的笑与泪：发动普通攻击时。血量 > 50%：目标 = 所有队友(受[群攻]限制，按攻击力排)，数值 = (增幅 + 1) × y；
        # 血量 ≤ 50%：目标 = 当前索敌目标，数值 = 攻击力 × 0.15 × (增幅 + 1)
        T("node_dancer_smile", POP, ["normal_attack", "equipment_payload"], mode="ability_keyword_value", kw="amplify",
          ratio=SMILE_Y, flat=SMILE_Y, rule="all_allies_except_self", team="ally", sort="attack_desc",
          conds=[{"type": "source_health_above_ratio", "ratio": 0.5}]),
        T("node_dancer_tears", POP, ["normal_attack", "equipment_payload"], mode="attack_ratio_keyword_plus_one", kw="amplify",
          ratio=0.15, rule="current_attack_target", team="enemy",
          conds=[{"type": "source_health_below_or_equal_ratio", "ratio": 0.5}]),
    ],
    "passive_abilities": [
        A("node_dancer_idol", "blade", "summon", keywords=["summon"], timings=["OnBattleStart"], tags=["passive_idol"], priority=50,
          cfg={"unit_id": "node_warrior", "count": 1, "placement": "front", "inherit_star": True, "shared": True}),
        A("node_dancer_dance", "blade", "escort_dash", keywords=["basic", "amplify"], kv={"amplify": 2}, kv_star={"amplify": IDOL_AMP},
          timings=["OnBattleFrame"], tags=["passive_dance"], unlock=2,
          cfg={"partner": "node_warrior", "distance": 3.5, "speed": 9.0, "dr_per_amp": 0.05, "taunt_radius": 5.0, "taunt_duration": 4.0,
               "status_id": "idol_guard"}),
        A("node_dancer_song_as", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_song"], unlock=2,
          cfg={"status_id": "idol_song_as", "stat_id": "attack_speed_multiplier", "value_mode": "amount_pct", "all_targets": True, "flags": ["buff"]}),
        A("node_dancer_song_ap", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_song"], unlock=2,
          cfg={"status_id": "idol_song_ap", "stat_id": "attack_power", "value_mode": "amount_pct", "all_targets": True, "flags": ["buff"]}),
    ],
})

# 蓝 · 研究 · 3费 · 施法者模版 —— 灾星节点(猫耳魔女，流星爆魔杖)
# 数值目标：带专武、有足量目标互相叠加溅射时，一击秒杀同星级的 1 费坦克(tools/strike_bench.gd)
WITCH_AMP = {"1": 0.08, "2": 0.08, "3": 0.15}             # 魔女的火与冰(红色武器)：每个[溅射]/[群攻]命中目标 +最终伤害(1 星值只是预览)
WITCH_STACKS = {"1": 1, "2": 1, "3": 2}                   # 魔女的火与冰(蓝色武器)：[叠加]状态额外叠层
# 魔女的笑与泪：触发数值 = 法术强度 × x(没有召唤物队友时 ÷3)。原来固定 1.0；2026-10-03 增强成按星级成长——
# 用户目标：她的流星打 3 个挤在护星节点周围的敌人时，对敌总输出要超过同星级带专武的炽照节点(tools/aoe_bench.gd 对 dps_bench)
WITCH_X = {"1": 1.3, "2": 2.25, "3": 3.2}
units.append({
    "id": "node_witch", "cost": 3, "role": "caster", "template": "caster", **W("focus", ["focus", "polearm"]),
    "faction_id": "blue", "profession_id": "research", "model": "witch", "reworked": True, "first_star": True, "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("caster", 3, move_speed=0.0),
    # 被动 1 的常驻部分：模版攻击力转法强、不能移动、打任何队友射程内的敌人(无视掩体)、普攻按法强算、换成她自己的施法动作
    "attack_as_ap": True, "sky_caster": True, "na_scaling": "ability_power",
    "anim_overrides": {"focus": {"attack": "attack_witch_focus"},
                       "polearm": {"idle": "idle_staff", "attack": "attack_witch_polearm"}},
    # 被动 2 的装备部分(2 星起)：不能装[双模]，可以装红色
    "equip_rules": {"unlock_star": 2, "extra_colors": ["red"], "forbid_classes": ["amulet"]},
    "triggers": [
        # 被动 1 初星的魔女：开战召唤护星节点(共享召唤)
        T("node_witch_star", "OnBattleStart", ["battle_start", "passive_witch_star"], rule="self", team="ally"),
        # 被动 2 魔女的火与冰(2 星)：按装备的武器颜色给隐藏属性
        T("node_witch_fire", "OnBattleStart", ["battle_start", "passive_fire"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_weapon_color", "colors": ["red"]}]),
        T("node_witch_ice", "OnBattleStart", ["battle_start", "passive_ice"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_weapon_color", "colors": ["blue"]}]),
        # 触发器 魔女的笑与泪：每 5 秒；以周围人最多的召唤物队友为中心、6 米内所有人(不分敌我，不含自己，中心本人最优先)
        T("node_witch_smile", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=20, mode="ability_power_ratio_center",
          ratio=WITCH_X["1"], ratio_star=WITCH_X, rule="summon_center", team="any", radius=6.0),
    ],
    "passive_abilities": [
        A("node_witch_star", "blade", "summon", keywords=["summon"], timings=["OnBattleStart"], tags=["passive_witch_star"], priority=50,
          cfg={"unit_id": "node_warrior", "count": 1, "placement": "front", "inherit_star": True, "shared": True}),
        A("node_witch_fire", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_fire"], unlock=2,
          cfg={"status_id": "witch_fire", "flags": ["hidden"], "stats_by_star": {"aoe_hit_amp_pct": {"flat": WITCH_AMP}}}),
        A("node_witch_ice", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_ice"], unlock=2,
          cfg={"status_id": "witch_ice", "flags": ["hidden"], "stats_by_star": {"extra_stacks": {"flat": WITCH_STACKS}}}),
    ],
})

# 蓝 · 研究 · 2费 · 战士模版 —— 和星节点(初星系的监护人，大胡子精灵德鲁伊，男性款)
# 数值目标：单挑比舞星节点强、打不过拿专武的狂猎节点；初星三人组(舞星 + 灾星 + 和星)对其他三人组 100% 赢，人数劣势也有很大机会赢(tools/team_bench.gd team=…)
GUARD_DR = {"1": 0.15, "2": 0.25, "3": 0.33}              # 初星之光：最终减免(来自友军的伤害减免效能 ×3)
WISDOM_AMP = {"1": 2, "2": 2, "3": 4}                     # 监护人的智与力【增幅 2/2/4】：治疗量加成 = 增幅 × 10%(暴击率 = 治疗量加成)
GUARD_SMILE_X = {"1": 1.00, "2": 1.80, "3": 2.20}         # 监护人的微笑：触发数值 = 攻击力 × (100 + 法强)% × x
units.append({
    "id": "node_druid", "cost": 2, "role": "warrior", "template": "warrior", **W("polearm", ["polearm", "focus", "sword", "heavy", "bow"]),   # 拉弦远程：用户 2026-10-09 加
    "faction_id": "blue", "profession_id": "research", "model": "druid", "reworked": True, "first_star": True,
    "target_priority": "nearest", "radius": 0.44, "anim_overrides": {"polearm": {"idle": "idle_staff"}},
    "base_stats": TEMPLATE("warrior", 2),
    "triggers": [
        # 被动 1 初星的监护人：开战召唤护星节点(共享召唤)；只要自己在场，每 0.25 秒给全体友方初星系节点续上"初星之光"
        T("node_druid_guardian", "OnBattleStart", ["battle_start", "passive_guardian_summon"], rule="self", team="ally"),
        T("node_druid_light_start", "OnBattleStart", ["battle_start", "passive_light"], rule="first_star_allies", team="ally"),
        T("node_druid_light", "OnBattleFrame", ["battle_frame", "passive_light"], rule="first_star_allies", team="ally"),
        # 被动 2 监护人的智与力(2 星)：治疗量加成 = 增幅 × 10%，暴击率 += 治疗量加成；每 5 秒向血最少的敌人射光箭
        T("node_druid_wisdom", "OnBattleStart", ["battle_start", "passive_wisdom"], mode="ability_keyword_value", kw="amplify", ratio=0.10,
          rule="self", team="ally", unlock=2),
        T("node_druid_arrow", "OnBattleFrame", ["battle_frame", "passive_arrow"], count=20, mode="attack_times_ability_power_pct", ratio=1.0,
          rule="all_enemies", team="enemy", sort="health_asc", unlock=2, conds=[{"type": "has_enemies"}]),
        # 触发器 监护人的微笑：开局一次，之后每 3 秒；目标 = 全体友方初星系节点；触发数值 = 攻击力 × (100 + 法强)% × x
        T("node_druid_smile_start", "OnBattleStart", ["battle_start", "equipment_payload"], mode="attack_times_ability_power_pct",
          ratio=GUARD_SMILE_X["1"], ratio_star=GUARD_SMILE_X, rule="first_star_allies", team="ally"),
        T("node_druid_smile", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=12, mode="attack_times_ability_power_pct",
          ratio=GUARD_SMILE_X["1"], ratio_star=GUARD_SMILE_X, rule="first_star_allies", team="ally"),
    ],
    "passive_abilities": [
        A("node_druid_guardian", "blade", "summon", keywords=["summon"], timings=["OnBattleStart"], tags=["passive_guardian_summon"], priority=50,
          cfg={"unit_id": "node_warrior", "count": 1, "placement": "front", "inherit_star": True, "shared": True}),
        A("node_druid_light", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart", "OnBattleFrame"], tags=["passive_light"],
          cfg={"status_id": "first_star_light", "duration": 0.6, "flags": ["buff"], "all_targets": True,
               "stats_by_star": {"final_dmg_reduction": {"flat": GUARD_DR}}}),
        A("node_druid_wisdom_heal", "blade", "stat_status", keywords=["basic", "amplify"], kv={"amplify": 2}, kv_star={"amplify": WISDOM_AMP},
          timings=["OnBattleStart"], tags=["passive_wisdom"], unlock=2, cfg={"status_id": "guardian_wisdom", "stat_id": "healing_done_pct", "flags": ["hidden"]}),
        A("node_druid_wisdom_crit", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_wisdom"], unlock=2,
          cfg={"status_id": "guardian_wisdom_crit", "flags": ["hidden"], "stats": {"crit_from_healing": {"flat": 1.0}}}),
        A("node_druid_arrow", "blade", "physical_damage", keywords=["basic", "crit"], timings=["OnBattleFrame"], tags=["passive_arrow"], unlock=2,
          cfg={"delivery": "projectile", "projectile": "light_arrow", "speed": 16.0, "heal_lowest_ally": True}),
    ],
})

# 黑 · 维护 · (1 费坦克模版，不入卡池) —— 护星节点：舞星节点的召唤物，不享受羁绊、不能换装备；星级来自所有尝试召唤他的舞星节点(相加，最高 9 星)
units.append({
    "id": "node_warrior", "cost": 1, "role": "tank", "template": "tank", **W("sword", ["sword"], "shield"), "faction_id": "black",
    "profession_id": "maintenance", "target_priority": "nearest", "radius": 0.46, "available_in_shop": False, "summon_only": True,
    "reworked": True, "first_star": True, "base_stats": TEMPLATE("tank", 1),
    "triggers": [], "passive_abilities": [],
})

# 红 · 福利 · 3费 · 施法者模版 —— 护理节点(红发精灵耳的小护士，粉色妖精翅膀；爱心针剂)
# 普攻打向血最少的受伤队友，对友方的普攻伤害按最终伤害值换成治疗；2 星起治疗时顺手驱散负面；每第 3 次普攻往这一下里"填充药水"触发装备
HEAL_X = {"1": 1.1, "2": 1.2, "3": 1.3}                  # 广义治疗：对友方的普攻最终伤害值(只算提升伤害的部分) × x → 治疗量
CARE_N = {"1": 1, "2": 1, "3": 3}                         # 一对一看护：每次驱散几个(持续时间最长的先)(1 星值只是预览)
FILL_Y = {"1": 1.5, "2": 1.75, "3": 2.0}                  # 药水填充：触发数值 = 攻击力 × y
units.append({
    "id": "node_nurse", "cost": 3, "role": "caster", "template": "caster", **W("focus", ["focus", "crossbow", "pistols", "rifle", "bow"]),   # 拉弦远程：用户 2026-10-09 加
    "faction_id": "red", "profession_id": "welfare", "model": "nurse", "reworked": True, "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("caster", 3),
    "triggers": [
        # 被动 1 广义治疗：开战给一个隐藏状态(普攻索敌血最少的受伤队友 + 对友方的普攻伤害转治疗)
        T("node_nurse_general_care", "OnBattleStart", ["battle_start", "passive_general_care"], rule="self", team="ally"),
        # 被动 2 一对一看护(2 星)：为带着可驱散负面状态的队友提供治疗时(不含自己；没有负面状态不触发、不耗充能)
        T("node_nurse_one_on_one", "OnHealApplied", ["heal_applied", "passive_one_on_one"], rule="event_target", team="ally", unlock=2,
          conds=[{"type": "event_target_not_source"}, {"type": "event_target_has_dispellable", "what": "debuff"}]),
        # 触发器 药水填充：每第 3 次普攻；目标 = 这次普攻的对象(队友或敌人)，触发数值 = 攻击力 × y
        T("node_nurse_potion_fill", POP, ["normal_attack", "equipment_payload"], count=3, mode="attack_ratio",
          ratio=FILL_Y["1"], ratio_star=FILL_Y, rule="current_attack_target", team="any"),
    ],
    "passive_abilities": [
        A("node_nurse_general_care", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_general_care"],
          cfg={"status_id": "general_care", "flags": ["hidden", "na_target_hurt_ally"], "stats_by_star": {"na_ally_heal_pct": {"flat": HEAL_X}}}),
        A("node_nurse_one_on_one", "blade", "dispel", keywords=["charged"], kv={"charged": 2}, cooldown=5.0,
          timings=["OnHealApplied"], tags=["passive_one_on_one"], unlock=2,
          cfg={"what": "debuff", "count_by_star": CARE_N, "order": "longest"}),
    ],
})

# 红 · 安保 · 3费 · 战士模版 —— 狩胜节点(猫耳红发双马尾的角斗士，赤焰战旗)；特殊标签"如火"(以后的第三种羁绊标签)
# 备战时上场就往武器库里放"狩猎旗标"(拖到敌人身上 = 指定狩猎对象)；开战把手里的武器投向狩猎对象、位移过去，之后只打狩猎对象；
# 2 星起击杀攒"光荣"，每次击杀触发装备(触发数值 = z × 被击杀者星级，精英 ×2、首领 ×3)
THROW_X = {"1": 2.0, "2": 2.5, "3": 3.0}                 # 必胜：投掷 = 攻击力 × x 的物理伤害(视为普攻伤害)
GLORY_Y = 0.10                                            # 光荣：每层普攻物理伤害附带原伤害 y 的魔法伤害
GLORY_GAIN = {"1": 1, "2": 1, "3": 2}                     # 凯旋：击杀获得的光荣层数(1 星值只是预览)
GLORY_GAIN_HUNT = {"1": 3, "2": 3, "3": 6}                # 凯旋：击杀狩猎对象时改为这么多
TRIUMPH_Z = {"1": 10.0, "2": 15.0, "3": 20.0}             # 我已得胜：触发数值 = z × 被击杀者星级(精英 ×2、首领 ×3)
GLORY = {"status_id": "glory", "duration": 0.0, "flags": ["buff"], "stats": {"na_bonus_magic_pct": {"flat": GLORY_Y}},
         # 5 层：免疫可驱散的负面状态；8 层：本应阵亡时失去 1 层、回复 25% 生命(状态自带的"触发器 + 能力")
         "flags_at": {"5": ["debuff_immune"], "8": ["glory_save"]},
         "pairs": [{"trigger": {"id": "glory_save", "timing": "OnBeforeDeath", "event_count_threshold": 1, "target_rule": "self", "team_filter": "any",
                                "tags": ["before_death", "status_glory_save"], "base_value_mode": "fixed",
                                "runtime_conditions": [{"type": "source_has_status", "status_id": "glory", "min_stacks": 8}]},
                    "ability": {"id": "glory_save", "ability_class": "blade", "effect_type": "status_cost_heal", "keywords": ["basic"],
                                "accepted_timings": ["OnBeforeDeath"], "required_trigger_tags": ["status_glory_save"],
                                "effect_config": {"status_id": "glory", "min_stacks": 8, "lose": 1, "heal_pct": 0.25}}}]}
units.append({
    "id": "node_gladiator", "cost": 3, "role": "warrior", "template": "warrior", **W("polearm", ["polearm", "sword", "heavy", "dual"]),
    "faction_id": "red", "profession_id": "security", "special_trait_ids": ["blaze"], "model": "gladiator", "reworked": True,
    "target_priority": "nearest", "radius": 0.44, "prep_items": ["hunt_flag"],
    "base_stats": TEMPLATE("warrior", 3),
    "triggers": [
        # 被动 1 必胜【暴击】：开战成为"狩猎者"(只以狩猎对象为目标)；战斗一开始把手里的武器投向狩猎对象(每场一次)，命中后立刻位移到它身边
        T("node_gladiator_hunter", "OnBattleStart", ["battle_start", "passive_hunter"], rule="self", team="ally"),
        T("node_gladiator_throw", "OnBattleFrame", ["battle_frame", "passive_throw"], mode="attack_ratio", ratio=THROW_X["1"], ratio_star=THROW_X,
          rule="hunt_target", team="enemy", max_acts=1, conds=[{"type": "battle_running"}, {"type": "has_enemies"}, {"type": "source_can_act"}]),
        # 被动 2 凯旋(2 星)【叠加 10】：击杀获得光荣(击杀狩猎对象时更多)；光荣满 10 层还要再加层 → 立刻再投一次(攻击范围无限)
        T("node_gladiator_glory", "OnUnitKilled", ["unit_killed", "passive_glory"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_metadata_equals", "key": "hunted", "value": "false"}]),
        T("node_gladiator_glory_hunt", "OnUnitKilled", ["unit_killed", "passive_glory_hunt"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_metadata_equals", "key": "hunted", "value": "true"}]),
        T("node_gladiator_glory_throw", "OnStatusOverflow", ["status_overflow", "passive_throw"], mode="attack_ratio", ratio=THROW_X["1"],
          ratio_star=THROW_X, rule="hunt_target", team="enemy", unlock=2,
          conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "glory"}, {"type": "has_enemies"}]),
        # 触发器 我已得胜：造成击杀时；目标 = 自身，触发数值 = z × 被击杀者星级(精英 ×2、首领 ×3)
        T("node_gladiator_triumph", "OnUnitKilled", ["unit_killed", "equipment_payload"], mode="event_target_star_rank",
          ratio=TRIUMPH_Z["1"], ratio_star=TRIUMPH_Z, rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_gladiator_hunter", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_hunter"],
          cfg={"status_id": "hunter", "flags": ["hidden", "hunter"]}),
        A("node_gladiator_throw", "blade", "weapon_throw", keywords=["crit"], timings=["OnBattleFrame", "OnStatusOverflow"], tags=["passive_throw"],
          cfg={"as_normal_attack": True, "windup": 0.34, "speed": 18.0, "dash_speed": 16.0}),
        A("node_gladiator_glory", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 10}, timings=["OnUnitKilled"],
          tags=["passive_glory"], unlock=2, cfg=dict(GLORY, add_stacks_by_star=GLORY_GAIN)),
        A("node_gladiator_glory_hunt", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 10}, timings=["OnUnitKilled"],
          tags=["passive_glory_hunt"], unlock=2, cfg=dict(GLORY, add_stacks_by_star=GLORY_GAIN_HUNT)),
    ],
})

# 白 · 无部门 · 0费(不进商店) · 施法者模版 —— 空白节点(开局送的"空白"节点：战斗里只摸鱼，不占上阵人数，但每多上阵一个就拖全队一次后腿)
DRAG_PER = 0.10                                          # 拖后腿：每上阵一个空白节点，所有队友伤害增幅 / 伤害减免各 -10%(× 空白节点个数)
units.append({
    "id": "node_basic", "cost": 0, "role": "caster", "template": "caster",
    **W("sword", ["sword", "heavy", "dual", "rifle", "pistols", "crossbow", "focus"]),
    "faction_id": "white", "profession_id": "none", "model": "basic", "reworked": True, "available_in_shop": False, "free_deploy": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 0),
    "triggers": [
        # 被动 1 摸鱼：战斗中不普攻、不移动(上场不占人数是单位数据 free_deploy)
        T("node_basic_slack", "OnBattleStart", ["battle_start", "passive_slack"], rule="self", team="ally"),
        # 被动 2 拖后腿(1 星就有)：开战时，所有队友伤害增幅、伤害减免各 -10% × 我方上阵的空白节点数(每个空白节点各给一份，可以减成负数)
        T("node_basic_drag", "OnBattleStart", ["battle_start", "passive_drag"], mode="team_unit_count", ratio=DRAG_PER,
          rule="all_allies_except_self", team="ally"),
        # 触发器 能活下来就算成功：战斗结束时(得活着)；目标 = 自身，触发数值 1/2/4
        T("node_basic_survive", "OnBattleEnd", ["battle_end", "equipment_payload"], flat=1.0, flat_star={"1": 1.0, "2": 2.0, "3": 4.0},
          rule="self", team="ally", conds=[{"type": "source_alive"}]),
    ],
    "passive_abilities": [
        A("node_basic_slack", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_slack"],
          cfg={"status_id": "slacking", "flags": ["hidden", "slacker"]}),
        A("node_basic_drag", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_drag"],
          cfg={"status_id": "dragged_down", "independent": True, "all_targets": True, "flags": ["debuff", "no_dispel"],
               "amount_flat_stats": {"damage_dealt_pct": -1.0, "damage_taken_pct": -1.0}}),
    ],
})

# 绿 · 福利 · 1费 · 施法者模版 —— 清心节点(绿发狐耳的小道士，如律所令)
# 被动 1 定时给一个队友治疗 + 清负面；2 星起定时打当前物理输出最高的敌人并叠【弱体】；发动任何被动时触发装备(目标 = 被动的目标)
QINGXIN_X = {"1": 150.0, "2": 220.0, "3": 320.0}         # 清心符：治疗量
QINGXIN_EVERY = {"1": 20, "2": 16, "3": 12}               # 清心符：每 5/4/3 秒(0.25 秒一帧)
WEAK_Y = {"1": 60.0, "2": 60.0, "3": 100.0}               # 弱体符：魔法伤害(1 星值只是预览)
WEAK_EVERY = {"1": 16, "2": 16, "3": 12}                  # 弱体符：每 4/4/3 秒
DAOFA_Z = 10.0                                            # 道法自然：触发数值(低：它触发得很频繁)
WEAK_PER = 0.07                                           # 弱体：每层攻速、攻击力 -7%(用户原稿 -20%/层，叠满 3 层输出只剩 16%，太强；2026-10-02 用户让砍)
WEAK = {"status_id": "weak", "duration": 7.0, "flags": ["debuff", "dispellable"],
        "stats": {"attack_speed_multiplier": {"pct": -WEAK_PER}, "attack_power": {"pct": -WEAK_PER}}}
units.append({
    "id": "node_taoist", "cost": 1, "role": "caster", "template": "caster", **W("focus", ["focus", "rifle", "pistols", "crossbow"]),
    "faction_id": "green", "profession_id": "welfare", "model": "taoist", "reworked": True, "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("caster", 1),
    "triggers": [
        # 被动 1 清心符：每 5/4/3 秒；目标 = 一个队友(可驱散的负面状态最多的优先，其次当前生命最低的)
        T("node_taoist_qingxin", "OnBattleFrame", ["battle_frame", "passive_qingxin"], count=20, count_star=QINGXIN_EVERY,
          flat=QINGXIN_X["1"], flat_star=QINGXIN_X, rule="ally_cleanse_priority", team="ally"),
        # 被动 2 弱体符(2 星)：每 4/4/3 秒；目标 = 当前物理输出最高的敌人
        T("node_taoist_weak", "OnBattleFrame", ["battle_frame", "passive_weak"], count=16, count_star=WEAK_EVERY,
          flat=WEAK_Y["1"], flat_star=WEAK_Y, rule="all_enemies", team="enemy", sort="physical_output_desc", unlock=2,
          conds=[{"type": "has_enemies"}]),
        # 触发器 道法自然：发动任意被动技能时；目标 = 那个被动的目标，触发数值 z
        T("node_taoist_daofa", "OnPassiveActivated", ["passive_activated", "equipment_payload"], flat=DAOFA_Z, rule="event_target", team="any"),
    ],
    "passive_abilities": [
        A("node_taoist_qingxin_heal", "blade", "heal", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_qingxin"], priority=90,
          cfg={"cast_fx": "talisman_heal"}),
        A("node_taoist_qingxin_cleanse", "blade", "dispel", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_qingxin"],
          cfg={"what": "debuff", "count": 3, "order": "longest"}),
        A("node_taoist_weak_dmg", "blade", "magic_damage", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_weak"], unlock=2,
          priority=90, cfg={"cast_fx": "talisman_weak"}),
        A("node_taoist_weak_status", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3}, timings=["OnBattleFrame"],
          tags=["passive_weak"], unlock=2, cfg=WEAK),
    ],
})

# 绿 · 情报 · 2费 · 刺客模版 —— 浪游节点(马耳绿发的牛仔，转瞬即逝)；特殊标签"宗族"(以后的第三种羁绊标签)
# 普攻间隔固定(极快)但要换弹，远处的目标会打空；2 星起可以部署到战场上任何没有地形的格子；每次换弹触发装备
GUN_INTERVAL = {"1": 0.166, "2": 0.133, "3": 0.1}        # 开枪最快之人：普攻间隔(秒，不受攻速影响)
GUN_RELOAD = 1.5                                          # 换弹时间(秒，我定的；不受攻速影响)
GUN_MISS = 0.25                                           # 对 1 米外的目标，普攻 x 概率打空
LOADER_Y = {"1": 0.15, "2": 0.25, "3": 0.30}              # 装弹器：触发数值 = 攻击力 × y
units.append({
    "id": "node_cowboy", "cost": 2, "role": "assassin", "template": "assassin", **W("crossbow", ["crossbow", "pistols"]),
    "faction_id": "green", "profession_id": "information", "special_trait_ids": ["clan"], "model": "cowboy", "reworked": True,
    # 索敌：锁定最近的敌人、打死前不换(不用刺客模版的"切最脆的后排")——随心所欲就是让玩家把他放到想切的目标身边，开场立刻打满一匣
    "target_priority": "nearest_locked", "radius": 0.42, "deploy_anywhere_star": 2,
    "base_stats": TEMPLATE("assassin", 2),
    "triggers": [
        # 被动 1 开枪最快之人【叠加 6】：开战给隐藏状态(固定普攻间隔、弹匣 = 叠加数、换弹时间、远距离打空)
        T("node_cowboy_fastest", "OnBattleStart", ["battle_start", "passive_fastest"], rule="self", team="ally"),
        # 被动 2 随心所欲(2 星)：部署规则(单位数据 deploy_anywhere_star)；这里只是一个不做事的配对，让卡片上能写它
        T("node_cowboy_roam", "OnBattleStart", ["battle_start", "passive_roam"], rule="self", team="ally", unlock=2),
        # 触发器 装弹器：换弹(完成)时；目标 = 自身，触发数值 = 攻击力 × y
        T("node_cowboy_loader", "OnReloadComplete", ["reload", "equipment_payload"], mode="attack_ratio", ratio=LOADER_Y["1"],
          ratio_star=LOADER_Y, rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_cowboy_fastest", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 6}, timings=["OnBattleStart"],
          tags=["passive_fastest"], cfg={"status_id": "fastest_gun", "flags": ["hidden"], "ammo_from_stacking": True,
                                         "meta": {"ammo_reload": GUN_RELOAD, "miss_far": {"pct": GUN_MISS, "dist": 1.0}},
                                         "meta_by_star": {"fixed_interval": GUN_INTERVAL}}),
        A("node_cowboy_roam", "blade", "none", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_roam"], unlock=2),
    ],
})

# 绿 · 安保 · 3费 · 战士模版 —— 炽照节点(墨绿长发高马尾的武士，炽霞)；特殊标签"如火"
# 拔刀术：普攻是从鞘里拔刀连斩【追击 2/3/4】(他自己的攻击动画：1 秒一轮，0.3 秒出手，副本每 0.08 秒一下、跟着攻速缩短)；
# 每一下普攻在目标身上留一层【剑痕】(0.75 秒，叠满 / 到期时引爆 → 残光)；2 星起每次造成普攻伤害给自己叠【重燃】，挨打时按层数回血
ZHAN_PURSUIT = {"1": 2, "2": 3, "3": 4}                  # 斩恶：【追击 N】
SCAR_DUR = 0.75                                           # 剑痕持续时间(秒)
SCAR_STACKS = 10                                          # 不灭【叠加 10】= 剑痕的层数上限(1 星视为 10)
SCAR_Y = {"1": 0.15, "2": 0.20, "3": 0.25}               # 残光：触发数值 = 攻击力 × y × (100 + 每层 5)%
SCAR_PER = 0.05
REKINDLE_X = {"2": 15, "3": 25}                          # 重燃：每层回复 x 点生命
IAI_NA = 0.80                                             # 拔刀连斩每一刀的普攻倍率(单手剑本来是 1.0；一轮 3~5 刀，一刀轻一点)
units.append({
    "id": "node_samurai", "cost": 3, "role": "warrior", "template": "warrior", **W("sword", ["sword", "heavy"]),
    "faction_id": "green", "profession_id": "security", "special_trait_ids": ["blaze"], "model": "samurai", "reworked": True,
    "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("warrior", 3),
    # 单手武器：拔刀术的待机(手按刀柄、刀在鞘里)/跑动/拔刀连斩；双手重武器用通用动作
    "anim_overrides": {"sword": {"idle": "idle_iaido", "run": "run_iaido", "attack": "attack_iaido"}},
    "hit_fx": "iaido",
    "wclass_overrides": {"sword": {"interval": 1.0, "windup": 0.30, "recover": 0.22, "copy_delay": 0.08, "copy_delay_scales": True, "na_mult": IAI_NA},
                         "heavy": {"copy_delay": 0.12, "copy_delay_scales": True}},
    "triggers": [
        # 被动 1 斩恶：每次普攻命中，再连斩 N 下(副本是完整的普攻)
        T("node_samurai_zhan", NA, ["normal_attack", "passive_zhan"]),
        # 残光(前半)：普攻留下剑痕 —— 每一下普攻命中(含追击副本)给目标叠一层
        T("node_samurai_scar", NA, ["normal_attack", "passive_scar"], rule="current_attack_target", team="enemy"),
        # 被动 2 不灭(2 星)：造成普攻伤害(含"视为普攻伤害"的武器效果)时给自己叠一层重燃
        T("node_samurai_undying", "OnDamageDealt", ["normal_attack", "passive_undying"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_has_tag", "tag": "normal_attack"}]),
        # 重燃：下次承受普攻伤害或技能伤害时(持续伤害不算)，每层回复 x，然后消耗
        T("node_samurai_rekindle", "OnDamageTaken", ["passive_rekindle"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_has_any_tag", "tags": ["normal_attack", "skill_damage"]}, {"type": "source_has_status", "status_id": "rekindle"}]),
        # 触发器 残光：剑痕引爆时每层各触发一次；目标 = 剑痕的持有者，触发数值 = 攻击力 × y × (100 + 引爆层数 × 5)%
        T("node_samurai_canguang", "OnStatusBurst", ["status_burst", "equipment_payload"], mode="attack_ratio_event_stacks",
          ratio=SCAR_Y["1"], ratio_star=SCAR_Y, flat=SCAR_PER, rule="event_target", team="enemy",
          conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "sword_scar"}]),
    ],
    "passive_abilities": [
        A("node_samurai_zhan", "blade", "none", keywords=["basic", "pursuit"], kv={"pursuit": 2}, kv_star={"pursuit": ZHAN_PURSUIT},
          timings=[NA], tags=["passive_zhan"]),
        A("node_samurai_scar", "blade", "stat_status", keywords=["basic"], timings=[NA], tags=["passive_scar"],
          cfg={"status_id": "sword_scar", "duration": SCAR_DUR, "max_stacks": SCAR_STACKS, "max_stacks_from_passive": "node_samurai_undying",
               "flags": ["debuff", "dispellable"], "burst": True, "stats": {}}),
        A("node_samurai_undying", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": SCAR_STACKS},
          timings=["OnDamageDealt"], tags=["passive_undying"], unlock=2,
          cfg={"status_id": "rekindle", "flags": ["buff", "dispellable"], "stats": {}}),
        A("node_samurai_rekindle", "blade", "status_stack_heal", keywords=["basic"], timings=["OnDamageTaken"], tags=["passive_rekindle"],
          unlock=2, cfg={"status_id": "rekindle", "per_stack_by_star": REKINDLE_X}),
    ],
})

# 绿 · 工程 · 2费 · 射手模版 —— 追猎节点(绿毛猴族弓手，易用短弓)
# 开战先花至多 6 秒"做笔记"(吟唱；站着不动)，盯住本场威胁最高的敌人；之后针对它闪避 / 增伤 / 穿甲，闪开它的普攻时触发装备(易用短弓 = 立刻反射一箭)。
# 2 星起笔记写完没被打断 → 钓鱼：把它拽到面前、嘲讽、让够得着的队友都打它
# 平衡目标(用户)：开战白送满 6 秒笔记时，单挑赢同星级带专武的炽照节点(tools/duel_bench.gd a_free_chant=1)；不送的话在小团里站 6 秒很致命，表现差是正常的
NOTES_X = {"1": 0.10, "2": 0.11, "3": 0.11}               # 猎人笔记：每准备 1 秒，针对目标 +x 普攻闪避率 / 伤害增幅 / 百分比护甲穿透(闪避最多 95%)
NOTES_CHANT = 6
CATCH_TAUNT = 3.0                                         # 意外渔获：嘲讽秒数(我定的)
AGILE_Y = {"1": 100, "2": 150, "3": 200}                  # 灵敏身法：触发数值
units.append({
    "id": "node_hunter", "cost": 2, "role": "archer", "template": "archer", **W("bow", ["bow", "dual"]),
    "faction_id": "green", "profession_id": "engineering", "model": "hunter", "reworked": True,
    "target_priority": "marked_first", "radius": 0.42,
    "base_stats": TEMPLATE("archer", 2),
    # 意外渔获解锁(2 星)后，猎人笔记的吟唱换成钓鱼：收起弓、拿出钓鱼竿(P_hunter_rod)，写完时起竿把目标拽过来
    "chant_fx": {"node_hunter_notes": {"anim": "fish_hunter", "pull_anim": "fish_pull_hunter", "prop": "P_hunter_rod", "min_star": 2}},
    "triggers": [
        # 被动 1 猎人笔记：开战时盯住威胁最高的敌人，吟唱 6 秒(被打断也按已吟唱的秒数结算)
        T("node_hunter_notes", "OnBattleStart", ["battle_start", "passive_notes"], rule="highest_threat", team="enemy",
          conds=[{"type": "has_enemies"}]),
        # 被动 2 意外渔获(2 星)：笔记完整写完(没被打断) → 把它钓到面前、嘲讽、队友改打它
        T("node_hunter_catch", "OnChantComplete", ["chant_complete", "passive_catch"], rule="event_target", team="enemy", unlock=2,
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_hunter_notes"}]),
        # 触发器 灵敏身法：笔记的针对性闪避每闪开一次普攻；目标 = 攻击者，触发数值 y
        T("node_hunter_agile", "OnDodge", ["dodge", "equipment_payload"], flat=AGILE_Y["1"], flat_star=AGILE_Y, rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_hunter_notes", "blade", "hunter_notes", keywords=["basic", "chant"], kv={"chant": NOTES_CHANT}, timings=["OnBattleStart"],
          tags=["passive_notes"], cfg={"status_id": "hunter_notes", "per_sec_by_star": NOTES_X, "release_on_interrupt": True, "dodge_cap": 0.95}),
        A("node_hunter_catch", "blade", "fish_pull", keywords=["basic"], timings=["OnChantComplete"], tags=["passive_catch"], unlock=2,
          cfg={"taunt": CATCH_TAUNT, "speed": 14.0}),
    ],
})

# 蓝 · 研究 · 4费 · 施法者模版 —— 巫术节点(鸦羽巫师，虹光花)
# 一直在吟唱：吟唱 5 秒 → 施放一轮虹光飞弹(1 + ⌊增幅 × 实际吟唱秒数⌋ 发，颜色随机、全场随机目标)→ 马上开始下一轮(吟唱 = 冷却，基本不普攻、不走动)；
# 自己造成的伤害 / 治疗攒"黑羽使魔"标记，集齐 6 种召唤一只鸟(最多 5 只)；鸟普攻命中触发他的装备(使魔之喙)
MISSILE_X = {"1": 0.45, "2": 1.1, "3": 1.9}               # 虹光飞弹：每发 = 法术强度 × x(蓝色再 ×1.2)
MISSILE_AMP = {"1": 2, "2": 2, "3": 3}                    # 【增幅 2/2/3】
MISSILE_CHANT = 5
BEAK_Y = 10                                               # 使魔之喙：触发数值(低固定值)
units.append({
    "id": "node_wizard", "cost": 4, "role": "caster", "template": "caster", **W("focus", ["focus", "polearm"]),
    "faction_id": "blue", "profession_id": "research", "model": "wizard", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 4),
    # 吟唱时放吟唱动作 + 脚下魔法阵；施放时一挥法杖
    "chant_fx": {"node_wizard_missiles": {"anim": "chant_wizard", "cast_anim": "cast_wizard", "circle": "#7fb4ff", "min_star": 1}},
    "triggers": [
        # 被动 1 虹光飞弹：开局吟唱；每轮吟唱完整结束马上开始下一轮；被打断(眩晕)后，没在吟唱、能动了就重新开始(每秒看一次)
        T("node_wizard_missiles", "OnBattleStart", ["battle_start", "passive_missiles"], mode="ability_power_ratio",
          ratio=MISSILE_X["1"], ratio_star=MISSILE_X, rule="self", team="ally"),
        T("node_wizard_missiles_again", "OnChantComplete", ["chant_complete", "passive_missiles"], mode="ability_power_ratio",
          ratio=MISSILE_X["1"], ratio_star=MISSILE_X, rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_wizard_missiles"}]),
        T("node_wizard_missiles_retry", "OnBattleFrame", ["battle_frame", "passive_missiles"], count=4, mode="ability_power_ratio",
          ratio=MISSILE_X["1"], ratio_star=MISSILE_X, rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_not_chanting"}]),
        # 被动 2 黑羽使魔(4 费：不用 2 星解锁)：自己造成伤害 / 治疗时攒标记
        T("node_wizard_familiar", "OnDamageDealt", ["damage_dealt", "passive_familiar"], rule="self", team="ally"),
        T("node_wizard_familiar_heal", "OnHealApplied", ["heal", "passive_familiar"], rule="self", team="ally"),
        # 触发器 使魔之喙：鸟普攻命中；目标 = 鸟打的敌人，触发数值 y(低固定值)
        T("node_wizard_beak", "OnSummonNormalAttackHit", ["summon_hit", "equipment_payload"], flat=BEAK_Y, rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_wizard_missiles", "blade", "rainbow_missiles", keywords=["basic", "chant", "amplify"],
          kv={"chant": MISSILE_CHANT, "amplify": 2}, kv_star={"amplify": MISSILE_AMP},
          timings=["OnBattleStart", "OnChantComplete", "OnBattleFrame"], tags=["passive_missiles"],
          cfg={"release_on_interrupt": True, "blue_mult": 1.2, "launch_gap": 0.06, "flight_min": 0.85, "flight_max": 1.3,
               # 红色飞弹的【燃烧】：和红之章敌人的同一个状态(每秒 25 点法术伤害、独立计时、可驱散)，8 秒
               "burn": {"status_id": "burning", "duration": 8.0, "max_stacks": 1, "independent": True,
                        "flags": ["debuff", "burning", "dispellable"], "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}}}),
        A("node_wizard_familiar", "blade", "familiar_marks", keywords=["summon"], timings=["OnDamageDealt", "OnHealApplied"],
          tags=["passive_familiar"], cfg={"need": 6, "max_birds": 5, "unit_id": "node_bird", "count": 1, "placement": "near", "inherit_star": True}),
    ],
})

# 黑 · 情报 · 1费 · 刺客模版 —— 鸟(巫术节点召唤的渡鸦使魔；不进卡池)
# 视为拿着双持近战武器(近战追击)；生命极低、跑得快，攻击力额外 + 召唤者法强 × r；活着时给所有队友维持 1 层【天空视野】(每只鸟 1 层，最多 3 层)
BIRD_AP = 0.1                                             # 脆弱使魔：攻击力 + 召唤者法强 × r
SKY_Z = {"1": 4, "2": 6, "3": 9}                          # 天空视野：每层普攻 / 技能伤害 +z
units.append({
    "id": "node_bird", "cost": 1, "role": "assassin", "template": "assassin", **W("dual", ["dual"]),
    "faction_id": "black", "profession_id": "information", "model": "bird", "reworked": True,
    "target_priority": "nearest", "radius": 0.36, "available_in_shop": False, "summon_only": True, "hide_weapon": True,
    "base_stats": TEMPLATE("assassin", 1, attack_power=30, max_health=160, move_speed=3.6, attack_speed_multiplier=0.6),
    "anim_overrides": {"dual": {"idle": "idle_bird", "run": "run_bird", "attack": "attack_bird"}},
    "ai": {"run_ref_speed": 3.0},                 # 飞的动作按这个速度放原速(它很快：别扇得像蜂鸟)
    "triggers": [
        T("node_bird_bond", "OnSummoned", ["summoned", "passive_bond"], mode="summoner_ability_power_ratio", ratio=BIRD_AP, rule="self", team="ally"),
        T("node_bird_eye", "OnBattleFrame", ["battle_frame", "passive_sky"], rule="all_allies", team="ally"),
    ],
    "passive_abilities": [
        # 隐藏属性(没有卡面文字)：会飞——移动时无视碰撞体积(和迅游节点一样 phasing：不和别人、地形碰撞)，flying：飞过障碍物(不绕路)
        A("node_bird_bond", "blade", "stat_status", keywords=["basic"], timings=["OnSummoned"], tags=["passive_bond"],
          cfg={"status_id": "familiar_bond", "stat_id": "attack_power", "flags": ["hidden"],
               "pre_effects": [{"effect_type": "flag_status", "status_id": "bird_flight", "duration": 0.0,
                                "flags": ["hidden", "no_dispel", "phasing", "flying"]}]}),
        A("node_bird_eye", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3}, timings=["OnBattleFrame"], tags=["passive_sky"],
          cfg={"status_id": "sky_vision", "per_source": True, "all_targets": True, "duration": 0.6, "flags": ["buff"],
               "stats_by_star": {"na_skill_flat_damage": {"flat": SKY_Z}}}),
    ],
})

# 红 · 工程 · 4费 · 射手模版 —— 清扫节点(红发猫耳女仆，闪烁刀刃)
# 完美时计：100% 暴击(写在基础属性里，卡片上看得到)；扔出去的飞刀(和子弹)先停在半空中，停着的每秒 +x% 伤害，
#   瞄着同一个敌人的飞刀加起来够打死它时一起飞过去(追踪、不会被掩体挡)；目标死了瞄着它的飞刀就消失(Battle._hold_projectile)
# 清洁世界(4 费：不用 2 星解锁)【群攻 3】：拿双持近战武器时改成远程扔飞刀(射程 = 双持远程)；开局(射程里第一次有敌人时)及之后每 10 秒，
#   对射程内看得见的至多 3 个敌人各发动 2 次普攻(原地转圈乱扔，storm 阶段)
# 女仆护身术：被近战敌人近身时触发装备(闪烁刀刃 = 瞬移拉开距离 + 连扔几把)
CLOCK_X = {"1": 0.20, "2": 0.45, "3": 0.90}              # 完美时计：停在半空的每秒 +x 伤害
STORM_CD = 10.0                                           # 清洁世界：每 10 秒
STORM_TIMES = [0.36, 0.76]                                # 转圈乱扔：两轮的出手时刻(动作 storm_maid 1.2 秒)
STORM_PATIENCE = 1.0                                      # 射程里的敌人不够【群攻】个时，最多等这么久(秒)再转(我定的：开局别一看到第一个敌人就转)
units.append({
    "id": "node_maid", "cost": 4, "role": "archer", "template": "archer", **W("dual", ["dual", "pistols"]),
    "faction_id": "red", "profession_id": "engineering", "model": "maid", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("archer", 4, crit_chance=1.0),
    # 双持近战 = 远程扔飞刀：射程和双持远程(手枪)一样，投射物是飞刀；扔飞刀的普攻动作；清洁世界的转圈乱扔(双枪也用它)
    "wclass_overrides": {"dual": {"ranged": True, "range": 2.8, "projectile": "knife", "proj_speed": 15.0}},
    "anim_overrides": {"dual": {"attack": "attack_maid", "storm": "storm_maid"}, "pistols": {"storm": "storm_maid"}},
    "triggers": [
        # 被动 1 完美时计：开战给隐藏状态(飞刀停在半空、每秒的伤害提升)
        T("node_maid_clock", "OnBattleStart", ["battle_start", "passive_clock"], rule="self", team="ally"),
        # 被动 2 清洁世界：射程里有看得见的敌人、能行动时(每 0.25 秒看一次)，冷却 10 秒
        # 清洁世界(2026-10-07 用户改)：全场不被掩体挡住的敌人(不限射程)，按大招表现(切入 + 时停)
        T("node_maid_storm", "OnBattleFrame", ["battle_frame", "passive_storm"], rule="enemies_in_sight", team="enemy",
          conds=[{"type": "battle_running"}, {"type": "source_can_act"},
                 {"type": "enemies_in_reach_gathered", "passive": "node_maid_storm", "patience": STORM_PATIENCE, "global": True}]),
        # 触发器 女仆护身术：被近战敌人近身；目标 = 那个敌人，触发数值 = 攻击力 × 暴击伤害
        T("node_maid_guard", "OnMeleeApproach", ["melee_approach", "equipment_payload"], mode="attack_times_crit_damage", rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_maid_clock", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_clock"],
          cfg={"status_id": "perfect_clock", "flags": ["hidden"], "stats": {}, "meta_by_star": {"time_stop_pct": CLOCK_X}}),
        A("node_maid_storm", "blade", "blade_storm", keywords=["multi_attack"], kv={"multi_attack": 3}, timings=["OnBattleFrame"],
          tags=["passive_storm"], cooldown=STORM_CD, cfg={"duration": 1.2, "times": STORM_TIMES, "ultimate": True}),
    ],
})

# 蓝 · 维护 · 4费 · 坦克模版 —— 星旅节点(章鱼宇航员，某已不知名的星星的旗帜)
# 用户的定位：摔炮。在仓库里也算羁绊；开战时场上没有她就从仓库坠落到敌人最密集的地方(不占上阵人数)，落地给护盾 + 砸一下；
# 活着时嘲讽溅射范围里的敌人、每秒扒掉它们一个可驱散的增益；本应阵亡时再撑 y 秒(无法被治疗也无法被击杀，结束必死)，期间按星级的间隔触发装备(真实形态)。
# 刻意没有可反复用的护盾 → 比正常 4 费弱
STARFALL_X = {"1": 100, "2": 150, "3": 220}               # 渡星而来：护盾 = 范围内敌人数 × x × (100 + 法强)%，伤害 = 它的一半
OUTER_Y = {"1": 2.5, "2": 3.0, "3": 4.0}                  # 外神之貌：再撑 y 秒
TRUE_PULSE = {"1": 0.5, "2": 0.4, "3": 0.25}              # 真实形态：每隔多少秒触发一次(用户定)
ASTRO_HP = 1200                                           # 她自己的身板(覆盖 4 费坦克模版的 攻 70 / 防 80 / 魔抗 60 / 生命 2000)
ASTRO_DEF = 50
ASTRO_MR = 40
ASTRO_ATK = 60
TRUE_Z = 50                                               # 真实形态：触发数值 = 范围内敌人数 × z × (100 + 法强)%
units.append({
    "id": "node_astronaut", "cost": 4, "role": "tank", "template": "tank", **W("polearm", ["polearm", "heavy"]),
    "faction_id": "blue", "profession_id": "maintenance", "model": "astronaut", "reworked": True,
    "target_priority": "nearest", "radius": 0.46, "bench_traits": True, "bench_drop": True,
    # 摔炮：比 4 费坦克模版脆(白送一个坠落的不该比正常上一个 4 费强；tools/team_bench.gd drop= / extra= 对照)
    "base_stats": TEMPLATE("tank", 4, max_health=ASTRO_HP, defense=ASTRO_DEF, magic_resistance=ASTRO_MR, attack_power=ASTRO_ATK),
    "triggers": [
        # 被动 1 渡星而来：从仓库坠落、落地那一刻(Battle._land_drops 发 OnStarfall)；触发数值 = 范围内敌人数 × x × (100 + 法强)%
        T("node_astronaut_starfall", "OnStarfall", ["starfall", "passive_starfall"], mode="splash_enemy_count_ap",
          ratio=STARFALL_X["1"], ratio_star=STARFALL_X, rule="self", team="ally"),
        # 被动 2 外神之貌(4 费：不用 2 星解锁)：每个战斗帧维持嘲讽；每秒扒掉被自己嘲讽的敌人一个可驱散的增益；本应阵亡时锁血(每场一次)
        T("node_astronaut_aura", "OnBattleFrame", ["battle_frame", "passive_aura"], rule="self", team="ally", conds=[{"type": "battle_running"}]),
        T("node_astronaut_strip", "OnBattleFrame", ["battle_frame", "passive_strip"], count=4, rule="taunted_by_self", team="enemy",
          conds=[{"type": "battle_running"}]),
        T("node_astronaut_undying", "OnBeforeDeath", ["before_death", "passive_undying"], rule="self", team="ally", max_acts=1),
        # 触发器 真实形态：外神之貌锁血期间每隔 0.5/0.4/0.25 秒；目标 = 溅射范围内所有敌人，触发数值 = 范围内敌人数 × z × (100 + 法强)%
        T("node_astronaut_true_form", "OnStatusPulse", ["status_pulse", "equipment_payload"], mode="splash_enemy_count_ap", ratio=TRUE_Z,
          rule="enemies_in_splash", team="enemy", conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "outer_form"}]),
    ],
    "passive_abilities": [
        A("node_astronaut_starfall", "blade", "starfall_impact", keywords=["basic", "splash"], kv={"splash": 2}, timings=["OnStarfall"],
          tags=["passive_starfall"], cfg={"splash_is_range": True, "splash_ratio": 0.5, "damage_kind": "magic"}),
        A("node_astronaut_aura", "blade", "aura_taunt", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_aura"], cfg={"duration": 0.4}),
        A("node_astronaut_strip", "blade", "dispel", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_strip"],
          cfg={"what": "buff", "count": 1, "all_targets": True}),
        A("node_astronaut_undying", "blade", "death_delay", keywords=["basic"], timings=["OnBeforeDeath"], tags=["passive_undying"],
          cfg={"status_id": "outer_form", "duration_by_star": OUTER_Y, "pulse_by_star": TRUE_PULSE}),
    ],
})

# 紫 · 工程 · 2费 · 射手模版 —— 改修节点(紫发机械臂工匠，驱动加农)；只能用双手远程
# 即时改装【叠加 3】：每 2 秒给自己一层【适应改造】(每层暴击率 + x × (100 + 法强)%；不可驱散、无限持续)，叠满后再叠 = 立刻连开两枪普攻(消耗子弹)；
#   每次换弹按对当前目标的预计伤害，下一个弹匣改成物理 / 魔法里更高的那种(Pipeline._adapt_magazine)
# 成品完工(2 星)：适应改造第一次叠到 3 层起，之后的弹匣都是真实伤害、同时吃物理和魔法伤害的加成(增幅 / 吸血)，掉层也不失效
# 应急道具：生命低于 50% 时(最小间隔 3 秒)失去一层适应改造并触发装备；目标 = 自己，触发数值 = y% × (100 + 法强)
RETRO_X = {"1": 0.08, "2": 0.10, "3": 0.12}               # 适应改造：每层暴击率(× (100 + 法强)%)
EMERG_Y = {"1": 200, "2": 300, "3": 400}                  # 应急道具：触发数值 = y × (100 + 法强)%
units.append({
    "id": "node_tinker", "cost": 2, "role": "archer", "template": "archer", **W("rifle", ["rifle"]),
    "faction_id": "purple", "profession_id": "engineering", "model": "tinker", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("archer", 2),
    "triggers": [
        # 被动 1 即时改装：每 2 秒叠一层；叠满后再叠(OnStatusOverflow) → 连开两枪；每次换弹完成 → 定下一个弹匣的伤害类型
        T("node_tinker_retrofit", "OnBattleFrame", ["battle_frame", "passive_retrofit"], count=8, mode="flat_times_ability_power_pct",
          flat=RETRO_X["1"], flat_star=RETRO_X, rule="self", team="ally", conds=[{"type": "battle_running"}]),
        T("node_tinker_overload", "OnStatusOverflow", ["status_overflow", "passive_overload"], rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "adaptive_retrofit"}]),
        T("node_tinker_adapt", "OnReloadComplete", ["reload", "passive_adapt"], rule="self", team="ally"),
        # 被动 2 成品完工(2 星)：适应改造叠满时挂上永久的【成品完工】(之后的换弹都改成真实伤害)
        T("node_tinker_finish", "OnStatusCapReached", ["status_cap", "passive_finish"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "adaptive_retrofit"}]),
        # 触发器 应急道具：承受伤害后生命低于 50%(且还有适应改造)，最小间隔 3 秒；先失去一层适应改造(被动的代价，没装备也照样扣)
        T("node_tinker_emergency", "OnDamageTaken", ["damage_taken", "equipment_payload", "passive_emergency"], mode="flat_times_ability_power_pct",
          flat=EMERG_Y["1"], flat_star=EMERG_Y, rule="self", team="any", cd_sec=3.0,
          conds=[{"type": "source_health_below_or_equal_ratio", "ratio": 0.5}, {"type": "source_has_status", "status_id": "adaptive_retrofit"}]),
    ],
    "passive_abilities": [
        A("node_tinker_retrofit", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3}, timings=["OnBattleFrame"],
          tags=["passive_retrofit"], cfg={"status_id": "adaptive_retrofit", "flags": ["buff"], "amount_flat_stats": {"crit_chance": 1.0}}),
        A("node_tinker_overload", "blade", "bonus_shots", keywords=["basic"], timings=["OnStatusOverflow"], tags=["passive_overload"],
          cfg={"count": 2, "gap": 0.12}),
        A("node_tinker_adapt", "blade", "adapt_magazine", keywords=["basic"], timings=["OnReloadComplete"], tags=["passive_adapt"],
          cfg={"finish_status": "finished_product"}),
        A("node_tinker_finish", "blade", "flag_status", keywords=["basic"], timings=["OnStatusCapReached"], tags=["passive_finish"], unlock=2,
          cfg={"status_id": "finished_product", "flags": ["buff"]}),
        A("node_tinker_emergency_cost", "blade", "lose_stack", keywords=["basic"], timings=["OnDamageTaken"], tags=["passive_emergency"],
          priority=10, cfg={"status_id": "adaptive_retrofit", "count": 1}),
    ],
})

# 绿 · 维护 · 1费 · 坦克模版 —— 耕植节点(牛耳农家少女，钉耙)
# 数值按用户给的两个目标调出来(tools/tank_bench.gd)：
#   ① 不带专武单抗同星级拿连射弩的速射节点(速射节点不死)，撑的时间≈架盾节点(★1/2/3：10.4/13.7/14.5 秒 vs 10.9/12.4/14.5)
#   ② 带专武、全程站在稻田里：能无限抗 2 个速射节点(★2/★3 血量回满)，3 个会被打死(约 33 秒)；★1 没有回血来源(韧性没解锁)，稻田帮不上
# 速射节点是一梭子 5 发 + 装弹的节奏，【吃苦耐劳】2 秒一断，所以时间是按"第几梭子打死"跳着变的；x 对 ★1 起作用，y 从 ★2 起
# 韧性每层单独回复、每 0.75 秒一次(= 5 层时每秒 6.7 次回复)，稻田"每次回复 +2% 最大生命"的收益就取决于这个频率
HARDWORK_NA_FLAT = {"1": 15, "2": 16, "3": 18}           # 【吃苦耐劳】每层：受到的普攻伤害固定减免 x
TOUGH_REGEN = {"1": 0.001, "2": 0.001, "3": 0.0015}      # 韧性：【吃苦耐劳】每层每秒回复最大生命的比例 y(1 星值只是预览)
TOUGH_INTERVAL = 0.75
units.append({
    "id": "node_peasant", "cost": 1, "role": "tank", "template": "tank", **W("polearm", ["polearm", "heavy", "sword"]),
    "faction_id": "green", "profession_id": "maintenance", "model": "peasant", "reworked": True, "target_priority": "nearest", "radius": 0.46,
    "base_stats": TEMPLATE("tank", 1),
    "triggers": [
        # 被动 1 吃苦耐劳：承受普攻时
        T("node_peasant_hardwork", HIT, ["normal_attack", "passive_hardwork"], rule="self", team="any"),
        # 触发器 收获时刻：生命首次低于 50%；目标 = 自身，触发数值 = 最大生命的 20%
        T("node_peasant_harvest", "OnDamageTaken", ["damage_taken", "equipment_payload"], mode="max_health_ratio", ratio=0.2,
          rule="self", team="any", max_acts=1, conds=[{"type": "source_health_below_or_equal_ratio", "ratio": 0.5}]),
    ],
    "passive_abilities": [
        A("node_peasant_hardwork", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 5}, timings=[HIT],
          tags=["passive_hardwork"], cfg={"status_id": "hardwork", "duration": 2.0, "flags": ["buff", "dispellable"],
                                          "stats_by_star": {"na_damage_taken_flat": {"flat": HARDWORK_NA_FLAT}}}),
        # 被动 2 韧性(2 星)：给同一个【吃苦耐劳】状态追加每层回血(不加层；驱散吃苦耐劳时一起没了)，排在被动 1 之后执行
        A("node_peasant_toughness", "blade", "stat_status", keywords=["basic"], timings=[HIT], tags=["passive_hardwork"], unlock=2,
          priority=110, cfg={"status_id": "hardwork", "modify_only": True, "hot": {"pct_by_star": TOUGH_REGEN, "interval": TOUGH_INTERVAL}}),
    ],
})

# 蓝 · 研究 · 1费 · 施法者模版 —— 求知节点(戴眼镜的光环少女，法典 + 钢笔)
# 数值目标(tools/tank_bench.gd dps=node_student)：她拿咒语笔记、被动 1 攒了 12 点法术强度时，打同星级架盾节点(铁剑)的速度 = 速射节点(连射弩)，之后反超
STUDY_MULT = {"1": 1, "2": 1, "3": 2}                    # 学力增长中：战后永久法术强度 = 1 + 武器本场学习计数 × 这个倍数
RECITE_X = {"1": 370, "2": 560, "3": 580}               # 把咒语念出来！触发数值 = x × (100 + 法术强度)%
BOMBARD_AMP = {"1": 0.01, "2": 0.01, "3": 0.015}        # 知识轰炸：普攻每点法术强度增伤(1 星值只是预览)
units.append({
    "id": "node_student", "cost": 1, "role": "caster", "template": "caster", **W("focus", ["focus", "rifle"]),   # 双手远程：用户 2026-10-09 加
    "faction_id": "blue", "profession_id": "research", "model": "student", "reworked": True, "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("caster", 1),
    # 把咒语念出来！触发时：把书举到脸前念、左手往前一指(recite_student)；面前一圈法阵，书里飞出一串发光的字打到目标身上(Fx.recite_spell)
    "trigger_fx": {"node_student_recite": {"anim": "recite_student", "fx": "recite", "color": "#7fb4ff"}},
    "triggers": [
        # 被动 1 学力增长中：每场战斗结束后(中途倒下也算)，触发数值 = 1 + 武器本场学习计数 × 1/1/2
        T("node_student_study", "OnBattleEnd", ["battle_end", "passive_study"], mode="weapon_learning_count", ratio=1.0,
          ratio_star=STUDY_MULT, flat=1.0, rule="self", team="ally"),
        # 被动 2 知识轰炸(2 星)：开战给一个隐藏状态(普攻转法术伤害 + 每点法术强度增伤)
        T("node_student_bombard", "OnBattleStart", ["battle_start", "passive_bombard"], rule="self", team="ally", unlock=2),
        # 触发器 把咒语念出来！：每 3 秒(12 个 0.25 秒)；目标 = 当前索敌目标；触发数值 = x × (100 + 法术强度)%
        T("node_student_recite", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=12, mode="flat_times_ability_power_pct",
          flat=RECITE_X["1"], flat_star=RECITE_X, rule="current_attack_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_student_study", "blade", "permanent_growth", keywords=["basic", "eternal"], timings=["OnBattleEnd"], tags=["passive_study"],
          cfg={"stat_id": "ability_power", "apply_to": "self"}),
        A("node_student_bombard", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_bombard"], unlock=2,
          cfg={"status_id": "knowledge_bombard", "flags": ["hidden", "na_magic"],
               "stats_by_star": {"na_damage_per_ap_pct": {"flat": BOMBARD_AMP}}}),
    ],
})

# 蓝 · 维护 · 1费 · 坦克模版 —— 架盾节点(大盾：她角色卡上那面防暴盾；原 2 费，2026-10-01 降为 1 费，模版属性同步取 1 费坦克)
units.append({
    "id": "node_shielder", "cost": 1, "role": "tank", "template": "tank", **W("sword", ["sword", "pistols"], "tower"),
    "faction_id": "blue", "profession_id": "maintenance", "reworked": True, "target_priority": "nearest", "radius": 0.5,
    "base_stats": TEMPLATE("tank", 1),
    "triggers": [
        # 被动 1 护盾充能：开战 50×增幅 的护盾，此后每秒 10×增幅
        T("node_shielder_charge_start", "OnBattleStart", ["battle_start", "passive_shield_charge"], mode="ability_keyword_value",
          kw="amplify", ratio=50.0, rule="self", team="ally"),
        T("node_shielder_charge_tick", "OnBattleFrame", ["battle_frame", "passive_shield_charge"], count=4, mode="ability_keyword_value",
          kw="amplify", ratio=10.0, rule="self", team="ally"),
        # 被动 2 鼠鼠缩头(2 星)：没有护盾时缩到盾后面
        T("node_shielder_turtle", "OnBattleFrame", ["battle_frame", "passive_turtle"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_shield_at_most", "value": 0.0}, {"type": "source_missing_status", "status_id": "turtle"}]),
        # 触发器 盾，我的盾！：护盾破碎时；目标 = 自身 + 周围一圈的敌人(自身最优先，受[群攻]限制)；触发数值 25×增幅
        T("node_shielder_my_shield", "OnShieldBroken", ["shield_broken", "equipment_payload"], mode="ability_keyword_value",
          kw="amplify", ratio=25.0, rule="self_then_nearby_units", team="enemy", radius=2.4),
    ],
    "passive_abilities": [
        A("node_shielder_shield_charge", "blade", "shield", mult=1.0, keywords=["basic", "amplify"],
          kv={"amplify": 1}, kv_star={"amplify": {"1": 1, "2": 2, "3": 3}}, timings=["OnBattleStart", "OnBattleFrame"],
          tags=["passive_shield_charge"], cfg={"mult_if_source_status": {"turtle": 2.0}}),
        A("node_shielder_turtle", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_turtle"], unlock=2,
          cfg={"status_id": "turtle", "flags": ["turtle"], "stats_by_star": {"defense": {"flat": {"1": 20, "2": 20, "3": 40}}},
               "end_when_shield_above": 100.0, "min_duration": 5.0}),
    ],
})

GIRL_SPLASH = 5                                           # 三个"少女幻 x"领域的【溅射】(用户 2026-10-06：3 → 5)
GIRL_FLOAT = 1.0                                          # 大招吟唱时升到空中的高度(米，表现用)

# 紫 · 安保 · 3费 · 战士模版 —— 幻彩节点(淡紫双马尾的魔法少女，幻彩镰刀)
# 闪耀色彩【充能 9】(冷却 99 秒 = 这场用完就没了)：攻击间隔拉长到 2.4 秒(她自己的慢动作大挥砍)；还有充能时，每造成一次伤害消耗 1 层，
#   物理伤害 → 蓝色颜料(魔法伤害增幅，下一次伤害转成魔法)，魔法伤害 → 红色颜料(物理增幅，转成物理)，增幅 = (200 + 2 × 法强 + x)%
# 少女幻终(1 星就有：用户 2026-10-04 改——强制阵亡的被动 2 星解锁会让升星反而变弱)【吟唱 9】【溅射 5】：充能用光时开始吟唱——嘲讽范围内的敌人、80% 伤害减免、每 0.25 秒对范围内所有其他人(不分敌我)
#   造成 攻击力 × y × (10 + 0.1 × 法强)% 真实伤害；吟唱结束(或被打断)对范围内所有其他人造成 攻击力 × y × (500 + 5 × 法强)% × 实际吟唱秒数 的真实伤害，然后强制阵亡
#   (用户原稿写的是"y × (10 + 0.1 × 法强)%"，没写乘谁——我按攻击力，和其它技能一样)
# 触发器 颜料：普攻造成伤害时；目标 = 身边一圈的敌人(受群攻限制)，触发数值 = 攻击力 × z × (100 + 法强)%
MAGI_X = {"1": 0, "2": 50, "3": 100}                      # 颜料：增幅里的 x
MAGI_Y = {"1": 0.3, "2": 0.3, "3": 0.45}                  # 少女幻终：y1 / y1 / y2
MAGI_Z = {"1": 0.8, "2": 1.0, "3": 1.2}                   # 颜料(触发器)：z
MAGI_IV = 2.4                                             # 攻击间隔(她自己的攻击动作 attack_magi 的长度)
_MAGI_WC = {"interval": MAGI_IV, "windup": 0.75, "recover": 0.55}       # 出手(0.75 秒)= attack_magi 的挥下时刻
units.append({
    "id": "node_magi", "cost": 3, "role": "warrior", "template": "warrior", **W("heavy", ["heavy", "polearm"]),
    "faction_id": "purple", "profession_id": "security", "model": "magi", "reworked": True,
    "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("warrior", 3),
    # 攻击间隔 2.4 秒：双手重 / 双手长都换成她自己的大挥砍(群攻招式也用它)
    "wclass_overrides": {"heavy": dict(_MAGI_WC, multi={"shape": "area", "min_targets": 2, "anim": "attack_magi", **_MAGI_WC}),
                         "polearm": dict(_MAGI_WC, multi={"shape": "line", "min_targets": 2, "anim": "attack_magi", **_MAGI_WC})},
    "anim_overrides": {"heavy": {"attack": "attack_magi"}, "polearm": {"attack": "attack_magi"}},
    # 大招：升到空中(float 米)、光柱 + 切入横幅(ultimate)，领域的表现见 game/view/domain_fx.gd
    "chant_fx": {"node_magi_finale": {"anim": "chant_magi", "min_star": 1, "domain": True, "float": GIRL_FLOAT, "ultimate": True,
                                      "ult_color": "#e6d2ff", "no_ring": True}},
    "triggers": [
        # 被动 1 闪耀色彩：自己造成物理 / 魔法伤害时(还有充能)
        T("node_magi_colors", "OnDamageDealt", ["damage_dealt", "passive_colors"], rule="self", team="ally",
          conds=[{"type": "event_has_any_tag", "tags": ["physical_damage", "magic_damage"]}]),
        # 被动 2 少女幻终(1 星就有)：闪耀色彩的充能用光 → 开始吟唱 + 挂上领域(减伤)；吟唱期间每个战斗帧维持嘲讽、打范围里的所有其他人
        T("node_magi_finale", "OnChargesEmpty", ["charges_empty", "passive_finale"], mode="attack_times_ability_power_pct",
          ratio=MAGI_Y["1"] * 5.0, ratio_star={k: v * 5.0 for k, v in MAGI_Y.items()}, rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_magi_colors"}]),
        T("node_magi_finale_taunt", "OnBattleFrame", ["battle_frame", "passive_finale_taunt"], rule="self", team="ally",
          conds=[{"type": "source_has_status", "status_id": "girl_finale"}]),
        T("node_magi_finale_tick", "OnBattleFrame", ["battle_frame", "passive_finale_tick"], mode="attack_times_ability_power_pct",
          ratio=MAGI_Y["1"] * 0.1, ratio_star={k: v * 0.1 for k, v in MAGI_Y.items()}, rule="others_in_splash", team="any",
          conds=[{"type": "source_has_status", "status_id": "girl_finale"}]),
        # 触发器 颜料：普攻造成伤害时；目标 = 身边一圈的敌人，触发数值 = 攻击力 × z × (100 + 法强)%
        T("node_magi_paint", NA, ["normal_attack", "equipment_payload"], mode="attack_times_ability_power_pct", ratio=MAGI_Z["1"], ratio_star=MAGI_Z,
          rule="nearby_units", team="enemy", radius=2.4, sort="nearest"),
    ],
    "passive_abilities": [
        A("node_magi_colors", "blade", "paint", keywords=["charged"], kv={"charged": 9}, timings=["OnDamageDealt"], tags=["passive_colors"],
          cooldown=99.0, cfg={"status_id": "paint", "x_by_star": MAGI_X}),
        A("node_magi_finale", "blade", "magi_finale", keywords=["basic", "chant", "splash"], kv={"chant": 9, "splash": GIRL_SPLASH}, timings=["OnChargesEmpty"],
          tags=["passive_finale"], cfg={"release_on_interrupt": True, "splash_is_range": True, "chant_pct_per_second": 0.0,
                                                 "end_statuses": ["girl_finale"]}),
        A("node_magi_domain", "blade", "stat_status", keywords=["basic"], timings=["OnChargesEmpty"], tags=["passive_finale"], priority=50,
          cfg={"status_id": "girl_finale", "duration": 9.5, "max_stacks": 1, "flags": ["buff", "no_dispel"], "stats": {"damage_taken_pct": {"flat": 0.8}},
               "meta": {"ally_danger": True}}),     # 队友的 AI 会躲开这个领域(终结一击不分敌我)
        A("node_magi_finale_taunt", "blade", "aura_taunt", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_finale_taunt"],
          cfg={"duration": 0.4}),
        A("node_magi_finale_tick", "blade", "true_damage", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_finale_tick"],
          cfg={"all_targets": True}),
    ],
})

# 紫 · 情报 · 4费 · 刺客模版 —— 迅游节点(紫色刺头鼠耳的跑者，闪电手套；男)；特殊标签"宗族"
# 闪电跑者：移动时穿过地形和其他人(不参与碰撞)；攻击力按比例转化为移动速度——每 1 秒，移动速度 +攻击力 × x%(一直累加)
# 飞身踢(不用 2 星解锁)【暴击】：一直在跑，以最远的敌人为目标(选定后跑到为止)；跑到它面前就踢一脚(= 普攻)：
#   攻击力 × (100 + 法强)% × f(这一段跑过的路程) 的物理伤害，踢完重新选最远的敌人折返。
#   f(d) = (d / KICK_D0) ^ KICK_POW：跑得越远、每米加得越多(非线性)。下一个目标离得太近(只剩一个敌人 / 敌人挤在一起)就先去卡车借力再折返
# 触发器 别粘我鞋底上：飞身踢造成伤害时；目标 = 被踢的人，触发数值 = 攻击力 × (100 + 法强)% × f(路程)(和这一脚同一个倍率)
#   (用户原稿的"(100 + 法术强度)% × f"没写乘谁，按攻击力，和普攻伤害一致)
RUN_X = {"1": 0.03, "2": 0.05, "3": 0.07}              # 闪电跑者：每秒移动速度 +攻击力 × x%
KICK_D0 = 4.0                                           # 飞身踢：跑满 4 米 = 1 倍
KICK_POW = 1.6                                          # 飞身踢：路程的指数(越远越赚)
KICK_MIN_RUN = 6.0                                      # 下一个目标不到 6 米远：先去卡车借力(拉开距离再踢)
units.append({
    "id": "node_runner", "cost": 4, "role": "assassin", "template": "assassin", **W("dual", ["dual", "sword"]),
    "faction_id": "purple", "profession_id": "information", "special_trait_ids": ["clan"], "model": "runner", "reworked": True,
    "target_priority": "farthest", "radius": 0.42,
    "base_stats": TEMPLATE("assassin", 4),
    "ai": {"run_ref_speed": 4.2},                        # 表现：跑步动作按 4.2 米/秒 = 原速放(冲刺步幅大)
    # 普攻 = 飞身踢：踢一脚(不是双刀的两下)，倍率 1 × 攻击力，再乘路程倍率(na_scale)
    "wclass_overrides": {"dual": {"na_mult": 1.0}, "sword": {"na_mult": 1.0}},
    "normal_attack_ability": A("node_runner_kick", "blade", "physical_damage", keywords=["basic", "crit", "normal_attack"],
                               timings=["OnNormalAttackPerform"], tags=["normal_attack_perform"]),
    "anim_overrides": {"dual": {"run": "run_runner", "attack": "kick_runner"}, "sword": {"run": "run_runner", "attack": "kick_runner"}},
    "triggers": [
        # 被动 1 闪电跑者：开战就穿模(隐藏状态 flag phasing)；每 1 秒(4 个战斗帧)叠一次移动速度
        T("node_runner_lightning", "OnBattleStart", ["battle_start", "passive_lightning"], rule="self", team="ally"),
        T("node_runner_speed", "OnBattleFrame", ["battle_frame", "passive_lightning_speed"], count=4, mode="attack_ratio",
          ratio=RUN_X["1"] / 100.0, ratio_star={k: v / 100.0 for k, v in RUN_X.items()}, rule="self", team="ally"),
        # 被动 2 飞身踢：开战给隐藏状态(flag runner：AI 改成一直跑、碰到就踢；路程倍率的参数在 meta 里)
        T("node_runner_kick", "OnBattleStart", ["battle_start", "passive_kick"], rule="self", team="ally"),
        # 触发器 别粘我鞋底上：飞身踢(普攻)命中
        T("node_runner_shoe", NA, ["normal_attack", "equipment_payload"], mode="kick_mult", ratio=1.0, rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_runner_lightning", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_lightning"],
          cfg={"status_id": "lightning_phase", "flags": ["hidden", "phasing"]}),
        A("node_runner_speed", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_lightning_speed"],
          cfg={"status_id": "lightning_runner", "flags": ["buff"], "max_stacks": 1, "accumulate": True, "amount_pct_stats": ["move_speed"]}),
        A("node_runner_kick", "blade", "stat_status", keywords=["basic", "crit"], timings=["OnBattleStart"], tags=["passive_kick"],
          cfg={"status_id": "flying_kick", "flags": ["hidden", "runner"],
               "meta": {"kick_d0": KICK_D0, "kick_pow": KICK_POW, "min_run": KICK_MIN_RUN}}),
    ],
})

# 白 · 情报 · 3费 · 刺客模版 —— 幻形节点(银白长波浪发、黑西装的女特工；万语千言)
# 千变万化【充能 9】(冷却 99 秒 = 这一场用完就没了，描述里不写；开战满充能)：部署规则 = 只能部署在任意敌人(出生点)周围一圈(单位数据 deploy_near_enemies，
#   取代部署区)；被敌人索敌(新时机 OnTargeted)且还有充能时，消耗 1 层，给那个敌人施加【误导】
# 【误导】(可驱散、不可叠加、负面，4 秒)：立刻取消当前索敌，强制改为索敌它自己的一个队友(自相残杀)；精英 / 首领免疫自相残杀，但照样重新索敌(不会再选中她)
# 少女幻嘘(1 星就有：用户 2026-10-04 改)【吟唱 9】【溅射 5】：千变万化的充能用光时开始吟唱；吟唱期间对溅射范围里所有人(不分敌我)维持【误导】；
#   吟唱结束(或被打断)对溅射范围里所有其他人施加【眩晕】(实际吟唱秒数 × x% 秒)，然后强制阵亡
# 【眩晕】(可驱散、不可叠加、负面)：无法移动、无法攻击、打断吟唱、"每 x 秒"的触发器暂停计时；精英 / 首领恢复得快一倍(时长减半)
# 触发器 小小收获：战斗结束时(自己还活着)；目标 = 自身，触发数值 = 千变万化已经用掉的充能数 × 1/1/2
SPY_X = {"1": 30, "2": 30, "3": 50}                     # 少女幻嘘：眩晕秒数 = 实际吟唱秒数 × x%(满吟唱 2.7 / 2.7 / 4.5 秒)
SPY_HARVEST = {"1": 1.0, "2": 1.0, "3": 2.0}            # 小小收获：已用充能数 × 1/1/2
units.append({
    "id": "node_spy", "cost": 3, "role": "assassin", "template": "assassin", **W("dual", ["dual", "pistols", "crossbow", "sword"]),
    "faction_id": "white", "profession_id": "information", "model": "spy", "reworked": True,
    "target_priority": "nearest", "radius": 0.42, "deploy_near_enemies": True,
    "base_stats": TEMPLATE("assassin", 3),
    "chant_fx": {"node_spy_hush": {"anim": "chant_spy", "min_star": 1, "glyph_domain": True, "float": GIRL_FLOAT, "ultimate": True,
                                   "ult_color": "#c8b8ff", "no_ring": True}},
    "triggers": [
        # 被动 1 千变万化：被敌人索敌时(还有充能)；目标 = 选中她的那个敌人
        T("node_spy_shift", "OnTargeted", ["targeted", "passive_shift"], rule="event_target", team="enemy"),
        # 被动 2 少女幻嘘(1 星就有)：充能用光 → 吟唱 + 领域；吟唱期间每个战斗帧给范围里的所有人续上误导
        T("node_spy_hush", "OnChargesEmpty", ["charges_empty", "passive_hush"], rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_spy_shift"}]),
        T("node_spy_hush_mislead", "OnBattleFrame", ["battle_frame", "passive_hush_mislead"], rule="others_in_splash", team="any",
          conds=[{"type": "source_has_status", "status_id": "spy_domain"}]),
        # 触发器 小小收获：战斗结束时(还活着)
        T("node_spy_harvest", "OnBattleEnd", ["battle_end", "equipment_payload"], mode="charges_spent", ratio=SPY_HARVEST["1"], ratio_star=SPY_HARVEST,
          rule="self", team="ally", conds=[{"type": "source_alive"}]),
    ],
    "passive_abilities": [
        A("node_spy_shift", "blade", "mislead", keywords=["charged"], kv={"charged": 9}, timings=["OnTargeted"], tags=["passive_shift"],
          cooldown=99.0, cfg={"status_id": "misled", "duration": 4.0}),
        A("node_spy_hush", "blade", "spy_hush", keywords=["basic", "chant", "splash"], kv={"chant": 9, "splash": GIRL_SPLASH}, timings=["OnChargesEmpty"],
          tags=["passive_hush"], cfg={"release_on_interrupt": True, "splash_is_range": True, "chant_pct_per_second": 0.0,
                                                 "end_statuses": ["spy_domain"], "x_by_star": SPY_X}),
        A("node_spy_domain", "blade", "stat_status", keywords=["basic"], timings=["OnChargesEmpty"], tags=["passive_hush"], priority=50,
          cfg={"status_id": "spy_domain", "duration": 9.5, "max_stacks": 1, "flags": ["buff", "no_dispel"], "meta": {"ally_danger": True}}),
        A("node_spy_hush_mislead", "blade", "mislead", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_hush_mislead"],
          cfg={"status_id": "misled", "duration": 0.6, "all_targets": True}),
    ],
})

# 紫 · 研发 · 4费 · 施法者模版 —— 幻灵节点(深紫长发猫耳的通灵少女，魔典)；只能用法器
# 无形伙伴【充能 9】【召唤】(冷却 99 秒 = 这一场用完就没了，描述里不写；开战满充能)：开局 + 每 4 秒，消耗 1 层，在当前目标背后召唤一个幽灵；
#   取代原有普攻：每次普攻消耗 1 层，在目标脚下召唤一只幽灵犬，令它发动普攻(两条路用同一个能力 id = 同一池充能)
# 少女幻葬(4 费：不用 2 星解锁)【吟唱 9】【溅射 5】【召唤】：无形伙伴的充能用光时开始吟唱；吟唱期间每秒在溅射范围里随便一个人背后召唤一个幽灵
#   (没有魂体存在、攻击不分敌我、出不了溅射范围)；吟唱结束：每吟唱满 3 秒，就在战场随机位置召唤 吟唱期间全场阵亡的单位数 个幽灵；然后强制阵亡
# 触发器 遗愿：友方召唤物阵亡时；目标 = 离它最近的敌人，触发数值 = 它的最大生命值
MEDIUM_IV = 3.5                                         # 幻灵节点的普攻间隔(秒)
units.append({
    "id": "node_medium", "cost": 4, "role": "caster", "template": "caster", **W("focus", ["focus"]),
    "faction_id": "purple", "profession_id": "research", "model": "medium", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 4),
    "normal_attack_ability": A("node_medium_partner", "blade", "medium_summon", keywords=["charged", "summon"], kv={"charged": 9},
                               timings=["OnNormalAttackPerform"], tags=["normal_attack_perform"], cooldown=99.0,
                               cfg={"dog": "node_dog", "ghost": "node_ghost"}),
    "chant_fx": {"node_medium_funeral": {"anim": "chant_medium", "min_star": 1, "soul_domain": True, "float": GIRL_FLOAT, "ultimate": True,
                                         "ult_color": "#a98cff", "no_ring": True}},
    # 普攻间隔拉长到 3.5 秒(用户 2026-10-04：普攻 + 每 4 秒的幽灵一共约 15 秒打出全部 9 层充能)
    "wclass_overrides": {"focus": {"interval": MEDIUM_IV}},
    "triggers": [
        # 被动 1 无形伙伴：开局 + 每 4 秒(16 个战斗帧)
        T("node_medium_partner_start", "OnBattleStart", ["battle_start", "passive_partner"], rule="self", team="ally"),
        T("node_medium_partner_tick", "OnBattleFrame", ["battle_frame", "passive_partner"], count=16, rule="self", team="ally"),
        # 被动 2 少女幻葬：充能用光 → 吟唱 + 领域；吟唱期间每秒召一个幽灵
        T("node_medium_funeral", "OnChargesEmpty", ["charges_empty", "passive_funeral"], rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_medium_partner"}]),
        T("node_medium_funeral_tick", "OnBattleFrame", ["battle_frame", "passive_funeral_tick"], count=4, rule="self", team="ally",
          conds=[{"type": "source_has_status", "status_id": "medium_domain"}]),
        # 触发器 遗愿：友方召唤物阵亡
        T("node_medium_last_wish", "OnAllyUnitDied", ["ally_unit_died", "equipment_payload"], mode="dead_max_health", ratio=1.0,
          rule="nearest_enemy_to_dead", team="enemy", conds=[{"type": "event_dead_is_summon"}]),
    ],
    "passive_abilities": [
        A("node_medium_partner", "blade", "medium_summon", keywords=["charged", "summon"], kv={"charged": 9}, timings=["OnBattleStart", "OnBattleFrame"],
          tags=["passive_partner"], cooldown=99.0, cfg={"dog": "node_dog", "ghost": "node_ghost"}),
        A("node_medium_funeral", "blade", "medium_funeral", keywords=["basic", "chant", "splash", "summon"], kv={"chant": 9, "splash": GIRL_SPLASH},
          timings=["OnChargesEmpty"], tags=["passive_funeral"],
          cfg={"release_on_interrupt": True, "splash_is_range": True, "chant_pct_per_second": 0.0, "end_statuses": ["medium_domain"],
               "per_seconds": 3.0, "unit_id": "node_ghost", "max_ghosts": 30}),
        A("node_medium_domain", "blade", "stat_status", keywords=["basic"], timings=["OnChargesEmpty"], tags=["passive_funeral"], priority=50,
          cfg={"status_id": "medium_domain", "duration": 9.5, "max_stacks": 1, "flags": ["buff", "no_dispel"], "meta": {"ally_danger": True}}),
        A("node_medium_funeral_tick", "blade", "medium_wisp", keywords=["basic", "summon"], timings=["OnBattleFrame"], tags=["passive_funeral_tick"],
          cfg={"unit_id": "node_ghost"}),
    ],
})

# 幽灵犬(幻灵节点召唤)：紫 · 安保 · 4费 · 战士模版，视为使用双手重武器(手里不显示)；金毛寻回犬的灵体
# 最好的伙伴：普攻额外造成 召唤者普通攻击伤害 × 100% 的魔法伤害；魂体存在：无法被选中、不受伤害、普攻一次后立刻阵亡
SPECTRAL = {"status_id": "spectral", "flags": ["hidden", "no_dispel", "phasing", "untargetable", "invulnerable", "spectral"]}
units.append({
    "id": "node_dog", "cost": 4, "role": "warrior", "template": "warrior", **W("heavy", ["heavy"]),
    "faction_id": "purple", "profession_id": "security", "model": "dog", "reworked": True,
    "target_priority": "nearest_locked", "radius": 0.45, "available_in_shop": False, "summon_only": True, "hide_weapon": True,
    "base_stats": TEMPLATE("warrior", 4),
    "anim_overrides": {"heavy": {"idle": "idle_dog", "run": "run_dog", "attack": "attack_dog"}},
    "triggers": [
        T("node_dog_spectral", "OnSummoned", ["summoned", "passive_spectral"], rule="self", team="ally",
          conds=[{"type": "source_meta_missing", "key": "no_spectral"}]),
        T("node_dog_partner", NA, ["normal_attack", "passive_partner_bite"], mode="summoner_na_value", ratio=1.0, rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_dog_spectral", "blade", "stat_status", keywords=["basic"], timings=["OnSummoned"], tags=["passive_spectral"], cfg=dict(SPECTRAL)),
        A("node_dog_partner", "blade", "magic_damage", keywords=["basic"], timings=[NA], tags=["passive_partner_bite"]),
    ],
})

# 幽灵(幻灵节点召唤)：紫 · 情报 · 3费 · 刺客模版，视为使用单手近战武器(手里不显示)；骷髅脸紫兜帽的小幽灵
# 无声无息：从背后发动的普通攻击必定暴击，且造成真实伤害；魂体存在：同上(少女幻葬吟唱时召出来的没有)
units.append({
    "id": "node_ghost", "cost": 3, "role": "assassin", "template": "assassin", **W("sword", ["sword"]),
    "faction_id": "purple", "profession_id": "information", "model": "ghost", "reworked": True,
    "target_priority": "nearest_locked", "radius": 0.38, "available_in_shop": False, "summon_only": True, "hide_weapon": True,
    "base_stats": TEMPLATE("assassin", 3),
    "triggers": [
        T("node_ghost_spectral", "OnSummoned", ["summoned", "passive_spectral"], rule="self", team="ally",
          conds=[{"type": "source_meta_missing", "key": "no_spectral"}]),
        T("node_ghost_silent", "OnSummoned", ["summoned", "passive_silent"], rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_ghost_spectral", "blade", "stat_status", keywords=["basic"], timings=["OnSummoned"], tags=["passive_spectral"], cfg=dict(SPECTRAL)),
        A("node_ghost_silent", "blade", "stat_status", keywords=["basic"], timings=["OnSummoned"], tags=["passive_silent"],
          cfg={"status_id": "silent_strike", "flags": ["hidden", "no_dispel", "backstab"]}),
    ],
})

# 青 · 工程 · 2费 · 射手模版 —— 真望节点(青绿长发、白色军装的指挥官，至远的弓弦)；唯一：场上不能同时有两个(单位数据 unique，通用规则)
# 引导之矢【叠加 9】：开战时 9 层【金矢】(可叠加、不可驱散、无限持续；每层 x% 伤害减免)。有金矢时普攻锁定队友(优先没有黄金的指引的)：
#   消耗一层，给一名"有冷却时间最长、充能不满的【充能】效果"的其他队友回 1 层充能，并给他一层【黄金的指引】(同样的叠加上限、每层 x% 减伤；
#   持有者所有"敌我不分"改为"仅限敌人"，溅射 / 群攻都算)。没有这样的队友时照常打敌人(金矢留着)
# 少女真心(2 星)【觉醒：战斗中我方总共至少 27 层充能】，每场战斗限一次：我方全灭时立刻复活所有具有【充能】的友方单位，
#   被动(不含武器效果)充能补满；每有 1 点充能上限回复 10% 生命。自己倒下了也能触发
# 触发器 勇气：自己阵亡时；目标 = 自己，触发数值 = y
LEADER_X = {"1": 0.03, "2": 0.04, "3": 0.05}            # 金矢 / 黄金的指引：每层伤害减免
LEADER_Y = {"1": 100.0, "2": 150.0, "3": 200.0}         # 勇气：触发数值
units.append({
    "id": "node_leader", "cost": 2, "role": "archer", "template": "archer", **W("bow", ["bow", "rifle", "pistols", "crossbow"]),
    "faction_id": "cyan", "profession_id": "engineering", "model": "leader", "reworked": True, "unique": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("archer", 2),
    "triggers": [
        # 被动 1 引导之矢：开战给 9 层金矢(普攻打到队友身上 = 金矢的效果，见 meta.na_ally_effect)
        T("node_leader_arrows", "OnBattleStart", ["battle_start", "passive_arrows"], rule="self", team="ally"),
        # 被动 2 少女真心(2 星)：我方全灭(倒下的她也收得到)
        T("node_leader_heart", "OnTeamWiped", ["team_wiped", "passive_heart"], rule="self", team="ally", unlock=2),
        # 触发器 勇气：自己阵亡
        T("node_leader_courage", "OnUnitDied", ["unit_died", "equipment_payload"], flat=LEADER_Y["1"], flat_star=LEADER_Y, rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_leader_arrows", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 9}, timings=["OnBattleStart"], tags=["passive_arrows"],
          cfg={"status_id": "golden_arrow", "flags": ["buff", "no_dispel"], "max_stacks": 9, "add_stacks": 9,
               "stats_by_star": {"damage_taken_pct": {"flat": LEADER_X}},
               "meta": {"na_ally_effect": "golden_arrow", "dr_stats": {"damage_taken_pct": {"flat": LEADER_X}}}}),
        A("node_leader_heart", "blade", "team_revive", keywords=["basic", "awakening"], timings=["OnTeamWiped"], tags=["passive_heart"], unlock=2,
          cfg={"once_per_battle": True, "hp_per_charge": 0.10, "awakening_key": "node_leader_heart",
               "awakening_tasks": [{"type": "team_charges_at_least", "count": 27}]}),
    ],
})

# 黄 · 福利 · 2费 · 施法者模版 —— 心音节点(金色长波浪发、精灵耳、蝴蝶翅膀的吟游诗人；无声琴 = 她那把镶宝石的鲁特琴)
# 基础武器拉弦远程(弓：拿基础弓时显示鲁特琴 weapon_look)，可装备法器
# 纤心的乐奏【吟唱 4】【双模】【演奏】：开战及每 4 秒进行一段演奏(一段接一段：吟唱完马上开始下一段；被打断后能动了就重新开始)。
#   演奏结束时，对这段演奏的对象造成 吟唱秒数 × k × (100 + 法强)% 的治疗(友方)或法术伤害(敌方)
#   【演奏】：效果在吟唱开始时就施加，吟唱期间一直维持；自动挑最关键的对象，同一种效果不连着用两次(Pipeline.perform_pick)
#     加攻 / 法强(攻击力或法强最高的队友，选较优的一项)、燃烧(生命最低的敌人)、寒气(本场输出最高的敌人，每秒叠一个)、
#     再生(生命比例最低的友方，每秒叠一个)、击退 + 减速(贴近我方后排的敌方近战)、减疗(本场回复最多的敌人)、削甲(本场承伤最多的敌人)
# 不绝的回响(2 星)：自己阵亡时，当时演奏维持的效果此后永久持续；其中没有加攻 / 法强就也给攻击力 / 法强最高的队友永久加上
# 触发器 艺术性批判：吟唱开始时；目标 = 这段演奏的对象，触发数值 y(会伤害人的装备效果不打队友：no_harm_allies)
BARD_CHANT = 4
BARD_K = {"1": 25.0, "2": 40.0, "3": 60.0}                # 演奏结束：每吟唱 1 秒 = k × (100 + 法强)%
BARD_Y = {"1": 60.0, "2": 90.0, "3": 130.0}               # 艺术性批判：触发数值
BARD_PERFORM = {
    "atk_pct": {"1": 0.20, "2": 0.30, "3": 0.40},         # 加攻：攻击力 +%
    "ap_flat": {"1": 25.0, "2": 40.0, "3": 60.0},         # 加法强：法强 +
    "burns": {"1": 1, "2": 2, "3": 3},                    # 燃烧：同时维持几个(每个每秒 25 点法术伤害)
    "chill_first": {"1": 1, "2": 2, "3": 3},              # 寒气(通用：每个攻速 -10%，合计超过 40% 冻结)：开始时给几个，之后每秒再叠一个
                                                          #   1 星 1→4 个(40%，冻不住)，2 星 2→5 个(第 4 秒冻结)，3 星 3→5 个(第 3 秒冻结)
    "regen_first": {"1": 2, "2": 3, "3": 4},              # 再生(通用：每个每秒回 10)：开始时给几个，之后每秒再叠一个
    "repel_dist": 2.0, "repel_reach": 2.5,                # 击退：推开 2 米；离我方后排 2.5 米以内的近战才算"贴近"
    "slow": {"1": 0.30, "2": 0.40, "3": 0.50},            # 减速：移动速度 -%
    "heal_cut": {"1": 0.35, "2": 0.50, "3": 0.60},        # 减疗：受到的治疗 -%
    "shred": {"1": 0.15, "2": 0.20, "3": 0.30},           # 削甲：护甲、魔抗 -%
}
units.append({
    "id": "node_bard", "cost": 2, "role": "caster", "template": "caster", **W("bow", ["bow", "focus"]),
    "faction_id": "yellow", "profession_id": "welfare", "model": "bard", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 2),
    # 演奏：平时拿着手里的武器(弓 / 法器)唱歌(sing_bard，法器另有 sing_bard_focus)；
    # 拿着专武无声琴时才抱着鲁特琴弹(P_bard_lute 挂在胸口，吟唱期间一直显示；连着的下一段不收)
    "chant_fx": {"node_bard_perform": {"anim": "sing_bard", "min_star": 1, "perform": True,
                                       "by_weapon": {"silent_lute": {"anim": "perform_bard", "prop": "P_bard_lute", "keep_prop": True}}}},
    "triggers": [
        T("node_bard_perform", "OnBattleStart", ["battle_start", "passive_perform"], mode="flat_times_ability_power_pct",
          flat=BARD_K["1"], flat_star=BARD_K, rule="performance_pick", team="any", conds=[{"type": "has_enemies"}]),
        T("node_bard_perform_again", "OnChantComplete", ["chant_complete", "passive_perform"], mode="flat_times_ability_power_pct",
          flat=BARD_K["1"], flat_star=BARD_K, rule="performance_pick", team="any",
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_bard_perform"}, {"type": "has_enemies"}]),
        T("node_bard_perform_retry", "OnBattleFrame", ["battle_frame", "passive_perform"], count=4, mode="flat_times_ability_power_pct",
          flat=BARD_K["1"], flat_star=BARD_K, rule="performance_pick", team="any",
          conds=[{"type": "battle_running"}, {"type": "source_not_chanting"}, {"type": "has_enemies"}]),
        # 演奏的维持(寒气 / 再生每秒叠一个)
        T("node_bard_sustain", "OnBattleFrame", ["battle_frame", "passive_sustain"], rule="self", team="any", conds=[{"type": "source_chanting"}]),
        # 被动 2 不绝的回响(2 星)
        T("node_bard_echo", "OnUnitDied", ["unit_died", "passive_echo"], rule="self", team="any", unlock=2),
        # 触发器 艺术性批判：吟唱开始时，目标 = 演奏对象
        T("node_bard_critique", "OnChantStart", ["chant_start", "equipment_payload"], flat=BARD_Y["1"], flat_star=BARD_Y, rule="event_target",
          team="any") | {"target_filter": {"no_harm_allies": True}},
    ],
    "passive_abilities": [
        A("node_bard_perform", "amulet", "heal", keywords=["basic", "chant", "performance"], kv={"chant": BARD_CHANT},
          timings=["OnBattleStart", "OnChantComplete", "OnBattleFrame"], tags=["passive_perform"],
          cfg={"release_on_interrupt": True, "chant_proportional": True,
               "ally_effect": {"effect_type": "heal", "value_multiplier": 1.0},
               "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": 1.0},
               "performance": BARD_PERFORM}),
        A("node_bard_sustain", "blade", "perform_tick", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_sustain"]),
        A("node_bard_echo", "blade", "perform_echo", keywords=["basic"], timings=["OnUnitDied"], tags=["passive_echo"], unlock=2),
    ],
})

# 青 · 福利 · 2费 · 施法者模版 —— 调香节点(青绿长发、鹿角鹿耳的调香师，旧香炉)；基础武器法器，可装备单手近战(剑)
# 飘香【叠加 3】：在场时，所有友方【再生】的效能 × 叠加数(Battle.regen_mult)；开战时及每 x 秒给全体友军施加 1 个再生，持续 y 秒
# 恒古(2 星)：在场时给全体友军维持 1 个再生(regen_eternal，每 0.5 秒续一次，她倒下后 0.6 秒内消失)
# 触发器 焚花：每 z 秒；触发数值 = 本场为友方施加的治疗量总和(不含溢出)，目标 = 全体敌人(受群攻限制)
PERFUME_X = {"1": 24, "2": 16, "3": 12}                   # 飘香：开战时及每 6 / 4 / 3 秒(战斗帧 = 0.25 秒)
PERFUME_Y = 10.0                                          # 飘香的再生持续 y 秒(几个叠在一起)
PERFUME_STACK = 3
PERFUME_Z = 32                                            # 焚花：每 8 秒
units.append({
    "id": "node_perfume", "cost": 2, "role": "caster", "template": "caster", **W("focus", ["focus", "sword"]),
    "faction_id": "cyan", "profession_id": "welfare", "model": "perfumer", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 2),
    "triggers": [
        T("node_perfume_scent_start", "OnBattleStart", ["battle_start", "passive_scent"], rule="all_allies", team="ally"),
        T("node_perfume_scent", "OnBattleFrame", ["battle_frame", "passive_scent"], count=PERFUME_X["1"], count_star=PERFUME_X, rule="all_allies",
          team="ally", conds=[{"type": "battle_running"}]),
        T("node_perfume_eternal", "OnBattleFrame", ["battle_frame", "passive_eternal"], count=2, rule="all_allies", team="ally", unlock=2),
        T("node_perfume_burn", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=PERFUME_Z, mode="source_heal_done", rule="all_enemies",
          team="enemy", conds=[{"type": "has_enemies"}]),
    ],
    "passive_abilities": [
        A("node_perfume_scent", "blade", "regen", keywords=["basic", "stacking"], kv={"stacking": PERFUME_STACK}, timings=["OnBattleStart", "OnBattleFrame"],
          tags=["passive_scent"], cfg={"duration": PERFUME_Y, "regen_amp": True, "all_targets": True}),
        A("node_perfume_eternal", "blade", "regen", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_eternal"], unlock=2,
          cfg={"duration": 0.6, "regen_id": "regen_eternal", "all_targets": True}),
    ],
})

# 青 · 安保 · 4费 · 战士模版 —— 血嗜节点(青绿短发、红竖瞳的吸血鬼剑士，男；凝血)；特殊标签"宗族"；基础武器双手重武器，可装备单手近战、双手长武器
# 关于那位永不饱餐的血魔，【叠加 12】：每 1 秒叠 2/2/3 层【血欲】(可叠加、不可驱散、无限持续)。
#   【血欲】：造成 / 承受非持续伤害时，每有一层就给对方叠一层【失血】(和本被动共用叠加数)：可驱散，10 秒，负面；
#   每层每 0.25 秒 x 点物理持续伤害，血嗜节点回复最终伤害量
# 却也永不堕入疯狂的伙伴，【叠加 12】(不用 2 星)：在场时全场每造成 y 点持续伤害，获得一层【血宴】(不可驱散，无限)：每层持续伤害增幅 z1%、固定伤害减免 z2
# 触发器 也是我等的至亲的故事。：血欲到 12 层时消耗 12 层触发；目标 = 半径 5 米的圆里的所有敌人(圆心 = 他在打的敌人；受群攻限制)；
#   触发数值 = 血宴层数 × 攻击力 × (100 + 法强)%。武器在冷却时不触发、也不消耗血欲(冷却好了才触发)；吟唱中也不触发
VAMP_LUST = {"1": 2, "2": 2, "3": 3}                      # 每秒叠几层血欲
VAMP_X = {"1": 0.6, "2": 1.0, "3": 1.8}                   # 失血：每层每 0.25 秒的物理持续伤害
VAMP_Y = 150.0                                            # 血宴：全场每这么多持续伤害一层
VAMP_Z1 = 0.04                                            # 血宴：每层持续伤害增幅
VAMP_Z2 = 3.0                                             # 血宴：每层固定伤害减免
VAMP_R = 6.0                                              # 至亲的故事：血之圆的半径(米)
units.append({
    "id": "node_vampire", "cost": 4, "role": "warrior", "template": "warrior", **W("heavy", ["heavy", "sword", "polearm"]),
    "faction_id": "cyan", "profession_id": "security", "special_trait_ids": ["clan"], "model": "vampire", "skin": "porcelain", "reworked": True,
    "target_priority": "nearest", "radius": 0.45,
    "base_stats": TEMPLATE("warrior", 4, attack_power=150, max_health=2000),
    # 触发器的武器效果有吟唱时：浮空、头顶凝聚血球(任何吟唱的武器效果都用这一套："*")；吟唱结束把血球扔出去
    "chant_fx": {"*": {"anim": "chant_vampire", "cast_anim": "throw_vampire", "min_star": 1}},
    "triggers": [
        T("node_vampire_lust", "OnBattleFrame", ["battle_frame", "passive_lust"], count=4, rule="self", team="any", conds=[{"type": "battle_running"}]),
        T("node_vampire_bleed_out", "OnDamageDealt", ["damage_dealt", "passive_bleed"], rule="event_target", team="enemy",
          conds=[{"type": "event_missing_tag", "tag": "dot_damage"}, {"type": "source_has_status", "status_id": "bloodlust"}]),
        T("node_vampire_bleed_in", "OnDamageTaken", ["damage_taken", "passive_bleed"], rule="event_target", team="enemy",
          conds=[{"type": "event_missing_tag", "tag": "dot_damage"}, {"type": "source_has_status", "status_id": "bloodlust"}]),
        T("node_vampire_feast", "OnBattleFrame", ["battle_frame", "passive_feast"], rule="self", team="any"),
        # 武器效果等血球砸到地上才结算(delivery throw：吟唱完 0.4 秒、没吟唱 0.66 秒后；Pipeline.execute)
        dict(T("node_vampire_kin", "OnBattleFrame", ["battle_frame", "equipment_payload", "passive_kin"], mode="status_stacks_atk_ap", status="blood_feast",
               rule="blood_circle", radius=VAMP_R, team="enemy",
               conds=[{"type": "source_has_status", "status_id": "bloodlust", "min_stacks": 12}, {"type": "source_not_chanting"},
                      {"type": "payload_ready"}, {"type": "has_enemies"}]), extra={"delivery": "throw", "throw_time": 0.4, "cast_time": 0.26}),
    ],
    "passive_abilities": [
        A("node_vampire_lust", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 12}, timings=["OnBattleFrame"], tags=["passive_lust"],
          cfg={"status_id": "bloodlust", "duration": 0.0, "max_stacks": 12, "flags": ["buff", "no_dispel"], "add_stacks_by_star": VAMP_LUST}),
        A("node_vampire_bleed", "blade", "bleed", keywords=["basic"], timings=["OnDamageDealt", "OnDamageTaken"], tags=["passive_bleed"],
          cfg={"x_by_star": VAMP_X, "duration": 10.0, "stack_from": "node_vampire_lust"}),
        A("node_vampire_feast", "blade", "blood_feast", keywords=["basic", "stacking"], kv={"stacking": 12}, timings=["OnBattleFrame"], tags=["passive_feast"],
          cfg={"per": VAMP_Y, "status": {"status_id": "blood_feast", "duration": 0.0, "flags": ["buff", "no_dispel"],
                                         "stats": {"dot_damage_pct": {"flat": VAMP_Z1}, "damage_taken_flat": {"flat": VAMP_Z2}}}}),
        A("node_vampire_kin", "blade", "kin_consume", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_kin"], cfg={"count": 12}),
    ],
})

# 黄 · 订法 · 3费 · 施法者模版 —— 灭罪节点(金色波浪长发、精灵长耳、身后太阳光环的白袍圣女；光之心)；基础武器法器，不能换别的大类
# 她是唯一的光【吟唱 99】【溅射 2】：战斗中永远在吟唱(被打断后能动了马上重新开始)。吟唱期间召唤一道从天而降的光束(Battle._step_light_beams)：
#   降临在敌方最强的单位所在的位置，之后一直锁定敌方本场伤害最高的单位、慢慢移过去(不避让友军、不管地形)；
#   每 0.25 秒对中心的主目标造成 x × 攻击力 × (100 + 法强)% 的法术伤害，没有主目标也照常溅射(溅射不分敌我)
# 她将照亮长夜(2 星)：每吟唱 0.5 秒，光束的倍率和溅射范围 +y%；被打断时重置(层数存在光束上)；造成击杀时直接获得 2 秒的提升
# 触发器 她必尽灭邪恶：光束每持续 0.25 秒触发一次；目标 = 光束溅射范围里的所有敌人(受群攻限制)，触发数值 = z × 攻击力 × (100 + 法强)%
#   (一秒 4 次：数值故意给得低，配专武光之心时斩杀线 = n × 触发数值)
ABS_X = {"1": 0.25, "2": 0.40, "3": 0.70}                 # 光束：每 0.25 秒 x × 攻击力 × (100 + 法强)%
ABS_Y = 0.03                                              # 照亮长夜：每 0.5 秒 +3% 倍率与溅射范围
ABS_Z = {"1": 0.10, "2": 0.15, "3": 0.25}                 # 她必尽灭邪恶：触发数值 z × 攻击力 × (100 + 法强)%
ABS_SPEED = 1.0                                           # 光束移动速度(米 / 秒；棋子 1.3~3 米 / 秒)
ABS_CORE = 0.3                                            # 光束中心：离中心这么远(+ 对方体型半径)以内的敌人才算"中心的主目标"
_ABS_LIGHT = dict(mode="attack_times_ability_power_pct", ratio=ABS_X["1"], ratio_star=ABS_X, rule="self", team="ally")
units.append({
    "id": "node_absolver", "cost": 3, "role": "caster", "template": "caster", **W("focus"),
    "faction_id": "yellow", "profession_id": "legislation", "model": "absolver", "skin": "porcelain", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 3),
    # 永远在吟唱：双手捧着法器举在胸前、微微浮起，法器往天上射一道细光(光束本体由 BattleView 按 unit.meta.light_beam 画)；不画通用的吟唱光圈
    "chant_fx": {"node_absolver_light": {"anim": "chant_absolver", "min_star": 1, "light": True, "no_ring": True}},
    "triggers": [
        # 被动 1 她是唯一的光：开局吟唱；之后每个战斗帧——没在吟唱就重新开始，在吟唱就让光束结算一次(吟唱 99 秒万一唱完了也马上再来)
        T("node_absolver_light", "OnBattleStart", ["battle_start", "passive_light"], **_ABS_LIGHT),
        T("node_absolver_light_frame", "OnBattleFrame", ["battle_frame", "passive_light"], conds=[{"type": "battle_running"}], **_ABS_LIGHT),
        T("node_absolver_light_again", "OnChantComplete", ["chant_complete", "passive_light"],
          conds=[{"type": "event_metadata_equals", "key": "ability_id", "value": "node_absolver_light"}], **_ABS_LIGHT),
        # 被动 2 她将照亮长夜(2 星)：每个战斗帧按吟唱了多久更新层数；造成击杀 +2 秒
        T("node_absolver_night", "OnBattleFrame", ["battle_frame", "passive_night"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_chanting"}]),
        T("node_absolver_night_kill", "OnUnitKilled", ["unit_killed", "passive_night"], rule="self", team="ally", unlock=2,
          conds=[{"type": "event_target_enemy"}]),
        # 触发器 她必尽灭邪恶：光束在场的每个战斗帧
        T("node_absolver_purge", "OnBattleFrame", ["battle_frame", "equipment_payload"], mode="attack_times_ability_power_pct",
          ratio=ABS_Z["1"], ratio_star=ABS_Z, rule="light_beam_area", team="enemy", conds=[{"type": "light_beam_active"}]),
    ],
    "passive_abilities": [
        A("node_absolver_light", "blade", "light_beam", keywords=["chant", "splash"], kv={"chant": 99, "splash": 2},
          timings=["OnBattleStart", "OnBattleFrame", "OnChantComplete"], tags=["passive_light"],
          cfg={"speed": ABS_SPEED, "core": ABS_CORE, "splash_is_range": True, "splash_fx": "light"}),
        A("node_absolver_night", "blade", "light_ramp", keywords=["basic"], timings=["OnBattleFrame", "OnUnitKilled"], tags=["passive_night"], unlock=2,
          cfg={"ramp_pct": ABS_Y, "ramp_step": 0.5, "kill_steps": 4}),
    ],
})

# 黄 · 工程 · 4费 · 射手模版 —— 屏息节点(金色长直发、猫耳、黑色战术服 + 黑披风的狙击手；黑色战场)；基础武器双手远程，可装备单手远程、拉弦远程
# 瞄准眉心【吟唱 10】：基础攻击力更高。每次普攻，作为吟唱，最多再瞄准 10 秒(单位数据 na_aim：普攻载荷多带【吟唱 10】，弓照常先拉弓再瞄)，
#   每瞄 1 秒攻击力 +x(连续计时，Pipeline.na_draw_scale)，开枪后重置。什么时候提前开枪是 AI 的事(BattleAI._aim_done)：
#   被近战敌人够得着了，或者这一枪已经打得死目标(带着有效果的武器时要打到 2 倍生命：溢出会被一石二鸟带走)
# 集中呼吸(4 费：不用 2 星)：身边 2.5 米(边到边)以内没有敌人时，每秒暴击率 +y(状态 focus_breath)；暴击率溢出的部分改为 2 倍暴击伤害
#   (基础属性 crit_overflow_cd = 2)；被近战敌人够得着时整个重置
# 触发器 一石二鸟：造成击杀时；目标 = 离被击杀者最近的敌人，触发数值 = 这次击杀溢出的伤害
SNIPER_X = {"1": 0.40, "2": 0.60, "3": 1.00}              # 瞄准眉心：每多瞄 1 秒攻击力 +x
SNIPER_AIM = 10                                           # 【吟唱 10】：最多再瞄这么多秒
SNIPER_Y = {"1": 0.05, "2": 0.08, "3": 0.12}              # 集中呼吸：每秒暴击率 +y
SNIPER_CALM = 2.5                                         # "身周"：边到边这么近以内有敌人就不涨(我定的)
units.append({
    "id": "node_sniper", "cost": 4, "role": "archer", "template": "archer", **W("rifle", ["rifle", "crossbow", "bow"]),
    "faction_id": "yellow", "profession_id": "engineering", "model": "sniper", "skin": "umber", "reworked": True,
    "target_priority": "range_lowest_health", "radius": 0.42,
    "base_stats": TEMPLATE("archer", 4, attack_power=220, crit_overflow_cd=2.0),
    "na_aim": "node_sniper_aim",
    # 拿步枪瞄准时换成她自己的"贴腮看瞄准镜"(aim_sniper)；弓照常拉弓
    # 狙击窝(表现，UnitView 的 nest 模式)：拿步枪停下来作战就单膝跪地、枪架在身前的黑箱子上(瞄准 / 开枪 / 换弹都是跪姿)，
    # 转身 turn 度以内不起身；crate = 箱子的位置 [x, z, 箱顶高](模型体素：护木 / 两脚架搁在箱顶，见 anim_chars 的 _nest_pose)
    "wclass_overrides": {"rifle": {"draw_anim": "aim_sniper", "draw_hold_anim": "aim_sniper",
                                   "nest": {"aim": "nest_aim_sniper", "fire": "nest_fire_sniper", "reload": "nest_reload_sniper",
                                            "in": "nest_in_sniper", "shift": "nest_shift_sniper", "turn": 45.0, "crate": [-10.0, 31.0, 33.8]}}},
    "triggers": [
        # 被动 2 集中呼吸：身边没敌人时每秒一层；被近战敌人够得着就清掉
        T("node_sniper_breath", "OnBattleFrame", ["battle_frame", "passive_breath"], count=4, rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "no_enemy_near", "radius": SNIPER_CALM}]),
        T("node_sniper_breath_reset", "OnBattleFrame", ["battle_frame", "passive_breath_reset"], rule="self", team="ally",
          conds=[{"type": "source_has_status", "status_id": "focus_breath"}, {"type": "in_melee_enemy_reach"}]),
        # 触发器 一石二鸟：击杀敌人时；目标 = 离被击杀者最近的敌人，触发数值 = 溢出伤害(事件数值)
        T("node_sniper_double", "OnUnitKilled", ["unit_killed", "equipment_payload"], mode="event_value", rule="nearest_enemy_to_dead", team="enemy",
          conds=[{"type": "event_target_enemy"}]),
    ],
    "passive_abilities": [
        # 被动 1 瞄准眉心：不监听事件，由普攻载荷的【吟唱】在出手前完成(BUnit.na_payload / BattleAI._do_draw)
        A("node_sniper_aim", "blade", "none", keywords=["chant"], kv={"chant": SNIPER_AIM}, tags=["passive_aim"], cfg={"aim_pct_by_star": SNIPER_X}),
        A("node_sniper_breath", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_breath"],
          cfg={"status_id": "focus_breath", "duration": 0.0, "max_stacks": 999, "flags": ["buff", "no_dispel"],
               "stats_by_star": {"crit_chance": {"flat": SNIPER_Y}}}),
        A("node_sniper_breath_reset", "blade", "clear_own_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_breath_reset"],
          cfg={"status_id": "focus_breath"}),
    ],
})

# 黄 · 安保 · 2费 · 战士模版 —— 止息节点(Node Commando：原来备用的 Node Captain 改名，用她的模型 captain——金色短波波头、异色瞳、头戴耳机、黑色战术服)；
# 和屏息节点绑定的二人组。基础武器双持近战，可装备单手远程、双手远程、双持远程、单手近战
# 画上句点：索敌目标没有【标定】时突进(Pipeline._commando_lunge)——把它从它正在打的人那里击退 2 米，冲到它背后(击退方向那一侧)恰好够得着的位置，
#   落地立刻普攻，强制它索敌自己(到标定被消耗为止)，施加【标定】(不可驱散、不叠加、负面：承受的伤害 +x% 增幅，damage_taken_amp)。
#   标定累计 3 秒：我方攻击力最高的远程友军立刻对它打出一发免费普攻弹道(_mark_volley：按当次普攻的一切加成，正在瞄准就按已瞄的倍率；
#   不消耗弹药、不算攻击、不打断瞄准)，命中时消耗标定 → 目标没有标定了 → 再突进
# 掩护支援(2 星)：冷却 5 秒【充能 2】：有近战敌人靠近我方攻击力最高的远程友军 2.8 米以内时，立刻改为索敌它
# 触发器 突击：发动突进时；目标 = 突进对象，触发数值 = 攻击力 × y
CMD_X = {"1": 0.15, "2": 0.20, "3": 0.30}                 # 标定：承受伤害的增幅
CMD_Y = {"1": 1.0, "2": 1.5, "3": 2.2}                    # 突击：触发数值 = 攻击力 × y
CMD_KNOCK = 2.0                                           # 画上句点：击退"数米"(我定的 2 米)
CMD_MARK_DELAY = 3.0                                      # 标定累计 3 秒 → 免费弹道
CMD_COVER_R = 2.8                                         # 掩护支援：近战敌人离远程友军 2.8 米以内
units.append({
    "id": "node_commando", "cost": 2, "role": "warrior", "template": "warrior", **W("dual", ["dual", "crossbow", "rifle", "pistols", "sword"]),
    "faction_id": "yellow", "profession_id": "security", "model": "captain", "reworked": True,
    # 选中的敌人没倒下就一直打它(不然每次换目标都会再突进一次)
    "target_priority": "nearest_locked", "radius": 0.42,
    "base_stats": TEMPLATE("warrior", 2),
    "triggers": [
        # 被动 1 画上句点：每个战斗帧看一次——目标没有标定、自己能行动 → 突进；标定满 3 秒 → 远程友军的免费弹道
        T("node_commando_period", "OnBattleFrame", ["battle_frame", "passive_period"], rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_can_act"}, {"type": "source_target_missing_status", "status_id": "commando_mark"}]),
        T("node_commando_volley", "OnBattleFrame", ["battle_frame", "passive_volley"], rule="self", team="ally", conds=[{"type": "battle_running"}]),
        # 被动 2 掩护支援(2 星)
        T("node_commando_cover", "OnBattleFrame", ["battle_frame", "passive_cover"], rule="melee_near_support", radius=CMD_COVER_R, team="enemy", unlock=2,
          conds=[{"type": "battle_running"}, {"type": "source_can_act"}]),
        # 触发器 突击：发动突进时；目标 = 突进对象
        T("node_commando_assault", "OnLunge", ["lunge", "equipment_payload"], mode="attack_ratio", ratio=CMD_Y["1"], ratio_star=CMD_Y,
          rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_commando_period", "blade", "commando_lunge", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_period"],
          cfg={"knock": CMD_KNOCK, "speed": 9.0,
               "mark": {"status_id": "commando_mark", "duration": 0.0, "max_stacks": 1, "flags": ["debuff", "no_dispel"],
                        "stats_by_star": {"damage_taken_amp": {"flat": CMD_X}}}}),
        A("node_commando_volley", "blade", "mark_volley", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_volley"],
          cfg={"status_id": "commando_mark", "delay": CMD_MARK_DELAY}),
        A("node_commando_cover", "blade", "cover_retarget", keywords=["charged"], kv={"charged": 2}, timings=["OnBattleFrame"], tags=["passive_cover"],
          cooldown=5.0, unlock=2),
    ],
})

# 青 · 情报 · 3费 · 刺客模版 —— 踏影节点(Node Knight-errant：青色乱发、黑金长袍的游侠，男；青影)；基础武器单手近战，可装备双持近战。第一阶段的最后一只
# 逆光 冷却 8 秒【充能 1】【叠加 3】(开战就有 1 层充能)：当前目标不是远程敌人时，瞬移到远程敌人(威胁最高的，我定的)背后并索敌它，获得 1 层【凝暗】
#   【凝暗】可叠加(上限 = 叠加数)、可驱散、无限：持有时除非已经是场上最后的合法目标，否则不能被敌人索敌(BattleAI.shadow_hidden)；每层背后攻击 +x% 伤害增幅(backstab_amp)
# 墨刃(2 星)：每 5 秒对当前目标造成 y × 攻击力 × (100 + 法强)% 的魔法伤害
# 触发器 淬血：发动逆光时(OnBlink)，对自己造成 z × 攻击力 × (100 + 法强)% 的真实持续伤害并触发；目标 = 自己，触发数值 = 这次流失的生命值。
#   和血嗜节点一样：没有武器效果 / 武器效果在冷却就不触发，也不掉血(payload_ready)
KE_X = {"1": 0.25, "2": 0.45, "3": 0.65}                  # 凝暗：每层背后攻击的伤害增幅
KE_Y = {"1": 2.0, "2": 2.0, "3": 3.0}                     # 墨刃：y1/y1/y2(2 星才解锁，1 星的值只是占位)
KE_Z = {"1": 0.5, "2": 0.6, "3": 0.8}                     # 淬血：z × 攻击力 × (100 + 法强)% 的真实持续伤害
units.append({
    "id": "node_knight_errant", "cost": 3, "role": "assassin", "template": "assassin", **W("sword", ["sword", "dual"]),
    "faction_id": "cyan", "profession_id": "information", "model": "knight_errant", "reworked": True,
    # 第一次逆光前先盯近战敌人(逆光才会把他送到后排)，逆光过以后先找远程敌人(BattleAI nearest_melee_first)
    "target_priority": "nearest_melee_first", "radius": 0.42,
    "base_stats": TEMPLATE("assassin", 3, attack_power=180),
    "triggers": [
        # 被动 1 逆光：每个战斗帧看一次——当前目标不是远程敌人、自己能行动、有充能 → 瞬移到威胁最高的远程敌人背后
        T("node_ke_backlight", "OnBattleFrame", ["battle_frame", "passive_backlight"], rule="ranged_threat", team="enemy",
          conds=[{"type": "battle_running"}, {"type": "source_can_act"}, {"type": "source_target_not_ranged"}]),
        # 被动 2 墨刃(2 星)：每 5 秒
        T("node_ke_ink", "OnBattleFrame", ["battle_frame", "passive_ink"], count=20, mode="attack_times_ability_power_pct", ratio=KE_Y["1"], ratio_star=KE_Y,
          rule="current_attack_target", team="enemy", unlock=2, conds=[{"type": "battle_running"}]),
        # 触发器 淬血：发动逆光时(先付生命 → 武器拿到"这次流失的生命值")
        T("node_ke_temper", "OnBlink", ["blink", "equipment_payload", "passive_temper"], mode="self_cost_lost", rule="self", team="ally",
          conds=[{"type": "payload_ready"}]),
    ],
    "passive_abilities": [
        A("node_ke_backlight", "blade", "shadow_step", keywords=["charged", "stacking"], kv={"charged": 1, "stacking": 3}, cooldown=8.0,
          timings=["OnBattleFrame"], tags=["passive_backlight"],
          cfg={"veil": {"status_id": "shadow_veil", "duration": 0.0, "flags": ["buff", "dispellable", "shadowed"],
                        "stats_by_star": {"backstab_amp": {"flat": KE_X}}}}),
        A("node_ke_ink", "blade", "magic_damage", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_ink"], unlock=2, cfg={"cast_fx": "ink_blade"}),
        A("node_ke_temper", "blade", "self_cost", keywords=["basic"], timings=["OnBlink"], tags=["passive_temper"], priority=10, cfg={"ratio_by_star": KE_Z}),
    ],
})

# 黄 · 维护 · 4费 · 坦克模版 —— 正行节点(Node Noble：金色波浪长发、银甲金边、缠着花藤与小花的花骑士；百合盾)；基础武器单手近战，
# 可装备法器、双手长武器——拿长枪 / 法器时也不双手持，而是单手拿，另一只手照样持盾(offhand "lily"：她自己的百合盾，GC guard_anims)
# 正色百合【叠加 12】：每 3 秒 1 层【花瓣】；每次队友造成击杀 1 层；每 3 次普攻 1 层；每次有队友阵亡 3 层；每次为队友提供治疗 2 层。
#   【花瓣】可叠加、不可驱散、无限：每层 +x% 治疗量加成；4 层起 +生命上限，8 层起 +护甲与魔抗(状态的 stats_at 阈值)
# 再绽之花【群攻 9】【吟唱 3】【叠加 3】：花瓣满层时开始吟唱，每秒消耗 4 层花瓣、获得 1 层【花蕊】；累计消耗满 12 层 → 获得【花】
#   【花蕊】可叠加(3)、不可驱散、无限：普攻伤害获得等同于治疗量加成的最终伤害加成(Effects.damage 的 na_heal_final)；
#     普攻时消耗 1 层，这一下变成延长过的光剑 / 光矛 / 光炮(BUnit.cone_cfg)：120° 锥形、4.5 米内最多【群攻 9】个敌人，各吃原普攻的 y 倍；
#     然后把这一下造成的伤害量当作治疗量，智能分配给全场受伤的友军(Pipeline.smart_heal：注水，不溢出)
#   【花】不可叠加、不可驱散、无限：提供满层的花瓣加成(之后花瓣自己的加成不再另算：off_with)
# 触发器 百合骑士的骑士：有敌人进入自身 3 米内，或在 3 米内停留满 2 秒(新时机 OnEnemyNear)；目标 = 那个敌人，触发数值 = 攻击力 × 治疗量加成 × z
#   (照用户原文：治疗量加成是 0 时触发数值也是 0——花瓣越多越强，开花之后满额)
NOBLE_X = {"1": 0.03, "2": 0.04, "3": 0.05}               # 花瓣：每层治疗量加成
NOBLE_HP = {"1": 300.0, "2": 450.0, "3": 700.0}           # 花瓣 4 层起：生命上限 +
NOBLE_DR = {"1": 20.0, "2": 30.0, "3": 45.0}              # 花瓣 8 层起：护甲与魔抗 +
NOBLE_Y = {"1": 2.5, "2": 3.0, "3": 4.0}                  # 花蕊：光刃对每个目标造成原普攻的 y 倍
NOBLE_Z = {"1": 3.5, "2": 4.0, "3": 5.0}                  # 百合骑士的骑士：触发数值 = 攻击力 × 治疗量加成 × z
NOBLE_CONE = {"angle": 120.0, "length": 4.5}              # "大面积锥形范围"(我定的：张角 120°、从她中心算 4.5 米)
NOBLE_NEAR = 3.0
NOBLE_LINGER = 2.0
_LILY = dict(mode="fixed", rule="self", team="ally")
units.append({
    "id": "node_noble", "cost": 4, "role": "tank", "template": "tank", **W("sword", ["sword", "focus", "polearm"], "lily"),
    "faction_id": "yellow", "profession_id": "maintenance", "model": "noble", "reworked": True,
    "target_priority": "nearest", "radius": 0.46,
    "base_stats": TEMPLATE("tank", 4),
    # 花蕊的光刃：三种武器各一套大横扫(时长 / 出手时刻和这类武器的普攻一样)；吟唱 = 骑士立誓(chant_noble_<大类> 自动选)
    "anim_overrides": {"sword": {"attack_cone": "attack_cone_noble_sword"}, "polearm": {"attack_cone": "attack_cone_noble_polearm"},
                       "focus": {"attack_cone": "attack_cone_noble_focus"}},
    "chant_fx": {"node_noble_rebloom": {"anim": "chant_noble", "min_star": 1, "no_ring": True, "petals": True}},
    # 百合骑士的骑士：开战后她身后站着一个黄光组成的骑士虚影(她自己的模型)，每次触发挥一次普攻(两次之间至少隔 min_interval 秒)
    "phantom_fx": {"trigger": "node_noble_knight", "color": "#ffd76a", "min_interval": 0.75, "back": 0.95, "lift": 0.3, "scale": 1.3},
    "triggers": [
        # 被动 1 正色百合：五个来源，层数 = 触发数值(都配同一个能力)
        T("node_noble_lily_time", "OnBattleFrame", ["battle_frame", "passive_lily"], count=12, flat=1.0, conds=[{"type": "battle_running"}], **_LILY),
        T("node_noble_lily_attack", POP, ["normal_attack", "passive_lily"], count=3, flat=1.0, **_LILY),
        T("node_noble_lily_kill", "OnAllyUnitKilled", ["ally_unit_killed", "passive_lily"], flat=1.0, conds=[{"type": "event_target_enemy"}], **_LILY),
        T("node_noble_lily_fallen", "OnAllyUnitDied", ["ally_unit_died", "passive_lily"], flat=3.0, conds=[{"type": "event_dead_not_summon"}], **_LILY),
        # 为队友提供治疗：同一下分给几个人也只算一次(0.2 秒冷却)
        T("node_noble_lily_heal", "OnHealApplied", ["heal", "passive_lily"], flat=2.0, cd_sec=0.2,
          conds=[{"type": "event_target_not_source"}, {"type": "event_value_at_least", "value": 1.0}], **_LILY),
        # 被动 2 再绽之花(4 费：不用 2 星解锁)：吟唱中每个战斗帧按吟唱秒数结算"每秒"；花瓣满层、没在吟唱、能行动 → 开始吟唱
        T("node_noble_rebloom_tick", "OnBattleFrame", ["battle_frame", "passive_rebloom_tick"], rule="self", team="ally",
          conds=[{"type": "source_chanting_ability", "ability_id": "node_noble_rebloom"}]),
        T("node_noble_rebloom", "OnBattleFrame", ["battle_frame", "passive_rebloom"], rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_status_capped", "status_id": "lily_petal"}, {"type": "source_not_chanting"},
                 {"type": "source_can_act"}]),
        # 花蕊的光刃命中(事件数值 = 这一下对所有目标造成的伤害)：消耗 1 层花蕊 + 智能分配等量治疗
        T("node_noble_stamen", NA, ["normal_attack", "passive_stamen"], mode="event_value", ratio=1.0, rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "attack_variant", "value": "cone"}]),
        # 触发器 百合骑士的骑士
        dict(T("node_noble_knight", "OnEnemyNear", ["enemy_near", "equipment_payload"], mode="attack_times_healing_bonus", ratio=NOBLE_Z["1"],
               ratio_star=NOBLE_Z, rule="event_target", team="enemy", radius=NOBLE_NEAR), extra={"linger": NOBLE_LINGER}),
    ],
    "passive_abilities": [
        A("node_noble_lily", "blade", "stat_status", keywords=["stacking"], kv={"stacking": 12},
          timings=["OnBattleFrame", POP, "OnAllyUnitKilled", "OnAllyUnitDied", "OnHealApplied"], tags=["passive_lily"],
          cfg={"status_id": "lily_petal", "duration": 0.0, "flags": ["buff", "no_dispel"], "add_stacks_from_value": True, "off_with": "lily_bloom",
               "stats_by_star": {"healing_done_pct": {"flat": NOBLE_X}},
               "stats_at_by_star": {"4": {"max_health": {"flat": NOBLE_HP}},
                                    "8": {"defense": {"flat": NOBLE_DR}, "magic_resistance": {"flat": NOBLE_DR}}}}),
        A("node_noble_rebloom", "blade", "lily_rebloom", keywords=["multi_attack", "chant", "stacking"], kv={"multi_attack": 9, "chant": 3, "stacking": 3},
          timings=["OnBattleFrame"], tags=["passive_rebloom"],
          cfg={"petal_status": "lily_petal", "petal_passive": "node_noble_lily", "per_tick": 4, "bloom_after": 12, "bloom_status": "lily_bloom",
               "stamen": {"status_id": "lily_stamen", "duration": 0.0, "flags": ["buff", "no_dispel", "na_heal_final"],
                          "meta": {"cone": dict(NOBLE_CONE, passive="node_noble_rebloom")}, "meta_by_star": {"cone_scale": NOBLE_Y}}}),
        A("node_noble_rebloom_tick", "blade", "lily_tick", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_rebloom_tick"],
          cfg={"rebloom": "node_noble_rebloom"}),
        A("node_noble_stamen", "blade", "lily_cone_heal", keywords=["basic"], timings=[NA], tags=["passive_stamen"], cfg={"status_id": "lily_stamen"}),
    ],
})

# 蓝 · 安保 · 4费 · 战士模版 —— 执剑节点(Node Brave：长春花蓝长发、象牙白龙角与龙尾、藏青白金十字骑士装的龙骑士；希望)；唯一(同真望节点)；
# 基础武器单手近战，可装备双手重武器
# 勇者，圣剑：开战及每 5 秒，对当前目标(还没有目标时 = 最近的敌人)发动——普通怪物(mob_ 且不是精英 / 首领)直接击杀；
#   否则造成 x × (100 + 法强)% × 目标最大生命 的真实伤害(百分比真实伤害；触发数值 = x × (100 + 法强)%，能力按目标最大生命换算)
# 梦想，未来：开战获得不可驱散的【梦想】——免疫负面状态(flag debuff_immune_all：任何带 debuff 标记的状态都挂不上)，
#   队友施加给她的属性提升类状态，数值 × y(meta ally_buff_amp → Effects.amp_stats_cfg)。阵亡时，把她身上所有属性提升类状态加在一起，
#   做成持续时间无限的【未来】施加给全体队友(Pipeline._brave_legacy)
# 触发器 与你，再度飞翔：每 10 秒；目标 = 自身 + 攻击力最高的已阵亡队友(target_filter.allow_dead)——触发器接受非常规用法：
#   会伤人的武器效果照样打在她自己身上(用户 2026-10-07 定；已阵亡的那个本来就打不到)，
#   触发数值 = z × (100 + 法强)%(和改修节点·应急道具同一写法：z% × (100 + 法强))
BRAVE_X = {"1": 0.06, "2": 0.09, "3": 0.14}               # 圣剑：目标最大生命的 x × (100 + 法强)% 真实伤害
BRAVE_Y = {"1": 1.5, "2": 1.75, "3": 2.0}                 # 梦想：队友提供的属性提升 × y
BRAVE_Z = {"1": 300.0, "2": 450.0, "3": 700.0}            # 与你，再度飞翔：触发数值 = z × (100 + 法强)%
BRAVE_ATK = 150                                           # 她自己的身板(覆盖 4 费战士模版的 攻 200 / 生命 2600；同血嗜节点)：
BRAVE_HP = 2000                                           #   圣剑直接击杀普通怪物本身就值一张 4 费(见 GAME_DESIGN)
BRAVE_SLAY = True                                         # 圣剑直接击杀普通怪物(用户原文)。可选的收紧写法(能力配置)：slay_first_only = 只有开战那一下；
                                                          #   slay_below = 0.5 只斩生命 ≤ 50% 的(★1 强度：原文 78 / 只开战 60 / ≤50% 44，见 GAME_DESIGN)
units.append({
    "id": "node_brave", "cost": 4, "role": "warrior", "template": "warrior", **W("sword", ["sword", "heavy"]),
    "faction_id": "blue", "profession_id": "security", "model": "brave", "reworked": True, "unique": True,
    "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("warrior", 4, attack_power=BRAVE_ATK, max_health=BRAVE_HP),
    "triggers": [
        # 被动 1 勇者，圣剑：开打的第一个战斗帧就发动，之后冷却 5 秒(没有敌人时不发动、不进冷却)
        T("node_brave_holy", "OnBattleFrame", ["battle_frame", "passive_holy"], mode="flat_times_ability_power_pct", flat=BRAVE_X["1"],
          flat_star=BRAVE_X, rule="target_or_nearest_enemy", team="enemy", cd_sec=5.0, conds=[{"type": "battle_running"}, {"type": "has_enemies"}]),
        # 被动 2 梦想，未来(4 费：不用 2 星解锁)：开战挂上【梦想】；阵亡时扩散
        T("node_brave_dream", "OnBattleStart", ["battle_start", "passive_dream"], rule="self", team="ally"),
        T("node_brave_future", "OnUnitDied", ["unit_died", "passive_future"], rule="self", team="ally"),
        # 触发器 与你，再度飞翔：每 10 秒
        dict(T("node_brave_fly", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=40, mode="flat_times_ability_power_pct", flat=BRAVE_Z["1"],
               flat_star=BRAVE_Z, rule="self_and_top_dead_ally", team="ally", conds=[{"type": "battle_running"}]),
             target_filter={"allow_dead": True}),
    ],
    "passive_abilities": [
        A("node_brave_holy", "blade", "holy_sword", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_holy"], cfg={"slay_common": BRAVE_SLAY}),
        A("node_brave_dream", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_dream"],
          cfg={"status_id": "brave_dream", "duration": 0.0, "flags": ["buff", "no_dispel", "debuff_immune_all"], "meta_by_star": {"ally_buff_amp": BRAVE_Y}}),
        A("node_brave_future", "blade", "brave_legacy", keywords=["basic"], timings=["OnUnitDied"], tags=["passive_future"],
          cfg={"legacy": {"status_id": "brave_future", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"]}}),
    ],
})

# 红 · 福利 · 4费 · 坦克模版 —— 共歌节点(Node Pacifist：红色卷发、坐着轮椅的人鱼歌姬；沉沦之梦)；基础武器单手近战，可装备双手重武器、双手长武器
# 温柔地：开局 10 秒(从开打算起)，所有单位受到的伤害最终降低 ★50/75/87.5%，不分敌我(Battle.gentle，Effects.damage 最后乘)
# 美妙地【永恒】【叠加 20】：替代常规普通攻击——她的普攻不造成伤害(自定义普攻载荷 none)，每次普攻给场上所有其他人(不分敌我)叠一层【沉醉】
#   【沉醉】可叠加、不可驱散、跨战斗持续(永恒：Battle.eternal_out → 花名册 eternal → 下一场挂回去)：每层伤害减免 -x1、伤害增幅 +x4
# 触发器 善良地：每 5 秒；目标 = 所有持有沉醉的单位(受群攻限制，层数多的先)，触发数值 = y × 目标的沉醉层数(按目标算：target_status_stacks)
INTOX_DR = {"1": 0.02, "2": 0.02, "3": 0.025}             # 沉醉：每层伤害减免 -x1/x2/x3
INTOX_AMP = {"1": 0.04, "2": 0.05, "3": 0.06}             # 沉醉：每层伤害增幅 +x4/x5/x6
GENTLE_K = {"1": 0.5, "2": 0.75, "3": 0.875}              # 温柔地：受到的伤害最终降低(用户定)
KIND_Y = {"1": 20.0, "2": 30.0, "3": 45.0}                # 善良地：触发数值 = y × 目标沉醉层数
_PAC_ANIM = {w: {"idle": "idle_pacifist_" + w, "run": "run_pacifist_" + w, "attack": "attack_pacifist_" + w} for w in ("sword", "heavy", "polearm")}
units.append({
    "id": "node_pacifist", "cost": 4, "role": "tank", "template": "tank", **W("sword", ["sword", "heavy", "polearm"]),
    "faction_id": "red", "profession_id": "welfare", "model": "pacifist", "reworked": True,
    "target_priority": "nearest", "radius": 0.5,
    "base_stats": TEMPLATE("tank", 4),
    # 坐轮椅的人鱼：待机 / 移动(轮椅自己滑)/ 普攻(唱歌)都用她自己的
    "anim_overrides": _PAC_ANIM,
    # 善良地真的触发时：她身上一圈心形脉冲、被打到的人头上的沉醉音符亮一下(表现层 BattleView._on_trigger)
    "trigger_fx": {"node_pacifist_kind": {"fx": "kind_pulse", "color": "#ff4f9e"}},
    # 美妙地：替代常规普通攻击——普攻载荷不造成任何效果，由"进行普通攻击时"的被动唱出沉醉
    "normal_attack_ability": A("node_pacifist_na", "blade", "none", keywords=["basic", "normal_attack"], timings=[POP], tags=["normal_attack_perform"]),
    "triggers": [
        T("node_pacifist_gentle", "OnBattleStart", ["battle_start", "passive_gentle"], rule="self", team="ally"),
        T("node_pacifist_song", POP, ["normal_attack", "passive_song"], rule="self", team="ally"),
        # 触发器 善良地：每 5 秒
        T("node_pacifist_kind", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=20, mode="target_status_stacks", ratio=KIND_Y["1"],
          ratio_star=KIND_Y, status="intox", rule="all_units", team="any", sort="status_stacks_desc:intox",
          conds=[{"type": "battle_running"}]) | {"target_filter": {"has_status": "intox"}},
    ],
    "passive_abilities": [
        A("node_pacifist_gentle", "blade", "gentle_field", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_gentle"],
          cfg={"duration": 10.0, "reduce_by_star": GENTLE_K}),
        A("node_pacifist_song", "blade", "intox_song", keywords=["eternal", "stacking"], kv={"stacking": 20}, timings=[POP], tags=["passive_song"],
          cfg={"status": {"status_id": "intox", "duration": 0.0, "flags": ["no_dispel"],
                          "stats_by_star": {"damage_taken_pct": {"flat": {k: -v for k, v in INTOX_DR.items()}}, "damage_dealt_pct": {"flat": INTOX_AMP}}}}),
    ],
})

# 青 · 福利 · 3费 · 射手模版 —— 白羽节点(Node Angel：浅蓝长发、白色大羽翼、黑白金修女装的天使枪手；飞蝶)；基础武器双持远程，可装备单手远程、双手远程
# 致向死的渴望【叠加 z】：每第二发普攻(双枪 = 追击那发)改打射程里生命低于 97% 的队友，回复其 3% 最大生命(没有合法队友就照常打敌人)；
#   所有普攻(敌我都算)都给打中的目标叠一层【送葬】(可叠加、不可驱散、负面)。叠到 z 层：普通怪物和棋子(node_)立刻死亡、不触发阵亡效果；
#   否则(精英 / 首领)失去 x% 生命上限(【送葬之痕】累计)，送葬全部消耗
# 致求生的意志(2 星)：持有送葬的队友(含自己)承受致命伤害时不阵亡(留 1 点)，这一下伤害每有 y 点再叠一层送葬(叠满就照规则倒下)
# 触发器 致将亡而未亡者：每 5 秒，连续触发 4 次(extra.repeat，间隔 0.12 秒，每次重新选)；目标 = 送葬层数最多的敌人，触发数值 10
ANGEL_Z = 10                                              # 【叠加 z】：送葬叠到这么多层结算(只有一个值)；30 层时一场战斗里根本叠不满(探针 0 次)，10 层 ★1 强度 29
ANGEL_X = {"1": 0.12, "2": 0.18, "3": 0.25}               # 精英 / 首领：失去 x% 生命上限
ANGEL_Y = {"1": 250.0, "2": 250.0, "3": 150.0}            # 致求生的意志：致命伤害每 y 点 +1 层(y1/y1/y2；1 星的值只是占位)
units.append({
    "id": "node_angel", "cost": 3, "role": "archer", "template": "archer", **W("pistols", ["pistols", "crossbow", "rifle"]),
    "faction_id": "cyan", "profession_id": "welfare", "model": "angel", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    # 致将亡而未亡者真的触发时：每一发一只黑 / 白蝴蝶从她身上扑向目标(表现层 BattleView._on_trigger)
    "trigger_fx": {"node_angel_requiem": {"fx": "requiem", "color": "#f4f2ff"}},
    "base_stats": TEMPLATE("archer", 3),
    "triggers": [
        # 被动 1 致向死的渴望：开战挂上规则状态(打向队友的普攻 = 回复)；每次普攻命中给目标叠送葬
        T("node_angel_wish", "OnBattleStart", ["battle_start", "passive_wish"], rule="self", team="ally"),
        T("node_angel_funeral", NA, ["normal_attack", "passive_funeral"], rule="event_target", team="any"),
        # 被动 2 致求生的意志(2 星)：队友 / 自己即将阵亡、身上有送葬
        T("node_angel_will", "OnAllyBeforeDeath", ["ally_before_death", "passive_will"], rule="event_target", team="ally", unlock=2,
          conds=[{"type": "event_target_has_status", "status_id": "funeral"}]),
        T("node_angel_will_self", "OnBeforeDeath", ["before_death", "passive_will"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_has_status", "status_id": "funeral"}]),
        # 触发器 致将亡而未亡者：每 5 秒连续 4 次
        dict(T("node_angel_requiem", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=20, flat=10.0, rule="all_enemies", team="enemy",
               sort="status_stacks_desc:funeral", conds=[{"type": "battle_running"}, {"type": "has_enemies"}]),
             extra={"repeat": 4, "repeat_gap": 0.12}),
    ],
    "passive_abilities": [
        A("node_angel_wish", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_wish"],
          cfg={"status_id": "death_wish", "duration": 0.0, "flags": ["buff", "no_dispel", "hidden"],
               "meta": {"na_ally_effect": "angel_heal", "angel_alt": {"below": 0.97, "heal_pct": 0.03}}}),
        A("node_angel_funeral", "blade", "funeral_mark", keywords=["stacking"], kv={"stacking": ANGEL_Z}, timings=[NA], tags=["passive_funeral"],
          cfg={"status": {"status_id": "funeral", "duration": 0.0, "flags": ["debuff", "no_dispel"]}, "loss_by_star": ANGEL_X}),
        A("node_angel_will", "blade", "funeral_save", keywords=["basic"], timings=["OnAllyBeforeDeath", "OnBeforeDeath"], tags=["passive_will"], unlock=2,
          cfg={"per_by_star": ANGEL_Y, "mark_passive": "node_angel_funeral"}),
    ],
})

# 绿 · 研究 · 4费 · 施法者模版 —— 守林节点(Node Warden：原储备模型 shaman 改名 warden——橄榄绿短发、狮耳狮尾的荒野萨满；翠绿之林)；
# 基础武器双手长，可装备单手近战、法器
# 护林狂怒：在变身状态下，攻击形态与所携带的武器无关(形态状态 meta.wclass_form 改写攻击模组：近战、自己的节奏 / 倍率 / 普攻关键词；武器的属性和效果照旧)。
#   开战进入狮子形态(普攻倍率以生命值计算：最大生命 × LION_HP；普攻【追击 x1/x2/x3】)；第一次阵亡 → 巨蜘蛛形态(普攻命中叠中毒，持续 x7 秒)；
#   第二次阵亡 → 巨蟾蜍形态(护甲与魔抗 +x8/x9/x10，普攻命中施加像色欲的余烬那样的束缚：toad_bind)；第三次阵亡 → 基础形态(之后再倒下就是真的倒下)
#   中毒：独立施加，可驱散，负面状态；每秒 x4/x5/x6 × (100 + 法强)% 的魔法持续伤害
# 荒野意志：每次切换形态时(包括开局进入狮子)恢复 1 点生命，获得 最大生命 × y × (100 + 法强)% 的护盾
# 触发器 原初血脉：切换形态时(包括开局)；目标 = 自身，触发数值 = 最大生命 × z × (100 + 法强)%
WARDEN_PURSUIT = {"1": 1, "2": 1, "3": 2}                 # 狮子：普攻【追击 x1/x2/x3】
WARDEN_LION_HP = 0.06                                     # 狮子：普攻触发数值 = 最大生命 × 6%(以生命值计算)
WARDEN_POISON_DUR = 5.0                                   # 中毒持续 x7 秒
WARDEN_POISON = {"1": 15.0, "2": 22.0, "3": 35.0}         # 中毒每秒 x4/x5/x6 × (100 + 法强)%
WARDEN_TOAD_DR = {"1": 40.0, "2": 60.0, "3": 90.0}        # 巨蟾蜍：护甲与魔抗 +x8/x9/x10
WARDEN_Y = {"1": 0.35, "2": 0.45, "3": 0.60}              # 荒野意志：护盾 = 最大生命 × y × (100 + 法强)%
WARDEN_Z = {"1": 0.08, "2": 0.12, "3": 0.18}              # 原初血脉：触发数值 = 最大生命 × z × (100 + 法强)%
_BEAST = {"ranged": False, "projectile": "", "proj_speed": 0.0, "na_class": "sword", "multi": {}, "ammo": None}
WARDEN_FORMS = {
    "lion": {"status_id": "form_lion", "pursuit_by_star": WARDEN_PURSUIT,
             "wclass_form": dict(_BEAST, range=1.0, interval=0.8, windup=0.24, recover=0.16, copy_delay=0.16, na_scaling="max_health", na_mult=WARDEN_LION_HP,
                                 anim_set="lion")},
    "spider": {"status_id": "form_spider",
               "wclass_form": dict(_BEAST, range=1.2, interval=0.8, windup=0.28, recover=0.16, na_scaling="", na_mult=1.0, na_keywords={}, anim_set="spider")},
    "toad": {"status_id": "form_toad", "stats_by_star": {"defense": {"flat": WARDEN_TOAD_DR}, "magic_resistance": {"flat": WARDEN_TOAD_DR}},
             "wclass_form": dict(_BEAST, range=1.4, interval=1.0, windup=0.35, recover=0.2, na_scaling="", na_mult=1.0, na_keywords={}, anim_set="toad")},
}
for _f in WARDEN_FORMS.values():
    _f["wclass_form"].pop("ammo", None)
units.append({
    "id": "node_warden", "cost": 4, "role": "caster", "template": "caster", **W("polearm", ["polearm", "sword", "focus"]),
    "faction_id": "green", "profession_id": "research", "model": "warden", "reworked": True,
    "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("caster", 4),
    "triggers": [
        # 被动 1 护林狂怒：开战进入狮子形态；本应阵亡时换下一个形态
        T("node_warden_fury", "OnBattleStart", ["battle_start", "passive_fury"], rule="self", team="ally"),
        T("node_warden_shift", "OnBeforeDeath", ["before_death", "passive_shift"], rule="self", team="ally"),
        T("node_warden_venom", NA, ["normal_attack", "passive_venom"], mode="flat_times_ability_power_pct", flat=WARDEN_POISON["1"], flat_star=WARDEN_POISON,
          rule="event_target", team="enemy", conds=[{"type": "source_has_status", "status_id": "form_spider"}]),
        T("node_warden_tongue", NA, ["normal_attack", "passive_tongue"], rule="event_target", team="enemy",
          conds=[{"type": "source_has_status", "status_id": "form_toad"}]),
        # 被动 2 荒野意志(4 费：不用 2 星)：每次切换形态(2026-10-07 用户：开局进入狮子也给)
        T("node_warden_will", "OnFormShift", ["form_shift", "passive_will"], mode="max_health_times_ap_pct", ratio=WARDEN_Y["1"], ratio_star=WARDEN_Y,
          rule="self", team="ally"),
        # 触发器 原初血脉：切换形态时(包括开局)
        T("node_warden_blood", "OnFormShift", ["form_shift", "equipment_payload"], mode="max_health_times_ap_pct", ratio=WARDEN_Z["1"], ratio_star=WARDEN_Z,
          rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_warden_fury", "blade", "warden_shift", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_fury"],
          cfg={"to": "lion", "forms": WARDEN_FORMS}),
        A("node_warden_shift", "blade", "warden_shift", keywords=["basic"], timings=["OnBeforeDeath"], tags=["passive_shift"], priority=10,
          cfg={"forms": WARDEN_FORMS}),
        A("node_warden_venom", "blade", "stat_status", keywords=["basic"], timings=[NA], tags=["passive_venom"],
          cfg={"status_id": "poison", "duration": WARDEN_POISON_DUR, "max_stacks": 1, "independent": True, "flags": ["debuff", "dispellable", "poison"],
               "dot": {"kind": "magic", "amount": 0.0, "interval": 1.0}, "dot_from_value": True}),
        A("node_warden_tongue", "blade", "entangle", keywords=["basic"], timings=[NA], tags=["passive_tongue"],
          cfg={"status_id": "toad_bind", "flags": ["rooted", "no_dispel"]}),
        A("node_warden_will", "blade", "wild_will", keywords=["basic"], timings=["OnFormShift"], tags=["passive_will"]),
    ],
})

# 黄 · 研究 · 3费 · 施法者模版 —— 导向节点(Node Psychic：储备模型 psychic——金发猫耳、藏青水手服的雷电魔导士；电磁学导论)；
# 基础武器法器，可装备双手远程(步枪)、单手远程(手弩)、双持远程(双枪)
# 引雷【吟唱 3】：普通攻击需要吟唱(和弓的拉弓同一套：前摇后吟唱最多 3 秒，拉满 ×2)，然后发出在敌人之间弹跳 x1/x2/x3 次的连锁闪电；
#   每一跳都是完整的普攻(武器大类的倍率、普攻关键词照旧：法器每跳都溅射、双枪第一跳追击——追击那发自己再连一串)；
#   可以弹回打过的人，但不能连着弹同一个人(Battle.chain_lightning：下一跳 = 3 米内的另一个敌人，先挑没打过的里最近的，都打过了才弹回去)
# 变天(2 星)：按章节换战场天气——白之章没有效果；红之章下雨(所有人被施加的燃烧持续时间减半)；紫之章晴天(寒气的攻速削减减半)；
#   蓝之章起雾(用户 2026-10-08)：敌我双方的远程非法器普攻有 PSY_FOG 的概率被闪避(Pipeline.fog_dodge，和普攻闪避率加在一起，会触发"闪开了一次普攻")
# 触发器 电闪：普通攻击弹跳结束时(OnChainEnd)；目标 = 这一串打到的所有敌人，触发数值 = 攻击力 × y
PSY_CHANT = 3                                              # 【吟唱 3】
PSY_X = {"1": 4, "2": 4, "3": 5}                           # 弹跳 x1/x2/x3 次
PSY_CHAIN_R = 5.0                                          # 下一跳离这一跳的目标多远以内(米，身体边缘)
PSY_Y = {"1": 1.2, "2": 1.4, "3": 1.7}                     # 电闪：攻击力 × y
PSY_FOG = 0.25                                             # 起雾：远程非法器普攻被闪避的概率
units.append({
    "id": "node_psychic", "cost": 3, "role": "caster", "template": "caster", **W("focus", ["focus", "rifle", "crossbow", "pistols"]),
    "faction_id": "yellow", "profession_id": "research", "model": "psychic", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 3),
    # 吟唱时的动作(普攻的吟唱 = 拉弓阶段：draw_anim 放一次，再循环 draw_hold_anim)
    "wclass_overrides": {c: {"draw_anim": "chant_psychic_" + c, "draw_hold_anim": "chant_psychic_%s_hold" % c}
                         for c in ["focus", "rifle", "crossbow", "pistols"]},
    "triggers": [
        # 被动 1 引雷：开战挂上规则状态(普攻带吟唱、改为连锁闪电)
        T("node_psychic_call", "OnBattleStart", ["battle_start", "passive_call"], rule="self", team="ally"),
        # 被动 2 变天(2 星)
        T("node_psychic_weather", "OnBattleStart", ["battle_start", "passive_weather"], rule="self", team="ally", unlock=2),
        # 触发器 电闪：普攻弹跳结束时
        T("node_psychic_flash", "OnChainEnd", ["chain_end", "equipment_payload"], mode="attack_ratio", ratio=PSY_Y["1"], ratio_star=PSY_Y,
          rule="event_meta_targets", team="enemy"),
    ],
    "passive_abilities": [
        # (【吟唱 3】写在规则状态里给普攻；能力本身不带吟唱关键词，否则管线会把这个被动当成要吟唱的技能)
        A("node_psychic_call", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_call"],
          cfg={"status_id": "lightning_call", "duration": 0.0, "flags": ["buff", "no_dispel", "hidden"],
               "meta": {"na_chant": PSY_CHANT, "na_chain": {"bounces_by_star": PSY_X, "radius": PSY_CHAIN_R}}}),
        A("node_psychic_weather", "blade", "weather_change", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_weather"], unlock=2,
          cfg={"by_chapter": {"red": "rain", "purple": "sunny", "blue": "fog"}, "params": {"fog": {"dodge": PSY_FOG}}}),
    ],
})

# 蓝 · 安保 · 3费 · 战士模版 —— 圣战节点(Node Paladin：储备模型 paladin——蓝发蓝胡子、白金重甲的锤骑士；大锤)；
# 基础武器双手重，可装备单手剑、双手长
# 裂地猛击：每 5 秒(到点时锥形够得着的地方没有敌人就蓄着，有敌人进来立刻砸，砸完重新计时)，智能地朝压到最多敌人的方向砸地——锥形里的所有敌人受到 x × (100 + 法强)% 魔法伤害，
#   破坏锥形里的地形(断壁残垣 / 燃烧废墟碎掉、余烬熄灭、寒雾散开；祭坛 / 喷泉打不碎)。出手 0.3 秒后(动作砸到地上)结算
# 圣疗(2 星)：每 4 秒(有友军掉血才计时)，对生命比例最低的友军回复 y × (100 + 法强)%
# 触发器 神圣战争：裂地猛击造成伤害时(OnSkillHit)；目标 = 受到伤害的敌人，触发数值 = z × (100 + 法强)%
PAL_X = {"1": 300.0, "2": 450.0, "3": 700.0}            # 裂地猛击：x × (100 + 法强)% 魔法伤害
PAL_Y = {"1": 150.0, "2": 220.0, "3": 350.0}            # 圣疗：y × (100 + 法强)%
PAL_Z = {"1": 100.0, "2": 130.0, "3": 180.0}            # 神圣战争：z × (100 + 法强)%
PAL_CONE = {"angle": 100.0, "length": 3.5}              # 锥形：100 度、3.5 米
units.append({
    "id": "node_paladin", "cost": 3, "role": "warrior", "template": "warrior", **W("heavy", ["heavy", "sword", "polearm"]),
    "faction_id": "blue", "profession_id": "security", "model": "paladin", "reworked": True,
    "target_priority": "nearest", "radius": 0.48,
    "base_stats": TEMPLATE("warrior", 3),
    "triggers": [
        # 被动 1 裂地猛击：每 5 秒(20 个战斗帧)；到点时没有敌人够得着就蓄着(meta.slam_pending)，有敌人进来马上砸(下一个触发器)
        T("node_paladin_slam", "OnBattleFrame", ["battle_frame", "passive_slam"], count=20, mode="flat_times_ability_power_pct", flat=PAL_X["1"],
          flat_star=PAL_X, rule="self", team="ally", conds=[{"type": "battle_running"}]),
        T("node_paladin_slam_held", "OnBattleFrame", ["battle_frame", "passive_slam"], mode="flat_times_ability_power_pct", flat=PAL_X["1"],
          flat_star=PAL_X, rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_meta_has", "key": "slam_pending"}, {"type": "enemy_near", "radius": PAL_CONE["length"]}]),
        # 被动 2 圣疗(2 星)：每 4 秒(16 个战斗帧；有友军掉血才计时)
        T("node_paladin_heal", "OnBattleFrame", ["battle_frame", "passive_heal"], count=16, mode="flat_times_ability_power_pct", flat=PAL_Y["1"],
          flat_star=PAL_Y, rule="all_allies", team="ally", sort="health_ratio_asc", unlock=2,
          conds=[{"type": "battle_running"}, {"type": "has_hurt_ally"}]),
        # 触发器 神圣战争：裂地猛击造成伤害时
        T("node_paladin_holywar", "OnSkillHit", ["skill_hit", "equipment_payload"], mode="flat_times_ability_power_pct", flat=PAL_Z["1"], flat_star=PAL_Z,
          rule="event_meta_targets", team="enemy", conds=[{"type": "event_metadata_equals", "key": "skill", "value": "node_paladin_slam"}]),
    ],
    "passive_abilities": [
        A("node_paladin_slam", "blade", "quake_slam", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_slam"],
          cfg={**PAL_CONE, "impact": 0.3, "lock": 0.8, "timer": "node_paladin_slam"}),
        A("node_paladin_heal", "blade", "heal", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_heal"], unlock=2),
    ],
})

# 白 · 情报 · 2费 · 刺客模版 —— 巧运节点(Node Rogue：储备模型 rogue——银发精灵小偷，男；匕首与金币)；基础武器双持近战，可装备双持远程
# 妙手：每次普攻命中，有 x% 的几率摸到 1 金币(战后入账)
# 真骰(2 星)：更高几率遇到高稀有度事件(稀有度 2 / 3 的权重 ×1.5 / ×2)；事件里有明确好坏的随机结果(结果写了 luck)重投 1 次取好的；
#   战斗里自己的概率(暴击、闪避、被麻痹打断、远距离打空、药剂大成功 / 失败、晶球升级、妙手、钱袋)也掷两次取好的(Battle.roll_good / roll_bad)
# 触发器 鸿运，大概吧：妙手摸到金币时(OnGoldGain，来源 = 妙手)；目标 = 自身，触发数值 = 1 / 1 / 2
ROGUE_X = {"1": 0.02, "2": 0.03, "3": 0.05}                 # 妙手：每次普攻 x% 摸到 1 金币
ROGUE_LUCK = {"2": 1.5, "3": 2.0}                           # 真骰：稀有度 2 / 3 的事件权重倍率
units.append({
    "id": "node_rogue", "cost": 2, "role": "assassin", "template": "assassin", **W("dual", ["dual", "pistols"]),
    "faction_id": "white", "profession_id": "information", "model": "rogue", "reworked": True,
    "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("assassin", 2),
    "triggers": [
        # 被动 1 妙手：普攻命中时
        T("node_rogue_pickpocket", NA, ["normal_attack", "passive_pickpocket"], rule="self", team="ally"),
        # 被动 2 真骰(2 星)：开战挂上规则状态(lucky)
        T("node_rogue_dice", "OnBattleStart", ["battle_start", "passive_dice"], rule="self", team="ally", unlock=2),
        # 触发器 鸿运，大概吧：妙手摸到金币时
        T("node_rogue_fortune", "OnGoldGain", ["gold_gain", "equipment_payload"], flat=1.0, flat_star={"1": 1.0, "2": 1.0, "3": 2.0},
          rule="self", team="ally", conds=[{"type": "event_metadata_equals", "key": "source", "value": "node_rogue_pickpocket"}]),
    ],
    "passive_abilities": [
        A("node_rogue_pickpocket", "blade", "pickpocket", keywords=["basic"], timings=[NA], tags=["passive_pickpocket"],
          cfg={"chance_by_star": ROGUE_X, "amount": 1}),
        A("node_rogue_dice", "blade", "true_dice", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_dice"], unlock=2,
          cfg={"event_rarity_mult": ROGUE_LUCK}),
    ],
})

# 蓝 · 福利 · 2费 · 施法者模版 —— 心连节点(Node Sister：储备模型 sister——人偶修女；祝福之心)；基础武器法器，可装备单手剑
# 量产型号【召唤】：开战及每 x 秒，召唤一个自身的复制(同星级)；复制品没有量产型号(meta.sister_copy)，装备基础单手剑
# 治疗祈愿(2 星；复制品也有)：每 y 秒(有友军掉血才计时)，对生命比例最低的友军回复 y' × (100 + 法强)%，并清除其一个剩余时间最长的负面状态
# 触发器 奇迹：每阵亡 2 只心连节点(复制品也算；OnAllyUnitDied 计数 2)；目标 = 一个已阵亡友方单位(非召唤物优先，最近倒下的优先)，z × (100 + 法强)%
SISTER_X = {"1": 32, "2": 28, "3": 20}                    # 量产型号：每 8 / 7 / 5 秒(战斗帧)
SISTER_PRAY_EVERY = {"1": 20, "2": 20, "3": 12}           # 治疗祈愿：每 5 / 5 / 3 秒(战斗帧；1 星的只是占位)
SISTER_PRAY = {"1": 120.0, "2": 120.0, "3": 200.0}        # 治疗祈愿：y × (100 + 法强)%
SISTER_Z = {"1": 150.0, "2": 220.0, "3": 350.0}           # 奇迹：z × (100 + 法强)%
units.append({
    "id": "node_sister", "cost": 2, "role": "caster", "template": "caster", **W("focus", ["focus", "sword"]),
    "faction_id": "blue", "profession_id": "welfare", "model": "sister", "reworked": True,
    "target_priority": "nearest", "radius": 0.4,
    "base_stats": TEMPLATE("caster", 2),
    "triggers": [
        # 被动 1 量产型号：开战 + 每 x 秒(复制品没有)
        T("node_sister_mass", "OnBattleStart", ["battle_start", "passive_mass"], rule="self", team="ally",
          conds=[{"type": "source_meta_missing", "key": "sister_copy"}]),
        T("node_sister_mass_tick", "OnBattleFrame", ["battle_frame", "passive_mass"], count=SISTER_X["1"], count_star=SISTER_X, rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_meta_missing", "key": "sister_copy"}]),
        # 被动 2 治疗祈愿(2 星)
        T("node_sister_pray", "OnBattleFrame", ["battle_frame", "passive_pray"], count=SISTER_PRAY_EVERY["1"], count_star=SISTER_PRAY_EVERY,
          mode="flat_times_ability_power_pct", flat=SISTER_PRAY["1"], flat_star=SISTER_PRAY, rule="all_allies", team="ally", sort="health_ratio_asc", unlock=2,
          conds=[{"type": "battle_running"}, {"type": "has_hurt_ally"}]),
        # 触发器 奇迹：每阵亡 2 只心连节点
        dict(T("node_sister_miracle", "OnAllyUnitDied", ["ally_unit_died", "equipment_payload"], count=2, mode="flat_times_ability_power_pct",
               flat=SISTER_Z["1"], flat_star=SISTER_Z, rule="dead_ally", team="ally", conds=[{"type": "event_dead_def_is", "def": "node_sister"}]),
             target_filter={"allow_dead": True}),
    ],
    "passive_abilities": [
        A("node_sister_mass", "blade", "mass_production", keywords=["summon"], timings=["OnBattleStart", "OnBattleFrame"], tags=["passive_mass"],
          cfg={"weapon": "basic_sword"}),
        A("node_sister_pray", "blade", "prayer_heal", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_pray"], unlock=2),
    ],
})

# 绿 · 安保 · 4费 · 战士模版 —— 无我节点(Node Killer：10-07 批储备模型 killer——咒刃武士；杀)；基础武器双手重，可装备单手近战
# 逆时幻影【追击 x】【召唤】：普攻会连续攻击(规则状态 meta.na_pursuit)；她普攻时(不算追击副本)：幻影在 → 幻影也普攻一次(以她的普攻计算事件和伤害)，
#   幻影不在(还没召唤 / 被消灭了)→ 在这次的攻击目标附近召唤一个(killer_phantom：1 点生命、不会动、自己不攻击)
# 无我(4 费：1 星就有)：备战时，仓库里还有别的无我节点 → 她身上出现按钮；点了移除一个仓库里的无我节点(星级最低的)，
#   下一场战斗开始时移除所有普通敌人(不触发阵亡效果、不掉晶球)，精英 / 首领失去 y% 生命上限；那一场她拔刀(出鞘的动作)
# 触发器：普攻命中时；目标 = 普攻目标，触发数值 = z(固定)
KILLER_X = {"1": 1, "2": 1, "3": 2}                       # 【追击 x】
KILLER_Y = {"1": 0.20, "2": 0.35, "3": 0.50}              # 无我：精英 / 首领失去 y% 生命上限
KILLER_Z = {"1": 60.0, "2": 90.0, "3": 140.0}             # 触发数值(固定)
units.append({
    "id": "node_killer", "cost": 4, "role": "warrior", "template": "warrior", **W("heavy", ["heavy", "sword"]),
    "faction_id": "green", "profession_id": "security", "model": "killer", "reworked": True,
    "target_priority": "nearest", "radius": 0.44,
    "base_stats": TEMPLATE("warrior", 4),
    # 拿着杀(外观 odachi)：平时挥刀鞘；无我的那一场出鞘(odachi_drawn，BattleView 在 selfless_draw 时换)
    "anim_overrides": {"heavy@odachi": {"attack": "attack_killer_sheathed", "attack_heavy_whirl": "whirl_killer_sheathed"},
                       "heavy@odachi_drawn": {"attack": "attack_killer_drawn", "attack_heavy_whirl": "whirl_killer_drawn"}},
    "triggers": [
        # 被动 1 逆时幻影：开战挂规则状态(普攻带追击)；每次普攻(不算副本)召唤 / 指挥幻影
        T("node_killer_rule", "OnBattleStart", ["battle_start", "passive_rule"], rule="self", team="ally"),
        T("node_killer_phantom", "OnNormalAttackPerform", ["normal_attack", "passive_phantom"], rule="self", team="ally",
          conds=[{"type": "event_metadata_equals", "key": "is_copy", "value": "false"}]),
        # 被动 2 无我：这一场是点过按钮的(meta.selfless)→ 开战清场
        T("node_killer_selfless", "OnBattleStart", ["battle_start", "passive_selfless"], rule="self", team="ally",
          conds=[{"type": "source_meta_has", "key": "selfless"}]),
        # 触发器：普攻命中时
        T("node_killer_strike", NA, ["normal_attack", "equipment_payload"], flat=KILLER_Z["1"], flat_star=KILLER_Z, rule="event_target", team="enemy"),
    ],
    "passive_abilities": [
        A("node_killer_rule", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_rule"],
          cfg={"status_id": "phantom_rule", "duration": 0.0, "flags": ["buff", "no_dispel", "hidden"], "meta_by_star": {"na_pursuit": KILLER_X}}),
        A("node_killer_phantom", "blade", "phantom_strike", keywords=["summon"], timings=["OnNormalAttackPerform"], tags=["passive_phantom"],
          cfg={"unit_id": "killer_phantom", "delay": 0.08, "reach": 1.6}),
        A("node_killer_selfless", "blade", "selfless_purge", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_selfless"],
          cfg={"cut_by_star": KILLER_Y}),
    ],
})
# 逆时幻影的幻影(只能被召唤)：她的样子(半透明)，1 点生命、不会动、自己不攻击——她普攻时由逆时幻影替它出手
units.append({
    "id": "killer_phantom", "cost": 1, "role": "assassin", "template": "assassin", "base_weapon_class": "", "weapon_classes": [],
    "faction_id": "green", "profession_id": "security", "model": "killer", "reworked": True,
    "target_priority": "nearest", "radius": 0.4, "available_in_shop": False, "summon_only": True,
    "anim_overrides": {"heavy@odachi": {"attack": "attack_killer_sheathed", "attack_heavy_whirl": "whirl_killer_sheathed"},
                       "heavy@odachi_drawn": {"attack": "attack_killer_drawn", "attack_heavy_whirl": "whirl_killer_drawn"}},
    "base_stats": {"attack_power": 0, "defense": 0, "magic_resistance": 0, "max_health": 1, "move_speed": 0.0, "attack_range": 1.0},
    "triggers": [],
    "passive_abilities": [],
})

# 紫(2026-10-09 用户：蓝 → 紫) · 研究 · 3费 · 施法者模版 —— 奇兴节点(Node Arcanist：10-07 批储备模型 arcanist——龙裔骰子术士；乱数)；基础武器法器，可装备双手长
# 自无数个世界之中【增幅 2/3/4】【无数世界】：每 x 秒掷 2d10 + 增幅数 + 已阵亡的队友人数，发动随机效果(规则写在关键词【无数世界】里；Pipeline._world_dice)
# 自久远的过去而来(2 星)：以石化状态开始战斗(特殊的眩晕，无法驱散，伤害减免 80%)；已阵亡的友军人数达到仍存活的友军人数时结束石化，
#   获得 当前时间(开打后的秒数) × y 的法术强度和攻击力
# 触发器：每 5 秒；目标 = 以当前目标为中心的圆形范围(2 米)里的所有敌人，触发数值 = z × 攻击力 × (100 + 法强)%
ARC_X = {"1": 18, "2": 16, "3": 12}                       # 每 4.5 / 4 / 3 秒掷一次(战斗帧)
ARC_AMP = {"1": 2, "2": 3, "3": 4}                        # 【增幅 2/3/4】
ARC_TIERS = {"low": 1.5, "mid": 2.4, "high": 3.6}         # 伤害档位：系数 × (攻击力 + 法术强度)
ARC_Y = {"1": 3.0, "2": 3.0, "3": 6.0}                    # 苏醒：每秒 +y 法术强度和攻击力(y1/y1/y2)
ARC_Z = {"1": 1.0, "2": 1.3, "3": 1.8}                    # 触发数值：z × 攻击力 × (100 + 法强)%
_CHILL = {"status_id": "chill", "duration": 5.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "dispellable", "chill"],
          "stats": {"attack_speed_multiplier": {"flat": -0.10}}, "meta": {"freeze_over": 0.40, "freeze_dur": 5.0}}
_POISON = {"status_id": "poison", "duration": 5.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "dispellable", "poison"],
           "dot": {"kind": "magic", "amount": 20.0, "interval": 1.0}}
_PARALYSIS = {"status_id": "paralysis", "duration": 6.0, "max_stacks": 1, "flags": ["debuff", "dispellable", "paralysis"],
              "stats": {"damage_taken_amp": {"flat": 0.10}}, "meta": {"paralyze": 0.10}}
_BURN4 = {"status_id": "burning", "duration": 4.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "burning", "dispellable"],
          "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}}         # 同 BURN(4)(BURN 在后面才定义)
ARC_DEBUFFS = [_BURN4, _CHILL, _POISON, _PARALYSIS]    # 随机通用负面状态：燃烧 / 寒气 / 中毒 / 麻痹
units.append({
    "id": "node_arcanist", "cost": 3, "role": "caster", "template": "caster", **W("focus", ["focus", "polearm"]),
    "faction_id": "purple", "profession_id": "research", "model": "arcanist", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    # 施法者：拿骰子法杖(双手长)也站在后面(走位 / 部署按远程)——石化的她摆在前排会在队友倒下一半之前先被打碎
    "ai_style": "ranged",
    "base_stats": TEMPLATE("caster", 3),
    "triggers": [
        # 被动 1 自无数个世界之中：每 x 秒(石化 / 被控住时不掷)
        T("node_arcanist_worlds", "OnBattleFrame", ["battle_frame", "passive_worlds"], count=ARC_X["1"], count_star=ARC_X, rule="self", team="ally",
          conds=[{"type": "battle_running"}, {"type": "has_enemies"}, {"type": "source_can_act"}]),
        # 被动 2 自久远的过去而来(2 星)：开战石化；有队友倒下时看能不能苏醒
        T("node_arcanist_petrify", "OnBattleStart", ["battle_start", "passive_petrify"], rule="self", team="ally", unlock=2),
        T("node_arcanist_wake", "OnAllyUnitDied", ["ally_unit_died", "passive_wake"], rule="self", team="ally", unlock=2,
          conds=[{"type": "source_has_status", "status_id": "petrified"}, {"type": "team_dead_at_least_alive"}]),
        # 触发器：每 5 秒，当前目标周围的敌人
        T("node_arcanist_strike", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=20, mode="attack_times_ap_pct", ratio=ARC_Z["1"],
          ratio_star=ARC_Z, rule="around_current_target", team="enemy", radius=2.0,
          conds=[{"type": "battle_running"}, {"type": "has_enemies"}, {"type": "source_can_act"}]),
    ],
    "passive_abilities": [
        A("node_arcanist_worlds", "blade", "world_dice", keywords=["amplify", "worlds"], kv={"amplify": ARC_AMP["1"]}, kv_star={"amplify": ARC_AMP},
          timings=["OnBattleFrame"], tags=["passive_worlds"], cfg={"tiers": ARC_TIERS, "debuffs": ARC_DEBUFFS}),
        A("node_arcanist_petrify", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_petrify"], unlock=2,
          cfg={"status_id": "petrified", "duration": 0.0, "flags": ["debuff", "stun", "no_dispel", "petrified"],
               "stats": {"damage_taken_pct": {"flat": 0.80}}, "no_cc_halving": True}),
        A("node_arcanist_wake", "blade", "petrify_wake", keywords=["basic"], timings=["OnAllyUnitDied"], tags=["passive_wake"], unlock=2,
          cfg={"per_sec_by_star": ARC_Y}),
    ],
})

# 绿 · 研究 · 3费 · 施法者模版 —— 锁芯节点(Node Cultist：10-07 批储备模型 keeper——蛇尾钥匙守护者；开与闭)；基础武器双手长，可装备双手重
# 万物闭锁：每普攻 x1 次，智能选一个圆形区域(罩住最多敌人)，里面所有敌人受到 x2 魔法伤害 + 眩晕 x5 秒；开局已经攒了 x8 次计数(extra.count_init)
# 血色仪式(不用 2 星解锁)：在场时自己身上维持【血色仪式】：每秒 y1 点真实持续伤害、自己无法被治疗；我方施加的所有【眩晕】持续时间 +y2%
#   (Effects.apply_status 按施加者那一队活着的【血色仪式】加总)
# 触发器 打开深空之门：场上(所有单位)累计被眩晕的时间每满 z1 秒触发一次(Battle 每累计 1 秒发一次 OnStunSecond，计数 z1)；
#   目标 = 所有曾被眩晕过的敌人(活着的，离自己近的在前)，触发数值 = z2
CULT_EVERY = 3                                            # 每普攻 x1 次
CULT_INIT = 1                                             # 开局计数 x8
CULT_DMG = {"1": 350.0, "2": 560.0, "3": 910.0}           # 万物闭锁：魔法伤害 x2/x3/x4
CULT_STUN = {"1": 2.0, "2": 2.5, "3": 3.0}                # 万物闭锁：眩晕 x5/x6/x7 秒
CULT_RADIUS = 2.2                                         # 万物闭锁：圆的半径(米)
CULT_HP = 1500                                            # 生命(施法者模版 950)
CULT_DEF = 30                                             # 护甲(施法者模版 0)
CULT_BLEED = 12.0                                         # 血色仪式：每秒 y1 点真实伤害
CULT_AMP = {"1": 0.25, "2": 0.40, "3": 0.60}              # 血色仪式：眩晕持续时间 +y2/y3/y4%
CULT_GATE = 8                                             # 深空之门：场上累计眩晕 z1 秒
CULT_Z = {"1": 300.0, "2": 450.0, "3": 700.0}             # 深空之门：触发数值 z2/z3/z4
units.append({
    "id": "node_cultist", "cost": 3, "role": "caster", "template": "caster", **W("polearm", ["polearm", "heavy"]),
    "faction_id": "green", "profession_id": "research", "model": "keeper", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    # 拿长柄贴身出手的施法者(万物闭锁靠普攻计数，按远程走位会站在后面一刀不出)：比施法者模版厚一些
    "base_stats": TEMPLATE("caster", 3, max_health=CULT_HP, defense=CULT_DEF),
    "triggers": [
        # 被动 1 万物闭锁：每普攻 x1 次(开局已攒 x8 次)。标签别带 normal_attack_perform：那是普攻载荷要的标签，带上就会把触发数值当普攻打在自己身上
        T("node_cultist_lock", "OnNormalAttackPerform", ["attack_count", "passive_lock"], count=CULT_EVERY, flat=CULT_DMG["1"],
          flat_star=CULT_DMG, rule="self", team="ally") | {"extra": {"count_init": CULT_INIT}},
        # 被动 2 血色仪式：开战挂上
        T("node_cultist_rite", "OnBattleStart", ["battle_start", "passive_rite"], rule="self", team="ally"),
        # 触发器 打开深空之门：场上累计眩晕每满 z1 秒
        T("node_cultist_gate", "OnStunSecond", ["stun_second", "equipment_payload"], count=CULT_GATE, flat=CULT_Z["1"], flat_star=CULT_Z,
          rule="stunned_enemies", team="enemy", sort="nearest", conds=[{"type": "battle_running"}]),
    ],
    "passive_abilities": [
        A("node_cultist_lock", "blade", "lock_all", keywords=["basic"], timings=["OnNormalAttackPerform"], tags=["passive_lock"],
          cfg={"radius": CULT_RADIUS, "stun_by_star": CULT_STUN, "impact": 0.35}),
        A("node_cultist_rite", "blade", "flag_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_rite"],
          cfg={"status_id": "blood_rite", "duration": 0.0, "flags": ["debuff", "no_dispel", "no_heal", "blood_rite"],
               "dot": {"kind": "true", "amount": CULT_BLEED, "interval": 1.0}, "meta_by_star": {"stun_amp": CULT_AMP}}),
    ],
})

# 青 · 研究(恶魔) / 福利(天使) · 4费 · 施法者模版 —— 变奏节点(Node Pianist：10-07 批储备模型 pianist——青发恶魔钢琴家；黑键 / 白键)；只能用法器
# 表里之间：战斗外头顶有切换按钮(Run.toggle_form)，恶魔形态(研究部，伤害增幅 x1/x2/x3%) ↔ 天使形态(福利部，治疗量加成 x4/x5/x6%)，初始恶魔。
#   形态 = 派生的 UnitDef(forms：部门 / 身体 / 她拿黑键时的外观与名字)；每场一次：阵亡时回满生命并切换为另一形态(濒死时机，算"本场阵亡过")
# 被动 2(魔) 悲怆【叠加 9】：开局及每 3 秒，所有敌人 +1 层【沮丧】；有敌人阵亡 → 所有敌人再 +2 层。
#   【沮丧】：可叠加、可驱散、负面、无限持续；每层每秒 y1 × (100 + 法强)% 魔法持续伤害，攻速与"每数秒"计时器充能速度 -层数 × y7%
# 被动 2(天) 热情【叠加 9】：开局及每 3 秒，所有友军 +1 层【亢奋】；有队友阵亡 → 所有友军再 +2 层。
#   【亢奋】：可叠加、可驱散、无限持续；每层每秒回复 y4 × (100 + 法强)%(算她的治疗)，攻速与计时器充能速度 +层数 × y7%
#   (规格里【亢奋】写的是"负面状态"——按增益做，用户 2026-10-08 确认)
# 触发器 下一乐章：她想给某个状态加层但它已经叠满时(OnStackCapped)，对自己触发，触发数值 = z × (100 + 法强)%
PIA_DMG = {"1": 0.20, "2": 0.30, "3": 0.45}               # 恶魔形态：伤害增幅 x1/x2/x3
PIA_HEAL = {"1": 0.20, "2": 0.30, "3": 0.45}              # 天使形态：治疗量加成 x4/x5/x6
PIA_STACK = 9                                             # 【叠加 9】
PIA_DOT = {"1": 8.0, "2": 10.0, "3": 16.0}                 # 沮丧：每层每秒 y1/y2/y3 × (100 + 法强)% 魔法
PIA_HOT = {"1": 1.5, "2": 2.0, "3": 3.5}                  # 亢奋：每层每秒回复 y4/y5/y6 × (100 + 法强)%
PIA_AS = {"1": 0.02, "2": 0.025, "3": 0.035}                # 沮丧：每层攻速 / 计时器充能速度 -y7/y8/y9
PIA_AS_UP = {"1": 0.01, "2": 0.012, "3": 0.018}            # 亢奋：每层攻速 / 计时器充能速度 +(天使形态全队都吃，比沮丧低一档)
PIA_Z = {"1": 300.0, "2": 450.0, "3": 700.0}              # 下一乐章：z × (100 + 法强)%
PIA_EVERY = 12                                            # 每 3 秒(战斗帧)
_DESPAIR = {"status_id": "despair", "duration": 0.0, "flags": ["debuff", "dispellable", "despair"],
            "dot": {"kind": "magic", "amount": 0.0, "interval": 1.0},
            "stats_by_star": {"attack_speed_multiplier": {"flat": {k: -v for k, v in PIA_AS.items()}},
                              "haste": {"flat": {k: -v for k, v in PIA_AS.items()}}}}
_ELATION = {"status_id": "elation", "duration": 0.0, "flags": ["buff", "dispellable", "elation"],
            "hot": {"flat": 0.0, "interval": 1.0, "src_heal": True},
            "stats_by_star": {"attack_speed_multiplier": {"flat": PIA_AS_UP}, "haste": {"flat": PIA_AS_UP}}}
_PIANO_ANIMS = {"idle": "idle_pianist_play", "run": "run_pianist_play", "attack": "attack_pianist_play"}
units.append({
    "id": "node_pianist", "cost": 4, "role": "caster", "template": "caster", **W("focus", ["focus"]),
    "faction_id": "cyan", "profession_id": "research", "model": "pianist", "reworked": True,
    "target_priority": "nearest", "radius": 0.42,
    "base_stats": TEMPLATE("caster", 4),
    # 形态：部门 / 身体 / 她本人拿黑键时的外观(大三角钢琴，黑 / 白)与名字(天使形态叫白键)
    "forms": {"demon": {"profession_id": "research", "model": "pianist", "weapon_models": {"black_keys": "grand"}},
              "angel": {"profession_id": "welfare", "model": "pianist_angel", "weapon_models": {"black_keys": "grand_white"},
                        "weapon_names": {"black_keys": "white_keys"}}},
    "form_default": "demon",
    # 拿着大钢琴时：站在琴后弹(钢琴挂在 Root 上跟着她走)
    "anim_overrides": {"focus@grand": _PIANO_ANIMS, "focus@grand_white": _PIANO_ANIMS},
    "triggers": [
        # 被动 1 表里之间：开战挂形态加成；阵亡时(每场一次)回满并换形态
        T("node_pianist_form", "OnBattleStart", ["battle_start", "passive_form"], rule="self", team="ally"),
        T("node_pianist_rebirth", "OnBeforeDeath", ["before_death", "passive_rebirth"], rule="self", team="ally", max_acts=1),
        # 被动 2(魔) 悲怆：开局 + 每 3 秒 1 层，敌人阵亡 2 层
        T("node_pianist_grief", "OnBattleStart", ["battle_start", "passive_grief"], mode="flat_times_ability_power_pct", flat=PIA_DOT["1"],
          flat_star=PIA_DOT, rule="all_enemies", team="enemy", conds=[{"type": "source_form", "form": "demon"}]),
        T("node_pianist_grief_tick", "OnBattleFrame", ["battle_frame", "passive_grief"], count=PIA_EVERY, mode="flat_times_ability_power_pct",
          flat=PIA_DOT["1"], flat_star=PIA_DOT, rule="all_enemies", team="enemy",
          conds=[{"type": "battle_running"}, {"type": "source_form", "form": "demon"}]),
        T("node_pianist_grief_dead", "OnEnemyUnitDied", ["enemy_unit_died", "passive_grief_dead"], mode="flat_times_ability_power_pct",
          flat=PIA_DOT["1"], flat_star=PIA_DOT, rule="all_enemies", team="enemy", conds=[{"type": "source_form", "form": "demon"}]),
        # 被动 2(天) 热情：开局 + 每 3 秒 1 层，队友阵亡 2 层
        T("node_pianist_passion", "OnBattleStart", ["battle_start", "passive_passion"], mode="flat_times_ability_power_pct", flat=PIA_HOT["1"],
          flat_star=PIA_HOT, rule="all_allies", team="ally", conds=[{"type": "source_form", "form": "angel"}]),
        T("node_pianist_passion_tick", "OnBattleFrame", ["battle_frame", "passive_passion"], count=PIA_EVERY, mode="flat_times_ability_power_pct",
          flat=PIA_HOT["1"], flat_star=PIA_HOT, rule="all_allies", team="ally",
          conds=[{"type": "battle_running"}, {"type": "source_form", "form": "angel"}]),
        T("node_pianist_passion_dead", "OnAllyUnitDied", ["ally_unit_died", "passive_passion_dead"], mode="flat_times_ability_power_pct",
          flat=PIA_HOT["1"], flat_star=PIA_HOT, rule="all_allies", team="ally", conds=[{"type": "source_form", "form": "angel"}]),
        # 触发器 下一乐章：想加层但已经叠满
        T("node_pianist_next", "OnStackCapped", ["stack_capped", "equipment_payload"], mode="flat_times_ability_power_pct", flat=PIA_Z["1"],
          flat_star=PIA_Z, rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_pianist_form", "blade", "pianist_form", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_form"],
          cfg={"forms": {"demon": {"status_id": "form_demon", "duration": 0.0, "flags": ["buff", "no_dispel", "form_demon"],
                                   "stats_by_star": {"damage_dealt_pct": {"flat": PIA_DMG}}},
                         "angel": {"status_id": "form_angel", "duration": 0.0, "flags": ["buff", "no_dispel", "form_angel"],
                                   "stats_by_star": {"healing_done_pct": {"flat": PIA_HEAL}}}}}),
        A("node_pianist_rebirth", "blade", "pianist_flip", keywords=["basic"], timings=["OnBeforeDeath"], tags=["passive_rebirth"]),
        A("node_pianist_grief", "blade", "mood_stack", keywords=["stacking"], kv={"stacking": PIA_STACK}, timings=["OnBattleStart", "OnBattleFrame"],
          tags=["passive_grief"], cfg={"status": _DESPAIR, "value_to": "dot", "add_stacks": 1, "card_form": "demon", "all_targets": True}),
        A("node_pianist_grief_dead", "blade", "mood_stack", keywords=["stacking"], kv={"stacking": PIA_STACK}, timings=["OnEnemyUnitDied"],
          tags=["passive_grief_dead"], cfg={"status": _DESPAIR, "value_to": "dot", "add_stacks": 2, "all_targets": True}),
        A("node_pianist_passion", "blade", "mood_stack", keywords=["stacking"], kv={"stacking": PIA_STACK}, timings=["OnBattleStart", "OnBattleFrame"],
          tags=["passive_passion"], cfg={"status": _ELATION, "value_to": "hot", "add_stacks": 1, "card_form": "angel", "all_targets": True}),
        A("node_pianist_passion_dead", "blade", "mood_stack", keywords=["stacking"], kv={"stacking": PIA_STACK}, timings=["OnAllyUnitDied"],
          tags=["passive_passion_dead"], cfg={"status": _ELATION, "value_to": "hot", "add_stacks": 2, "all_targets": True}),
    ],
})

units.append({
    "id": "node_vine", "cost": 2, "role": "tank", **W("sword", ["sword", "heavy", "polearm"], "shield"), "faction_id": "green", "profession_id": "maintenance",
    "target_priority": "nearest", "radius": 0.5,
    "base_stats": S(attack_power=60, defense=55, magic_resistance=45, max_health=1600, health_regen_per_second=6,
                    move_speed=1.9, attack_speed_multiplier=0.7),
    "triggers": [
        T("node_vine_thorns", HIT, ["normal_attack", "passive_thorns"], count=3, flat_star={"1": 40, "2": 70, "3": 110},
          rule="event_target", team="enemy"),
        T("node_vine_sap", "OnBattleFrame", ["battle_frame", "equipment_payload"], count=12, mode="max_health_ratio", ratio=0.05,
          rule="self", team="ally"),
    ],
    "passive_abilities": [
        A("node_vine_thorns_ability", "blade", "magic_damage", keywords=["basic", "crit"], timings=[HIT], tags=["passive_thorns"]),
    ],
})

# 黄 · 情报 · 2费 · 射手 —— 悬赏节点(击杀得金币；黄色单位两个生效槽)
units.append({
    "id": "node_bounty", "cost": 2, "role": "archer", **W("pistols", ["pistols", "crossbow", "rifle"]), "faction_id": "yellow", "profession_id": "information",
    "target_priority": "range_lowest_health_else_nearest_tank_first", "radius": 0.42,
    "base_stats": S(attack_power=96, magic_resistance=15, max_health=380, move_speed=1.5),
    "triggers": [
        T("node_bounty_payout", "OnUnitKilled", ["unit_killed", "passive_gold"], rule="self", team="ally"),
        T("node_bounty_every_fourth", NA, ["normal_attack", "equipment_payload"], count=4, flat_star={"1": 12, "2": 20, "3": 30}),
    ],
    "passive_abilities": [
        A("node_bounty_gold", "bullet", "grant_gold", fixed=1.0, keywords=["basic"], timings=["OnUnitKilled"], tags=["passive_gold"]),
    ],
})

# —— 验收样例单位(源项目 sample_archer / sample_darkknight)：不入卡池，只用于验收与教学
units.append({
    "id": "sample_archer", "cost": 1, "role": "archer", **W("bow", []), "faction_id": "white", "profession_id": "engineering",
    "target_priority": "nearest", "available_in_shop": False,
    "base_stats": S(attack_power=100, defense=10, magic_resistance=20, max_health=900, crit_chance=0.0),
    "triggers": [
        T("sample_archer_every_fourth", NA, ["normal_attack", "passive_pursuit"], count=4),
        T("sample_archer_every_sixth", NA, ["normal_attack", "equipment_payload"], count=6, mode="attack_ratio", ratio=1.0),
    ],
    "passive_abilities": [
        A("sample_archer_pursuit", "blade", "none", keywords=["basic", "pursuit"], kv={"pursuit": 1}, timings=[NA], tags=["passive_pursuit"]),
    ],
})
units.append({
    "id": "sample_darkknight", "cost": 2, "role": "warrior", **W("sword", []), "faction_id": "white", "profession_id": "security",
    "target_priority": "nearest", "available_in_shop": False,
    "base_stats": S(attack_power=60, defense=100, magic_resistance=40, max_health=1000, crit_chance=0.0),
    "triggers": [
        T("sample_darkknight_sixth_heal", HIT, ["normal_attack", "passive_heal"], count=6, flat=50, rule="self", team="any"),
        T("sample_darkknight_second_defense", HIT, ["normal_attack", "passive_defense"], count=2, flat=10, rule="self", team="any"),
        T("sample_darkknight_third_hit", HIT, ["normal_attack", "equipment_payload"], count=3, mode="defense_ratio", ratio=0.5,
          rule="self", team="any"),
    ],
    "passive_abilities": [
        A("sample_darkknight_heal", "blade", "heal", keywords=["basic"], timings=[HIT], tags=["passive_heal"]),
        A("sample_darkknight_stacking_defense", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3},
          timings=[HIT], tags=["passive_defense"], cfg={"status_id": "sample_darkknight_defense", "stat_id": "defense"}),
    ],
})

# =====================================================================  遭遇里的小怪(不是"节点"，不入卡池)
# 第零章·白之章：白色宗教遗迹里的守卫。暂时沿用节点的体素模型(白色涂装)。
units.append({
    "id": "mob_sentinel", "cost": 1, "role": "tank", **W("sword", ["sword"], "shield"), "faction_id": "white", "profession_id": "",
    "target_priority": "nearest", "radius": 0.44, "available_in_shop": False,
    "base_stats": S(attack_power=36, defense=18, magic_resistance=10, max_health=520, move_speed=1.8, attack_speed_multiplier=0.8),
    "triggers": [T("mob_sentinel_guard", HIT, ["normal_attack", "passive_guard"], count=3, flat=6, rule="self", team="any")],
    "passive_abilities": [
        A("mob_sentinel_guard_up", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3},
          timings=[HIT], tags=["passive_guard"], cfg={"status_id": "mob_sentinel_guard", "stat_id": "defense"}),
    ],
})
units.append({
    "id": "mob_archer", "cost": 1, "role": "archer", **W("bow", ["bow"]), "faction_id": "white", "profession_id": "",
    "target_priority": "nearest", "radius": 0.42, "available_in_shop": False,
    "base_stats": S(attack_power=40, magic_resistance=5, max_health=300, move_speed=1.6),
    "triggers": [T("mob_archer_volley", NA, ["normal_attack", "passive_volley"], count=5)],
    "passive_abilities": [
        A("mob_archer_volley_pursuit", "blade", "none", keywords=["basic", "pursuit"], kv={"pursuit": 1}, timings=[NA], tags=["passive_volley"]),
    ],
})
units.append({
    "id": "mob_acolyte", "cost": 1, "role": "caster", **W("focus"), "faction_id": "white", "profession_id": "",
    "target_priority": "nearest", "radius": 0.4, "available_in_shop": False,
    "base_stats": S(attack_power=32, ability_power=10, magic_resistance=15, max_health=330, move_speed=1.4),
    "triggers": [T("mob_acolyte_prayer", "OnBattleFrame", ["battle_frame", "passive_prayer"], count=16, flat=45,
                   rule="all_allies", team="ally", sort="health_ratio_asc")],
    "passive_abilities": [
        A("mob_acolyte_prayer_heal", "blade", "heal", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_prayer"]),
    ],
})
units.append({
    "id": "mob_guardian", "cost": 2, "role": "warrior", **W("heavy"), "faction_id": "white", "profession_id": "",
    "target_priority": "nearest", "radius": 0.5, "scale": 1.2, "available_in_shop": False,
    "base_stats": S(attack_power=52, defense=28, magic_resistance=25, max_health=1250, move_speed=1.7, attack_speed_multiplier=0.8),
    "triggers": [T("mob_guardian_ward", HIT, ["normal_attack", "passive_ward"], count=4, mode="max_health_ratio", ratio=0.05,
                   rule="self", team="any")],
    "passive_abilities": [
        A("mob_guardian_ward_shield", "blade", "shield", keywords=["basic"], timings=[HIT], tags=["passive_ward"]),
    ],
})


# 第一章·红之章：大罪的余烬(普通怪物)。怪物不分费用，按"战斗强度"配怪(author_chapters.py)。
# 【燃烧】(和地形上的是同一个状态)：负面状态，可驱散，每次施加独立计时(可以同时有好几个)，每秒造成 BURN_DPS 点法术伤害。
BURN_DPS = 25.0


def BURN(dur, **kw):
    d = {"status_id": "burning", "duration": float(dur), "max_stacks": 1, "independent": True, "flags": ["debuff", "burning", "dispellable"],
         "dot": {"kind": "magic", "amount": BURN_DPS, "interval": 1.0}}
    d.update(kw)
    return d


MOB_BURN = BURN(4.0)                # 精英 / 首领(占位)用
WRATH_X = {"1": 1.2, "2": 1.6, "3": 2.2}        # 愤怒·解放：引爆 = 剩余持续伤害 × x
SLOTH_Y = {"1": 0.12, "2": 0.15, "3": 0.20}     # 怠惰·预热：每层攻速 +y(在 -60% 的基础上加)
GLUT_Z = 0.05                                   # 暴食·赤油：自身最大生命的 z
EMBER_BODY = {"faction_id": "white", "profession_id": "", "available_in_shop": False, "hide_weapon": True}

# 愤怒的余烬(法师型)：每 3 秒给一个还没在烧的敌人点上 7 秒的燃烧；2 星起每 5 秒引爆一个在烧的敌人
units.append({
    "id": "mob_ember_wrath", "cost": 1, "role": "caster", **W("focus", ["focus"]), **EMBER_BODY, "model": "ember_wrath",
    "target_priority": "nearest", "radius": 0.46, "scale": 1.12, "projectile": "ember",
    # 专属动作(tools/anim_chars.gd)：弓背喘粗气的待机、笨重冲锋、抡火过头顶砸出火球(男性模型播 idle / run 的 *_m)
    "anim_overrides": {"focus": {"idle": "idle_wrath", "run": "run_wrath", "attack": "attack_wrath"}},
    "base_stats": S(attack_power=50, defense=15, magic_resistance=30, max_health=880, move_speed=1.4),
    "triggers": [
        T("mob_ember_wrath_spread", "OnBattleFrame", ["battle_frame", "passive_wrath_spread"], count=12, rule="all_enemies", sort="random",
          conds=[{"type": "has_enemies"}]) | {"target_filter": {"missing_status": "burning"}},
        T("mob_ember_wrath_release", "OnBattleFrame", ["battle_frame", "passive_wrath_release"], count=20, flat_star=WRATH_X, rule="all_enemies",
          sort="status_remaining_desc:burning", conds=[{"type": "has_enemies"}], unlock=2) | {"target_filter": {"has_status": "burning"}},
    ],
    "passive_abilities": [
        A("mob_ember_wrath_spread", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_wrath_spread"], cfg=BURN(7.0)),
        A("mob_ember_wrath_release", "blade", "status_detonate", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_wrath_release"],
          cfg={"status_id": "burning", "damage_kind": "magic"}, unlock=2),
    ],
})
# 怠惰的余烬(射手型)：攻速 -60% 起步，每次普攻叠一层预热(【叠加 8】)；2 星起普攻挑燃烧最多 / 刚好够叠满的敌人，吞掉它身上全部燃烧换预热
PREHEAT = {"status_id": "sloth_preheat", "duration": 0.0, "flags": ["buff", "dispellable"],
           "stats_by_star": {"attack_speed_multiplier": {"flat": SLOTH_Y}}}
units.append({
    "id": "mob_ember_sloth", "cost": 1, "role": "archer", **W("crossbow", ["crossbow"]), **EMBER_BODY, "model": "ember_sloth",
    "target_priority": "nearest", "radius": 0.5, "scale": 1.15, "projectile": "ember",
    # 专属动作：打瞌睡的待机、沉重跺步、把炮臂拽起来开炮(后坐)
    "anim_overrides": {"crossbow": {"idle": "idle_sloth", "run": "run_sloth", "attack": "attack_sloth"}},
    "base_stats": S(attack_power=88, defense=22, magic_resistance=20, max_health=880, move_speed=1.2, attack_speed_multiplier=0.4),
    "triggers": [
        T("mob_ember_sloth_warmup", "OnNormalAttackPerform", ["normal_attack_perform", "passive_sloth_warmup"], rule="self", team="any"),
        T("mob_ember_sloth_ignite", NA, ["normal_attack", "passive_sloth_ignite"], rule="event_target",
          conds=[{"type": "source_status_below_cap", "status_id": "sloth_preheat"}, {"type": "event_target_has_status", "status_id": "burning"}], unlock=2),
    ],
    "passive_abilities": [
        A("mob_ember_sloth_warmup", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 8}, timings=["OnNormalAttackPerform"],
          tags=["passive_sloth_warmup"], cfg=dict(PREHEAT)),
        A("mob_ember_sloth_ignite", "blade", "consume_status", keywords=["basic", "stacking"], kv={"stacking": 8}, timings=[NA], tags=["passive_sloth_ignite"],
          cfg={"status_id": "burning", "gain": dict(PREHEAT), "na_target_fit": {"status": "burning", "gauge": "sloth_preheat", "cap": 8}}, unlock=2),
    ],
})
# 色欲的余烬(战士型)：普攻命中就和目标互相缠住(定身、强制以彼此为目标、不可驱散)，缠在一起的双方每秒各被点上 2 秒的燃烧；
# 2 星起自己受到的燃烧伤害改为回复 2 倍的生命
units.append({
    "id": "mob_ember_lust", "cost": 1, "role": "warrior", **W("sword", ["sword"]), **EMBER_BODY, "model": "ember_lust",
    "target_priority": "nearest", "radius": 0.5, "scale": 1.1,
    "anim_overrides": {"sword": {"idle": "idle_lust", "run": "run_lust", "attack": "attack_lust"}},
    "base_stats": S(attack_power=66, defense=28, magic_resistance=28, max_health=1250, move_speed=2.0),
    "triggers": [
        T("mob_ember_lust_heat", NA, ["normal_attack", "passive_lust_heat"], rule="event_target"),
        T("mob_ember_lust_burn", "OnBattleFrame", ["battle_frame", "passive_lust_burn"], count=4, rule="entangled_with_self", team="any"),
        T("mob_ember_lust_regrowth", "OnBattleStart", ["battle_start", "passive_lust_regrowth"], rule="self", team="any", unlock=2),
    ],
    "passive_abilities": [
        A("mob_ember_lust_heat", "blade", "entangle", keywords=["basic"], timings=[NA], tags=["passive_lust_heat"],
          cfg={"status_id": "lust_bind", "flags": ["rooted", "no_dispel"]}),
        A("mob_ember_lust_burn", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"],
          tags=["passive_lust_burn"], cfg=BURN(2.0, all_targets=True)),
        A("mob_ember_lust_regrowth", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_lust_regrowth"],
          cfg={"status_id": "lust_regrowth", "duration": 0.0, "flags": ["buff", "no_dispel"], "stat_id": "burn_to_heal", "flat": 2.0}, unlock=2),
    ],
})
# 暴食的余烬(坦克型)：每被普攻 3 次，喷出赤油——对自己造成最大生命 z 的法术伤害(【溅射 3】：周围不分敌我受一半)并让溅到的所有人燃烧 8 秒；
# 2 星起血量低于 33% 时【吟唱 2】，然后每秒对自己喷一次赤油，直到倒下
OIL_TIMINGS = [HIT, "OnBattleFrame"]
units.append({
    "id": "mob_ember_glut", "cost": 1, "role": "tank", **W("sword", ["sword"]), **EMBER_BODY, "model": "ember_glut",
    "target_priority": "nearest", "radius": 0.62, "scale": 1.2,
    "anim_overrides": {"sword": {"idle": "idle_glut", "run": "run_glut", "attack": "attack_glut"}},
    "base_stats": S(attack_power=55, defense=48, magic_resistance=48, max_health=2000, move_speed=1.5, attack_speed_multiplier=0.75),
    "triggers": [
        T("mob_ember_glut_oil", HIT, ["normal_attack", "passive_glut_oil"], count=3, mode="max_health_ratio", ratio=GLUT_Z, rule="self", team="any"),
        T("mob_ember_glut_collapse", "OnDamageTaken", ["damage_taken", "passive_glut_collapse"], rule="self", team="any", max_acts=1,
          conds=[{"type": "source_health_below_or_equal_ratio", "ratio": 0.33}], unlock=2),
        T("mob_ember_glut_melt", "OnBattleFrame", ["battle_frame", "passive_glut_oil"], count=4, mode="max_health_ratio", ratio=GLUT_Z, rule="self", team="any",
          conds=[{"type": "source_has_status", "status_id": "glut_meltdown"}], unlock=2),
    ],
    "passive_abilities": [
        A("mob_ember_glut_oil", "blade", "magic_damage", keywords=["basic", "splash"], kv={"splash": 3}, timings=OIL_TIMINGS, tags=["passive_glut_oil"]),
        A("mob_ember_glut_oil_burn", "blade", "stat_status", keywords=["basic", "splash"], kv={"splash": 3}, timings=OIL_TIMINGS, tags=["passive_glut_oil"],
          cfg=BURN(8.0)),
        A("mob_ember_glut_collapse", "blade", "stat_status", keywords=["basic", "chant"], kv={"chant": 2}, timings=["OnDamageTaken"], tags=["passive_glut_collapse"],
          cfg={"status_id": "glut_meltdown", "duration": 0.0, "flags": ["no_dispel"], "stat_id": "move_speed", "flat": 0.0}, unlock=2),
    ],
})
# ---------------------------------------------------------------- 第一章·红之章的精英：虚荣的余烬
# 战士型。体型是普通单位的 4 倍(直径 2 倍：radius 0.5 × scale 2)。
# 被动 1 虚荣的日冕【叠加 3】：开战获得 3 层【虚荣】(层数只标记驱散进度，效果不随层数叠加；可驱散，每次最多驱散 1 层；持续 20 秒)：
#   体型翻倍(面积 ×2 = 直径 ×√2)，最大生命 / 攻击 / 防御 / 魔抗翻倍，受到伤害 -50%，造成伤害 +100%，
#   普攻变成龙息：一条宽 2 米、长 VANITY_BREATH_LEN 米(从中心算)的射线，压到的敌人都吃普攻伤害，方向按"压到最多敌人"自动选；射程 +VANITY_REACH。
# 被动 2 煌然：普攻(爪击 / 龙息)给打到的每个敌人施加 1 次【燃烧】，持续 VANITY_X 秒；带着虚荣时改为 3 次。
VANITY_X = {"1": 1.0, "2": 1.5, "3": 2.0}
VANITY_BREATH_LEN = 5.0
VANITY_REACH = 2.0                                # 攻击范围 +2 点(= +2.8 米)：龙息够得着远一点的敌人
VANITY = {"status_id": "elite_vanity", "duration": 20.0, "add_stacks": 3, "stack_effect": False,
          "flags": ["buff", "dispellable", "dispel_one", "na_breath"], "size": 1.4142,
          "breath": {"width": 2.0, "length": VANITY_BREATH_LEN},
          "stats": {"max_health": {"pct": 1.0}, "attack_power": {"pct": 1.0}, "defense": {"pct": 1.0}, "magic_resistance": {"pct": 1.0},
                    "damage_taken_pct": {"flat": 0.5}, "damage_dealt_pct": {"flat": 1.0}, "attack_range": {"flat": VANITY_REACH}}}
units.append({
    "id": "elite_ember_vanity", "cost": 3, "role": "warrior", **W("sword", ["sword"]), **EMBER_BODY, "model": "ember_vanity",
    "target_priority": "nearest", "radius": 0.5, "scale": 2.0,
    "anim_overrides": {"sword": {"idle": "idle_vanity", "run": "run_vanity", "attack": "attack_vanity", "attack_breath": "breath_vanity"}},
    "base_stats": S(attack_power=18, defense=25, magic_resistance=25, max_health=1300, move_speed=1.5, attack_speed_multiplier=0.25),
    "triggers": [
        T("elite_vanity_corona", "OnBattleStart", ["battle_start", "passive_vanity_corona"], rule="self", team="any"),
        T("elite_vanity_blaze", "OnNormalAttackPerform", ["normal_attack_perform", "passive_vanity_blaze"], rule="weapon_attack",
          conds=[{"type": "source_missing_status", "status_id": "elite_vanity"}]),
        T("elite_vanity_blaze3", "OnNormalAttackPerform", ["normal_attack_perform", "passive_vanity_blaze3"], rule="weapon_attack",
          conds=[{"type": "source_has_status", "status_id": "elite_vanity"}]),
    ],
    "passive_abilities": [
        A("elite_vanity_corona", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 3}, timings=["OnBattleStart"],
          tags=["passive_vanity_corona"], cfg=dict(VANITY)),
        A("elite_vanity_blaze", "blade", "stat_status", keywords=["basic"], timings=["OnNormalAttackPerform"], tags=["passive_vanity_blaze"],
          cfg=BURN(3.0, duration_by_star=VANITY_X)),
        A("elite_vanity_blaze3", "blade", "stat_status", keywords=["basic"], timings=["OnNormalAttackPerform"], tags=["passive_vanity_blaze3"],
          cfg=BURN(3.0, duration_by_star=VANITY_X, repeat=3)),
    ],
})
# ---------------------------------------------------------------- 红之章·新的余烬(2026-10-04)
# 嫉妒的余烬(射手型小怪)：一只拖着触须、浮在半空的熔岩眼球。普攻是一道一直维持着的射线(法器，但没有弹道、不溅射：每 0.5 秒结算一次)，
#   总是索敌我方本场造成伤害最多的单位(target_priority top_damage)；
# 嫉妒的凝视：每命中 3 次，使目标【燃烧】2 秒(射线一直照着 = 身上一直有 1~2 个燃烧)
# 妒恨(2 星)：每次命中给目标叠 1 层【妒恨】(每层造成的伤害 -ENVY_SPITE，最多 6 层，3 秒，可驱散)
ENVY_SPITE = 0.03
units.append({
    "id": "mob_ember_envy", "cost": 1, "role": "archer", **W("focus", ["focus"]), **EMBER_BODY, "model": "ember_envy",
    "target_priority": "top_damage", "radius": 0.42, "scale": 1.0, "projectile": "beam",
    "wclass_overrides": {"focus": {"projectile": "", "interval": 0.5, "windup": 0.1, "recover": 0.1, "range": 3.2, "na_mult": 0.3, "na_keywords": {}}},
    "anim_overrides": {"focus": {"idle": "idle_envy", "run": "run_envy", "attack": "attack_envy"}},
    "base_stats": S(attack_power=40, defense=12, magic_resistance=25, max_health=680, move_speed=1.5),
    "triggers": [
        T("mob_ember_envy_gaze", NA, ["normal_attack", "passive_envy_gaze"], count=3, rule="event_target"),
        T("mob_ember_envy_spite", NA, ["normal_attack", "passive_envy_spite"], rule="event_target", unlock=2),
    ],
    "passive_abilities": [
        A("mob_ember_envy_gaze", "blade", "stat_status", keywords=["basic"], timings=[NA], tags=["passive_envy_gaze"], cfg=BURN(2.0)),
        A("mob_ember_envy_spite", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": 6}, timings=[NA], tags=["passive_envy_spite"],
          cfg={"status_id": "envy_spite", "duration": 3.0, "max_stacks": 6, "flags": ["debuff", "dispellable"],
               "stats": {"damage_dealt_pct": {"flat": -ENVY_SPITE}}}, unlock=2),
    ],
})
# 贪婪的余烬(施法者型小怪)：一本摊开的黑色魔典，金色包角、紫宝石，锁链吊着紫宝石坠子，书页上烧着紫色的火。
# 贪婪的吞噬【叠加 10】：每 2 秒，吞掉周围 4.5 米内所有单位(不分敌我)身上的全部【燃烧】，每吞掉一个获得 1 层【贪婪】(可驱散)
# 金焰【溅射 2】：有贪婪时，普通攻击命中后消耗全部贪婪：对目标和它 2.4 米内的队友(= 我方)各造成 层数 × 攻击力 × GREED_X 的魔法伤害
# 挥霍(2 星)：金焰波及的每个敌人重新【燃烧】3 秒(又能被吞掉)
GREED_X = 0.45
GREED_HOARD = {"status_id": "greed_hoard", "duration": 0.0, "flags": ["buff", "dispellable"]}
GREED_SPLASH = {"splash_ratio": 1.0, "splash_filter": "target_allies", "splash_fx": "greed"}
units.append({
    "id": "mob_ember_greed", "cost": 1, "role": "caster", **W("focus", ["focus"]), **EMBER_BODY, "model": "ember_greed",
    "target_priority": "nearest", "radius": 0.44, "scale": 1.05, "projectile": "ember_violet",
    "anim_overrides": {"focus": {"idle": "idle_greed", "run": "run_greed", "attack": "attack_greed"}},
    "base_stats": S(attack_power=46, defense=15, magic_resistance=35, max_health=800, move_speed=1.3),
    "triggers": [
        T("mob_ember_greed_devour", "OnBattleFrame", ["battle_frame", "passive_greed_devour"], count=8, rule="nearby_units", team="any", radius=4.5)
        | {"target_filter": {"has_status": "burning"}},
        # 挥霍要排在金焰前面：金焰会把贪婪用掉
        T("mob_ember_greed_squander", NA, ["normal_attack", "passive_greed_squander"], rule="event_target",
          conds=[{"type": "source_has_status", "status_id": "greed_hoard"}], unlock=2),
        T("mob_ember_greed_burst", NA, ["normal_attack", "passive_greed_burst"], rule="event_target", mode="source_status_stacks_times_stat",
          ratio=GREED_X, status="greed_hoard", stat="attack_power", conds=[{"type": "source_has_status", "status_id": "greed_hoard"}]),
        T("mob_ember_greed_spend", NA, ["normal_attack", "passive_greed_spend"], rule="self", team="any",
          conds=[{"type": "source_has_status", "status_id": "greed_hoard"}]),
    ],
    "passive_abilities": [
        A("mob_ember_greed_devour", "blade", "consume_status", keywords=["basic", "stacking"], kv={"stacking": 10}, timings=["OnBattleFrame"],
          tags=["passive_greed_devour"], cfg={"status_id": "burning", "all_targets": True, "gain": dict(GREED_HOARD), "consume_fx": "greed"}),
        A("mob_ember_greed_burst", "blade", "magic_damage", keywords=["basic", "splash"], kv={"splash": 2}, timings=[NA], tags=["passive_greed_burst"],
          cfg=dict(GREED_SPLASH)),
        A("mob_ember_greed_spend", "blade", "lose_stack", keywords=["basic"], timings=[NA], tags=["passive_greed_spend"],
          cfg={"status_id": "greed_hoard", "all": True}),
        A("mob_ember_greed_squander", "blade", "stat_status", keywords=["basic", "splash"], kv={"splash": 2}, timings=[NA], tags=["passive_greed_squander"],
          cfg=BURN(3.0, **GREED_SPLASH), unlock=2),
    ],
})
# ---------------------------------------------------------------- 红之章的精英：忧郁的余烬 / 傲慢的余烬(本体占的战斗强度少，靠手下打)
# 忧郁的余烬(坦克型精英)：一只熔岩水母，暗色的伞盖顶上一圈发光的环，伞下是紫色的，垂着发光的触须。
# 忧郁之潮【溅射 2】：不会攻击。每秒嘲讽周围 2.4 米内的敌人(1.2 秒)
# 溺于悲伤：除了自己还有活着的队友时，受到的伤害 -MEL_DR
# 泪雨(2 星)：被忧郁之潮嘲讽的敌人攻击速度 -MEL_SLOW(1.5 秒)
MEL_DR = 0.5
MEL_SLOW = 0.25
units.append({
    "id": "elite_ember_melancholy", "cost": 3, "role": "tank", **W("sword", ["sword"]), **EMBER_BODY, "model": "ember_melancholy",
    "target_priority": "nearest", "radius": 0.55, "scale": 1.45,
    "anim_overrides": {"sword": {"idle": "idle_melancholy", "run": "run_melancholy", "attack": "idle_melancholy"}},
    "base_stats": S(attack_power=10, defense=40, magic_resistance=40, max_health=3600, move_speed=1.6),
    "triggers": [
        T("elite_melancholy_listless", "OnBattleStart", ["battle_start", "passive_melancholy_tide"], rule="self", team="any"),
        T("elite_melancholy_tide", "OnBattleFrame", ["battle_frame", "passive_melancholy_taunt"], count=4, rule="self", team="any"),
        T("elite_melancholy_drown", "OnBattleFrame", ["battle_frame", "passive_melancholy_drown"], count=2, rule="self", team="any",
          conds=[{"type": "has_allies"}]),
        T("elite_melancholy_rain", "OnBattleFrame", ["battle_frame", "passive_melancholy_rain"], count=4, rule="nearby_units", team="enemy",
          radius=2.4, unlock=2),
    ],
    "passive_abilities": [
        A("elite_melancholy_listless", "blade", "stat_status", keywords=["basic", "splash"], kv={"splash": 2}, timings=["OnBattleStart"],
          tags=["passive_melancholy_tide"], cfg={"status_id": "melancholy_listless", "duration": 0.0, "flags": ["no_dispel", "disarm"], "splash_is_range": True}),
        A("elite_melancholy_taunt", "blade", "aura_taunt", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_melancholy_taunt"],
          cfg={"duration": 1.2}),
        A("elite_melancholy_drown", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_melancholy_drown"],
          cfg={"status_id": "melancholy_drown", "duration": 0.6, "flags": ["buff", "no_dispel"], "stats": {"damage_taken_pct": {"flat": MEL_DR}}}),
        A("elite_melancholy_rain", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_melancholy_rain"],
          cfg={"status_id": "melancholy_gloom", "duration": 1.5, "flags": ["debuff", "dispellable"], "all_targets": True,
               "stats": {"attack_speed_multiplier": {"flat": -MEL_SLOW}}}, unlock=2),
    ],
})
# 傲慢的余烬(施法者型精英)：戴着白色面具、黑金尖冠的女王，熔岩裂纹的羽毛长裙，爪形的护手。
# 王座的召唤：开战时和之后每 8 秒，在身前召唤一只随机的余烬小怪(继承星级)；她召唤的小怪最多同时 3 只
# 傲慢敕令：每 4 秒，所有友方(不含自己)获得【傲慢的恩赐】4.5 秒：攻击力 +PRIDE_ATK、攻速 +PRIDE_AS、受到的伤害 -PRIDE_DR
# 众星拱月(2 星)：【傲慢的恩赐】期间每秒回复 3% 最大生命
PRIDE_ATK, PRIDE_AS, PRIDE_DR = 0.3, 0.3, 0.2
PRIDE_POOL = ["mob_ember_wrath", "mob_ember_sloth", "mob_ember_lust", "mob_ember_glut", "mob_ember_envy", "mob_ember_greed"]
units.append({
    "id": "elite_ember_pride", "cost": 3, "role": "caster", **W("focus", ["focus"]), **EMBER_BODY, "model": "ember_pride",
    "target_priority": "nearest", "radius": 0.45, "scale": 1.25, "projectile": "ember",
    # 专属动作：叉腰抬爪的女王待机、裙底滑行、举爪往前一指的敕令
    "anim_overrides": {"focus": {"idle": "idle_pride", "run": "run_pride", "attack": "attack_pride"}},
    "base_stats": S(attack_power=50, defense=25, magic_resistance=40, max_health=2200, move_speed=1.4),
    "triggers": [
        T("elite_pride_summon_start", "OnBattleStart", ["battle_start", "passive_pride_summon"], rule="self", team="any"),
        T("elite_pride_summon", "OnBattleFrame", ["battle_frame", "passive_pride_summon"], count=32, rule="self", team="any"),
        T("elite_pride_edict", "OnBattleFrame", ["battle_frame", "passive_pride_edict"], count=16, rule="all_allies_except_self", team="ally",
          conds=[{"type": "has_allies"}]),
    ],
    "passive_abilities": [
        A("elite_pride_summon", "blade", "summon", keywords=["basic", "summon"], timings=["OnBattleStart", "OnBattleFrame"], tags=["passive_pride_summon"],
          cfg={"unit_pool": PRIDE_POOL, "max_alive": 3, "placement": "front"}),
        A("elite_pride_edict", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_pride_edict"],
          cfg={"status_id": "pride_favor", "duration": 4.5, "flags": ["buff", "dispellable"], "all_targets": True,
               "stats": {"attack_power": {"pct": PRIDE_ATK}, "attack_speed_multiplier": {"flat": PRIDE_AS}, "damage_taken_pct": {"flat": PRIDE_DR}}}),
        A("elite_pride_grace", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_pride_edict"],
          cfg={"status_id": "pride_grace", "duration": 4.5, "flags": ["buff", "dispellable"], "all_targets": True,
               "hot": {"pct": 0.03, "interval": 0.5}}, unlock=2),
    ],
})
# ---------------------------------------------------------------- 红之章的首领：龙的余烬(人形；没有手下，纯单体战斗)
# 黑红长发、龙角、蝙蝠翼、龙尾、黑金铠甲的龙娘，双手持一柄燃烧的熔岩薙刀(长柄，weapon_look = ember_glaive)。
# 龙之余烬：她在场时——余烬地块不会熄灭(踩上去照样燃烧，一直站着每 2.5 秒再烧一次)；所有【燃烧】不再造成法术伤害，改为每秒直接移除
#   25 点生命上限(连同这部分生命：不吃魔抗 / 护盾，治疗不回来)；她自己免疫燃烧
# 燎原：每 5 秒在 3 个随机敌人脚下点燃一格余烬；每 3 秒，随机 2 块亮着的余烬各往旁边烧过去一格(亮着的余烬最多 DRAGON_CAP 格)
# 龙焰薙刀：普攻(含长柄的贯穿)打到的每个敌人【燃烧】{★3/4/5} 秒
DRAGON_CAP = 60
DRAGON_X = {"1": 3.0, "2": 4.0, "3": 5.0}
units.append({
    "id": "boss_ember_dragon", "cost": 5, "role": "warrior", **W("polearm", ["polearm"]), "faction_id": "white", "profession_id": "",
    "available_in_shop": False, "model": "ember_dragon", "weapon_look": "ember_glaive", "skin": "porcelain",
    "target_priority": "nearest", "radius": 0.5, "scale": 1.3,
    # 专属动作：低架斜举薙刀、翅膀呼吸的待机，前倾收翼冲锋，大斜斩(张翼)；attack_multi = 长柄[群攻]贯穿时的弓步突刺
    "anim_overrides": {"polearm": {"idle": "idle_dragon", "run": "run_dragon", "attack": "attack_dragon", "attack_multi": "pierce_dragon"}},
    "base_stats": S(attack_power=130, defense=55, magic_resistance=50, max_health=8000, move_speed=2.0),
    "triggers": [
        T("boss_dragon_heart", "OnBattleStart", ["battle_start", "passive_dragon_heart"], rule="self", team="any"),
        T("boss_dragon_ignite", "OnBattleFrame", ["battle_frame", "passive_dragon_ignite"], count=20, rule="all_enemies", sort="random", max_targets=3,
          conds=[{"type": "has_enemies"}]),
        T("boss_dragon_spread", "OnBattleFrame", ["battle_frame", "passive_dragon_spread"], count=12, rule="self", team="any"),
        T("boss_dragon_glaive", "OnNormalAttackPerform", ["normal_attack_perform", "passive_dragon_glaive"], rule="weapon_attack"),
    ],
    "passive_abilities": [
        A("boss_dragon_heart", "blade", "stat_status", keywords=["basic"], timings=["OnBattleStart"], tags=["passive_dragon_heart"],
          cfg={"status_id": "dragon_ember", "duration": 0.0, "flags": ["buff", "no_dispel", "ember_keeper", "burn_wither", "burn_immune"]}),
        A("boss_dragon_ignite", "blade", "ignite_embers", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_dragon_ignite"],
          cfg={"all_targets": True, "cap": DRAGON_CAP}),
        A("boss_dragon_spread", "blade", "spread_embers", keywords=["basic"], timings=["OnBattleFrame"], tags=["passive_dragon_spread"],
          cfg={"count": 2, "cap": DRAGON_CAP}),
        A("boss_dragon_glaive", "blade", "stat_status", keywords=["basic"], timings=["OnNormalAttackPerform"], tags=["passive_dragon_glaive"],
          cfg=BURN(3.0, duration_by_star=DRAGON_X)),
    ],
})
units.append({
    "id": "boss_cinder_colossus", "cost": 4, "role": "tank", **W("heavy", ["heavy"]), "faction_id": "white", "profession_id": "",
    "target_priority": "nearest", "radius": 0.6, "scale": 1.45, "available_in_shop": False,
    "base_stats": S(attack_power=120, defense=60, magic_resistance=45, max_health=5200, move_speed=1.6, attack_speed_multiplier=0.75),
    "triggers": [T("boss_cinder_colossus_quake", NA, ["normal_attack", "passive_quake"], count=5, mode="attack_ratio", ratio=1.6,
                   rule="nearby_units", team="enemy", radius=3.0)],
    "passive_abilities": [
        A("boss_cinder_colossus_quake_dmg", "blade", "magic_damage", keywords=["basic"], timings=[NA], tags=["passive_quake"], cfg={"all_targets": True}),
        A("boss_cinder_colossus_quake_burn", "blade", "stat_status", keywords=["basic"], timings=[NA], tags=["passive_quake"], cfg=BURN(4.0, all_targets=True)),
    ],
})


# =====================================================================  外观差分：发色(本色系里任选) + 肤色(GC.SKIN_TONES)
# 同色系的棋子也要一眼分得开：红系有玫红/赤铜/粉/猩红/酒红…，白系有雪白/银/铂金/灰…
# ---------------------------------------------------------------- 第一章-B·蓝之章：机械造物(2026-10-07 第一版 4 只普通怪物；命名 = 产品编号 + 功能)
# 战斗的核心原语是【增幅】：每只怪的被动都带【增幅 N】、效果随增幅缩放。被动的增幅 = 关键词数值 + 属性 passive_amplify_bonus(链路 / 力场给的)。
#   RX 增幅中继：每 4 秒给 4 米内的友军【增幅链路】(被动增幅 +N)；HV 场域载具：放出增幅力场(地形：场内所有单位的被动增幅 +N，不分敌我)；
#   SG 哨戒炮台(不会动) / AX 突击仿生人：吃增幅的输出终端。增幅的"来源"(中继 / 力场)放出去的数值用基础值(ability_keyword_base)：不被自己放大。
# 强度点数先按红之章同类估(author_chapters.py)，怪物不分费用。
DROID_BODY = {"faction_id": "white", "profession_id": "", "available_in_shop": False, "hide_weapon": True}
SG_RATIO = 0.25                                  # 火控终端：普攻命中额外造成 攻击力 × 25% × 增幅 的法术伤害
SG_AMP = {"1": 2, "2": 2, "3": 3}
RX_AMP = {"1": 2, "2": 2, "3": 3}                # 中继广播：增幅链路 = 被动增幅 +增幅(基础值)。第一版 +1 / 4 米标定出来 ≈ 0 点(没存在感)，改 +2 / 6 米
RX_LINK_DUR, RX_LINK_RADIUS = 5.0, 6.0
HV_AMP = {"1": 2, "2": 2, "3": 3}                # 增幅力场：场内增幅 +增幅(基础值)
HV_FIELD = {"kind": "amp", "radius": 2.5, "duration": 6.0}
HV_PROJECT_EVERY = 4                             # 载具每第 4 次普攻命中把力场投射到目标脚下(铺在自己脚下时没人在场里：终端都冲到前面去了)
AX_RATIO = 0.6                                   # 输出协议：每第 3 次普攻命中追加 攻击力 × 60% × 增幅 的物理伤害
AX_AMP = {"1": 1, "2": 1, "3": 2}
AMP_LINK = {"status_id": "amp_link", "duration": RX_LINK_DUR, "max_stacks": 1, "flags": ["buff", "dispellable"],
            "amount_flat_stats": {"passive_amplify_bonus": 1.0}}
units.append({
    "id": "mob_sg_sentry", "cost": 1, "role": "archer", **W("rifle", ["rifle"]), **DROID_BODY, "model": "turret_sentry",
    "target_priority": "nearest", "radius": 0.55, "scale": 1.3,
    # 固定炮台：不会移动(move_speed 0)；动作是炮塔自己的(tools/anim_chars.gd blue_table：待机扫视、开火后坐)
    "anim_overrides": {"rifle": {"idle": "idle_turret", "run": "run_turret", "attack": "attack_turret"}},
    "base_stats": S(attack_power=96, defense=12, magic_resistance=18, max_health=720, move_speed=0.0, attack_speed_multiplier=0.85),
    "triggers": [
        T("mob_sg_fire", NA, ["normal_attack", "passive_sg_fire"], mode="attack_ratio_keyword", kw="amplify", ratio=SG_RATIO, rule="event_target"),
    ],
    "passive_abilities": [
        A("mob_sg_fire", "blade", "magic_damage", keywords=["basic", "amplify"], kv={"amplify": 2}, kv_star={"amplify": SG_AMP},
          timings=[NA], tags=["passive_sg_fire"]),
    ],
})
units.append({
    "id": "mob_rx_relay", "cost": 1, "role": "caster", **W("focus", ["focus"]), **DROID_BODY, "model": "droid_relay",
    "target_priority": "nearest", "radius": 0.44, "scale": 1.1,
    "base_stats": S(attack_power=44, defense=10, magic_resistance=30, max_health=860, move_speed=1.3),
    "triggers": [
        T("mob_rx_broadcast", "OnBattleFrame", ["battle_frame", "passive_rx_broadcast"], count=16, mode="ability_keyword_base", kw="amplify",
          rule="nearby_units", team="ally", radius=RX_LINK_RADIUS, conds=[{"type": "has_enemies"}]),
    ],
    "passive_abilities": [
        A("mob_rx_broadcast", "blade", "stat_status", keywords=["basic", "amplify"], kv={"amplify": 2}, kv_star={"amplify": RX_AMP},
          timings=["OnBattleFrame"], tags=["passive_rx_broadcast"], cfg=dict(AMP_LINK)),
    ],
})
units.append({
    "id": "mob_hv_carrier", "cost": 1, "role": "tank", **W("crossbow", ["crossbow"]), **DROID_BODY, "model": "vehicle_field",
    "target_priority": "nearest", "radius": 0.62, "scale": 1.6,
    # 悬浮载具：整体挂 Hips 起伏，车顶小炮塔开火后坐
    "anim_overrides": {"crossbow": {"idle": "idle_hover", "run": "run_hover", "attack": "attack_hover"}},
    "base_stats": S(attack_power=50, defense=44, magic_resistance=36, max_health=1850, move_speed=1.1, attack_speed_multiplier=0.8),
    "triggers": [
        T("mob_hv_field_start", "OnBattleStart", ["battle_start", "passive_hv_field"], mode="ability_keyword_base", kw="amplify", rule="self", team="any"),
        T("mob_hv_project", NA, ["normal_attack", "passive_hv_field"], count=HV_PROJECT_EVERY, mode="ability_keyword_base", kw="amplify",
          rule="event_target"),
    ],
    "passive_abilities": [
        A("mob_hv_field", "blade", "create_field", keywords=["basic", "amplify"], kv={"amplify": 2}, kv_star={"amplify": HV_AMP},
          timings=["OnBattleStart", NA], tags=["passive_hv_field"], cfg=dict(HV_FIELD)),
    ],
})
units.append({
    "id": "mob_ax_assault", "cost": 1, "role": "warrior", **W("dual", ["dual"]), **DROID_BODY, "model": "droid_assault",
    "target_priority": "nearest", "radius": 0.46, "scale": 1.1,
    "base_stats": S(attack_power=70, defense=26, magic_resistance=20, max_health=1150, move_speed=2.4, attack_speed_multiplier=0.95),
    "triggers": [
        T("mob_ax_protocol", NA, ["normal_attack", "passive_ax_protocol"], count=3, mode="attack_ratio_keyword", kw="amplify", ratio=AX_RATIO, rule="event_target"),
    ],
    "passive_abilities": [
        A("mob_ax_protocol", "blade", "physical_damage", keywords=["basic", "amplify"], kv={"amplify": 1}, kv_star={"amplify": AX_AMP},
          timings=[NA], tags=["passive_ax_protocol"]),
    ],
})

LOOKS = {
    "node_archer":       ("#c43c2e", "fair"),       # 赤铜红短发(绿斗篷配暖红)
    "node_dancer":       ("#d42c4a", "peach"),      # 玫瑰红卷发，暖一点的肤色
    "node_nurse":        ("#e8607e", "porcelain"),  # 粉红长发(配粉翅膀)，白皙
    "node_berserker":    ("#e2362c", "bronze"),     # 猩红
    "node_darkknight":   ("#7c1c34", "porcelain"),  # 酒红
    "node_gladiator":    ("#b3203a", "fair"),       # 绯红双马尾(角色卡)
    "node_warrior":      ("#34313a", "tan"),        # 炭黑(护星节点改成黑色：不享受羁绊)
    "node_witch":        ("#2c3aa6", "porcelain"),  # 藏青长发(角色卡)
    "node_druid":        ("#7f93d8", "fair"),       # 蓝灰的长须(角色卡)
    "node_shielder":     ("#3f7fe0", "honey"),      # 天蓝(卡片的蓝波波头)
    "node_peasant":      ("#58a83c", "peach"),      # 草绿(角色卡的绿发)
    "node_student":      ("#3a4fbf", "fair"),       # 藏青蓝(角色卡的蓝短发)
    "node_magi":         ("#c2a3f5", "porcelain"),  # 淡紫(卡片上的淡紫双马尾)
    "node_vine":         ("#3aa864", "umber"),      # 翠绿
    "node_bounty":       ("#e2bf74", "tan"),        # 沙金(卡片的沙金高马尾)
    "sample_archer":     ("#f4f2f0", "fair"),
    "sample_darkknight": ("#b8b4b2", "fair"),
    "mob_sentinel":      ("#e6dcc6", "fair"),       # 铂金
    "mob_archer":        ("#e2dbee", "porcelain"),  # 珠光淡紫白
    "mob_acolyte":       ("#f4f2f0", "porcelain"),  # 雪白
    "mob_guardian":      ("#b8b4b2", "peach"),      # 灰
    # 第一章·红之章的占位首领：灰烬色的头发(白色系里偏暗的几档)
    "boss_cinder_colossus": ("#918a84", "umber"),
}
for u in units:
    if u["id"] in LOOKS:
        u["hair"], u["skin"] = LOOKS[u["id"]]

# 专属体素模型(tools/chars/<模型>.gd)：这批按角色卡做的模型里，已有棋子的直接换上
BODY_MODELS = {"node_berserker": "berserker", "node_darkknight": "darkknight", "node_warrior": "warrior", "node_magi": "magi",
               "node_bounty": "bounty", "node_shielder": "shielder", "node_vine": "vine"}
for u in units:
    if u["id"] in BODY_MODELS:
        u["model"] = BODY_MODELS[u["id"]]

# =====================================================================  装备(= 武器)
eqs = []


def E(id, cost, color, cls, abilities, flat=None, pct=None, model="", reworked=False, owner="", **extra):
    """model：外观(默认 ornate 华丽款；法器另有 tome 魔典款)；owner：专属武器的主人(谁都能装，图鉴里标明是谁的)"""
    d = {"id": id, "cost": cost, "color_id": color, "weapon_class": cls, "abilities": abilities,
         "flat_stat_modifiers": flat or {}, "percent_stat_modifiers": pct or {}}
    if model:
        d["model"] = model
    if reworked:
        d["reworked"] = True
    if owner:
        d["owner"] = owner
    d.update(extra)
    eqs.append(d)


def BASIC(id, cls):
    """基础武器：没有效果也没有属性，只提供本大类的射程/普攻倍率/普攻动画；外观朴素"""
    eqs.append({"id": id, "cost": 0, "color_id": "black", "weapon_class": cls, "basic": True, "model": "plain", "abilities": []})


EP = ["equipment_payload"]

# —— 基础武器(每个大类一把)
BASIC("basic_sword", "sword")          # 铁剑
BASIC("basic_polearm", "polearm")      # 木枪
BASIC("basic_heavy", "heavy")          # 铁大剑
BASIC("basic_dual", "dual")            # 铁匕首(双持)
BASIC("basic_bow", "bow")              # 木弓
BASIC("basic_crossbow", "crossbow")    # 木手弩
BASIC("basic_pistols", "pistols")      # 燧发双枪
BASIC("basic_rifle", "rifle")          # 燧发步枪
BASIC("basic_focus", "focus")          # 学徒魔典

# —— 示例武器(源项目验收样例，载荷数值必须保持)
E("sample_arcane_edge", 1, "black", "sword",
  [A("sample_arcane_edge_magic_damage", "blade", "magic_damage", mult=4.0, tags=EP)])
E("sample_splash_potion", 1, "black", "focus",
  [A("sample_splash_potion_heal", "potion", "heal", mult=0.5, keywords=["splash"], kv={"splash": 2}, tags=EP)])

# —— 固定值载荷(不吃触发数值)
E("colorless_bow", 1, "black", "bow",
  [A("colorless_bow_true", "bullet", "true_damage", fixed=30.0, tags=EP)], flat={"attack_power": 8})
E("frenzy_daggers", 1, "red", "dual",
  [A("frenzy_daggers_hit", "bullet", "physical_damage", fixed=25.0, keywords=["stacking", "crit"], kv={"stacking": 5}, tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "frenzy_haste",
                             "stats": {"attack_speed_multiplier": {"pct": 0.06}}, "duration": 5.0}]})],
  pct={"attack_speed_multiplier": 0.08})
E("root_greatsword", 1, "green", "heavy",
  [A("root_greatsword_hit", "bullet", "physical_damage", fixed=50.0, tags=EP,
     cfg={"extra_effects": [{"effect_type": "heal", "target": "self", "fixed_value": 30.0}]})],
  pct={"max_health": 0.12}, flat={"defense": 3})

# —— 放大型载荷(触发数值×倍率)
E("desperation_greatsword", 2, "red", "heavy",
  [A("desperation_greatsword_hit", "blade", "physical_damage", mult=2.0, keywords=["crit"], tags=EP,
     cfg={"scale_by_missing_health": 2.0})], pct={"attack_power": 0.15})
E("annual_ring_spear", 3, "green", "polearm",
  [A("annual_ring_spear_hit", "blade", "physical_damage", mult=1.0, keywords=["crit", "stacking", "eternal"], kv={"stacking": 5},
     tags=EP, cfg={"extra_effects": [{"effect_type": "permanent_growth", "target": "self", "apply_to": "self",
                                      "stat_id": "defense", "fixed_value": 2.0}]})],
  pct={"max_health": 0.2}, flat={"defense": 8})

# —— 法器：法术 + [学习]成长
E("ice_lance_tome", 1, "blue", "focus",
  [A("ice_lance_tome_hit", "tome", "magic_damage", mult=0.5, keywords=["splash", "learning"], kv={"splash": 1}, tags=EP,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": 0.08, "cap": 20}})], flat={"ability_power": 15}, model="tome")
E("fireball_tome", 3, "red", "focus",
  [A("fireball_tome_hit", "tome", "magic_damage", mult=3.0, keywords=["splash", "learning", "crit"], kv={"splash": 1}, tags=EP,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": 0.12, "cap": 10}})],
  flat={"ability_power": 30}, pct={"attack_power": 0.1}, model="tome")

# 黑剑(守誓节点的专属武器，2 费 · 红 · 双手重武器)：外观是他角色卡上那把血色大剑(黑刃红边、发光的血色纹路、蝠翼护手、红色尖刺柄头)。
# 效果：给触发目标【暗色誓约】，再提升触发数值 n% 的生命上限(提升的部分立刻回复)；目标是(被视为)召唤物时，再给【光色誓约】并再提升一次。
#   【暗色誓约】不可叠加、不可驱散、永久；【觉醒：击杀一个本场击杀过队友的敌人】→ 普攻间隔减半、伤害 +100%
#   【光色誓约】不可叠加、不可驱散、永久；【觉醒：承受 20 次普攻】→ 自己 / 自己的召唤者即将阵亡时，立刻回满生命(各一次)
BLACKBLADE_N = 0.5
DARK_OATH = {"status_id": "dark_oath", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
             "awaken": {"key": "dark_oath", "tasks": [{"type": "kill_ally_killer"}],
                        "stats": {"attack_speed_multiplier": {"pct": 1.0}, "damage_dealt_pct": {"flat": 1.0}}}}
_LO_AWAKE = [{"type": "source_status_awakened", "status_id": "light_oath"}]
LIGHT_OATH = {"status_id": "light_oath", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
              "awaken": {"key": "light_oath", "tasks": [{"type": "na_taken_at_least", "count": 20}]},
              "pairs": [
                  {"trigger": T("light_oath_save_self", "OnBeforeDeath", ["before_death", "status_light_oath_self"], rule="self", team="any",
                                max_acts=1, conds=_LO_AWAKE),
                   "ability": A("light_oath_save_self", "blade", "heal_to_full", keywords=["basic"], timings=["OnBeforeDeath"],
                                tags=["status_light_oath_self"])},
                  {"trigger": T("light_oath_save_summoner", "OnSummonerBeforeDeath", ["summoner_before_death", "status_light_oath_summoner"],
                                rule="event_target", team="ally", max_acts=1, conds=_LO_AWAKE),
                   "ability": A("light_oath_save_summoner", "blade", "heal_to_full", keywords=["basic"], timings=["OnSummonerBeforeDeath"],
                                tags=["status_light_oath_summoner"])}]}
E("blackblade", 2, "red", "heavy",
  [A("blackblade_oath", "blade", "oath_bestow", keywords=["basic"], tags=EP,
     cfg={"dark": DARK_OATH, "light": LIGHT_OATH, "hp_pct": BLACKBLADE_N})],
  flat={"max_health": 60, "defense": 8}, model="blood", reworked=True, owner="node_darkknight")
E("order_sword", 2, "blue", "sword",
  [A("order_sword_dual", "amulet", "shield", mult=1.5, tags=EP,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": 1.5},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": 1.0}})],
  flat={"magic_resistance": 12, "ability_power": 20})
E("energy_halberd", 3, "cyan", "polearm",
  [A("energy_halberd_dual", "amulet", "shield", mult=2.0, tags=EP,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": 2.0},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": 2.0}})],
  flat={"magic_resistance": 20}, pct={"max_health": 0.1})

# —— 浮动载荷：5% 大成功 / 5% 大失败
E("healing_orb", 2, "cyan", "focus",
  [A("healing_orb_heal", "potion", "heal", mult=1.0, tags=EP,
     cfg={"variance": {"success": 0.05, "fail": 0.05, "success_mult": 2.0, "fail_mult": 0.0}})],
  pct={"healing_done_pct": 0.2}, flat={"health_regen_per_second": 4})
E("wildfire_pistols", 3, "yellow", "pistols",
  [A("wildfire_pistols_burn", "potion", "magic_damage", mult=1.2, keywords=["splash", "stacking"], kv={"splash": 2, "stacking": 3},
     tags=EP, cfg={"variance": {"success": 0.05, "fail": 0.05, "success_mult": 2.0, "fail_mult": 0.0}})],
  pct={"attack_power": 0.2, "healing_done_pct": 0.1})

# —— 改写型载荷：先改写同一次触发里排在后面的载荷，再由武器自己的载荷打出去
E("calibration_rifle", 3, "purple", "rifle",
  [A("calibration_rifle_rewrite", "chip", "none", tags=EP, priority=10, cfg={"value_from_target_max_health_pct": 0.035}),
   A("calibration_rifle_shot", "blade", "magic_damage", mult=1.0, tags=EP)],
  flat={"magic_percent_penetration": 0.1, "attack_power": 12})
E("amplifier_crossbow", 2, "black", "crossbow",
  [A("amplifier_crossbow_rewrite", "chip", "none", tags=EP, priority=10, cfg={"value_multiplier": 1.6}),
   A("amplifier_crossbow_shot", "blade", "physical_damage", mult=0.6, keywords=["crit"], tags=EP)],
  flat={"ability_power": 10})

# —— 专属武器(特效最适合某个棋子，但谁都能装)
# 连射弩(速射节点)：步枪大类(弹量 = 标准的【叠加 5】)，黑色万用，外观 = 她角色卡上那把弩
E("rapidfire_arbalest", 1, "black", "rifle",
  [A("rapidfire_arbalest_bolt", "bullet", "physical_damage", fixed=25.0, keywords=["basic", "pursuit"], kv={"pursuit": 1}, tags=EP)],
  flat={"crit_chance": 0.05}, pct={"attack_speed_multiplier": 0.10}, model="arbalest", reworked=True, owner="node_archer")
# 丰收(耕植节点)：双手长武器，外观是她角色卡上那把钉耙；冷却 20 秒，在触发目标脚下开出稻田(地形)
E("harvest_rake", 2, "green", "polearm",
  [A("harvest_rake_paddy", "blade", "create_field", mult=0.1, tags=EP, cooldown=20.0,
     cfg={"kind": "paddy", "radius": 1.2, "duration": 8.0})],
  flat={"max_health": 100, "defense": 20}, model="rake", reworked=True, owner="node_peasant")
# 硬质手杖(和星节点)：双手长武器，外观是他角色卡上那根缠着藤蔓的木杖；治疗量加成 +30%；
# 【基本】【群攻 4】：为触发目标回复触发数值 × y 的生命，溢出的治疗转成护盾
CANE_Y = 1.0
E("sturdy_cane", 2, "black", "polearm",
  [A("sturdy_cane_mend", "blade", "heal", mult=CANE_Y, keywords=["basic", "multi_attack"], kv={"multi_attack": 4}, tags=EP,
     cfg={"overheal_to_shield": True, "shield_cap_pct": 0.15})],
  flat={"healing_done_pct": 0.30}, model="cane", reworked=True, owner="node_druid")
# 流星爆魔杖(灾星节点)：双手长武器(她当法杖用)，外观按她的配色做的长柄魔杖；法强 +120、法术固定穿透 +40；
# 冷却 8 秒【充能 2】【群攻 12】【溅射 3】：向每个触发目标召唤流星，0.7 秒后落地爆炸，造成触发数值 × y 的魔法伤害。
# 充能从 0 开始(开战第 8 秒才有第一层，配每 5 秒的触发器 → 第 10 秒第一发)
METEOR_Y = 1.85
E("meteor_staff", 4, "red", "polearm",
  [A("meteor_staff_fall", "blade", "magic_damage", mult=METEOR_Y, keywords=["charged", "multi_attack", "splash"],
     kv={"charged": 2, "multi_attack": 12, "splash": 3}, tags=EP, cooldown=8.0,
     cfg={"initial_charges": 0, "delivery": "meteor", "fall_time": 0.7, "stagger": 0.16, "stagger_span": 1.1})],
  flat={"ability_power": 120, "magic_flat_penetration": 40}, model="meteor", reworked=True, owner="node_witch")
# 舞扇(舞星节点)：双持近战，外观按她的配色做的一对折扇；攻击距离 +2、攻速 +10%，目标远时改发划弧线的魔力飞环；
# 【基本】【双模】【群攻 10】：对队友回复触发数值 × z 的生命，对敌人造成触发数值 × z 的真实伤害
FAN_Z = 1.5
E("dance_fans", 2, "red", "dual",
  [A("dance_fans_grace", "amulet", "heal", mult=FAN_Z, keywords=["basic", "multi_attack"], kv={"multi_attack": 10}, tags=EP,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": FAN_Z},
          "enemy_effect": {"effect_type": "true_damage", "value_multiplier": FAN_Z}})],
  flat={"attack_range": 2.0}, pct={"attack_speed_multiplier": 0.10}, model="fan", reworked=True, owner="node_dancer",
  ranged_projectile={"kind": "fan_ring", "speed": 11.0, "min_dist": 1.9})
# 狼双刃(狂猎节点)：双持近战，外观是他角色卡上那对锯齿刃的狼牙双刀；冷却 15 秒【暴击】【群攻 3】，
# 造成触发数值 × y 的物理伤害，触发时自己血量低于 10% 则 ×3(配"再来一次"：濒死结算时血量 ≤ 0，正好吃满)
WOLF_Y = 2.0
E("wolf_blades", 2, "red", "dual",
  [A("wolf_blades_rend", "blade", "physical_damage", mult=WOLF_Y, keywords=["crit", "multi_attack"], kv={"multi_attack": 3}, tags=EP,
     cooldown=15.0, cfg={"mult_if_source_hp_below": {"ratio": 0.1, "mult": 3.0}})],
  flat={"crit_chance": 0.10, "physical_lifesteal": 0.10}, model="wolf", reworked=True, owner="node_berserker")
# 咒语笔记(求知节点)：法器，外观是她角色卡上那本法典；冷却 3 秒(和"每 3 秒"的触发器正好对齐，不会被冷却卡掉，见 Pipeline.CD_EPS)
# 【学习】每次发动记一层；先让触发者获得一个【乱念的咒语】(每次施加相互独立，6 秒，可驱散，随机攻速/法术强度/增伤之一，强度随这次的学习计数)，再造成伤害
NOTES_Y = 1.0                                            # 伤害 = 触发数值 × y
GARBLED = [                                              # 乱念的咒语：强度 = base + per_learning × 本次发动时的学习计数
    {"tag": "attack_speed", "stat": "attack_speed_multiplier", "mode": "pct", "base": 0.0, "per_learning": 0.03},
    {"tag": "ability_power", "stat": "ability_power", "mode": "flat", "base": 0.0, "per_learning": 3.0},
    {"tag": "damage", "stat": "damage_dealt_pct", "mode": "flat", "base": 0.0, "per_learning": 0.02},
]
E("spell_notes", 1, "blue", "focus",
  [A("spell_notes_recite", "blade", "magic_damage", mult=NOTES_Y, keywords=["learning"], tags=EP, cooldown=3.0,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": 0.0},
          "pre_effects": [{"effect_type": "random_status", "status_id": "garbled_spell", "duration": 6.0, "independent": True,
                           "flags": ["buff", "dispellable"], "options": GARBLED}]})],
  flat={"ability_power": 20}, model="notes", reworked=True, owner="node_student")
# 两用电击器(架盾节点)：手枪大类，攻击范围归零(只能打贴身的敌人)，获得的护盾 +20%；外观是一把电击枪
E("dual_use_stunner", 1, "blue", "pistols",
  [A("dual_use_stunner_zap", "amulet", "shield", mult=1.2, keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=5.0,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": 1.2},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": 1.5}})],
  flat={"shield_received_pct": 0.20}, pct={"attack_range": -1.0}, model="stunner", reworked=True, owner="node_shielder")
# 爱心针剂(护理节点)：法器，外观是她角色卡上那支大针筒(粉白玻璃管、红药液、金箍、指环)；普攻发射针剂飞镖(projectile)。
# 攻击力 +m1、攻速 +m2；冷却 1.5 秒【溅射 1.5】【暴击】：对触发目标造成触发数值 × n 的物理伤害，视为普攻伤害
# (打在队友身上会被广义治疗换成治疗；溅射到敌人的那部分照常是伤害)。溅射外观 = 爱心(splash_fx)
SYRINGE_N = 1.0
SYRINGE_ATK = 15
SYRINGE_AS = 0.15
E("heart_syringe", 2, "red", "focus",
  [A("heart_syringe_dose", "blade", "physical_damage", mult=SYRINGE_N, keywords=["splash", "crit"], kv={"splash": 1.5}, tags=EP,
     cooldown=1.5, cfg={"as_normal_attack": True, "splash_fx": "heart"})],
  flat={"attack_power": SYRINGE_ATK}, pct={"attack_speed_multiplier": SYRINGE_AS}, model="syringe", reworked=True, owner="node_nurse",
  projectile="syringe_dart")

# 赤焰战旗(狩胜节点)：双手长武器，外观 = 她角色卡上那面燃烧的金狮红旗长矛；暴击率 +m1、暴击伤害 +m2；
# 冷却 5 秒【暴击】【溅射 6】：给触发目标"每 n 点触发数值 +1% 攻击力与攻速"的永久强化(重复获得时累加)；溅射出去的只有 1/4，只给触发目标的队友
BANNER_N = 1.0
BANNER_CRIT = 0.20
BANNER_CRIT_DMG = 0.40
E("flame_banner", 3, "red", "polearm",
  [A("flame_banner_rally", "blade", "stat_status", mult=0.01 / BANNER_N, keywords=["crit", "splash"], kv={"splash": 6}, tags=EP, cooldown=5.0,
     cfg={"status_id": "flame_banner", "amount_pct_stats": ["attack_power", "attack_speed_multiplier"], "accumulate": True, "flags": ["buff"],
          "splash_ratio": 0.25, "splash_filter": "target_allies", "splash_fx": "banner"})],
  flat={"crit_chance": BANNER_CRIT, "crit_damage": BANNER_CRIT_DMG}, model="banner", reworked=True, owner="node_gladiator")
# 打工小帮手(空白节点)：单手近战(扳手，握在中间)，白色(只有白色棋子能装)；没有属性；开局送一把，不进晶球 / 黑市 / 车间
# 效果：制造触发数值个白色晶球(隐藏：5% 蓝色、1% 金色、0.05% 彩色——不写进说明)
E("work_helper", 1, "white", "sword",
  [A("work_helper_orbs", "blade", "create_orbs", mult=1.0, tags=EP,
     cfg={"tier": "white", "upgrades": [["rainbow", 0.0005], ["gold", 0.01], ["blue", 0.05]]})],
  model="wrench", reworked=True, owner="node_basic", no_drop=True)
# 如律所令(清心节点)：法器，外观 = 她角色卡上手里那张黄符；治疗量 +m1、伤害增幅 +m2；
# 【基本】【叠加 3】【固定值】【双模】：给目标一层【律令】——按目标是队友还是敌人、以及它的定位，提升 / 降低最大生命、法术强度、攻击力中的一种(固定 10%/层)
EDICT_PCT = 10.0
EDICT_RULES = [
    {"team": "ally", "roles": ["tank"], "stat": "max_health", "sign": 1, "status_id": "edict_hp_up"},
    {"team": "ally", "ap_user": True, "stat": "ability_power", "sign": 1, "status_id": "edict_ap_up"},
    {"team": "ally", "stat": "attack_power", "sign": 1, "status_id": "edict_atk_up"},
    {"team": "enemy", "roles": ["tank"], "stat": "max_health", "sign": -1, "status_id": "edict_hp_down"},
    {"team": "enemy", "ap_user": True, "stat": "ability_power", "sign": -1, "status_id": "edict_ap_down"},
    {"team": "enemy", "stat": "attack_power", "sign": -1, "status_id": "edict_atk_down"},
]
E("talisman_edict", 1, "green", "focus",
  [A("talisman_edict_seal", "bullet", "edict", fixed=EDICT_PCT, keywords=["basic", "stacking"], kv={"stacking": 3}, tags=EP,
     cfg={"rules": EDICT_RULES, "duration": 7.0, "extra_rules": ["amulet"]})],
  flat={"healing_done_pct": 0.20, "damage_dealt_pct": 0.10}, model="talisman", reworked=True, owner="node_taoist")
# 转瞬即逝(浪游节点)：单手远程(他角色卡上那把左轮)，黑色万用；攻击范围减到 1 米以内(浪游节点拿着它要贴脸打，正好不会打空)，暴击伤害 +m1；
# 【基本】：给触发目标【大口径子弹】(不可叠加、不可驱散、无限持续)：接下来 6 次普攻必定暴击、基础伤害 + m × 触发数值；
# 次数用完后普攻必定不能暴击且伤害 ×after。再次获得时重置次数
REVOLVER_RANGE = -2.3                                     # 手弩 3 点 → 0.7 点 = 0.98 米
REVOLVER_CRIT_DMG = 0.25
REVOLVER_M = 1.0
REVOLVER_AFTER = 0.7
E("fleeting_revolver", 2, "black", "crossbow",
  [A("fleeting_revolver_load", "blade", "empower_shots", mult=REVOLVER_M, keywords=["basic"], tags=EP,
     cfg={"status_id": "big_caliber", "count": 6, "after_mult": REVOLVER_AFTER})],
  flat={"attack_range": REVOLVER_RANGE, "crit_damage": REVOLVER_CRIT_DMG}, model="revolver", reworked=True, owner="node_cowboy",
  projectile="bullet")
# 炽霞(炽照节点)：单手近战(他角色卡上那把太刀，配黑鞘)，3 费 · 绿；攻速 +m1(他的拔刀连斩 1 秒一轮 → 0.75 秒以内一轮，剑痕才续得上)；
# 【基本】：造成 触发数值 × n 点物理普攻伤害(视为普攻伤害)；0.1 秒内每已触发一次，n × 1.05(一次引爆 10 层剑痕 = 1、1.05、1.05² …)
GLOW_AS = 0.5
GLOW_N = 1.0
E("blazing_glow", 3, "green", "sword",
  [A("blazing_glow_cut", "blade", "physical_damage", mult=GLOW_N, keywords=["basic"], tags=EP,
     cfg={"as_normal_attack": True, "chain": {"window": 0.1, "mult": 1.05}})],
  pct={"attack_speed_multiplier": GLOW_AS}, model="katana", reworked=True, owner="node_samurai")
# 易用短弓(追猎节点)：拉弦远程(他角色卡上那把深棕色反曲短弓，金箍)，2 费 · 绿；最大生命 +m1、攻击力 +m2；
# 冷却 1 秒【充能 3】：让触发者以一发免前后摇的普攻立刻攻击触发目标；触发数值每 100 点，这一发造成原伤害的 n%
SHORTBOW_HP = 150
SHORTBOW_ATK = 20
SHORTBOW_N = 1.0
E("easy_shortbow", 2, "green", "bow",
  [A("easy_shortbow_shot", "blade", "instant_attack", mult=SHORTBOW_N, keywords=["charged"], kv={"charged": 3}, tags=EP, cooldown=1.0)],
  flat={"max_health": SHORTBOW_HP, "attack_power": SHORTBOW_ATK}, model="short", reworked=True, owner="node_hunter")
# 虹光花(巫术节点)：法器(他角色卡上那根顶着彩虹花的细杖)，4 费 · 蓝；法强 +m1，携带者被动技能【增幅】+1；
# 【基本】【固定值】【追击 2】：从 n 点 物理普攻伤害 / 法术技能伤害 / 真实持续伤害 里随机造成一种(每一下各自随机)
FLOWER_AP = 100
FLOWER_N = 5
E("rainbow_flower", 4, "blue", "focus",
  [A("rainbow_flower_spark", "bullet", "rainbow_spark", fixed=FLOWER_N, keywords=["basic", "pursuit"], kv={"pursuit": 2}, tags=EP)],
  flat={"ability_power": FLOWER_AP, "passive_amplify_bonus": 1}, model="rainbow", reworked=True, owner="node_wizard")
# 清扫节点的专属武器(红 · 双持近战 · 4 费)：被近战敌人近身(女仆护身术) → 瞬移到刚好打得到它、又不会被别的敌人缠上的地方，立刻连扔几把
BLINK_CRIT_DMG = 0.4                                      # 暴击伤害 +m1
BLINK_ATK = 30                                            # 攻击力 +m2
BLINK_N = 100                                             # 触发数值每 n 点 1 次普攻
E("blink_blade", 4, "red", "dual",
  [A("blink_blade_strike", "blade", "blink_strike", mult=1.0 / BLINK_N, keywords=["charged"], kv={"charged": 2}, tags=EP, cooldown=20.0,
     cfg={"initial_charges": 1, "gap": 0.08, "blink_fx": "clock"})],
  flat={"crit_damage": BLINK_CRIT_DMG, "attack_power": BLINK_ATK}, model="blink", reworked=True, owner="node_maid")
# 某已不知名的星星的旗帜(星旅节点)：双手长(她角色卡上那面白底蓝边、金色盾徽的旗)，4 费 · 蓝；获得护盾量 +m1、法强 +m2；
# 【基本】【群攻 99】【增幅 2】【固定值】：令触发目标流失 max(n1% × 增幅，每 100 触发数值 n2% × 增幅) 的当前生命(n1 是固定值)。
# 数值的填法(用户)：只算旗子的法强时，溅射范围里有 ≥3 个敌人 n2 那边才超过 n1：3 × 50 × 1.6 = 240 → 2.4% > 2%，2 个 → 1.6% < 2%
FLAG_SHIELD = 0.3
FLAG_AP = 60
FLAG_N1 = 2.0
FLAG_N2 = 1.0
E("forgotten_star_flag", 4, "blue", "polearm",
  [A("forgotten_star_flag_fade", "bullet", "hp_loss_pct", fixed=FLAG_N1, mult=FLAG_N2, keywords=["basic", "multi_attack", "amplify"],
     kv={"multi_attack": 99, "amplify": 2}, tags=EP)],
  flat={"shield_received_pct": FLAG_SHIELD, "ability_power": FLAG_AP}, model="starflag", reworked=True, owner="node_astronaut")
# 驱动加农(改修节点)：双手远程(他角色卡上那把紫色步枪：木托、黄铜件、钢管里一道紫光、管下挂着紫水晶)，3 费 · 紫；
# 物理伤害增幅 +m1、魔法伤害增幅 +m1；冷却 2.5 秒：让触发目标获得 3 秒【紧急维护】(可驱散、不叠加：n1 物理吸血 + n1 法术吸血；获得的瞬间回复 触发数值 × n2)
CANNON_AMP = 0.20
CANNON_LS = 0.25
CANNON_HEAL = 0.5
E("drive_cannon", 3, "purple", "rifle",
  [A("drive_cannon_maintenance", "blade", "stat_status", mult=1.0, tags=EP, cooldown=2.5,
     cfg={"status_id": "emergency_maintenance", "duration": 3.0, "max_stacks": 1, "flags": ["buff", "dispellable"],
          "stats": {"physical_lifesteal": {"flat": CANNON_LS}, "spell_lifesteal": {"flat": CANNON_LS}},
          "extra_effects": [{"effect_type": "heal", "value_multiplier": CANNON_HEAL, "target": "target"}]})],
  flat={"physical_damage_pct": CANNON_AMP, "magic_damage_pct": CANNON_AMP}, model="drive", reworked=True, owner="node_tinker")
# 幻彩镰刀(幻彩节点)：双手重(她角色卡上那把：紫色长柄、银箍、尾端挂星星坠，柄头一颗粉色星星，一弯发光的紫色月牙刃，周围漂着小方块)，3 费 · 紫；
# 攻击力 +m1、法强 +m1；冷却 2.5 秒【群攻 3】：造成 触发数值 × n 的物理伤害
SCYTHE_M = 30
SCYTHE_N = 1.0
E("prism_scythe", 3, "purple", "heavy",
  [A("prism_scythe_reap", "blade", "physical_damage", mult=SCYTHE_N, keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=2.5)],
  flat={"attack_power": SCYTHE_M, "ability_power": SCYTHE_M}, model="prism", reworked=True, owner="node_magi")
# 闪电手套(迅游节点)：双持近战(他角色卡上那副：露指手套 + 指节护板，手背一圈发光的紫色能量环，两侧伸出闪电形的小鳍)，4 费 · 紫；
# 移动速度 +m1%；冷却 2 秒：造成 触发数值 × n% 的魔法伤害，把目标往远离自己的方向击退 触发数值 × k 米(最多 3 米)
# (用户原稿两处都写 n：伤害 n% 与击退 n 的距离量纲不同，分成两个数 n / k)
GLOVE_M = 0.20
GLOVE_N = 0.8
GLOVE_KB = 0.004
E("lightning_gloves", 4, "purple", "dual",
  [A("lightning_gloves_jolt", "blade", "magic_damage", mult=GLOVE_N, keywords=["basic"], tags=EP, cooldown=2.0,
     cfg={"extra_effects": [{"effect_type": "knockback", "value_multiplier": GLOVE_KB / GLOVE_N, "target": "target", "max_dist": 3.0}]})],
  pct={"move_speed": GLOVE_M}, model="volt", reworked=True, owner="node_runner")
# 万语千言(幻形节点)：双持近战(两捆白色的书简，竹片上是看不清的文字样纹路，用绳子捆着)，3 费 · 白；携带者被动技能的【充能】+2；
# 效果：获得 触发数值 点经验和金币(配小小收获：战斗结束时还活着)
E("myriad_words", 3, "white", "dual",
  [A("myriad_words_harvest", "blade", "grant_reward", keywords=["basic"], tags=EP)],
  flat={"passive_charges_bonus": 2}, model="slips", reworked=True, owner="node_spy")
# 魔典(幻灵节点)：法器(她角色卡上那本：黑色封面、金色包角、封面一颗紫宝石，边上飘着紫色的骷髅灵火)，4 费 · 紫；
# 携带者作为召唤者时视为 +1 星(召唤物的星级 +1)；冷却 5 秒【充能 2】【召唤】：在触发目标背后召唤一只幽灵，它的首次攻击额外造成 触发数值 × n 的伤害
GRIM_N = 0.03
E("necro_grimoire", 4, "purple", "focus",
  [A("necro_grimoire_haunt", "blade", "summon_ghost_behind", mult=GRIM_N, keywords=["charged", "summon"], kv={"charged": 2}, tags=EP, cooldown=5.0,
     cfg={"unit_id": "node_ghost"})],
  flat={"summon_star_bonus": 1}, model="grimoire", reworked=True, owner="node_medium")
# 至远的弓弦(真望节点)：拉弦远程(她角色卡上那张弓，做得更繁复华丽：深色木弓臂上缠满金色卷草、弓梢金色卷涡、握把上一颗青色宝石、发光的青白色弓弦、
# 弓梢边飘着星光)，5 费 · 青；拉满弦的普攻额外选两个目标；冷却 99 秒【充能 9】【固定值】(开战满充能)：刷新触发目标"每场战斗限一次"的技能
E("farthest_string", 5, "cyan", "bow",
  [A("farthest_string_renew", "bullet", "refresh_once", keywords=["charged"], kv={"charged": 9}, tags=EP, cooldown=99.0)],
  flat={"full_draw_extra_targets": 2}, model="farthest", reworked=True, owner="node_leader")
# 无声琴(心音节点)：拉弦远程(她角色卡上那把镶满宝石的鲁特琴)，2 费 · 黄；法强 +m1；冷却 n 秒【双模】【固定值】：
# 对队友施加 n% 伤害增幅、对敌人施加 -n% 伤害减免(= 受到的伤害 +n%)，持续 n 秒；触发者在吟唱(拉弓蓄力也算)时效果翻倍。
# 任何拿拉弓远程武器的棋子都能吟唱，所以它是一把通用武器
LUTE_AP = 20
LUTE_N = 6.0
E("silent_lute", 2, "yellow", "bow",
  [A("silent_lute_score", "amulet", "stat_status", tags=EP, cooldown=LUTE_N,
     cfg={"mult_if_chanting": 2.0,
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "lute_rapture", "duration": LUTE_N, "max_stacks": 1,
                                                               "flags": ["buff", "dispellable"], "stats": {"damage_dealt_pct": {"flat": LUTE_N / 100.0}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "lute_dissonance", "duration": LUTE_N, "max_stacks": 1,
                                                                "flags": ["debuff", "dispellable"], "stats": {"damage_taken_pct": {"flat": -LUTE_N / 100.0}}}}})],
  flat={"ability_power": LUTE_AP}, model="lute", reworked=True, owner="node_bard")
# 旧香炉(调香节点)：法器(她角色卡上那只青铜香炉：镂空的盖子、两只耳、白花饰、垂着青色流苏，冒着青烟)，2 费 · 青；治疗量加成 +m1；
# 冷却 n1 秒【群攻 6】【叠加 6】：每 n 点触发数值，给目标叠一层【浸染】(持续 n2 秒)
# 【浸染】：可叠加，可驱散，负面。受到普通攻击时消耗 1 层：给攻击者回复 n3 点生命(算施加者的治疗)，再对持有者造成等量的法术伤害
CENSER_HEAL = 0.15
CENSER_CD = 8.0
CENSER_PER = 150.0
CENSER_DUR = 8.0
CENSER_POP = 40.0
INFUSION = {"status_id": "infusion", "duration": CENSER_DUR, "flags": ["debuff", "dispellable"],
            "pairs": [{"trigger": T("infusion_pop", HIT, ["normal_attack", "status_infusion"], rule="event_target", team="any",
                                    conds=[{"type": "source_has_status", "status_id": "infusion"}]),
                       "ability": A("infusion_pop", "blade", "infusion_pop", keywords=["basic"], timings=[HIT], tags=["status_infusion"])}]}
E("old_censer", 2, "cyan", "focus",
  [A("old_censer_steep", "blade", "infuse", keywords=["multi_attack", "stacking"], kv={"multi_attack": 6, "stacking": 6}, tags=EP, cooldown=CENSER_CD,
     cfg={"per": CENSER_PER, "pop": CENSER_POP, "status": INFUSION})],
  flat={"healing_done_pct": CENSER_HEAL}, model="censer", reworked=True, owner="node_perfume")
# 凝血(血嗜节点)：双手重武器(用户给的图：一柄黑边暗红的结晶血刃，刃身上交错着发亮的血色纹路，下端一颗血珠)，整体做得比普通大剑大一号；4 费 · 青
# 持续伤害增幅 +m1、物理穿透 +m2；冷却 7 秒【群攻 8】【叠加 6】【吟唱 3】：吟唱结束时，对所有触发目标造成"吟唱了几秒就几下"、每下 触发数值 × n1% 的
# 法术伤害(技能伤害)，每下叠一层【崩裂】(可叠加，可驱散，负面：每层受到的每一跳持续伤害 +n2)
CLOT_DOT = 0.25
CLOT_PEN = 20
CLOT_N1 = 0.12
CLOT_N2 = 2.0
E("clotted_blood", 4, "cyan", "heavy",
  [A("clotted_blood_rupture", "blade", "blood_rupture", mult=CLOT_N1, keywords=["multi_attack", "stacking", "chant"],
     kv={"multi_attack": 8, "stacking": 6, "chant": 3}, tags=EP, cooldown=7.0,
     cfg={"chant_pct_per_second": 0.0, "crack": {"status_id": "blood_crack", "duration": 10.0, "flags": ["debuff", "dispellable"],
                                                 "stats": {"dot_taken_flat": {"flat": CLOT_N2}}}})],
  flat={"dot_damage_pct": CLOT_DOT, "physical_flat_penetration": CLOT_PEN}, model="clot", reworked=True, owner="node_vampire")
# 光之心(灭罪节点)：她角色卡上捧着的黄色水晶球；法器，3 费 · 黄。攻击力 +m1、法强 +m2；【基本】【群攻 6】：
# 触发目标的当前生命低于 n × 触发数值时斩杀之(不触发它自己的阵亡时效果：濒死 / 阵亡时机都不发)
HEART_ATK = 15
HEART_AP = 40
HEART_N = 12.0
E("light_heart", 3, "yellow", "focus",
  [A("light_heart_absolve", "blade", "absolve", keywords=["basic", "multi_attack"], kv={"multi_attack": 6}, tags=EP, cfg={"n": HEART_N})],
  flat={"attack_power": HEART_ATK, "ability_power": HEART_AP}, model="lightheart", reworked=True, owner="node_absolver")
# 黑色战场(屏息节点)：她角色卡上那把黑色狙击枪；双手远程，4 费 · 黑。弹匣是非标准的【叠加 1】(每打一枪就要换弹)，相对的普攻倍率很高
# (武器的 wclass_override 改写大类参数)；攻击距离 +99、物理穿透 +m1；【基本】【暴击】：对触发目标造成 触发数值 × n 的物理伤害
BB_MULT = 2.8                                             # 普攻倍率(步枪 1.6)
BB_PEN = 30
BB_N = 0.5
E("black_battlefield", 4, "black", "rifle",
  [A("black_battlefield_shot", "blade", "physical_damage", mult=BB_N, keywords=["basic", "crit"], tags=EP, cfg={"cast_fx": "ricochet"})],
  flat={"attack_range": 99, "physical_flat_penetration": BB_PEN}, model="sniper", reworked=True, owner="node_sniper",
  wclass_override={"na_mult": BB_MULT, "na_keywords": {"stacking": 1}})
# 黑色任务(止息节点)：她角色卡上的黑色微冲；单手远程，2 费 · 黑。法抗 +m1、护甲 +m2；冷却 2 秒【充能 3】：对目标发动一次普攻(即时普攻，原样倍率)，
# 然后携带者获得【战场感知】(可驱散、不叠加、3 秒：每 n 点触发数值 +1% 普攻闪避率，新属性 na_dodge)
BM_MR = 15
BM_DEF = 15
BM_N = 10.0
E("black_mission", 2, "black", "crossbow",
  [A("black_mission_burst", "blade", "instant_attack", keywords=["charged"], kv={"charged": 3}, tags=EP, cooldown=2.0,
     cfg={"na_scale": 1.0,
          "extra_effects": [{"target": "self", "effect_type": "stat_status", "value_multiplier": 1.0,
                             "status_id": "battle_sense", "duration": 3.0, "max_stacks": 1, "flags": ["buff", "dispellable"],
                             "amount_flat_stats": {"na_dodge": 0.01 / BM_N}}]})],
  flat={"magic_resistance": BM_MR, "defense": BM_DEF}, model="blackmission", projectile="bullet", reworked=True, owner="node_commando")
# 青影(踏影节点)：他角色卡上那把发光的青色长剑；单手近战，3 费 · 青。攻击力 +m1、法强 +m2；冷却 8 秒【充能 1】【叠加 3】(开战就有 1 层充能)：
# 获得 1 层【诛影】(可驱散、可叠加、无限：普攻伤害和技能伤害附带每层 触发数值 × n 的魔法持续伤害——状态附带的触发器 shadow_slay_rot)
CS_ATK = 20
CS_AP = 30
CS_N = 0.25
SHADOW_SLAY = {"status_id": "shadow_slay", "duration": 0.0, "flags": ["buff", "dispellable"],
               "pairs": [{"trigger": T("shadow_slay_rot", "OnDamageDealt", ["damage_dealt", "status_shadow_slay"], rule="event_target", team="enemy",
                                       conds=[{"type": "event_missing_tag", "tag": "dot_damage"}, {"type": "source_has_status", "status_id": "shadow_slay"}]),
                          "ability": A("shadow_slay_rot", "blade", "shadow_rot", keywords=["basic"], timings=["OnDamageDealt"], tags=["status_shadow_slay"],
                                       cfg={"duration": 2.0, "interval": 0.5})}]}
E("cyan_shadow", 3, "cyan", "sword",
  [A("cyan_shadow_slay", "blade", "shadow_slay", mult=CS_N, keywords=["charged", "stacking"], kv={"charged": 1, "stacking": 3}, tags=EP, cooldown=8.0,
     cfg={"status": SHADOW_SLAY})],
  flat={"attack_power": CS_ATK, "ability_power": CS_AP}, model="cyanshadow", reworked=True, owner="node_knight_errant")
# 正花(正行节点)：双手长武器(缠绕着花藤与花瓣、末端绽放着一朵百合的长枪；voxel 人物卡里没有，按描述独立建模 W_polearm_lily)，4 费 · 黄。
# 攻击速度 +m1、伤害减免 +m2；冷却 1 秒【充能 3】：对目标造成 触发数值 × n1 的魔法普攻伤害(视为普攻伤害)，然后为装备者回复 触发数值 × n2 的生命值
FLOWER_AS = 0.15
FLOWER_DR = 0.10
FLOWER_N1 = 1.5
FLOWER_N2 = 0.6
E("true_flower", 4, "yellow", "polearm",
  [A("true_flower_bloom", "blade", "magic_damage", mult=FLOWER_N1, keywords=["charged"], kv={"charged": 3}, tags=EP, cooldown=1.0,
     cfg={"as_normal_attack": True, "cast_fx": "lily_thrust",
          "extra_effects": [{"target": "self", "effect_type": "heal", "value_multiplier": FLOWER_N2 / FLOWER_N1}]})],
  pct={"attack_speed_multiplier": FLOWER_AS}, flat={"damage_taken_pct": FLOWER_DR}, model="lily", reworked=True, owner="node_noble")
# 希望(执剑节点)：单手近战(她角色卡上那把银刃、金十字、蓝宝石护手的骑士剑，W_sword_hope)，4 费 · 蓝。法术强度 +m1、最大生命 +m2；
# 冷却 9 秒【群攻 2】：为触发目标回复 n × 触发数值 的生命值；若其已阵亡，则令其以该生命值复活(cfg revive_dead；回复量照常吃治疗加成)
HOPE_AP = 30
HOPE_HP = 300
HOPE_N = 1.0
E("hope", 4, "blue", "sword",
  [A("hope_rekindle", "blade", "heal", mult=HOPE_N, keywords=["multi_attack"], kv={"multi_attack": 2}, tags=EP, cooldown=9.0, cfg={"revive_dead": True})],
  flat={"ability_power": HOPE_AP, "max_health": HOPE_HP}, model="hope", reworked=True, owner="node_brave")
# 沉沦之梦(共歌节点)：单手近战(她角色卡上那支麦克风：深棕握柄、金箍蓝宝石、银灰网罩，柄尾垂着金十字与白流苏；W_sword_mic)，4 费 · 红。攻击速度 +m1；
# 冷却 4 秒【群攻 10】【双模】：按触发目标的阵营——队友：伤害增幅效能 + 每 n 点触发数值 1%；敌人：伤害减免效能 + 每 n 点触发数值 1%
# (效能 = 那一项 × (1 + 效能)，负的也放大：敌人身上沉醉带来的负伤害减免会变得更负)；状态持续 5.5 秒(配善良地的 5 秒一次不断档)
DREAM_AS = 0.20
DREAM_N = 1.5
DREAM_DUR = 5.5
E("sinking_dream", 4, "red", "sword",
  [A("sinking_dream_echo", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": 10}, tags=EP, cooldown=4.0,
     cfg={"cast_fx": "dream_echo",
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "dream_amp", "duration": DREAM_DUR, "max_stacks": 1, "flags": ["buff", "dispellable"],
                                                              "amount_flat_stats": {"amp_efficacy": 0.01 / DREAM_N}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "dream_sink", "duration": DREAM_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
                                                               "amount_flat_stats": {"dr_efficacy": 0.01 / DREAM_N}}}})],
  pct={"attack_speed_multiplier": DREAM_AS}, model="mic", reworked=True, owner="node_pacifist")
# 飞蝶(白羽节点)：双持远程(她角色卡上那对黑白手枪：右手白、左手黑，金饰 + 握把金十字；W/L_pistols_butterfly)，3 费 · 青。攻击速度 +m1；
# 【基本】：对触发目标发动一次普通攻击(双枪的追击照常)，这次普攻至多造成触发数值的伤害(cap_by_value → dmg_cap)
BUTTERFLY_AS = 0.20
E("butterfly", 3, "cyan", "pistols",
  [A("butterfly_flutter", "blade", "instant_attack", keywords=["basic"], tags=EP, cfg={"na_scale": 1.0, "cap_by_value": True})],
  pct={"attack_speed_multiplier": BUTTERFLY_AS}, model="butterfly", reworked=True, owner="node_angel")
# 翠绿之林(守林节点)：用户写的"双持长武器"没有这个大类 → 按双手长武器(她角色卡上那根缠着藤蔓、顶端木环托着绿宝珠的长杖；W_polearm_verdant)，4 费 · 绿。
# 最大生命 +m1、法强 +m2；冷却 12 秒【充能 2】【学习】，开局拥有全部充能：获得 每 n1 点触发数值 (4 − 学习计数)% 攻击速度(永久累加，不低于 0)，
# 回复 每 n2 点触发数值 (0 + 学习计数)% 最大生命值(学习计数 = 这次发动之前的；触发数值不随学习计数变大)
VERDANT_HP = 300
VERDANT_AP = 30
VERDANT_N1 = 40.0
VERDANT_N2 = 30.0
E("verdant_grove", 4, "green", "polearm",
  [A("verdant_grove_growth", "blade", "verdant_grove", keywords=["charged", "learning"], kv={"charged": 2}, tags=EP, cooldown=12.0,
     cfg={"n1": VERDANT_N1, "n2": VERDANT_N2, "as_base": 4, "learning": {"bonus_per_learning": 0.0}})],
  flat={"max_health": VERDANT_HP, "ability_power": VERDANT_AP}, model="verdant", reworked=True, owner="node_warden")
# 电磁学导论(导向节点)：她角色卡上那本藏青封面、金色闪电纹章的法术书(W_focus_electro)，3 费 · 黄 · 法器。
# 攻击力 +m1、普攻伤害增幅 +m2；冷却 3 秒【充能 2】【学习】【群攻 3】：施加【麻痹】8 秒——不可叠加、可驱散、负面；
# 承受的伤害提升 每 n 点触发数值 (1 + 学习计数)%，普攻前摇完成时有同样的几率被打断；重复施加取较高者
EMAG_ATK = 40
EMAG_NA_AMP = 0.30
EMAG_N = 30.0
E("emag_intro", 3, "yellow", "focus",
  [A("emag_paralyze", "blade", "paralyze", keywords=["charged", "learning", "multi_attack"], kv={"charged": 2, "multi_attack": 3}, tags=EP, cooldown=3.0,
     cfg={"n": EMAG_N, "duration": 8.0, "learning": {"bonus_per_learning": 0.0}})],
  flat={"attack_power": EMAG_ATK, "na_damage_pct": EMAG_NA_AMP}, model="electro", reworked=True, owner="node_psychic")
# 大锤(圣战节点)：他角色卡上那把木柄金箍、灰石锤头刻着金色日轮十字的战锤(W_heavy_warhammer)，3 费 · 蓝 · 双手重。
# 法术强度 +m1、伤害减免 +m2%；冷却 4 秒【群攻 4】：施加【眩晕】，每 n 点触发数值持续 1 秒(精英 / 首领照通用规则减半)
HAMMER_AP = 30
HAMMER_DR = 0.10
HAMMER_N = 100.0
E("warhammer", 3, "blue", "heavy",
  [A("warhammer_stun", "blade", "stun_from_value", keywords=["multi_attack"], kv={"multi_attack": 4}, tags=EP, cooldown=4.0,
     cfg={"n": HAMMER_N})],
  flat={"ability_power": HAMMER_AP, "damage_taken_pct": HAMMER_DR}, model="warhammer", reworked=True, owner="node_paladin")
# 匕首与金币(巧运节点)：他角色卡上那把金护手的直刃匕首 + 左手里抛着的金币(W_dual_coin / L_dual_coin)，2 费 · 白 · 双持近战。
# 攻击速度 +m1；【基本】【学习】【永恒】：携带者还没有【钱袋】就施加之(从 0 枚开始)，否则金币计数 + 触发数值。学习计数跨战斗保留(记在棋子身上)。
# 【钱袋】：不可叠加、不可驱散、无限持续，记录金币数量；每 2 秒按学习计数 L 翻倍 / 清空；战斗结束时清空，获得等同计数的金币
#   概率随 L 收敛(用户 2026-10-08：不再线性、不会无限涨)：f = L / (L + 10)，翻倍 5% → 25%、清空 25% → 5% 按 f 插值(学习 10 次时各 15%)
COIN_AS = 0.15
_BAG_TICK = A("money_bag_tick", "blade", "money_bag_tick", keywords=["basic"], timings=["OnStatusPulse"], tags=["bag_tick"],
              cfg={"double_base": 5.0, "double_max": 25.0, "clear_base": 25.0, "clear_min": 5.0, "learn_half": 10.0})
_BAG_CASH = A("money_bag_cashout", "blade", "money_bag_cashout", keywords=["basic"], timings=["OnBattleEnd"], tags=["bag_cash"])
E("coin_dagger", 2, "white", "dual",
  [A("coin_purse", "blade", "money_bag", keywords=["basic", "learning", "eternal"], tags=EP,
     cfg={"learning": {"bonus_per_learning": 0.0},
          "bag": {"duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"], "pulse_interval": 2.0,
                  "pairs": [{"trigger": T("money_bag_tick", "OnStatusPulse", ["status_pulse", "bag_tick"], rule="self", team="ally",
                                          conds=[{"type": "event_metadata_equals", "key": "status_id", "value": "money_bag"}]),
                             "ability": _BAG_TICK},
                            {"trigger": T("money_bag_cashout", "OnBattleEnd", ["battle_end", "bag_cash"], rule="self", team="ally"),
                             "ability": _BAG_CASH}]}})],
  pct={"attack_speed_multiplier": COIN_AS}, model="coin", reworked=True, owner="node_rogue")
# 祝福之心(心连节点)：她角色卡上那串藏青念珠 + 镶蓝宝石的金十字(W_focus_rosary)，2 费 · 蓝 · 法器。
# 法术强度 +m1；冷却 10 秒：目标已阵亡 → 以 n × 触发数值 的生命复活(召唤物也行)，否则回复等量生命
BLESS_AP = 30
BLESS_N = 2.0
E("blessing_heart", 2, "blue", "focus",
  [A("blessing_heart_grace", "blade", "heal", keywords=["basic"], tags=EP, cooldown=10.0,
     cfg={"revive_dead": True, "revive_summons": True, "revive_mult": BLESS_N, "revive_kind": "blessing"})],
  flat={"ability_power": BLESS_AP}, model="rosary", reworked=True, owner="node_sister")
# 黑键 / 白键(变奏节点)：别人拿是一台小号钢琴(W_focus_piano，通用法器动作)；她本人拿是大三角钢琴(W_focus_grand / _grand_white，按形态；
# 天使形态名字叫白键——UnitDef.weapon_models / weapon_names)，4 费 · 青 · 法器。
# 法术强度 +m1、攻击范围 +m2；冷却 5 秒【永恒】【叠加 20】：触发目标是本场战斗没阵亡过的友军 → 立刻击杀它，并令它获得 每 n1 点触发数值 1 层【渐强】(跨战斗保留)。
# 【渐强】：可叠加、不可驱散、跨战斗持续；每层"每数秒"计时器充能速度 +n2%
BK_AP = 40
BK_RANGE = 1.0
BK_N1 = 150.0
BK_N2 = 0.03
E("black_keys", 4, "cyan", "focus",
  [A("black_keys_finale", "blade", "black_keys", keywords=["eternal", "stacking"], kv={"stacking": 20}, tags=EP, cooldown=5.0,
     cfg={"n": BK_N1, "status": {"status_id": "crescendo", "duration": 0.0, "flags": ["buff", "no_dispel", "crescendo"],
                                 "stats": {"haste": {"flat": BK_N2}}}})],
  flat={"ability_power": BK_AP, "attack_range": BK_RANGE}, model="piano", reworked=True, owner="node_pianist")
# 开与闭(锁芯节点)：她角色卡上扛着的那把金头巨钥匙(W_polearm_key)，3 费 · 绿 · 双手长。
# 最大生命 +m1、攻击速度 +m2；冷却 n1 秒【群攻 5】：把触发目标往一个点(它们的中心)大力拉拽、聚到一起，然后施加 每 n2 点触发数值 1 秒的眩晕
KEY_HP = 350.0
KEY_AS = 0.15
KEY_CD = 6.0
KEY_N = 200.0
E("open_shut_key", 3, "green", "polearm",
  [A("open_shut_key_pull", "blade", "gather_stun", keywords=["multi_attack"], kv={"multi_attack": 5}, tags=EP, cooldown=KEY_CD,
     cfg={"n": KEY_N, "gap": 0.55})],
  flat={"max_health": KEY_HP}, pct={"attack_speed_multiplier": KEY_AS}, model="key", reworked=True, owner="node_cultist")
# 杀(无我节点)：她角色卡上那把大太刀(W_heavy_odachi：收在黑漆刀鞘里；无我的那一场拔出来 W_heavy_odachi_drawn)，4 费 · 黑 · 双手重。
# 攻击力 +m1、攻击速度 +m2；【基本】【觉醒：场上仅剩一个敌人】【永恒】【学习】【固定值】【群攻 9】：触发目标是召唤物 → 移除之，否则移除其 n1% 生命上限。
# 学习计数跨战斗累计；累计达 n2 → 永久降低携带者一星(已经是一星：移除携带者，武器回到武器库)——Run.finish_battle 结算(cfg.curse_at)
KILL_ATK = 50
KILL_AS = 0.15
KILL_N1 = 0.06
KILL_N2 = 40
E("kill_blade", 4, "black", "heavy",
  [A("kill_sever", "bullet", "sever", keywords=["basic", "awakening", "eternal", "learning", "multi_attack"], kv={"multi_attack": 9}, tags=EP,
     cfg={"pct": KILL_N1, "curse_at": KILL_N2, "learning": {"bonus_per_learning": 0.0},
          "awakening_tasks": [{"type": "enemies_at_most", "count": 1}]})],
  flat={"attack_power": KILL_ATK}, pct={"attack_speed_multiplier": KILL_AS}, model="odachi", reworked=True, owner="node_killer")
# 乱数(奇兴节点)：她角色卡上那根骰子法杖(W_polearm_dice：金环托着一颗大白骰子)，3 费 · 蓝 · 双手长。
# 伤害增幅 +m1、攻击范围 +m2；冷却 4 秒【群攻 3】：每个目标掷 1d20 → 0.05 × 点数 × n × 触发数值；1~5 物理、6~15 魔法、16~20 真实；
# 已阵亡的友军 ≥ 仍存活的友军时必定掷出 20
DICE_AMP = 0.20
DICE_RANGE = 1.0
DICE_N = 3.0
E("chaos_dice", 3, "purple", "polearm",   # 跟着主人改成紫(2026-10-09)
  [A("chaos_dice_roll", "blade", "dice_damage", keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=4.0, cfg={"n": DICE_N})],
  flat={"damage_dealt_pct": DICE_AMP, "attack_range": DICE_RANGE}, model="dice", reworked=True, owner="node_arcanist")
# =====================================================================  通用武器(第三阶段第一批，2026-10-08)
# 没有主人(owner)、谁都能装、进随机来源(晶球 / 黑市 / 车间 / 事件)。每把只求"适配 2 只以上棋子"：触发器插槽差异很大，
# 能装上但用着不合手的棋子是预期内的(docs/PHASE2_AUDIT.md 第四节)。每把都有专属外观。
# 双生烛台(黑 · 法器 · 3 费 · 双模)：法术强度 +GEN_CANDLE_AP；冷却 3 秒(不带治疗量加成：和星这种治疗者吃了属性强度暴涨 +18)：
#   友方 → 回复 触发数值 × r 生命；敌方 → 造成 触发数值 × r 魔法伤害。合手(★2 实测)：和星 +18(每 3 秒给队友回血)、幻灵 +9(召唤物阵亡 → 大额伤害)；护理 / 灾星 +0
GEN_CANDLE_AP = 10
GEN_CANDLE_R = 0.4
E("twin_candelabra", 3, "black", "focus",
  [A("twin_candelabra_flame", "amulet", "heal", mult=GEN_CANDLE_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": GEN_CANDLE_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": GEN_CANDLE_R}})],
  flat={"ability_power": GEN_CANDLE_AP}, model="candelabra", reworked=True)
# 号令短剑(青 · 单手剑 · 2 费 · 固定值)：攻击力 +m、生命 +m；冷却 2 秒【群攻 3】：触发目标获得 1 层【锋芒】(8 秒，叠加 4：每层攻击力 +6%、攻速 +6%)。
#   不吃触发数值(固定值)。合手：踏影(瞬移 → 自己)、和星(每 3 秒 → 队友)、守林(变身 → 自己)、耕植；目标是敌人的会去给敌人加 buff(不合手)
GEN_RALLY_ATK = 15
GEN_RALLY_HP = 120
GEN_RALLY_PER = 0.06
E("rally_blade", 2, "cyan", "sword",
  [A("rally_blade_order", "bullet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=2.0,
     cfg={"status_id": "edge_rally", "duration": 8.0, "max_stacks": 4, "flags": ["buff", "dispellable"],
          "stats": {"attack_power": {"pct": GEN_RALLY_PER}, "attack_speed_multiplier": {"flat": GEN_RALLY_PER}}})],
  flat={"attack_power": GEN_RALLY_ATK, "max_health": GEN_RALLY_HP}, model="rally", reworked=True)
# 标定步枪(黄 · 步枪 · 2 费 · 固定值)：攻击速度 +m；冷却 1.5 秒：对触发目标造成 GEN_SPOT_DMG 物理伤害，并施加【破绽】(4 秒，受到的伤害 +15%)。
#   不吃触发数值——触发数值很小但扣得勤的插槽也好用。合手：速射(每 3 次命中)、屏息(击杀后)、止息(突进)。
#   (首版是手弩：速射 / 屏息换成手弩丢了步枪大类，强度反而 -10 / -23，所以改成步枪)
GEN_SPOT_AS = 0.15
GEN_SPOT_DMG = 120.0
GEN_SPOT_EXPOSE = 0.15
E("spotter_rifle", 2, "yellow", "rifle",
  [A("spotter_mark", "bullet", "physical_damage", fixed=GEN_SPOT_DMG, tags=EP, cooldown=1.5,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "exposed", "duration": 4.0, "max_stacks": 1,
                             "flags": ["debuff", "dispellable"], "stats": {"damage_taken_amp": {"flat": GEN_SPOT_EXPOSE}}}]})],
  pct={"attack_speed_multiplier": GEN_SPOT_AS}, model="spotter", reworked=True)
# 碎岩巨剑(蓝 · 双手剑 · 4 费 · 放大)：攻击力 +m、护甲 +m；冷却 4 秒【群攻 4】：对触发目标造成 触发数值 × r 物理伤害，
#   并施加 1 层【碎甲】(8 秒，叠加 3：每层护甲与魔抗 -12)。合手：圣战(裂地猛击打到的人)、星旅(真实形态的脉冲)——一次打一片的插槽
GEN_ROCK_ATK = 30
GEN_ROCK_AP = 30
GEN_ROCK_DEF = 15
GEN_ROCK_R = 1.5
GEN_ROCK_SHRED = 20
E("rockbreaker", 4, "blue", "heavy",
  [A("rockbreaker_crush", "blade", "physical_damage", mult=GEN_ROCK_R, keywords=["multi_attack"], kv={"multi_attack": 4}, tags=EP, cooldown=4.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "armor_crack", "duration": 8.0, "max_stacks": 3,
                             "flags": ["debuff", "dispellable"],
                             "stats": {"defense": {"flat": -GEN_ROCK_SHRED}, "magic_resistance": {"flat": -GEN_ROCK_SHRED}}}]})],
  flat={"attack_power": GEN_ROCK_ATK, "ability_power": GEN_ROCK_AP, "defense": GEN_ROCK_DEF}, model="rockbreaker", reworked=True)
# 蚀月(黑 · 单手剑 · 3 费 · 固定值 + 学习；首版是紫色双匕——双匕棋子里每次命中都打敌人的只有迅游，改成单手剑：迅游 / 无我 / 血嗜都合手；
#   按触发数值放大时，数值小的高频插槽(无我 60、血嗜)几乎没收益，改成固定值)：攻击速度 +m、暴击 +m；冷却 1 秒【学习】：对触发目标造成 GEN_MOON_DMG 魔法伤害(不吃触发数值)，
#   本场每学习一次 +8%(最多 15 次)。扣得越勤越强。合手：迅游(每次命中)、无我(每次命中)、血嗜(每 0.25 秒)
GEN_MOON_AS = 0.15
GEN_MOON_CRIT = 0.05
GEN_MOON_DMG = 50.0
GEN_MOON_R = 0.2
GEN_MOON_LEARN = 0.08
E("waning_moon", 3, "black", "sword",
  [A("waning_moon_cut", "bullet", "magic_damage", fixed=GEN_MOON_DMG, keywords=["learning"], tags=EP, cooldown=1.0,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": GEN_MOON_LEARN, "cap": 15}}),
   # 第二段：触发数值 × r(不学习)——触发数值大的插槽(迅游的飞身踢)靠这一段
   A("waning_moon_glow", "blade", "magic_damage", mult=GEN_MOON_R, tags=EP, cooldown=1.0)],
  flat={"crit_chance": GEN_MOON_CRIT}, pct={"attack_speed_multiplier": GEN_MOON_AS}, model="moon", reworked=True)
# =====================================================================  通用武器 · 第二批(2026-10-08)：召唤系 / 暴击系 / 充能系各两把
# —— 召唤系：效果作用在携带者的召唤物上(新效果 summon_aura：不管触发目标是谁，一次触发给所有活着的召唤物挂状态 / 回血)
# 牵丝提灯(蓝 · 法器 · 3 费 · 放大)：法术强度 +m；冷却 4 秒：携带者的所有召唤物获得【牵丝】(5 秒：攻击力 +x%、攻速 +x%)，并回复 触发数值 × r 生命。
#   合手：巫术(鸟使魔)、和星(召唤的战士)(首版法强 +25、牵丝 30%：巫术 +14)
GEN_LANTERN_AP = 15
GEN_LANTERN_BUFF = 0.25
GEN_LANTERN_HEAL = 0.30
E("puppet_lantern", 3, "blue", "focus",
  [A("puppet_lantern_strings", "blade", "summon_aura", tags=EP, cooldown=4.0,
     cfg={"heal_ratio": GEN_LANTERN_HEAL, "style": "strings",
          "status": {"status_id": "puppet_strings", "duration": 5.0, "max_stacks": 1, "flags": ["buff", "dispellable"],
                     "stats": {"attack_power": {"pct": GEN_LANTERN_BUFF}, "attack_speed_multiplier": {"flat": GEN_LANTERN_BUFF}}}})],
  flat={"ability_power": GEN_LANTERN_AP}, model="lantern", reworked=True, fit_add=["node_wizard"])
# 殉魂幡(青 · 法器 · 3 费 · 固定值；手持的短柄招魂幡)：生命 +m、法术强度 +m；冷却 2 秒：携带者的所有召唤物获得【殉魂】(无限持续、不可驱散：生命 +30%)：
#   它阵亡时，对 2 米内的敌人造成 它的最大生命 × r 的魔法伤害(状态自带的触发器：OnUnitDied，按阵亡的召唤物算)。
#   合手：巫术 / 灾星(都是蓝：青色能装)。(首版是长柄的矛：只有和星拿矛不吃亏，+4；巫术换大类 -20)
GEN_REQUIEM_HP = 150
GEN_REQUIEM_AP = 20
GEN_REQUIEM_R = 0.5
GEN_REQUIEM_HPPCT = 0.30
E("requiem_banner", 3, "cyan", "focus",
  [A("requiem_banner_toll", "bullet", "summon_aura", tags=EP, cooldown=2.0,
     cfg={"style": "requiem",
          "status": {"status_id": "requiem_soul", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
                     "stats": {"max_health": {"pct": GEN_REQUIEM_HPPCT}},
                     "pairs": [{"trigger": T("requiem_burst", "OnUnitDied", ["unit_died", "requiem_burst"], mode="max_health_ratio", ratio=GEN_REQUIEM_R,
                                             rule="nearby_units", team="enemy", radius=2.0),
                                "ability": A("requiem_burst", "blade", "magic_damage", keywords=["basic"], timings=["OnUnitDied"], tags=["requiem_burst"],
                                             cfg={"all_targets": True, "damage_category": "skill"})}]}})],
  flat={"max_health": GEN_REQUIEM_HP, "ability_power": GEN_REQUIEM_AP}, model="requiem", reworked=True, fit_add=["node_wizard"])
# —— 暴击系
# 猩红獠牙(紫 · 双匕 · 3 费 · 放大【暴击】)：暴击率 +m、暴击伤害 +m；冷却 1.5 秒【暴击】：对触发目标造成 触发数值 × r 物理伤害(可以暴击)。
#   合手：迅游(每次命中)、清扫(暴击率 100%：每一下都暴击)、狂猎
GEN_FANG_CRIT = 0.15
GEN_FANG_CDMG = 0.30
GEN_FANG_R = 0.7
E("crimson_fang", 3, "purple", "dual",
  [A("crimson_fang_rend", "blade", "physical_damage", mult=GEN_FANG_R, keywords=["crit"], tags=EP, cooldown=1.5)],
  flat={"crit_chance": GEN_FANG_CRIT, "crit_damage": GEN_FANG_CDMG}, model="fang", reworked=True)
# 锐眼步枪(黑 · 步枪 · 3 费 · 双模；屏息是黄、改修是紫，只有黑色两个都能装)：暴击率 +m、暴击伤害 +m、暴击率溢出转暴击伤害(+1 倍)；冷却 3 秒【双模】：
#   友方 → 【锐眼】(5 秒：暴击率 +x%、暴击伤害 +y%)；敌方 → 触发数值 × r 物理伤害【暴击】。
#   合手：屏息(一石二鸟：击杀 → 最近的敌人，触发数值 = 溢出伤害；集中呼吸本来就溢出转暴伤)、改修(应急道具 → 自己；暴击率叠层，只能拿步枪)。
#   (首版黄色左轮：清扫 / 浪游都 +0；第二版长枪：狩胜 +0 / 和星 +4——暴击系的步枪手才是一路的)
GEN_KEEN_CRIT = 0.15
GEN_KEEN_CDMG = 0.25
GEN_KEEN_BUFF_CRIT = 0.30
GEN_KEEN_BUFF_CDMG = 0.30
GEN_KEEN_R = 0.8
E("keeneye_rifle", 3, "black", "rifle",
  [A("keeneye_shot", "amulet", "stat_status", keywords=["crit"], tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "keen_eye", "duration": 5.0, "max_stacks": 1, "flags": ["buff", "dispellable"],
                                                                "stats": {"crit_chance": {"flat": GEN_KEEN_BUFF_CRIT}, "crit_damage": {"flat": GEN_KEEN_BUFF_CDMG}}}},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": GEN_KEEN_R}})],
  flat={"crit_chance": GEN_KEEN_CRIT, "crit_damage": GEN_KEEN_CDMG, "crit_overflow_cd": 1.0}, model="keeneye", reworked=True)
# —— 充能系
# 回响刃(黑 · 单手剑 · 3 费 · 双模)：攻击 +m、被动【充能】上限 +1、"每数秒"计时 / 充能回复速度 +m；冷却 4 秒【双模】：
#   友方 → 回复 触发数值 × h 生命；敌方 → 触发数值 × r 物理伤害；不管目标是谁，携带者充能比例最低、没满的一个【充能】效果回复 1 层(extra_effects 里的 charge_refill)。
#   合手：踏影(淬血：逆光时付生命 → 目标自己，回一半 + 逆光回 1 层)、止息(突进 → 敌人 + 掩护支援回 1 层)。
#   (首版是双匕、只有回充能：踏影从剑换成双匕 -9 / 止息 +0；第二版单手剑、只有回充能：踏影 +1 / 止息 +2——光回充能不够，
#    踏影带着有效果的武器每次逆光都要付淬血的生命)
GEN_ECHO_ATK = 15
GEN_ECHO_CHARGES = 1
GEN_ECHO_HASTE = 0.15
GEN_ECHO_HEAL = 0.5
GEN_ECHO_R = 0.8
E("echo_blade", 3, "black", "sword",
  [A("echo_blade_pulse", "amulet", "charge_refill", tags=EP, cooldown=4.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": GEN_ECHO_HEAL},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": GEN_ECHO_R},
          "extra_effects": [{"effect_type": "charge_refill", "target": "self", "count": 1}]})],
  flat={"attack_power": GEN_ECHO_ATK, "passive_charges_bonus": GEN_ECHO_CHARGES, "haste": GEN_ECHO_HASTE}, model="echo", reworked=True)
# 蓄能法典(紫 · 法器 · 4 费 · 放大)：被动【充能】上限 +m、法术强度 +m；冷却 3 秒：对触发目标造成
#   触发数值 × (base + per × 携带者所有【充能】效果当前剩余层数之和) 的魔法伤害；目标是友方时改为 触发数值 × (ally_base + ally_per × 层数) 的治疗(新效果 charge_scaled_damage)。
#   合手：幻灵(充能 9，遗愿按幽灵的最大生命；首版 +23、第二版 +16、第三版 +14、第四版 +13 太强)、护理(药水填充多半打在受伤的队友身上 → 治疗；只有 3 层充能，治疗用单独的系数，第三版 2 倍伤害公式时 +0；第四版 100% + 10%/层：50 级前压 69%，差一点过)
GEN_CAP_CHARGES = 1
GEN_CAP_AP = 15
GEN_CAP_BASE = 0.2
GEN_CAP_PER = 0.03
GEN_CAP_ALLY_BASE = 1.4
GEN_CAP_ALLY_PER = 0.10
E("capacitor_codex", 4, "purple", "focus",
  [A("capacitor_codex_burst", "blade", "charge_scaled_damage", tags=EP, cooldown=3.0, cfg={"base": GEN_CAP_BASE, "per": GEN_CAP_PER, "ally_base": GEN_CAP_ALLY_BASE, "ally_per": GEN_CAP_ALLY_PER})],
  flat={"passive_charges_bonus": GEN_CAP_CHARGES, "ability_power": GEN_CAP_AP}, model="capacitor", reworked=True)
# =====================================================================  通用武器 · 第三批(2026-10-09)：法器
# 按适配标签(game/core/fit_tags.gd)补法器的空档：能拿法器的 17 只棋子里，"对敌人·多目标"(奇兴 / 调香 / 导向)、"对敌人·单体·高频"(巫术 / 舞星 / 正行)、
# "对队友·多目标"(舞星 / 和星)还没有通用法器；触发数值差得很远(巫术 / 清心 10、调香 3349、幻灵 2279)，所以小数值插槽用固定值，大数值插槽用放大。
# 万花镜(青 · 法器 · 3 费 · 固定值 + 放大，【群攻 3】)：法强 +m；冷却 3 秒两段：① GEN_KALEI_DMG 魔法伤害 + 1 层【碎光】(6 秒，叠 2：魔抗 -x)
#   ② 触发数值 × r 魔法伤害。合手：奇兴(d20 掷出来的打击)、调香(焚花：所有敌人)——一次给好几个目标的插槽；调香的触发数值很大靠第二段
GEN_KALEI_AP = 20
GEN_KALEI_DMG = 60
GEN_KALEI_SHRED = 15
GEN_KALEI_R = 0.10
E("kaleidoscope", 3, "cyan", "focus",
  [A("kaleido_shard", "bullet", "magic_damage", fixed=GEN_KALEI_DMG, keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=3.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "prism_shatter", "duration": 6.0, "max_stacks": 2,
                             "flags": ["debuff", "dispellable"], "stats": {"magic_resistance": {"flat": -GEN_KALEI_SHRED}}}]}),
   A("kaleido_glare", "blade", "magic_damage", mult=GEN_KALEI_R, keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=3.0)],
  flat={"ability_power": GEN_KALEI_AP}, model="kaleido", reworked=True, fit_add=["node_wizard"])
# 星屑法球(黑 · 法器 · 2 费 · 固定值【基本】)：法强 +m；【基本】：对触发目标造成 GEN_DUST_DMG 魔法伤害，并施加 1 层【星痕】(4 秒，叠 5：受到的伤害 +x%)。
#   (首版每层 3%、法强 15：正行 +18 / 巫术 +14——高频插槽常驻满层 = 全队打它都增伤)
#   合手：巫术(鸟每次啄中，触发数值 10：对数值很敏感，12 点 / 每层 2% → +5，20 点 / 2.5% / 6 秒 → +14，定稿 16 点 / 2% / 5 秒 → +6)、正行(敌人靠近：拿法器本身就 61 → 79，
#   再加星屑法球 77~79 级的胜率高 5~7 个百分点，80 级是一道墙)。舞星的两个触发器一个给队友一个给敌人，单边的武器会用反；幻灵 +1
GEN_DUST_AP = 15
GEN_DUST_DMG = 16
GEN_DUST_AMP = 0.02
E("stardust_orb", 2, "black", "focus",
  [A("stardust_mote", "bullet", "magic_damage", fixed=GEN_DUST_DMG, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "star_mark", "duration": 5.0, "max_stacks": 5,
                             "flags": ["debuff", "dispellable"], "stats": {"damage_taken_amp": {"flat": GEN_DUST_AMP}}}]})],
  flat={"ability_power": GEN_DUST_AP}, model="stardust", reworked=True)
# 和弦音叉(紫 · 法器 · 3 费 · 双模【基本】【群攻 4】)：生命 +m；【基本】【群攻 4】【双模】：队友 → 1 层【共鸣】(5 秒，叠 4：攻击速度 +x%)；
#   敌人 → 触发数值 × r 魔法伤害。合手：舞星(微笑给全队、泪滴打敌人：两个触发器一边一个，只有双模不会用反)、和星(每 3 秒给星级最低的队友)。
#   第二段冷却 3 秒【双模】：队友 → 触发数值 × s 的护盾；敌人 → 同样多的魔法伤害(和星的触发数值大、触发得慢，靠这一段)。
#   (首版是单边的增益：舞星的泪滴把【共鸣】给了敌人；只有攻速时和星 +0——4 秒一次叠不起来)
GEN_CHORD_HP = 100
GEN_CHORD_AS = 0.03
GEN_CHORD_STACKS = 4
GEN_CHORD_R = 0.3
GEN_CHORD_SHIELD = 0.35
E("chord_fork", 3, "purple", "focus",
  [A("chord_resonance", "amulet", "stat_status", keywords=["basic", "multi_attack"], kv={"multi_attack": 4}, tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "chord_resonance", "duration": 5.0, "max_stacks": GEN_CHORD_STACKS,
                                                                "flags": ["buff", "dispellable"], "stats": {"attack_speed_multiplier": {"flat": GEN_CHORD_AS}}}},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": GEN_CHORD_R}}),
   # 第二段(冷却 3 秒)：队友 → 触发数值 × s 的护盾；敌人 → 同样多的魔法伤害——触发数值大的插槽(和星的微笑 290 上下)靠这一段
   A("chord_overtone", "amulet", "shield", keywords=["multi_attack"], kv={"multi_attack": 4}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": GEN_CHORD_SHIELD},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": GEN_CHORD_SHIELD}})],
  flat={"max_health": GEN_CHORD_HP}, model="chord", reworked=True)
# 晶壁手镜(黑 · 法器 · 2 费 · 放大)：生命 +m、魔抗 +m；冷却 4 秒：触发目标获得 触发数值 × r 的护盾和【晶壁】(4 秒：受到的伤害 -x%)。
#   合手：护理(药水填充多半打在受伤的队友身上)、守林(变身：自己)、变奏(下一乐章：自己)——给自己 / 队友的单体插槽
#   (首版青色：护理是红装不上，变奏本来就 86 只 +1)
GEN_MIRROR_HP = 100
GEN_MIRROR_MR = 15
GEN_MIRROR_R = 0.70
GEN_MIRROR_DR = 0.12
E("ward_mirror", 2, "black", "focus",
  [A("ward_mirror_barrier", "blade", "shield", mult=GEN_MIRROR_R, tags=EP, cooldown=4.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "crystal_wall", "duration": 4.0, "max_stacks": 1,
                             "flags": ["buff", "dispellable"], "stats": {"damage_taken_amp": {"flat": -GEN_MIRROR_DR}}}]})],
  flat={"max_health": GEN_MIRROR_HP, "magic_resistance": GEN_MIRROR_MR}, model="mirror", reworked=True)
# 博闻书匣(紫 · 法器 · 3 费 · 放大【学习】)：法强 +m；冷却 2 秒：对触发目标造成 触发数值 × r 的魔法伤害【学习】(每学一次 +x%，最多 15 次)。
#   合手：求知(背诵：触发数值 600 上下)、幻灵(遗愿：幽灵的最大生命)——对敌人的单体低频插槽、触发数值大。
#   (首版是 60 点固定值 + 学习：求知 +0 / 幻灵 +1——触发数值大的插槽配固定值太亏)
GEN_ERUD_AP = 20
GEN_ERUD_R = 0.15
GEN_ERUD_LEARN = 0.10
E("erudite_case", 3, "purple", "focus",
  [A("erudite_lecture", "blade", "magic_damage", mult=GEN_ERUD_R, keywords=["learning"], tags=EP, cooldown=2.0,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": GEN_ERUD_LEARN, "cap": 15}})],
  flat={"ability_power": GEN_ERUD_AP}, model="erudite", reworked=True)
# =====================================================================  通用武器 · 第四批(2026-10-09)：手枪(双持远程)
# 能拿手枪的 12 只棋子里只有白羽的基础大类是手枪，其余都要换大类(手枪攻速快、带【追击 1】，触发器会变勤：护理拿手枪 0.6 次/秒)。
# 用户：不一定都长成两把手枪；不射子弹的要有自己的攻击特效(武器数据 projectile = 投射物外观，Fx.make_projectile)。
# 设计时用 intensity_bench mode=fitprobe class=pistols 量的"拿上手枪以后"的触发器：白羽 0.63 次/秒、3.3 个目标、数值 10；速射 0.61、10；止息 0.12、242；
#   导向 0.17、2.9 个目标、138；架盾 0.47、自己 + 身边的敌人、50；清心 0.14、敌我各半、10；浪游 / 真望 / 巧运 自己、很少触发。清扫拿手枪不近战，触发器不响。
#   首版数值是现在的一半左右：对"拿基础手枪"只 +0~+3——换成手枪的棋子大多本来就弱(速射 / 架盾 / 浪游 / 巧运 / 清心拿手枪 38~39 = 基础阵容自己的水平)，
#   武器得给得多一点才值得换大类
# 双子燧发枪(黄 · 手枪 · 2 费 · 固定值【基本】+ 放大)：攻速 +m%；两段：①【基本】GEN_FLINT_DMG 物理 ② 冷却 2 秒：触发数值 × r 物理 + 1 层【硝烟】(5 秒，叠 3：护甲 -x)。
#   合手：速射(每 3 次命中，数值 10：吃第一段)、止息(突进，数值 242：吃第二段)。这一把是正经的两把手枪(子弹)
GEN_FLINT_AS = 0.15
GEN_FLINT_DMG = 35
GEN_FLINT_R = 0.5
GEN_FLINT_SHRED = 6
E("twin_flintlock", 2, "yellow", "pistols",
  [A("flintlock_shot", "bullet", "physical_damage", fixed=GEN_FLINT_DMG, keywords=["basic"], tags=EP),
   A("flintlock_powder", "blade", "physical_damage", mult=GEN_FLINT_R, tags=EP, cooldown=2.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "gunsmoke", "duration": 5.0, "max_stacks": 3,
                             "flags": ["debuff", "dispellable"], "stats": {"defense": {"flat": -GEN_FLINT_SHRED}}}]})],
  pct={"attack_speed_multiplier": GEN_FLINT_AS}, model="flintlock", reworked=True)
# 回旋双轮(黑 · 手枪 · 3 费 · 固定值【基本】【群攻 3】)：攻击力 +m；【基本】【群攻 3】：触发目标们各受到 GEN_CHAKRAM_DMG 物理伤害，并【迟滞】(3 秒：移速 -x%)。
#   两手各一只回旋刃轮，普攻扔出去的是打着转的刃轮(projectile chakram)。合手：白羽(诅咒弹：所有敌人，0.6 次/秒)、导向(连锁：一串敌人)
GEN_CHAKRAM_ATK = 20
GEN_CHAKRAM_DMG = 25
GEN_CHAKRAM_SLOW = 0.20
E("twin_chakram", 3, "black", "pistols",
  [A("chakram_cut", "bullet", "physical_damage", fixed=GEN_CHAKRAM_DMG, keywords=["basic", "multi_attack"], kv={"multi_attack": 3}, tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "chakram_slow", "duration": 3.0, "max_stacks": 1,
                             "flags": ["debuff", "dispellable"], "stats": {"move_speed": {"pct": -GEN_CHAKRAM_SLOW}}}]})],
  flat={"attack_power": GEN_CHAKRAM_ATK}, model="chakram", reworked=True, projectile="chakram")
# 命运双牌(青 · 手枪 · 3 费 · 双模)：暴击率 +m；冷却 2 秒【双模】：队友 → 【好运】(10 秒：暴击率 +x%、攻速 +x%)；敌人 → 【厄运】(10 秒：受到的伤害 +y%)。
#   (合手的插槽 7~16 秒才响一次，持续 6 秒时盖不满：清心 +0)
#   两手各一叠扑克牌，普攻甩出去的是旋转的纸牌(projectile card)。不吃触发数值——合手的都是数值很小 / 打自己的插槽：
#   清心(道法：敌我各半)、浪游(装填：自己)、真望(勇气：自己)、巧运(进账：自己)
GEN_CARD_CRIT = 0.15
GEN_CARD_LUCK = 0.30
GEN_CARD_DUR = 10.0
GEN_CARD_HEX = 0.20
E("fortune_cards", 3, "cyan", "pistols",
  [A("fortune_draw", "amulet", "stat_status", tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "good_luck", "duration": GEN_CARD_DUR, "max_stacks": 1, "flags": ["buff", "dispellable"],
                                                                "stats": {"crit_chance": {"flat": GEN_CARD_LUCK}, "attack_speed_multiplier": {"flat": GEN_CARD_LUCK}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "bad_luck", "duration": GEN_CARD_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
                                                                 "stats": {"damage_taken_amp": {"flat": GEN_CARD_HEX}}}}})],
  flat={"crit_chance": GEN_CARD_CRIT}, model="cards", reworked=True, projectile="card")
# 泡泡枪(红 · 手枪 · 2 费 · 固定值【基本】)：生命 +m；【基本】：触发目标回复 GEN_BUBBLE_HEAL 生命，并获得 GEN_BUBBLE_SHIELD 点护盾。
#   两把玩具泡泡枪，普攻打出去的是一串泡泡(projectile bubble)。合手：护理(药水填充：拿手枪 0.6 次/秒，多半打在受伤的队友身上)、巧运(进账：自己)
GEN_BUBBLE_HP = 200
GEN_BUBBLE_HEAL = 35
GEN_BUBBLE_SHIELD = 25
E("bubble_blasters", 2, "red", "pistols",
  [A("bubble_mend", "bullet", "heal", fixed=GEN_BUBBLE_HEAL, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "shield", "target": "target", "fixed_value": GEN_BUBBLE_SHIELD}]})],
  flat={"max_health": GEN_BUBBLE_HP}, model="bubble", reworked=True, projectile="bubble",
  wclass_override={"proj_speed": 12.0})        # 泡泡飞得慢(手枪默认 24 米/秒)
# 共振双铃(黑 · 手枪 · 3 费 · 双模【群攻 3】)：护甲 +m、魔抗 +m；冷却 2 秒【双模】【群攻 3】：队友 → 触发数值 × r 的护盾；敌人 → 触发数值 × r 魔法伤害。
#   两手各一只手铃，普攻荡出去的是一圈声波(projectile sound_ring)。合手：架盾(我的盾：自己 + 身边的敌人)、导向(连锁)
GEN_BELL_DEF = 20
GEN_BELL_R = 1.5
E("resonance_bells", 3, "black", "pistols",
  [A("bell_toll", "amulet", "shield", keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": GEN_BELL_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": GEN_BELL_R}})],
  flat={"defense": GEN_BELL_DEF, "magic_resistance": GEN_BELL_DEF}, model="bells", reworked=True, projectile="sound_ring")
# =====================================================================  通用武器 · 分批文件(2026-10-09 起：三批一组并行派给不同的子代理)
# 每批各写各的 tools/weapons/<批>_data.py(直接用这里的 E / A / T / EP 和常量)，在这里按文件名顺序执行——几个子代理同时改也不会互相覆盖。
# 文本在 tools/weapons/<批>_loc.py(author_loc.py 执行)，模型在 tools/weapons/<批>_models.gd(build_kits.gd 登记)，
# 投射物在 game/view/proj_kinds/<批>.gd(ProjRegistry)，测试在 game/tests/test_<批>.gd。
for _bf in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "weapons", "*_data.py"))):
    exec(compile(open(_bf, encoding="utf-8").read(), _bf, "exec"))

# 狩猎旗标：不可佩戴的特殊物品(狩胜节点上场时放进武器库)；拖到敌人身上 = 标记为狩猎对象，用完回到武器库
eqs.append({"id": "hunt_flag", "cost": 1, "color_id": "red", "weapon_class": "polearm", "slot": "token", "token": "hunt_mark",
            "abilities": [], "model": "hunt_flag"})


# 第一阶段收尾(2026-10-05，用户要求)：还没按新设计重构的棋子(缠绕、悬赏)和武器(无色长弓等)从所有能拿到的池子里清掉——
# 棋子不进商店(available_in_shop：商店 / 随机给棋子)，武器不进随机来源(no_drop：晶球 / 黑市 / 车间制造)。数据本身留着(测试、旧存档还能用)；
# 以后重构了写上 "reworked": True 就自动回到池子里。敌人(mob_ / elite_ / boss_)本来就不进商店，不受影响
LEGACY_UNITS = []
LEGACY_WEAPONS = []
for u in units:
    if u["id"].startswith("node_") and not u.get("reworked") and u.get("available_in_shop", True):
        u["available_in_shop"] = False
        LEGACY_UNITS.append(u["id"])
for e in eqs:
    if not e.get("reworked") and not e.get("basic") and e.get("slot", "weapon") == "weapon" and not e.get("no_drop"):
        e["no_drop"] = True
        LEGACY_WEAPONS.append(e["id"])


# 武器触发器的内置适配标签(用户 2026-10-09；规则见 game/core/fit_tags.gd)：tools/fit_tags_data.py 是 ./run_fitprobe.sh 实测出来的
# (side 对敌人 enemy / 对队友 ally / 需要双模 both，count 对多个目标 multi / 对单个目标 single，freq 高频 high / 低频 low)。
# 实测不对的写在这里覆盖(触发器 id → 要改的那几组)。新棋子 / 改了触发器：./run_fitprobe.sh 再跑本脚本。
FIT_OVERRIDE = {
}


def attach_fit_tags():
    try:
        from fit_tags_data import TRIGGER_FIT
    except ImportError:
        TRIGGER_FIT = {}
    for u in units:
        for t in u.get("triggers", []):
            if "equipment_payload" not in t.get("tags", []):
                continue
            m = TRIGGER_FIT.get(t["id"])
            ft = {k: m[k] for k in ("side", "count", "freq")} if m else {}
            ft.update(FIT_OVERRIDE.get(t["id"], {}))
            if ft:
                t["fit_tags"] = ft


def main():
    from filelock import lock
    with lock("author"):          # 几个子代理并行时别同时写数据(tools/filelock.py)
        _main()


def _main():
    clear()
    attach_fit_tags()
    for u in units:
        write("units", u["id"], u)
    for e in eqs:
        write("equipment", e["id"], e)
    import author_traits
    author_traits.main(write)
    import author_chapters
    author_chapters.main()
    import author_events
    author_events.main()
    import author_mods
    author_mods.main()
    purge_stale()
    print("units:", len(units), " equipment:", len(eqs), " legacy(out of pools):", len(LEGACY_UNITS), "units", len(LEGACY_WEAPONS), "weapons")


if __name__ == "__main__":
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    main()
