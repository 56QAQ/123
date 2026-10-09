extends SceneTree
## 正行节点的过程探针：-- a=node_noble,node_archer,node_student,node_nurse b=node_berserker,node_shielder,node_archer,node_witch star=2 [weapon=true_flower|none|<武器 id>]
##   [ehp=2] 敌人生命 ×ehp(看长一点的战斗)
## 打印花瓣层数的每次变化(来源)、再绽之花的吟唱 / 每一秒 / 花开、每一道光刃(打到几个人、多少伤害、分出去多少治疗)、
## 百合骑士的骑士的每次触发(enter / linger、触发数值)，每 2 秒一行状态(花瓣 / 花蕊 / 治疗量加成 / 生命)，最后按来源汇总(调试 / 调平衡用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "2"))
	var units: Array = []
	for side in range(2):
		var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "node_noble,node_archer,node_student,node_nurse" if side == 0 else
			"node_berserker,node_shielder,node_archer,node_witch")).split(",", false)
		var sgn: float = -1.0 if side == 0 else 1.0
		var front: Array = []
		var back: Array = []
		for id: String in ids:
			var d: UnitDef = cat.get_unit(id)
			(back if d.wclass_for(d.base_weapon_class).get("ranged", false) else front).append(id)
		for row in [0, 1]:
			var r: Array = front if row == 0 else back
			for n in range(r.size()):
				var id2: String = r[n]
				var w: String = ""
				if id2 == "node_noble" and side == 0:
					w = str(args.get("weapon", "true_flower"))
					if w == "none":
						w = ""
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	var ehp: float = float(args.get("ehp", "1"))
	b.start()
	for u0: BUnit in b.units:
		if u0.team == 1 and ehp != 1.0:
			u0.base.max_health *= ehp
			u0.mark_dirty()
			u0.get_stats()
			u0.hp = u0.get_stats().max_health
	var v: BUnit = null
	for u: BUnit in b.units:
		if u.def.id == "node_noble" and u.team == 0:
			v = u
	var by_src := {}
	var heal_by := {}
	var petals := 0
	var cones := 0
	var knights := 0
	var next_print := GC.START_DELAY
	var t0 := GC.START_DELAY
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			var tt: float = b.time - t0
			match str(e["t"]):
				"status":
					if e["unit"] == v and str(e.get("base_id", e.get("id", ""))) == "lily_petal":
						var ns: int = int(e.get("stacks", 0))
						if ns != petals:
							print("%5.2f petals %d -> %d" % [tt, petals, ns])
						petals = ns
				"chant_start":
					if e["unit"] == v:
						print("%5.2f CHANT %s %.1fs" % [tt, str(e.get("ability", "")), float(e["duration"])])
				"interrupt":
					if e["unit"] == v:
						print("%5.2f INTERRUPTED" % tt)
				"lily_tick":
					if e["unit"] == v:
						print("%5.2f   tick %d/%d: -%d petals, stamens %d" % [tt, int(e["tick"]), int(e["of"]), int(e["took"]), v.status_stacks("lily_stamen")])
				"lily_full_bloom":
					if e["unit"] == v:
						print("%5.2f BLOOM (healing bonus now %.0f%%)" % [tt, v.get_stats().healing_done_pct * 100.0])
				"cone_sweep":
					if e["unit"] == v:
						cones += 1
						print("%5.2f CONE #%d (%s) hits %d" % [tt, cones, str(e.get("weapon_class", "")), (e["targets"] as Array).size()])
				"lily_heal":
					if e["unit"] == v:
						print("        smart heal %.0f over %d allies" % [float(e["amount"]), (e["targets"] as Array).size()])
				"trigger":
					if e["unit"] == v and str(e.get("trigger", "")) == "node_noble_knight":
						knights += 1
						print("%5.2f knight -> %s value %.0f" % [tt, (e["target"] as BUnit).def.id if e.get("target") is BUnit else "-", float(e.get("value", 0.0))])
				"damage":
					if e.get("src") == v:
						var k: String = str(e.get("surface", ""))
						by_src[k] = float(by_src.get(k, 0.0)) + float(e["amount"])
				"heal":
					if e.get("src") == v:
						var hk: String = "%s->%s" % [str(e.get("surface", "")), "self" if e["dst"] == v else "ally"]
						heal_by[hk] = float(heal_by.get(hk, 0.0)) + float(e["amount"])
				"death":
					if e["unit"] == v:
						print("%5.2f NOBLE DIED" % tt)
		if b.time >= next_print and v != null and v.alive:
			next_print += 2.0
			var st: StatBlock = v.get_stats()
			print("%5.2f [petals %d stamen %d bloom %d] heal+%.0f%% hp %d/%d def %d mr %d phase=%s" % [b.time - t0, v.status_stacks("lily_petal"),
				v.status_stacks("lily_stamen"), v.status_stacks("lily_bloom"), st.healing_done_pct * 100.0, int(v.hp), int(st.max_health), int(st.defense),
				int(st.magic_resistance), v.phase])
	print("damage by source ", by_src)
	print("heal by surface ", heal_by)
	print("cones %d, knight triggers %d" % [cones, knights])
	print("t=%.1f winner=%d" % [b.time - t0, b.winner])
	quit()
