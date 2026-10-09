extends RefCounted
## 卡车摆法(开局的初始卡车改装)：三种规则的几何、Run 里移动 / 旋转时棋子怎么跟、战斗地图 / 战斗里卡车真的在新位置。


func _bounds() -> Rect2i:
	return Rect2i(0, 0, GC.MAP_W, GC.MAP_H)


func test_bigger_map_and_initial_layout(t: TestCtx) -> void:
	t.eq(GC.MAP_W, 25, "25 columns (19 + 3 on each side)")
	t.eq(GC.MAP_H, 20, "20 rows (14 + 3 on each side)")
	t.eq(GC.DEPLOY_RECT, Rect2i(8, 7, 9, 6), "the initial deploy zone is still 9 × 6 around the centre")
	t.eq(GC.TRUCK_RECT, Rect2i(11, 9, 3, 2), "the truck starts in the middle")
	t.ok(GC.truck_center().is_zero_approx(), "map centre = truck centre")
	t.eq(GC.deploy_cells().size(), 48, "48 deployable cells")
	t.eq(BattleMap.empty().deploy_cells().size(), 48, "the battle map agrees")
	t.near(GC.region_anchor("n").y, -(10.0 - GC.SPAWN_INSET), 0.001, "enemies from the north spawn 3 m further out than on the old map")
	t.near(GC.region_anchor("e").x, 12.5 - GC.SPAWN_INSET, 0.001, "…and from the east too")


func test_mod_rules_are_pure_geometry(t: TestCtx) -> void:
	var none := TruckLayout.make("")
	t.ok(not none.can_move(), "no mod: the truck is fixed")
	t.ok(none.rotated().equals(none) and none.moved_to(Vector2i(0, 0)).equals(none), "…rotating / moving does nothing")
	var wide := TruckLayout.make("truck_wide")
	t.ok(not wide.can_move(), "Wider Ground: fixed truck")
	t.eq(wide.deploy, GC.DEPLOY_RECT.grow(1), "…zone 11 × 8")
	t.eq(wide.deploy_cells().size(), 11 * 8 - 6, "82 cells")
	var z := TruckLayout.make("truck_zone")
	t.ok(z.can_move() and z.deploy == GC.DEPLOY_RECT and z.truck == GC.TRUCK_RECT, "Mobile Workshop starts as the initial layout")
	var z2: TruckLayout = z.moved_to(Vector2i(0, 0))
	t.eq(z2.truck.position, GC.DEPLOY_RECT.position, "moving is clamped into the initial zone (top-left corner)")
	t.eq(z2.deploy, Rect2i(GC.DEPLOY_RECT.position - TruckLayout.ZONE_PAD, GC.DEPLOY_RECT.size), "the zone follows the truck")
	t.ok(_bounds().encloses(z2.deploy), "…and stays inside the map")
	var z3: TruckLayout = z2.moved_to(Vector2i(99, 99))
	t.eq(z3.truck, Rect2i(GC.DEPLOY_RECT.end - Vector2i(3, 2), Vector2i(3, 2)), "clamped at the bottom-right corner")
	t.ok(_bounds().encloses(z3.deploy), "zone inside the map at the far corner too")
	var r1: TruckLayout = z.rotated()
	t.eq(r1.rot, 1, "one quarter turn")
	t.eq(r1.truck, Rect2i(GC.TRUCK_RECT.position, Vector2i(2, 3)), "rotated: 2 × 3 keeping the top-left")
	t.eq(r1.deploy, Rect2i(r1.truck.position - Vector2i(2, 3), Vector2i(6, 9)), "the zone turned with it: 6 × 9")
	t.ok(TruckLayout.fits(r1.truck) and _bounds().encloses(r1.deploy), "still inside the initial zone / the map")
	t.ok(r1.rotated().rotated().rotated().equals(z), "four quarter turns = back to the start")
	t.ok(z.rotated(-1).rot == 3 and z.rotated(-1).rotated().equals(z), "a counter-clockwise turn is undone by a clockwise one")
	var zb: TruckLayout = z.moved_to(Vector2i(14, 11))
	t.eq(zb.truck, Rect2i(14, 11, 3, 2), "(test setup: truck in the bottom-right of the initial zone)")
	var zbr: TruckLayout = zb.rotated()
	t.eq(zbr.truck, Rect2i(14, 10, 2, 3), "a rotation that would poke out of the initial zone is pushed back in")
	t.ok(_bounds().encloses(zbr.deploy), "…zone still inside the map")
	var f := TruckLayout.make("truck_free")
	var f2: TruckLayout = f.moved_to(Vector2i(8, 7))
	t.eq(f2.truck.position, Vector2i(8, 7), "Free Chassis: the truck moved")
	t.eq(f2.deploy, GC.DEPLOY_RECT, "…the zone stays")
	t.eq(f2.deploy_cells().size(), 48, "still 48 cells (the truck covers 6 wherever it is)")
	t.ok(not f2.is_deploy_cell(Vector2i(8, 7)) and f2.is_deploy_cell(GC.TRUCK_RECT.position), "the old truck cells are free now, the new ones are not")
	t.eq(f.rotated().deploy, GC.DEPLOY_RECT, "rotating a Free Chassis keeps the zone too")


func test_pieces_follow_a_mobile_workshop(t: TestCtx) -> void:
	var z := TruckLayout.make("truck_zone")
	var c := Vector2i(10, 8)
	var zm: TruckLayout = z.moved_to(Vector2i(9, 8))
	t.eq(z.map_cell(c, zm), Vector2i(8, 7), "pieces translate with the zone")
	var r1: TruckLayout = z.rotated()
	var truck_ok := true
	var free_ok := true
	var seen: Dictionary = {}
	for y in range(z.deploy.position.y, z.deploy.end.y):
		for x in range(z.deploy.position.x, z.deploy.end.x):
			var src := Vector2i(x, y)
			var dst: Vector2i = z.map_cell(src, r1)
			seen[dst] = true
			if z.truck.has_point(src) != r1.truck.has_point(dst):
				truck_ok = false
			if not r1.deploy.has_point(dst):
				free_ok = false
	t.ok(truck_ok, "the truck's own cells land exactly on the rotated truck's cells")
	t.ok(free_ok and seen.size() == 54, "the rotation maps the 54 zone cells one-to-one onto the turned zone")
	var r2: TruckLayout = r1.rotated()
	t.eq(r1.map_cell(z.map_cell(c, r1), r2), z.map_cell(c, r2), "turning twice = one half turn")
	var f := TruckLayout.make("truck_free")
	t.eq(f.map_cell(c, f.moved_to(Vector2i(8, 7))), c, "Free Chassis: pieces stay put")


func test_layout_round_trips_into_the_battle_map(t: TestCtx) -> void:
	var r1: TruckLayout = TruckLayout.make("truck_zone").moved_to(Vector2i(9, 8)).rotated()
	var lay: Dictionary = r1.write_into({})
	t.ok(TruckLayout.from_layout(lay).equals(r1), "write_into / from_layout round trip")
	var bm := BattleMap.from_layout(lay)
	t.eq(bm.truck_rect, r1.truck, "the battle map takes the truck rect")
	t.eq(bm.deploy_rect, r1.deploy, "…and the deploy zone")
	t.eq(bm.truck_rot, 1, "…and the facing")
	t.ok(bm.blocks_move(r1.truck.position) and bm.blocks_move(r1.truck.end - Vector2i(1, 1)), "the rotated truck is stamped on the map")
	t.ok(not bm.blocks_move(GC.TRUCK_RECT.end - Vector2i(1, 1)), "…and the old truck cells are free")
	t.eq(bm.truck_center(), r1.truck_center(), "truck centre from the map")
	t.eq(bm.deploy_cells().size(), 48, "48 free zone cells on an empty map")
	t.eq(BattleMap.from_layout({}).truck_rect, GC.TRUCK_RECT, "a layout without truck keys = the initial layout")


func test_run_picks_a_start_mod_then_moves_the_truck(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var r := Run.create(cat, 5, "ch0", true)
	t.eq(r.phase, "start_mod", "a real run begins with the starting-mod choice")
	t.eq(r.mod_options.size(), 3, "three starting mods")
	t.eq(r.pick_mod("nope")["reason"], "ui.err.bad_target", "an unknown mod is refused")
	t.eq(r.move_truck(Vector2i(8, 7))["reason"], "ui.err.truck_fixed", "no moving before a mod is picked")
	t.ok(r.pick_mod("truck_zone")["ok"], "pick Mobile Workshop")
	t.ok(r.phase == "map" and r.truck_mods.size() == 1 and r.truck_mods[0] == "truck_zone", "…recorded, and the run is on the map")
	t.eq(r.move_truck(Vector2i(8, 7))["reason"], "ui.err.not_now", "the truck only moves while preparing")
	t.ok(not r.truck_can_move(), "…so it can't move on the map")
	r.travel()
	t.eq(r.phase, "prepare", "(test setup: preparing at node 1)")
	t.ok(r.truck_can_move(), "now it can")
	var rel: Dictionary = {}
	for u: Dictionary in r.board_units():
		rel[u["id"]] = (u["cell"] as Vector2i) - r.truck_layout.truck.position
	t.ok(r.move_truck(Vector2i(0, 0))["ok"], "move (clamped) to the top-left of the initial zone")
	t.eq(r.truck_layout.truck.position, Vector2i(8, 7), "the truck is in the corner")
	var kept := true
	for u2: Dictionary in r.board_units():
		if (u2["cell"] as Vector2i) - r.truck_layout.truck.position != rel[u2["id"]] or not r.can_deploy_at(u2, u2["cell"]):
			kept = false
	t.ok(kept and r.board_units().size() == 3, "the pieces moved with the zone and still stand on valid cells")
	t.eq(r.current_map().truck_rect, r.truck_layout.truck, "the node's battle map carries the moved truck")
	t.ok(not r.can_deploy_at(r.board_units()[0], GC.DEPLOY_RECT.end - Vector2i(1, 1)), "the far corner of the old zone is no longer deployable")
	t.ok(r.rotate_truck()["ok"], "rotate")
	t.eq(r.truck_layout.rot, 1, "…quarter turn")
	var ok2 := true
	for u3: Dictionary in r.board_units():
		if not r.can_deploy_at(u3, u3["cell"]):
			ok2 = false
	t.ok(ok2 and r.board_units().size() == 3, "after the turn every piece stands on a valid cell of the 6 × 9 zone")
	var setup: Dictionary = r.build_battle_setup()
	var b := Battle.new(cat, 3)
	b.setup(setup)
	t.eq(b.map.truck_rect, r.truck_layout.truck, "the battle map has the rotated, moved truck")
	for e: Dictionary in setup["units"]:
		if int(e["team"]) == GC.TEAM_PLAYER:
			t.ok(not b.map.blocks_move(e["cell"]), "no player piece under the truck or terrain (%s)" % str(e["cell"]))
		else:
			t.ok(not r.truck_layout.deploy.grow(1).has_point(GC.world_to_cell(e["pos"])), "enemies spawn away from the moved zone")
	b.run_to_end()
	t.ok(b.state == "ended", "the battle resolves with the truck in its new place")


func test_free_chassis_moves_pieces_out_of_the_way(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5, "ch0", true)
	r.pick_mod("truck_free")
	r.travel()
	var covered := Vector2i(10, 8)
	var cov_id := ""
	for u: Dictionary in r.board_units():
		if u["cell"] == covered:
			cov_id = str(u["id"])
	t.ok(cov_id != "", "(test setup: a starting piece stands at (10, 8))")
	t.ok(r.move_truck(Vector2i(9, 8))["ok"], "park the truck over it")
	t.eq(r.truck_layout.deploy, GC.DEPLOY_RECT, "Free Chassis: the zone did not move")
	t.ok(r.roster[cov_id]["cell"] != null and r.roster[cov_id]["cell"] != covered and r.can_deploy_at(r.roster[cov_id], r.roster[cov_id]["cell"]),
		"the covered piece stepped aside to a free cell (%s)" % str(r.roster[cov_id]["cell"]))
	t.eq(r.board_units().size(), 3, "nobody was benched (there was room)")
	var old_br: Vector2i = GC.TRUCK_RECT.end - Vector2i(1, 1)
	t.ok(not r.can_deploy_at(r.roster[cov_id], covered) and r.can_deploy_at(r.roster[cov_id], old_br), "the truck's new cells are blocked, its old ones are free")
	var m: BattleMap = r.current_map()
	t.ok(m.blocks_move(Vector2i(9, 8)) and not m.blocks_move(old_br), "the battle map agrees")


func test_wider_ground_is_fixed_but_larger(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5, "ch0", true)
	r.pick_mod("truck_wide")
	r.travel()
	t.eq(r.move_truck(Vector2i(8, 7))["reason"], "ui.err.truck_fixed", "cannot move")
	t.eq(r.rotate_truck()["reason"], "ui.err.truck_fixed", "cannot rotate")
	var u: Dictionary = r.add_unit("node_shielder", 1, null, r.free_bench_slot())
	t.ok(r.move_unit(str(u["id"]), {"cell": Vector2i(7, 6)})["ok"], "the extra ring (7, 6) is deployable")
	t.eq(r.move_unit(str(u["id"]), {"cell": Vector2i(6, 6)})["reason"], "ui.err.bad_cell", "two rings out is not")
	t.eq(r.current_map().deploy_rect, GC.DEPLOY_RECT.grow(1), "the battle map has the 11 × 8 zone")
	t.eq(BattleMap.from_layout(r.build_battle_setup()["map"]).deploy_cells().size(), 82, "82 cells on the battle map")


func test_enemies_raid_a_moved_truck(t: TestCtx) -> void:
	var lay: Dictionary = TruckLayout.make("truck_free").moved_to(Vector2i(8, 7)).write_into({"truck": true})
	var b: Battle = Fixture.make([{"def": "test_dummy", "pos": Vector2(3.0, 3.0)},
		{"def": "node_darkknight", "team": 1, "pos": Vector2(6, -6), "star": 2}], 7, lay)
	t.eq(b.map.truck_rect, Rect2i(8, 7, 3, 2), "(test setup: the truck sits in the north-west corner of the zone)")
	b.start()
	b.units[0].hp = 0.0
	b.pipeline.fx.try_kill(b.units[0], b.units[1])
	var entered := false
	for i in range(int(25.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "enter_truck":
				entered = true
		b.events.clear()
		if b.state == "ended":
			break
	t.ok(entered and b.state == "ended" and b.winner == GC.TEAM_ENEMY, "the surviving enemy raids the truck where it actually is")
	t.ok(b.map.dist_to_truck(b.units[1].pos) < 1.5, "…and ended up next to the moved truck (%.1f m)" % b.map.dist_to_truck(b.units[1].pos))
	t.ok(b.units[1].pos.distance_to(Vector2.ZERO) > 2.0, "not at the map centre where the truck used to be")
