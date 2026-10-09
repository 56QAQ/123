"""事件(地图上的"事件"节点)的生成脚本(由 author_data.py 调用)。写出 game/data/events.json。

事件 = 一幕有实际场景建模的遭遇 + 《杀戮尖塔》式的选项。文本在 author_loc.py(event.<id>.title / body / opt.<选项> / res.<结果>)。
  rarity：稀有度 1~3(越大越少见，抽取权重见 RARITY_WEIGHTS)
  pool：事件池
    {"type": "common"}                       通用：总是可以出现；出现后移出事件池(本局不再出现)
    {"type": "chapter", "chapter": n}        特定章节：只在第 n 章出现(第一章 = 红 / 绿 / 蓝之章)；出现后移出事件池
    {"type": "color", "color": c}            特定颜色：只在包含这种颜色的章节出现(红色事件：红之章(1)、紫 / 黄之章(2)、黑之章(3))；同一章里不重复
    {"type": "exclusive", "chapter": id}     限定：只在某一个章节出现(纯红色事件只在红之章)；同一章里不重复
    {"type": "fallback"}                     兜底：池子里没有能出的事件时用(不参与抽取)
  scene：场景(game/view/event_stage.gd)。事件有战斗时 scene = 那个专属战场的布景：事件画面和事件战斗是同一个地方
  options：[{id, requires:[条件], outcomes:[{w 权重, id, effects:[效果]}]}]
    条件：truck_hp_above{value}(卡车耐久要高于这个值)，ranged_attack_at_least{value}(有节点手持远程武器且攻击力 ≥ value)
    效果：truck_damage{amount} / materials{red, green, blue} / gold{amount} / xp{amount} /
          ap{amount 行动力(可以是负数)} / reveal{radius 观测周围这么多格内的节点} /
          battle{arena 专属战场(见 ARENAS), intensity_bonus 在节点强度上加多少, min_intensity, orbs 胜利后额外掉落的晶球,
                 fixed 没有专属战场时：在随机生成的战斗地图上固定放的障碍[{style, w, h, kind, terrain}]}

专属战场 ARENAS(事件战斗不用随机生成的战斗地图)：id -> {
    theme       章节主题(地面 / 天色)
    cam_z       战斗镜头的注视点往北(负)挪多少米：把北侧的主角放进画面
    set         表现层的布景(game/view/arena_set.gd)：事件画面和战场用同一套
    regions     敌人的出生方位(轮流分给每个敌人)
    obstacles   障碍物 [{x, y, w, h, kind low/high, style 模型, terrain 可选, ox / oz 可选：模型相对格子矩形中心的偏移(米)}]
    embers      余烬地块 [{x, y, w, h, style}]
    hazards     战场机制(Battle 按时刻表发地形事件 OnTerrainHit，伤害 / 燃烧走 terrain.json 的"触发器 + 能力"，见 author_chapters.py)：
        {type: "sweep"    一个大家伙沿直线冲过战场(电车)：id, tag 地形事件的标签, z 轨道中心线, half_width, length, rest_x 发车前停在哪,
                          accel, speed, first 开战后第几秒第一班, period 每隔几秒一班, warn 提前几秒预警}
        {type: "eruption" 周期性的喷发(喷泉)：id, tag, center, height 喷口高度, first, period, warn 蓄力几秒, flight 火弧飞几秒, embers 落点 = 第几块余烬地块(重新点燃)}
}
坐标：格子 (x, y) 19×14，x 向东、y 向南；世界坐标(米)原点在地图中心，z = y - 7 + 0.5。我方部署区 = 格子 x 5..13、y 4..9，卡车在正中。
"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "data")

RARITY_WEIGHTS = {"1": 6, "2": 3, "3": 1}


# ---------------------------------------------------------------- 第二批事件(2026-10-06，docs/EVENTS_BATCH2.md)的写法
#   可重复的选项：option.repeat = {max: n}(最多选 n 次，选了以后结果页按「回到现场」回到选项列表)；
#     by_pick = [第 1 次的结果列表, 第 2 次的, …](超出用最后一组)；条件 gold_at_least 可以带 per_pick(每选一次涨这么多)；
#     结果 close = [选项 id](这个结果关掉那些选项)，end = true(选完不再回到现场)；选项 hidden = true(界面上只写「？？？」)
#   纯负面事件：event.negative = true(校验：任何结果都不许有收益)
#   新效果：truck_heal{amount|pct} / truck_max{amount} / unit{cost|id, star} / weapon{max_cost|id} / orb{tier, count} /
#     perm{who random|strongest|cheapest, stats{damage_dealt_pct…}} / star_up{max_cost} / lose_unit{who} / lose_weapon / lose_part / part{id|random} /
#     flag{id, value, until next_battle|chapter|run}；做不成的效果(没棋子可失去 / 零件箱满 / 没有能升星的)用 fallback 里的效果
#   新条件：gold_at_least / materials_at_least{color?} / level_at_least / ap_at_least / roster_at_least / has_weapon / has_part /
#     picked_at_least{option} / picked_below{option}
#   场景：scene = "roadside"(街景套件：路肩 + 按章节主题的背景) + props(主角道具，见 event_stage._place_prop) + cam(可选)
def O(oid, effects=(), w=1, close=None, end=False, luck=None):
    """luck：这个随机结果有多好(越大越好)；同一个选项的结果都写了 luck = 有明确好坏，巧运节点的真骰会重投 1 次取好的"""
    d = {"w": w, "id": oid, "effects": list(effects)}
    if luck is not None:
        d["luck"] = luck
    if close:
        d["close"] = list(close)
    if end:
        d["end"] = True
    return d


def OPT(oid, outcomes=None, requires=(), repeat=0, by_pick=None, hidden=False):
    d = {"id": oid, "requires": list(requires)}
    if by_pick is not None:
        d["by_pick"] = by_pick
    else:
        d["outcomes"] = outcomes
    if repeat:
        d["repeat"] = {"max": repeat}
    if hidden:
        d["hidden"] = True
    return d


def PROP(model, x, z, yaw=0.0, scale=1.0, y=0.0):
    return {"kind": "model", "model": model, "pos": [x, y, z], "yaw": yaw, "scale": scale}


def LIGHT(x, y, z, color, energy=2.0, rng=6.0):
    return {"kind": "light", "pos": [x, y, z], "color": color, "energy": energy, "range": rng}


def FIRE(x, y, z, size=0.4, smoke=True):
    return {"kind": "fire", "pos": [x, y, z], "size": size, "smoke": smoke}


def SPHERE(x, y, z, color, r=0.3):
    return {"kind": "sphere", "pos": [x, y, z], "color": color, "r": r}


def TRUCK(a):
    return {"type": "truck_damage", "amount": a}


def GOLD(a):
    return {"type": "gold", "amount": a}


def XP(a):
    return {"type": "xp", "amount": a}


def AP(a):
    return {"type": "ap", "amount": a}


def MAT(**kw):
    d = {"type": "materials"}
    d.update(kw)
    return d


def ORB(tier, count=1):
    return {"type": "orb", "tier": tier, "count": count}


def FLAG(fid, value, until):
    return {"type": "flag", "id": fid, "value": value, "until": until}

ARENAS = {
    # 公园喷泉(事件「燃烧喷泉」)：铺砖的圆形广场，北侧偏中是那座燃烧的喷泉(5×4 格，紧挨着初始部署区的北沿；它北边还有 3 排空地)，烧红的人影从它两侧走出来。
    # 格子坐标按 25 × 20 的战场写(世界坐标 = 原点在地图中心，和布景 ArenaSet 一致)。
    # 喷泉周围一圈 7 个落火点(余烬地块)：喷泉每 9 秒喷发一次，火弧砸在落火点上并把它们重新点燃。
    "fountain_park": {
        "theme": "red", "set": "fountain_park", "cam_z": -2.4,
        "regions": ["nw", "ne", "nw", "ne", "w", "e"],
        "obstacles": [
            {"x": 10, "y": 3, "w": 5, "h": 4, "kind": "low", "style": "burn_fountain", "terrain": "burning", "oz": -0.5},
            {"x": 6, "y": 7, "w": 1, "h": 2, "kind": "low", "style": "evt_bench"},
            {"x": 18, "y": 8, "w": 1, "h": 2, "kind": "low", "style": "evt_bench"},
            {"x": 5, "y": 13, "w": 1, "h": 1, "kind": "high", "style": "evt_tree"},
            {"x": 19, "y": 13, "w": 1, "h": 1, "kind": "high", "style": "evt_tree"},
            {"x": 8, "y": 15, "w": 1, "h": 1, "kind": "high", "style": "evt_tree"},
            {"x": 15, "y": 15, "w": 3, "h": 1, "kind": "low", "style": "evt_swing"},
        ],
        "embers": [{"x": x, "y": y, "w": 1, "h": 1, "style": "ember_jet"} for x, y in [(16, 4), (15, 6), (14, 7), (12, 8), (10, 7), (9, 6), (8, 4)]],
        "hazards": [{"type": "eruption", "id": "fountain", "tag": "fire_arc", "center": [0.0, -5.5], "height": 3.3,
                     "first": 5.0, "period": 9.0, "warn": 2.0, "flight": 1.2, "embers": [0, 1, 2, 3, 4, 5, 6]}],
    },
    # 电车站(事件「末班电车」)：铁轨横贯战场北侧(格子第 2~3 行，z = -7)，轨道北边是站台("乘客"在站台上站成一排)，南边隔 3 排空地是我方部署区。
    # 每隔 13 秒一班电车从西边冲过整条轨道(道口的红灯和栏杆提前 3 秒预警)：轨道上的单位被撞开、受伤、点燃，敌我不分。
    "tram_stop": {
        "theme": "red", "set": "tram_stop", "cam_z": -1.2,
        "regions": ["n"],
        "obstacles": [
            {"x": 5, "y": 9, "w": 1, "h": 1, "kind": "high", "style": "ash_pillar"},
            {"x": 18, "y": 10, "w": 2, "h": 1, "kind": "low", "style": "ash_car"},
            {"x": 6, "y": 14, "w": 1, "h": 1, "kind": "low", "style": "burn_debris", "terrain": "burning"},
            {"x": 14, "y": 15, "w": 2, "h": 1, "kind": "low", "style": "burn_car", "terrain": "burning"},
            {"x": 19, "y": 15, "w": 1, "h": 1, "kind": "low", "style": "ash_rubble_a"},
        ],
        "embers": [],
        "hazards": [{"type": "sweep", "id": "tram", "tag": "tram", "z": -7.0, "half_width": 1.1, "length": 9.8, "rest_x": -17.6,
                     "accel": 7.0, "speed": 11.0, "first": 6.0, "period": 13.0, "warn": 3.0}],
    },
}

EVENTS = [
    # 兜底：这一章的事件都出过了
    {"id": "quiet_street", "rarity": 1, "pool": {"type": "fallback"}, "scene": "quiet",
     "options": [{"id": "leave", "requires": [], "outcomes": [{"w": 1, "id": "leave", "effects": []}]}]},
    # ---------------------------------------------------------------- 红之章 限定
    # 燃烧喷泉：公园遗址中央的喷泉喷出三人多高的火柱
    {"id": "burning_fountain", "rarity": 2, "pool": {"type": "exclusive", "chapter": "ch1_red"}, "scene": "fountain_park",
     "options": [
         # 冒险收集火焰样本：损失卡车耐久，换燃素
         {"id": "collect", "requires": [{"type": "truck_hp_above", "value": 6}],
          "outcomes": [{"w": 1, "id": "collect", "effects": [{"type": "truck_damage", "amount": 6}, {"type": "materials", "red": 6}]}]},
         # 破坏喷泉：要有拿远程武器、攻击力够高的节点。一半拿到金币，一半惊醒了火里的东西(在喷泉前面打一场艰难的战斗，赢了额外掉金色 + 蓝色晶球)
         #   强度 = 节点 +12(和精英节点一样)、至少 28(2026-10-06 新刻度；旧刻度的 +6 靠的是跨进强怪池)
         {"id": "destroy", "requires": [{"type": "ranged_attack_at_least", "value": 120}],
          "outcomes": [{"w": 1, "id": "destroy_gold", "effects": [{"type": "gold", "amount": 10}]},
                       {"w": 1, "id": "destroy_fight", "effects": [{"type": "battle", "arena": "fountain_park", "intensity_bonus": 12, "min_intensity": 28,
                                                                    "orbs": ["gold", "blue"]}]}]},
         # 尝试理解其中的原理：获得经验
         {"id": "study", "requires": [],
          "outcomes": [{"w": 1, "id": "study", "effects": [{"type": "xp", "amount": 6}]}]},
     ]},
    # 末班电车：一节灌满了火的路面电车准点进站(火焰还记得这座城市的时刻表)。三个选项对应三套系统：行动力 / 战斗 / 观测
    {"id": "last_tram", "rarity": 1, "pool": {"type": "exclusive", "chapter": "ch1_red"}, "scene": "tram_stop",
     "options": [
         # 跟在它后面走：电车一路撞开轨道上的瓦砾，卡车沿着清出来的路走(+2 行动力 = 一个备用油桶)，代价是被它拖着的火尾燎到
         {"id": "follow", "requires": [{"type": "truck_hp_above", "value": 8}],
          "outcomes": [{"w": 1, "id": "follow", "effects": [{"type": "truck_damage", "amount": 8}, {"type": "ap", "amount": 2}]}]},
         # 上车拿行李架上的遗失物：一场自己选的硬仗(没有运气成分)，就在这个电车站打——"乘客"在站台上，电车照着时刻表一班一班地冲过战场。
         # 赢了额外掉两个蓝色晶球。强度只比节点高一点：敌人全从正北一个方向压过来、电车也撞自己人(旧刻度 +2 约 65%；
         # 2026-10-06 换成平滑的新刻度后 +2 太容易(85%)，改成 +6、至少 20)
         {"id": "board", "requires": [],
          "outcomes": [{"w": 1, "id": "board_fight", "effects": [{"type": "battle", "arena": "tram_stop", "intensity_bonus": 6, "min_intensity": 20,
                                                                  "orbs": ["blue", "blue"]}]}]},
         # 目送它离开，读站牌上的路线图：观测周围 3 格内的节点 + 一点经验
         {"id": "watch", "requires": [],
          "outcomes": [{"w": 1, "id": "watch", "effects": [{"type": "reveal", "radius": 3}, {"type": "xp", "amount": 3}]}]},
     ]},
    # ================================================================ 第二批(2026-10-06)：通用事件
    # ---------------------------------------------------------------- A. 可重复选择的选项
    # 扭蛋机：停电的街区里唯一还亮着的机器。投币(最多 5 次，第 n 次 n+1 金，结果不明)：按晶球表出白 / 蓝 / 金球，或者吞币；
    # 投过 2 次之后可以晃它(40% 掉一颗白球 / 60% 卡车撞上去 -4 耐久，之后机器坏了不能再投)；走开
    {"id": "gacha_machine", "rarity": 2, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_gacha", 0.0, 0.0, 12.0), PROP("bld_vending", -2.1, -0.9, 6.0), LIGHT(0.0, 1.7, 0.9, "#ff7ad6", 2.6, 5.0), LIGHT(-2.1, 1.4, -0.3, "#9fd8ff", 1.2, 4.0)],
     "options": [
         OPT("pull", requires=[{"type": "gold_at_least", "value": 2, "per_pick": 1}], repeat=5, hidden=True,
             by_pick=[[O("ball_white", [GOLD(-(n + 2)), ORB("white")], 50, luck=1), O("ball_blue", [GOLD(-(n + 2)), ORB("blue")], 30, luck=2),
                       O("eat", [GOLD(-(n + 2))], 12, luck=0), O("ball_gold", [GOLD(-(n + 2)), ORB("gold")], 8, luck=3)] for n in range(5)]),
         OPT("shake", requires=[{"type": "picked_at_least", "option": "pull", "value": 2}],
             outcomes=[O("shake_ball", [ORB("white")], 40, close=["pull", "shake"], luck=1), O("shake_hit", [TRUCK(4)], 60, close=["pull", "shake"], luck=0)]),
         OPT("walk", outcomes=[O("walk", [])]),
     ]},
    # 挖掘现场：有人挖了一半的坑。再挖一层(最多 4 层，每层 -3 耐久)：第 1 层有机物 +3，第 2 层液态负熵 +4，第 3 层 60% +8 金 / 40% 空箱，
    # 第 4 层 40% 虹球 / 60% 塌方(再 -10 耐久、-1 行动力，挖不下去了)；收工
    {"id": "dig_site", "rarity": 1, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_dig", 0.2, 0.3, -8.0), PROP("ash_rubble_b", -3.0, -2.2, 30.0), LIGHT(0.6, 1.3, 1.4, "#ffc27a", 1.6, 5.0)],
     "options": [
         OPT("dig", requires=[{"type": "truck_hp_above", "value": 15}], repeat=4,
             by_pick=[[O("dig1", [TRUCK(3), MAT(green=3)])],
                      [O("dig2", [TRUCK(3), MAT(blue=4)])],
                      [O("dig3_gold", [TRUCK(3), GOLD(8)], 60, luck=1), O("dig3_empty", [TRUCK(3)], 40, luck=0)],
                      [O("dig4_orb", [TRUCK(3), ORB("rainbow")], 40, luck=1), O("dig4_collapse", [TRUCK(13), AP(-1)], 60, end=True, luck=0)]]),
         OPT("pack_up", outcomes=[O("pack_up", [])]),
     ]},
    # 负熵井：井水往上流。再打一桶(最多 3 次)：液态负熵 +4、卡车耐久上限 -3；让一个节点喝一口：70% 永久 +8% 伤害 / 30% 失去它(只有一个棋子时改为 -10 耐久)；盖上井盖
    {"id": "entropy_well", "rarity": 2, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_well", 0.0, 0.0, 20.0), LIGHT(0.0, 1.6, 0.0, "#5ad6ff", 3.0, 6.5), PROP("ash_rubble_a", 2.8, 1.2, 0.0)],
     "options": [
         OPT("draw", repeat=3, outcomes=[O("draw", [MAT(blue=4), {"type": "truck_max", "amount": -3}])]),
         OPT("drink", requires=[{"type": "roster_at_least", "value": 1}],
             outcomes=[O("drink_boon", [{"type": "perm", "who": "random", "stats": {"damage_dealt_pct": 0.08}}], 70, luck=1),
                       O("drink_lost", [{"type": "lose_unit", "who": "random", "fallback": TRUCK(10)}], 30, luck=0)]),
         OPT("cover", outcomes=[O("cover", [])]),
     ]},
    # ---------------------------------------------------------------- B. 纯负面事件(negative = true：校验不许有任何收益)
    # 路障：对方不想打，只想要东西。交钱 -6 金 / 交一把武器 / 硬闯(-12 耐久、-1 行动力) / 掉头(-2 行动力)
    {"id": "toll_gate", "rarity": 1, "pool": {"type": "common"}, "negative": True, "scene": "roadside",
     "props": [PROP("evt_barricade", 0.0, -0.6, 0.0), PROP("ash_car", -3.3, -1.5, 18.0), PROP("ash_car", 3.5, -1.3, -22.0),
               PROP("evt_searchlight", 1.5, -2.3, 200.0), LIGHT(1.3, 2.1, -1.6, "#fff1c0", 3.2, 8.0)],
     "options": [
         OPT("pay", requires=[{"type": "gold_at_least", "value": 6}], outcomes=[O("pay", [GOLD(-6)])]),
         OPT("hand_weapon", requires=[{"type": "has_weapon"}], outcomes=[O("hand_weapon", [{"type": "lose_weapon"}])]),
         OPT("force", requires=[{"type": "truck_hp_above", "value": 20}], outcomes=[O("force", [TRUCK(12), AP(-1)])]),
         OPT("turn", outcomes=[O("turn", [AP(-2)])]),
     ]},
    # 爆胎：主角就是自己的卡车。换备胎(-2 行动力) / 用轮毂开(-10 耐久) / 拆一个零件顶上
    {"id": "blowout", "rarity": 1, "pool": {"type": "common"}, "negative": True, "scene": "roadside",
     "props": [PROP("truck", 0.0, -0.2, -24.0), PROP("evt_tire_kit", 2.2, 1.3, 35.0), LIGHT(2.0, 1.2, 1.6, "#ffd9a0", 1.6, 5.0)],
     "options": [
         OPT("spare", outcomes=[O("spare", [AP(-2)])]),
         OPT("rim", requires=[{"type": "truck_hp_above", "value": 20}], outcomes=[O("rim", [TRUCK(10)])]),
         OPT("part", requires=[{"type": "has_part"}], outcomes=[O("part", [{"type": "lose_part"}])]),
     ]},
    # 变质的补给：密封罐开了缝。倒掉(最多的那种材料 -50%) / 分拣(-1 行动力，三种材料各 -1) / 不管它(罐子在车厢里炸了：-6 耐久)
    {"id": "spoiled_supplies", "rarity": 1, "pool": {"type": "common"}, "negative": True, "scene": "roadside",
     "props": [PROP("truck", -0.6, -1.4, 155.0), PROP("evt_canisters", 0.9, 1.1, -12.0), FIRE(1.3, 0.15, 1.5, 0.22), LIGHT(0.9, 1.2, 1.4, "#9fffb0", 1.4, 4.0)],
     "options": [
         OPT("dump", outcomes=[O("dump", [MAT(half="most")])]),
         OPT("sort", outcomes=[O("sort", [AP(-1), MAT(red=-1, green=-1, blue=-1)])]),
         OPT("ignore", outcomes=[O("ignore", [TRUCK(6)])]),
     ]},
    # 余烬风暴(红色事件)：风把整座城市的灰烬都卷起来了。顶风开(-8 耐久) / 停车等(-2 行动力) / 关掉所有仪器(诅咒：下一场敌人强度 +6)
    {"id": "ash_storm", "rarity": 2, "pool": {"type": "color", "color": "red"}, "negative": True, "scene": "roadside",
     "props": [PROP("evt_sign", 1.4, -0.4, 22.0), PROP("ash_rubble_a", -2.2, 0.8, 70.0), {"kind": "embers", "size": 30, "amount": 900, "height": 9.0},
               LIGHT(0.0, 2.5, 0.0, "#ff8a4a", 2.2, 9.0)],
     "options": [
         OPT("drive", requires=[{"type": "truck_hp_above", "value": 20}], outcomes=[O("drive", [TRUCK(8)])]),
         OPT("wait", outcomes=[O("wait", [AP(-2)])]),
         OPT("dark", outcomes=[O("dark", [FLAG("next_battle_intensity", 6, "next_battle")])]),
     ]},
    # ---------------------------------------------------------------- C. 高收益的通用事件
    # 失落的军火库：锁的是等级。破解(等级 ≥ 5：一把 ≤ 4 费武器 + 8 金) / 炸开(远程攻击 ≥ 150：一把 ≤ 3 费武器，-6 耐久) / 只拿门口的(+5 金)
    {"id": "lost_armory", "rarity": 3, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_bunker", 0.0, -1.2, 0.0), LIGHT(-0.1, 1.0, 0.9, "#ffd080", 2.0, 5.0), LIGHT(1.05, 1.25, 0.6, "#8dff9a", 0.9, 2.5)],
     "options": [
         OPT("hack", requires=[{"type": "level_at_least", "value": 5}], outcomes=[O("hack", [{"type": "weapon", "max_cost": 4}, GOLD(8)])]),
         OPT("blast", requires=[{"type": "ranged_attack_at_least", "value": 150}], outcomes=[O("blast", [{"type": "weapon", "max_cost": 3}, TRUCK(6)])]),
         OPT("door", outcomes=[O("door", [GOLD(5)])]),
     ]},
    # 流浪技师：请他大修(10 金：耐久回满、上限 +10) / 换零件(一个随机零件；零件箱满了折 3 金) / 请他上车(一个 3 费随机节点)
    {"id": "wandering_mechanic", "rarity": 2, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_pickup", 0.5, -0.7, -32.0), LIGHT(0.3, 2.3, -0.5, "#9fd0ff", 3.4, 4.5), FIRE(2.4, 0.1, 1.9, 0.3, False)],
     "options": [
         OPT("overhaul", requires=[{"type": "gold_at_least", "value": 10}],
             outcomes=[O("overhaul", [GOLD(-10), {"type": "truck_max", "amount": 10}, {"type": "truck_heal", "pct": 1.0}])]),
         OPT("part", outcomes=[O("part", [{"type": "part", "id": "random", "fallback": GOLD(3)}])]),
         OPT("join", outcomes=[O("join", [{"type": "unit", "cost": 3, "star": 1}])]),
     ]},
    # 晶球雨：捡近的(蓝球 ×3) / 捡大的(-2 行动力：金球 + 白球) / 追还在滚的那颗(50% 虹球 / 50% 什么都没有)
    {"id": "orb_rain", "rarity": 3, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_crater", 0.0, 0.2, 0.0), SPHERE(-1.6, 0.35, 1.2, "#6fc8ff"), SPHERE(1.9, 0.35, 0.6, "#6fc8ff"), SPHERE(0.4, 0.35, 2.3, "#6fc8ff"),
               SPHERE(-0.3, 0.45, -0.4, "#ffd36b", 0.38), SPHERE(2.8, 0.3, -1.6, "#ffffff", 0.26), SPHERE(-3.4, 0.4, -0.9, "#c86aff", 0.34)],
     "cam": {"focus": [0.0, 0.8, 0.2], "dist": 9.5, "height": 4.4, "yaw": 16.0},
     "options": [
         OPT("near", outcomes=[O("near", [ORB("blue", 3)])]),
         OPT("big", requires=[{"type": "ap_at_least", "value": 2}], outcomes=[O("big", [AP(-2), ORB("gold"), ORB("white")])]),
         OPT("chase", hidden=True, outcomes=[O("chase_orb", [ORB("rainbow")], 50, luck=1), O("chase_lost", [], 50, luck=0)]),
     ]},
    # 古老的祭坛：献金币(-6 金：最强的节点永久 +10% 伤害) / 献耐久(-12：一个 1 星节点 ≤ 3 费升 2 星；没有就 +6 经验) /
    # 献材料(三种各 -3：本章节点制造按高一级的概率抽) / 研究(+4 经验)
    {"id": "old_altar", "rarity": 2, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("altar", 0.0, -0.5, 0.0), LIGHT(0.0, 1.7, -0.3, "#ffd36b", 2.4, 6.5), FIRE(-0.9, 0.95, 0.1, 0.16, False), FIRE(0.9, 0.95, 0.1, 0.16, False)],
     "cam": {"focus": [0.0, 1.3, -0.3], "dist": 8.5, "height": 3.4, "yaw": 8.0},
     "options": [
         OPT("offer_gold", requires=[{"type": "gold_at_least", "value": 6}],
             outcomes=[O("offer_gold", [GOLD(-6), {"type": "perm", "who": "strongest", "stats": {"damage_dealt_pct": 0.10}}])]),
         OPT("offer_hp", requires=[{"type": "truck_hp_above", "value": 25}],
             outcomes=[O("offer_hp", [TRUCK(12), {"type": "star_up", "max_cost": 3, "fallback": XP(6)}])]),
         OPT("offer_mats", requires=[{"type": "materials_at_least", "value": 3}],
             outcomes=[O("offer_mats", [MAT(red=-3, green=-3, blue=-3), FLAG("shop_odds_shift", 1, "chapter")])]),
         OPT("study", outcomes=[O("study", [XP(4)])]),
     ]},
    # 旧友：收下武器(一把 ≤ 3 费武器) / 收下人情(本章每个节点 +2 金) / 劝他一起走(60% 一个 2 费节点 / 40% 他拒绝了，+5 经验)
    {"id": "old_friend", "rarity": 2, "pool": {"type": "common"}, "scene": "roadside",
     "props": [PROP("evt_friend", 0.1, 0.1, 24.0), PROP("evt_bench", 2.6, -0.9, 95.0), LIGHT(0.4, 1.5, 1.0, "#ffd9a0", 1.8, 5.0)],
     "cam": {"focus": [0.0, 1.0, 0.0], "dist": 7.5, "height": 3.0, "yaw": 14.0},
     "options": [
         OPT("take_weapon", outcomes=[O("take_weapon", [{"type": "weapon", "max_cost": 3}])]),
         OPT("favor", outcomes=[O("favor", [FLAG("income_bonus", 2, "chapter")])]),
         OPT("join", outcomes=[O("join_yes", [{"type": "unit", "cost": 2, "star": 1}], 60, luck=1), O("join_no", [XP(5)], 40, luck=0)]),
     ]},
]


def main():
    with open(os.path.join(ROOT, "events.json"), "w", encoding="utf-8") as f:
        json.dump({"rarity_weights": RARITY_WEIGHTS, "events": EVENTS, "arenas": ARENAS}, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
