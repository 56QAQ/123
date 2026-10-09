class_name Loc
extends RefCounted
## 中英双语本地化。数据文件在 res://game/data/loc/{zh,en}.json，键值为扁平字典。
## t("key", [args]) 支持 %s 格式化；缺键时回退到另一语言，再回退到键名。

static var lang: String = "zh"
static var _tables: Dictionary = {}
static var _loaded: bool = false


static func load_all() -> void:
	if _loaded:
		return
	for l: String in ["zh", "en"]:
		var path := "res://game/data/loc/%s.json" % l
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_tables[l] = d if d is Dictionary else {}
	_loaded = true


static func has_key(k: String) -> bool:
	load_all()
	return (_tables.get(lang, {}) as Dictionary).has(k) or (_tables.get("zh", {}) as Dictionary).has(k)


static func t(key: String, args: Array = []) -> String:
	load_all()
	var s: String = ""
	var cur: Dictionary = _tables.get(lang, {})
	if cur.has(key):
		s = str(cur[key])
	else:
		var other: Dictionary = _tables.get("en" if lang == "zh" else "zh", {})
		s = str(other.get(key, key))
	if args.is_empty():
		return s
	var n: int = s.count("%s") + s.count("%d")
	if n <= 0:
		return s
	return s % args.slice(0, n)


## 指定语言取文本(不格式化)。界面上的英文小标注用它取英文名，与当前语言无关
static func t_in(l: String, key: String) -> String:
	load_all()
	var d: Dictionary = _tables.get(l, {})
	return str(d.get(key, t(key)))


static func set_lang(l: String) -> void:
	lang = l


static func toggle() -> void:
	lang = "en" if lang == "zh" else "zh"
