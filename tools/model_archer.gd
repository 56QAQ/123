extends RefCounted
## 角色整体雕刻入口
const Pal = preload("res://tools/pal.gd")
const Body = preload("res://tools/model_body.gd")
const Head = preload("res://tools/model_head.gd")
const Bow = preload("res://tools/model_bow.gd")


func build(g, rig) -> void:
	var P: Dictionary = Pal.make()
	var body = Body.new(g, P)
	body.build()
	var head = Head.new(g, rig, P)
	head.build()
	var bow = Bow.new(g, rig, P)
	bow.build()
