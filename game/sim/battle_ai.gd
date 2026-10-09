class_name BattleAI
extends RefCounted
## 自由移动 AI(连续空间，没有格子)。
## 每个棋子每个逻辑步：状态机(idle/windup/draw/recover/reload/chant) → 选目标 → 按"风格"决定移动 → 有目标在射程内且攻击就绪则出手。
## 普攻载荷上的关键词决定出手方式(都读 Pipeline.kw_value，关键词数值被修正时自动跟着变)：
##   [吟唱] 前摇后再拉弓 draw(最多 N 秒，倍率由 Pipeline.chant_scale 给)  [群攻] 候选够多时改用群攻招式(multi)
##   [溅射] 按收益规划落点(可以打地板)  [叠加] 弹量(ammo)：每发消耗 1 层，打空装弹 reload
##  melee    逼近目标，围绕目标散开站位，靠身体互相阻挡形成前排
##  ranged   远程：走到射程边缘就停；被近身时在"下一次攻击就绪前"后撤(风筝)，就绪后立刻站定射击
##  support  跟随并治疗盟友，同样风筝
##  assassin 优先攻击后排(最低最大生命)，被前排挡住时从侧面绕后
##  runner   迅游节点·飞身踢(状态 flag runner)：一直在跑、穿过一切，碰到目标就踢，踢完折返(_runner_step)
## 目标选择带滞后(避免来回切)，近战带"拥挤惩罚"(避免所有人围殴同一个)，嘲讽强制目标。
## 地图：移动绕开断壁残垣与卡车(直线走得通就直走，否则按 A* 路点走并做"拉绳"平滑)；
## 远程必须有视线(高障碍/卡车挡视线)才会出手，被挡住时会绕到看得见的位置。

var b: Battle

const ACCEL := 15.0
const DECEL := 26.0
const RETARGET_INTERVAL := 0.4


func _init(battle: Battle) -> void:
	b = battle


func step(u: BUnit, dt: float) -> void:
	if not u.alive or u.phase == "dash" or u.phase == "throw":    # 冲锋 / 投掷(位移技能)中不受 AI 控制
		return
	if u.attack_cd > 0.0:
		u.attack_cd -= dt
	# 凝暗(踏影节点)：目标进了影子就放掉(吟唱 / 拉弓中也一样，之后照常重新索敌)
	if u.target != null and u.target.team != u.team and shadow_hidden(u, u.target):
		u.target = null
		u.engaged = false
	# 魂体存在：普攻过一次，马上就要散掉了——不再行动
	if bool(u.meta.get("spent", false)):
		_damp(u, dt)
		return
	# 摸鱼(空白节点)：战斗中不普攻、不移动，只会被挤开
	if u.has_flag("slacker"):
		u.target = null
		_damp(u, dt)
		return
	if u.is_stunned():
		b.interrupt(u)
		_damp(u, dt)
		return
	# 缩头：缩在盾后面，不移动也不普通攻击，只转身朝着最近的敌人
	if u.has_flag("turtle"):
		if u.phase == "windup" or u.phase == "draw" or u.phase == "recover" or u.phase == "reload":
			b.interrupt(u)
		_damp(u, dt)
		var ne: BUnit = _nearest_enemy(u)
		if ne != null:
			_face(u, ne.pos - u.pos, dt)
		return
	match u.phase:
		"chant":
			_do_chant(u, dt)
			return
		"windup":
			_do_windup(u, dt)
			return
		"draw":
			_do_draw(u, dt)
			return
		"reload":
			_do_reload(u, dt)
			return
		"recover":
			_do_recover(u, dt)
			return
		"storm":
			_do_storm(u, dt)
			return
	if u.has_flag("runner"):
		_runner_step(u, dt)
		return
	_retarget(u)
	var t: BUnit = u.target
	# 天降施法者(灾星节点)：不能移动；只要目标在自己或任何队友的射程里就能打(无视掩体)
	if u.def.sky_caster:
		u.vel = Vector2.ZERO
		if t != null and t.alive:
			_face(u, t.pos - u.pos, dt)
			if u.attack_cd <= 0.0 and not u.is_disarmed() and u.can_attack() and sky_valid(u, t):
				_start_attack(u, t)
		return
	if t == null:
		u.engaged = false
		_drift_to_center(u, dt)
		return
	var st: StatBlock = u.get_stats()
	var reach: float = st.range_meters()
	var d: float = u.pos.distance_to(t.pos)
	# 队友的"不分敌我"领域(少女幻终)：在里面就先跑出去；近战的目标在领域里就在外面等着(远程照样在外面打)
	var zone: Dictionary = _danger_zone(u)
	if not zone.is_empty():
		var zc: Vector2 = zone["center"]
		var zr: float = float(zone["radius"])
		if u.pos.distance_to(zc) < zr + u.radius:
			u.engaged = false
			var away: Vector2 = (u.pos - zc).normalized() if u.pos.distance_to(zc) > 0.01 else Vector2(sin(u.facing), cos(u.facing)) * -1.0
			_accelerate(u, away * st.speed_mps() * 1.1, st.speed_mps() * 1.15, dt)
			_face(u, away, dt)
			return
		if not u.is_ranged() and t.pos.distance_to(zc) < zr + t.radius and not in_reach(u, t, d, reach):
			u.engaged = false
			_damp(u, dt)
			_face(u, t.pos - u.pos, dt)
			return
	u.engaged = t.team != u.team and not u.is_ranged() and in_reach(u, t, d, reach)
	# 出手判定(空手不能攻击)
	if in_reach(u, t, d, reach) and u.attack_cd <= 0.0 and not u.is_disarmed() and u.can_attack() and can_hit(u, t):
		_start_attack(u, t)
		return
	# 定身(被触手缠住 / 用触手缠住别人)：不能移动，只转身朝着目标
	if u.has_flag("rooted"):
		_damp(u, dt)
		_face(u, t.pos - u.pos, dt)
		return
	var desired: Vector2 = Vector2.ZERO
	var speed: float = st.speed_mps()
	match u.style():
		"ranged", "support":
			desired = _move_ranged(u, t, d, reach, speed)
		"assassin":
			desired = _move_assassin(u, t, d, reach, speed)
		_:
			desired = _move_melee(u, t, d, reach, speed)
	if u.engaged:
		desired = Vector2.ZERO                  # 已经够得着了就站住等下一刀(以前停步距离比"够得着"近，会一直往目标身上顶、互相挤)
	desired += _separation(u, speed) * (0.3 if u.engaged else 1.0)
	_accelerate(u, desired, speed * 1.05, dt)
	# 贴上目标了就一直对着它(不跟着分离力、被挤的那点位移转头)；还在走的时候朝走的方向
	_face(u, t.pos - u.pos if u.engaged or desired.length() < speed * 0.35 else desired, dt)


# ---------------------------------------------------------------- 迅游节点·飞身踢
const RUN_ACCEL := 30.0              # 折返时的加速度(米/秒²)：踢完冲过去一小段再掉头
const RUN_MAX_SPEED := 14.0          # 移动速度再怎么叠也不超过它(逻辑步里的位移别太大)
const SPRING_DIST := 4.5             # 没有卡车可借力时：往外再跑这么远再折返

## 一直在跑：锁定一个目标(最远的敌人；被嘲讽 = 嘲讽者)直线冲过去(穿过地形和人)，碰到就踢(普攻，倍率按这一段的路程)；
## 踢完重新选最远的敌人；它离得不到 min_run 米(只剩一个敌人 / 都挤在一起)就先去卡车边上借力再折返。
## 记录在 meta.run：{target, spring(借力点，没有 = 直接去目标), dist(上一脚之后跑过的路程)}
func _runner_step(u: BUnit, dt: float) -> void:
	var rs: Dictionary = u.meta.get("run", {})
	var t: BUnit = rs.get("target") as BUnit
	var forced: BUnit = u.forced_target if u.forced_target != null and u.forced_target.alive and b.time < u.forced_until else null
	var mis: bool = u.misled_status() != null and not u.cc_resistant()
	if t == null or not t.alive or (t.team == u.team) != mis or (forced != null and t != forced and not mis):
		t = _runner_pick(u)
		rs["target"] = t
		if t != null and not (rs.get("spring") is Vector2) and u.pos.distance_to(t.pos) < float(Pipeline.status_meta(u, "min_run")):
			rs["spring"] = _spring_point(u, t)
	if t != u.target:
		u.target = t
		if t != null:
			b.pipeline.emit("OnTargeting", u, t, 0.0, ["targeting"], {})
	u.meta["run"] = rs
	if t == null:
		_damp(u, dt)
		return
	if u.has_flag("rooted"):
		_damp(u, dt)
		_face(u, t.pos - u.pos, dt)
		return
	var spring: bool = rs.get("spring") is Vector2
	var goal: Vector2 = rs["spring"] if spring else t.pos
	var speed: float = minf(u.get_stats().speed_mps(), RUN_MAX_SPEED)
	var to: Vector2 = goal - u.pos
	var desired: Vector2 = to.normalized() * speed if to.length() > 0.001 else Vector2.ZERO
	var p0: Vector2 = u.pos
	u.vel = u.vel.move_toward(desired, maxf(RUN_ACCEL, speed * 4.0) * dt)
	u.pos += u.vel * dt
	u.pos = b.clamp_to_arena(u.pos, u.radius)
	rs["dist"] = float(rs.get("dist", 0.0)) + p0.distance_to(u.pos)
	_face(u, u.vel if u.vel.length() > 0.3 else to, dt)
	if spring:
		# 到了借力点(或者已经冲过头)：折返去目标
		if _dist_to_segment(goal, p0, u.pos) < 0.35 or u.pos.distance_to(goal) < 0.35:
			rs.erase("spring")
			b.fx({"t": "runner_spring", "unit": u, "pos": goal, "truck": b.map.has_truck() and b.map.truck_world_rect().grow(0.6).has_point(goal)})
		return
	# 这一步扫过的线段碰到目标(速度很快时一步能走好几十厘米)：踢
	if _dist_to_segment(t.pos, p0, u.pos) > u.radius + t.radius + 0.12:
		return
	if u.attack_cd > 0.0 or u.is_disarmed() or not u.can_attack():
		return
	var run: float = float(rs.get("dist", 0.0))
	var km: float = Pipeline.kick_mult(u, run)
	u.attack_cd = 0.25
	rs["dist"] = 0.0
	b.fx({"t": "attack_start", "unit": u, "target": t, "windup": 0.0, "recover": 0.0, "weapon_class": u.weapon_class(),
		"speed_scale": 1.0, "anim": "kick_runner", "variant": ""})
	b.fx({"t": "runner_kick", "unit": u, "target": t, "dist": run, "mult": km})
	b.deliver_normal_attack(u, t, false, {"na_scale": km, "kick_mult": km, "run_dist": run, "released_at": b.time})
	# 重新选目标：离得太近就先去借力
	var nt: BUnit = _runner_pick(u)
	rs["target"] = nt
	if nt != null and u.pos.distance_to(nt.pos) < float(Pipeline.status_meta(u, "min_run")):
		rs["spring"] = _spring_point(u, nt)
	u.meta["run"] = rs


## 飞身踢的目标：被嘲讽就是嘲讽者，否则最远的敌人
func _runner_pick(u: BUnit) -> BUnit:
	if u.misled_status() != null and not u.cc_resistant():
		var ally: BUnit = _misled_pick(u)
		if ally != null:
			return ally
	if u.forced_target != null and u.forced_target.alive and b.time < u.forced_until:
		return u.forced_target
	var best: BUnit = null
	var bd := -1.0
	var shun: BUnit = _misled_by(u)
	for o: BUnit in b.enemies_of(u):
		if o == shun:
			continue
		var d: float = u.pos.distance_to(o.pos)
		if d > bd:
			bd = d
			best = o
	return best


## 借力点：有卡车 = 卡车边上离自己最近的那一点(往外让出半个身位)；卡车太近(来回不到 min_run)或没有卡车 =
## 往远离目标的方向(在场地里能跑得最远的那个方向)再跑 SPRING_DIST 米
func _spring_point(u: BUnit, t: BUnit) -> Vector2:
	var need: float = float(Pipeline.status_meta(u, "min_run"))
	if b.map.has_truck():
		var r: Rect2 = b.map.truck_world_rect().grow(u.radius + 0.05)
		var q := Vector2(clampf(u.pos.x, r.position.x, r.end.x), clampf(u.pos.y, r.position.y, r.end.y))
		if r.has_point(u.pos):
			# 正站在卡车里(穿模)：推到最近的那条边上
			var dl: float = u.pos.x - r.position.x
			var dr: float = r.end.x - u.pos.x
			var dtp: float = u.pos.y - r.position.y
			var db: float = r.end.y - u.pos.y
			var m: float = minf(minf(dl, dr), minf(dtp, db))
			q = Vector2(r.position.x, u.pos.y) if m == dl else (Vector2(r.end.x, u.pos.y) if m == dr else (Vector2(u.pos.x, r.position.y) if m == dtp else Vector2(u.pos.x, r.end.y)))
		if u.pos.distance_to(q) + q.distance_to(t.pos) >= need:
			return q
	var away: Vector2 = u.pos - t.pos
	if away.length() < 0.05:
		away = u.vel if u.vel.length() > 0.05 else Vector2(sin(u.facing), cos(u.facing))
	away = away.normalized()
	var best: Vector2 = b.clamp_to_arena(u.pos + away * SPRING_DIST, u.radius + 0.2)
	var bl: float = best.distance_to(t.pos)
	for ang: float in [0.5, -0.5, 1.0, -1.0, 1.6, -1.6, 2.4, -2.4, PI]:
		var c: Vector2 = b.clamp_to_arena(u.pos + away.rotated(ang) * SPRING_DIST, u.radius + 0.2)
		if c.distance_to(t.pos) > bl + 0.5:
			bl = c.distance_to(t.pos)
			best = c
	return best


# ---------------------------------------------------------------- 幻形节点·误导
## 误导刚挂上：立刻取消当前索敌(正对着谁出招的话打断)，下一步重新选(_retarget：队友；精英 / 首领：除了施加者以外的敌人)
func on_misled(u: BUnit, st: BStatus) -> void:
	var by: BUnit = st.meta.get("by") as BUnit
	var keep: bool = u.target != null and u.target.alive and u.target.team == u.team and u.target != u and not u.cc_resistant()
	if keep:
		return
	if u.cc_resistant() and u.target != by:
		return
	u.target = null
	u.engaged = false
	u.last_target_check = -1.0e9
	u.meta.erase("run")
	if (u.phase == "windup" or u.phase == "draw") and u.attack_target != null and u.attack_target.team != u.team:
		b.interrupt(u)


## 自相残杀的对象：离自己最近的活着的队友(不含自己、还在天上的)；没有 = null
func _misled_pick(u: BUnit) -> BUnit:
	var best: BUnit = null
	var bd := 1.0e9
	for o: BUnit in b.units:
		if not o.alive or o == u or o.team != u.team or bool(o.meta.get("dropping", false)):
			continue
		var d: float = u.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


## 误导期间不会选中的人(精英 / 首领：施加误导的那个)；没有 = null
func _misled_by(u: BUnit) -> BUnit:
	var ml: BStatus = u.misled_status()
	return ml.meta.get("by") as BUnit if ml != null else null


## 队友正在放的"不分敌我"的领域(身上带 cfg 里 ally_danger 的状态：少女幻终)：{center, radius}；没有 = {}
func _danger_zone(u: BUnit) -> Dictionary:
	# 领域自己召唤的幽灵(拴在领域里的 leash / 不分敌我的 feral)就是在领域里打架的，不躲(以前它们跟着队友一起往外跑，贴在拴绳边上打不着人)
	if u.meta.has("leash") or bool(u.meta.get("feral", false)):
		return {}
	for o: BUnit in b.units:
		if not o.alive or o == u or o.team != u.team:
			continue
		for st: BStatus in o.statuses.values():
			if bool(st.meta.get("ally_danger", false)):
				return {"center": o.pos, "radius": b.pipeline.passive_splash_radius(o) + 0.4}
	return {}


## 射程判定。射程极短(例如"攻击范围归零"的武器)时退化为"贴身"：两个身体挨着就算够得着
static func in_reach(u: BUnit, t: BUnit, d: float, reach: float) -> bool:
	return d <= maxf(reach + t.radius * 0.6, touch_reach(u, t))


static func touch_reach(u: BUnit, t: BUnit) -> float:
	return u.radius + t.radius + 0.12


## 远程攻击需要视线；近战只看距离；天降施法者不看视线
func can_hit(u: BUnit, t: BUnit) -> bool:
	return u.def.sky_caster or not u.is_ranged() or b.map.has_los(u.pos, t.pos, u.team)


## 天降施法者能打的目标：在自己射程里，或者在任何一个队友的射程里
func sky_valid(u: BUnit, t: BUnit) -> bool:
	if t == null or not t.alive:
		return false
	if in_reach(u, t, u.pos.distance_to(t.pos), u.get_stats().range_meters()):
		return true
	for a: BUnit in b.units:
		if a.alive and a != u and a.team == u.team and a.can_attack() and in_reach(a, t, a.pos.distance_to(t.pos), a.get_stats().range_meters()):
			return true
	return false


# ---------------------------------------------------------------- 攻击状态机
## 普攻模组来自武器大类：动画时长 = 基础攻击间隔；攻速让间隔变短时，整套动作(前摇/后摇/动画)按比例加速
func _start_attack(u: BUnit, t: BUnit) -> void:
	var wc: Dictionary = u.wclass()
	var na: AbilityDef = u.na_payload()
	# [叠加] 弹量打空：先装弹
	var am: BStatus = b.pipeline.ammo(u)
	if am != null and am.stacks <= 0:
		_start_reload(u)
		return
	var interval: float = u.get_stats().attack_interval()
	# 固定的普攻间隔(开枪最快之人)：不受攻速影响
	var fixed: Variant = Pipeline.status_meta(u, "fixed_interval")
	if fixed != null and float(fixed) > 0.0:
		interval = float(fixed)
	var cycle: float = float(wc["interval"])
	var k: float = minf(1.0, interval / cycle)
	# [群攻]：出招形状上的候选够多时改用群攻招式(双手长 = 贯穿戳刺，双手重 = 旋斩)，时长/前摇可以不同
	var mode: Dictionary = wc
	u.attack_variant = ""
	var m: Dictionary = wc.get("multi", {})
	if not m.is_empty() and na != null and na.has_keyword("multi_attack"):
		if u.def.sky_caster:
			u.attack_variant = "multi"                  # 天降施法者拿双手长：每一下都是[群攻]，但动作用她自己的
		elif 1 + Targeting.multi_extra(b, u, t).size() >= int(m.get("min_targets", 2)):
			u.attack_variant = "multi"
			mode = m
	# 龙息(虚荣)：普攻变成一条射线，出招时先按"压到最多敌人"定方向，出手时再按当时的站位重新瞄一次
	var anim_alt := ""
	var bc: Dictionary = u.breath_cfg()
	if not bc.is_empty():
		u.attack_variant = "breath"
		var aim0: Dictionary = Targeting.best_breath_aim(b, u, bc, t)
		if not aim0.is_empty():
			u.meta["breath_dir"] = aim0["dir"]
		anim_alt = str((u.def.anim_overrides.get(u.weapon_class(), {}) as Dictionary).get("attack_breath", ""))
	# 花蕊(正行节点)：这一下是延长过的光剑 / 光矛 / 光炮——锥形大范围；节奏照这类武器的普攻(不用群攻招式的时长)
	if not u.cone_cfg().is_empty():
		u.attack_variant = "cone"
		mode = wc
		anim_alt = str((u.def.anim_overrides.get(u.weapon_class(), {}) as Dictionary).get("attack_cone", ""))
	u.phase = "windup"
	u.phase_t = 0.0
	u.phase_dur = float(mode.get("windup", wc["windup"])) * k
	u.recover_dur = float(mode.get("recover", wc["recover"])) * k
	var this_interval: float = float(mode.get("interval", cycle)) * k
	u.rest_after_release = maxf(0.0, this_interval - u.phase_dur)
	u.attack_target = t
	u.attack_cd = this_interval
	u.vel = Vector2.ZERO
	b.fx({"t": "attack_start", "unit": u, "target": t, "windup": u.phase_dur, "recover": u.recover_dur,
		"weapon_class": u.weapon_class(), "speed_scale": 1.0 / k,
		"anim": anim_alt if anim_alt != "" else (_multi_anim(u, mode) if u.attack_variant == "multi" else ""),
		"variant": u.attack_variant})


## 群攻招式的动作：单位自带的(anim_overrides 的 attack_multi，如龙的余烬的弓步突刺)优先，否则用武器大类的
func _multi_anim(u: BUnit, mode: Dictionary) -> String:
	var ov: Dictionary = u.def.anim_overrides.get(u.weapon_class(), {})
	if ov.has("attack_multi"):
		return str(ov["attack_multi"])
	# 持盾的棋子拿长枪：单手枪 + 盾的贯穿戳刺(正行节点)
	if mode.has("guard_anim") and u.def.offhand != "" and u.def.offhand != "tower" and u.wclass().has("guard_anims"):
		return str(mode["guard_anim"])
	return str(mode.get("anim", ""))


func _do_windup(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	u.vel = Vector2.ZERO
	var t: BUnit = u.attack_target
	if u.attack_variant == "breath" and u.meta.get("breath_dir") is Vector2:
		_face(u, u.meta["breath_dir"] as Vector2, dt)
	elif t != null and t.alive:
		_face(u, t.pos - u.pos, dt)
	if u.phase_t >= u.phase_dur:
		_release(u)


## 前摇结束：普攻载荷带 [吟唱] 就先拉弓，否则直接出手
func _release(u: BUnit) -> void:
	# 麻痹(电磁学导论)：前摇完成的这一刻有 p 的几率被打断——这一下不打了，照常走完这一轮
	var pz: float = float(Pipeline.status_meta(u, "paralyze", 0.0))
	if pz > 0.0 and b.roll_bad(u) < pz:
		u.phase = "recover"
		u.phase_t = 0.0
		u.attack_cd = maxf(u.attack_cd, u.rest_after_release)
		b.fx({"t": "paralyzed", "unit": u})
		return
	var na: AbilityDef = u.na_payload()
	if na != null and na.has_keyword("chant") and na.has_keyword("normal_attack"):
		var n: float = float(Pipeline.kw_value(u, na, "chant", 1))
		if n > 0.0:
			u.phase = "draw"
			u.phase_t = 0.0
			u.draw_dur = n
			b.fx({"t": "draw_start", "unit": u, "target": u.attack_target, "duration": n, "weapon_class": u.weapon_class(),
				"anim": str(u.wclass().get("draw_anim", ""))})
			return
	_fire(u, 1.0, false)


## 拉弓：最多拉满 N 秒；目标没了/跑出射程就提前放箭(按已拉的时间算倍率)。拉弓的时间插在出手之前，出手后照常走完这一轮
func _do_draw(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	u.vel = Vector2.ZERO
	var t: BUnit = u.attack_target
	if t != null and t.alive:
		_face(u, t.pos - u.pos, dt)
	var reach: float = u.get_stats().range_meters()
	var lost: bool = t == null or not t.alive or u.pos.distance_to(t.pos) > reach * 1.45 + t.radius
	var early := false
	if not lost and u.phase_t < u.draw_dur and u.aim_passive() != null and u.phase_t >= Pipeline.na_base_chant(u):
		early = _aim_done(u, t)
	if u.phase_t >= u.draw_dur or lost or early:
		var drawn: float = minf(u.phase_t, u.draw_dur)
		u.attack_cd = maxf(u.attack_cd, u.rest_after_release)
		_fire(u, Pipeline.na_draw_scale(u, drawn, u.draw_dur), true)


## 瞄准眉心(屏息节点)：什么时候不再多瞄、直接开枪——被拿近战武器的敌人够得着了；或者这一枪(按现在的倍率、期望暴击)
## 已经打得死目标(带着有效果的武器时要打到它生命的 2 倍：溢出的伤害会被一石二鸟带到下一个敌人身上)。都不是就瞄满
func _aim_done(u: BUnit, t: BUnit) -> bool:
	if b.melee_threat(u):
		return true
	var need: float = (t.hp + t.shield) * (2.0 if not u.active_payload_equipment().is_empty() else 1.0)
	return b.pipeline.estimate_na(u, t, Pipeline.na_draw_scale(u, u.phase_t, u.draw_dur)) >= need


## 出手：远程发射投射物，近战当场结算；[溅射] 的普攻按收益选落点(可以打地板)，[叠加] 弹量消耗 1 层
func _fire(u: BUnit, chant_scale: float, drawn: bool) -> void:
	var t: BUnit = u.attack_target
	var reach: float = u.get_stats().range_meters()
	if t == null or not t.alive:
		t = _pick_target(u) if u.def.sky_caster else _nearest_in_reach(u, reach)
		if u.has_flag("hunter"):
			var ht2: BUnit = b.hunt_target_of(u)
			t = ht2 if ht2 != null and in_reach(u, ht2, u.pos.distance_to(ht2.pos), reach) else null
		if u.has_flag("na_target_hurt_ally"):
			var low: BUnit = _lowest_hurt_ally(u)
			if low != null and in_reach(u, low, u.pos.distance_to(low.pos), reach) and can_hit(u, low):
				t = low
	u.phase = "recover"
	u.phase_t = 0.0
	var opts := {"chant_scale": chant_scale, "attack_variant": u.attack_variant, "released_at": b.time}
	if u.def.sky_caster:
		# 天降流星：直接砸目标(溅射以目标为圆心)，不看距离
		if t == null or not sky_valid(u, t):
			b.fx({"t": "whiff", "unit": u})
			u.attack_cd = minf(u.attack_cd, 0.35)
			return
		b.fx({"t": "attack_release", "unit": u, "target": t, "weapon_class": u.weapon_class(), "drawn": drawn, "chant_scale": chant_scale})
		b.deliver_normal_attack(u, t, false, opts)
		return
	var na: AbilityDef = u.na_payload()
	# 致向死的渴望(白羽节点)：不带追击的武器，每第二发普攻改打射程里生命低于 97% 的队友(带追击的双枪由追击那发打，见 Pipeline._pursuit_copy)
	if Pipeline.status_meta(u, "angel_alt") != null and na != null and not na.has_keyword("pursuit"):
		var ash: int = int(u.meta.get("angel_shots", 0)) + 1
		u.meta["angel_shots"] = ash
		if ash % 2 == 0:
			var aly: BUnit = b.pipeline.angel_ally(u)
			if aly != null:
				t = aly
	if u.attack_variant == "cone":
		var cc: Dictionary = u.cone_cfg()
		if not cc.is_empty():
			_fire_cone(u, t, cc, opts, drawn, chant_scale)
			return
		u.attack_variant = ""                       # 花蕊在出手前没了(正常不会)：照常普攻
		opts["attack_variant"] = ""
	# 打向队友的普攻(广义治疗)：直接打在她身上，不做溅射落点规划
	var at_ally: bool = t != null and t.team == u.team
	if not at_ally and na != null and na.has_keyword("splash") and na.has_keyword("normal_attack") and na.effect_type.ends_with("_damage") \
			and u.chain_cfg().is_empty():               # 连锁闪电(引雷)：直接打敌人，不做溅射落点规划
		var aim: Dictionary = Targeting.best_splash_aim(b, u, na, reach * 1.1)
		if aim.is_empty():
			t = null
		else:
			t = aim["target"] as BUnit
			opts["aim_point"] = aim["point"]
			u.facing = atan2((aim["point"] as Vector2).x - u.pos.x, (aim["point"] as Vector2).y - u.pos.y)
	if u.attack_variant == "breath":
		# 龙息：按出手这一刻的站位重新选最优方向；主目标 = 射线上最近的敌人
		var bc: Dictionary = u.breath_cfg()
		var aim: Dictionary = Targeting.best_breath_aim(b, u, bc, u.attack_target) if not bc.is_empty() else {}
		if aim.is_empty():
			b.fx({"t": "whiff", "unit": u})
			u.attack_cd = minf(u.attack_cd, 0.35)
			u.phase_t = u.recover_dur * 0.5
			return
		var dir: Vector2 = aim["dir"]
		opts["breath_dir"] = dir
		t = (aim["targets"] as Array)[0] as BUnit
		u.facing = atan2(dir.x, dir.y)
		b.fx({"t": "attack_release", "unit": u, "target": t, "weapon_class": u.weapon_class(), "drawn": drawn, "chant_scale": chant_scale})
		b.fx({"t": "breath", "unit": u, "dir": dir, "length": float(bc.get("length", 7.0)), "width": float(bc.get("width", 2.0)),
			"targets": aim["targets"]})
		b.deliver_normal_attack(u, t, false, opts)
		return
	if not opts.has("aim_point") and (t == null or u.pos.distance_to(t.pos) > maxf(reach * 1.45 + t.radius, touch_reach(u, t) * 1.3)):
		b.fx({"t": "whiff", "unit": u})
		u.attack_cd = minf(u.attack_cd, 0.35)
		u.phase_t = u.recover_dur * 0.5
		return
	# 远距离打空(开枪最快之人)：目标的身体边缘离自己超过 dist 米时，有 pct 的概率打空
	var mf: Variant = Pipeline.status_meta(u, "miss_far")
	if mf != null and t != null and t.team != u.team:
		var md: Dictionary = mf
		if u.pos.distance_to(t.pos) - t.radius > float(md.get("dist", 1.0)) and b.roll_bad(u) < float(md.get("pct", 0.0)):
			opts["missed"] = true
	b.fx({"t": "attack_release", "unit": u, "target": t, "weapon_class": u.weapon_class(), "drawn": drawn,
		"chant_scale": chant_scale, "aim": opts.get("aim_point"), "missed": bool(opts.get("missed", false))})
	if b.pipeline.ammo(u) != null:
		b.pipeline.spend_ammo(u)
	b.deliver_normal_attack(u, t, false, opts)


## 花蕊的光刃 / 光矛 / 光炮(正行节点)：按出手这一刻的站位挑锥形方向(压到最多敌人)，主目标 = 原来的目标(还在锥形里时)或锥形里最近的；
## 当场结算(法器也不发弹道)，原普攻的 cone.scale 倍、不溅射
func _fire_cone(u: BUnit, t: BUnit, cc: Dictionary, opts: Dictionary, drawn: bool, chant_scale: float) -> void:
	var aim: Dictionary = Targeting.best_cone_aim(b, u, cc, u.attack_target)
	if aim.is_empty():
		b.fx({"t": "whiff", "unit": u})
		u.attack_cd = minf(u.attack_cd, 0.35)
		u.phase_t = u.recover_dur * 0.5
		return
	var dir: Vector2 = aim["dir"]
	var hits: Array = aim["targets"]
	var main: BUnit = t if t != null and t.alive and hits.has(t) else hits[0] as BUnit
	opts["cone_dir"] = dir
	opts["na_scale"] = float(cc.get("scale", 1.0))
	opts["no_splash"] = true
	u.facing = atan2(dir.x, dir.y)
	var shown: Array = hits.slice(0, Targeting.cone_limit(u))
	b.fx({"t": "attack_release", "unit": u, "target": main, "weapon_class": u.weapon_class(), "drawn": drawn, "chant_scale": chant_scale})
	b.fx({"t": "cone_sweep", "unit": u, "dir": dir, "length": float(cc.get("length", 4.5)), "angle": float(cc.get("angle", 120.0)),
		"weapon_class": u.weapon_class(), "targets": shown})
	if b.pipeline.ammo(u) != null:
		b.pipeline.spend_ammo(u)
	b.pipeline.normal_attack(u, main, false, opts)


## 装弹：时长 = 武器大类 ammo.reload(随攻速一起变快)，结束时弹量回满([叠加 N] 当时的 N)
func _start_reload(u: BUnit) -> void:
	var wc: Dictionary = u.wclass()
	var cfg: Dictionary = wc.get("ammo", {})
	var k: float = minf(1.0, u.get_stats().attack_interval() / float(wc["interval"]))
	u.phase = "reload"
	u.phase_t = 0.0
	u.phase_dur = float(cfg.get("reload", 2.0)) * k * maxf(0.1, 1.0 + u.get_stats().reload_time_pct)
	# 状态给的弹匣(开枪最快之人)：换弹时间固定，不受攻速影响；换弹动作按武器大类
	var src: BStatus = Pipeline.ammo_source(u)
	if src != null:
		u.phase_dur = float(src.meta.get("ammo_reload", 1.5)) * maxf(0.1, 1.0 + u.get_stats().reload_time_pct)
		cfg = {"anim": str(wc.get("reload_anim", ""))}
	u.vel = Vector2.ZERO
	b.fx({"t": "reload_start", "unit": u, "duration": u.phase_dur, "anim": str(cfg.get("anim", "")), "weapon_class": u.weapon_class()})


func _do_reload(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	_damp(u, dt)
	if u.phase_t >= u.phase_dur:
		b.pipeline.refill_ammo(u)
		u.phase = "idle"
		b.fx({"t": "reload_end", "unit": u})


func _do_recover(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	_damp(u, dt)
	if u.attack_target != null and u.attack_target.alive:
		_face(u, u.attack_target.pos - u.pos, dt)
	if u.phase_t >= u.recover_dur:
		u.phase = "idle"
		var am: BStatus = b.pipeline.ammo(u)
		if am != null and am.stacks <= 0:
			_start_reload(u)                        # 打空了就马上装弹，不等下一次出手


## 清扫节点·清洁世界：原地转着圈乱扔飞刀(Pipeline._blade_storm 开始)；到每一轮的出手时刻，对每个还活着的目标各发动一次普攻
func _do_storm(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	_damp(u, dt)
	var sd: Dictionary = u.meta.get("storm", {})
	var times: Array = sd.get("times", [])
	var fired: int = int(sd.get("fired", 0))
	while fired < times.size() and u.phase_t >= float(times[fired]) - 0.0001:
		fired += 1
		var hit: Array[BUnit] = []
		for t: BUnit in sd.get("targets", []):
			if t.alive and u.alive and u.can_attack():
				hit.append(t)
				b.deliver_normal_attack(u, t, false, {"released_at": b.time})
		b.fx({"t": "storm_throw", "unit": u, "round": fired, "targets": hit})
	sd["fired"] = fired
	if u.phase_t >= u.phase_dur:
		u.phase = "idle"
		u.meta.erase("storm")
		u.attack_cd = maxf(u.attack_cd, 0.15)


func _do_chant(u: BUnit, dt: float) -> void:
	u.phase_t += dt
	_damp(u, dt)
	if u.target != null and u.target.alive:
		_face(u, u.target.pos - u.pos, dt)
	if b.time >= u.chant_until:
		b.pipeline.release_chant(u, u.phase_dur)
		u.attack_cd = maxf(u.attack_cd, 0.3)


## 凝暗(踏影节点)：持有者不能被敌人索敌，除非它已经是场上最后的合法目标
func shadow_hidden(u: BUnit, o: BUnit) -> bool:
	if o == null or o.team == u.team or not o.has_flag("shadowed"):
		return false
	for e: BUnit in b.enemies_of(u):
		if e != o and not e.has_flag("shadowed"):
			return true
	return false


func _nearest_in_reach(u: BUnit, reach: float) -> BUnit:
	var best: BUnit = null
	var bd := 1e9
	var pool: Array[BUnit] = b.allies_of(u) if u.def.target_priority.begins_with("ally_") else b.enemies_of(u)
	for o: BUnit in pool:
		if shadow_hidden(u, o):
			continue
		var d: float = u.pos.distance_to(o.pos)
		if in_reach(u, o, d, reach) and d < bd and can_hit(u, o):
			bd = d
			best = o
	return best


# ---------------------------------------------------------------- 目标选择
func _retarget(u: BUnit) -> void:
	# 目标进了影子(凝暗)：放掉它重新选(嘲讽 / 锁定也留不住)
	if u.target != null and shadow_hidden(u, u.target):
		u.target = null
		u.engaged = false
		if u.forced_target != null and shadow_hidden(u, u.forced_target):
			u.forced_target = null
	# 少女幻葬的幽灵：攻击不分敌我——打最近的任何人(召唤者自己除外)
	if bool(u.meta.get("feral", false)):
		if u.target != null and u.target.alive and u.target != u and b.time - u.last_target_check < RETARGET_INTERVAL:
			return
		u.last_target_check = b.time
		var fb: BUnit = null
		var fd := 1.0e9
		var smn: BUnit = u.meta.get("summoner") as BUnit
		for o: BUnit in b.enemies_of(u):
			if o == smn:
				continue
			if u.pos.distance_to(o.pos) < fd:
				fd = u.pos.distance_to(o.pos)
				fb = o
		if fb != u.target:
			u.target = fb
			if fb != null:
				b.pipeline.emit("OnTargeting", u, fb, 0.0, ["targeting"], {})
		return
	# 金矢(真望节点·引导之矢)：普攻锁定有充能不满的队友(没有这样的队友就照常打敌人)
	if Pipeline.status_meta(u, "na_ally_effect") != null and u.status_stacks("golden_arrow") > 0 and u.misled_status() == null:
		var gt: BUnit = b.pipeline.golden_target(u)
		if gt != null:
			if gt != u.target:
				u.target = gt
				u.engaged = false
				b.pipeline.emit("OnTargeting", u, gt, 0.0, ["targeting"], {"golden": true})
			return
		if u.target != null and u.target.team == u.team:
			u.target = null
	# 误导(幻形节点·千变万化)：强制索敌自己的一个队友(自相残杀)；精英 / 首领免疫，照常索敌但不会选中施加者
	var ml: BStatus = u.misled_status()
	if ml != null and not u.cc_resistant():
		if u.target != null and u.target.alive and u.target.team == u.team and u.target != u:
			return
		var ally: BUnit = _misled_pick(u)
		if ally != null:
			u.target = ally
			u.engaged = false
			b.pipeline.emit("OnTargeting", u, ally, 0.0, ["targeting"], {"misled": true})
			return
	# 狩猎者(狩胜节点·必胜)：场上有狩猎对象时只以它为目标(嘲讽也改不了)；没有就现选一个
	if u.has_flag("hunter"):
		var ht: BUnit = b.hunt_target_of(u)
		if shadow_hidden(u, ht):
			ht = null
		if ht != u.target:
			u.target = ht
			if ht != null:
				b.pipeline.emit("OnTargeting", u, ht, 0.0, ["targeting"], {})
		return
	if u.forced_target != null and u.forced_target.alive and b.time < u.forced_until:
		if u.target != u.forced_target:
			u.target = u.forced_target
			b.pipeline.emit("OnTargeting", u, u.target, 0.0, ["targeting"], {})
		return
	# 广义治疗(护理节点)：普攻索敌当前生命值最低的非满血队友(严格按血量，不带滞后；她回满了就马上换人)，没有受伤的队友才打敌人
	if u.has_flag("na_target_hurt_ally"):
		var stale: bool = u.target == null or not u.target.alive or (u.target.team == u.team and not _hurt(u.target))
		if not stale and b.time - u.last_target_check < RETARGET_INTERVAL:
			return
		u.last_target_check = b.time
		var nb: BUnit = _pick_target(u)
		if nb != u.target:
			u.target = nb
			if nb != null:
				b.pipeline.emit("OnTargeting", u, nb, 0.0, ["targeting"], {})
		return
	# 追猎节点：猎人笔记盯上的敌人还活着就打它(加成只对它有效)
	if u.def.target_priority == "marked_first":
		var mk: BUnit = u.meta.get("threat_mark") as BUnit
		if mk != null and mk.alive and not shadow_hidden(u, mk):
			if u.target != mk:
				u.target = mk
				b.pipeline.emit("OnTargeting", u, mk, 0.0, ["targeting"], {})
			return
	# 锁定(浪游节点)：选中的敌人没倒下就一直打它(开局放在谁身边就先打谁)
	if u.def.target_priority == "nearest_locked" and u.target != null and u.target.alive and u.target.team != u.team:
		return
	var sky_lost: bool = u.def.sky_caster and u.target != null and not sky_valid(u, u.target)
	# 近战已经贴着目标在打：不换(以前拥挤惩罚随站位变来变去，打着打着就转头去打旁边那个)
	if u.engaged and u.target != null and u.target.alive and u.target.team != u.team:
		return
	if u.target != null and u.target.alive and b.time - u.last_target_check < RETARGET_INTERVAL and not sky_lost:
		return
	u.last_target_check = b.time
	var best: BUnit = _pick_target(u)
	if best == null:
		u.target = null
		return
	if best != u.target:
		# 滞后：现有目标仍有效且新目标没有明显更优时不切换
		if u.target != null and u.target.alive and not sky_lost:
			var cur_score: float = _target_score(u, u.target)
			var new_score: float = _target_score(u, best)
			if u.def.target_priority == "top_damage":
				if new_score < cur_score + 1.3:
					return                       # 嫉妒的余烬：有人的伤害明显超过现在的目标(≈ 多 65 点)就换过去
			elif new_score > cur_score - 1.3:
				return
		u.target = best
		b.pipeline.emit("OnTargeting", u, best, 0.0, ["targeting"], {})


func _pick_target(u: BUnit) -> BUnit:
	if u.has_flag("na_target_hurt_ally"):
		var low: BUnit = _lowest_hurt_ally(u)
		if low != null:
			return low
	var pool: Array[BUnit]
	var prio: String = u.def.target_priority
	if prio.begins_with("ally_"):
		pool = b.allies_of(u, false)
		if pool.is_empty():
			pool = b.allies_of(u, true)
	else:
		pool = b.enemies_of(u)
	# 天降施法者：只从"自己或队友射程里"的敌人里挑，挑离自己最近的
	if u.def.sky_caster:
		var sb: BUnit = null
		var sd := 1.0e9
		for o0: BUnit in pool:
			if sky_valid(u, o0) and u.pos.distance_to(o0.pos) < sd:
				sd = u.pos.distance_to(o0.pos)
				sb = o0
		return sb
	var best: BUnit = null
	var best_score := -1e18
	var shun: BUnit = _misled_by(u)
	for o: BUnit in pool:
		if o == shun or shadow_hidden(u, o):
			continue
		var s: float = _target_score(u, o)
		if s > best_score:
			best_score = s
			best = o
	return best


static func _hurt(o: BUnit) -> bool:
	return o.alive and o.hp < o.get_stats().max_health - 0.5


## 当前生命值最低的非满血队友(不含自己；一样低时取近的)
func _lowest_hurt_ally(u: BUnit) -> BUnit:
	var best: BUnit = null
	for a: BUnit in b.units:
		if a == u or a.team != u.team or not _hurt(a):
			continue
		if best == null or a.hp < best.hp - 0.01 or (absf(a.hp - best.hp) <= 0.01 and a.pos.distance_squared_to(u.pos) < best.pos.distance_squared_to(u.pos)):
			best = a
	return best


## 分数越高越优先(以"米"为量纲，便于与滞后比较)
func _target_score(u: BUnit, o: BUnit) -> float:
	var d: float = u.pos.distance_to(o.pos)
	var score: float = -d
	var reach: float = u.get_stats().range_meters()
	match u.def.target_priority:
		"nearest_tank_first":
			if o.def.role == "tank":
				score += 2.0
		"lowest_max_health":
			score = -o.get_stats().max_health * 0.02 - d * 0.15
		"nearest_melee_first":
			# 踏影节点：第一次逆光之前先盯拿近战武器的敌人(逆光要"当前目标不是远程敌人"才会瞬移到后排；敌人前排是拿手枪的架盾节点时，
			# 按"最近"他会一直打它、永远不瞬移)；逆光过以后(身在影子里，敌人选不中他)改为先找远程敌人
			if o.is_ranged() == bool(u.meta.get("backlit", false)):
				score += 4.0
		"range_lowest_health":
			# 屏息节点：射程里看得见的敌人挑当前生命最低的(打得死就开枪，溢出给一石二鸟)；射程里没有就挑近的
			if d <= reach + o.radius and b.map.has_los(u.pos, o.pos, u.team):
				score = 50.0 - (o.hp + o.shield) * 0.01
		"range_lowest_health_else_nearest_tank_first":
			if d <= reach + o.radius and b.map.has_los(u.pos, o.pos, u.team):
				score = 50.0 - o.hp * 0.01
			elif o.def.role == "tank":
				score += 2.0
		"ally_highest_defense":
			score = o.get_stats().defense * 0.05 - d * 0.1
		"ally_lowest_health_ratio":
			score = -o.hp_ratio() * 8.0 - d * 0.1
		"farthest":
			score = d
		"top_damage":
			# 本场造成伤害最多的敌人(战报里的累计伤害；每多 100 点伤害 ≈ 近 2 米)；都还没打过人就挑近的
			var rr: Dictionary = b.report.rows.get(o.uid, {})
			score = float(rr.get("dealt", 0.0)) * 0.02 - d * 0.1
		"nearest_locked":
			return -d                     # 只看远近：不吃视线、拥挤这些修正(开局放在谁身边就是谁)
	score += _fit_bonus(u, o)
	# 远程：被高障碍/卡车挡住视线的目标降低优先级
	if u.is_ranged() and not b.map.has_los(u.pos, o.pos, u.team):
		score -= 4.0
	# 近战拥挤惩罚：已经有很多友军围着这个目标时，去找别的
	var sty: String = u.style()
	if sty == "melee" or sty == "assassin":
		var crowd := 0
		for a: BUnit in b.units:
			if a.alive and a != u and a.team == u.team and a.target == o and a.pos.distance_to(o.pos) < 2.1:
				crowd += 1
		score -= 0.7 * float(maxi(0, crowd - 1))
	return score


## 普攻"按某状态的个数挑目标"(怠惰的余烬·引火：预热没满时，挑燃烧最多 / 刚好能把预热叠满的敌人)。
## 配置写在单位已解锁的能力上：effect_config.na_target_fit = {status, gauge}
func _fit_bonus(u: BUnit, o: BUnit) -> float:
	if not u.meta.has("_na_fit"):
		var cfg := {}
		for e: Dictionary in u.all_ability_entries():
			var a: AbilityDef = e["ability"]
			if a.effect_config.has("na_target_fit"):
				cfg = a.effect_config["na_target_fit"]
		u.meta["_na_fit"] = cfg
	var fit: Dictionary = u.meta["_na_fit"]
	if fit.is_empty():
		return 0.0
	var g: BStatus = u.get_status(str(fit.get("gauge", "")))
	var cap: int = g.max_stacks if g != null else int(fit.get("cap", 8))
	var have: int = g.stacks if g != null else 0
	if have >= cap:
		return 0.0
	var cnt: int = o.status_count(str(fit.get("status", "burning")))
	if cnt <= 0:
		return 0.0
	var need: int = maxi(1, cap - have - 1)
	return 8.0 + 1.5 * float(mini(cnt, need)) - 0.8 * float(maxi(0, cnt - need))


# ---------------------------------------------------------------- 移动
## 朝 goal 移动的期望速度：直线畅通就直走；否则走 A* 路点(每 0.5 秒或目标明显移动时重算)，并跳过可以直达的路点
func _steer(u: BUnit, goal: Vector2, speed: float) -> Vector2:
	# 会飞的(巫术节点的鸟)：从障碍物上面飞过去，不绕路
	if u.has_flag("flying"):
		u.meta.erase("path")
		return (goal - u.pos).normalized() * speed
	if b.time >= float(u.meta.get("direct_t", -1.0)):
		u.meta["direct"] = b.map.path_clear(u.pos, goal, u.radius)
		u.meta["direct_t"] = b.time + 0.15
	if bool(u.meta.get("direct", true)):
		u.meta.erase("path")
		return (goal - u.pos).normalized() * speed
	var path: PackedVector2Array = u.meta.get("path", PackedVector2Array())
	var pgoal: Vector2 = u.meta.get("path_goal", Vector2(1e9, 1e9))
	if path.is_empty() or pgoal.distance_to(goal) > 0.8 or b.time >= float(u.meta.get("path_t", 0.0)):
		path = b.map.find_path(u.pos, goal)
		u.meta["path_goal"] = goal
		u.meta["path_t"] = b.time + 0.5
	while path.size() > 1 and (u.pos.distance_to(path[0]) < 0.3 or b.map.path_clear(u.pos, path[1], u.radius)):
		path.remove_at(0)
	u.meta["path"] = path
	if path.is_empty():
		return (goal - u.pos).normalized() * speed
	return (path[0] - u.pos).normalized() * speed


func _move_melee(u: BUnit, t: BUnit, d: float, reach: float, speed: float) -> Vector2:
	var stop_at: float = maxf(reach * 0.8, touch_reach(u, t) - 0.05)
	if d <= stop_at:
		return Vector2.ZERO
	# 不直接冲目标的圆心：找目标身边一个没人站的位置(近战 a → 近战 b → 敌人排成一条线时，a 绕到侧面，不再一直把 b 往旁边挤)，
	# 路上有人挡着就从它旁边绕过去
	var goal: Vector2 = _melee_slot(u, t, stop_at)
	return _steer(u, _detour(u, goal, t), speed)


## 目标身边能站的位置：以目标为圆心、半径 r(刚好够得着)的一圈候选点里，没被别的单位占着、地图上站得下的、离自己最近的
## (路上要穿过别人的加一点距离)。选好的位置记 0.4 秒，没被人占就一直用(免得每一步换来换去)
func _melee_slot(u: BUnit, t: BUnit, r: float) -> Vector2:
	var rs: float = maxf(touch_reach(u, t) - 0.04, r - 0.05)
	var cache: Dictionary = u.meta.get("melee_slot", {})
	if not cache.is_empty() and cache.get("t") == t and b.time < float(cache.get("until", 0.0)):
		var cp: Vector2 = t.pos + (cache["off"] as Vector2)
		if _slot_free(u, t, cp):
			return cp
	var dir0: Vector2 = u.pos - t.pos
	dir0 = dir0.normalized() if dir0.length() > 0.001 else Vector2(0.0, -1.0)
	var best: Vector2 = t.pos + dir0 * rs
	var best_s := 1.0e9
	for i in range(16):
		var ang: float = float((i + 1) / 2) * (TAU / 16.0) * (1.0 if i % 2 == 0 else -1.0)   # 0, +22.5°, -22.5°, +45° …(先看正对自己的那边)
		var p: Vector2 = t.pos + dir0.rotated(ang) * rs
		if not _slot_free(u, t, p):
			continue
		var s: float = u.pos.distance_to(p)
		if _blocker(u, p, t) != null:
			s += 0.8
		if s < best_s:
			best_s = s
			best = p
	u.meta["melee_slot"] = {"t": t, "off": best - t.pos, "until": b.time + 0.4}
	return best


## 这个位置站得下：地图上没墙，也没被别的单位(敌我都算，目标自己和 u 除外)占着
func _slot_free(u: BUnit, t: BUnit, p: Vector2) -> bool:
	if GC.clamp_to_arena(p, u.radius).distance_to(p) > 0.05 or not b.map.circle_free(p, u.radius * 0.9):
		return false
	for o: BUnit in b.units:
		if not o.alive or o == u or o == t or bool(o.meta.get("dropping", false)) or o.has_flag("phasing"):
			continue
		if o.pos.distance_to(p) < (u.radius + o.radius) * 0.85:
			return false
	return true


## 从 u 走直线去 goal，路上第一个挡着的单位(身体会撞上的；目标自己不算)；没有 = null
func _blocker(u: BUnit, goal: Vector2, t: BUnit) -> BUnit:
	var best: BUnit = null
	var bd := 1.0e9
	var seg: float = u.pos.distance_to(goal)
	for o: BUnit in b.units:
		if not o.alive or o == u or o == t or bool(o.meta.get("dropping", false)) or o.has_flag("phasing"):
			continue
		var along: float = (o.pos - u.pos).dot((goal - u.pos).normalized()) if seg > 0.001 else 0.0
		if along <= 0.0 or along > seg + o.radius:
			continue
		if _dist_to_segment(o.pos, u.pos, goal) < u.radius + o.radius - 0.05 and along < bd:
			bd = along
			best = o
	return best


## 路上有人挡着：先走到它旁边(goal 那一侧)，绕过去
func _detour(u: BUnit, goal: Vector2, t: BUnit) -> Vector2:
	var o: BUnit = _blocker(u, goal, t)
	if o == null:
		return goal
	var dir: Vector2 = (goal - u.pos).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var side: float = signf((goal - o.pos).dot(perp))
	if side == 0.0:
		side = 1.0 if (hash(u.uid) % 2) == 0 else -1.0
	return o.pos + perp * side * (u.radius + o.radius + 0.25)


func _move_ranged(u: BUnit, t: BUnit, d: float, reach: float, speed: float) -> Vector2:
	var kite: float = float(u.def.ai.get("kite_radius", clampf(reach * 0.5, 1.8, 3.0)))
	var threat: BUnit = _nearest_enemy(u)
	if threat != null:
		var td: float = u.pos.distance_to(threat.pos)
		if td < kite and u.attack_cd > 0.25 and not u.def.ai.get("no_kite", false):
			var away: Vector2 = _retreat_dir(u, _threat_away(u, kite + 1.5))
			if away != Vector2.ZERO:
				return away * speed
	# 射程外，或者视线被挡住：往目标走(绕障碍)，直到看得见
	if d > reach * 0.96 or not can_hit(u, t):
		return _steer(u, t.pos, speed)
	return Vector2.ZERO


## 被多个方向的敌人包围时，远离"威胁场"的合力方向(越近权重越大)，而不是只躲最近的一个
func _threat_away(u: BUnit, radius: float) -> Vector2:
	var push: Vector2 = Vector2.ZERO
	for o: BUnit in b.units:
		if not o.alive or o.team == u.team:
			continue
		var dv: Vector2 = u.pos - o.pos
		var dist: float = dv.length()
		if dist < radius and dist > 0.001:
			push += dv / dist * (radius - dist) / radius
	if push.length() < 0.001:
		return -u.pos.normalized() if u.pos.length() > 0.1 else Vector2.RIGHT
	return push.normalized()


## 撤退方向：在"远离威胁"的方向附近找一个走得通(不撞墙、不出界)的方向；实在无路可退返回零向量
func _retreat_dir(u: BUnit, away: Vector2) -> Vector2:
	for ang: float in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
		var dir: Vector2 = away.rotated(ang)
		var probe: Vector2 = u.pos + dir * 1.1
		if GC.clamp_to_arena(probe, u.radius).distance_to(probe) > 0.05:
			continue
		if b.map.path_clear(u.pos, probe, u.radius):
			return dir
	return Vector2.ZERO


## 刺客：前面有 2 个以上敌人挡路时，从侧面绕过去(绕行点 = 目标侧方 2.6 米)
func _move_assassin(u: BUnit, t: BUnit, d: float, reach: float, speed: float) -> Vector2:
	if d <= reach * 0.8:
		return Vector2.ZERO
	var blockers: int = 0
	if d > 4.0:
		for e: BUnit in b.enemies_of(u):
			if e == t:
				continue
			if _dist_to_segment(e.pos, u.pos, t.pos) < 1.15 and e.pos.distance_to(u.pos) < d:
				blockers += 1
	if blockers >= 2:
		var to_t: Vector2 = (t.pos - u.pos).normalized()
		var perp := Vector2(-to_t.y, to_t.x)
		var side: float = float(u.meta.get("flank_side", 0.0))
		if side == 0.0:
			side = 1.0 if b.map.point_free(t.pos + perp * 2.6) else -1.0
			u.meta["flank_side"] = side
		var wp: Vector2 = GC.clamp_to_arena(t.pos + perp * side * 2.6, u.radius + 0.6)
		if u.pos.distance_to(wp) > 1.2:
			return _steer(u, wp, speed)
	u.meta.erase("flank_side")
	return _steer(u, t.pos, speed)


## 我方全灭后：敌人涌向卡车(走到卡车旁的空地)
func raid_step(u: BUnit, dt: float) -> void:
	if u.phase != "idle":
		u.phase = "idle"
	var goal: Vector2 = b.map.truck_center()
	var best := 1e9
	for p: Vector2 in b.map.truck_entry_points():
		var dd: float = p.distance_to(u.pos)
		if dd < best:
			best = dd
			goal = p
	if best < 0.35:
		goal = b.map.truck_center()        # 已到门口：往车里钻
	var speed: float = u.get_stats().speed_mps() * 1.15
	var desired: Vector2 = _steer(u, goal, speed) if best >= 0.35 else (goal - u.pos).normalized() * speed
	desired += _separation(u, speed) * 0.4
	_accelerate(u, desired, speed, dt)
	_face(u, desired, dt)


func _drift_to_center(u: BUnit, dt: float) -> void:
	_damp(u, dt)


func _nearest_enemy(u: BUnit) -> BUnit:
	var best: BUnit = null
	var bd := 1e9
	for o: BUnit in b.units:
		if not o.alive or o.team == u.team:
			continue
		var d: float = u.pos.distance_squared_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


## 分离力：只跟队友保持一点间距(敌人之间靠碰撞体积分开——以前连敌人也推，近战被推到射程外又走回来，来回晃)
func _separation(u: BUnit, speed: float) -> Vector2:
	var push: Vector2 = Vector2.ZERO
	for o: BUnit in b.units:
		if not o.alive or o == u or o.team != u.team or o.has_flag("phasing"):
			continue
		var d: Vector2 = u.pos - o.pos
		var dist: float = d.length()
		var want: float = u.radius + o.radius + 0.28
		if dist < want and dist > 0.001:
			push += d / dist * (want - dist) / want
	return push * speed * 0.9


static func _dist_to_segment(p: Vector2, a: Vector2, c: Vector2) -> float:
	var ac: Vector2 = c - a
	var l2: float = ac.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ac) / l2, 0.0, 1.0)
	return p.distance_to(a + ac * t)


# ---------------------------------------------------------------- 运动学
func _accelerate(u: BUnit, desired: Vector2, max_speed: float, dt: float) -> void:
	if desired.length() > max_speed:
		desired = desired.normalized() * max_speed
	var rate: float = ACCEL if desired.length() > u.vel.length() else DECEL
	u.vel = u.vel.move_toward(desired, rate * dt)
	u.pos += u.vel * dt


func _damp(u: BUnit, dt: float) -> void:
	u.vel = u.vel.move_toward(Vector2.ZERO, DECEL * dt)
	u.pos += u.vel * dt


func _face(u: BUnit, dir: Vector2, dt: float) -> void:
	if dir.length() < 0.01:
		return
	var want: float = atan2(dir.x, dir.y)
	u.facing = lerp_angle(u.facing, want, minf(1.0, dt * 11.0))
