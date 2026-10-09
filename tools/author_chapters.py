"""章节 / 地图节点 / 遭遇 / 晶球掉落表 的生成脚本(由 author_data.py 调用)。写出：
  game/data/chapters/<id>.json   章节：主题、起始资源、地图节点(一条路线)、每个节点的遭遇与地图参数
  game/data/loot.json            晶球(白/蓝/金)的掉落表，参考《云顶之弈》开局野怪回合的战利品并做了平衡

遭遇 units 的写法：[单位, 星级, 方位(n ne e se s sw w nw；n = 画面上方/敌方纵深), 武器 id("" = 基础武器), {选项}]
  选项：orb = 被击杀时掉落的晶球(white/blue/gold)，boss = 首领(体型更大、生命更高、冲进卡车伤害更高)
地图 map：{"low": 矮障碍数, "high": 高障碍数, "altar": 是否在敌方一侧放终点祭坛, "theme", "burning", "embers"}，由 MapGen 按种子生成
  game/data/terrain.json         地形效果(燃烧废墟 / 余烬地块)的"触发器 + 能力"
  game/data/meta.json            卡车零件、卡车改装(占位)
  game/data/workshop.json        车间：材料、装备制造的概率曲线、分解
ui_theme：该章节的 UI 配色(game/ui/ui_theme.gd 里的主题名)，不同底色的章节用对比足够鲜明的配色
"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "data")


def enc(units, low, high, altar=False):
    return {"units": units, "map": {"low": low, "high": high, "altar": altar}}


def node(nid, ntype, encounter, income):
    return {"id": nid, "type": ntype, "encounter": encounter, "income": income}


# ---------------------------------------------------------------- 第零章：白之章
# 白色宗教风遗迹(大理石/石英/灰白)。3 个奖励节点排成一条直线，没有岔路——相当于《云顶之弈》正式开局前的野怪奖励回合。
CH0 = {
    "id": "ch0", "chapter_no": 0, "color": "white", "theme": "white", "ui_theme": "white", "start_gold": 3, "start_level": 3, "truck_hp": 100, "truck_damage_base": 2,
    "loot_guarantee": {"weapon": 2, "unit": 1},        # 保底：本章晶球至少开出 2 把武器、1 个节点
    # 打完：选一项卡车改装(占位) → 选第一章的分支(红/蓝/绿；现在只做了红之章)
    "next": {"branches": [{"id": "ch1_red", "available": True}, {"id": "ch1_blue", "available": True}, {"id": "ch1_green", "available": False}]},
    "nodes": [
        # 开局送了空白节点 + 打工小帮手(每场活下来就多一个白色晶球)，所以前两个奖励节点各少掉一个白色晶球(2026-10-02)
        node("ch0_n1", "reward", enc([
            ["mob_sentinel", 1, "n", "", {"orb": "white"}],
            ["mob_sentinel", 1, "nw", "", {}],
        ], low=3, high=2), income=0),
        node("ch0_n2", "reward", enc([
            ["mob_sentinel", 1, "ne", "", {"orb": "white"}],
            ["mob_archer", 1, "n", "", {}],
            ["mob_sentinel", 1, "w", "", {"orb": "blue"}],
        ], low=4, high=3), income=2),
        node("ch0_n3", "reward", enc([
            ["mob_guardian", 1, "n", "", {"orb": "gold", "boss": True}],
            ["mob_acolyte", 1, "nw", "", {"orb": "blue"}],
            ["mob_archer", 1, "ne", "", {"orb": "blue"}],
            ["mob_sentinel", 1, "e", "", {"orb": "white"}],
        ], low=4, high=3, altar=True), income=3),
    ],
}

# ---------------------------------------------------------------- 第一章-A：红之章
# 黑夜里燃烧的现代日本城市废墟(学校 / 居民区 / 市中心 / 工厂区)。地位相当于《杀戮尖塔 2》第一幕的"密林"(蓝之章、绿之章 = "暗港")。
# 地图是方格网(ChapterMap)，移动机制参照《明日方舟·沉沦者的黑流树海》：每经过 1 个格点扣 1 点行动力，不能穿过未完成的节点；
# 行动力 = 起点到首领的最短步数 + ap_spare；用完还没打倒首领 → 追猎(首领的强化版就地开战)。
# 战斗强度(2026-10-05 重做，用户定的口径)：一场战斗敌方总水平的绝对刻度——普通 / 精英 / 首领 / 追猎，同样的强度 = 同样多的"强度点数"
#   (实际难度会因为配怪组合不同而有差别)。一只怪的点数 = power × 星级系数 × (生命攻击倍率)^scale_exp，精英 / 首领的本体也在同一个刻度上；
#   这三样由 tools/fit_power.py 用模拟战斗标定(intensity_bench mode=calib 的随机配怪 → 最大似然)：同样的点数 ≈ 同样的难度。
# 节点强度：离起点越远越高(基础 base，每远一步 +per_depth，最高 max)；精英节点再 +elite_bonus；普通 / 精英再乘 1 ± jitter(开局定好)。
#   强怪 = 后半程的普通作战有 strong.chance 的几率在浮动之上再加 strong.bump 级强度(开局定好，悬停能看到)，掉蓝色晶球。没有单独的强怪池了。
# 配怪(Run._make_encounter)：本体(精英 / 首领)先占自己的点数；剩下的点数挑一个阵型(必备的怪 1 星放得下的阵型里随机)，补可选的怪、再升星，
#   都不超过剩下的点数；最后这批怪的生命 / 攻击乘同一个倍率，总点数正好 = 战斗强度——强度每 +1 难度都平滑地涨，没有台阶。
#   单挑的首领 / 追猎(或剩下的点数配不了手下)：倍率加在本体上。星级上限按强度(max_star)。
WR, SL, LU, GL = "mob_ember_wrath", "mob_ember_sloth", "mob_ember_lust", "mob_ember_glut"
EN, GR = "mob_ember_envy", "mob_ember_greed"
VANITY, MEL, PRIDE = "elite_ember_vanity", "elite_ember_melancholy", "elite_ember_pride"
DRAGON = "boss_ember_dragon"
# 第一章-B·蓝之章的机械造物(2026-10-07)：哨戒炮台 / 增幅中继 / 场域载具 / 突击仿生人
SG, RX, HV, AX = "mob_sg_sentry", "mob_rx_relay", "mob_hv_carrier", "mob_ax_assault"


def F(req, extra=(), w=1):
    return {"w": w, "req": list(req), "extra": list(extra)}


CH1_RED = {
    "id": "ch1_red", "chapter_no": 1, "color": "red", "theme": "red", "ui_theme": "ember", "map_kind": "grid", "branch": "red",
    "truck_damage_base": 3, "loot_guarantee": {},
    "material_weights": {"red": 2, "green": 1, "blue": 1},        # 红之章的晶球里燃素多一些
    "grid": {"w": 7, "h": 6, "mask": "band", "nodes": 25, "loops": 4, "min_path": 7, "max_path": 9, "ap_spare": 4,
             "weights": {"fight": 46, "event": 16, "elite": 14, "rest": 8, "shop_black": 8, "shop_parts": 8},
             "min_depth": {"elite": 3, "rest": 4, "shop_black": 2, "shop_parts": 2, "event": 2},
             "min_count": {"elite": 2, "shop_black": 1, "shop_parts": 1, "event": 2},
             "max_count": {"elite": 4, "rest": 3, "shop_black": 2, "shop_parts": 2, "event": 5}},
    # (2026-10-06 按新刻度调：campaign_bench 普通作战 ~97%、强怪 ~75%、精英 ~50%、首领每次 ~50%、整章通关 ~93%)
    "intensity": {"base": 11, "per_depth": 3.0, "max": 36, "jitter": 0.10, "elite_bonus": 12, "boss": 43, "hunt": 54,
                  # 强怪：离起点的步数 > 首领步数 × from 的普通作战，chance 的几率再加 bump 级强度(闭区间随机)
                  "strong": {"chance": 0.35, "from": 0.5, "bump": [4, 7]}},
    # 强度点数(2026-10-06 标定，tools/fit_power.py：6 套参考阵容 × 约 1.5 万场随机配怪 / 游戏配怪，倍率 0.6~2.4 的场次)：
    #   余烬 + 精英 / 首领的本体(head = 用 head_star_power 的星级系数)。锚点：愤怒的余烬 1 星 = 3.6。
    #   贪婪的余烬拟合出来 ≈ 0(它会吞掉周围所有单位身上的【燃烧】，包括我方身上的，等于帮我方解了燃烧)，保底给 1.0，免得被当成白送的怪
    "monsters": {WR: {"power": 3.6}, SL: {"power": 3.26}, LU: {"power": 3.45}, GL: {"power": 8.85}, EN: {"power": 3.29}, GR: {"power": 1.0},
                 VANITY: {"power": 29.5, "head": True}, MEL: {"power": 12.4, "head": True}, PRIDE: {"power": 12.4, "head": True},
                 DRAGON: {"power": 35.6, "head": True}},
    "star_power": {"1": 1.0, "2": 1.61, "3": 2.12},
    "head_star_power": {"1": 1.0, "2": 1.53},
    "scale_exp": 1.08,                               # 生命 / 攻击同乘 m 时点数 × m^scale_exp
    "max_star": [[0, 1], [18, 2], [34, 3]],          # [强度下限, 允许的最高星级](2 星放到 18：弱阵容遇到第一只 2 星的那一下比点数说的更疼，晚点出现曲线更平)
    # 阵型(一张表；必备的怪 1 星放得下才会被挑中，所以强度低时只有两只怪起步的阵型)：
    #   两只起步的基础组合；三四只起步的是互相配合的组合(愤怒点火 + 怠惰吞火、色欲缠人 + 愤怒引爆、暴食喷油 + 怠惰…、
    #   愤怒点火 + 贪婪吞火群攻、暴食挡在前面 + 两只嫉妒盯着我方输出最高的人)
    "formations": [F([LU, WR], [GL, SL]), F([GL, SL], [LU, WR]), F([LU, LU], [WR, GL]), F([GL, WR], [SL, LU]),
                   F([LU, EN], [GL, GR]), F([GL, GR], [WR, EN]),
                   F([WR, WR, SL], [GL, LU]), F([LU, LU, WR], [GL, SL]), F([GL, GL, SL], [WR, LU]), F([WR, SL, LU, GL], [LU, WR]),
                   F([WR, GR, GL], [LU, EN]), F([GL, EN, EN], [LU, GR])],
    "regions": [["n", "nw", "ne", "n", "nw", "ne"], ["nw", "ne", "n", "nw", "ne", "n"], ["w", "e", "nw", "ne", "w", "e"],
                ["n", "ne", "e", "n", "ne", "e"], ["n", "nw", "w", "n", "nw", "w"]],
    # 精英：本体的点数在 monsters 里(和余烬同一个刻度)，其余用余烬补齐(forms = 这只精英自己的阵型)；
    #   本体点数放得下的精英才会出现；2 星本体的点数 ≤ 强度 × elite_star2_share 时出 2 星(忧郁 / 傲慢约 24 起，虚荣约 56 起)
    #   忧郁 / 傲慢的余烬本体占得少、靠手下打：忧郁挡在前面配远程的小怪，傲慢自己会召唤，配近战的小怪护着她
    # 首领 / 追猎：龙的余烬，solo = 没有手下(纯单体战斗：龙按倍率放大到正好等于首领 / 追猎的战斗强度)
    "elites": [{"unit": VANITY},
               {"unit": MEL, "forms": [F([EN, GR], [WR, SL, EN]), F([SL, WR], [EN, GR, WR]), F([EN, WR], [GR, SL, EN])]},
               {"unit": PRIDE, "forms": [F([LU, GL], [EN, WR]), F([GL, EN], [LU, GR]), F([LU, WR], [GL, SL])]}],
    "elite_star2_share": 0.8,
    "boss": {"unit": DRAGON, "star": 1, "solo": True},
    "hunt": {"unit": DRAGON, "star": 2, "region": "s", "solo": True},
    "income": {"fight": 3, "elite": 4, "boss": 0, "hunt": 0},
    # 普通作战的晶球：普通 1 白，强怪 1 蓝(开局送了空白节点 + 打工小帮手，这里少一个白)；精英 / 首领的手下 1 蓝
    "orb_drops": {"weak": ["white"], "strong": ["blue"], "minions": ["blue"]},
    "rest": {"repair_pct": 0.30, "upgrade_max_cost": 3},      # 修整：回复卡车耐久 30%，或把一个 1 星棋子升到 2 星(本章最多 3 费)
    "battle_map": {
        "fight": {"low": 3, "high": 2, "burning": 1, "embers": 3},          # 普通作战(含强怪)
        "elite": {"low": 2, "high": 3, "burning": 3, "embers": 4},
        "boss": {"low": 2, "high": 2, "burning": 2, "embers": 6},
        "hunt": {"low": 2, "high": 2, "burning": 2, "embers": 8},
    },
    # 两种商店(对应黑流树海的「诡意行商」与「秘境行商」)。都用金币，都能反复进入；刷新 2 金起、每次 +2，每次进店最多刷新 3 次
    "shops": {
        "shop_black": {"weapons": 3, "weapon_max_cost": 4, "parts": 1, "repair": {"amount": 15, "price": 4},
                       "weapon_price": {"1": 3, "2": 5, "3": 7, "4": 9}, "refresh": [2, 2, 3]},
        "shop_parts": {"parts": 4, "sell_ratio": 0.5, "refresh": [2, 2, 3]},
    },
    # 打倒首领(或赢下追猎) → 第二章：紫之章(2-A)；黄之章 / 青之章(2-B / 2-C)尚未制作
    "next": {"branches": [{"id": "ch2_purple", "available": True}, {"id": "ch2_yellow", "available": False}, {"id": "ch2_cyan", "available": False}]},
}

# ---------------------------------------------------------------- 第二章-A：紫之章(2026-10-06，先做地图；怪物用红之章的占位)
# 云海上的和风空岛(紫色的夜)：大地图 = 椭圆形的方格网空岛(ChapterMap mask = island)，首领在岛正中央(巨大的紫色冰山)，
#   一道斜着的巨大剑痕把岛切成两半(scar)，只在 2 座桥(固定的过河点)相通；起点在岛边缘、剑痕的另一侧；北方九条巨大的冰质狐狸尾巴(表现层)。
# 地形效果主题 = 寒气：战斗地图上的障碍是坚冰(ICE_LOW / ICE_HIGH，和死灰废墟一样没有效果)，寒雾地块(frost)站上去每秒一个【寒气】
#   (每个攻速 -10%，合计超过 40% → 冻结 5 秒；寒气持续 FROST_CHILL 秒 → 一直站着第 5 秒会冻住)。
# 怪物 / 精英 / 首领 / 阵型：先直接用红之章的(占位)，强度刻度接在红之章之后(红之章普通作战最高 36、首领 43)。
CH2_PURPLE = dict(CH1_RED)
CH2_PURPLE.update({
    "id": "ch2_purple", "chapter_no": 2, "color": "purple", "theme": "purple", "ui_theme": "frost", "branch": "purple", "overworld": "island",
    "truck_damage_base": 4,
    "material_weights": {"red": 2, "green": 1, "blue": 2},        # 紫 = 红 + 蓝：燃素和液态负熵多一些
    "grid": {"w": 9, "h": 9, "mask": "island", "scar": {"bridges": 2}, "mountain": {"ring": 4}, "nodes": 30, "loops": 5, "min_path": 10, "max_path": 15, "ap_spare": 4,
             "weights": {"fight": 46, "event": 16, "elite": 14, "rest": 8, "shop_black": 8, "shop_parts": 8},
             "min_depth": {"elite": 3, "rest": 4, "shop_black": 2, "shop_parts": 2, "event": 2},
             "min_count": {"elite": 3, "shop_black": 1, "shop_parts": 1, "event": 2},
             "max_count": {"elite": 5, "rest": 3, "shop_black": 2, "shop_parts": 2, "event": 5}},
    "intensity": {"base": 30, "per_depth": 3.0, "max": 62, "jitter": 0.10, "elite_bonus": 14, "boss": 72, "hunt": 88,
                  "strong": {"chance": 0.35, "from": 0.5, "bump": [4, 7]}},
    "max_star": [[0, 1], [30, 2], [50, 3]],
    "hunt": {"unit": DRAGON, "star": 2, "region": "s", "solo": True},
    "battle_map": {
        "fight": {"low": 3, "high": 2, "frost": 3},
        "elite": {"low": 2, "high": 3, "frost": 4},
        "boss": {"low": 2, "high": 2, "frost": 6},
        "hunt": {"low": 2, "high": 2, "frost": 8},
    },
    "next": "",                                    # 第三章尚未制作
})

# ---------------------------------------------------------------- 第一章-B·蓝之章(2026-10-07：先做地图)
# 蓝色穹顶包围的"箱庭"——穹顶下一座未来风的科幻都市；蓝色靠穿过穹顶的光来表现(World 的 blue 主题 + 大地图上的光柱)。
# 方格网：圆形的轮廓(mask = dome)，首领在最北(城北巨大的未来风信标 sf_beacon 之下)，起点在最南的边缘。
# 战斗地图：科技障碍(TECH_LOW / TECH_HIGH：花坛 / 货箱 / 长凳 / 光栅 / 立柱 / 全息亭 / 机柜 / 门架)，没有地形效果(主题待定)。
# 怪物 / 精英 / 首领 / 阵型 / 强度：和红之章一样(占位)，它是第一章的另一条分支。
CH1_BLUE = dict(CH1_RED)
CH1_BLUE.update({
    "id": "ch1_blue", "chapter_no": 1, "color": "blue", "theme": "blue", "ui_theme": "dome", "branch": "blue", "overworld": "dome",
    "material_weights": {"red": 1, "green": 1, "blue": 2},        # 蓝之章的晶球里液态负熵多一些
    # 怪物(第一版 4 只普通怪物；精英 / 首领仍是红之章的占位，手下换成机械造物)：点数由 tools/fit_power.py 标定(2026-10-07，
    #   3 套参考阵容 × 红 / 蓝 × 随机 / 游戏配怪约 2500 场，锚点仍是愤怒的余烬 3.6)。按红之章同类估的第一版(3.5 / 3.0 / 7.6 / 3.6)把载具高估了一倍多、
    #   中继拟合 ≈ 0(所以中继改 +2 / 6 米、载具改投射力场后再标)。拟合值(2.7 / 1.9 / 3.0 / 4.3)让参考阵容在蓝之章只过 70(红之章 89)——
    #   拟合的 gamma / 星级系数和章节常量不同，刻度偏紧——按 89/70 整体乘 1.27 对齐到红之章的刻度(比例照拟合)。
    "monsters": {SG: {"power": 3.4}, RX: {"power": 2.4}, HV: {"power": 3.8}, AX: {"power": 5.5},
                 VANITY: {"power": 29.5, "head": True}, MEL: {"power": 12.4, "head": True}, PRIDE: {"power": 12.4, "head": True},
                 DRAGON: {"power": 35.6, "head": True}},
    # 阵型：输出终端(炮台 / 突击) + 增幅来源(中继 / 载具)的组合——两只起步的基础组合，三四只起步的是"来源 + 终端"的配合
    "formations": [F([AX, SG], [RX, HV]), F([SG, RX], [AX, HV]), F([AX, AX], [SG, RX]), F([HV, SG], [AX, RX]), F([RX, HV], [SG, AX]),
                   F([AX, SG, RX], [HV, AX]), F([SG, SG, RX], [HV, AX]), F([AX, AX, HV], [RX, SG]), F([HV, RX, SG], [AX, AX]),
                   F([AX, SG, RX, HV], [AX, SG])],
    "elites": [{"unit": VANITY},
               {"unit": MEL, "forms": [F([RX, SG], [AX, HV, SG]), F([SG, AX], [RX, HV, SG]), F([RX, AX], [SG, HV, AX])]},
               {"unit": PRIDE, "forms": [F([AX, HV], [RX, SG]), F([SG, RX], [AX, HV]), F([AX, SG], [HV, RX])]}],
    "grid": {"w": 9, "h": 9, "mask": "dome", "nodes": 28, "loops": 5, "min_path": 9, "max_path": 14, "ap_spare": 4,
             "weights": {"fight": 46, "event": 16, "elite": 14, "rest": 8, "shop_black": 8, "shop_parts": 8},
             "min_depth": {"elite": 3, "rest": 4, "shop_black": 2, "shop_parts": 2, "event": 2},
             "min_count": {"elite": 2, "shop_black": 1, "shop_parts": 1, "event": 2},
             "max_count": {"elite": 4, "rest": 3, "shop_black": 2, "shop_parts": 2, "event": 5}},
    "battle_map": {
        "fight": {"low": 3, "high": 2},
        "elite": {"low": 2, "high": 3},
        "boss": {"low": 2, "high": 2},
        "hunt": {"low": 2, "high": 2},
    },
})

# ---------------------------------------------------------------- 卡车零件(零件铺 / 黑市出售；对应黑流树海的"加工品")
# kind：ap = 立刻 +N 行动力；move = 特殊移动(跳到某个格点上的节点，可以越过未完成/未观测的节点，扣 cost 行动力)；reveal = 观测周围
#   move.shape：line = 上下左右直线 range 格以内；ring = 周围一圈 8 格
# 零件箱最多 PART_CAP 个。
PART_CAP = 5
PARTS = {
    "jerrycan": {"price": 4, "kind": "ap", "ap": 2},
    "offroad_tire": {"price": 3, "kind": "move", "shape": "line", "range": 2, "cost": 1},
    "spring_jack": {"price": 3, "kind": "move", "shape": "ring", "range": 1, "cost": 1},
    "scout_drone": {"price": 2, "kind": "reveal", "radius": 2},
}
# 卡车改装(开局三选一 + 每进一章选一项)在 tools/author_mods.py(→ mods.json)


# ---------------------------------------------------------------- 地形效果(第一章·红之章起)
# 地形只负责发事件(Battle：燃烧废墟周围每个战斗帧 OnTerrainTick[burning_ruin]，踩上余烬 OnTerrainEnter[ember]，
#   被战场机制打中 OnTerrainHit[tram / fire_arc])；
# 效果和羁绊/装备一样是"触发器 + 能力"(tag terrain_payload)，有地形的战斗里挂到每个单位(双方，含召唤物)身上。
# 【燃烧】：和怪物施加的是同一个状态(author_data.BURN)：负面、可驱散、每次施加独立计时，每秒 25 点法术伤害。
#   燃烧废墟：站在它周围时每秒被点上一个 2 秒的燃烧(一直挨着 = 身上一直有 2 个)；余烬地块：踩上去一个 5 秒的燃烧。
#   地形施加的燃烧没有施加者(sourceless)。
def BURN(dur):
    return {"status_id": "burning", "duration": float(dur), "max_stacks": 1, "independent": True, "flags": ["debuff", "burning", "dispellable"],
            "sourceless": True, "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}}


def _terrain_pair(tid, timing, tag, every, dur):
    trig = {"id": tid, "timing": timing, "event_count_threshold": every, "base_value_mode": "fixed", "base_value_flat": 0.0,
            "target_rule": "self", "team_filter": "any", "tags": ["terrain_payload", "terrain_" + tag],
            "runtime_conditions": [{"type": "event_has_tag", "tag": tag}]}
    ab = {"id": tid + "_burn", "ability_class": "blade", "effect_type": "stat_status", "value_multiplier": 1.0, "fixed_value": 0.0,
          "keywords": ["basic"], "accepted_timings": [timing], "required_trigger_tags": ["terrain_payload", "terrain_" + tag],
          "effect_config": BURN(dur), "cooldown": 0.0, "priority": 100}
    return {"trigger": trig, "ability": ab}


# 战场机制(事件战斗的专属战场，时刻表在 author_events.py 的 ARENAS.hazards)打中单位时发 OnTerrainHit[标签]：
#   伤害没有施加者(sourceless)，触发数值 = 被打中的单位自己的 最大生命 × ratio + flat
def _terrain_hit(tid, tag, kind, ratio, flat):
    trig = {"id": tid, "timing": "OnTerrainHit", "event_count_threshold": 1, "base_value_mode": "max_health_ratio",
            "base_value_ratio": ratio, "base_value_flat": flat,
            "target_rule": "self", "team_filter": "any", "tags": ["terrain_payload", tid],
            "runtime_conditions": [{"type": "event_has_tag", "tag": tag}]}
    ab = {"id": tid + "_dmg", "ability_class": "blade", "effect_type": kind + "_damage", "value_multiplier": 1.0, "fixed_value": 0.0,
          "keywords": ["basic"], "accepted_timings": ["OnTerrainHit"], "required_trigger_tags": ["terrain_payload", tid],
          "effect_config": {"sourceless": True}, "cooldown": 0.0, "priority": 110}
    return {"trigger": trig, "ability": ab}


TRAM_HIT = {"ratio": 0.2, "flat": 120.0, "burn": 4.0}      # 被电车撞：物理伤害 = 20% 最大生命 + 120，再【燃烧】4 秒
FIRE_ARC_HIT = {"flat": 80.0}                              # 被喷泉的火弧砸中：80 点法术伤害(落点同时重新烧成余烬地块)
FROST_CHILL = 4.5                                          # 寒雾地块：站在上面每秒一个 4.5 秒的【寒气】(第 5 秒 5 个 = 50% > 40% → 冻结)


# 【寒气】：和心音节点的演奏施加的是同一个通用状态(Effects.apply_chill 的写法)：每次施加独立计时、可驱散，每个攻速 -10%(GC.CHILL_AS)，
#   合计超过 40%(GC.FREEZE_OVER)时全部消耗变成【冻结】5 秒(GC.FREEZE_DUR)。地形施加的没有施加者
def CHILL(dur):
    return {"status_id": "chill", "duration": float(dur), "max_stacks": 1, "independent": True, "flags": ["debuff", "dispellable", "chill"],
            "sourceless": True, "stats": {"attack_speed_multiplier": {"flat": -0.10}}, "meta": {"freeze_over": 0.40, "freeze_dur": 5.0}}


def _terrain_chill(tid, timing, tag, every, dur):
    p = _terrain_pair(tid, timing, tag, every, dur)
    p["ability"]["id"] = tid + "_chill"
    p["ability"]["effect_config"] = CHILL(dur)
    return p


TERRAIN = {"pairs": [
    _terrain_pair("terrain_burning_ruin", "OnTerrainTick", "burning_ruin", 4, 2.0),   # 燃烧废墟：周围的棋子(每 4 个战斗帧 = 每秒一次)
    _terrain_pair("terrain_ember", "OnTerrainEnter", "ember", 1, 5.0),                # 余烬地块：踩上去的棋子(然后余烬熄灭)
    _terrain_hit("terrain_tram_hit", "tram", "physical", TRAM_HIT["ratio"], TRAM_HIT["flat"]),
    _terrain_pair("terrain_tram", "OnTerrainHit", "tram", 1, TRAM_HIT["burn"]),
    _terrain_hit("terrain_fire_arc_hit", "fire_arc", "magic", 0.0, FIRE_ARC_HIT["flat"]),
    _terrain_chill("terrain_frost", "OnTerrainTick", "frost", 4, FROST_CHILL),         # 寒雾地块(紫之章)：站在上面的棋子每秒一个【寒气】
]}


# ---------------------------------------------------------------- 车间(装备制造) → game/data/workshop.json
# 三种材料(内部名 = 颜色)：red 燃素(火团) / green 有机物(发芽的种子) / blue 液态负熵(矿泉水瓶)。
# 制造：选装备种类(现在只有武器；其余种类留接口：装备数据写 "slot" = 种类 id、"weapon_class" = 门类，这里登记门类即可)，
#   再选至少 min_categories 个门类，投入 min_total ~ max_total 份材料：
#   · 颜色：三种材料的配比 p = (r, g, b) / 合计 落在三角形里；每种装备颜色有一个"理想配比"(color_mix，红绿蓝 = 三个角、
#     二次色 = 两两的中点、黑(无色，谁都能装) = 正中心)，权重 = color_prior × exp(-|p - 理想配比|² / (2 σ²))，σ = color_sigma——配比连续变化，概率也连续变化。
#   · 稀有度(= 费用)：材料合计 N 越多越贵，权重 = exp(-(费用 - μ)² / (2 rarity.sigma²))，μ = rarity.base + (N - min_total) × rarity.per_material。
#   · 只在选中门类里实际存在的(颜色, 费用)格子之间归一化，格子里的装备等概率。
# 分解：武器库里的武器拆成材料，份数 = salvage[费用]，按武器颜色的理想配比分到三种材料上。
# 材料来源：开局 start；每个晶球附带 orb_materials[晶球档位] 份(颜色按章节的 material_weights 随机，没写 = 均匀)；分解武器。
WORKSHOP = {
    "materials": ["red", "green", "blue"],
    "start": {"red": 2, "green": 2, "blue": 2},
    "orb_materials": {"white": 1, "blue": 2, "gold": 3, "rainbow": 6},
    "kinds": [
        {"id": "weapon", "categories": ["sword", "heavy", "polearm", "dual", "bow", "crossbow", "rifle", "pistols", "focus"], "min_categories": 3},
        {"id": "gear", "categories": [], "min_categories": 3, "locked": True},     # 武器以外的装备：尚未制作，留接口
    ],
    "min_total": 3, "max_total": 30,
    "color_mix": {"red": [1, 0, 0], "green": [0, 1, 0], "blue": [0, 0, 1],
                  "yellow": [0.5, 0.5, 0], "purple": [0.5, 0, 0.5], "cyan": [0, 0.5, 0.5],
                  "black": [0.3333, 0.3333, 0.3333], "white": [0.3333, 0.3333, 0.3333]},
    "color_sigma": 0.35,
    "color_prior": {"black": 0.6, "white": 0.25},   # 黑色武器谁都能装，压低一点；白色(只有白色节点能装)和黑色一样在正中间，再低一些
    "rarity": {"base": 1.0, "per_material": 1.0 / 7.0, "sigma": 0.55},
    "salvage": {"1": 2, "2": 4, "3": 7, "4": 10, "5": 13},
}


# ---------------------------------------------------------------- 晶球掉落表
# 每项：w = 权重；gold = 金币；unit_cost = 一个该费用的随机节点；weapon_max_cost = 一把费用不超过它的随机武器(不含基础武器)
LOOT = {"orbs": {
    "white": [{"w": 35, "gold": 2}, {"w": 20, "gold": 3}, {"w": 30, "unit_cost": 1}, {"w": 15, "weapon_max_cost": 1}],
    "blue": [{"w": 25, "gold": 5}, {"w": 25, "unit_cost": 2}, {"w": 40, "weapon_max_cost": 2}, {"w": 10, "gold": 2, "unit_cost": 1}],
    "gold": [{"w": 20, "gold": 10}, {"w": 30, "unit_cost": 3}, {"w": 35, "weapon_max_cost": 3}, {"w": 15, "gold": 3, "weapon_max_cost": 2}],
    # 彩色晶球：只有打工小帮手有极小的概率做出来(0.05%)
    "rainbow": [{"w": 50, "gold": 8, "weapon_max_cost": 4}, {"w": 50, "gold": 8, "unit_cost": 3}],
}}


def main():
    d = os.path.join(ROOT, "chapters")
    os.makedirs(d, exist_ok=True)
    for ch in [CH0, CH1_RED, CH1_BLUE, CH2_PURPLE]:
        with open(os.path.join(d, ch["id"] + ".json"), "w", encoding="utf-8") as f:
            json.dump(ch, f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, "loot.json"), "w", encoding="utf-8") as f:
        json.dump(LOOT, f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, "terrain.json"), "w", encoding="utf-8") as f:
        json.dump(TERRAIN, f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, "workshop.json"), "w", encoding="utf-8") as f:
        json.dump(WORKSHOP, f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, "meta.json"), "w", encoding="utf-8") as f:
        json.dump({"parts": PARTS, "part_cap": PART_CAP}, f, ensure_ascii=False, indent=1)
    old = os.path.join(ROOT, "waves.json")
    if os.path.exists(old):
        os.remove(old)


if __name__ == "__main__":
    main()
