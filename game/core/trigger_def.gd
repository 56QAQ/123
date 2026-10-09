class_name TriggerDef
extends RefCounted
## 触发器：单位(或羁绊/遗物)持有的"扳机"。它只决定 何时(timing+计数) / 打谁(target_rule) / 触发值多少(base_value_*)，
## 本身不产生效果——效果来自与之配对的能力(被动/装备载荷)。配对条件见 can_pair()。

var id: String = ""
var timing: String = "OnNormalAttackHit"
var count_threshold: int = 1                    # 每第 N 次事件触发一次
var count_threshold_by_star: Dictionary = {}
var base_value_mode: String = "attack_ratio"
var base_value_ratio: float = 1.0
var ratio_by_star: Dictionary = {}
var base_value_flat: float = 0.0
var flat_by_star: Dictionary = {}
var base_value_keyword: String = ""
var base_value_stat_id: String = ""
var base_value_status_id: String = ""
var target_rule: String = "current_attack_target"
var team_filter: String = "enemy"
var target_radius: float = 0.0                  # 米
var target_sort_rule: String = ""
var max_targets: int = 0
var cooldown_seconds: float = 0.0
var max_activations: int = 0                    # 每场战斗，0=不限
var tags: Array[String] = []
var allowed_classes: Array[String] = []
var forbidden_classes: Array[String] = []
var allowed_keywords: Array[String] = []
var forbidden_keywords: Array[String] = []
var conditions: Array[Dictionary] = []
## 备选触发条件：计数还没到时，这组条件全部满足也触发(例如"每第 3 次命中，或装弹后的第一次命中")
var alt_conditions: Array[Dictionary] = []
var unlock_star: int = 1                        # 棋子达到这个星级才有这个触发器(被动 2 = 2 星解锁)
## 候选目标的过滤：{"has_status": id} 只要身上有这个状态的 / {"missing_status": id} 只要没有的
var target_filter: Dictionary = {}
## 时机自己的参数(OnEnemyNear：{"linger": 2.0} 敌人在范围里停留满几秒再发一次；范围 = target_radius)
var extra: Dictionary = {}
var fit: Dictionary = {}                       # 武器触发器的内置适配标签 {side, count, freq}(FitTags；单位数据 fit_tags)


static func from_dict(d: Dictionary) -> TriggerDef:
	var t := TriggerDef.new()
	t.id = str(d.get("id", ""))
	t.timing = str(d.get("timing", "OnNormalAttackHit"))
	var ft: Variant = d.get("fit_tags", {})
	if ft is Dictionary:
		t.fit = (ft as Dictionary).duplicate()
	t.count_threshold = maxi(1, int(d.get("event_count_threshold", d.get("count_threshold", 1))))
	t.count_threshold_by_star = _int_dict(d.get("event_count_threshold_by_star", {}))
	t.base_value_mode = str(d.get("base_value_mode", "attack_ratio"))
	t.base_value_ratio = float(d.get("base_value_ratio", 1.0))
	t.ratio_by_star = _float_dict(d.get("base_value_ratio_by_star", {}))
	t.base_value_flat = float(d.get("base_value_flat", 0.0))
	t.flat_by_star = _float_dict(d.get("base_value_flat_by_star", {}))
	t.base_value_keyword = str(d.get("base_value_keyword", ""))
	t.base_value_stat_id = str(d.get("base_value_stat_id", ""))
	t.base_value_status_id = str(d.get("base_value_status_id", ""))
	t.target_rule = str(d.get("target_rule", "current_attack_target"))
	t.team_filter = str(d.get("team_filter", "enemy"))
	t.target_radius = float(d.get("target_radius", 0.0))
	t.target_sort_rule = str(d.get("target_sort_rule", ""))
	t.target_filter = (d.get("target_filter", {}) as Dictionary).duplicate()
	t.extra = (d.get("extra", {}) as Dictionary).duplicate(true)
	t.max_targets = int(d.get("max_targets", 0))
	if d.has("cooldown_seconds"):
		t.cooldown_seconds = float(d["cooldown_seconds"])
	else:
		t.cooldown_seconds = float(d.get("cooldown_frames", 0)) * GC.FRAME_SECONDS
	t.max_activations = int(d.get("max_activations_per_battle", d.get("max_activations", 0)))
	t.tags = _strings(d.get("tags", []))
	t.allowed_classes = _strings(d.get("allowed_ability_classes", []))
	t.forbidden_classes = _strings(d.get("forbidden_ability_classes", []))
	t.allowed_keywords = _strings(d.get("allowed_ability_keywords", []))
	t.forbidden_keywords = _strings(d.get("forbidden_ability_keywords", []))
	for c: Variant in d.get("runtime_conditions", []):
		if c is Dictionary:
			t.conditions.append((c as Dictionary).duplicate(true))
	for c2: Variant in d.get("alt_conditions", []):
		if c2 is Dictionary:
			t.alt_conditions.append((c2 as Dictionary).duplicate(true))
	t.unlock_star = maxi(1, int(d.get("unlock_star", 1)))
	return t


## 按星级取值：表里没有这个星级时，超过 3 星(守誓节点绑定后加的星、共享召唤物)按 3 星取
static func _star_key(d: Dictionary, star: int) -> int:
	if d.has(star):
		return star
	if star > 3 and d.has(3):
		return 3
	return -1


func threshold_for(star: int) -> int:
	var k: int = _star_key(count_threshold_by_star, star)
	if k >= 0:
		return maxi(1, int(count_threshold_by_star[k]))
	return count_threshold


func flat_for(star: int) -> float:
	var k: int = _star_key(flat_by_star, star)
	if k >= 0:
		return float(flat_by_star[k])
	return base_value_flat


func ratio_for(star: int) -> float:
	var k: int = _star_key(ratio_by_star, star)
	if k >= 0:
		return float(ratio_by_star[k])
	return base_value_ratio


func has_tag(tag: String) -> bool:
	return tags.has(tag)


## 配对契约：时机被能力接受、能力要求的 tag 触发器都带、职业/关键词过滤通过。
func can_pair(ability: AbilityDef) -> bool:
	if ability == null:
		return false
	if not ability.accepts_timing(timing):
		return false
	for req: String in ability.required_trigger_tags:
		if not tags.has(req):
			return false
	var cls: String = ability.ability_class
	if not allowed_classes.is_empty() and not allowed_classes.has(cls):
		return false
	if forbidden_classes.has(cls):
		return false
	if not allowed_keywords.is_empty():
		var ok := false
		for k: String in allowed_keywords:
			if ability.has_keyword(k):
				ok = true
				break
		if not ok:
			return false
	for k2: String in forbidden_keywords:
		if ability.has_keyword(k2):
			return false
	return true


func duplicate_def() -> TriggerDef:
	var t := TriggerDef.new()
	t.id = id
	t.timing = timing
	t.count_threshold = count_threshold
	t.count_threshold_by_star = count_threshold_by_star.duplicate()
	t.base_value_mode = base_value_mode
	t.base_value_ratio = base_value_ratio
	t.ratio_by_star = ratio_by_star.duplicate()
	t.base_value_flat = base_value_flat
	t.flat_by_star = flat_by_star.duplicate()
	t.base_value_keyword = base_value_keyword
	t.base_value_stat_id = base_value_stat_id
	t.base_value_status_id = base_value_status_id
	t.target_rule = target_rule
	t.team_filter = team_filter
	t.target_radius = target_radius
	t.extra = extra.duplicate(true)
	t.fit = fit.duplicate()
	t.target_sort_rule = target_sort_rule
	t.max_targets = max_targets
	t.cooldown_seconds = cooldown_seconds
	t.max_activations = max_activations
	t.tags = tags.duplicate()
	t.allowed_classes = allowed_classes.duplicate()
	t.forbidden_classes = forbidden_classes.duplicate()
	t.allowed_keywords = allowed_keywords.duplicate()
	t.forbidden_keywords = forbidden_keywords.duplicate()
	for c: Dictionary in conditions:
		t.conditions.append(c.duplicate(true))
	for c2: Dictionary in alt_conditions:
		t.alt_conditions.append(c2.duplicate(true))
	t.unlock_star = unlock_star
	return t


func validate() -> Array[String]:
	var errs: Array[String] = []
	if id == "":
		errs.append("trigger id is required")
	if not GC.TIMINGS.has(timing):
		errs.append("trigger %s: unknown timing %s" % [id, timing])
	if tags.is_empty():
		errs.append("trigger %s: has no tags, no ability can pair with it" % id)
	return errs


static func _strings(v: Variant) -> Array[String]:
	var r: Array[String] = []
	if v is Array:
		for e: Variant in v:
			r.append(str(e))
	return r


static func _int_dict(v: Variant) -> Dictionary:
	var r := {}
	if v is Dictionary:
		for k: Variant in (v as Dictionary).keys():
			r[int(k)] = int((v as Dictionary)[k])
	return r


static func _float_dict(v: Variant) -> Dictionary:
	var r := {}
	if v is Dictionary:
		for k: Variant in (v as Dictionary).keys():
			r[int(k)] = float((v as Dictionary)[k])
	return r
