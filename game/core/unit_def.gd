class_name UnitDef
extends RefCounted
## 棋子定义：数值 + 触发器(触发面) + 被动能力 + 武器(基础武器大类/可用大类) + 3D 表现(尺寸/副手/模型/发色/肤色) + AI 风格。

var reworked: bool = false            # 按新设计重构过(图鉴只收录这些)
var attack_as_ap: bool = false        # 模版给的攻击力 1:1 转成法术强度(攻击力 = 0)
var first_star: bool = false          # 初星系节点：会尝试召唤护星节点的棋子 + 护星节点本人(和星节点的"初星之光"、"监护人的微笑"认这个)
var sky_caster: bool = false          # 天降流星施法者：不能移动；能打任何队友射程内的敌人；无视掩体；普攻是从天上落下的流星
var na_scaling: String = ""           # "ability_power"：普攻的触发数值按法术强度算
var na_aim: String = ""               # 普攻前再瞄准的被动(能力 id；屏息节点·瞄准眉心)：普攻额外带【吟唱】= 这个被动的吟唱数
var anim_overrides: Dictionary = {}   # 武器大类 -> {idle/run/attack: 动画名}(替换这个棋子用这类武器时的动作)
var chant_fx: Dictionary = {}         # 吟唱的表现：能力 id -> {anim, pull_anim, prop, min_star}(追猎节点：意外渔获解锁后，猎人笔记换成钓鱼)
var phantom_fx: Dictionary = {}       # 开战后身后的光之虚影(正行节点·百合骑士的骑士)：{trigger, color, min_interval, back, lift, scale}；只是表现
var trigger_fx: Dictionary = {}       # 触发器真的触发时的表现：触发器 id -> {anim(本人放一次的动作), fx(Fx 里的演法：recite …), color}；只是表现
var hit_fx: String = ""              # 普攻命中的表现(iaido = 拔刀术：一刀一道剑光，追击副本不飘"追击")
var wclass_overrides: Dictionary = {} # 武器大类 -> {interval/windup/recover/copy_delay…}：这个棋子用这类武器时的普攻节奏(跟着他自己的攻击动画；炽照节点的拔刀连斩)
var equip_rules: Dictionary = {}      # {unlock_star, extra_colors[], forbid_classes[]}：到星级后额外能装的颜色 / 不能装的结算规则
var projectile: String = ""           # 远程普攻的投射物外观(空 = 按武器大类)；怪物用：余烬的火弹
var hide_weapon: bool = false         # 不显示手里的武器(武器长在身体上的怪物：手里的火、手臂炮、触手、大嘴)
var weapon_look: String = ""          # 拿基础武器时显示的武器外观(W_<大类>_<外观>；龙的余烬的熔岩薙刀)：怪物自己的武器，不是一件装备
var prep_items: Array[String] = []     # 备战时在场上就往武器库里放的特殊物品(狩胜节点 → 狩猎旗标)；同一件只放一个
var free_deploy: bool = false          # 上场不占队伍的上阵人数(空白节点)
var bench_traits: bool = false         # 在仓库里也计入羁绊人数(星旅节点·渡星而来)
var bench_drop: bool = false           # 战斗开始时，场上没有同名棋子就从仓库坠落到敌人最密集的地方(星旅节点·渡星而来；Run.starfall_unit)
var deploy_anywhere_star: int = 0      # 到这个星级起，备战时可以部署到战场上任何没有地形的格子(浪游节点·随心所欲 = 2)；0 = 只能在部署区
var unique: bool = false               # 唯一：场上不能同时有两个(真望节点)；Run.move_unit 拒绝并提示"该节点是唯一的"
var deploy_near_enemies: bool = false  # 只能部署在任意敌人(出生点)周围一圈的格子，取代部署区(幻形节点·千变万化)
var id: String = ""
var cost: int = 1
var role: String = "warrior"           # archer / warrior / tank / caster / support / assassin
var faction_id: String = "white"
var profession_id: String = ""
var special_traits: Array[String] = []
var base_weapon_class: String = "sword"   # 没装备武器时自动装备的"基础武器"大类(GC.WEAPON_CLASSES)
var weapon_classes: Array[String] = []  # 允许装备的武器大类；空 = 不限
var offhand: String = ""               # 副手外观："shield" = 用单手武器时左手持盾(长枪 / 法器也单手拿：武器大类有 guard_anims 时)；"tower" = 大盾(有 tower_anims 时)；
                                      # 别的名字 = 自己的盾(套件里的 Shield_<名字>：正行节点的百合盾 lily)
var model: String = ""                 # 专属身体模型(tools/chars/<model>.gd → assets/unit_body_<model>.res)；空 = 通用模型
var hair: String = ""                  # 发色("#rrggbb")，必须属于本单位的色系；空 = 按 id 在本色系色板里挑(GC.hair_color_of)
var skin: String = "fair"              # 肤色键(GC.SKIN_TONES)
var scale: float = 1.0
var radius: float = 0.42
var target_priority: String = "nearest"
var base_stats: StatBlock = StatBlock.new()
var star_scaling_stats: Array = GC.STAR_SCALING_STATS
var triggers: Array[TriggerDef] = []
var passives: Array[AbilityDef] = []
var normal_attack: AbilityDef = null   # 自定义普攻(例如护士治疗)；null=默认物理普攻
var available_in_shop: bool = true
var summon_only: bool = false
var ai_style: String = ""              # 空=按 role 推断
var ai: Dictionary = {}                # 覆盖参数：kite_radius 等
var strings_key: String = ""           # 本地化前缀，默认 unit.<id>
## 形态(变奏节点·表里之间)：形态名 -> {profession_id, model, weapon_models, weapon_names}；空 = 没有形态。
## 每个形态是一个派生的 UnitDef(form_def：同一个 id、共用触发器 / 被动 / 数值，只换部门、身体、武器外观与名字)，
## 羁绊、外观、提示卡拿到哪个形态的 def 就按哪个形态算
var forms: Dictionary = {}
var form: String = ""                   # 这个 def 是哪个形态(没有形态 = "")
var form_default: String = ""
var weapon_models: Dictionary = {}      # 装备 id -> 外观：她本人拿这件武器时的样子(变奏节点：黑键 → 大三角钢琴)
var weapon_names: Dictionary = {}       # 装备 id -> 名字的本地化键(equip.<键>.name)：她本人拿这件武器时的叫法(天使形态：白键)
var _form_cache: Dictionary = {}


static func from_dict(d: Dictionary) -> UnitDef:
	var u := UnitDef.new()
	u.projectile = str(d.get("projectile", ""))
	u.hide_weapon = bool(d.get("hide_weapon", false))
	u.weapon_look = str(d.get("weapon_look", ""))
	u.id = str(d.get("id", ""))
	u.cost = int(d.get("cost", 1))
	u.role = str(d.get("role", "warrior"))
	u.faction_id = str(d.get("faction_id", "white")).to_lower()
	u.profession_id = str(d.get("profession_id", GC.PROFESSION_BY_ROLE.get(u.role, "")))
	u.special_traits = TriggerDef._strings(d.get("special_trait_ids", []))
	u.prep_items = TriggerDef._strings(d.get("prep_items", []))
	u.free_deploy = bool(d.get("free_deploy", false))
	u.deploy_anywhere_star = int(d.get("deploy_anywhere_star", 0))
	u.deploy_near_enemies = bool(d.get("deploy_near_enemies", false))
	u.unique = bool(d.get("unique", false))
	u.bench_traits = bool(d.get("bench_traits", false))
	u.bench_drop = bool(d.get("bench_drop", false))
	u.base_weapon_class = str(d.get("base_weapon_class", "sword"))
	u.weapon_classes = TriggerDef._strings(d.get("weapon_classes", []))
	u.offhand = str(d.get("offhand", ""))
	u.model = str(d.get("model", ""))
	u.reworked = bool(d.get("reworked", false))
	u.attack_as_ap = bool(d.get("attack_as_ap", false))
	u.first_star = bool(d.get("first_star", false))
	u.sky_caster = bool(d.get("sky_caster", false))
	u.na_scaling = str(d.get("na_scaling", ""))
	u.na_aim = str(d.get("na_aim", ""))
	u.anim_overrides = (d.get("anim_overrides", {}) as Dictionary).duplicate(true)
	u.wclass_overrides = (d.get("wclass_overrides", {}) as Dictionary).duplicate(true)
	u.hit_fx = str(d.get("hit_fx", ""))
	u.chant_fx = (d.get("chant_fx", {}) as Dictionary).duplicate(true)
	u.phantom_fx = (d.get("phantom_fx", {}) as Dictionary).duplicate(true)
	u.trigger_fx = (d.get("trigger_fx", {}) as Dictionary).duplicate(true)
	u.equip_rules = (d.get("equip_rules", {}) as Dictionary).duplicate(true)
	u.hair = str(d.get("hair", ""))
	u.skin = str(d.get("skin", "fair"))
	u.scale = float(d.get("scale", 1.0))
	u.radius = float(d.get("radius", 0.42)) * u.scale
	u.target_priority = str(d.get("target_priority", "nearest"))
	u.base_stats = StatBlock.from_dict(d.get("base_stats", {}))
	var sc: Variant = d.get("star_scaling_stats", null)
	if sc is Array:
		u.star_scaling_stats = sc
	u.available_in_shop = bool(d.get("available_in_shop", true))
	u.summon_only = bool(d.get("summon_only", false))
	u.ai_style = str(d.get("ai_style", ""))
	var ai: Variant = d.get("ai", {})
	if ai is Dictionary:
		u.ai = (ai as Dictionary).duplicate(true)
	for t: Variant in d.get("triggers", []):
		if t is Dictionary:
			u.triggers.append(TriggerDef.from_dict(t as Dictionary))
	for p: Variant in d.get("passive_abilities", []):
		if p is Dictionary:
			u.passives.append(AbilityDef.from_dict(p as Dictionary))
	var na: Variant = d.get("normal_attack_ability", null)
	if na is Dictionary:
		u.normal_attack = AbilityDef.from_dict(na as Dictionary)
	u.strings_key = "unit.%s" % u.id
	u.forms = (d.get("forms", {}) as Dictionary).duplicate(true)
	if not u.forms.is_empty():
		u.form_default = str(d.get("form_default", u.forms.keys()[0]))
		u._apply_form(u.form_default)
	return u


## 这个形态的 def(没有形态 / 名字不对 / 就是自己这个形态 → 自己)。派生的 def 浅拷贝所有字段(触发器、被动、数值是同一份)
func form_def(f: String) -> UnitDef:
	if forms.is_empty() or f == "" or f == form or not forms.has(f):
		return self
	var root: UnitDef = self
	if _form_cache.has(f):
		return _form_cache[f]
	var v := UnitDef.new()
	for p: Dictionary in get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(p["name"]) != "_form_cache":
			v.set(str(p["name"]), get(str(p["name"])))
	v._form_cache = _form_cache                 # 几个形态共用一个缓存(互相切换不会越派生越多)
	if not _form_cache.has(form):
		_form_cache[form] = root
	v._apply_form(f)
	_form_cache[f] = v
	return v


## 另一个形态(两个形态的棋子：变奏节点 恶魔 ↔ 天使)
func other_form() -> String:
	for k: Variant in forms.keys():
		if str(k) != form:
			return str(k)
	return form


func _apply_form(f: String) -> void:
	var fd: Dictionary = forms.get(f, {})
	form = f
	if fd.has("profession_id"):
		profession_id = str(fd["profession_id"])
	if fd.has("model"):
		model = str(fd["model"])
	weapon_models = (fd.get("weapon_models", {}) as Dictionary).duplicate()
	weapon_names = (fd.get("weapon_names", {}) as Dictionary).duplicate()


func stats_for_star(star: int) -> StatBlock:
	var s: StatBlock = base_stats.scaled_for_star(star, star_scaling_stats)
	if attack_as_ap:
		s.ability_power += s.attack_power         # 攻击力(已按星级缩放)1:1 转成法术强度
		s.attack_power = 0.0
	return s


func can_use_weapon_class(cls: String) -> bool:
	return weapon_classes.is_empty() or weapon_classes.has(cls)


## AI 风格：显式 ai_style 优先；辅助/刺客按职业；其余由"手里的武器"决定近战还是远程
func style_for_weapon(ranged: bool) -> String:
	if ai_style != "":
		return ai_style
	match role:
		"support":
			return "support"
		"assassin":
			return "assassin"
	return "ranged" if ranged else "melee"


func base_weapon_ranged() -> bool:
	return bool(wclass_for(base_weapon_class).get("ranged", false))


## 被动里【溅射 N】的半径(米)：第一个带溅射的被动(星旅节点·渡星而来的坠落范围；战斗里用 Pipeline.passive_splash_radius，带关键词修正)
func passive_splash_radius(star: int) -> float:
	for pa: AbilityDef in passives:
		if pa.has_keyword("splash"):
			return maxf(0.1, pa.keyword_value_f("splash", star, 1.0)) * GC.SPLASH_M_PER_POINT
	return 0.0


## 这个棋子用某个武器大类时的参数：GC.WEAPON_CLASSES 并上自己的 wclass_overrides(清扫节点的双持近战 = 远程飞刀)
func wclass_for(cls: String) -> Dictionary:
	var wc: Dictionary = GC.weapon_class(cls)
	if wclass_overrides.has(cls):
		wc = wc.duplicate()
		wc.merge(wclass_overrides[cls], true)
	return wc


## 拿着这把武器时算不算远程(单位自己的 wclass_overrides 可以把近战武器改成远程)
func ranged_with(w: EquipmentDef) -> bool:
	return w != null and bool(wclass_for(w.class_id).get("ranged", false))


func validate() -> Array[String]:
	var errs: Array[String] = []
	if id == "":
		errs.append("unit id is required")
	if not GC.FACTIONS.has(faction_id):
		errs.append("unit %s: unknown faction %s" % [id, faction_id])
	if base_weapon_class != "" and not GC.WEAPON_CLASSES.has(base_weapon_class):
		errs.append("unit %s: unknown base weapon class %s" % [id, base_weapon_class])
	for wc: String in weapon_classes:
		if not GC.WEAPON_CLASSES.has(wc):
			errs.append("unit %s: unknown weapon class %s" % [id, wc])
	if base_weapon_class != "" and not can_use_weapon_class(base_weapon_class):
		errs.append("unit %s: base weapon class %s is not in its allowed classes" % [id, base_weapon_class])
	if base_stats.max_health <= 0.0:
		errs.append("unit %s: max_health must be positive" % id)
	if hair != "":
		if not Color.html_is_valid(hair):
			errs.append("unit %s: bad hair color %s" % [id, hair])
		elif GC.FACTIONS.has(faction_id) and GC.color_family(Color(hair)) != faction_id:
			errs.append("unit %s: hair %s is %s, not in its color family %s" % [id, hair, GC.color_family(Color(hair)), faction_id])
	if not GC.SKIN_TONES.has(skin):
		errs.append("unit %s: unknown skin tone %s" % [id, skin])
	for t: TriggerDef in triggers:
		errs.append_array(t.validate())
	for tfk: Variant in trigger_fx.keys():
		if not triggers.any(func(t1: TriggerDef) -> bool: return t1.id == str(tfk)):
			errs.append("unit %s: trigger_fx for %s, which is not one of its triggers" % [id, str(tfk)])
	if not phantom_fx.is_empty():
		var pt: String = str(phantom_fx.get("trigger", ""))
		if not triggers.any(func(t0: TriggerDef) -> bool: return t0.id == pt):
			errs.append("unit %s: phantom_fx trigger %s is not one of its triggers" % [id, pt])
	for a: AbilityDef in passives:
		errs.append_array(a.validate())
		var paired := false
		for t2: TriggerDef in triggers:
			if t2.can_pair(a):
				paired = true
				break
		# 改写普攻载荷的被动(na_aim：瞄准眉心给普攻加【吟唱】)由每个棋子自带的普攻触发器带动，不需要自己的触发器
		if not paired and a.id != na_aim:
			errs.append("unit %s: passive %s is not pairable with any of the unit's triggers (effects must be triggered)" % [id, a.id])
	if not summon_only and triggers.is_empty():
		errs.append("unit %s: has no trigger surface" % id)
	return errs


## 按 id 找被动能力(不管有没有解锁)
func passive_by_id(aid: String) -> AbilityDef:
	for a: AbilityDef in passives:
		if a.id == aid:
			return a
	return null
