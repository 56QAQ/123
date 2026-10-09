extends SceneTree
## 屏息节点的过程探针：-- a=node_sniper,node_shielder,node_archer,node_student b=… star=2 [weapon=black_battlefield|none]
## 打印每一枪(瞄了几秒、倍率、伤害、有没有暴击)、一石二鸟的跳弹、集中呼吸的层数 / 暴击率 / 暴击伤害，最后按来源汇总伤害(调试用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "2"))
	var units: Array = []
	for side in range(2):
		var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "")).split(",", false)
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
				if id2 == "node_sniper":
					w = str(args.get("weapon", "black_battlefield"))
					if w == "none":
						w = ""
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var v: BUnit = null
	for u: BUnit in b.units:
		if u.def.id == "node_sniper" and u.team == 0:
			v = u
	var by_src := {"normal_attack": 0.0, "equipment": 0.0}
	var draw_t0 := -1.0
	var next_print := GC.START_DELAY
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			match str(e["t"]):
				"draw_start":
					if e["unit"] == v:
						draw_t0 = b.time
				"attack_release":
					if e["unit"] == v:
						var tg: BUnit = e.get("target") as BUnit
						print("%5.2f SHOT aimed %.2fs scale x%.2f at %s (hp %d)" % [b.time - GC.START_DELAY, b.time - draw_t0 if draw_t0 >= 0.0 else 0.0,
							float(e.get("chant_scale", 1.0)), tg.def.id if tg != null else "-", int(tg.hp) if tg != null else 0])
						draw_t0 = -1.0
				"damage":
					if e.get("src") == v:
						var k: String = "normal_attack" if str(e.get("surface", "")) == "normal_attack" else str(e.get("surface", ""))
						by_src[k] = float(by_src.get(k, 0.0)) + float(e["amount"])
						print("        %s %d%s -> %s (overkill %d)" % [k, int(e["amount"]), " CRIT" if bool(e.get("crit", false)) else "", (e["dst"] as BUnit).def.id,
							int(float(e.get("overkill", 0.0)))])
				"cast_fx":
					if e["unit"] == v and str(e.get("kind", "")) == "ricochet":
						print("        RICOCHET -> %s" % (e["target"] as BUnit).def.id)
				"status_reset":
					if e["unit"] == v:
						print("%5.2f breath reset" % [b.time - GC.START_DELAY])
				"reload_start":
					if e["unit"] == v:
						print("%5.2f reload %.2fs" % [b.time - GC.START_DELAY, float(e["duration"])])
		if b.time >= next_print and v != null:
			next_print += 2.0
			var st: StatBlock = v.get_stats()
			print("%5.2f breath=%d crit=%.2f cdmg=%.2f hp=%d phase=%s" % [b.time - GC.START_DELAY, v.status_stacks("focus_breath"), st.crit_chance, st.crit_damage,
				int(v.hp), v.phase])
	print("damage by source ", by_src)
	print("t=%.1f winner=%d" % [b.time - GC.START_DELAY, b.winner])
	quit()
