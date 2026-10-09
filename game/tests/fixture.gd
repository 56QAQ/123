class_name Fixture
extends RefCounted
## 测试夹具：造"木桩"单位、快速搭建战斗。

static var _cat: Catalog = null


static func catalog() -> Catalog:
	if _cat == null:
		_cat = Catalog.load_all()
		# 木桩：血厚、零抗性、空手(没有基础武器 = 永不攻击)，用来精确测量伤害/治疗数值
		_cat.units["test_dummy"] = UnitDef.from_dict({
			"id": "test_dummy", "cost": 1, "role": "warrior", "base_weapon_class": "", "faction_id": "white", "available_in_shop": false,
			"base_stats": {"attack_power": 100, "defense": 0, "magic_resistance": 0, "max_health": 100000,
				"crit_chance": 0.0, "attack_base_interval_seconds": 999.0, "attack_range": 1.0, "move_speed": 0.0},
			"triggers": [{"id": "dummy_nothing", "timing": "OnBattleStart", "tags": ["none"]}]})
		# 打手：只用来"打"目标一下，攻击力可控；基础武器是长枪(普攻倍率 1.0)
		_cat.units["test_hitter"] = UnitDef.from_dict({
			"id": "test_hitter", "cost": 1, "role": "warrior", "base_weapon_class": "polearm", "weapon_classes": [], "faction_id": "white", "available_in_shop": false,
			"base_stats": {"attack_power": 100, "defense": 0, "magic_resistance": 0, "max_health": 100000,
				"crit_chance": 0.0, "attack_base_interval_seconds": 999.0, "attack_range": 1.0, "move_speed": 0.0},
			"triggers": [{"id": "hitter_nothing", "timing": "OnBattleStart", "tags": ["none"]}]})
		# 稀有度 5 的木桩(现在还没有真正的 5 费棋子)：测守誓节点的誓绶身
		_cat.units["test_rarity5"] = UnitDef.from_dict({
			"id": "test_rarity5", "cost": 5, "role": "warrior", "base_weapon_class": "", "faction_id": "white", "available_in_shop": false,
			"base_stats": {"attack_power": 100, "defense": 0, "magic_resistance": 0, "max_health": 5000,
				"crit_chance": 0.0, "attack_base_interval_seconds": 999.0, "attack_range": 1.0, "move_speed": 0.0},
			"triggers": [{"id": "r5_nothing", "timing": "OnBattleStart", "tags": ["none"]}]})
	return _cat


## 构建战斗(不 start)。spec: [{def, team, pos:Vector2, weapon:id, equipment:[id](旧写法), unarmed, star, hp_ratio, perm:{stat: v}(永恒成长)}]
## layout：战斗地图(默认没有卡车、没有障碍物的空地，方便精确测量)
static func make(specs: Array, seed_value: int = 7, layout: Dictionary = {"truck": false}, cfg_extra: Dictionary = {}) -> Battle:
	var b := Battle.new(catalog(), seed_value)
	var list: Array = []
	for s: Dictionary in specs:
		var e: Dictionary = {"def": s["def"], "team": s.get("team", 0), "star": s.get("star", 1),
			"pos": s.get("pos", Vector2.ZERO), "weapon": s.get("weapon", ""), "equipment": s.get("equipment", []),
			"unarmed": s.get("unarmed", false), "perm": s.get("perm", {})}
		for k: String in ["form", "roster_id"]:
			if s.has(k):
				e[k] = s[k]
		list.append(e)
	var cfg: Dictionary = {"potion_variance": false}
	cfg.merge(cfg_extra, true)
	b.setup({"units": list, "map": layout, "cfg": cfg})
	for i in range(specs.size()):
		var hr: float = float((specs[i] as Dictionary).get("hp_ratio", 1.0))
		if hr < 1.0:
			b.units[i].hp = b.units[i].get_stats().max_health * hr
		b.units[i].target = null
	return b


## 汇总本次事件流里某个 surface 的伤害/治疗
static func events_of(b: Battle, type: String, surface: String = "") -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in b.events:
		if e.get("t") == type and (surface == "" or e.get("surface") == surface):
			r.append(e)
	return r
