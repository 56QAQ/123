extends RefCounted
## 本地化完整性：数据里引用的键都要有中英文；源码里字面量 Loc.t("…") 的键也不能缺。


func _langs() -> Array[String]:
	return ["zh", "en"]


## 严格检查：只看该语言自己的表(Loc.has_key 会回退到中文)
func _has(lang: String, key: String) -> bool:
	Loc.load_all()
	return (Loc._tables.get(lang, {}) as Dictionary).has(key)


func _scan_dir(path: String, out: PackedStringArray) -> void:
	for f: String in DirAccess.get_files_at(path):
		if f.ends_with(".gd"):
			out.append(path.path_join(f))
	for d: String in DirAccess.get_directories_at(path):
		_scan_dir(path.path_join(d), out)


func test_every_literal_loc_key_exists_in_both_languages(t: TestCtx) -> void:
	var files := PackedStringArray()
	_scan_dir("res://game", files)
	var re := RegEx.new()
	re.compile("Loc\\.t\\(\"([a-z0-9_.]+)\"")
	var missing: Array[String] = []
	var checked := 0
	for f: String in files:
		if f.contains("/tests/"):
			continue
		var txt: String = FileAccess.get_file_as_string(f)
		for m: RegExMatch in re.search_all(txt):
			var key: String = m.get_string(1)
			if key.ends_with(".") or key.ends_with("_"):        # 动态拼接的前缀
				continue
			checked += 1
			for lang in _langs():
				if not _has(lang, key):
					missing.append("%s [%s] in %s" % [key, lang, f.get_file()])
	t.ok(checked > 40, "scanned a reasonable number of keys (%d)" % checked)
	t.ok(missing.is_empty(), "missing loc keys: %s" % ", ".join(missing.slice(0, 12)))


func test_catalog_content_has_names_in_both_languages(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var missing: Array[String] = []
	for lang in _langs():
		for id: String in cat.units.keys():
			if id.begins_with("test_"):
				continue
			for suffix in ["name", "desc"]:
				if not _has(lang, "unit.%s.%s" % [id, suffix]):
					missing.append("unit.%s.%s [%s]" % [id, suffix, lang])
		for id2: String in cat.equipment.keys():
			for suffix2 in ["name", "desc"]:
				if not _has(lang, "equipment.%s.%s" % [id2, suffix2]):
					missing.append("equipment.%s.%s [%s]" % [id2, suffix2, lang])
		for id3: String in cat.traits.keys():
			if not _has(lang, "trait.%s.name" % id3):
				missing.append("trait.%s.name [%s]" % [id3, lang])
	t.ok(missing.is_empty(), "missing names: %s" % ", ".join(missing.slice(0, 12)))


func test_zh_and_en_tables_have_identical_keys(t: TestCtx) -> void:
	Loc.load_all()
	var zh: Dictionary = Loc._tables["zh"]
	var en: Dictionary = Loc._tables["en"]
	var only_zh: Array[String] = []
	var only_en: Array[String] = []
	for k: String in zh.keys():
		if not en.has(k):
			only_zh.append(k)
	for k2: String in en.keys():
		if not zh.has(k2):
			only_en.append(k2)
	t.ok(only_zh.is_empty(), "keys missing in en: %s" % ", ".join(only_zh.slice(0, 8)))
	t.ok(only_en.is_empty(), "keys missing in zh: %s" % ", ".join(only_en.slice(0, 8)))


func test_catalog_validates(t: TestCtx) -> void:
	var errs: Array[String] = []
	for e: String in Fixture.catalog().validate_all():
		if not e.begins_with("unit test_"):        # 夹具里的木桩没有本地化
			errs.append(e)
	t.ok(errs.is_empty(), "catalog validation: %s" % ", ".join(errs.slice(0, 6)))
