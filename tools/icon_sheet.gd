extends SceneTree
## 预览游戏启动时渲染的 UI 贴图：全部武器图标(体素模型)拼成一张表。
## godot --path . --script res://tools/icon_sheet.gd -- out=res://out/icons.png
func _init() -> void:
	var out := "res://out/icons.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	var cat := Catalog.load_all()
	var p := Portraits.new()
	root.add_child(p)
	await process_frame
	await p.render_all(cat)
	var ids: Array = p.weapon_textures.keys()
	ids.sort()
	var cell := 144
	var cols := 7
	var rows: int = int(ceil(float(ids.size()) / float(cols)))
	var sheet := Image.create(cell * cols, cell * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#24262f"))
	for i in range(ids.size()):
		var img: Image = (p.weapon_textures[ids[i]] as ImageTexture).get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((i % cols) * cell, (i / cols) * cell))
	sheet.save_png(out)
	# 车间材料的像素图标：大号 ×4、小号 ×4 放大(最近邻)排成一行
	var row := Image.create(3 * 220, 2 * 210, false, Image.FORMAT_RGBA8)
	row.fill(Color("#24262f"))
	var i2 := 0
	for m: String in Crafting.MATS:
		var st: Dictionary = p.material_textures.get(m, {})
		for k2 in range(2):
			var key: String = ["l", "s"][k2]
			if not st.has(key):
				continue
			var im: Image = (st[key] as ImageTexture).get_image()
			im.convert(Image.FORMAT_RGBA8)
			var sc: int = 4 if key == "l" else 7
			im.resize(im.get_width() * sc, im.get_height() * sc, Image.INTERPOLATE_NEAREST)
			row.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(i2 * 220 + 8, k2 * 210 + 8))
		i2 += 1
	row.save_png(out.replace(".png", "_materials.png"))
	print("saved ", out, " ", ids)
	quit()
