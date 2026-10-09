class_name TestCtx
extends RefCounted
## 极简测试上下文：断言 + 计数

var passed: int = 0
var failed: int = 0
var current: String = ""
var failures: Array[String] = []


func ok(cond: bool, msg: String = "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		failures.append("[%s] %s" % [current, msg])


func eq(a: Variant, b: Variant, msg: String = "") -> void:
	ok(a == b, "%s (expected %s, got %s)" % [msg, str(b), str(a)])


func near(a: float, b: float, eps: float = 0.01, msg: String = "") -> void:
	ok(absf(a - b) <= eps, "%s (expected %.3f, got %.3f)" % [msg, b, a])
