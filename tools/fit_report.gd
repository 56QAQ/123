extends SceneTree
## 适配标签的总表(FitTags)：每把武器的三组标签和适配角色；专武的主人适不适配；第二批通用武器测强度定下的合手棋子在不在里面。
## 用法: godot --headless --path . --script res://tools/fit_report.gd --quit-after 100
func _init() -> void:
	var cat: Catalog = Catalog.load_all()
	var own_ok := 0
	var own_n := 0
	var rows: Array[String] = []
	var ids: Array = cat.equipment.keys()
	ids.sort()
	for id: String in ids:
		var e: EquipmentDef = cat.get_equipment(id)
		if e.basic or e.abilities.is_empty() or e.slot == "token" or not e.reworked:
			continue
		var wt: Dictionary = FitTags.weapon_tags(e)
		var fits: Array[String] = cat.fit_units(id)
		var short: Array[String] = []
		for u: String in fits:
			short.append(u.trim_prefix("node_"))
		var own := ""
		if e.owner != "":
			own_n += 1
			var ok: bool = fits.has(e.owner)
			if ok:
				own_ok += 1
			var why := ""
			if not ok:
				var bits: Array[String] = []
				for t: TriggerDef in FitTags.payload_triggers(cat.get_unit(e.owner)):
					bits.append("%s/%s/%s" % [t.fit.get("side", "?"), t.fit.get("count", "?"), t.fit.get("freq", "?")])
				why = " 主人触发器=" + ",".join(bits)
			own = "  主人 %s %s%s" % [e.owner.trim_prefix("node_"), "适配" if ok else "不适配", why]
		rows.append("%-22s %-5s %-6s %-5s %2d只  %s%s" % [id, wt["side"], "群攻" if wt["multi"] else "-", "基本" if wt["basic"] else "-", fits.size(), ",".join(short), own])
	for r: String in rows:
		print(r)
	print("专武适配主人：%d / %d" % [own_ok, own_n])
	# dump=1：把原始数据写成 out/fit_dump.json(调规则 / 阈值时离线比较用)
	if OS.get_cmdline_user_args().has("dump=1"):
		var dw := {}
		for id2: String in ids:
			var e2: EquipmentDef = cat.get_equipment(id2)
			if e2.basic or e2.abilities.is_empty() or e2.slot == "token" or not e2.reworked:
				continue
			var can: Array[String] = []
			for uid: String in cat.shop_unit_ids():
				if FitTags.can_equip(e2, cat.get_unit(uid)):
					can.append(uid)
			dw[id2] = {"tags": FitTags.weapon_tags(e2), "owner": e2.owner, "can": can}
		var f := FileAccess.open("res://out/fit_dump.json", FileAccess.WRITE)
		f.store_string(JSON.stringify({"weapons": dw}))
		f.close()
	quit()
