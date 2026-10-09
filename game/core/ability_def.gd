class_name AbilityDef
extends RefCounted
## 能力(效果载荷)：被动能力属于单位，装备载荷属于装备。能力自己不会触发——
## 必须有一个 tag/时机 都兼容的触发器把它"扣动"，才会执行(见 TriggerDef.can_pair)。

var id: String = ""
var ability_class: String = "blade"     # bullet/blade/amulet/potion/chip/tome
var effect_type: String = "none"
var value_multiplier: float = 1.0
var fixed_value: float = 0.0
var cooldown: float = 0.0               # 秒
var max_charges: int = 0
var keywords: Array[String] = []
var keyword_values: Dictionary = {}     # keyword -> 数值(一般是整数；【溅射 1.5】这种允许小数，读的时候用 keyword_value_f)
var keyword_values_by_star: Dictionary = {}   # keyword -> {star: 数值}
var accepted_timings: Array[String] = []
var required_trigger_tags: Array[String] = []
var effect_config: Dictionary = {}
var priority: int = 100
var unlock_star: int = 1                # 棋子达到这个星级才有这个能力(被动 2 = 2 星解锁)


static func from_dict(d: Dictionary) -> AbilityDef:
	var a := AbilityDef.new()
	a.id = str(d.get("id", ""))
	a.ability_class = str(d.get("ability_class", "blade"))
	a.effect_type = str(d.get("effect_type", "none"))
	a.value_multiplier = float(d.get("value_multiplier", 1.0))
	a.fixed_value = float(d.get("fixed_value", 0.0))
	a.cooldown = float(d.get("cooldown", 0.0))
	a.max_charges = int(d.get("max_charges", 0))
	a.priority = int(d.get("priority", 100))
	a.unlock_star = maxi(1, int(d.get("unlock_star", 1)))
	a.keywords = TriggerDef._strings(d.get("keywords", []))
	var kv: Variant = d.get("keyword_values", {})
	if kv is Dictionary:
		for k: Variant in (kv as Dictionary).keys():
			a.keyword_values[str(k)] = _num((kv as Dictionary)[k])
	var kvs: Variant = d.get("keyword_values_by_star", {})
	if kvs is Dictionary:
		for k2: Variant in (kvs as Dictionary).keys():
			var byst := {}
			var src: Variant = (kvs as Dictionary)[k2]
			if src is Dictionary:
				for sk: Variant in (src as Dictionary).keys():
					byst[int(sk)] = _num((src as Dictionary)[sk])
			a.keyword_values_by_star[str(k2)] = byst
	a.accepted_timings = TriggerDef._strings(d.get("accepted_timings", []))
	a.required_trigger_tags = TriggerDef._strings(d.get("required_trigger_tags", []))
	var cfg: Variant = d.get("effect_config", {})
	if cfg is Dictionary:
		a.effect_config = (cfg as Dictionary).duplicate(true)
	return a


func has_keyword(k: String) -> bool:
	return keywords.has(k)


func keyword_value(k: String, star: int = 1, fallback: int = 0) -> int:
	return int(keyword_value_f(k, star, float(fallback)))


## 关键词数值(允许小数，例如【溅射 1.5】)
func keyword_value_f(k: String, star: int = 1, fallback: float = 0.0) -> float:
	if keyword_values_by_star.has(k):
		var byst: Dictionary = keyword_values_by_star[k]
		if byst.has(star):
			return float(byst[star])
	return float(keyword_values.get(k, fallback))


## 整数照旧存成 int，带小数的存成 float
static func _num(v: Variant) -> Variant:
	var f: float = float(v)
	return int(f) if is_equal_approx(f, roundf(f)) else f


func accepts_timing(t: String) -> bool:
	return accepted_timings.is_empty() or accepted_timings.has(t)


func cfg(key: String, fallback: Variant = null) -> Variant:
	return effect_config.get(key, fallback)


func duplicate_def() -> AbilityDef:
	return AbilityDef.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"id": id, "ability_class": ability_class, "effect_type": effect_type,
		"value_multiplier": value_multiplier, "fixed_value": fixed_value, "cooldown": cooldown,
		"max_charges": max_charges, "priority": priority, "unlock_star": unlock_star, "keywords": keywords.duplicate(),
		"keyword_values": keyword_values.duplicate(true),
		"keyword_values_by_star": keyword_values_by_star.duplicate(true),
		"accepted_timings": accepted_timings.duplicate(),
		"required_trigger_tags": required_trigger_tags.duplicate(),
		"effect_config": effect_config.duplicate(true),
	}


func validate() -> Array[String]:
	var errs: Array[String] = []
	if id == "":
		errs.append("ability id is required")
	if not GC.CLASSES.has(ability_class):
		errs.append("ability %s: unknown class %s" % [id, ability_class])
	for k: String in keywords:
		if not (GC.KEYWORDS.has(k) or GC.SYSTEM_KEYWORDS.has(k)):
			errs.append("ability %s: unknown keyword %s" % [id, k])
	if required_trigger_tags.is_empty():
		errs.append("ability %s: has no required_trigger_tags — it could never be triggered by anything" % id)
	return errs
