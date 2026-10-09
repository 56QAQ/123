extends SceneTree
## 手臂穿模检查：烘焙各持械动画的姿态(不含弹簧骨)，量出上臂/前臂/手陷进躯干的最大深度(体素)。
## 用法: godot --path . --script res://tools/arm_clip.gd --quit-after 200 -- [anims=idle_polearm,attack_heavy]
const Rig = preload("res://tools/rig.gd")
const Lib = preload("res://tools/anim_lib.gd")
const Defs = preload("res://tools/anim_chars.gd")

const DEFAULT := ["idle_polearm", "run_polearm", "attack_polearm", "idle_heavy", "run_heavy", "attack_heavy",
	"idle_rifle", "run_rifle", "attack_rifle", "idle_sword", "run_sword", "attack_sword", "idle_dual", "run_dual", "attack_dual",
	"idle_crossbow", "attack_crossbow", "idle_pistols", "attack_pistols", "idle_focus", "attack_focus", "idle", "idle_m", "run", "run_m", "attack_bow", "aim_bow", "release_bow",
	"fidget", "victory", "fidget_dancer", "victory_dancer", "fidget_archer", "victory_archer", "fidget_nurse", "victory_nurse"]


func _init() -> void:
	var rig = Rig.new()
	rig.build()
	var defs = Defs.new(rig)
	var tbl: Dictionary = defs.table()
	var names: Array = DEFAULT
	for a in OS.get_cmdline_user_args():
		if a.begins_with("anims="):
			names = Array(a.substr(6).split(","))
	var p = Lib.Pose.new(rig)
	var worst := 0.0
	for nm: String in names:
		if not tbl.has(nm):
			continue
		var d: Dictionary = tbl[nm]
		var frames: int = int(round(float(d["dur"]) * 30.0))
		var mx := {"L": 0.0, "R": 0.0}
		var at := {"L": "", "R": ""}
		for f in range(frames + 1):
			var t := float(f) / 30.0
			p.reset()
			(d["fn"] as Callable).call(t, p)
			p.fk()
			for side: String in ["L", "R"]:
				var r: Dictionary = defs.arm_penetration(p, side)
				if float(r["depth"]) > float(mx[side]):
					mx[side] = float(r["depth"])
					at[side] = "f%02d %s" % [f, r["where"]]
		print("%-16s  L %4.1f %-18s  R %4.1f %s" % [nm, mx["L"], at["L"], mx["R"], at["R"]])
		worst = maxf(worst, maxf(mx["L"], mx["R"]))
	print("worst penetration: %.1f voxels" % worst)
	quit()
