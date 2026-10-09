extends SceneTree
## 无头单元测试：执行 res://game/tests/test_*.gd 里的所有 test_* 方法。
## 用法: godot --headless --path . --script res://tools/run_tests.gd --quit-after 3000 [-- only=test_pipeline]
func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	var ctx := TestCtx.new()
	var files: PackedStringArray = DirAccess.get_files_at("res://game/tests")
	var total_methods := 0
	for f: String in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_ctx.gd":
			continue
		if only != "" and not f.begins_with(only):
			continue
		var script: GDScript = load("res://game/tests/" + f)
		var obj: Object = script.new()
		var methods: Array[String] = []
		for m: Dictionary in obj.get_method_list():
			if str(m["name"]).begins_with("test_"):
				methods.append(str(m["name"]))
		methods.sort()
		for m2: String in methods:
			ctx.current = "%s::%s" % [f, m2]
			var before_f: int = ctx.failed
			obj.call(m2, ctx)
			total_methods += 1
			print(("  ok   " if ctx.failed == before_f else "  FAIL ") + ctx.current)
	print("---- tests: %d methods, %d assertions passed, %d failed" % [total_methods, ctx.passed, ctx.failed])
	for msg in ctx.failures:
		print("  ✗ " + msg)
	quit(1 if ctx.failed > 0 else 0)
