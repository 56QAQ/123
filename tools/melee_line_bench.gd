extends SceneTree
## 近战排成一条直线的基准：我方近战 a 在近战 b 正后方、b 正对着一个敌人(a → b → 敌人一条线)，看 a 多久能打到敌人、b 被挤开多远。
## 另一组：舞星节点(近战武器) + 她开局召出的护星节点 对 1 个敌人。godot --headless --path . --script res://tools/melee_line_bench.gd -- [secs=6]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var secs: float = float(args.get("secs", "6"))
	var cat: Catalog = Fixture.catalog()
	var cases := [
		["line samurai→samurai→foe", [{"def": "node_samurai", "team": 0, "pos": Vector2(0, -1.0)}, {"def": "node_samurai", "team": 0, "pos": Vector2(0, 1.6)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.8)}]],
		["line gladiator→darkknight→foe", [{"def": "node_gladiator", "team": 0, "pos": Vector2(0, -1.0), "weapon": "basic_sword"},
			{"def": "node_darkknight", "team": 0, "pos": Vector2(0, 1.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.8)}]],
		["dancer(basic dual) + her star guard", [{"def": "node_dancer", "team": 0, "pos": Vector2(0, -2.0), "weapon": "basic_dual"},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}]],
		["dancer(fans) + her star guard", [{"def": "node_dancer", "team": 0, "pos": Vector2(0, -2.0), "weapon": "dance_fans"},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}]],
	]
	for c: Array in cases:
		for sd in range(3):
			var b := Battle.new(cat, 40 + sd)
			b.setup({"units": c[1], "map": {"truck": false}, "cfg": {"traits": false}})
			b.start()
			var foe: BUnit = null
			for u: BUnit in b.units:
				if u.team == 1:
					foe = u
					u.base.max_health = 1.0e8
					u.mark_dirty()
					u.get_stats()
					u.hp = 1.0e8
			var first_hit := {}
			var start_pos := {}
			var max_disp := {}
			while b.time < GC.START_DELAY + secs and b.state != "ended":
				b.step()
				for u2: BUnit in b.units:
					if u2.team != 0 or not u2.alive:
						continue
					if not start_pos.has(u2.uid) and b.state == "running":
						start_pos[u2.uid] = u2.pos
				for e: Dictionary in b.poll_events():
					if e["t"] == "damage" and e["dst"] == foe and e["src"] != null and not first_hit.has((e["src"] as BUnit).uid):
						first_hit[(e["src"] as BUnit).uid] = b.time - GC.START_DELAY
			var line := "%-38s seed %d:" % [c[0], sd]
			for u3: BUnit in b.units:
				if u3.team == 0:
					line += "  %s first hit %s  dist %.2f" % [u3.def.id.replace("node_", ""), ("%.1fs" % first_hit[u3.uid]) if first_hit.has(u3.uid) else "never",
						u3.pos.distance_to(foe.pos)]
			print(line)
	quit()
