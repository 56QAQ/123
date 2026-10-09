extends RefCounted
## 调色板(全部为 sRGB 十六进制)。参考图色调：暖白、亮银发、黑金、青色发光。
const VGrid = preload("res://tools/vgrid.gd")


static func make() -> Dictionary:
	var h := func(s: String) -> int: return VGrid.hexc(s)
	return {
		"skin": h.call("#f8cdb8"), "skin2": h.call("#efb7a3"), "skin3": h.call("#e59f92"), "skinh": h.call("#fce0d0"),
		"hair": h.call("#eeeae9"), "hair2": h.call("#dfd9dc"), "hair3": h.call("#cec8cd"), "hair4": h.call("#bdb8c3"),
		"hairtip1": h.call("#d6ebf1"), "hairtip2": h.call("#b6e1ee"), "hairtip3": h.call("#8fd3e8"),
		"white": h.call("#f3f1f1"), "white2": h.call("#dedce0"), "white3": h.call("#c6c4ce"),
		"black": h.call("#2a2c33"), "black2": h.call("#3d4049"), "black3": h.call("#1b1c21"),
		"gold": h.call("#dcae4e"), "gold2": h.call("#f4d478"), "gold3": h.call("#a97e30"),
		"cyan": h.call("#33d5ea"), "cyan2": h.call("#8df2ff"), "cyan3": h.call("#149fb8"), "cyan4": h.call("#0c6d84"), "cyanw": h.call("#e4fdff"),
		"eye": h.call("#3fcfe0"), "eye2": h.call("#21a0b6"), "eye3": h.call("#106a7c"), "lash": h.call("#20232a"),
		"white_eye": h.call("#f4f3f6"), "white_eye2": h.call("#d9dbe4"),
		# 基础武器用的朴素材质：木头 / 铁 / 皮革 / 纸
		"wood": h.call("#9a6a3f"), "wood2": h.call("#b7844f"), "wood3": h.call("#6f4a2a"),
		"iron": h.call("#b9bec8"), "iron2": h.call("#d7dbe2"), "iron3": h.call("#868c98"),
		"leather": h.call("#5b3f2e"), "leather2": h.call("#76533c"), "paper": h.call("#efe4c8"), "paper2": h.call("#d8c9a6"),
	}


## 打包颜色 -> 材质类别，用于阵营换色：1=强调色(青系发光/眼睛) 2=发梢渐变 3=发色 4=肤色
static func classes() -> Dictionary:
	var P: Dictionary = make()
	var m := {}
	for k: String in ["cyan", "cyan2", "cyan3", "cyan4", "cyanw", "eye", "eye2", "eye3"]:
		m[P[k]] = 1
	for k2: String in ["hairtip1", "hairtip2", "hairtip3"]:
		m[P[k2]] = 2
	for k3: String in ["hair", "hair2", "hair3", "hair4"]:
		m[P[k3]] = 3
	for k4: String in ["skin", "skin2", "skin3", "skinh"]:
		m[P[k4]] = 4
	return m
