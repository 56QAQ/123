class_name BattleView
extends Node3D
## 战斗表现：以固定步长驱动 Battle(逻辑层)，并把它的事件流翻译成 动画 / 特效 / 飘字 / UI 信息流。
## 逻辑层完全不知道有 3D 存在；这里只读取状态与事件。

signal feed(entry: Dictionary)
signal ended(winner: int)
signal shake(amount: float)
signal banner(text_key: String)
signal ultimate(unit: BUnit, ability_id: String, color: Color)     # 大招开始(HUD 切入立绘 + 技能名)
signal orb_dropped(tier: String, pos: Vector2)
signal truck_hit(damage: int)
signal ember_out(id: int)           # 有人踩灭了一块余烬地块(战场视图把它熄掉)
signal ember_lit(id: int)           # 喷泉的火弧把一块余烬地块重新点燃了
signal ember_add(id: int, e: Dictionary)   # 战斗中新烧起来一块余烬地块(龙的余烬：点燃 / 蔓延)
signal hazard(e: Dictionary)        # 专属战场的机制：预警 / 发动 / 结束(战场视图的布景去演)
signal terrain_break(kind: String, id: int)   # 地形被打碎(圣战节点·裂地猛击)：obstacle / frost(余烬走 ember_out)
signal weather(kind: String)          # 战场天气(导向节点·变天：rain / sunny；"" = 恢复)：GameWorld 换光照、下雨
signal synced(alpha: float)         # 每帧：逻辑步之间的插值系数(布景里跟着逻辑层走的东西用)

var battle: Battle
var catalog: Catalog
var fx: Fx
var views: Dictionary = {}          # uid -> UnitView
var proj_views: Dictionary = {}     # projectile id -> Node3D
var _held_seen: Dictionary = {}
var astro_rings: Dictionary = {}    # 星旅节点：uid -> {unit, node} 嘲讽范围的地面圈
var astro_forms: Dictionary = {}    # 星旅节点：uid -> {unit, node} 锁血时的真实形态(EldritchForm：虚空之池 + 触手 + 眼睛)
var astro_comets: Dictionary = {}   # 星旅节点：uid -> 坠落的拖尾     # 完美时计：projectile id -> 上次看到的阶段(out / hover / in)，换阶段时放停住的闪光、开关拖尾
var thrown_views: Dictionary = {}   # 投掷 id -> {node, spin, start_y}：飞行中的武器(狩胜节点·必胜)；命中后 stuck = 插在地上等她扑过来拿
var weapon_flames: Dictionary = {}  # 单位 uid -> 武器上的火(WeaponFlame：狩胜节点·光荣的层数)
var beast_spirits: Dictionary = {}  # 单位 uid -> 背后灵(BeastSpirit：守林节点的兽形——狮子 / 巨蛛 / 巨蟾)
var intox_marks: Dictionary = {}    # 单位 uid -> 头部周围的沉醉音符(IntoxMarks：共歌节点·美妙地的层数)
var song_auras: Dictionary = {}     # 单位 uid -> 共歌节点身上一直冒的泡泡
var gentle_fx: Dictionary = {}      # 共歌节点 uid -> 温柔地的水下梦境 {dom: DomainFX(同时只开一个), bub: 满场的泡泡}
var _song_acc := 0.0
var funeral_wreaths: Dictionary = {} # 单位 uid -> 绕着飞的黑蝶(FuneralWreath：白羽节点·送葬的层数)
var funeral_scars: Dictionary = {}   # 单位 uid -> [身上停着的黑蝶](送葬之痕：精英 / 首领，最多 3 只)
var funeral_doomed: Dictionary = {}  # 单位 uid -> true：送葬满层倒下(阵亡时不倒地，身体直接化成蝴蝶)
var butterfly_auras: Dictionary = {} # 白羽节点 uid -> 身边常驻的两黑两白(ButterflyAura)
var _wreath_clear: Array[BUnit] = [] # 这一帧送葬层数清零的单位：满层结算的 funeral 事件紧跟在后面，先别收，帧末再收
var _dart_n := 0
var shadow_auras: Dictionary = {}    # 单位 uid -> 凝暗的黑烟 + 青色碎光(踏影节点)
var shadow_blades: Dictionary = {}   # 单位 uid -> 剑上的诛影影火(挂在武器骨上)
var link_markers: Dictionary = {}   # 单位 uid -> 脚下的增幅链路六边形(RX 增幅中继给的)
var _muzzle_n: Dictionary = {}       # 机械炮台 / 载具：这一枪从哪根炮管出(左右轮流)
var chain_arcs: Dictionary = {}      # 导向节点 uid(追击副本 + "c") -> 这一串连锁闪电已经画出来的每一节(LightningArc)
var quarry_uid: Dictionary = {}     # 队伍 -> 当前狩猎对象的 uid(头顶插旗)
var glory_seen: Dictionary = {}     # uid -> 上次显示的光荣层数
var charges: Dictionary = {}        # uid -> 拉弓蓄力的光点(Fx.charge)
var field_views: Dictionary = {}    # 地形 id -> 节点(稻田)
var dashing: Dictionary = {}        # uid -> {until, next}：冲锋中的单位(每隔一小段留一个残影)
var _text_gate: Dictionary = {}     # 高频飘字限流：key -> 下次允许的时刻(真实时间秒)
var skill_projs: Array = []          # 能力的投射物(光箭等)：{node, from, target, t, flight}，按真实时间飞向目标(目标会动就跟着)
var _hold: Dictionary = {}           # 正在派发的这一批事件里刚飞出去的符：它带来的治疗/伤害/净化先扣住，符落地时再播
var scars: Dictionary = {}           # 单位 uid -> {holder, marks:[刀痕节点]}：身上的剑痕(炽照节点·残光)
var _last_cut: Dictionary = {}       # 单位 uid -> 最近一刀拔刀术落在它身上的几何(_iaido_geom)：新的剑痕沿着这一刀留
var fishing: Dictionary = {}         # 钓鱼中的单位 uid -> {unit, target, prop, pull_until}：画鱼线(追猎节点·意外渔获)
var fish_lines: MeshInstance3D = null
var circles: Dictionary = {}         # 吟唱中的单位 uid -> 脚下的魔法阵(巫术节点)
var domains: Dictionary = {}         # 吟唱中的单位 uid -> 少女幻终的黑白领域(幻彩节点)
var paint_orbs: Dictionary = {}      # 单位 uid -> 身上颜料的发光块(幻彩节点·闪耀色彩)
var guidance_rings: Dictionary = {}  # 单位 uid -> 脚下的黄金的指引光环(真望节点)
var beams: Dictionary = {}           # 单位 uid -> {node, until, target}：嫉妒的余烬维持着的射线
var _wither_acc: Dictionary = {}     # "wither:uid" -> 还没飘字的生命上限损失(龙的余烬)
var keep_props: Dictionary = {}      # 单位 uid -> 吟唱期间一直拿着的道具(心音节点的鲁特琴：一段接一段演奏时不收)
var perf_links: Dictionary = {}      # 演奏者 uid -> {node, target, opt}：心音节点演奏期间连到演奏对象的五线谱光带
var ice_blocks: Dictionary = {}      # 单位 uid -> 冻结的冰块
var blood_orbs: Dictionary = {}      # 单位 uid -> {node, multi, center, target, next}：血嗜节点头顶 / 手里的血球(至亲的故事)
var blood_auras: Dictionary = {}     # 单位 uid -> 脚下往上飘的血雾(血欲的层数越多越浓)
var blood_land: Dictionary = {}      # 单位 uid -> 血球该落地的战斗时刻(逻辑层 throw_cast 给的；可能比 kin_tale 先到)
const BLOOD_FLIGHT_BIG := 0.3        # 吟唱的大血球飞多久(战斗秒)：落地时刻往前倒推这么久扔出去
const BLOOD_FLIGHT := 0.28
var stamen_buds: Dictionary = {}     # 单位 uid -> 头顶的花苞(正行节点·花蕊的层数)
var petal_swirls: Dictionary = {}    # 单位 uid -> 再绽之花吟唱时绕着她转的花瓣
var petal_seen: Dictionary = {}      # 单位 uid -> 上次看到的花瓣层数(涨了才飘花瓣)
var lily_counters: Dictionary = {}   # 单位 uid -> 脚下的百合(花瓣层数计数器，LilyCounter)
var phantoms: Dictionary = {}        # 单位 uid -> 身后的光之虚影(KnightPhantom；单位数据 phantom_fx：正行节点·百合骑士的骑士)
var light_beams: Dictionary = {}     # 单位 uid -> {node, ray, pulse}：灭罪节点的光束 + 她手里往天上射的细光(她是唯一的光)
var snipe_aims: Dictionary = {}      # 单位 uid -> {node, target, t0}：屏息节点瞄准时的激光 + 准星(瞄准眉心)
var mark_rings: Dictionary = {}      # 被标定的单位 uid -> 脚下的锁定准星(止息节点·画上句点)
var lunges: Dictionary = {}          # 突进中的止息节点 uid -> {prop, style, target, until, next}：手里换成微冲 / 匕首，结束换回来
var soul_domains: Dictionary = {}    # 吟唱中的单位 uid -> {node, unit, t0}：少女幻葬的灵魂领域(幻灵节点)
var glyph_domains: Dictionary = {}   # 吟唱中的单位 uid -> 少女幻嘘的文字领域(幻形节点)
var misled_marks: Dictionary = {}    # 单位 uid -> 头顶的误导"?"
var stun_marks: Dictionary = {}      # 单位 uid -> 头顶转的眩晕星星(锁芯节点锁住的：金锁 + 锁链)
var rite_circles: Dictionary = {}    # 锁芯节点 uid -> 脚下的血色仪式法阵
var gate_gauges: Dictionary = {}     # 锁芯节点 uid -> 脚下深空之门的计数石
var mood_notes: Dictionary = {}      # 单位 uid -> {"despair": 往下坠的暗红音符, "elation": 往上蹦的金色音符}
var _volt_next: Dictionary = {}      # 迅游节点 uid -> 下一次留残影 / 闪电的真实时刻(跑得越快留得越密)
var missiles: Array = []             # 飞行中的虹光飞弹：{node, start, p1, off2, target, delay, flight, t, color, launched}
var burn_fx: Dictionary = {}        # uid -> FireFX：身上【燃烧】的火苗
var tethers: MeshInstance3D = null  # 色欲的侵蚀：缠在一起的两个单位之间画一条扭动的熔岩触手
## 近战出手的顿帧(真实秒)：越重的武器停得越久；群攻招式另算
const HITSTOP := {"sword": 0.05, "polearm": 0.05, "heavy": 0.11, "dual": 0.035}
const ARROW_TIP := Vector3(-0.055, 0.79, 0.38)       # 拉满弦时箭头在模型里的位置(米，模型朝 +Z)
var speed: float = 1.0
var paused: bool = false
var running: bool = false
var _acc: float = 0.0
var _end_timer: float = -1.0
var _units_layer: Node3D
var _ended_emitted: bool = false


func _ready() -> void:
	_units_layer = Node3D.new()
	_units_layer.name = "Units"
	add_child(_units_layer)
	fx = Fx.new()
	fx.name = "Fx"
	add_child(fx)


func start(setup_data: Dictionary, cat: Catalog, seed_value: int) -> void:
	clear()
	catalog = cat
	battle = Battle.new(cat, seed_value)
	battle.setup(setup_data)
	for u: BUnit in battle.units:
		var v: UnitView = _add_view(u, u.team != GC.TEAM_PLAYER)
		if bool(u.meta.get("dropping", false)):
			v.fall_in(GC.START_DELAY / maxf(0.05, speed), 16.0)        # 还在天上(坠落事件来了再配拖尾)
		if u.team != GC.TEAM_PLAYER:
			var p := Vector3(u.pos.x, 0.0, u.pos.y)
			if u.def.model.begins_with("ember_"):
				# 余烬从熔岩里爬出来(那一种火的颜色)
				var boss_in: bool = bool(u.meta.get("boss", false))
				fx.ember_summon(p, _ident_color(u, Color("#ff5a1a")), 2.2 if boss_in else (1.4 if u.def.id.begins_with("elite_") else 1.0))
				if boss_in:
					shake.emit(0.12)
			else:
				# 敌人从遗迹四周现身：白金色的光圈 + 光柱
				fx.ring(p, 1.3, Color("#ffe6a8"), 0.7)
				fx.pillar(p, Color("#fff1c8"), 0.7)
	weather.emit("")
	battle.start()
	# 直接上场的星旅节点：脚下的嘲讽范围圈(坠落的那个落地时再加)
	for ua: BUnit in battle.units:
		if not bool(ua.meta.get("dropping", false)):
			for pa: AbilityDef in ua.def.passives:
				if pa.effect_type == "aura_taunt":
					_add_astro_ring(ua)
	for u2: BUnit in battle.units:
		var v2: UnitView = _view(u2)
		if v2 != null:
			v2.rotation.y = u2.facing
	running = true
	paused = false
	_ended_emitted = false
	_end_timer = -1.0
	_acc = 0.0
	set_speed(speed)


func clear() -> void:
	weather.emit("")
	for dd: Dictionary in [astro_rings, astro_forms]:
		for k: String in dd.keys():
			if is_instance_valid(dd[k]["node"]):
				(dd[k]["node"] as Node3D).queue_free()
		dd.clear()
	astro_comets.clear()
	running = false
	if fx != null:
		fx.speed_scale = 1.0                 # 战斗外(拾取、备战)的特效按原速放
	charges.clear()
	for fid: int in field_views.keys():
		var fv2: Node3D = field_views[fid]
		if is_instance_valid(fv2):
			fv2.queue_free()
	field_views.clear()
	for uid: String in views.keys():
		(views[uid] as UnitView).queue_free()
	views.clear()
	dashing.clear()
	if tethers != null:
		(tethers.mesh as ImmediateMesh).clear_surfaces()
	for bid: String in burn_fx.keys():
		if is_instance_valid(burn_fx[bid]):
			(burn_fx[bid] as Node).queue_free()
	burn_fx.clear()
	for sp2: Dictionary in skill_projs:
		if is_instance_valid(sp2["node"]):
			(sp2["node"] as Node3D).queue_free()
	skill_projs.clear()
	for sk: String in scars.keys():
		if is_instance_valid(scars[sk]["holder"]):
			(scars[sk]["holder"] as Node3D).queue_free()
	scars.clear()
	_last_cut.clear()
	fishing.clear()
	if fish_lines != null:
		(fish_lines.mesh as ImmediateMesh).clear_surfaces()
	for cu0: String in circles.keys():
		if is_instance_valid(circles[cu0]):
			(circles[cu0] as Node3D).queue_free()
	circles.clear()
	for sd0: String in soul_domains.keys():
		if is_instance_valid(soul_domains[sd0]["node"]):
			(soul_domains[sd0]["node"] as Node3D).queue_free()
	soul_domains.clear()
	for bm0: String in beams.keys():
		if is_instance_valid(beams[bm0]["node"]):
			(beams[bm0]["node"] as Node3D).queue_free()
	beams.clear()
	keep_props.clear()
	for pl: String in perf_links.keys():
		if is_instance_valid(perf_links[pl]["node"]):
			(perf_links[pl]["node"] as Node3D).queue_free()
	perf_links.clear()
	for bo0: String in blood_orbs.keys():
		if is_instance_valid(blood_orbs[bo0]["node"]):
			(blood_orbs[bo0]["node"] as Node3D).queue_free()
	blood_orbs.clear()
	blood_land.clear()
	petal_seen.clear()
	for gf0: String in gentle_fx.keys():
		for gn0: String in ["dom", "bub"]:
			if is_instance_valid(gentle_fx[gf0][gn0]):
				(gentle_fx[gf0][gn0] as Node3D).queue_free()
	gentle_fx.clear()
	for sc0: String in funeral_scars.keys():
		for sb0: Variant in funeral_scars[sc0]:
			if is_instance_valid(sb0):
				(sb0 as Node3D).queue_free()
	funeral_scars.clear()
	funeral_doomed.clear()
	_wreath_clear.clear()
	chain_arcs.clear()
	mood_notes.clear()
	for dd0: Dictionary in [domains, paint_orbs, glyph_domains, misled_marks, stun_marks, guidance_rings, ice_blocks, stamen_buds, petal_swirls, blood_auras, lily_counters, phantoms, weapon_flames, beast_spirits, intox_marks, song_auras, funeral_wreaths, butterfly_auras, shadow_auras, shadow_blades, link_markers, rite_circles, gate_gauges]:
		for k0: String in dd0.keys():
			if is_instance_valid(dd0[k0]):
				(dd0[k0] as Node3D).queue_free()
		dd0.clear()
	for ms0: Dictionary in missiles:
		if is_instance_valid(ms0["node"]):
			(ms0["node"] as Node3D).queue_free()
	missiles.clear()
	for id: int in proj_views.keys():
		(proj_views[id] as Node3D).queue_free()
	proj_views.clear()
	for tid: int in thrown_views.keys():
		var tn: Node3D = thrown_views[tid]["node"]
		if is_instance_valid(tn):
			tn.queue_free()
	thrown_views.clear()
	quarry_uid.clear()
	glory_seen.clear()
	battle = null


## 跳过：直接算完整场战斗(不播表现)，下一帧进入结算
func skip() -> void:
	if battle == null or not running:
		return
	var guard: int = int((GC.BATTLE_MAX_SECONDS + 8.0) / GC.SIM_DT)
	while battle.state != "ended" and guard > 0:
		battle.step()
		battle.events.clear()
		guard -= 1
	for uid: String in views.keys():
		var v: UnitView = views[uid]
		if v.bu != null and not v.bu.alive:
			v.dead_done = true
		v.update_battle(1.0)
	_end_timer = 5.0


func set_speed(s: float) -> void:
	speed = s
	if fx != null:
		fx.speed_scale = s                   # 慢放(×0.5 / ×0.25)时特效的动画也跟着慢下来
	for uid: String in views.keys():
		(views[uid] as UnitView).time_scale = s


func set_paused(p: bool) -> void:
	paused = p
	for uid: String in views.keys():
		var v: UnitView = views[uid]
		v.ap.speed_scale = 0.0 if p else maxf(v.ap.speed_scale, 0.01)


func _add_view(u: BUnit, dissolve_in: bool) -> UnitView:
	var v := UnitView.new()
	_units_layer.add_child(v)
	v.setup(u.def, u.star, u.team, bool(u.meta.get("boss", false)), u.weapon)
	v.bu = u
	v.time_scale = speed
	v.position = Vector3(u.pos.x, 0.0, u.pos.y)
	v.rotation.y = u.facing
	views[u.uid] = v
	if dissolve_in:
		v.set_dissolve(1.0)
		var tw: Tween = create_tween()
		tw.tween_method(v.set_dissolve, 1.0, 0.0, 0.6)
	return v


func _process(delta: float) -> void:
	if not running or battle == null:
		return
	if not paused:
		_acc += minf(delta, 0.1) * speed
		var guard := 0
		while _acc >= GC.SIM_DT and guard < 80:
			battle.step()
			_dispatch(battle.poll_events())
			_acc -= GC.SIM_DT
			guard += 1
			if battle.state == "ended":
				break
	var alpha: float = clampf(_acc / GC.SIM_DT, 0.0, 1.0)
	for uid: String in views.keys():
		var v: UnitView = views[uid]
		v.update_battle(alpha)
		# 闪电跑者：和本来有碰撞体积的东西(别人 / 地形 / 卡车)重叠时变成半透明紫色虚影；跑起来拖一串紫色残影
		if v.bu != null and v.bu.alive and v.bu.has_flag("petrified") != (v.stone_k > 0.5):
			v.set_stone(v.bu.has_flag("petrified"))                     # 石化(奇兴节点)：灰石、动作定住
		if v.bu != null and v.bu.has_flag("spectral"):
			v.ghost_target = 0.4 if v.bu.alive else 0.0              # 魂体存在：一直是半透明的灵体
		elif v.bu != null and v.bu.meta.has("phantom_of"):
			v.ghost_target = 0.55 if v.bu.alive else 0.0               # 逆时幻影(无我节点)：半透明的紫色虚影
		elif v.bu != null and v.bu.has_flag("shadowed"):
			v.ghost_target = 0.5 if v.bu.alive else 0.0                 # 凝暗(踏影节点)：在影子里——半透明的墨青色剪影，敌人选不中
		elif v.bu != null and v.bu.has_flag("phasing"):
			v.ghost_target = 1.0 if v.bu.alive and _overlapping(v.bu) else 0.0
			_volt_trail(v)
		# 摸鱼中：头上隔一会儿飘一串 Z z z
		if v.bu != null and v.bu.alive and battle.state == "running" and v.bu.has_flag("slacker") and _gate("zzz:" + uid, 3.2):
			fx.number(_chest(v.bu) + Vector3(0.25, 0.75, 0.0), "Z z z", Color("#a8c4ff"), 0.7, 0.7, 1.4)
	_update_projectiles(alpha)
	_update_thrown(alpha)
	synced.emit(alpha)
	_update_afterimages()
	_update_soul_domains()
	_update_magi_keep()
	_update_beams()
	_update_blood_orbs()
	_update_light_beams(alpha, delta)
	_update_snipe_aims()
	_update_marks()
	_update_volt()
	_update_lunges()
	_update_perform_links()
	_update_skill_projs(delta)
	_update_scars()
	_update_fishing()
	_update_missiles(delta)
	_update_tethers()
	_update_astro()
	_update_song(delta)
	# 清理已死亡的视图
	for uid2: String in views.keys():
		var v2: UnitView = views[uid2]
		if v2.dead_done:
			v2.queue_free()
			views.erase(uid2)
	if battle.state == "ended":
		if _end_timer < 0.0:
			_end_timer = 0.0
		_end_timer += delta
		if _end_timer > 1.4 and not _ended_emitted:
			_ended_emitted = true
			ended.emit(battle.winner)


# ---------------------------------------------------------------- 能力投射物(光箭)
func _update_skill_projs(delta: float) -> void:
	if skill_projs.is_empty():
		return
	var keep: Array = []
	var landed: Array = []
	for sp: Dictionary in skill_projs:
		var n: Node3D = sp["node"]
		if not is_instance_valid(n):
			continue
		sp["t"] = float(sp["t"]) + delta * (speed if not paused else 0.0)
		var tgt: BUnit = sp["target"]
		var to: Vector3 = _chest(tgt) if tgt != null else (sp["from"] as Vector3)
		var k: float = clampf(float(sp["t"]) / maxf(0.05, float(sp["flight"])), 0.0, 1.0)
		var pos: Vector3 = (sp["from"] as Vector3).lerp(to, k) + Vector3(0, sin(k * PI) * float(sp.get("arc", 0.35)), 0)
		var d: Vector3 = to - pos
		n.position = pos
		if sp.has("held"):
			# 符：不对准飞行方向，自己转着飞
			var card: Node3D = n.get_node_or_null("Card") as Node3D
			if card != null:
				card.rotation.y += delta * (speed if not paused else 0.0) * 9.0
		elif d.length() > 0.05:
			n.look_at(pos + d, Vector3.UP)
		if k >= 1.0:
			if sp.has("held"):
				landed.append(sp)
				fx.talisman_land(n, to, bool(sp["heal"]))
			else:
				n.queue_free()
				fx.burst(to, Color("#ffe27a"), 8, 2.0, 0.8, 0.6, 0.35)
			continue
		keep.append(sp)
	skill_projs = keep
	# 符落地：补播它带来的治疗 / 伤害 / 净化
	for sp3: Dictionary in landed:
		_dispatch(sp3["held"])


# ---------------------------------------------------------------- 虹光飞弹(巫术节点)
## 每帧：三次贝塞尔弧线——起点(杖尖) → 天上的控制点(每发方向不同) → 目标头顶 → 目标胸口(后两个跟着目标走)；到了炸开
func _update_missiles(delta: float) -> void:
	if missiles.is_empty():
		return
	var keep: Array = []
	var dt: float = delta * (speed if not paused else 0.0)
	for ms: Dictionary in missiles:
		var n: Node3D = ms["node"]
		if not is_instance_valid(n):
			continue
		ms["t"] = float(ms["t"]) + dt
		var tt: float = float(ms["t"]) - float(ms["delay"])
		if tt < 0.0:
			keep.append(ms)
			continue
		if not bool(ms["launched"]):
			ms["launched"] = true
			n.visible = true
			fx.burst(ms["start"], ms["color"], 4, 1.6, 0.5, 1.0, 0.25)
			fx.soft_flash(ms["start"], (ms["color"] as Color).lerp(Color.WHITE, 0.5), 0.45, 0.16, 1.6)
		var tgt: BUnit = ms["target"]
		var end: Vector3 = _chest(tgt) if tgt != null else (ms["start"] as Vector3)
		var p0: Vector3 = ms["start"]
		var p1: Vector3 = ms["p1"]
		var p2: Vector3 = Vector3(end.x, 0.0, end.z) + (ms["off2"] as Vector3)
		var k: float = clampf(tt / maxf(0.05, float(ms["flight"])), 0.0, 1.0)
		var u: float = 1.0 - k
		var pos: Vector3 = p0 * (u * u * u) + p1 * (3.0 * u * u * k) + p2 * (3.0 * u * k * k) + end * (k * k * k)
		n.position = pos
		if k >= 1.0:
			fx.missile_impact(n, end, ms["color"], str(ms.get("kind", "")))
			continue
		keep.append(ms)
	missiles = keep


func _end_keep_prop(uid: String) -> void:
	var prop: String = str(keep_props.get(uid, ""))
	keep_props.erase(uid)
	var v: UnitView = views.get(uid, null)
	if v != null and prop != "":
		v.chant_anim = ""
		v.set_prop(prop, false)


# ---------------------------------------------------------------- 钓鱼(追猎节点·意外渔获)
func _end_fishing(uid: String) -> void:
	var rec: Dictionary = fishing.get(uid, {})
	fishing.erase(uid)
	var v: UnitView = views.get(uid, null)
	if v != null and not rec.is_empty():
		v.chant_anim = ""
		v.set_prop(str(rec.get("prop", "")), false)


## 每帧：鱼线 = 竿尖到目标胸口的一根下垂的细线，目标脚下一个浮漂；起竿后线跟着被拽过来的目标，0.6 秒后收竿
func _update_fishing() -> void:
	if fish_lines == null:
		fish_lines = MeshInstance3D.new()
		fish_lines.mesh = ImmediateMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.92, 0.95, 1.0, 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		fish_lines.material_override = m
		fish_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fish_lines)
	var im: ImmediateMesh = fish_lines.mesh as ImmediateMesh
	im.clear_surfaces()
	if fishing.is_empty():
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var cam: Camera3D = get_viewport().get_camera_3d()
	var drew := false
	for uid: String in fishing.keys():
		var rec: Dictionary = fishing[uid]
		var u: BUnit = rec["unit"]
		var v: UnitView = views.get(uid, null)
		var tgt: BUnit = rec.get("target") as BUnit
		var pu: float = float(rec.get("pull_until", -1.0))
		if v == null or u == null or not u.alive or (pu > 0.0 and now >= pu):
			_end_fishing(uid)
			continue
		if tgt == null or not tgt.alive:
			continue
		var tip: Vector3 = v.bone_point("Hand_L", Vector3(16.0, 44.0 + 78.0, 3.0))
		var end: Vector3 = _chest(tgt) if pu > 0.0 else Vector3(tgt.pos.x, 0.12, tgt.pos.y)
		var sag: float = 0.0 if pu > 0.0 else clampf(tip.distance_to(end) * 0.12, 0.1, 0.6)
		var right: Vector3 = Vector3.RIGHT
		if cam != null:
			right = cam.global_transform.basis.x
		if not drew:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			drew = true
		var n := 14
		for i in range(n):
			var a0: float = float(i) / float(n)
			var a1: float = float(i + 1) / float(n)
			var p0: Vector3 = tip.lerp(end, a0) - Vector3(0, sag * 4.0 * a0 * (1.0 - a0), 0)
			var p1: Vector3 = tip.lerp(end, a1) - Vector3(0, sag * 4.0 * a1 * (1.0 - a1), 0)
			var w: Vector3 = right * 0.008
			im.surface_add_vertex(p0 - w)
			im.surface_add_vertex(p0 + w)
			im.surface_add_vertex(p1 + w)
			im.surface_add_vertex(p0 - w)
			im.surface_add_vertex(p1 + w)
			im.surface_add_vertex(p1 - w)
		# 浮漂(钓着的时候)：目标脚下一个红白的小方块
		if pu <= 0.0:
			var bob: float = 0.03 * sin(now * 6.0)
			var c: Vector3 = end + Vector3(0, 0.04 + bob, 0)
			for q: Array in [[Vector3(-0.05, 0.0, 0.0), Vector3(0.05, 0.0, 0.0), Vector3(0.0, 0.1, 0.0)]]:
				im.surface_add_vertex(c + (q[0] as Vector3))
				im.surface_add_vertex(c + (q[1] as Vector3))
				im.surface_add_vertex(c + (q[2] as Vector3))
	if drew:
		im.surface_end()


# ---------------------------------------------------------------- 剑痕(炽照节点·残光)
## 刀口数对齐层数：多了就补(沿着最近砍在它身上的那一刀留；没有就按正面一刀估)，变成 0(被驱散 / 持有者倒下)就淡掉。
## 刀痕挂在目标模型下面，跟着它走、转、变大。引爆走 status_burst，那时刀口已经炸掉了
## 花蕊的花苞：层数变了就整圈换掉(0 = 拿掉)
func _sync_stamens(u: BUnit, n: int) -> void:
	if u == null:
		return
	if stamen_buds.has(u.uid):
		if is_instance_valid(stamen_buds[u.uid]):
			(stamen_buds[u.uid] as Node3D).queue_free()
		stamen_buds.erase(u.uid)
	var v: UnitView = _view(u)
	if n > 0 and v != null and u.alive:
		stamen_buds[u.uid] = fx.stamen_buds(v, Vector3(0.0, v.body_height + 0.2, 0.0), n)


## 狩胜节点武器上的火(第一次有光荣时挂上；拿什么大类的武器就沿哪一段刃冒火)
func _weapon_flame(u: BUnit) -> WeaponFlame:
	if u == null or not u.alive:
		return null
	if weapon_flames.has(u.uid) and is_instance_valid(weapon_flames[u.uid]):
		return weapon_flames[u.uid]
	var v: UnitView = _view(u)
	if v == null:
		return null
	var wf: WeaponFlame = WeaponFlame.create(v, u.weapon_class())
	v.add_child(wf)
	weapon_flames[u.uid] = wf
	return wf


## 光之虚影(phantom_fx)：开打时在她身后浮现
func _spawn_phantom(u: BUnit) -> void:
	if phantoms.has(u.uid) and is_instance_valid(phantoms[u.uid]):
		return
	var v: UnitView = _view(u)
	var kp: KnightPhantom = KnightPhantom.create(v, u.def.phantom_fx)
	if kp == null:
		return
	add_child(kp)
	phantoms[u.uid] = kp
	fx.soft_flash(kp.global_position + Vector3(0.0, v.body_height * 0.8, 0.0), kp.color, 1.6, 0.4, 1.2)


## 正行节点脚下的百合(花瓣计数器)：第一次有花瓣事件时挂上
func _lily_counter(u: BUnit) -> LilyCounter:
	if u == null or not u.alive:
		return null
	if lily_counters.has(u.uid) and is_instance_valid(lily_counters[u.uid]):
		return lily_counters[u.uid]
	var v: UnitView = _view(u)
	if v == null:
		return null
	var lc := LilyCounter.new()
	lc.follow = v
	lc.chest_h = v.body_height * 0.72
	add_child(lc)
	lily_counters[u.uid] = lc
	return lc


## 血欲的血雾：第一次有层数时挂上(跟着模型走)，之后只改浓度(0 = 停止冒雾)
func _sync_blood_aura(u: BUnit, n: int) -> void:
	if u == null:
		return
	if not blood_auras.has(u.uid):
		var v: UnitView = _view(u)
		if n <= 0 or v == null or not u.alive:
			return
		blood_auras[u.uid] = fx.blood_aura(v, u.def.radius * 0.9)
	var p: GPUParticles3D = blood_auras[u.uid] as GPUParticles3D
	if is_instance_valid(p):
		p.amount_ratio = clampf(float(n) / 12.0, 0.0, 1.0) if u.alive else 0.0


func _sync_scars(u: BUnit, n: int) -> void:
	if u == null:
		return
	var v: UnitView = _view(u)
	var rec: Dictionary = scars.get(u.uid, {})
	if rec.is_empty():
		if n <= 0 or v == null:
			return
		rec = {"holder": fx.scar_holder(v.model), "marks": []}
		scars[u.uid] = rec
	var marks: Array = rec["marks"]
	if n <= 0:
		fx.scar_fade(marks)
		rec["marks"] = []
		return
	while marks.size() < n:
		var g: Dictionary = _last_cut.get(u.uid, {})
		if g.is_empty() or v == null:
			g = _cut_fallback(u)
		marks.append(fx.scar_mark(rec["holder"], g["center"], g["toward"], g["normal"], float(g["sweep"]), float(g["radius"])))
	while marks.size() > n:
		fx.scar_fade([marks.pop_back()])


## 每帧：持有者没了就把剑痕收掉(刀痕本身挂在模型下面，不用每帧摆)
func _update_scars() -> void:
	if scars.is_empty():
		return
	for uid: String in scars.keys():
		var rec: Dictionary = scars[uid]
		var h: Node3D = rec["holder"]
		var v: UnitView = views.get(uid, null)
		if v == null or v.bu == null or not v.bu.alive or not is_instance_valid(h):
			if is_instance_valid(h):
				fx.scar_fade(rec["marks"])
				var hh: Node3D = h
				get_tree().create_timer(0.4).timeout.connect(func() -> void:
					if is_instance_valid(hh):
						hh.queue_free())
			scars.erase(uid)
			_last_cut.erase(uid)
			continue


## 拔刀术这一刀落在目标身上的几何(世界)：光弧圆心 = 目标中心(刀砍到的高度)、toward = 目标 → 出刀的人(水平)、
## normal = 刀的挥动平面(出刀者刀光最近两次取样)、sweep = 刀在接触点的走向、radius ≈ 目标身体的半径(按碰撞半径估)。
## 大体型(巨龙)的刀痕落在它被砍到的高度(盘起来的身子上)，不再飘在胸口那么高
func _iaido_geom(u: BUnit, t: BUnit) -> Dictionary:
	var g: Dictionary = _cut_fallback(t, u)
	var va: UnitView = _view(u)
	var sw: Dictionary = va.blade_swing() if va != null else {}
	if sw.is_empty():
		return g
	var base: Vector3 = sw["base"]
	var tip: Vector3 = sw["tip"]
	var nn: Vector3 = ((sw["prev_tip"] as Vector3) - base).cross(tip - base)
	if nn.length() > 1e-6:
		var normal: Vector3 = nn.normalized()
		g["normal"] = normal
		var mv: Vector3 = tip - (sw["prev_tip"] as Vector3)
		g["sweep"] = 1.0 if mv.dot(normal.cross(g["toward"])) >= 0.0 else -1.0
	var vt: UnitView = _view(t)
	var th: float = vt.body_height if vt != null else 1.3
	var c: Vector3 = g["center"]
	c.y = clampf(((base + tip) * 0.5).y, th * 0.22, th * 0.8)
	g["center"] = c
	if OS.get_cmdline_user_args().has("cutlog"):
		print("CUT anim=%s @%.3f n=%s sweep=%.0f h=%.2f r=%.2f" % [va.ap.current_animation, va.ap.current_animation_position, str((g["normal"] as Vector3).snapped(Vector3.ONE * 0.01)), g["sweep"], c.y, g["radius"]])
	return g


## 没有刀光取样时(别的来源挂的剑痕、离线测试)：按"从出刀者那边横着砍过来"估
func _cut_fallback(t: BUnit, u: BUnit = null) -> Dictionary:
	var vt: UnitView = _view(t)
	var tpos: Vector3 = vt.global_position if vt != null else Vector3(t.pos.x, 0.0, t.pos.y)
	var toward := Vector3(sin(t.facing), 0.0, cos(t.facing))
	if u != null:
		var va: UnitView = _view(u)
		var apos: Vector3 = va.global_position if va != null else Vector3(u.pos.x, 0.0, u.pos.y)
		var d: Vector3 = apos - tpos
		d.y = 0.0
		if d.length() > 0.01:
			toward = d.normalized()
	var th: float = vt.body_height if vt != null else 1.3
	var tilt: Vector3 = Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5)).normalized()
	return {"center": Vector3(tpos.x, th * 0.5, tpos.z), "toward": toward, "normal": tilt, "sweep": 1.0 if randf() < 0.5 else -1.0,
		"radius": clampf(t.radius * 0.72, 0.24, 2.2)}


# ---------------------------------------------------------------- 色欲的侵蚀：缠在一起的单位之间的触手
func _update_tethers() -> void:
	if battle == null:
		return
	if tethers == null:
		tethers = MeshInstance3D.new()
		tethers.mesh = ImmediateMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		tethers.material_override = m
		tethers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tethers)
	var im: ImmediateMesh = tethers.mesh as ImmediateMesh
	im.clear_surfaces()
	var pairs: Array = []
	for u: BUnit in battle.units:
		if not u.alive:
			continue
		for st: BStatus in u.status_instances("lust_bind"):
			for pid: Variant in st.meta.get("partners", []):
				var o: BUnit = battle.get_unit_by_uid(str(pid))
				if o != null and o.alive and u.uid < o.uid:
					pairs.append([u, o])
	if pairs.is_empty():
		return
	var tt: float = float(Time.get_ticks_msec()) * 0.001
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for pr: Array in pairs:
		var a: Vector3 = _chest(pr[0]) + Vector3(0, -0.25, 0)
		var b: Vector3 = _chest(pr[1]) + Vector3(0, -0.25, 0)
		var d: Vector3 = b - a
		var side: Vector3 = d.cross(Vector3.UP).normalized() * 0.06
		var n := 10
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for i in range(n + 1):
			var k: float = float(i) / float(n)
			var wob: Vector3 = Vector3(0, sin(k * PI) * 0.25 + sin(tt * 6.0 + k * 9.0) * 0.06 * sin(k * PI), 0) + side * 2.0 * sin(tt * 5.0 + k * 7.0) * sin(k * PI)
			var c: Vector3 = a.lerp(b, k) + wob
			var w: float = lerpf(1.0, 0.6, absf(k - 0.5) * 2.0)
			var l: Vector3 = c + side * w
			var r: Vector3 = c - side * w
			if i > 0:
				var col := Color(1.0, 0.22 + 0.2 * sin(tt * 8.0 + k * 6.0), 0.62 + 0.15 * sin(tt * 5.0 + k * 4.0), 1.0)     # 色欲的玫红
				for v: Vector3 in [prev_l, l, r, prev_l, r, prev_r]:
					im.surface_set_color(col)
					im.surface_add_vertex(v)
			prev_l = l
			prev_r = r
	im.surface_end()


# ---------------------------------------------------------------- 冲锋残影
## 穿模的单位此刻和别人的身体 / 挡路的地形重叠着
func _overlapping(u: BUnit) -> bool:
	if not battle.map.circle_free(u.pos, u.radius * 0.6):
		return true
	for o: BUnit in battle.units:
		if o != u and o.alive and not bool(o.meta.get("dropping", false)) and o.pos.distance_to(u.pos) < (o.radius + u.radius) * 0.85:
			return true
	return false


## 闪电跑者的拖尾：移动速度 3 米/秒以上时，每隔一小段留一个紫色残影，脚边偶尔窜一道小闪电
func _volt_trail(v: UnitView) -> void:
	var u: BUnit = v.bu
	var spd: float = u.vel.length()
	if not u.alive or spd < 3.0 or battle.state != "running":
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < float(_volt_next.get(u.uid, 0.0)):
		return
	_volt_next[u.uid] = now + clampf(0.5 / spd, 0.03, 0.14) / maxf(1.0, speed)
	fx.afterimage(v.model, Color(0.66, 0.4, 1.0), 0.22, 0.4)
	if randf() < 0.35:
		var back: Vector3 = Vector3(-u.vel.x, 0.0, -u.vel.y).normalized()
		var p0: Vector3 = Vector3(u.pos.x, 0.25, u.pos.y)
		fx.lightning(p0, p0 + back * 0.8 + Vector3(0, 0.25, 0), Fx.VOLT, 0.035, 0.14, 3)


## 少女幻葬的领域：灵魂随吟唱时间(每秒一个)和吟唱期间的阵亡数(每个两个)变多
## 嫉妒的余烬的射线：最后一次出手后 until 秒内一直连着眼睛和目标(目标倒下 / 自己倒下就收掉)
## 吟唱中的血球：慢慢长大，不断有血从目标身上 / 周围飘进去
## 灭罪节点的光束：位置 / 半径每帧从 unit.meta.light_beam 读(按 alpha 在上一步和这一步之间插值)；她手里的光之心往天上射一道细光
func _update_light_beams(alpha: float, delta: float) -> void:
	for uid: String in light_beams.keys():
		var lbv: Dictionary = light_beams[uid]
		var bu: BUnit = battle.get_unit_by_uid(uid)
		var lb: Dictionary = bu.meta.get("light_beam", {}) if bu != null else {}
		if lb.is_empty() or battle.state == "ended":
			_end_light_beam(uid)
			continue
		var p: Vector2 = (lb["prev"] as Vector2).lerp(lb["pos"] as Vector2, alpha)
		lbv["pulse"] = maxf(0.0, float(lbv["pulse"]) - delta * 4.0 * maxf(1.0, speed))
		fx.light_beam_set(lbv["node"], Vector3(p.x, 0.0, p.y), float(lb.get("rad", 2.4)), float(lbv["pulse"]))
		var v: UnitView = _view(bu)
		if v != null:
			fx.light_ray_set(lbv["ray"], v.bone_point("Bow", LIGHT_ORB), float(lbv["pulse"]))


## 屏息节点瞄准：激光从枪口连到目标胸口，准星在目标脚下；瞄了 3 秒以上就是最亮最紧(瞄准眉心最长 10 秒)
## 滑铲到一半：匕首从目标身侧划过的那一下
func _lunge_cut(u: BUnit, t: BUnit) -> void:
	if t != null and t.alive and u != null:
		fx.knife_slash(_chest(t), Vector3(t.pos.x - u.pos.x, 0.0, t.pos.y - u.pos.y).normalized())


func _update_snipe_aims() -> void:
	for uid: String in snipe_aims.keys():
		var sa: Dictionary = snipe_aims[uid]
		var su: BUnit = battle.get_unit_by_uid(uid)
		var st: BUnit = su.attack_target if su != null else null
		if su == null or not su.alive or su.phase != "draw" or st == null or not st.alive:
			_end_snipe_aim(uid)
			continue
		var sv: UnitView = _view(su)
		var tv: UnitView = _view(st)
		var from: Vector3 = sv.bone_point("Bow", SNIPER_MUZZLE) if sv != null and su.weapon_class() == "rifle" else _chest(su)
		var ground: Vector3 = tv.global_position if tv != null else Vector3(st.pos.x, 0.0, st.pos.y)
		var k: float = clampf((battle.time - float(sa["t0"])) / 3.0, 0.0, 1.0)
		var scope: Vector3 = sv.bone_point("Bow", SNIPER_SCOPE) if sv != null and su.weapon_class() == "rifle" else Vector3.INF
		fx.sniper_aim_set(sa["node"], from, _chest(st), ground, k, battle.time * 1.2, scope)


## 标定：脚下的锁定准星跟着单位走，3 秒里慢慢收紧；标定没了(被免费弹道消耗)就收掉
func _update_marks() -> void:
	for u: BUnit in battle.units:
		var st: BStatus = u.get_status("commando_mark") if u.alive else null
		if st == null:
			if mark_rings.has(u.uid):
				fx.mark_ring_end(mark_rings[u.uid], u.alive)
				mark_rings.erase(u.uid)
			continue
		if not mark_rings.has(u.uid):
			mark_rings[u.uid] = fx.mark_ring()
		var v: UnitView = _view(u)
		var at: Vector3 = v.global_position if v != null else Vector3(u.pos.x, 0.0, u.pos.y)
		var k: float = clampf((battle.time - float(st.meta.get("t0", battle.time))) / 3.0, 0.0, 1.0)
		fx.mark_ring_set(mark_rings[u.uid], at, u.radius / 0.42, k, battle.time * 1.5)


## 引雷(导向节点)：吟唱(普攻的拉弓阶段)时身上噼啪作响，越接近吟唱满越密；【麻痹】的人隔一会儿身上闪一下电光
func _update_volt() -> void:
	if battle.state != "running":
		return
	for u: BUnit in battle.units:
		if not u.alive:
			continue
		if u.phase == "draw" and not u.chain_cfg().is_empty():
			var k: float = clampf(u.phase_t / maxf(0.1, u.draw_dur), 0.0, 1.0)
			if _gate("volt:" + u.uid, lerpf(0.16, 0.06, k)):
				var v: UnitView = _view(u)
				var hand: Vector3 = v.bone_origin("Bow") if v != null else _chest(u)
				if hand.y < 0.3:
					hand = _chest(u)
				fx.volt_crackle(_chest(u), hand, k)
		if u.get_status("paralysis") != null and _gate("pzap:" + u.uid, 0.55):
			fx.paralysis_zap(_chest(u), false)


## 突进中：空翻时一路朝目标开枪(每 0.08 秒一团枪口火光)；突进完(落地 / 倒下)把手里的道具换回原来的武器
func _update_lunges() -> void:
	for uid: String in lunges.keys():
		var ld: Dictionary = lunges[uid]
		var lu: BUnit = battle.get_unit_by_uid(uid)
		var lv: UnitView = _view(lu) if lu != null else null
		if lu == null or not lu.alive or lu.phase != "dash":
			if lv != null:
				lv.set_prop(str(ld["prop"]), false)
				lv.set_weapon_hidden(false)
			lunges.erase(uid)
			continue
		var lt: BUnit = ld.get("target") as BUnit
		if str(ld["style"]) == "flip" and lv != null and lt != null and lt.alive and battle.time >= float(ld["next"]):
			ld["next"] = battle.time + 0.08
			var mz: Vector3 = lv.bone_point("Bow", SNIPER_MUZZLE_SMG)
			fx.smg_burst(mz, (_chest(lt) - mz).normalized())


const SNIPER_MUZZLE_SMG := Vector3(-16.5, 22.0, 7.5)   # 黑色任务 / 突进微冲的枪口(体素，挂 Bow；tools/model_weapons.gd black_mission：y -22 + 44)


func _end_snipe_aim(uid: String) -> void:
	if snipe_aims.has(uid):
		fx.sniper_aim_end(snipe_aims[uid]["node"])
		snipe_aims.erase(uid)


const SNIPER_MUZZLE := Vector3(-16.5, -16.0, 6.5)    # 黑色战场 / 步枪的枪口(体素，挂 Bow；tools/model_weapons.gd sniper_rifle)
## 蓝之章的机械造物：身份色、炮口(挂 Chest 的体素坐标，左右轮流开火)、天线 / 力场发射器的位置，big = 炮台 / 载具(整台炸开，不倒地)
const MECH := {
	"turret_sentry": {"col": "#ffb84a", "big": true, "muzzles": [Vector3(-5.5, 42.0, 39.0), Vector3(4.5, 42.0, 39.0)]},
	"vehicle_field": {"col": "#4fd2ff", "big": true, "muzzles": [Vector3(-2.5, 38.0, 27.5), Vector3(1.5, 38.0, 27.5)],
		"emitter": Vector3(-0.5, 44.0, -12.0)},
	"droid_relay": {"col": "#5dffc8", "big": false, "antenna": Vector3(-3.5, 97.0, -9.5)},
	"droid_assault": {"col": "#ff4d6d", "big": false},
}
const SELFLESS_DRAW := 0.48       # 无我：draw_killer 拔到这一刻刀出鞘(一闪)
const SELFLESS_HOLD := 0.6        # 一闪之后定格(黑白)多久，刀痕才"落下"(崩散)
const PAL_HAMMER_HEAD := Vector3(-16.0, 104.0, 3.0)   # 圣战节点的战锤锤头(挂 Bow；W_heavy_warhammer 锤头在柄上 y 52..69)
const PAL_BLADE_TIP := Vector3(-16.0, 90.0, 3.0)      # 拿剑 / 长柄时取武器前段
const SNIPER_SCOPE := Vector3(-16.5, 16.0, 12.5)     # 瞄准镜前镜片(反光的星芒；sniper_rifle 的镜片 y -28、z 9..11)
const SNIPER_PORT := Vector3(-18.5, 40.0, 8.0)       # 抛壳口(机匣右侧，拉机柄前面)


func _end_light_beam(uid: String) -> void:
	if not light_beams.has(uid):
		return
	fx.light_beam_end(light_beams[uid]["node"])
	fx.light_ray_end(light_beams[uid]["ray"])
	if is_instance_valid(light_beams[uid].get("aura")):
		(light_beams[uid]["aura"] as SaintAura).end()
	light_beams.erase(uid)


const LIGHT_ORB := Vector3(-16.5, 43.5, 12.6)     # 光之心的球心(体素，挂 Bow；tools/model_weapons.gd light_heart)


func _update_blood_orbs() -> void:
	for uid: String in blood_orbs.keys():
		var rec: Dictionary = blood_orbs[uid]
		var node: Node3D = rec["node"]
		var u: BUnit = battle.get_unit_by_uid(uid)
		if not is_instance_valid(node):
			blood_orbs.erase(uid)
			continue
		var chant: bool = bool(rec.get("chant", false))
		# 什么时候扔：逻辑层的 throw_cast 给出落地时刻(= 武器效果结算的那一刻)，按飞行时间倒推出手；倒下了也照样扔(落地照样结算)
		if blood_land.has(uid) and not rec.has("land_at"):
			rec["land_at"] = float(blood_land[uid])
			blood_land.erase(uid)
		if rec.has("land_at"):
			if battle.time >= float(rec["land_at"]) - (BLOOD_FLIGHT_BIG if chant else BLOOD_FLIGHT) or u == null or not u.alive:
				_launch_blood_orb(uid, maxf(0.04, float(rec["land_at"]) - battle.time))
				continue
		elif u == null or not u.alive:
			node.queue_free()
			blood_orbs.erase(uid)
			continue
		elif battle.time - float(rec.get("released", rec["t0"])) > (0.6 if rec.has("released") or not chant else 1.0e9):
			_launch_blood_orb(uid, BLOOD_FLIGHT)         # 等不到 throw_cast(武器效果没结算)：按默认扔出去，别一直挂在手上
			continue
		# 血球托在手上：吟唱时在两手之间往上一点(球底贴着手心)，否则在左手心上
		var bv: UnitView = _view(u)
		if bv != null:
			var hand: Vector3 = (bv.bone_origin("Hand_L") + bv.bone_origin("Hand_R")) * 0.5 if chant else bv.bone_origin("Hand_L")
			node.global_position = hand + Vector3(0.0, (0.42 * node.scale.x * 0.9 + 0.05) if chant else 0.13, 0.0)
		if not chant or rec.has("released"):
			continue
		var k: float = clampf((battle.time - float(rec["t0"])) / maxf(0.3, float(rec["dur"])), 0.0, 1.0)
		node.scale = Vector3.ONE * lerpf(0.35, 1.0, k)
		if battle.time >= float(rec["next"]):
			rec["next"] = battle.time + 0.16
			# 血从圆里的敌人身上流过来(轮流)；圆里没人了就从他脚下的地上升起来
			var live: Array = []
			for tu: Variant in rec.get("targets", []):
				if tu is BUnit and (tu as BUnit).alive:
					live.append(tu)
			var src: Vector3
			if live.is_empty():
				var ga: float = randf() * TAU
				src = Vector3(u.pos.x + cos(ga) * 0.9, 0.05, u.pos.y + sin(ga) * 0.9)
			else:
				rec["turn"] = int(rec.get("turn", 0)) + 1
				src = _chest(live[int(rec["turn"]) % live.size()] as BUnit)
			fx.blood_stream(src, node)


## 血球扔出去(flight = 飞多久，落地那一刻 = 武器效果结算)：群攻 = 原样砸到目标所在的地点(血浪)，否则拉成血矛射实际的那个目标
func _launch_blood_orb(uid: String, flight: float) -> void:
	var rec: Dictionary = blood_orbs.get(uid, {})
	blood_orbs.erase(uid)
	if rec.is_empty() or not is_instance_valid(rec["node"]):
		return
	var tgt: BUnit = rec.get("target") as BUnit
	if bool(rec["multi"]):
		var c: Vector2 = rec["center"]
		if tgt != null and tgt.alive:
			c = tgt.pos
		# 血浪推到血之圆的边
		fx.blood_throw(rec["node"], Vector3(c.x, 0.0, c.y), float(rec.get("radius", 5.0)), bool(rec.get("chant", false)), flight)
	elif tgt != null:
		fx.blood_arrow(rec["node"], _chest(tgt), flight)
	else:
		(rec["node"] as Node3D).queue_free()


func _update_beams() -> void:
	for uid: String in beams.keys():
		var bd: Dictionary = beams[uid]
		var bu: BUnit = battle.get_unit_by_uid(uid)
		var bt: BUnit = bd["target"] as BUnit
		var node: Node3D = bd["node"]
		if bu == null or not bu.alive or bt == null or not bt.alive or battle.time > float(bd["until"]):
			if is_instance_valid(node):
				node.queue_free()
			beams.erase(uid)
			continue
		fx.beam_set(node, _envy_eye(bu), _chest(bt), 0.5 + 0.5 * sin(battle.time * 25.0))


## 嫉妒的余烬的眼睛(射线的起点)：身体中心往前一点
func _envy_eye(u: BUnit) -> Vector3:
	var v: UnitView = _view(u)
	var base: Vector3 = v.global_position if v != null else Vector3(u.pos.x, 0.0, u.pos.y)
	var fwd := Vector3(sin(v.rotation.y if v != null else u.facing), 0.0, cos(v.rotation.y if v != null else u.facing))
	return base + Vector3(0, ENVY_EYE.y * u.def.scale, 0) + fwd * ENVY_EYE.z * u.def.scale


const ENVY_EYE := Vector3(0.0, 0.895, 0.227)   # 眼睛正前方中心(米，未乘体型；挂 Neck)：tools/chars/ember_envy.gd 的 EYE_FRONT


## 少女幻终：她自己留着颜色(悬浮着，留色的圆柱跟着她的高度)
func _update_magi_keep() -> void:
	for uid: String in domains.keys():
		var v: UnitView = views.get(uid, null)
		if v == null:
			continue
		fx.magi_domain_keep(domains[uid], v.global_position, 0.55 * v.scale_mult, v.body_height + v._lev + 0.45)


func _update_soul_domains() -> void:
	for uid: String in soul_domains.keys():
		var sd: Dictionary = soul_domains[uid]
		var n: int = 4 + int(battle.time - float(sd["t0"])) + 2 * (battle.death_times.size() - int(sd["d0"]))
		fx.soul_domain_grow(sd["node"], n)


func _update_afterimages() -> void:
	if dashing.is_empty():
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	for uid: String in dashing.keys():
		var d: Dictionary = dashing[uid]
		var v: UnitView = views.get(uid, null)
		if v == null or now > float(d["until"]):
			dashing.erase(uid)
			continue
		if now >= float(d["next"]):
			d["next"] = now + 0.035 / maxf(1.0, speed)
			fx.afterimage(v.model, d["color"], 0.32)


## 远距离飞扑 / 突进的特效(时间和 UnitView 的 LEAP_PREP / LEAP_LAND 对上)：蹬地那一刻尘土 + 碎块 + 浅坑，空中拖残影，
## 砸地那一刻尘土冲击波 + 碎块 + 地坑 + 震屏；fire_k = 狩胜节点的光荣(0..1)：落地炸开的火
func _leap_fx(u: BUnit, from: Vector2, to: Vector2, dur: float, col: Color, fire_k: float, power: float = 1.0) -> void:
	var s0: float = maxf(0.1, speed)
	var dir := Vector3(to.x - from.x, 0.0, to.y - from.y)
	var t_up: float = dur * UnitView.LEAP_PREP / s0
	var t_down: float = dur * UnitView.LEAP_LAND / s0
	get_tree().create_timer(t_up).timeout.connect(func() -> void:
		fx.leap_takeoff(Vector3(from.x, 0.0, from.y), dir, col)
		dashing[u.uid] = {"until": Time.get_ticks_msec() / 1000.0 + (t_down - t_up), "next": 0.0, "color": col.lerp(Color("#ffb04a"), fire_k)})
	var pw: float = power * clampf(0.75 + from.distance_to(to) * 0.08, 0.8, 1.3)
	get_tree().create_timer(t_down).timeout.connect(func() -> void:
		fx.leap_land(Vector3(to.x, 0.0, to.y), dir, col, pw, fire_k)
		shake.emit(0.05 + 0.04 * pw))


## 时间停止(清扫节点·清洁世界)：dur = 停多久(真实秒)
## 共歌节点唱歌的出声处：拿着麦克风(单手剑大类)= 右手拳头上方的话筒头；拿别的武器 = 嘴边
func _song_mouth(u: BUnit) -> Vector3:
	var v: UnitView = _view(u)
	if v == null:
		return _chest(u) + Vector3(0.0, 0.3, 0.0)
	if u.weapon_class() == "sword":
		return v.bone_origin("Hand_R") + Vector3(0.0, 0.2, 0.0)
	return v.bone_origin("Head") + Vector3(sin(v.rotation.y), 0.0, cos(v.rotation.y)) * 0.18 + Vector3(0.0, 0.08, 0.0)


## 温柔地：整个战场沉进水下的梦(DomainFX lullaby，同时只开一个)+ 满场往上飘的泡泡；gentle_end 时收掉
func _gentle_open(u: BUnit) -> void:
	if gentle_fx.has(u.uid):
		_gentle_close(u)
	var at := Vector3(u.pos.x, 0.0, u.pos.y)
	var dm: DomainFX = null
	if gentle_fx.is_empty():
		dm = DomainFX.make("lullaby", at, 34.0, Color("#ffb0d8"))
		add_child(dm)
		dm.open(1.8, 0.0)
	var half := Vector2(GC.MAP_W, GC.MAP_H) * GC.CELL * 0.5
	gentle_fx[u.uid] = {"dom": dm, "bub": fx.gentle_bubbles(Vector3.ZERO, half)}


func _gentle_close(u: BUnit) -> void:
	if u == null or not gentle_fx.has(u.uid):
		return
	var g: Dictionary = gentle_fx[u.uid]
	gentle_fx.erase(u.uid)
	if is_instance_valid(g["dom"]):
		(g["dom"] as DomainFX).close(1.3, false)
	fx.gentle_bubbles_stop(g["bub"] as GPUParticles3D if is_instance_valid(g["bub"]) else null)
	fx.gentle_fade(Vector3(u.pos.x, 0.0, u.pos.y))


## 共歌节点：沉醉的层数标记(头部周围绕着转的音符；沉沦之梦挂着时变金 / 变紫)、她身上一直冒的泡泡。
## 每 0.15 秒按状态同步一次(永恒的沉醉是开战时直接挂回去的，不走状态事件)
func _update_song(delta: float) -> void:
	# 送葬清零了(不是满层结算：那个已经在 funeral 事件里扑进身体了)：黑蝶缩小散掉
	for wc0: BUnit in _wreath_clear:
		if wc0.status_stacks("funeral") > 0:
			continue
		if is_instance_valid(funeral_wreaths.get(wc0.uid)):
			(funeral_wreaths[wc0.uid] as FuneralWreath).set_stacks(0, 10)
		funeral_wreaths.erase(wc0.uid)
	_wreath_clear.clear()
	_song_acc += delta
	if _song_acc < 0.15:
		return
	_song_acc = 0.0
	for uid: String in views.keys():
		var v: UnitView = views[uid]
		var u: BUnit = v.bu
		if u == null:
			continue
		var n: int = u.status_stacks("intox") if u.alive else 0
		var mk0: Variant = intox_marks.get(uid)
		if n > 0:
			if not is_instance_valid(mk0):
				mk0 = IntoxMarks.create(fx, v, v.body_height - 0.04, 0.34)
				intox_marks[uid] = mk0
			var dm: int = 1 if not u.status_instances("dream_amp").is_empty() else (-1 if not u.status_instances("dream_sink").is_empty() else 0)
			(mk0 as IntoxMarks).set_state(n, dm)
		elif mk0 != null:
			if is_instance_valid(mk0):
				(mk0 as IntoxMarks).queue_free()
			intox_marks.erase(uid)
		# 踏影节点：凝暗 = 身上冒黑烟、虚影换成墨青；诛影 = 剑上缠着影火(层数越多越旺)
		var veil: int = u.status_stacks("shadow_veil") if u.alive else 0
		if veil > 0 or shadow_auras.has(uid):
			if not is_instance_valid(shadow_auras.get(uid)):
				shadow_auras[uid] = fx.shadow_aura(v, v.body_height)
			fx.shadow_aura_set(shadow_auras[uid], clampf(float(veil) / 3.0, 0.0, 1.0))
		if u.has_flag("shadowed"):
			v.set_ghost_tint(Color(0.03, 0.2, 0.26))
		var slay: int = u.status_stacks("shadow_slay") if u.alive and not v.weapon_hidden else 0
		if slay > 0 and not is_instance_valid(shadow_blades.get(uid)):
			var sbl: Node3D = fx.shadow_blade(v, WeaponFlame.BLADE.get(u.weapon_class(), [18.0, 58.0]))
			if sbl != null:
				shadow_blades[uid] = sbl
		if is_instance_valid(shadow_blades.get(uid)):
			fx.shadow_blade_set(shadow_blades[uid], clampf(float(slay) / 3.0, 0.0, 1.0))
		# 增幅链路挂着时：脚下一个慢慢转的薄荷色六边形
		var lk: int = u.status_stacks("amp_link") if u.alive else 0
		if lk > 0 and not is_instance_valid(link_markers.get(uid)):
			link_markers[uid] = fx.link_marker(v, u.radius * 1.05)
		elif lk <= 0 and is_instance_valid(link_markers.get(uid)):
			(link_markers[uid] as Node3D).queue_free()
			link_markers.erase(uid)
		# 锁芯节点：血色仪式 = 脚下一圈暗红的仪式法阵 + 血雾；深空之门 = 脚下一圈计数石(场上累计眩晕每满 1 秒亮一颗)
		if u.def.model == "keeper":
			var rite_on: bool = u.alive and u.status_stacks("blood_rite") > 0
			if rite_on and not is_instance_valid(rite_circles.get(uid)):
				rite_circles[uid] = fx.blood_rite_circle(v, u.radius * 2.7)
			elif not rite_on and rite_circles.has(uid):
				if is_instance_valid(rite_circles[uid]):
					(rite_circles[uid] as Node3D).queue_free()
				rite_circles.erase(uid)
			var gtg: TriggerDef = null
			for tg0: TriggerDef in u.all_triggers():
				if tg0.timing == "OnStunSecond":
					gtg = tg0
					break
			if gtg != null and u.alive:
				var gth: int = gtg.threshold_for(u.star)
				if not is_instance_valid(gate_gauges.get(uid)):
					gate_gauges[uid] = fx.gate_gauge(v, u.radius * 1.45, gth)
				fx.gate_gauge_set(gate_gauges[uid], int(u.counters.get(gtg.id, 0)), gth)
			elif gate_gauges.has(uid):
				if is_instance_valid(gate_gauges[uid]):
					(gate_gauges[uid] as Node3D).queue_free()
				gate_gauges.erase(uid)
		# 变奏节点的沮丧 / 亢奋：身上一直飘的音符(沮丧往下坠、亢奋往上蹦；层数越多越密)
		for mood: String in ["despair", "elation"]:
			var mn: int = u.status_stacks(mood) if u.alive else 0
			var md: Dictionary = mood_notes.get(uid, {})
			var mp: Variant = md.get(mood)
			if mn > 0 and not is_instance_valid(mp):
				mp = fx.stack_notes(v, v.body_height, mood == "elation")
				md[mood] = mp
				mood_notes[uid] = md
			if is_instance_valid(mp):
				(mp as GPUParticles3D).amount_ratio = clampf(0.15 + float(mn) / 9.0 * 0.85, 0.0, 1.0) if mn > 0 else 0.0
		# 白羽节点：身边常驻两黑两白
		if u.def.model == "angel" and u.alive and not is_instance_valid(butterfly_auras.get(uid)):
			butterfly_auras[uid] = ButterflyAura.create(fx, v, v.body_height * 0.72)
		if u.def.model == "pacifist":
			var au0: Variant = song_auras.get(uid)
			if u.alive and not is_instance_valid(au0):
				song_auras[uid] = fx.song_aura(v, v.body_height)
			elif not u.alive and is_instance_valid(au0):
				(au0 as GPUParticles3D).emitting = false


func _time_stop(u: BUnit, dur: float) -> void:
	var at := Vector3(u.pos.x, 0.0, u.pos.y)
	var dm: DomainFX = DomainFX.make("timestop", at, 32.0, Color("#9fd8ff"))
	add_child(dm)
	dm.open(0.35, 0.0)
	var v: UnitView = _view(u)
	dm.set_keep(at, 0.75, (v.body_height if v != null else 1.3) + 0.8)
	fx.timestop_clock(at, 2.2, dur)
	fx.soft_flash(_chest(u), Color("#e8f4ff"), 1.6, 0.25, 1.8)
	shake.emit(0.05)
	get_tree().create_timer(dur + 0.1).timeout.connect(func() -> void:
		if is_instance_valid(dm):
			dm.close(0.35, false)
		fx.ring(at + Vector3(0.0, 0.05, 0.0), 6.0, Color("#e8f4ff"), 0.45, 2.2, 0.05))


## 狩胜节点的光荣层数 → 火势(0..1)
func _glory_k(u: BUnit) -> float:
	if u == null:
		return 0.0
	return clampf(float(u.status_stacks("glory")) / 10.0, 0.0, 1.0)


## 命中后插在地上的武器：刃尖朝下往前斜插进地里(握柄露在外面)
func _plant_thrown(tv: Dictionary) -> void:
	if bool(tv.get("planted", false)):
		return
	tv["planted"] = true
	var node: Node3D = tv["node"]
	var st: Dictionary = tv["stuck"]
	var d: Vector3 = st["dir"]
	var h := Vector3(d.x, 0.0, d.z).normalized() if Vector3(d.x, 0.0, d.z).length() > 0.01 else Vector3(0, 0, 1)
	var axis: Vector3 = (h * 0.55 + Vector3(0.0, -1.0, 0.0)).normalized()          # 刃(局部 +Y)朝前下方
	var side: Vector3 = axis.cross(Vector3.UP).normalized() if absf(axis.y) < 0.99 else Vector3.RIGHT
	var k: float = float(tv.get("scale", 1.0))
	var blade: float = {"polearm": 1.07, "heavy": 0.97, "sword": 0.7, "dual": 0.34}.get(str(tv.get("wclass", "sword")), 0.7) * k
	var tip: Vector3 = (st["pos"] as Vector3) + h * 0.25 + Vector3(0.0, -0.12, 0.0)
	node.global_transform = Transform3D(Basis(side, axis, side.cross(axis)).scaled(Vector3.ONE * k), tip - axis * blade)
	fx.debris(st["pos"], h, 6, 2.4)


# ---------------------------------------------------------------- 投掷出去的武器(狩胜节点·必胜)
## 跟着逻辑层的飞行位置走：长矛像标枪一样矛尖朝前、走一道低弧线；别的武器在飞行面里翻滚着飞
func _update_thrown(alpha: float) -> void:
	if thrown_views.is_empty() or battle == null:
		return
	var live := {}
	for th: Dictionary in battle.thrown:
		live[int(th["id"])] = th
	for tid: int in thrown_views.keys():
		var tv: Dictionary = thrown_views[tid]
		var node: Node3D = tv["node"]
		if not live.has(tid) and tv.has("stuck") and is_instance_valid(node) and battle.time - float(tv["stuck"]["t"]) < 2.5:
			_plant_thrown(tv)
			continue
		if not live.has(tid) or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			thrown_views.erase(tid)
			continue
		var th2: Dictionary = live[tid]
		var p2: Vector2 = (th2["prev"] as Vector2).lerp(th2["pos"], alpha)
		var dest: Vector2 = th2["dest"]
		var start: Vector2 = tv["start"]
		var total: float = maxf(0.3, start.distance_to(dest))
		var frac: float = clampf(1.0 - p2.distance_to(dest) / total, 0.0, 1.0)
		var tgt: BUnit = th2["target"]
		var y_end: float = _chest(tgt).y if tgt != null and tgt.alive else 0.4
		var y: float = lerpf(float(tv["start_y"]), y_end, frac) + sin(frac * PI) * (0.55 if bool(tv["javelin"]) else 0.35)
		var pos := Vector3(p2.x, y, p2.y)
		var fdir := Vector3(dest.x - p2.x, (y_end - y) * 0.6 - cos(frac * PI) * 0.35, dest.y - p2.y)
		if fdir.length() < 0.01:
			fdir = Vector3(dest.x - start.x, 0.0, dest.y - start.y)
		fdir = fdir.normalized()
		var side: Vector3 = fdir.cross(Vector3.UP)
		if side.length() < 0.01:
			side = Vector3.RIGHT
		side = side.normalized()
		var basis: Basis
		if bool(tv["javelin"]):
			# 局部 +Y(矛尖) → 飞行方向
			basis = Basis(side, fdir, side.cross(fdir))
		else:
			tv["spin"] = float(tv["spin"]) + get_process_delta_time() * 20.0 * speed
			basis = Basis(side, fdir, side.cross(fdir)).rotated(side, float(tv["spin"]))
		node.global_transform = Transform3D(basis.scaled(Vector3.ONE * float(tv["scale"])), pos)


## 星旅节点：落地后脚下一直有一圈淡紫的嘲讽范围；锁血时罩上虚空外壳——都跟着单位走
func _update_astro() -> void:
	for uid: String in astro_rings.keys():
		var u: BUnit = astro_rings[uid]["unit"]
		var n: Node3D = astro_rings[uid]["node"]
		if not is_instance_valid(n):
			astro_rings.erase(uid)
			continue
		if not u.alive:
			n.queue_free()
			astro_rings.erase(uid)
			continue
		var v: UnitView = _view(u)
		var base: Vector3 = v.global_position if v != null else Vector3(u.pos.x, 0.0, u.pos.y)
		n.position = Vector3(base.x, 0.03, base.z)
		n.rotation.y += get_process_delta_time() * 0.4 * speed
	for uid2: String in astro_forms.keys():
		var u2: BUnit = astro_forms[uid2]["unit"]
		var f: EldritchForm = astro_forms[uid2]["node"] as EldritchForm
		if f == null or not is_instance_valid(f):
			astro_forms.erase(uid2)
			continue
		if not u2.alive:
			f.collapse()
			astro_forms.erase(uid2)
			continue
		# 眼睛盯着最近的敌人
		var near: BUnit = null
		for en: BUnit in battle.enemies_of(u2):
			if near == null or en.pos.distance_to(u2.pos) < near.pos.distance_to(u2.pos):
				near = en
		f.has_look = near != null
		if near != null:
			f.look_at_pos = _chest(near)


const WARDEN_FORM_SIZE := {"lion": 1.1, "spider": 1.08, "toad": 1.2, "base": 1.0}   # 守林节点各形态的表现体型
const ASTRO_TRUE_SIZE := 1.7          # 真实形态：星旅节点长到几倍(只是表现)


## 嘲讽范围的地面圈(半径 = 渡星而来的溅射范围)
func _add_astro_ring(u: BUnit) -> void:
	if astro_rings.has(u.uid):
		return
	var r: float = battle.pipeline.passive_splash_radius(u)
	var root := Node3D.new()
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.62, 0.42, 1.0, 0.5)
	var rm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.05
	tm.outer_radius = r
	tm.rings = 64
	tm.ring_segments = 4
	rm.mesh = tm
	rm.scale = Vector3(1.0, 0.1, 1.0)
	rm.material_override = mat
	rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rm)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.01, 0.24)
		var mm := MeshInstance3D.new()
		mm.mesh = bm
		mm.material_override = mat
		mm.position = Vector3(sin(a) * (r - 0.18), 0.0, cos(a) * (r - 0.18))
		mm.rotation.y = a
		mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mm)
	astro_rings[u.uid] = {"unit": u, "node": root}


# ---------------------------------------------------------------- 投射物外观
func _update_projectiles(alpha: float) -> void:
	var live: Dictionary = {}
	for p: Dictionary in battle.projectiles:
		var id: int = p["id"]
		live[id] = true
		var node: Node3D = proj_views.get(id, null)
		if node == null:
			var kit_color: Color = GC.faction_color((p["from"] as BUnit).def.faction_id)
			# 改修节点的弹匣：魔法弹 = 紫，真实弹 = 白金(物理照常)
			match Pipeline.magazine_kind(p["from"] as BUnit):
				"magic":
					kit_color = Color("#b06cff")
				"true":
					kit_color = Color("#fff2c8")
			var ptg: BUnit = p["target"] as BUnit
			if ptg != null and ptg.team == (p["from"] as BUnit).team and Pipeline.status_meta(p["from"] as BUnit, "na_ally_effect") != null:
				kit_color = Fx.GOLD                    # 金矢
			if MECH.has((p["from"] as BUnit).def.model):
				kit_color = Color(str(MECH[(p["from"] as BUnit).def.model]["col"]))     # 蓝之章的机械：弹 = 身份色(白色的弹在淡蓝白的地面上看不见)
			if str(p["kind"]).begins_with("ember"):
				# 余烬的火弹：颜色 = 施放者那一种火(身体模型的身份色)，落地时炸开
				var ident: Dictionary = UnitSkin.identity_of((p["from"] as BUnit).def.model)
				kit_color = Color(str(ident.get("rim", "#ff5a1a")))
			var pfrom: BUnit = p["from"] as BUnit
			if pfrom.def.model.begins_with("pianist") and str(p["kind"]) == "orb" and not bool(p["heal"]):
				node = fx.make_note_projectile(pfrom.def.form == "angel")      # 变奏节点：一枚大音符(恶魔 = 猩红、天使 = 白金)
			else:
				node = fx.make_projectile(str(p["kind"]), bool(p["heal"]), kit_color)
			if str(p["kind"]).begins_with("ember"):
				node.set_meta("impact", Fx.GREED_VIOLET if str(p["kind"]) == "ember_violet" else kit_color)
			add_child(node)
			proj_views[id] = node
		if p.has("hold"):
			_place_held(p, node, alpha)
			continue
		var pos2: Vector2 = (p["prev"] as Vector2).lerp(p["pos"], alpha)
		var tgt: BUnit = p["target"]
		var dest: Vector2 = tgt.pos if tgt != null else (p["dest"] as Vector2)     # 打地板：飞向落点
		var frac: float = clampf(1.0 - pos2.distance_to(dest) / float(p["total"]), 0.0, 1.0)
		var y: float = lerpf(0.95, 0.75, frac)
		if str(p["kind"]) == "arrow":
			y += sin(frac * PI) * 0.16
		elif str(p["kind"]) == "bolt":
			y += sin(frac * PI) * 0.06
		elif str(p["kind"]) == "syringe_dart":
			# 针剂飞镖：轻轻往上拱一点，绕自身的轴滚转
			y += sin(frac * PI) * 0.2
			var rl: Node3D = node.get_node_or_null("Roll")
			if rl != null:
				rl.rotation.z += 0.3
		elif str(p["kind"]) == "fan_ring":
			# 魔力飞环：往上拱、往一侧划一道弧(两只手的那两发往两边弯)，自己转
			y += sin(frac * PI) * 0.55
			var dir2: Vector2 = (dest - (p["start"] as Vector2)).normalized()
			var side: float = -1.0 if bool(p.get("is_copy", false)) else 1.0
			pos2 += Vector2(dir2.y, -dir2.x) * side * sin(frac * PI) * 0.9
			var spn: Node3D = node.get_node_or_null("Spin")
			if spn != null:
				spn.rotation.y += 0.45
		elif ProjRegistry.has(str(p["kind"])):
			# 通用武器分批文件的投射物(game/view/proj_kinds/)：偏移由它自己算
			var off: Vector3 = ProjRegistry.fly(node, str(p["kind"]), frac, battle.time, float(id))
			y += off.y
			var dro: Vector2 = (dest - (p["start"] as Vector2)).normalized()
			pos2 += Vector2(dro.y, -dro.x) * off.x + dro * off.z
		elif str(p["kind"]) == "chakram":
			# 回旋刃轮(通用手枪)：往一侧划一道浅弧(两只手的两发往两边弯)，平着高速自转
			y += sin(frac * PI) * 0.12
			var dirc: Vector2 = (dest - (p["start"] as Vector2)).normalized()
			var sidec: float = -1.0 if bool(p.get("is_copy", false)) else 1.0
			pos2 += Vector2(dirc.y, -dirc.x) * sidec * sin(frac * PI) * 0.45
			var spc: Node3D = node.get_node_or_null("Spin")
			if spc != null:
				spc.rotation.y = battle.time * 30.0
		elif str(p["kind"]) == "card":
			# 纸牌(通用手枪)：直线飞，边飞边绕自己的横轴翻跟头
			var flp: Node3D = node.get_node_or_null("Flip")
			if flp != null:
				flp.rotation.x = battle.time * 16.0 + float(id)
		elif str(p["kind"]) == "bubble":
			# 泡泡(通用手枪)：往上飘一点、一路上下晃，泡泡本身一胀一缩
			y += sin(frac * PI) * 0.25 + sin(battle.time * 7.0 + float(id) * 1.3) * 0.09
			var wb: Node3D = node.get_node_or_null("Wobble")
			if wb != null:
				var sq: float = sin(battle.time * 13.0 + float(id)) * 0.08
				wb.scale = Vector3(1.0 + sq, 1.0 - sq, 1.0 + sq * 0.5)
		elif str(p["kind"]) == "sound_ring":
			# 声波环(通用手枪)：边飞边变大、变淡
			var rg: Node3D = node.get_node_or_null("Ring")
			if rg != null:
				rg.scale = Vector3.ONE * (0.7 + 1.5 * frac)
				for rm: Variant in node.get_meta("mats", []):
					var smat: StandardMaterial3D = rm
					smat.albedo_color.a = float(smat.get_meta("a0", 1.0)) * (1.0 - 0.7 * frac)
		if tgt == null:
			y = lerpf(0.95, 0.15, frac * frac)
		elif bool((p.get("opts", {}) as Dictionary).get("missed", false)):
			# 打空：弹道往一侧偏开，从目标身边擦过
			var dmv: Vector2 = (dest - (p["start"] as Vector2)).normalized()
			pos2 += Vector2(dmv.y, -dmv.x) * 0.55 * frac
		var world := Vector3(pos2.x, y, pos2.y)
		var aim := Vector3(dest.x, 0.75 if tgt != null else 0.0, dest.y)
		if node.global_position.distance_to(world) > 0.001 or true:
			node.position = world
			var d: Vector3 = aim - world
			if d.length() > 0.05:
				node.look_at(world + d, Vector3.UP)
	for id2: int in proj_views.keys():
		if not live.has(id2):
			var pn: Node3D = proj_views[id2]
			if pn.has_meta("impact"):
				fx.ember_impact(pn.global_position, pn.get_meta("impact"), 1.0)
			pn.queue_free()
			proj_views.erase(id2)
	for id3: int in _held_seen.keys():
		if not live.has(id3):
			_held_seen.erase(id3)

## 完美时计的飞刀：往停顿点飞(从出手的高度升到停顿高度) → 停在半空(轻轻浮着，停得越久越红) → 放出去(从停顿高度扎向目标胸口)；刀尖一直朝着目标
func _place_held(p: Dictionary, node: Node3D, alpha: float) -> void:
	var hd: Dictionary = p["hold"]
	var id: int = p["id"]
	var pos2: Vector2 = (p["prev"] as Vector2).lerp(p["pos"], alpha)
	var tgt: BUnit = p["target"]
	var aim: Vector3 = _chest(tgt) if tgt != null and tgt.alive else Vector3((p["dest"] as Vector2).x, 0.75, (p["dest"] as Vector2).y)
	var h: float = float(hd["h"])
	var phase: String = str(hd["phase"])
	var y: float
	match phase:
		"out":
			var pt: Vector2 = hd["point"]
			var tot: float = maxf(0.05, (p["start"] as Vector2).distance_to(pt))
			var k: float = clampf(1.0 - pos2.distance_to(pt) / tot, 0.0, 1.0)
			y = lerpf(0.95, h, 1.0 - (1.0 - k) * (1.0 - k))
		"hover":
			y = h + sin(battle.time * 2.4 + float(id) * 1.7) * 0.025
		_:
			var k2: float = clampf(1.0 - pos2.distance_to(Vector2(aim.x, aim.z)) / maxf(0.3, float(p["total"])), 0.0, 1.0)
			y = lerpf(h, aim.y, k2)
	var world := Vector3(pos2.x, y, pos2.y)
	node.position = world
	var d: Vector3 = aim - world
	if d.length() > 0.05:
		node.look_at(world + d, Vector3.UP)
	if str(_held_seen.get(id, "")) != phase:
		var was: String = str(_held_seen.get(id, ""))
		_held_seen[id] = phase
		var trail: GPUParticles3D = node.get_node_or_null("Trail") as GPUParticles3D
		if trail != null:
			trail.emitting = phase != "hover"
		var rib: RibbonTrail = node.get_node_or_null("Ribbon") as RibbonTrail
		if rib != null:
			rib.active = phase != "hover"
		if phase == "hover":
			fx.knife_freeze(world)
		elif was == "hover":
			fx.knife_unfreeze(world)
	var heat: float = clampf((battle.held_scale(p) - 1.0) / 1.5, 0.0, 1.0) if phase != "out" else 0.0
	fx.knife_heat(node, heat, 0.5 + 0.5 * sin(battle.time * TAU), phase == "hover")



# ---------------------------------------------------------------- 事件翻译
func _view(u: BUnit) -> UnitView:
	return views.get(u.uid, null) as UnitView if u != null else null


const VANITY_MOUTH := Vector3(0.0, 87.0, 22.0)     # 虚荣的余烬的嘴(体素，挂 Head：上颌底下、嘴的中间；tools/chars/ember_vanity.gd)


## 演奏的连线：每帧按逻辑层的演奏状态(unit.meta.perf：对象 + 这一段是哪一种)摆；换了对象 / 换了一段就重建，演奏结束就收
func _update_perform_links() -> void:
	if battle == null:
		return
	var dt: float = get_process_delta_time() * speed
	var seen: Dictionary = {}
	for u: BUnit in battle.units:
		if not u.alive:
			continue
		var pf: Dictionary = u.meta.get("perf", {})
		if pf.is_empty():
			continue
		var tg: BUnit = pf.get("target") as BUnit
		if tg == null or not tg.alive:
			continue
		seen[u.uid] = true
		var rec: Dictionary = perf_links.get(u.uid, {})
		if rec.is_empty() or rec["target"] != tg or str(rec["opt"]) != str(pf["opt"]):
			if not rec.is_empty():
				fx.perform_link_end(rec["node"], _chest(rec["target"]) if (rec["target"] as BUnit).alive else _chest(u), false)
			rec = {"node": fx.perform_link(Fx.PERFORM_COLORS.get(str(pf["opt"]), Color.WHITE)), "target": tg, "opt": str(pf["opt"])}
			perf_links[u.uid] = rec
		var tv: UnitView = _view(tg)
		var th: float = tv.body_height if tv != null else 1.3
		var tpos: Vector3 = tv.global_position if tv != null else Vector3(tg.pos.x, 0, tg.pos.y)
		var from: Vector3 = _chest(u) + Vector3(0, 0.05, 0)
		if tg == u:
			# 给自己演奏：光带从胸前绕一圈回到自己头顶(拉一点距离，别缩成一个点)
			from = _chest(u) + Vector3(0.5, -0.2, 0.4)
		fx.perform_link_set(rec["node"], from, _chest(tg), tpos, tg.radius * 1.5, tpos + Vector3(0, th + 0.55, 0), dt)
	for uid: String in perf_links.keys():
		if not seen.has(uid):
			var rec2: Dictionary = perf_links[uid]
			var tg2: BUnit = rec2["target"]
			fx.perform_link_end(rec2["node"], _chest(tg2), tg2.alive)
			perf_links.erase(uid)


## 吟唱的表现(单位数据 chant_fx)；by_weapon 里按手里的武器覆盖(心音节点：拿着无声琴才抱琴弹奏，否则拿着手里的武器唱歌)；
## "*" = 没有专门写的能力都用它(血嗜节点：任何吟唱的武器效果都浮空凝聚血球)
func _chant_fx(u: BUnit, ability: String) -> Dictionary:
	var cfx: Dictionary = u.def.chant_fx.get(ability, u.def.chant_fx.get("*", {}))
	var bw: Dictionary = cfx.get("by_weapon", {})
	if u.weapon != null and bw.has(u.weapon.id):
		cfx = cfx.duplicate()
		cfx.merge(bw[u.weapon.id], true)
	return cfx


## 怪物身体模型的身份色(余烬：那一种火的颜色)
func _ident_color(u: BUnit, fallback: Color) -> Color:
	var ident: Dictionary = UnitSkin.identity_of(u.def.model)
	return Color(str(ident["rim"])) if ident.has("rim") else fallback


func _chest(u: BUnit) -> Vector3:
	var v: UnitView = _view(u)
	var base: Vector3 = v.global_position if v != null else Vector3(u.pos.x, 0.0, u.pos.y)
	return base + Vector3(0, (v.body_height if v != null else 1.3) * 0.75, 0)


## 刚飞出去的符带来的事件(同一个施放者对同一个目标的治疗 / 伤害 / 净化 / 状态)：扣住，等符落地
func _held_by_talisman(e: Dictionary) -> bool:
	var src: BUnit = _hold["src"]
	var dst: BUnit = _hold["target"]
	match str(e["t"]):
		"damage", "heal", "shield":
			return e.get("src") == src and e.get("dst") == dst
		"dispel":
			return e.get("unit") == dst and e.get("src") == src
		"status":
			return e.get("unit") == dst and (not e.has("src") or e.get("src") == src)
	return false


func _dispatch(events: Array[Dictionary]) -> void:
	_hold = {}
	for e: Dictionary in events:
		if not _hold.is_empty() and _held_by_talisman(e):
			(_hold["held"] as Array[Dictionary]).append(e)
			continue
		match e["t"]:
			"attack_start":
				var v: UnitView = _view(e["unit"])
				if v != null:
					v.play_attack(float(e["speed_scale"]) * speed, str(e.get("anim", "")))
				# 守林节点的背后灵跟着她一起打(前摇里蓄力，出手那一刻扑 / 咬 / 吐舌头)
				var asu: BUnit = e["unit"]
				if asu.def.model.begins_with("pianist"):
					fx.piano_notes(_chest(asu) + Vector3(sin(asu.facing), 0.0, cos(asu.facing)) * 0.35 + Vector3(0, 0.15, 0), asu.def.form == "angel")
				if beast_spirits.has(asu.uid) and is_instance_valid(beast_spirits[asu.uid]):
					var atg: BUnit = e.get("target") as BUnit
					if atg != null:
						(beast_spirits[asu.uid] as BeastSpirit).attack(_chest(atg), float(e.get("windup", 0.25)) / maxf(0.1, speed))
			"draw_start":
				var du: BUnit = e["unit"]
				var dv: UnitView = _view(du)
				if dv != null:
					var dwc: Dictionary = du.wclass()
					dv.start_draw(str(e.get("anim", "")), str(dwc.get("draw_hold_anim", "")), float(e["duration"]) / maxf(0.01, speed))
					_drop_charge(du, false)
					if du.weapon_class() == "bow":
						charges[du.uid] = fx.charge(dv.model, ARROW_TIP, GC.faction_color(du.def.faction_id).lightened(0.45), float(e["duration"]))
				if du.aim_passive() != null:
					_end_snipe_aim(du.uid)
					snipe_aims[du.uid] = {"node": fx.sniper_aim(), "t0": battle.time}
			"reload_start":
				var lu: BUnit = e["unit"]
				var lv: UnitView = _view(lu)
				if lv != null:
					lv.play_reload(str(e.get("anim", "")), float(e["duration"]) / maxf(0.01, speed))
					# 狙击窝里的拉栓换弹：拉栓那一下(换弹的 0.40 / 2.6 处)弹壳从抛壳口跳出去
					if lv.nest_on and lu.weapon_class() == "rifle":
						var real: float = float(e["duration"]) / maxf(0.01, speed)
						get_tree().create_timer(real * 0.4 / 2.6).timeout.connect(func() -> void:
							if is_instance_valid(lv) and not lv.dying:
								var rq: Basis = lv.global_transform.basis
								fx.shell_casing(lv.bone_point("Bow", SNIPER_PORT), -rq.x))
				fx.number(_chest(lu) + Vector3(0, 0.6, 0), Loc.t("fx.reload"), Color("#c8d3e8"), 0.7)
			"attack_release":
				_on_release(e)
			"attack_copy":
				_on_copy(e)
			"projectile_end":
				var p: Dictionary = e["proj"]
				if p.has("hold") and not bool(e.get("hit", false)):
					# 完美时计：发射者倒下 → 停着的飞刀掉在地上；目标没了 → 碎成光点
					var hn: Node3D = proj_views.get(int(p["id"]), null)
					proj_views.erase(int(p["id"]))
					if bool(e.get("dropped", false)):
						fx.knife_drop(hn)
					else:
						fx.knife_vanish(hn)
					continue
				if bool(e.get("hit", false)) and str(p["kind"]) == "knife" and p["target"] != null:
					# 飞刀扎中：一道银色的交叉斩光(顺着飞来的方向) + 红色的血花 + 银屑
					var kt: Vector3 = _chest(p["target"])
					var kfrom: Vector2 = p.get("start", (p["target"] as BUnit).pos)
					var kdir := Vector3((p["target"] as BUnit).pos.x - kfrom.x, 0.0, (p["target"] as BUnit).pos.y - kfrom.y)
					fx.knife_slash(kt, kdir.normalized() if kdir.length() > 0.01 else Vector3(0, 0, 1))
					fx.burst(kt, Color("#ff4a5c"), 6, 2.2, 0.7, 0.5, 0.3)
					fx.burst(kt, Color("#f2f4fa"), 4, 2.8, 0.5, 0.4, 0.2)
					continue
				if bool(e.get("hit", false)) and str(p["kind"]) == "syringe_dart":
					# 针剂扎中：玻璃碎屑 + 药液四溅(治疗 = 粉、伤害 = 血红)
					var tg2: BUnit = p["target"]
					var hp2: Vector3 = _chest(tg2) if tg2 != null else Vector3((p["dest"] as Vector2).x, 0.2, (p["dest"] as Vector2).y)
					fx.burst(hp2, Color("#ff86c2") if bool(p["heal"]) else Color("#ff2a4c"), 9, 2.2, 0.8, 0.7, 0.4)
					fx.burst(hp2, Color("#fff4fa"), 4, 1.6, 0.6, 0.9, 0.3)
				elif bool(e.get("hit", false)) and ProjRegistry.has(str(p["kind"])):
					var tg6: BUnit = p["target"]
					var hp6: Vector3 = _chest(tg6) if tg6 != null else Vector3((p["dest"] as Vector2).x, 0.2, (p["dest"] as Vector2).y)
					var st6: Vector2 = p.get("start", Vector2(hp6.x, hp6.z))
					var fd6 := Vector3(hp6.x - st6.x, 0.0, hp6.z - st6.y)
					ProjRegistry.hit(fx, str(p["kind"]), hp6, fd6.normalized() if fd6.length() > 0.01 else Vector3(0, 0, 1))
				elif bool(e.get("hit", false)) and Fx.PISTOL_PROJ.has(str(p["kind"])):
					# 不射子弹的手枪：刃轮 = 一小簇火星、纸牌 = 碎成光屑、泡泡 = 破成水珠、声波环 = 一圈涟漪
					var tg5: BUnit = p["target"]
					var hp5: Vector3 = _chest(tg5) if tg5 != null else Vector3((p["dest"] as Vector2).x, 0.2, (p["dest"] as Vector2).y)
					var st5: Vector2 = p.get("start", Vector2(hp5.x, hp5.z))
					var fd5 := Vector3(hp5.x - st5.x, 0.0, hp5.z - st5.y)
					fx.pistol_hit(str(p["kind"]), hp5, fd5.normalized() if fd5.length() > 0.01 else Vector3(0, 0, 1))
				elif bool(e.get("hit", false)):
					var tgt: BUnit = p["target"]
					if tgt != null:
						fx.burst(_chest(tgt), Color("#ffe6b0"), 5, 1.6, 0.8)
					else:
						var gp: Vector2 = p["dest"]
						fx.burst(Vector3(gp.x, 0.2, gp.y), Color("#ffe6b0"), 8, 2.0, 0.9)
				elif bool(e.get("blocked", false)):
					# 弹道撞上高墙/卡车：石屑
					var bp: Vector2 = p["pos"]
					fx.burst(Vector3(bp.x, 0.9, bp.y), Color("#e9e4dc"), 8, 1.8, 0.8)
			"orb_drop":
				orb_dropped.emit(str(e["tier"]), e["pos"])
			"raid_start":
				banner.emit("ui.raid")
			"enter_truck":
				var eu: BUnit = e["unit"]
				var ev: UnitView = _view(eu)
				if ev != null:
					ev.set_dissolve(0.0)
					var tw: Tween = create_tween()
					tw.tween_method(ev.set_dissolve, 0.0, 1.0, 0.45)
					tw.tween_callback(func() -> void: ev.dead_done = true)
					ev.dying = true
				var tc: Vector2 = battle.map.truck_center()
				fx.burst(Vector3(tc.x, 1.3, tc.y), Color("#a8f6ff"), 16, 2.6, 1.0)
				fx.number(Vector3(tc.x, 2.8, tc.y), "-%d" % int(e["damage"]), Color("#ff6a6a"), 1.3)
				truck_hit.emit(int(e["damage"]))
			"damage":
				_on_damage(e)
				# 蓝之章的机械：SG 火控终端 = 琥珀色的锁定框收紧；AX 输出协议 = 赤红的交叉斩
				match str(e.get("ability", "")):
					"mob_sg_fire":
						fx.firecontrol_hit(_chest(e["dst"] as BUnit))
					"mob_ax_protocol":
						var axs: BUnit = e.get("src") as BUnit
						var axd: BUnit = e["dst"]
						fx.protocol_strike(_chest(axd), Vector3(axd.pos.x - axs.pos.x, 0.0, axd.pos.y - axs.pos.y) if axs != null else Vector3(0, 0, 1))
				# 守林节点变身形态的普攻：爪痕 / 毒液 / 长舌(只看画面上的形态：UnitView.beast_form)
				if str(e.get("surface", "")) == "normal_attack" and e.get("src") != null:
					var bsv: UnitView = _view(e["src"] as BUnit)
					if bsv != null and bsv.beast_form != "":
						var bsu: BUnit = e["src"]
						fx.beast_hit(bsv.beast_form, bsv.global_position + Vector3(0, bsv.body_height * 0.5, 0) + Vector3(sin(bsu.facing), 0, cos(bsu.facing)) * 0.2,
							_chest(e["dst"] as BUnit))
				# 失血的每一跳：一缕血雾飘回血嗜节点(同一个目标隔一会儿才飘一次)
				if str(e.get("ability", "")) == "bleed" and e.get("src") != null and (e["src"] as BUnit).alive:
					var bd: BUnit = e["dst"]
					var dv0: UnitView = _view(e["src"] as BUnit)
					if dv0 != null and _gate("drain:" + bd.uid, 0.7):
						fx.blood_drain(_chest(bd), dv0, Vector3(0.0, dv0.body_height * 0.75, 0.0))
			"heal":
				_on_heal(e)
				# 圣疗(圣战节点)：蓝金色的光柱
				if str(e.get("ability", "")) == "node_paladin_heal" and e.get("dst") is BUnit:
					var hsrc: BUnit = e.get("src") as BUnit
					fx.holy_mend(_chest(e["dst"] as BUnit), _chest(hsrc) if hsrc != null and hsrc != e["dst"] else Vector3.INF)
			"field_start":
				var f: Dictionary = e["field"]
				if str(f["kind"]) == "paddy":
					var fp: Vector2 = f["pos"]
					field_views[int(f["id"])] = fx.paddy(Vector3(fp.x, 0.0, fp.y), float(f["radius"]))
				elif str(f["kind"]) == "amp":
					var fp2: Vector2 = f["pos"]
					# HV 场域载具：车顶的发射环往落点射一道青色的光，力场随后展开
					var fsrc: BUnit = f.get("src") as BUnit
					var fsv: UnitView = _view(fsrc) if fsrc != null else null
					if fsv != null and MECH.has(fsrc.def.model) and (MECH[fsrc.def.model] as Dictionary).has("emitter"):
						fx.field_projection(fsv.bone_point("Chest", MECH[fsrc.def.model]["emitter"]), Vector3(fp2.x, 0.15, fp2.y))
					field_views[int(f["id"])] = fx.amp_field(Vector3(fp2.x, 0.0, fp2.y), float(f["radius"]))
			"field_end":
				var f2: Dictionary = e["field"]
				var fv: Node3D = field_views.get(int(f2["id"]), null)
				field_views.erase(int(f2["id"]))
				if fv != null and is_instance_valid(fv):
					fx.remove_field(fv)
			"ember_out":
				ember_out.emit(int(e["id"]))
			"ember_lit":
				ember_lit.emit(int(e["id"]))
			"ember_add":
				ember_add.emit(int(e["id"]), e)
			"perform_start":
				# 演奏：一串音符从琴上飘向演奏对象 + 这段演奏的名字
				var pfu: BUnit = e["unit"]
				var pft: BUnit = e.get("target") as BUnit
				var pcol: Color = Fx.PERFORM_COLORS.get(str(e.get("opt", "")), Color.WHITE)
				if pft != null:
					fx.music_notes(_chest(pfu) + Vector3(0, -0.1, 0), _chest(pft), pcol)
					fx.number(_chest(pft) + Vector3(0, 0.75, 0), Loc.t("ui.fx.perform." + str(e.get("opt", ""))), pcol, 0.7)
			"freeze":
				var fzu: BUnit = e["unit"]
				var fzv: UnitView = _view(fzu)
				if fzv != null and not ice_blocks.has(fzu.uid):
					ice_blocks[fzu.uid] = fx.ice_block(fzv, fzu.radius / maxf(0.1, fzu.def.scale), fzv.body_height / maxf(0.1, fzu.def.scale))
				fx.number(_chest(fzu) + Vector3(0, 0.8, 0), Loc.t("ui.fx.freeze"), Fx.ICE, 0.9)
			"light_beam_start":
				# 她是唯一的光：光柱从天而降(落在敌方最强的单位脚下)，她手里的光之心往天上射一道细光
				var lu: BUnit = e["unit"]
				_end_light_beam(lu.uid)
				var lp: Vector2 = e["pos"]
				light_beams[lu.uid] = {"node": fx.light_beam(), "ray": fx.light_ray(), "pulse": 0.0}
				# 她身上的光：脚下的圣印、身后的光轮、绕着她转的经文(SaintAura)
				var luv: UnitView = _view(lu)
				if luv != null:
					light_beams[lu.uid]["aura"] = SaintAura.create(fx, luv, luv.body_height)
				shake.emit(0.04)
				fx.light_beam_set(light_beams[lu.uid]["node"], Vector3(lp.x, 0.0, lp.y), float(e.get("radius", 2.4)), 0.0)
				fx.light_descend(Vector3(lp.x, 0.0, lp.y), float(e.get("radius", 2.4)))
			"light_beam_tick":
				var tu: BUnit = e["unit"]
				if light_beams.has(tu.uid):
					light_beams[tu.uid]["pulse"] = 1.0
					# 一圈光环从天上的圣印顺着光柱滑到地上；她身上的圣印 / 光轮 / 经文一起亮一下
					fx.light_beam_tick(light_beams[tu.uid]["node"], float((tu.meta.get("light_beam", {}) as Dictionary).get("rad", 2.4)))
					if is_instance_valid(light_beams[tu.uid].get("aura")):
						(light_beams[tu.uid]["aura"] as SaintAura).pulse()
				var ltg: BUnit = e.get("target") as BUnit
				if ltg != null and ltg.alive:
					fx.light_beam_hit(_chest(ltg))
			"light_beam_end":
				_end_light_beam((e["unit"] as BUnit).uid)
			"light_boost":
				var bpos: Vector2 = e["pos"]
				var bu2: BUnit = e["unit"]
				var brad: float = float((bu2.meta.get("light_beam", {}) as Dictionary).get("rad", 2.4))
				fx.light_boost(Vector3(bpos.x, 0.0, bpos.y), brad)
				if _gate("lboost:" + bu2.uid, 0.8):
					fx.number(Vector3(bpos.x, 1.6, bpos.y), Loc.t("ui.fx.light_boost"), Color("#ffe58a"), 0.85)
			"absolve":
				# 光之心的斩杀：金色光十字 + "斩杀"
				var at: BUnit = e["target"]
				fx.absolve_cross(_chest(at))
				fx.number(_chest(at) + Vector3(0, 0.8, 0), Loc.t("ui.fx.absolve"), Color("#fff1a8"), 1.15, 0.9, 1.0)
			"kin_tale":
				var ku: BUnit = e["unit"]
				var kv: UnitView = _view(ku)
				if kv != null:
					if blood_orbs.has(ku.uid) and is_instance_valid(blood_orbs[ku.uid]["node"]):
						(blood_orbs[ku.uid]["node"] as Node3D).queue_free()
					var chanting: bool = bool(e.get("chant", false))
					var orb: Node3D = fx.blood_orb(kv, 0.42 if chanting else 0.16)
					orb.position = Vector3(0.0, kv.body_height * 1.12 + 0.42, 0.06) if chanting else Vector3(0.25, kv.body_height * 0.95, 0.35)
					blood_orbs[ku.uid] = {"node": orb, "multi": bool(e.get("multi", false)), "center": e.get("center", ku.pos), "target": e.get("target"),
						"targets": e.get("targets", []), "chant": chanting, "t0": battle.time, "dur": 3.0, "next": battle.time, "radius": float(e.get("radius", 5.0))}
					fx.number(_chest(ku) + Vector3(0, 0.95, 0), Loc.t("ui.fx.kin_tale"), Fx.BLOOD_HOT, 0.8)
					if not chanting:
						kv.play_once("cast_vampire")
			"throw_cast":
				# 至亲的故事：武器效果等血球落地才结算——记下落地时刻，_update_blood_orbs 倒推出手的时机
				var tcu: BUnit = e["unit"]
				blood_land[tcu.uid] = battle.time + float(e.get("land", 0.4))
			"throw_land":
				# 血球砸到地上：每个真正被打中的人脚下冲起一根血柱
				var tlu: BUnit = e["unit"]
				var tlv: UnitView = _view(tlu)
				var big_t: bool = bool(e.get("big", true))
				for tlt: Variant in e.get("targets", []):
					var tb0: BUnit = tlt as BUnit
					if tb0 != null:
						var hv0: UnitView = _view(tb0)
						var bh0: float = hv0.body_height if hv0 != null else 1.3
						fx.blood_pillar(Vector3(tb0.pos.x, 0.0, tb0.pos.y), maxf(1.6, bh0 * 1.5) if big_t else maxf(1.1, bh0 * 1.0), big_t)
				if tlv != null and not (e.get("targets", []) as Array).is_empty():
					shake.emit(0.06)
			"blood_feast":
				var bfu: BUnit = e["unit"]
				if _gate("feast:" + bfu.uid, 1.2):
					fx.blood_feast(Vector3(bfu.pos.x, 0.0, bfu.pos.y))
			"infusion_pop":
				var ipu: BUnit = e["unit"]
				var ipa: BUnit = e.get("attacker") as BUnit
				fx.infusion_pop(_chest(ipu), _chest(ipa) if ipa != null else _chest(ipu))
			"perform_echo":
				var ecu: BUnit = e["unit"]
				for etu: Variant in e.get("targets", []):
					if etu is BUnit and (etu as BUnit).alive:
						fx.music_notes(_chest(ecu), _chest(etu as BUnit), Fx.GOLD)
				fx.number(_chest(ecu) + Vector3(0, 0.9, 0), Loc.t("ui.fx.echo"), Fx.GOLD, 0.95)
			"ember_flare":
				# 龙的余烬在场：余烬不熄，踩上去照样烧——地块蹿起一小团火
				var fid: int = int(e["id"])
				if fid >= 0 and fid < battle.map.embers.size() and _gate("eflare:%d" % fid, 0.5):
					var fr: Rect2 = battle.map.rect_world(battle.map.embers[fid]["rect"])
					fx.ember_flare(Vector3(fr.get_center().x, 0.0, fr.get_center().y))
			"dragon_ignite":
				var ip: Vector2 = e["pos"]
				fx.ember_ignite(Vector3(ip.x, 0.0, ip.y))
			"wither":
				# 燃烧移除生命上限(龙的余烬在场)：暗红的灰烬 + "-25 上限"(同一个人隔一会儿才飘一次)
				var wu: BUnit = e["unit"]
				var wk: String = "wither:" + wu.uid
				_wither_acc[wk] = float(_wither_acc.get(wk, 0.0)) + float(e["amount"])
				if _gate(wk, 0.8):
					fx.number(_chest(wu) + Vector3(-0.25, 0.15, 0), Loc.t("ui.fx.wither") % int(round(float(_wither_acc[wk]))), Color("#ff6a7a"), 0.65)
					fx.wither_ash(_chest(wu))
					_wither_acc[wk] = 0.0
			"hazard":
				hazard.emit(e)
			"hazard_hit":
				# 被电车撞到 / 被喷泉的火弧砸中：身上炸开一团火星
				var hu: BUnit = e["unit"]
				var tram_hit: bool = str(e.get("id", "")) == "tram"
				fx.burst(Vector3(hu.pos.x, 0.7, hu.pos.y), Color(1.0, 0.62, 0.2), 22 if tram_hit else 14, 4.2 if tram_hit else 3.0, 0.9, 1.4, 0.5)
				if tram_hit:
					fx.burst(Vector3(hu.pos.x, 0.5, hu.pos.y), Color(0.28, 0.25, 0.23), 12, 2.4, 1.3, 1.6, 0.8, false)
			"cone_sweep":
				# 花蕊(正行节点)：延长过的光剑 / 光矛 / 光炮扫过身前的大锥形；被扫到的人身上亮一下
				var lu0: BUnit = e["unit"]
				var ld0: Vector2 = e["dir"]
				var lhits: Array = []
				for lt0: Variant in e.get("targets", []):
					var ltu0: BUnit = lt0 as BUnit
					if ltu0 != null:
						lhits.append(_chest(ltu0))
				fx.lily_sweep(Vector3(lu0.pos.x, 0.0, lu0.pos.y), Vector3(ld0.x, 0.0, ld0.y), float(e.get("angle", 120.0)), float(e.get("length", 4.5)),
					str(e.get("weapon_class", "sword")), lhits)
				shake.emit(0.05)
			"dice_roll":
				# 无数世界：头上飘"d1+d2(+增幅+阵亡) = 结果"，两颗骰子飞向敌人中间；双 1 = "大失败！"
				var dru: BUnit = e["unit"]
				var drv: UnitView = _view(dru)
				if drv != null:
					drv.play_once("roll_%s_%s" % [dru.def.model, dru.weapon_class()])
				var extra: int = int(e.get("amp", 0)) + int(e.get("dead", 0))
				var dtxt: String = Loc.t("ui.fx.dice") % [int(e.get("d1", 0)), int(e.get("d2", 0)), ("+%d" % extra) if extra > 0 else "", int(e.get("total", 0))]
				var chaos_r: bool = bool(e.get("chaos", false))
				fx.number(_chest(dru) + Vector3(0, 1.0, 0), Loc.t("ui.fx.dice_chaos") if chaos_r else dtxt,
					Color("#ff4a6a") if chaos_r else Fx.DICE_PURPLE, 1.1 if chaos_r else 0.95, 1.0, 1.5)
				var cen := Vector3.ZERO
				var nfo := 0
				for fo: BUnit in battle.enemies_of(dru):
					cen += Vector3(fo.pos.x, 0.0, fo.pos.y)
					nfo += 1
				if nfo > 0:
					fx.dice_toss(_chest(dru), cen / float(nfo), chaos_r)
				if chaos_r:
					shake.emit(0.1)
			"shuffle":
				for mv: Variant in e.get("moves", []):
					var md: Dictionary = mv
					var mf: Vector2 = md["from"]
					var mt: Vector2 = md["to"]
					fx.swap_flash(Vector3(mf.x, 0.0, mf.y), Vector3(mt.x, 0.0, mt.y))
			"d20":
				var dtt: BUnit = e["target"]
				if dtt != null and _gate("d20:" + dtt.uid, 0.3):
					var kcol: Color = Fx.COLORS.get(str(e.get("kind", "magic")), Color.WHITE)
					fx.number(_chest(dtt) + Vector3(-0.3, 0.6, 0), "d20 %d" % int(e.get("roll", 0)), kcol, 0.7)
			"petrify_wake":
				var pwu: BUnit = e["unit"]
				fx.stone_break(_chest(pwu))
				fx.number(_chest(pwu) + Vector3(0, 1.1, 0), Loc.t("ui.fx.awake") % int(round(float(e.get("gain", 0.0)))), Fx.DICE_PURPLE, 1.1, 1.0, 1.5)
				shake.emit(0.08)
			"summon_aura":
				# 牵丝提灯 / 殉魂幡：从携带者身上拉一道细光到每个召唤物身上，召唤物身上一圈光
				var sau: BUnit = e["unit"]
				var scol: Color = Color("#9fd8ff") if str(e.get("style", "")) == "strings" else Color("#bff0e8")
				for st0: Variant in e.get("targets", []):
					var stu: BUnit = st0 as BUnit
					if stu != null and sau != null:
						fx.thunder_bolt_colored(_chest(sau), _chest(stu), scol)
						fx.ring(Vector3(stu.pos.x, 0.05, stu.pos.y), 0.7, scol, 0.4, 1.2, 0.3)
			"charge_refill":
				var cru: BUnit = e["unit"]
				fx.burst(_chest(cru), Color("#6fe8ff"), 8, 1.6, 0.7, 0.8, 0.4)
				fx.number(_chest(cru) + Vector3(0, 0.9, 0), Loc.t("ui.fx.charge_refill"), Color("#6fe8ff"), 0.85, 0.9, 1.0)
			"charge_burst":
				var cbt: BUnit = e.get("target") as BUnit
				if cbt != null:
					fx.soft_flash(_chest(cbt), Color("#b47cff"), 1.0 + 0.08 * float(int(e.get("charges", 0))), 0.3, 2.2)
			"pianist_flip":
				# 表里之间：阵亡时回满并换形态——身体 / 钢琴换成另一个形态的样子
				var pfu: BUnit = e["unit"]
				var pfv: UnitView = _view(pfu)
				var angel: bool = str(e.get("form", "")) == "angel"
				if pfv != null:
					pfv.set_def(pfu.def)
				fx.pianist_flip(_chest(pfu), angel)
				fx.number(_chest(pfu) + Vector3(0, 1.1, 0), Loc.t("ui.fx.flip_" + ("angel" if angel else "demon")),
					Fx.PIANO_WHITE if angel else Fx.PIANO_RED, 1.1, 1.0, 1.5)
				shake.emit(0.06)
			"black_keys":
				# 黑键 / 白键：琴键飞向目标，"渐强 +N"
				var bku: BUnit = e["unit"]
				var bkt: BUnit = e["target"]
				if bku != null and bkt != null:
					fx.black_keys(_chest(bku), _chest(bkt), bool(e.get("white", false)))
					if int(e.get("stacks", 0)) > 0:
						fx.number(_chest(bkt) + Vector3(0, 1.0, 0), Loc.t("ui.fx.crescendo") % int(e.get("stacks", 0)), Fx.PIANO_GOLD, 1.0, 1.0, 1.4)
			"lock_cast":
				# 万物闭锁(锁芯节点)：头上"万物闭锁"，选中的圆上张开绿金法阵，impact 秒后锁上
				var lcu: BUnit = e["unit"]
				var lcp: Vector2 = e["pos"]
				fx.number(_chest(lcu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.lock"), Fx.CULT_GOLD, 0.95, 1.0, 1.2)
				fx.lock_sigil(Vector3(lcp.x, 0.0, lcp.y), float(e.get("radius", 1.8)), float(e.get("impact", 0.35)))
			"lock_close":
				var lkp: Vector2 = e["pos"]
				var lkh: Array = []
				for lk0: Variant in e.get("targets", []):
					var lku: BUnit = lk0 as BUnit
					if lku != null:
						lkh.append(_chest(lku))
				fx.lock_close(Vector3(lkp.x, 0.0, lkp.y), float(e.get("radius", 1.8)), lkh)
				shake.emit(0.05)
			"key_gate":
				# 打开深空之门(开与闭)：地上一扇暗紫的星空门，金链从门里射向每个目标、把它们拽过来
				var kgu: BUnit = e["unit"]
				var kgp: Vector2 = e["pos"]
				var kgh: Array = []
				for kg0: Variant in e.get("targets", []):
					var kgt: BUnit = kg0 as BUnit
					if kgt != null:
						kgh.append(_chest(kgt))
				fx.number(_chest(kgu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.gate"), Color("#b08cff"), 1.0, 1.0, 1.4)
				fx.deep_gate(Vector3(kgp.x, 0.0, kgp.y), kgh)
				shake.emit(0.07)
			"phantom_strike":
				# 逆时幻影跟着她出手：幻影挥一下，目标身上一道紫色刀痕
				var phu: BUnit = e["unit"]
				var phv: UnitView = _view(phu)
				var pht: BUnit = e["target"]
				if phv != null:
					phv.rotation.y = phu.facing
					phv.play_attack(1.6 * speed)
				if pht != null:
					var pdir: Vector3 = Vector3(pht.pos.x - phu.pos.x, 0.0, pht.pos.y - phu.pos.y).normalized()
					fx.phantom_echo(_chest(pht) - pdir * 0.2, pdir)
			"sever":
				# 杀：斩断——召唤物直接被抹去；否则削掉生命上限(暗红 + 黑的刀痕)
				var svt: BUnit = e["target"]
				if svt != null:
					fx.sever_mark(_chest(svt), bool(e.get("summon", false)))
			"selfless_draw":
				# 无我：她拔刀(动作 draw_<模型>，拔到一半换成出鞘的刀)，普通敌人一齐被斩开、消散；精英 / 首领身上一道裂痕
				var sdu: BUnit = e["unit"]
				var sdv: UnitView = _view(sdu)
				if sdv != null:
					sdv.play_once("draw_" + sdu.def.model)
					var swap_t: float = 0.48                    # draw_killer：0.28~0.50 秒刀停在居合架势里，这里把刀鞘换成出鞘的刀
					var tw_sd: Tween = create_tween()
					tw_sd.tween_interval(swap_t / maxf(0.05, speed))
					tw_sd.tween_callback(func() -> void:
						if is_instance_valid(sdv) and str(sdv.look.get("model", "")).ends_with("odachi"):
							sdv.set_weapon_model(str(sdv.look["model"]) + "_drawn")
							fx.soft_flash(sdv.bone_origin("Bow"), Fx.PHANTOM_VIOLET, 1.4, 0.3, 2.4)
							fx.burst(sdv.bone_origin("Bow"), Fx.PHANTOM_VIOLET, 14, 2.2, 0.7, 1.2, 0.5))
				fx.number(_chest(sdu) + Vector3(0, 1.1, 0), Loc.t("ui.fx.selfless"), Fx.PHANTOM_VIOLET, 1.2, 1.0, 1.6)
				# 拔刀的一瞬(SELFLESS_DRAW)：一道巨大的新月刀光横扫全场，画面一下子变成黑白(只有她留着颜色)；
				# 被斩开的人定格、身上一道迟来的白线，SELFLESS_HOLD 秒后黑白反相闪几下，那些人一齐崩散；精英 / 首领身上一道暗红的重刀痕
				var sp: float = maxf(0.05, speed)
				var gone: Array = (e.get("removed", []) as Array).duplicate()
				var hurt: Array = (e.get("cut", []) as Array).duplicate()
				var sd_at := Vector3(sdu.pos.x, 0.0, sdu.pos.y)
				var aim := Vector2.ZERO
				for gu: Variant in gone + hurt:
					if gu is BUnit:
						aim += (gu as BUnit).pos - sdu.pos
				var sd_dir := Vector3(aim.x, 0.0, aim.y) if aim.length() > 0.1 else Vector3(sin(sdu.facing), 0.0, cos(sdu.facing))
				var sd_h: float = sdv.body_height if sdv != null else 1.3
				var pts: Array = []
				for gu2: Variant in gone:
					if gu2 is BUnit:
						pts.append(_chest(gu2 as BUnit))
				get_tree().create_timer(SELFLESS_DRAW / sp).timeout.connect(func() -> void:
					fx.iai_sweep(sd_at, sd_dir, 14.0)
					var dm: DomainFX = DomainFX.make("ink", sd_at, 40.0)
					add_child(dm)
					dm.open(0.1, 0.0)
					dm.set_keep(sd_at, 0.7, sd_h + 0.7)
					for cp: Variant in pts:
						fx.iai_cut_line(cp, SELFLESS_HOLD)
					for cu: Variant in hurt:
						if cu is BUnit and is_instance_valid(cu):
							fx.selfless_scar(_chest(cu as BUnit), float(e.get("pct", 0.2)))
					shake.emit(0.1)
					var dref: WeakRef = weakref(dm)
					get_tree().create_timer(SELFLESS_HOLD / sp).timeout.connect(func() -> void:
						var dm1: DomainFX = dref.get_ref() as DomainFX
						if dm1 != null:
							dm1.close(0.55, true)
						shake.emit(0.14)))
			"prayer_heal":
				var prt: BUnit = e.get("target") as BUnit
				if prt != null and prt.alive:
					fx.prayer_glow(_chest(prt))
			"blessing_revive":
				# 奇迹 → 祝福之心：倒下的人身上升起一枚金十字
				var brt: BUnit = e["target"]
				fx.miracle_cross(_chest(brt))
				fx.number(_chest(brt) + Vector3(0, 1.2, 0), Loc.t("ui.fx.miracle"), Fx.SISTER_GOLD, 1.0)
			"pickpocket":
				# 妙手：一枚金币从他手边弹起来(+N 由 gold 事件飘)
				var ppu: BUnit = e["unit"]
				fx.coin_pop(_chest(ppu) + Vector3(0.15, 0.1, 0.0), int(e.get("amount", 1)))
			"money_bag":
				# 钱袋：进账飘"钱袋 N"(同一个人隔一会儿才飘一次)；翻倍一团金光 + 几枚金币；清空一股灰；结算时金币往外蹦
				var mbu: BUnit = e["unit"]
				var ch: String = str(e.get("change", ""))
				var mb_at: Vector3 = _chest(mbu) + Vector3(0, 0.95, 0)
				match ch:
					"add":
						if _gate("bag:" + mbu.uid, 0.6):
							fx.number(mb_at, Loc.t("ui.fx.bag") % int(e.get("coins", 0)), Fx.COIN_GOLD, 0.75)
					"double":
						fx.number(mb_at, Loc.t("ui.fx.bag_double") % int(e.get("coins", 0)), Fx.COIN_GOLD, 1.0)
						fx.coin_pop(_chest(mbu), 3)
						fx.soft_flash(_chest(mbu), Fx.COIN_GOLD, 1.0, 0.25, 2.0)
					"clear":
						fx.number(mb_at, Loc.t("ui.fx.bag_clear"), Color("#b8b0a4"), 0.85)
						fx.burst(_chest(mbu), Color("#8a8278"), 10, 1.6, 0.9, 0.6, 0.6, false)
					"cash":
						if int(e.get("delta", 0)) > 0:
							fx.number(mb_at, Loc.t("ui.fx.bag_cash") % int(e.get("delta", 0)), Fx.COIN_GOLD, 1.0)
							fx.coin_pop(_chest(mbu), mini(8, int(e.get("delta", 0))))
			"quake_windup":
				# 裂地猛击：举锤 → 0.3 秒后砸到地上(动作 slam_paladin_<大类>；没有就用这类武器的攻击动作)
				var qu: BUnit = e["unit"]
				var qv: UnitView = _view(qu)
				if qv != null:
					var qa: String = "slam_%s_%s" % [qu.def.model, qu.weapon_class()]
					if qv.ap.has_animation(qa):
						qv.play_once(qa)
					else:
						qv.play_attack(1.0 * speed)
					qv.rotation.y = qu.facing
				# 前摇：锥形范围的轮廓亮起来、砸点的圣印往下收、锤头聚光(锤头 = 武器骨上 PAL_HAMMER_HEAD；拿剑 / 长柄时取武器尖)
				var qdir: Vector2 = e.get("dir", Vector2(sin(qu.facing), cos(qu.facing)))
				var qhead: Vector3 = PAL_HAMMER_HEAD if qu.weapon_class() == "heavy" else PAL_BLADE_TIP
				var qref: WeakRef = weakref(qv)
				var qget := func() -> Vector3:
					var qv1: UnitView = qref.get_ref() as UnitView
					return qv1.bone_point("Bow", qhead) if qv1 != null and not qv1.dying else Vector3(qu.pos.x, 1.4, qu.pos.y)
				fx.quake_windup(Vector3(qu.pos.x, 0.0, qu.pos.y), Vector3(qdir.x, 0.0, qdir.y), float(e.get("angle", 100.0)), float(e.get("length", 3.5)),
					float(e.get("impact", 0.3)), qget)
			"quake_slam":
				var qsu: BUnit = e["unit"]
				var qd: Vector2 = e["dir"]
				fx.quake_slam(Vector3(qsu.pos.x, 0.0, qsu.pos.y), Vector3(qd.x, 0.0, qd.y), float(e.get("angle", 100.0)), float(e.get("length", 3.5)))
				shake.emit(0.09 if int(e.get("broke", 0)) > 0 else 0.07)
			"terrain_break":
				terrain_break.emit(str(e.get("kind", "obstacle")), int(e.get("id", -1)))
			"chain_hop":
				# 引雷(导向节点)：连锁闪电一跳一跳地传过去(Battle 每跳隔 CHAIN_HOP_DT 秒结算)：这一跳从上一个人(第一跳 = 她手里)推到下一个人，
				# 打中后整条留一会儿；同一串的每一节记下来，传完时整条再亮一下
				var chu: BUnit = e["unit"]
				var cht: BUnit = e.get("to") as BUnit
				if chu != null and cht != null:
					var chf: BUnit = e.get("from") as BUnit
					var from: Vector3
					if chf == null:
						var clv: UnitView = _view(chu)
						from = clv.bone_origin("Bow") if clv != null else _chest(chu)
						if clv != null and from.y < 0.3:
							from = _chest(chu)
					else:
						from = _chest(chf)
					var ckey: String = chu.uid + ("c" if bool(e.get("copy", false)) else "")
					if int(e.get("i", 0)) == 0:
						chain_arcs[ckey] = []
					var carcs: Array = chain_arcs.get(ckey, [])
					carcs.append(fx.chain_hop(from, _chest(cht), float(e.get("dt", 0.0)), chf == null))
					chain_arcs[ckey] = carcs
			"chain_lightning":
				# 整条链传完：每一节再亮一下、每个被打中的人脚下闪一圈；连得长的震一下屏幕
				var clu: BUnit = e["unit"]
				var ckey2: String = clu.uid + ("c" if bool(e.get("copy", false)) else "")
				var cnodes: Array = []
				for cp: Variant in e.get("path", []):
					var cpu: BUnit = cp as BUnit
					if cpu != null:
						cnodes.append(_chest(cpu))
				fx.chain_done(chain_arcs.get(ckey2, []), cnodes)
				chain_arcs.erase(ckey2)
				if cnodes.size() > 3:
					shake.emit(0.03)
			"paralyze":
				var pzt: BUnit = e["target"]
				if pzt != null and pzt.alive:
					fx.paralysis_zap(_chest(pzt), true)
			"paralyzed":
				# 麻痹：这一下普攻被打断
				var pdu: BUnit = e["unit"]
				fx.paralysis_zap(_chest(pdu), true)
				if _gate("paralyzed:" + pdu.uid, 0.8):
					fx.number(_chest(pdu) + Vector3(0, 0.7, 0), Loc.t("ui.fx.paralyzed"), Fx.THUNDER, 0.8)
			"weather":
				# 变天(导向节点)：GameWorld 换天气；她头上飘一行字
				var wk: String = str(e.get("kind", ""))
				weather.emit(wk)
				var wsu0: BUnit = e.get("unit") as BUnit
				if wsu0 != null and wk != "":
					var wcol: Color = Fx.THUNDER if wk == "sunny" else (Color("#c8d2de") if wk == "fog" else Color("#9fc8ff"))
					fx.number(_chest(wsu0) + Vector3(0, 1.0, 0), Loc.t("ui.fx.weather_" + wk), wcol, 1.0, 0.9, 1.4)
			"form_shift":
				# 守林节点变身：绿叶卷起来裹住她，换成这个形态的动作 / 体型；变回基础形态时武器回到手里
				var wsu: BUnit = e["unit"]
				var wsv: UnitView = _view(wsu)
				var wform: String = str(e.get("form", "base"))
				if wsv != null:
					fx.wild_shift(Vector3(wsu.pos.x, 0.0, wsu.pos.y), wsv.body_height, wform)
					wsv.set_beast_form(wform)
					# 背后灵：旧的散掉，换成这个形态的野兽灵体(变回基础形态就没有了)
					if beast_spirits.has(wsu.uid) and is_instance_valid(beast_spirits[wsu.uid]):
						(beast_spirits[wsu.uid] as BeastSpirit).vanish()
					beast_spirits.erase(wsu.uid)
					if BeastSpirit.COLS.has(wform):
						var bsp: BeastSpirit = BeastSpirit.create(wform, wsv, wsu)
						add_child(bsp)
						beast_spirits[wsu.uid] = bsp
						get_tree().create_timer(0.35 / maxf(0.1, speed)).timeout.connect(bsp.roar)
					wsv.form_size = float(WARDEN_FORM_SIZE.get(wform, 1.0))
					wsv.set_size(wsu.size_mult() * wsv.form_size, true)
					if str(e.get("reason", "")) == "death":
						wsv.play_once("shift_" + wsu.def.model)
						shake.emit(0.05)
					fx.number(_chest(wsu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.form_" + wform), Fx.WARDEN_FORM_COLS.get(wform, Color("#9fe07a")), 1.0)
			"verdant_grove":
				var vgu: BUnit = e.get("target", e["unit"])
				if vgu != null and _gate("verdant:" + vgu.uid, 0.4):
					fx.verdant_grove(_chest(vgu), float(e.get("heal", 0.0)) > 0.0)
			"funeral":
				# 送葬叠满：绕着飞的黑蝶一起扑进身体——倒下的(普通怪物 / 棋子)身体化掉、化成一大群黑白蝴蝶飞散；
				# 精英 / 首领(失去生命上限)：黑蝶咬一口四散，身上停下一只黑蝶(送葬之痕，最多 3 只)
				var fnt: BUnit = e["target"]
				var fnp: Vector2 = e.get("pos", fnt.pos)
				var fkill: bool = bool(e.get("kill", false))
				var fnv: UnitView = _view(fnt)
				if is_instance_valid(funeral_wreaths.get(fnt.uid)):
					(funeral_wreaths[fnt.uid] as FuneralWreath).release()
				funeral_wreaths.erase(fnt.uid)
				fx.funeral(Vector3(fnp.x, 0.0, fnp.y), fkill, fnv.body_height if fnv != null else 1.3)
				if fkill:
					funeral_doomed[fnt.uid] = true
					if _gate("funeral:" + fnt.uid, 0.5):
						fx.number(Vector3(fnp.x, 1.8, fnp.y), Loc.t("ui.fx.funeral"), Color("#f0ecff"), 0.95)
				elif fnv != null:
					var scs: Array = (funeral_scars.get(fnt.uid, []) as Array).filter(func(x: Variant) -> bool: return is_instance_valid(x))
					if scs.size() < 3:
						scs.append(fx.funeral_scar(fnv, scs.size(), fnv.body_height))
					funeral_scars[fnt.uid] = scs
			"funeral_save":
				# 致求生的意志：身后张开一对半透明的白蝶大翅膀、一圈白蝶飞散；绕着他的黑蝶被一下子推开
				var fsu: BUnit = e["target"]
				if fsu != null and fsu.alive:
					var fsv2: UnitView = _view(fsu)
					var fh: float = fsv2.body_height if fsv2 != null else 1.3
					fx.will_live(Vector3(fsu.pos.x, fh * 0.55, fsu.pos.y), fsv2.rotation.y if fsv2 != null else fsu.facing, fh)
					if is_instance_valid(funeral_wreaths.get(fsu.uid)):
						(funeral_wreaths[fsu.uid] as FuneralWreath).pulse()
					if _gate("will:" + fsu.uid, 0.6):
						fx.number(_chest(fsu) + Vector3(0, 0.8, 0), "%s %d/%d" % [Loc.t("ui.fx.will_live"), int(e.get("stacks", 0)), int(e.get("of", 0))],
							Color("#fff1c4"), 0.85)
			"intox_song":
				# 美妙地：麦克风里旋出一条五线谱 + 一圈圈声波 + 给每个被唱到的人一枚拖着闪光的音符
				var isu: BUnit = e["unit"]
				var ipts: Array = []
				for it0: Variant in e.get("targets", []):
					var itu: BUnit = it0 as BUnit
					if itu != null and itu.alive:
						ipts.append(_chest(itu))
				fx.song_wave(Vector3(isu.pos.x, 0.0, isu.pos.y), _song_mouth(isu), ipts)
			"gentle_start":
				var gsu: BUnit = e["unit"]
				if gsu != null:
					fx.gentle_wave(Vector3(gsu.pos.x, 0.0, gsu.pos.y))
					fx.number(_chest(gsu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.gentle"), Color("#ffd1e4"), 1.15)
					_gentle_open(gsu)
			"gentle_end":
				_gentle_close(e.get("unit") as BUnit)
			"holy_sword":
				# 勇者，圣剑：光剑从天上插下来；直接击杀时更大、飘"圣剑！"
				var hsu: BUnit = e["target"]
				var hp0v: Vector2 = e.get("pos", hsu.pos)
				fx.holy_sword(Vector3(hp0v.x, 0.0, hp0v.y), bool(e.get("kill", false)))
				if bool(e.get("kill", false)):
					fx.number(Vector3(hp0v.x, 1.9, hp0v.y), Loc.t("ui.fx.holy_slay"), Color("#cfe0ff"), 1.0)
					shake.emit(0.06)
			"hope_revive":
				# 希望：被复活的队友(复活本身的光柱 / 飘字由 revive 事件画)：从她身上飞过去一道光 + 白羽
				var hru: BUnit = e["unit"]
				var hrt: BUnit = e["target"]
				var hrv: UnitView = _view(hrt)
				if hrv != null:
					fx.hope_rebirth(hrv, hrv.body_height, _chest(hru))
				else:
					fx.fly_again(_chest(hru), _chest(hrt))
				fx.number(_chest(hrt) + Vector3(0, 1.2, 0), Loc.t("ui.fx.fly_again"), Color("#dce8ff"), 0.85)
			"brave_legacy":
				# 梦想，未来：她倒下时，属性提升化作光飞向每个队友
				var blu: BUnit = e["unit"]
				for bt0: Variant in e.get("targets", []):
					var btu: BUnit = bt0 as BUnit
					if btu != null and btu.alive:
						fx.future_stream(_chest(blu), _chest(btu))
						fx.number(_chest(btu) + Vector3(0, 0.9, 0), Loc.t("ui.fx.future"), Color("#ffe39a"), 0.8)
			"lily_tick":
				# 再绽之花的每一秒：花瓣收进胸口 → 花蕊 +1
				var lku: BUnit = e["unit"]
				fx.petal_gather(_chest(lku))
				fx.number(_chest(lku) + Vector3(0, 0.8, 0), Loc.t("ui.fx.stamen") % str(int(e.get("tick", 1))), Color("#ffe39a"), 0.75)
			"lily_full_bloom":
				var lbu: BUnit = e["unit"]
				var lbc: LilyCounter = _lily_counter(lbu)
				if lbc != null:
					lbc.set_bloom(true)
				fx.lily_bloom(Vector3(lbu.pos.x, 0.0, lbu.pos.y))
				fx.number(_chest(lbu) + Vector3(0, 1.1, 0), Loc.t("ui.fx.bloom"), Color("#fff3c8"), 1.1)
				shake.emit(0.06)
			"lily_heal":
				# 光刃打出的伤害智能分配成治疗：花瓣沿弧线飞到每个受伤的友军身上
				var lhu: BUnit = e["unit"]
				for ht0: Variant in e.get("targets", []):
					var htu0: BUnit = ht0 as BUnit
					if htu0 != null and htu0.alive and htu0 != lhu:
						fx.petal_stream(_chest(lhu), _chest(htu0))
			"breath":
				# 龙息：从嘴里沿射线喷出一道火流；被烧到的人身上炸一下火星
				var bu2: BUnit = e["unit"]
				var bv2: UnitView = _view(bu2)
				var d2: Vector2 = e["dir"]
				var dir3 := Vector3(d2.x, 0.0, d2.y)
				# 嘴：从模型的头骨上取(上颌里、嘴的中间)。它体型很大(放大 2 × 1.2，虚荣时再 ×√2)，嘴在 3~4 米高——
				# 以前龙息从这个高度水平喷出去(还往上飘)，从人头顶上飞过去，看起来根本没喷到挨伤害的人
				var mouth: Vector3 = bv2.bone_point("Head", VANITY_MOUTH) if bv2 != null else 					Vector3(bu2.pos.x, 2.0, bu2.pos.y) + dir3 * bu2.radius * 0.75
				var reach: float = float(e["length"])
				var end_pt := Vector3(bu2.pos.x, 0.0, bu2.pos.y) + dir3 * reach
				var hit_pts: Array = []
				for tg: Variant in e.get("targets", []):
					var tu: BUnit = tg as BUnit
					if tu != null and tu.alive:
						hit_pts.append(_chest(tu))
				fx.breath(mouth, end_pt, float(e["width"]), hit_pts)
			"detonate":
				# 解放：被引爆的燃烧一下子炸开
				var du: BUnit = e["unit"]
				fx.explosion(_chest(du), 0.9, Color("#ff5a1a"), 0.7)
				if float(e.get("amount", 0.0)) >= 1.0:
					fx.number(_chest(du) + Vector3(0, 0.75, 0), Loc.t("ui.fx.detonate"), Color("#ffb23a"), 0.8)
			"consume":
				# 引火：燃烧被吞掉——火星从目标飞向怠惰的余烬(贪婪的余烬：紫色的火星被吸进魔典)
				var cu: BUnit = e["unit"]
				var cs: BUnit = e.get("src") as BUnit
				if str(e.get("style", "")) == "greed":
					fx.greed_swallow(_chest(cu), _chest(cs) if cs != null else _chest(cu), int(e.get("count", 1)))
					continue
				fx.burst(_chest(cu), Color("#ff7a22"), 10 + 4 * int(e.get("count", 1)), 2.6, 1.0, 0.8, 0.5)
				if cs != null:
					fx.streak(_chest(cu), _chest(cs), Color("#ff9a3a"), 0.35, 0.4)
			"entangle":
				var gu: BUnit = e["unit"]
				fx.ring(Vector3(gu.pos.x, 0, gu.pos.y), 0.9, Color("#ff4a12"), 0.5)
			"status":
				# 增幅链路(RX 增幅中继)：天线连一道数据光过去；中继自己一圈信号波(同一次广播只画一次)
				if str(e.get("base_id", e.get("id", ""))) == "amp_link" and int(e.get("stacks", 0)) > 0:
					var lsrc: BUnit = e.get("src") as BUnit
					var ldst: BUnit = e["unit"] as BUnit
					var lsv: UnitView = _view(lsrc) if lsrc != null else null
					if lsv != null and ldst != null and MECH.has(lsrc.def.model) and (MECH[lsrc.def.model] as Dictionary).has("antenna"):
						var ant: Vector3 = lsv.bone_point("Chest", MECH[lsrc.def.model]["antenna"])
						if ldst != lsrc:
							fx.data_link(ant, _chest(ldst))
						if _gate("relay:" + lsrc.uid, 0.8):
							fx.relay_pulse(ant, Vector3(lsrc.pos.x, 0.0, lsrc.pos.y), 6.0)
							if not lsv.is_busy():
								lsv.play_once("broadcast_" + lsrc.def.model)
				# 【送葬】(白羽节点)：每一层 = 一只绕着飞的黑蝶，从施加者那一侧飞进来；清零时先记下(满层结算的 funeral 事件紧跟在后面，让黑蝶扑进身体)
				if str(e.get("base_id", e.get("id", ""))) == "funeral":
					var fnu: BUnit = e["unit"] as BUnit
					var fst: int = int(e.get("stacks", 0))
					if fnu != null and fst > 0 and fnu.alive:
						var fsv0: UnitView = _view(fnu)
						if fsv0 != null:
							var fw0: Variant = funeral_wreaths.get(fnu.uid)
							if not is_instance_valid(fw0):
								fw0 = FuneralWreath.create(fx, fsv0, fsv0.body_height * 0.62)
								funeral_wreaths[fnu.uid] = fw0
							var fbs: BStatus = fnu.get_status(str(e.get("id", "funeral")))
							var fsrc: BUnit = e.get("src") as BUnit
							(fw0 as FuneralWreath).set_stacks(fst, fbs.max_stacks if fbs != null and fbs.max_stacks > 0 else 10,
								_chest(fsrc) if fsrc != null else null)
					elif fnu != null:
						_wreath_clear.append(fnu)
				# 【燃烧】：身上冒火苗(每次施加独立——最后一个燃烧结束时才熄掉)
				if str(e.get("base_id", e.get("id", ""))) == "burning":
					var bu0: BUnit = e["unit"] as BUnit
					_set_burning(bu0, bu0 != null and bu0.status_count("burning") > 0)
				# 体型变化(虚荣)：获得时放大、失去时缩小，带一小段过渡；获得时一圈金色的冲击环 + 火星，失去时一股烟
				var su: BUnit = e["unit"] as BUnit
				var sv: UnitView = _view(su) if su != null else null
				if sv != null:
					su.get_stats()
					var want: float = su.size_mult() * sv.form_size
					if absf(want - sv.size_target) > 0.01:
						var feet := Vector3(su.pos.x, 0.0, su.pos.y)
						if want > sv.size_k:
							fx.ring(feet, su.radius * 2.6, Color("#ffcf5a"), 0.6, 1.6)
							fx.burst(_chest(su), Color("#ffb23a"), 26, 3.4, 1.4, 0.8, 0.7)
							fx.number(_chest(su) + Vector3(0, 1.2, 0), Loc.t("ui.fx.vanity"), Color("#ffd35a"), 1.1)
						else:
							fx.burst(_chest(su), Color("#4a4440"), 18, 1.6, 1.8, 1.0, 0.9, false)
							fx.number(_chest(su) + Vector3(0, 0.8, 0), Loc.t("ui.fx.vanity_lost"), Color("#c8b8a8"), 0.9)
						sv.set_size(want, true)
				# 预热(怠惰的余烬)：越热身上越亮
				if str(e.get("base_id", e.get("id", ""))) == "sloth_preheat":
					var pv: UnitView = _view(e["unit"] as BUnit)
					if pv != null:
						var stp: BStatus = (e["unit"] as BUnit).get_status("sloth_preheat")
						pv.set_glow(0.0 if stp == null else 0.6 * float(stp.stacks) / maxf(1.0, float(stp.max_stacks)))
				# 光荣(凯旋)：层数涨了飘"光荣 ×N"，5 / 8 / 10 层再亮一圈
				if str(e.get("base_id", e.get("id", ""))) == "glory":
					var glu: BUnit = e["unit"]
					var gst: int = int(e.get("stacks", 0))
					var gold: int = int(glory_seen.get(glu.uid, 0))
					# 武器上的火：层数越多烧得越旺(WeaponFlame)
					var wfl: WeaponFlame = _weapon_flame(glu)
					if wfl != null:
						var gsts: BStatus = glu.get_status("glory")
						wfl.set_level(gst, gsts.max_stacks if gsts != null and gsts.max_stacks > 0 else 10)
					if gst > gold:
						fx.number(_chest(glu) + Vector3(0, 0.8, 0), Loc.t("ui.fx.glory") % str(gst), Color("#ffd35a"), 0.9)
						fx.burst(_chest(glu), Color("#ffe27a"), 8, 2.0, 0.8, 1.0, 0.5)
						# 跨过 5 / 8 / 10：武器一下子烧得更旺(阶段特效)
						var nst: int = WeaponFlame.stage_of(gst)
						if nst > WeaponFlame.stage_of(gold):
							fx.weapon_ignite(wfl.blade_center() if wfl != null else _chest(glu), Vector3(glu.pos.x, 0, glu.pos.y), nst)
							if nst >= 3:
								shake.emit(0.06)
					glory_seen[glu.uid] = gst
				# 剑痕(残光)：身上一道道发光的刀口，层数 = 刀口数
				if str(e.get("base_id", e.get("id", ""))) == "sword_scar":
					_sync_scars(e["unit"] as BUnit, int(e.get("stacks", 0)))
				# 重燃(不灭)：层数涨的时候脚下冒一点火星
				if str(e.get("base_id", e.get("id", ""))) == "rekindle" and int(e.get("stacks", 0)) > 0:
					var rku: BUnit = e["unit"]
					if _gate("rekindle:" + rku.uid, 0.45):
						fx.burst(Vector3(rku.pos.x, 0.25, rku.pos.y), Color("#ff9a3a"), 4, 1.2, 0.6, 1.6, 0.45)
				# 赤焰战旗的强化：身上窜一下火星
				if str(e.get("base_id", e.get("id", ""))) == "flame_banner":
					var fbu: BUnit = e["unit"]
					fx.burst(_chest(fbu), Color("#ff8a2a"), 8, 2.2, 0.8, 1.4, 0.5)
				# 进入"缩头"：飘个字提示(状态本身由 UnitView 播缩头动作)
				if str(e.get("id", "")) == "turtle" and bool(e.get("created", false)):
					var tu2: BUnit = e["unit"]
					fx.number(_chest(tu2) + Vector3(0, 0.7, 0), Loc.t("status.turtle") + "!", Color("#9adcff"), 0.85)
				# 初星之光：第一次罩上时亮一圈金光
				if str(e.get("base_id", e.get("id", ""))) == "first_star_light" and bool(e.get("created", false)):
					var lu: BUnit = e["unit"]
					if _gate("fsl:" + lu.uid, 30.0):
						fx.ring(Vector3(lu.pos.x, 0, lu.pos.y), 1.0, Color("#ffe27a"), 0.6, 1.4, 0.3)
						fx.burst(_chest(lu), Color("#fff1b0"), 8, 1.6, 0.8, 0.8, 0.6)
				# 颜料(幻彩节点)：拿到时手边炸开一小团、头顶边上挂一颗转着的颜料块；颜料用掉 / 换掉时拿掉
				if str(e.get("base_id", e.get("id", ""))) == "paint":
					var pu0: BUnit = e["unit"]
					var pv0: UnitView = _view(pu0)
					if paint_orbs.has(pu0.uid):
						if is_instance_valid(paint_orbs[pu0.uid]):
							(paint_orbs[pu0.uid] as Node3D).queue_free()
						paint_orbs.erase(pu0.uid)
					if int(e.get("stacks", 0)) > 0 and pv0 != null and pu0.alive:
						var pcol: String = str(e.get("variant", ""))
						paint_orbs[pu0.uid] = fx.paint_orb(pv0, Vector3(0.0, pv0.body_height + 0.12, 0.0), pcol)
						fx.paint_gain(_chest(pu0) + Vector3(0, 0.15, 0), pcol)
						if _gate("paint:" + pu0.uid, 0.5):
							fx.number(_chest(pu0) + Vector3(0, 0.75, 0), Loc.t("ui.fx.paint_" + pcol), Fx.PAINT_COLORS.get(pcol, Color.WHITE), 0.7)
				var sbid: String = str(e.get("base_id", e.get("id", "")))
				# 花蕊(正行节点)：头顶一圈发光的花苞，几层就几颗
				if sbid == "lily_stamen":
					_sync_stamens(e["unit"] as BUnit, int(e.get("stacks", 0)))
					# 有花蕊时手里的武器化成光武器(层数越多越长)，花蕊用完碎成花瓣
					var lwv: UnitView = _view(e["unit"] as BUnit)
					if lwv != null and (int(e.get("stacks", 0)) > 0 or lwv.light_weapon != null):
						var lw: LightWeapon = lwv.ensure_light_weapon()
						if lw != null:
							lw.set_charges(int(e.get("stacks", 0)))
				# 花瓣：层数涨了身上飘几片花瓣(限流)
				if sbid == "lily_petal":
					var lpu: BUnit = e["unit"]
					var lps: int = int(e.get("stacks", 0))
					if lps > int(petal_seen.get(lpu.uid, 0)) and _gate("petal:" + lpu.uid, 0.5):
						fx.petal_puff(_chest(lpu), 3 + mini(4, lps - int(petal_seen.get(lpu.uid, 0))), 0.9, 0.7)
					petal_seen[lpu.uid] = lps
					var lc: LilyCounter = _lily_counter(lpu)
					if lc != null:
						var lst: BStatus = lpu.get_status("lily_petal")
						if lst != null and lst.max_stacks > 0 and lc.stacks == 0 and lps > 0:
							lc.cap = mini(lst.max_stacks, 12)
						lc.set_stacks(lps)
				if sbid == "frozen" and int(e.get("stacks", 0)) <= 0 and ice_blocks.has((e["unit"] as BUnit).uid):
					var iu0: BUnit = e["unit"]
					if is_instance_valid(ice_blocks[iu0.uid]):
						(ice_blocks[iu0.uid] as Node3D).queue_free()
					ice_blocks.erase(iu0.uid)
					fx.ice_shatter(_chest(iu0))
				if sbid == "bleed" and int(e.get("stacks", 0)) > 0 and _gate("bleed:" + (e["unit"] as BUnit).uid, 0.8):
					var blu: BUnit = e["unit"]
					var bls: BUnit = e.get("src") as BUnit
					fx.bleed_drip(_chest(blu), Vector3(blu.pos.x - bls.pos.x, 0.0, blu.pos.y - bls.pos.y) if bls != null else Vector3.ZERO)
				# 血欲(血嗜节点)：脚下的血雾随层数变浓
				if sbid == "bloodlust":
					_sync_blood_aura(e["unit"] as BUnit, int(e.get("stacks", 0)))
				if sbid == "infusion" and int(e.get("stacks", 0)) > 0 and _gate("infuse:" + (e["unit"] as BUnit).uid, 1.0):
					fx.infusion_puff(_chest(e["unit"] as BUnit))
				if sbid == "chill" and bool(e.get("created", false)) and _gate("chill:" + (e["unit"] as BUnit).uid, 0.6):
					fx.chill_puff(_chest(e["unit"] as BUnit))
				if sbid == "regen" and bool(e.get("created", false)) and _gate("regen:" + (e["unit"] as BUnit).uid, 0.6):
					fx.float_icons(_chest(e["unit"] as BUnit), fx.cross_mesh(), Fx.PERFORM_COLORS["regen"], 3, 0.3, 0.8, 0.9)
				# 傲慢的恩赐：受赐的小怪头顶闪一下金光(傲慢的余烬的敕令)
				if str(e.get("base_id", e.get("id", ""))) == "pride_favor" and bool(e.get("created", false)):
					var pf: BUnit = e["unit"]
					if pf != null and pf.alive and _gate("favor:" + pf.uid, 3.0):
						fx.burst(_chest(pf) + Vector3(0, 0.45, 0), Fx.GOLD, 8, 1.2, 0.7, 1.4, 0.45)
						fx.ring(Vector3(pf.pos.x, 0.0, pf.pos.y), 0.7, Fx.GOLD, 0.4, 1.0, 0.3)
				# 黄金的指引：脚下一圈淡金光环
				if str(e.get("base_id", e.get("id", ""))) == "golden_guidance":
					var gu0: BUnit = e["unit"]
					var gv0: UnitView = _view(gu0)
					if int(e.get("stacks", 0)) > 0 and gu0.alive and gv0 != null and not guidance_rings.has(gu0.uid):
						guidance_rings[gu0.uid] = fx.guidance_ring(gv0, gu0.radius * 1.5)
					elif int(e.get("stacks", 0)) <= 0 and guidance_rings.has(gu0.uid):
						if is_instance_valid(guidance_rings[gu0.uid]):
							(guidance_rings[gu0.uid] as Node3D).queue_free()
						guidance_rings.erase(gu0.uid)
				# 变奏节点：悲怆 / 热情全场加层——从她身上推一道波(每个被加层的人都会发一次状态事件：按她 2.5 秒一次)
				var mbid: String = str(e.get("base_id", e.get("id", "")))
				if (mbid == "despair" or mbid == "elation") and int(e.get("stacks", 0)) > 0:
					var msrc: BUnit = e.get("src") as BUnit
					if msrc != null and msrc.alive and msrc.def.model.begins_with("pianist") and _gate("mood:" + msrc.uid, 2.5):
						fx.piano_wave(Vector3(msrc.pos.x, 0.0, msrc.pos.y), mbid == "elation")
				# 误导 / 眩晕：头顶挂标记，状态没了就拿掉
				var bid: String = str(e.get("base_id", e.get("id", "")))
				if bid == "misled" or bid == "stun":
					var mu0: BUnit = e["unit"]
					var mv0: UnitView = _view(mu0)
					var marks: Dictionary = misled_marks if bid == "misled" else stun_marks
					var on: bool = int(e.get("stacks", 0)) > 0 and mu0.alive
					if on and not marks.has(mu0.uid) and mv0 != null:
						var lsrc: BUnit = e.get("src") as BUnit
						var locked: bool = bid == "stun" and lsrc != null and lsrc.def.model == "keeper"
						if locked:
							# 锁芯节点锁住的：头顶一把晃着的金锁 + 胸口一圈转着的锁链(代替通用的眩晕星星)
							marks[mu0.uid] = fx.lock_mark(mv0, Vector3(0, mv0.body_height + 0.22, 0), mv0.body_height * 0.58, mu0.radius * 0.62 + 0.08)
						else:
							marks[mu0.uid] = fx.misled_mark(mv0, Vector3(0, mv0.body_height + 0.32, 0)) if bid == "misled" else fx.stun_mark(mv0, Vector3(0, mv0.body_height + 0.12, 0))
						if bid == "stun":
							fx.number(_chest(mu0) + Vector3(0, 0.7, 0), Loc.t("ui.fx.stun"), Fx.CULT_GOLD if locked else Color("#ffe27a"), 0.75)
					elif not on and marks.has(mu0.uid):
						if is_instance_valid(marks[mu0.uid]):
							(marks[mu0.uid] as Node3D).queue_free()
						marks.erase(mu0.uid)
				# 乱念的咒语：飘出这次抽到的是哪种效果、多少
				if str(e.get("base_id", "")) == "garbled_spell" and bool(e.get("created", false)):
					var gu: BUnit = e["unit"]
					var vv: float = float(e.get("variant_value", 0.0))
					var vtag: String = str(e.get("variant", ""))
					var shown: String = str(int(round(vv * 100.0))) if vtag != "ability_power" else str(int(round(vv)))
					fx.number(_chest(gu) + Vector3(0, 0.95, 0), Loc.t("ui.fx.garbled." + vtag) % shown, Fx.COLORS["buff"], 0.75)
			"shield":
				var dst: BUnit = e["dst"]
				if float(e["amount"]) >= 1.0 and str(e.get("surface", "")) != "passive":
					fx.number(_chest(dst) + Vector3(0, 0.25, 0), "+%d" % int(round(float(e["amount"]))), Fx.COLORS["shield"], 0.85)
				fx.ring(Vector3(dst.pos.x, 0, dst.pos.y), 0.85, Fx.COLORS["shield"], 0.4)
				var sv: UnitView = _view(dst)
				if sv != null:
					sv.pulse_bar()
			"trigger":
				_on_trigger(e)
			"death":
				_on_death(e)
			"summon":
				var nu: BUnit = e["unit"]
				_add_view(nu, true)
				if nu.def.id == "node_dog" or nu.def.id == "node_ghost":
					fx.spirit_puff(_chest(nu), not bool(e.get("spectral", true)))     # 幻灵节点的灵体：一团淡紫灵火(吟唱里召出来的大一团)
				elif nu.def.model.begins_with("ember_"):
					# 余烬从熔岩里爬出来(傲慢的召唤)：火的颜色 = 那一只的身份色
					fx.ember_summon(Vector3(nu.pos.x, 0, nu.pos.y), _ident_color(nu, Color("#ff5a1a")))
				elif str(e.get("kind", "")) == "phantom":
					# 逆时幻影：她的样子(拿着她的武器)，半透明紫色；出现时一圈逆转的钟面光环
					var pv: UnitView = _view(nu)
					var psu: BUnit = e.get("summoner") as BUnit
					if pv != null and psu != null and psu.weapon != null:
						pv.set_weapon(psu.weapon)
						var psv: UnitView = _view(psu)
						if psv != null:
							pv.set_weapon_model(str(psv.look.get("model", "")))
					if pv != null:
						pv.set_ghost_tint(Fx.PHANTOM_VIOLET)
						pv.ghost_target = 0.55
						fx.phantom_clock(pv, 0.62)              # 脚下一直逆着转的钟面
					fx.phantom_rewind(Vector3(nu.pos.x, 0, nu.pos.y))
				elif str(e.get("kind", "")) == "sister_copy":
					# 量产型号：复制品出场
					fx.clockwork_copy(Vector3(nu.pos.x, 0, nu.pos.y))
					if _gate("mass:" + str((e.get("summoner") as BUnit).uid if e.get("summoner") is BUnit else ""), 1.0):
						fx.number(_chest(nu) + Vector3(0, 0.8, 0), Loc.t("ui.fx.mass_copy"), Fx.SISTER_GOLD, 0.75)
				elif nu.def.id == "node_bird":
					fx.raven_summon(Vector3(nu.pos.x, 0, nu.pos.y))     # 渡鸦使魔：灵焰一闪 + 蓝黑羽毛炸开飘落
				else:
					fx.pillar(Vector3(nu.pos.x, 0, nu.pos.y), GC.faction_color(nu.def.faction_id))
					fx.ring(Vector3(nu.pos.x, 0, nu.pos.y), 1.4, GC.faction_color(nu.def.faction_id), 0.6)
			"starfall_start":
				# 渡星而来：倒计时里从天上落下来(拖着星光)，落点先亮一圈预警
				var su0: BUnit = e["unit"]
				var sv0: UnitView = _view(su0)
				var real: float = float(e["dur"]) / maxf(0.05, speed)
				if sv0 != null:
					sv0.fall_in(real, 16.0)
					var cm: Node3D = fx.comet_trail()
					sv0.model.add_child(cm)
					astro_comets[su0.uid] = cm
				fx.starfall_warn(Vector3((e["to"] as Vector2).x, 0, (e["to"] as Vector2).y), battle.pipeline.passive_splash_radius(su0), float(e["dur"]))
			"starfall_land":
				var su1: BUnit = e["unit"]
				var sv1: UnitView = _view(su1)
				if sv1 != null:
					sv1.set_bar_visible(true)
					sv1.position = Vector3(su1.pos.x, 0, su1.pos.y)
				fx.end_comet(astro_comets.get(su1.uid, null))
				astro_comets.erase(su1.uid)
				fx.starfall_impact(Vector3(su1.pos.x, 0, su1.pos.y), battle.pipeline.passive_splash_radius(su1))
				shake.emit(0.12)
				_add_astro_ring(su1)
			"golden_arrow":
				var gat: BUnit = e["target"]
				fx.golden_hit(_chest(gat))
				fx.number(_chest(gat) + Vector3(0, 0.8, 0), Loc.t("ui.fx.charge_up"), Fx.GOLD, 0.75)
			"team_revive":
				# 少女真心：她身上一圈金光 + 大字；被复活的人各一道金色光柱
				var tru: BUnit = e["unit"]
				fx.ring(Vector3(tru.pos.x, 0.0, tru.pos.y), 3.0, Fx.GOLD, 0.8, 2.0, 0.1)
				fx.number(_chest(tru) + Vector3(0, 1.1, 0), Loc.t("ui.fx.true_heart"), Fx.GOLD_HOT, 1.2)
				shake.emit(0.1)
			"revive":
				var rvu: BUnit = e["unit"]
				if views.has(rvu.uid):
					(views[rvu.uid] as UnitView).queue_free()
					views.erase(rvu.uid)
				var nv: UnitView = _add_view(rvu, true)
				guidance_rings.erase(rvu.uid)
				if rvu.status_stacks("golden_guidance") > 0:
					guidance_rings[rvu.uid] = fx.guidance_ring(nv, rvu.radius * 1.5)
				# 希望的复活(与你，再度飞翔)：光柱 / 翅膀 / 法阵由 hope_revive 画，这里不再叠一道金色光柱
				if str(e.get("kind", "")) != "hope":
					fx.revive_pillar(_chest(rvu))
					fx.number(_chest(rvu) + Vector3(0, 0.8, 0), Loc.t("ui.fx.revive"), Fx.GOLD_HOT, 0.9)
			"refresh_once":
				var rfu: BUnit = e["unit"]
				fx.number(_chest(rfu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.refresh"), Fx.GOLD, 0.9)
				fx.ring(Vector3(rfu.pos.x, 0.0, rfu.pos.y), 1.2, Fx.GOLD, 0.5, 1.4, 0.2)
			"backstab":
				var bsu: BUnit = e["unit"]
				var bst: BUnit = e["target"]
				fx.backstab(_chest(bst), Vector3(bst.pos.x - bsu.pos.x, 0.2, bst.pos.y - bsu.pos.y))
				if _gate("backstab:" + bst.uid, 0.6):
					fx.number(_chest(bst) + Vector3(0, 0.9, 0), Loc.t("ui.fx.backstab"), Color("#e6d0ff"), 0.7)
			"medium_funeral":
				# 少女幻葬：领域里的灵魂飞散到战场各处(那里冒出幽灵)
				var mfu: BUnit = e["unit"]
				if soul_domains.has(mfu.uid):
					fx.soul_domain_end(soul_domains[mfu.uid]["node"], e.get("spots", []))
					soul_domains.erase(mfu.uid)
				fx.number(_chest(mfu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.requiem"), Color("#e6d0ff"), 1.1)
				shake.emit(0.1)
			"misled":
				# 误导：字从施加者身上飞到对方头上 + 飘字(精英 / 首领：免疫自相残杀)
				var mlu: BUnit = e["unit"]
				var mls: BUnit = e.get("src") as BUnit
				if mls != null and mls != mlu:
					fx.mislead_cast(_chest(mls), _chest(mlu))
				if _gate("misled:" + mlu.uid, 0.8):
					fx.number(_chest(mlu) + Vector3(0, 0.85, 0), Loc.t("ui.fx.misled_resist" if bool(e.get("resist", false)) else "ui.fx.misled"), Color("#d6c2ff"), 0.75)
			"spy_hush":
				# 少女幻嘘：领域里的字灌进还在里面的敌人身体里 + 一闪
				var hu: BUnit = e["unit"]
				var into: Array = []
				for hx: BUnit in (e.get("hits", []) as Array):
					if hx.team != hu.team:
						into.append(_chest(hx))
				if glyph_domains.has(hu.uid):
					fx.glyph_domain_end(glyph_domains[hu.uid], into)
					glyph_domains.erase(hu.uid)
				fx.ring(Vector3(hu.pos.x, 0, hu.pos.y), float(e.get("radius", 3.0)), Color("#ffffff"), 0.5, 2.0, 0.2)
				fx.number(_chest(hu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.hush"), Color("#e6dcff"), 1.1)
				shake.emit(0.12)
			"xp":
				var xu: BUnit = e.get("unit")
				if xu != null and int(e["amount"]) > 0 and int(e["team"]) == GC.TEAM_PLAYER:
					fx.number(_chest(xu) + Vector3(0, 0.95, 0), Loc.t("ui.fx.xp") % str(int(e["amount"])), Color("#8fd8ff"), 0.9)
			"runner_kick":
				# 飞身踢：紫电炸开(倍率越高越大) + 头顶飘倍率
				var ku: BUnit = e["unit"]
				var kt: BUnit = e["target"]
				var kdir: Vector3 = Vector3(kt.pos.x - ku.pos.x, 0.0, kt.pos.y - ku.pos.y)
				fx.volt_kick(_chest(kt), kdir if kdir.length() > 0.01 else Vector3.FORWARD, float(e.get("mult", 1.0)))
				fx.number(_chest(kt) + Vector3(0, 0.75, 0), Loc.t("ui.fx.kick") % ("%.1f" % float(e.get("mult", 1.0))), Fx.VOLT_HOT, 0.75)
				shake.emit(clampf(0.02 + 0.012 * float(e.get("mult", 1.0)), 0.02, 0.08))
			"runner_spring":
				var sp0: Vector2 = e["pos"]
				fx.volt_spring(Vector3(sp0.x, 0.0, sp0.y))
			"knockback":
				var kbu: BUnit = e["unit"]
				var kf: Vector2 = e["from"]
				var kto: Vector2 = e["to"]
				if str(e.get("style", "")) == "chain":
					fx.burst(Vector3(kto.x, _chest(kbu).y, kto.y), Fx.CULT_GOLD, 6, 1.6, 0.7, 0.5, 0.35)     # 被锁链拽过来(链子由深空之门画)
				else:
					fx.volt_knock(Vector3(kf.x, _chest(kbu).y, kf.y), Vector3(kto.x, _chest(kbu).y, kto.y))
			"paint_used":
				# 颜料用掉了：打中的地方泼开一大团
				var put: BUnit = e.get("target") as BUnit
				if put != null:
					fx.paint_splash(_chest(put), str(e.get("color", "")))
			"magi_finale":
				# 少女幻终的终结一击：领域里黑白闪烁 + 白光 / 冲击环 / 打中的人身上光柱和红蓝两刀
				var mu: BUnit = e["unit"]
				var hp: Array = []
				for hu: BUnit in (e.get("hits", []) as Array):
					hp.append(_chest(hu))
				fx.magi_finale(Vector3(mu.pos.x, 0.0, mu.pos.y), float(e.get("radius", 3.0)), hp)
				if domains.has(mu.uid):
					fx.magi_domain_end(domains[mu.uid], true)
					domains.erase(mu.uid)
				fx.number(_chest(mu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.finale"), Color("#f2ddff"), 1.2)
				shake.emit(0.22)
			"aura_taunt":
				var at: BUnit = e["unit"]
				var asrc: BUnit = e.get("src") as BUnit
				if asrc != null and asrc.def.model == "ember_melancholy":
					# 忧郁之潮：每秒一道涟漪(施放者身上画一次)；被嘲讽的人"嘲讽"二字隔久一点才飘一次
					if _gate("tide:" + asrc.uid, 0.9):
						fx.melancholy_tide(Vector3(asrc.pos.x, 0.0, asrc.pos.y), 2.4, _ident_color(asrc, Color("#5a8aff")), Color("#c9a6ff"))
					if _gate("taunted:" + at.uid, 3.0):
						fx.number(_chest(at) + Vector3(0, 0.6, 0), Loc.t("fx.taunt"), Color("#a8c4ff"), 0.6)
				else:
					fx.number(_chest(at) + Vector3(0, 0.6, 0), Loc.t("fx.taunt"), Color("#c9a6ff"), 0.6)
			"outer_form":
				# 外神之貌：锁血——罩上虚空外壳
				var ou: BUnit = e["unit"]
				# 外神之貌(锁血)= 真实形态：她长到 1.7 倍、身体化成星空；脚下裂开虚空之池，池边钻出触手，头顶后方睁开一圈眼睛
				var ov: UnitView = _view(ou)
				if not astro_forms.has(ou.uid) and ov != null:
					ov.form_size = ASTRO_TRUE_SIZE
					ov.set_size(ou.size_mult() * ASTRO_TRUE_SIZE, true)
					ov.set_void(1.0, 0.5)
					var fnode := EldritchForm.create(ov, minf(battle.pipeline.passive_splash_radius(ou) * 0.72, 2.0), ov.body_height * ASTRO_TRUE_SIZE / maxf(0.01, ov.size_k))
					add_child(fnode)
					astro_forms[ou.uid] = {"unit": ou, "node": fnode}
					fx.outer_awaken(Vector3(ou.pos.x, 0.0, ou.pos.y))
					shake.emit(0.12)
				fx.number(_chest(ou) + Vector3(0, 0.8, 0), Loc.t("ui.fx.outer_form"), Color("#d7a8ff"), 1.0)
			"status_pulse":
				var pu: BUnit = e["unit"]
				if str(e.get("id", "")) == "outer_form":
					var prad: float = battle.pipeline.passive_splash_radius(pu)
					fx.outer_pulse(Vector3(pu.pos.x, 0, pu.pos.y), prad)
					# 真实形态：一条触手甩过去抽范围里的一个敌人(随机挑)
					if astro_forms.has(pu.uid) and is_instance_valid(astro_forms[pu.uid]["node"]):
						var inr: Array = []
						for en2: BUnit in battle.enemies_of(pu):
							if en2.pos.distance_to(pu.pos) - en2.radius <= prad:
								inr.append(en2)
						if not inr.is_empty():
							var lt: BUnit = inr[randi() % inr.size()]
							var lat: Vector3 = _chest(lt)
							var dly: float = (astro_forms[pu.uid]["node"] as EldritchForm).lash(lat)
							get_tree().create_timer(dly / maxf(0.2, speed)).timeout.connect(fx.tentacle_hit.bind(lat))
			"magazine":
				# 改修节点换弹：下一个弹匣是什么伤害
				var mu: BUnit = e["unit"]
				var mk: String = str(e.get("kind", "physical"))
				var mcol: Color = {"physical": Color("#ffb35a"), "magic": Color("#c39bff"), "true": Color("#ffffff")}.get(mk, Color.WHITE)
				fx.number(_chest(mu) + Vector3(0, 0.75, 0), Loc.t("ui.fx.mag_" + mk), mcol, 0.85)
				fx.burst(_chest(mu), mcol, 8, 1.6, 0.6, 0.6, 0.35)
			"bonus_shot":
				# 即时改装叠满后的连开两枪：一个紫色的全息准星 + 一下快速的开枪动作
				var bu2: BUnit = e["unit"]
				var bv2: UnitView = _view(bu2)
				if bv2 != null:
					bv2.play_attack(2.4 * speed)
				if int(e.get("index", 0)) == 0 and e.get("target") is BUnit:
					var bt2: BUnit = e["target"]
					var dir2 := Vector3(bt2.pos.x - bu2.pos.x, 0.0, bt2.pos.y - bu2.pos.y).normalized()
					fx.holo_reticle(_chest(bu2) + dir2 * 0.9, dir2)
			"held_release":
				# 完美时计：瞄着它的飞刀够了，一起放出去
				var hr: BUnit = e["target"]
				if hr != null:
					fx.knife_release(_chest(hr), Color("#ff3048"))
			"storm_start":
				# 清洁世界：原地转圈乱扔飞刀(双枪也一样转)；大招(ultimate)：切入立绘 + 时间停止——
				# 从她身上扩出去一道波前，世界褪成冷灰(她留色)，脚下一面大怀表的表针倒转后停住；转完时间恢复(负片一闪、回色)
				var su5: BUnit = e["unit"]
				var sv5: UnitView = _view(su5)
				if sv5 != null:
					sv5.play_once(str((sv5.look.get("overrides", {}) as Dictionary).get("storm", "")))
				fx.ring(Vector3(su5.pos.x, 0, su5.pos.y), 1.3, Color("#ff5a6a"), 0.5, 1.2, 0.3)
				if bool(e.get("ultimate", false)):
					var sdur: float = float(e.get("duration", 1.2)) / maxf(0.1, speed)
					ultimate.emit(su5, str(e.get("ability", "")), Color("#ff5a6a"))
					_time_stop(su5, sdur)
			"storm_throw":
				var su6: BUnit = e["unit"]
				fx.burst(_chest(su6), Color("#f2f4fa"), 6, 2.6, 0.5, 0.2, 0.2)
			"blink_throw":
				# 闪烁刀刃：瞬移后连扔的几把(第一把放一下扔飞刀的动作)
				if int(e.get("index", 0)) == 0:
					var bt: UnitView = _view(e["unit"])
					if bt != null:
						bt.play_attack(1.8 * speed)
			"blink":
				var bu: BUnit = e["unit"]
				var f: Vector2 = e["from"]
				if str(e.get("style", "")) == "clock":
					# 闪烁刀刃：怀表一停——原地留下残影和表盘，落点再亮一个表盘(没有中间的冲刺过程)
					var cv: UnitView = _view(bu)
					if cv != null:
						fx.afterimage(cv.model, Color("#ff8a96"), 0.45, 0.6)
						cv.position = Vector3(bu.pos.x, 0, bu.pos.y)
						cv.rotation.y = bu.facing
					fx.clock_face(Vector3(f.x, 0, f.y), Color("#ff3048"), 0.9, 0.6)
					fx.clock_face(Vector3(bu.pos.x, 0, bu.pos.y), Color("#ff3048"), 0.9, 0.6)
					fx.burst(Vector3(bu.pos.x, 0.7, bu.pos.y), Color("#ffe4e8"), 10, 2.4, 0.7, 0.6, 0.3)
					continue
				fx.burst(Vector3(f.x, 0.6, f.y), GC.faction_color(bu.def.faction_id), 12, 3.0, 1.0, 0.4)
				fx.ring(Vector3(bu.pos.x, 0, bu.pos.y), 1.1, GC.faction_color(bu.def.faction_id), 0.35)
				var bv: UnitView = _view(bu)
				if bv != null:
					bv.position = Vector3(bu.pos.x, 0, bu.pos.y)
			"throw_start":
				# 投掷(狩胜节点·必胜)：举起武器蓄力的动作(出手时刻 = 逻辑的前摇)
				var tsu: BUnit = e["unit"]
				var tsv: UnitView = _view(tsu)
				if tsv != null:
					tsv.play_skill("throw", float(e.get("windup", 0.34)) + 0.36)
				fx.number(_chest(tsu) + Vector3(0, 0.85, 0), Loc.t("ui.fx.quarry"), Color("#ff6a4a"), 0.8)
			"throw_release":
				# 武器离手：手里的藏起来，复制一份按手上的姿势飞出去
				var tru: BUnit = e["unit"]
				var trv: UnitView = _view(tru)
				if trv != null:
					var tnode: Node3D = trv.make_thrown_weapon()
					if tnode != null:
						add_child(tnode)
						var gp0: Vector3 = tnode.global_position
						thrown_views[int(e["id"])] = {"node": tnode, "spin": 0.0, "javelin": tru.weapon_class() == "polearm",
							"start": Vector2(tru.pos.x, tru.pos.y), "start_y": gp0.y, "scale": trv.model.scale.x, "unit": tru.uid, "wclass": tru.weapon_class()}
						fx.dress_thrown(tnode, tru.weapon_class(), GC.faction_color(tru.def.faction_id), _glory_k(tru))
					trv.set_weapon_hidden(true)
				fx.burst(_chest(tru) + Vector3(0, 0.3, 0), Color("#ffd8a0"), 6, 2.0, 0.7, 0.6, 0.25)
			"throw_hit":
				var thu: BUnit = e["unit"]
				var tht: BUnit = e.get("target") as BUnit
				var hp3: Vector2 = e["pos"]
				var at3: Vector3 = _chest(tht) if tht != null else Vector3(hp3.x, 0.3, hp3.y)
				var dir3 := Vector3(hp3.x - thu.pos.x, 0.0, hp3.y - thu.pos.y) if thu != null else Vector3.ZERO
				fx.throw_impact(at3, dir3, GC.faction_color(thu.def.faction_id) if thu != null else Color("#ff6a4a"), _glory_k(thu) if thu != null else 0.0)
				shake.emit(0.08)
				# 武器插在落点的地上，等她扑过来拿(weapon_return 时收掉)
				if thrown_views.has(int(e["id"])):
					thrown_views[int(e["id"])]["stuck"] = {"pos": Vector3(hp3.x, 0.0, hp3.y), "dir": dir3, "t": battle.time}
			"weapon_return":
				# 落地拿回武器：手上一闪
				var wru: BUnit = e["unit"]
				var wrv: UnitView = _view(wru)
				for tid0: int in thrown_views.keys():
					var tv0: Dictionary = thrown_views[tid0]
					if str(tv0.get("unit", "")) == wru.uid and tv0.has("stuck"):
						if is_instance_valid(tv0["node"]):
							(tv0["node"] as Node3D).queue_free()
						thrown_views.erase(tid0)
				if wrv != null:
					wrv.set_weapon_hidden(false)
					fx.burst(_chest(wru) + Vector3(0, 0.15, 0), Color("#ffe6a0"), 10, 2.2, 0.8, 0.8, 0.35)
			"hunt_target":
				# 新的狩猎对象：头顶插旗(同一队只有一个)
				var hteam: int = int(e["team"])
				var old_uid: String = str(quarry_uid.get(hteam, ""))
				var hu0: BUnit = e["unit"]
				if old_uid != "" and views.has(old_uid):
					(views[old_uid] as UnitView).set_quarry(false)
				quarry_uid[hteam] = hu0.uid
				var hv0: UnitView = _view(hu0)
				if hv0 != null:
					hv0.set_quarry(true)
			"glory_save":
				# 光荣 8 层：本应阵亡 → 失去一层、回复 25% 生命
				var gsu: BUnit = e["unit"]
				fx.pillar(Vector3(gsu.pos.x, 0, gsu.pos.y), Color("#ffd35a"), 0.8)
				fx.burst(_chest(gsu), Color("#ffe27a"), 22, 3.4, 1.2, 1.0, 0.7)
				fx.number(_chest(gsu) + Vector3(0, 0.9, 0), Loc.t("ui.fx.glory_save"), Color("#ffd35a"), 1.15)
				shake.emit(0.04)
			"shadow_step":
				# 逆光：原地沉进影子(漆黑的残影往下沉)，在敌人背后从影子里升起来
				var ssu: BUnit = e["unit"]
				var ssv: UnitView = _view(ssu)
				var sf: Vector2 = e["from"]
				var sto: Vector2 = e["to"]
				fx.shadow_sink(ssv.model if ssv != null else null, Vector3(sf.x, 0.0, sf.y))
				fx.shadow_dash(Vector3(sf.x, 0.0, sf.y), Vector3(sto.x, 0.0, sto.y))
				fx.shadow_pool(Vector3(sto.x, 0.0, sto.y), 1.3)
				if ssv != null:
					ssv.emerge(0.4)
					ssv.play_once("emerge_" + ssu.def.model)
				# 从影子里升起来的那一下：身后一团青白的逆光(他成了剪影)
				var sh_h: float = ssv.body_height if ssv != null else 1.3
				get_tree().create_timer(0.16 / maxf(0.2, speed)).timeout.connect(fx.backlight_flare.bind(Vector3(sto.x, 0.0, sto.y), sh_h))
				shake.emit(0.03)
			"self_cost":
				# 淬血：身上迸出一团暗红的血雾
				var scu: BUnit = e["unit"]
				fx.burst(_chest(scu), Color("#7a0f1c"), 8, 1.6, 0.6, 0.8, 0.4)
				var scv: UnitView = _view(scu)
				if scv != null:
					var bl: Array = WeaponFlame.BLADE.get(scu.weapon_class(), [18.0, 58.0])
					fx.temper_blood(_chest(scu), scv.bone_point("Bow", Vector3(-16.0, 44.0 + (float(bl[0]) + float(bl[1])) * 0.5, 3.0)))
				if _gate("temper:" + scu.uid, 0.8):
					fx.number(_chest(scu) + Vector3(0, 0.75, 0), Loc.t("ui.fx.temper"), Color("#ff6b6b"), 0.75)
			"shadow_slay":
				# 诛影：剑上缠起一圈青黑的影子(身上一团青色碎光)
				var slu: BUnit = e["unit"]
				fx.burst(_chest(slu) + Vector3(0, 0.1, 0), Fx.SHADOW_TEAL, 6 + 2 * int(e.get("stacks", 1)), 1.4, 0.45, 1.0, 0.4)
			"lunge_start":
				# 画上句点：近战武器 = 空翻过目标头顶、手里换成微冲扫射；远程武器 = 从目标身侧滑铲过去、手里换成匕首划一刀
				var lsu: BUnit = e["unit"]
				var lsv: UnitView = _view(lsu)
				var style: String = str(e.get("style", "flip"))
				var prop: String = "P_commando_smg" if style == "flip" else "P_commando_knife"
				if lsv != null:
					lsv.set_weapon_hidden(true)
					lsv.set_prop(prop, true)
					var ldist: float = (e["from"] as Vector2).distance_to(e["to"])
					lsv.play_lunge("lunge_commando_" + style, float(e["dur"]), 1.25 if style == "flip" else 0.0, ldist)
				lunges[lsu.uid] = {"prop": prop, "style": style, "target": e.get("target"), "next": battle.time + 0.12}
				var lf: Vector2 = e["from"]
				var lt2: Vector2 = e["to"]
				fx.lunge_dust(Vector3(lf.x, 0, lf.y), Vector3(lt2.x, 0, lt2.y))
				_leap_fx(lsu, lf, lt2, float(e["dur"]), GC.faction_color(lsu.def.faction_id), 0.0, 0.8 if style == "flip" else 0.6)
				if style == "slide":
					var ltg: BUnit = e.get("target") as BUnit
					if ltg != null:
						get_tree().create_timer(float(e["dur"]) * 0.45 / maxf(0.1, speed)).timeout.connect(_lunge_cut.bind(lsu, ltg))
			"lunge_end":
				var leu: BUnit = e["unit"]
				var let: BUnit = e.get("target") as BUnit
				if let != null and let.alive and _gate("mark:" + let.uid, 0.5):
					fx.number(_chest(let) + Vector3(0, 0.8, 0), Loc.t("ui.fx.mark"), Fx.MARK_COL, 0.8)
				if lunges.has(leu.uid):
					var lev: UnitView = _view(leu)
					if lev != null:
						lev.set_prop(str(lunges[leu.uid]["prop"]), false)
						lev.set_weapon_hidden(false)
					lunges.erase(leu.uid)
			"mark_volley":
				# 标定满 3 秒：远程友军身上一闪(免费的一发；弹道本身由 projectile 事件画)
				var msh: BUnit = e["shooter"]
				fx.soft_flash(_chest(msh) + Vector3(0, 0.3, 0), Fx.MARK_COL, 0.6, 0.2, 2.0)
			"mark_consumed":
				var mcu: BUnit = e["unit"]
				fx.burst(_chest(mcu), Fx.MARK_COL, 8, 2.0, 0.5, 0.8, 0.3)
			"cover":
				# 掩护支援：头上飘"掩护"，脚下一圈
				var cvu: BUnit = e["unit"]
				if _gate("cover:" + cvu.uid, 0.6):
					fx.number(_chest(cvu) + Vector3(0, 0.75, 0), Loc.t("ui.fx.cover"), Color("#ffe08a"), 0.8)
				fx.ring(Vector3(cvu.pos.x, 0.04, cvu.pos.y), 1.0, Color("#ffe08a"), 0.35, 1.2, 0.3)
			"status_reset":
				var sru: BUnit = e["unit"]
				if str(e.get("status", "")) == "focus_breath" and _gate("breath:" + sru.uid, 1.0):
					fx.number(_chest(sru) + Vector3(0, 0.7, 0), Loc.t("ui.fx.breath_reset"), Color("#c8d3e8"), 0.75)
			"cast_fx":
				# 被动技能的施法表现(清心节点：飞出一张符)
				var cfu: BUnit = e["unit"]
				var cft: BUnit = e.get("target") as BUnit
				var kind: String = str(e.get("kind", ""))
				if kind == "ink_blade" and cft != null:
					fx.ink_blade(_chest(cfu) + Vector3(0, 0.1, 0), _chest(cft))
				if kind == "dream_echo" and cft != null:
					fx.dream_echo(_chest(cfu) + Vector3(0, 0.2, 0), _chest(cft), cft.team == cfu.team)
				if kind == "lily_thrust" and cft != null:
					fx.lily_thrust(_chest(cfu) + Vector3(0, 0.1, 0), _chest(cft))
				if kind == "ricochet" and cft != null:
					# 一石二鸟：子弹从刚倒下的敌人身上弹到离它最近的敌人
					var rf: Vector2 = e.get("from", cfu.pos)
					fx.ricochet(Vector3(rf.x, _chest(cft).y, rf.y), _chest(cft))
					if _gate("ricochet:" + cfu.uid, 0.6):
						fx.number(Vector3(rf.x, 1.5, rf.y), Loc.t("ui.fx.double_bird"), Color("#ffd27a"), 0.9)
				if cft != null and kind.begins_with("talisman"):
					var heal_t: bool = kind == "talisman_heal"
					var from_t: Vector3 = _chest(cfu) + Vector3(0, 0.25, 0)
					var node_t: Node3D = fx.make_talisman(heal_t)
					add_child(node_t)
					node_t.position = from_t
					fx.talisman_cast(from_t, heal_t)
					# 弧线飞过去(按距离 0.3~0.6 秒，跟着目标)；这次施放带来的事件扣到落地再播
					var held_t: Array[Dictionary] = []
					var sp_t := {"node": node_t, "from": from_t, "target": cft, "t": 0.0, "arc": 0.8, "heal": heal_t, "held": held_t,
						"src": cfu, "flight": clampf(from_t.distance_to(_chest(cft)) / 7.0, 0.3, 0.6)}
					skill_projs.append(sp_t)
					_hold = sp_t
					var cv: UnitView = _view(cfu)
					if cv != null:
						cv.set_glow(0.8)
						create_tween().tween_method(cv.set_glow, 0.8, 0.0, 0.35)
			"missile":
				# 虹光飞弹：从杖尖升空，先往天上绕一段(每发方向不同)，再俯冲追着目标(落点跟着目标走)
				var msu: BUnit = e["unit"]
				var mst: BUnit = e.get("target") as BUnit
				var mkind: String = str(e.get("color", "white"))
				var mcol: Color = Fx.MISSILE_COL.get(mkind, Color.WHITE)
				var start_m: Vector3 = _chest(msu) + Vector3(0, 0.9, 0)
				var ang_m: float = randf() * TAU
				var mnode: Node3D = fx.make_missile(mcol, mkind)
				mnode.visible = false
				mnode.position = start_m
				add_child(mnode)
				missiles.append({"node": mnode, "start": start_m, "target": mst, "delay": float(e.get("delay", 0.0)), "flight": float(e.get("flight", 1.0)),
					"t": 0.0, "color": mcol, "kind": mkind, "launched": false,
					"p1": start_m + Vector3(cos(ang_m) * randf_range(0.8, 1.8), randf_range(2.0, 3.2), sin(ang_m) * randf_range(0.8, 1.8)),
					"off2": Vector3(randf_range(-1.2, 1.2), randf_range(2.2, 3.0), randf_range(-1.2, 1.2))})
			"familiar_marks":
				# 黑羽使魔：身边一圈小羽毛，飘"使魔 n/6"
				var fmu: BUnit = e["unit"]
				var nmk: int = (e.get("marks", []) as Array).size()
				fx.burst(_chest(fmu) + Vector3(0, 0.5, 0), Color("#5a6cff"), 3 + nmk, 1.4, 0.7, 1.2, 0.5, false)
				if _gate("familiar:" + fmu.uid, 0.4):
					fx.number(_chest(fmu) + Vector3(0.35, 0.9, 0), Loc.t("ui.fx.familiar") % str(nmk), Color("#9aa6ff"), 0.7)
			"rainbow_spark":
				# 虹光花：一点小火花(物理橙 / 法术紫 / 真实白)
				var rst: BUnit = e.get("target") as BUnit
				if rst != null:
					var rcol: Color = {"physical": Color("#ffb35a"), "magic": Color("#c39bff"), "true": Color("#ffffff")}.get(str(e.get("kind", "")), Color.WHITE)
					fx.burst(_chest(rst) + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.3), 0), rcol, 3, 1.6, 0.5, 0.6, 0.25)
			"fish_pull":
				# 意外渔获：起竿，把目标拽到面前
				var fpu: BUnit = e["unit"]
				var fpv: UnitView = _view(fpu)
				var fpt: BUnit = e.get("target") as BUnit
				var rec0: Dictionary = fishing.get(fpu.uid, {})
				if fpv != null:
					fpv.chant_anim = ""
					fpv.play_once(str(rec0.get("pull_anim", "")))
				if not rec0.is_empty():
					rec0["target"] = fpt
					rec0["pull_until"] = Time.get_ticks_msec() / 1000.0 + 0.6 / maxf(0.25, speed)
				if fpt != null:
					fx.burst(_chest(fpt), Color("#bfe6ff"), 14, 2.6, 0.8, 1.6, 0.5)
					fx.number(_chest(fpt) + Vector3(0, 0.9, 0), Loc.t("ui.fx.hooked"), Color("#9fe0ff"), 1.05)
				shake.emit(0.03)
			"hunter_notes":
				# 猎人笔记写完：身上一闪 + 飘"笔记 +X%"
				var hnu: BUnit = e["unit"]
				fx.burst(_chest(hnu) + Vector3(0, 0.3, 0), Color("#e8f4c8"), 10, 1.8, 0.7, 1.2, 0.5)
				fx.number(_chest(hnu) + Vector3(0, 0.95, 0), Loc.t("ui.fx.notes") % str(int(round(float(e.get("value", 0.0)) * 100.0))), Color("#cfe8a8"), 0.85)
			"dodge":
				# 闪开了一次普攻：一道残影 + "闪避"
				var dgu: BUnit = e["unit"]
				var dgv: UnitView = _view(dgu)
				if dgv != null:
					fx.afterimage(dgv.model, Color("#cfe8a8"), 0.28, 0.5)
				if _gate("dodge:" + dgu.uid, 0.35):
					fx.number(_chest(dgu) + Vector3(0.3, 0.7, 0), Loc.t("ui.fx.dodge"), Color("#cfe8a8"), 0.8)
			"instant_shot":
				# 易用短弓：不拉满，抬手就是一箭
				var isu: BUnit = e["unit"]
				var isv: UnitView = _view(isu)
				if isv != null:
					isv.play_release(str(isu.wclass().get("release_anim", "")), float(isu.wclass().get("windup", 0.0)))
			"status_burst":
				# 剑痕引爆(残光)：刀口一道道炸开
				if str(e.get("id", "")) == "sword_scar":
					var sbu: BUnit = e["unit"]
					var rec: Dictionary = scars.get(sbu.uid, {})
					var mk: Array = rec.get("marks", [])
					var lc: Dictionary = _last_cut.get(sbu.uid, {})
					fx.scar_burst(mk, lc["center"] if not lc.is_empty() else _chest(sbu), int(e.get("stacks", 0)))
					if not rec.is_empty():
						rec["marks"] = []
					if int(e.get("stacks", 0)) >= 10 and _gate("afterglow:" + sbu.uid, 0.3):
						fx.number(_chest(sbu) + Vector3(0, 1.0, 0), Loc.t("ui.fx.afterglow"), Color("#ffb04a"), 1.1)
					shake.emit(0.02 + 0.003 * float(int(e.get("stacks", 0))))
			"stack_heal":
				# 重燃：挨打时消耗层数回血
				var shu: BUnit = e["unit"]
				fx.rekindle_heal(_chest(shu), int(e.get("stacks", 0)))
				if _gate("rekindle_txt:" + shu.uid, 0.6):
					fx.number(_chest(shu) + Vector3(0, 0.95, 0), Loc.t("ui.fx.rekindle") % str(int(e.get("stacks", 0))), Color("#ffb04a"), 0.8)
			"miss":
				# 打空(开枪最快之人)：子弹从目标身边擦过，飘个"打空"
				var mu2: BUnit = e.get("target") as BUnit
				if mu2 != null:
					var mp: Vector3 = _chest(mu2)
					fx.burst(mp + Vector3(0.45, -0.3, 0.0), Color("#d8d2c8"), 4, 1.4, 0.6, 0.6, 0.3, false)
					if _gate("miss:" + mu2.uid, 0.45):
						fx.number(mp + Vector3(0.3, 0.55, 0), Loc.t("ui.fx.miss"), Color("#c8ccd6"), 0.7)
			"empower_shot":
				# 大口径子弹：每一发枪口一团金色的火光
				var esu: BUnit = e["unit"]
				var ev2: UnitView = _view(esu)
				var fwd := Vector3(sin(esu.facing), 0.0, cos(esu.facing))
				fx.burst(_chest(esu) + fwd * 0.55, Color("#ffd35a"), 6, 2.0, 0.8, 0.4, 0.22)
				if int(e.get("left", 0)) == int(e.get("count", 6)) - 1 and ev2 != null:
					fx.number(_chest(esu) + Vector3(0, 0.8, 0), Loc.t("status.big_caliber"), Color("#ffd35a"), 0.85)
			"orb_made":
				# 打工小帮手做出一个晶球：身上一闪，晶球颜色的光点往上冒
				var omu: BUnit = e["unit"]
				var otier: String = str(e.get("tier", "white"))
				var ocol: Color = OrbView.COLORS.get(otier, OrbView.COLORS["white"])
				var op: Vector2 = e["pos"]
				fx.burst(Vector3(op.x, 0.6, op.y), ocol, 12, 2.2, 0.9, 1.4, 0.6)
				fx.ring(Vector3(op.x, 0.0, op.y), 0.6, OrbView.MARK_COLORS.get(otier, OrbView.MARK_COLORS["white"]), 0.5, 1.4, 0.2)
				fx.number(_chest(omu) + Vector3(0, 0.9, 0), Loc.t("ui.orb." + otier), ocol.darkened(0.15) if otier == "white" else ocol, 0.85)
			"immune":
				var imu: BUnit = e["unit"]
				if _gate("immune:" + imu.uid, 0.8):
					fx.number(_chest(imu) + Vector3(0, 0.7, 0), Loc.t("ui.fx.immune"), Color("#fff3c0"), 0.8)
			"dash_start":
				# 冲锋：扑出去的动作 + 一路残影 + 地上的拖痕(投掷后的飞扑：腾空扑过去)
				var du: BUnit = e["unit"]
				var dv: UnitView = _view(du)
				var dcol: Color = GC.faction_color(du.def.faction_id)
				if dv != null and bool(e.get("pulled", false)):
					dv.play_leap(float(e["dur"]), 0.7)               # 被鱼线拽飞过来
				elif dv != null and bool(e.get("leap", false)):
					# 投掷后的飞扑：蓄力蹲一下 → 蹬地扑出去(尘土、碎块、残影)→ 砸到武器旁边(尘土冲击波、地坑、火：光荣越多火越大)
					var lf0: Vector2 = e["from"]
					var lt0: Vector2 = e["to"]
					var ld: float = lf0.distance_to(lt0)
					dv.play_leap(float(e["dur"]), clampf(0.35 + ld * 0.12, 0.5, 1.3), ld)
					_leap_fx(du, lf0, lt0, float(e["dur"]), dcol, _glory_k(du))
				elif dv != null:
					dv.play_skill("dash", float(e["dur"]))
					dashing[du.uid] = {"until": Time.get_ticks_msec() / 1000.0 + float(e["dur"]) / maxf(0.1, speed), "next": 0.0, "color": dcol}
				var df: Vector2 = e["from"]
				var dt2: Vector2 = e["to"]
				fx.streak(Vector3(df.x, 0, df.y), Vector3(dt2.x, 0, dt2.y), dcol.darkened(0.2))
			"dash_strike":
				# 落地旋斩：转一圈的动作 + 斩击光环 + 尘土；震一下
				var su2: BUnit = e["unit"]
				var sv2: UnitView = _view(su2)
				dashing.erase(su2.uid)
				if sv2 != null:
					sv2.play_skill("spin")
				fx.spin_slash(Vector3(su2.pos.x, 0, su2.pos.y), float(e["radius"]), GC.faction_color(su2.def.faction_id).lightened(0.3))
				shake.emit(0.045 if int(e.get("hits", 0)) > 0 else 0.02)
			"skill_projectile":
				var su4: BUnit = e["unit"]
				var node4: Node3D = fx.make_projectile(str(e.get("kind", "light_arrow")), false, GC.faction_color(su4.def.faction_id))
				add_child(node4)
				var from4: Vector3 = _chest(su4) + Vector3(0, 0.2, 0)
				node4.position = from4
				skill_projs.append({"node": node4, "from": from4, "target": e["target"], "t": 0.0, "flight": float(e["flight"])})
			"summon_star":
				# 共享召唤：又一位舞星节点把星级加给了护星节点
				var su3: BUnit = e["unit"]
				var sv3: UnitView = _view(su3)
				if sv3 != null:
					sv3.set_star(int(e["star"]))
				fx.pillar(Vector3(su3.pos.x, 0, su3.pos.y), Color("#ffd875"), 0.6)
				fx.number(_chest(su3) + Vector3(0, 0.8, 0), Loc.t("ui.fx.summon_star") % str(e["star"]), Color("#ffd875"), 1.0)
			"escort_end":
				# 舞与歌：冲到台前，护星节点亮一下(减伤)，接着就是嘲讽(taunt 事件自己画)
				var eu: BUnit = e["unit"]
				var ep: BUnit = e.get("partner") as BUnit
				fx.burst(_chest(eu) + Vector3(0, 0.3, 0), Color("#ffd875"), 14, 2.6, 1.0, 0.8, 0.6)
				if ep != null:
					fx.ring(Vector3(ep.pos.x, 0, ep.pos.y), 1.2, Color("#9adcff"), 0.5, 1.6, 0.2)
			"meteor_na":
				# 灾星节点的普攻：一颗(双手长时两颗)小火流星从天上砸向目标
				var mu: BUnit = e["unit"]
				var mcol := Color("#ff7a2a")
				var mt: BUnit = e["target"]
				fx.meteor(Vector3(mt.pos.x, _chest(mt).y * 0.6, mt.pos.y), float(e["fall"]), mcol, 1.0, 0.6)
				for ex2: Variant in e.get("extra", []):
					var xb: BUnit = ex2 as BUnit
					if xb != null and xb.alive:
						fx.meteor(Vector3(xb.pos.x, _chest(xb).y * 0.6, xb.pos.y), float(e["fall"]), mcol, 1.0, 0.6)
			"meteor_cast":
				# 流星爆魔杖：每个触发目标头上一颗大流星，地上是落点预警；有 delays 时一颗接一颗(第 i 颗晚 delays[i] 秒才开始落)
				var mpts: Array = e.get("points", [])
				var mdl: Array = e.get("delays", [])
				var mrad: float = clampf(float(e.get("radius", 1.1)) * 0.6, 0.8, 1.6)
				for mi: int in range(mpts.size()):
					var pv: Vector2 = mpts[mi]
					var md: float = float(mdl[mi]) if mi < mdl.size() else 0.0
					if md <= 0.001:
						fx.meteor(Vector3(pv.x, 0.4, pv.y), float(e["fall"]), Color("#ff4a26"), 2.0, mrad)
					else:
						get_tree().create_timer(md / maxf(0.1, speed)).timeout.connect(fx.meteor.bind(Vector3(pv.x, 0.4, pv.y), float(e["fall"]), Color("#ff4a26"), 2.0, mrad))
					get_tree().create_timer((md + float(e["fall"])) / maxf(0.1, speed)).timeout.connect(shake.emit.bind(0.05))
			"uses_reset":
				var ru2: BUnit = e["unit"]
				fx.number(_chest(ru2) + Vector3(0, 0.8, 0), Loc.t("ui.fx.uses_reset"), Color("#ff6a5a"), 0.95)
				fx.pillar(Vector3(ru2.pos.x, 0, ru2.pos.y), Color("#ff5a4a"), 0.45)
			"taunt":
				var tu: BUnit = e["unit"]
				fx.ring(Vector3(tu.pos.x, 0, tu.pos.y), maxf(1.8, float(e.get("radius", 2.0))), Color("#ff6a5a"), 0.55)
				fx.number(_chest(tu) + Vector3(0, 0.7, 0), Loc.t("fx.taunt"), Color("#ff8a7a"), 0.85)
			"chant_start":
				var cu: BUnit = e["unit"]
				var cv: UnitView = _view(cu)
				if cv != null:
					cv.set_glow(1.0)
					# 吟唱换成专门的动作 + 道具(追猎节点：意外渔获解锁后 = 钓鱼)
					var cfx: Dictionary = _chant_fx(cu, str(e.get("ability", "")))
					if not cfx.is_empty() and cu.star >= int(cfx.get("min_star", 1)):
						cv.chant_anim = str(cfx.get("anim", ""))
						# 同一个动作可以按手里的武器大类细分(心音节点拿法器唱歌 = sing_bard_focus)
						if cv.ap.has_animation(cv.chant_anim + "_" + cu.weapon_class()):
							cv.chant_anim += "_" + cu.weapon_class()
						if cfx.has("prop") and bool(cfx.get("keep_prop", false)):
							cv.set_prop(str(cfx["prop"]), true)
							keep_props[cu.uid] = str(cfx["prop"])
						elif cfx.has("prop"):
							cv.set_prop(str(cfx.get("prop", "")), true)
							fishing[cu.uid] = {"unit": cu, "target": e.get("target"), "prop": str(cfx.get("prop", "")),
								"pull_anim": str(cfx.get("pull_anim", "")), "pull_until": -1.0}
							fx.burst(_chest(cu) + Vector3(0, 0.4, 0), Color("#cfe8a8"), 6, 1.4, 0.6, 1.0, 0.4)
						# 少女幻葬：张开灵魂领域
						if bool(cfx.get("soul_domain", false)) and not soul_domains.has(cu.uid):
							soul_domains[cu.uid] = {"node": fx.soul_domain(Vector3(cu.pos.x, 0.0, cu.pos.y), battle.pipeline.passive_splash_radius(cu)),
								"unit": cu, "t0": battle.time, "d0": battle.death_times.size()}
						# 少女幻嘘：张开文字领域
						if bool(cfx.get("glyph_domain", false)) and not glyph_domains.has(cu.uid):
							glyph_domains[cu.uid] = fx.glyph_domain(Vector3(cu.pos.x, 0.0, cu.pos.y), battle.pipeline.passive_splash_radius(cu))
						# 少女幻终：张开黑白领域(半径 = 溅射范围)
						if bool(cfx.get("domain", false)) and not domains.has(cu.uid):
							domains[cu.uid] = fx.magi_domain(Vector3(cu.pos.x, 0.0, cu.pos.y), battle.pipeline.passive_splash_radius(cu))
						# 大招(充能 9 的终结技)：升到空中、脚下一道光柱冲起来、镜头一震，HUD 切入一条立绘 + 技能名的横幅
						if cfx.has("float"):
							cv.lev_target = float(cfx["float"])
						if bool(cfx.get("ultimate", false)):
							var uc: Color = Color(str(cfx.get("ult_color", "#d7b8ff")))
							fx.ultimate_rise(Vector3(cu.pos.x, 0.0, cu.pos.y), uc, cv.body_height)
							shake.emit(0.14)
							ultimate.emit(cu, str(e.get("ability", "")), uc)
						# 再绽之花(正行节点)：花瓣绕着她转
						if bool(cfx.get("petals", false)):
							if petal_swirls.has(cu.uid):
								fx.petal_swirl_end(petal_swirls[cu.uid], false)
							petal_swirls[cu.uid] = fx.petal_swirl(Vector3(cu.pos.x, 0.0, cu.pos.y), cv.body_height)
						# 脚下的魔法阵(巫术节点)
						if cfx.has("circle"):
							if circles.has(cu.uid):
								fx.magic_circle_end(circles[cu.uid], false)
							circles[cu.uid] = fx.magic_circle(Vector3(cu.pos.x, 0.0, cu.pos.y), Color(str(cfx["circle"])))
				# 吟唱的通用光圈(演奏不画：五线谱连线就是它的吟唱表现)
				var cfx2: Dictionary = _chant_fx(cu, str(e.get("ability", "")))
				if not bool(cfx2.get("perform", false)) and not bool(cfx2.get("no_ring", false)):
					fx.ring(Vector3(cu.pos.x, 0, cu.pos.y), 1.6, Color("#9a8cff"), float(e["duration"]) * 0.9, 1.6, 0.3)
			"chant_release":
				var ru: BUnit = e["unit"]
				var rv: UnitView = _view(ru)
				if rv != null:
					rv.set_glow(0.0)
				# 钓鱼没钓成(被打断)：收竿
				if fishing.has(ru.uid) and not bool(e.get("complete", false)):
					_end_fishing(ru.uid)
				# 一直拿着的道具(鲁特琴)：完整结束就接着下一段，被打断才收
				if keep_props.has(ru.uid) and not bool(e.get("complete", false)):
					_end_keep_prop(ru.uid)
				if petal_swirls.has(ru.uid):
					fx.petal_swirl_end(petal_swirls[ru.uid], bool(e.get("complete", false)))
					petal_swirls.erase(ru.uid)
				# 魔法阵：施放时一闪收掉；施放动作(一挥法杖)
				if circles.has(ru.uid):
					fx.magic_circle_end(circles[ru.uid], true)
					circles.erase(ru.uid)
				var rcfx: Dictionary = _chant_fx(ru, str(e.get("ability", "")))
				if rv != null and rcfx.has("cast_anim"):
					rv.play_once(str(rcfx["cast_anim"]))
				# 血嗜节点：吟唱结束 = 准备扔血球(什么时候扔看 throw_cast 的落地时刻)；不再从敌人身上抽血
				if blood_orbs.has(ru.uid):
					blood_orbs[ru.uid]["released"] = battle.time
			"interrupt":
				var iu: BUnit = e["unit"]
				var iv: UnitView = _view(iu)
				if iv != null:
					iv.set_glow(0.0)
				if fishing.has(iu.uid):
					_end_fishing(iu.uid)
				if keep_props.has(iu.uid):
					_end_keep_prop(iu.uid)
				if circles.has(iu.uid):
					fx.magic_circle_end(circles[iu.uid], false)
					circles.erase(iu.uid)
				if petal_swirls.has(iu.uid):
					fx.petal_swirl_end(petal_swirls[iu.uid], false)
					petal_swirls.erase(iu.uid)
				# 血嗜节点的吟唱被打断：头顶的血球破掉、血洒一地
				if blood_orbs.has(iu.uid) and bool(blood_orbs[iu.uid].get("chant", false)) and not blood_orbs[iu.uid].has("released"):
					fx.blood_orb_pop(blood_orbs[iu.uid]["node"])
					blood_orbs.erase(iu.uid)
				_drop_charge(iu, false)
			"splash":
				var sp: Vector2 = e["pos"]
				var srad: float = float(e["radius"])
				var ssrc: BUnit = e.get("src") as BUnit
				var stg0: BUnit = e.get("target") as BUnit
				if bool(e.get("heal_ally", false)):
					# 打在队友身上、被广义治疗转成治疗的溅射(护理节点)：粉色波纹 + 爱心，不炸；爱心针剂再大一号
					fx.care_splash(Vector3(sp.x, _chest(stg0).y * 0.8 if stg0 != null else 0.4, sp.y), srad, str(e.get("style", "")) == "heart")
				elif str(e.get("style", "")) == "light":
					pass                                     # 灭罪节点的光束：溅射范围就是光束脚下的光环，不另外画爆炸
				elif str(e.get("style", "")) == "banner":
					# 赤焰战旗：火色波纹(范围) + 火星
					fx.banner_splash(Vector3(sp.x, _chest(stg0).y * 0.8 if stg0 != null else 0.4, sp.y), srad)
				elif str(e.get("style", "")) == "greed":
					# 金焰(贪婪的余烬)：紫色的爆炸 + 金色碎光
					fx.greed_burst(Vector3(sp.x, _chest(stg0).y * 0.85 if stg0 != null else 0.3, sp.y), srad)
					if ssrc != null and _gate("greed:" + ssrc.uid, 0.5):
						fx.number(_chest(ssrc) + Vector3(0, 0.7, 0), Loc.t("ui.fx.greed"), Color("#e2b8ff"), 0.8)
				elif str(e.get("style", "")) == "heart":
					# 爱心针剂打在敌人身上：粉红色的爆炸 + 崩出来的爱心
					fx.heart_burst(Vector3(sp.x, _chest(stg0).y * 0.85 if stg0 != null else 0.3, sp.y), srad)
				elif str(e.get("effect", "")) == "heal" or str(e.get("effect", "")) == "shield":
					# 治疗/护盾的溅射：柔和的一圈，不炸
					fx.ring(Vector3(sp.x, 0, sp.y), srad, Fx.COLORS["heal"] if str(e.get("effect", "")) == "heal" else Fx.COLORS["shield"], 0.45)
				elif ssrc != null and ssrc.def.model.begins_with("pianist"):
					# 变奏节点的音符落地：一声和弦(颜色的环 + 崩出来的小音符 + 黑 / 白琴键的碎片)
					fx.chord_burst(Vector3(sp.x, _chest(stg0).y * 0.85 if stg0 != null else 0.4, sp.y), srad, ssrc.def.form == "angel")
				elif ssrc != null and not ssrc.chain_cfg().is_empty():
					# 导向节点(引雷)的每一跳都带法器的溅射：雷电炸开，电弧窜到溅射半径、跳到每个被溅到的人身上
					var tgt0: BUnit = e.get("target") as BUnit
					var tc: Vector3 = Vector3(sp.x, _chest(tgt0).y * 0.85 if tgt0 != null else 0.4, sp.y)
					var shits: Array = []
					for ou: BUnit in battle.units:
						if ou.alive and ou != tgt0 and ou.pos.distance_to(sp) <= srad + ou.radius and not (ou.team == ssrc.team and ssrc.has_flag("enemies_only")):
							shits.append(_chest(ou))
					fx.thunder_splash(tc, srad, shits)
				elif ssrc != null and ssrc.def.model.begins_with("ember_"):
					# 余烬的溅射(暴食的赤油……)：熔岩炸开，颜色 = 那一种火。同一次喷发会对每个溅到的人各发一个溅射事件，只画一次
					var lt: BUnit = e.get("target") as BUnit
					if _gate("lava:" + ssrc.uid, 0.2):
						fx.lava_splash(Vector3(sp.x, _chest(lt).y * 0.7 if lt != null else 0.3, sp.y), srad, _ident_color(ssrc, Color("#ff5a1a")))
				else:
					# 伤害溅射：爆炸(颜色跟施放者的法球一致；命中单位时爆心在对方胸口偏下，打地板时贴地)
					var sc: Color = GC.faction_color(ssrc.def.faction_id) if ssrc != null else Fx.COLORS["magic"]
					if ssrc != null and ssrc.def.sky_caster:
						# 灾星节点的流星：爆炸由流星自己落地时画(Fx.meteor_impact)，这里只补一圈溅射范围的火色冲击环
						fx.ring(Vector3(sp.x, 0.05, sp.y), srad, Color("#ff7a2a"), 0.4, 1.6, 0.2)
					else:
						var stgt: BUnit = e.get("target") as BUnit
						var hy: float = _chest(stgt).y * 0.85 if stgt != null else 0.3
						fx.explosion(Vector3(sp.x, hy, sp.y), srad, sc, clampf(srad / 1.2, 0.85, 1.6))
			"dispel":
				# 净化(驱散友军的负面状态，如一对一看护)：白金色的光点从身上散开 + "净化"
				var du0: BUnit = e["unit"]
				if str(e.get("what", "")) == "debuff" and du0 != null:
					fx.burst(_chest(du0), Color("#fff6d8"), 10, 2.0, 0.8, 1.2, 0.5)
					fx.float_icons(_chest(du0), fx.cross_mesh(), Color("#fff3c0"), 3, 0.3, 0.7, 0.8)
					if _gate("cleanse:" + du0.uid, 0.8):
						fx.number(_chest(du0) + Vector3(0, 0.75, 0), Loc.t("ui.fx.cleanse"), Color("#fff3c0"), 0.8)
			"awakened":
				var au: BUnit = e["unit"]
				# 黑剑的誓约觉醒：暗色 = 暗红的光柱，光色 = 白金的光柱
				var acol := Color("#ffd875")
				if str(e.get("status", "")) == "dark_oath":
					acol = Color("#d8203a")
				elif str(e.get("status", "")) == "light_oath":
					acol = Color("#fff3c8")
				fx.pillar(Vector3(au.pos.x, 0, au.pos.y), acol)
				fx.number(_chest(au) + Vector3(0, 0.8, 0), Loc.t("fx.awakened"), acol, 1.1)
				feed.emit({"kind": "awakened", "unit": au})
			"vendetta":
				# 誓血仇：盯上了凶手——自己头上飘"血仇"，凶手脚下一圈暗红
				var vu: BUnit = e["unit"]
				var vt: BUnit = e["target"]
				fx.number(_chest(vu) + Vector3(0, 0.9, 0), Loc.t("ui.fx.vendetta"), Color("#e8303a"), 0.9)
				if vt != null:
					fx.ring(Vector3(vt.pos.x, 0, vt.pos.y), 1.1, Color("#c8102a"), 0.7, 1.4)
					fx.streak(_chest(vu), _chest(vt), Color("#c8102a"), 0.25, 0.5)
			"max_hp_up":
				var mu: BUnit = e["unit"]
				if float(e.get("amount", 0.0)) >= 1.0:
					fx.number(_chest(mu) + Vector3(0, 0.5, 0), "+%d" % int(round(float(e["amount"]))), Fx.COLORS.get("heal", Color("#7cff9a")), 0.9)
					fx.ring(Vector3(mu.pos.x, 0, mu.pos.y), 0.9, Color("#ff5a6a"), 0.45)
			"oath_save":
				# 光色誓约：即将阵亡时回满
				var ou: BUnit = e["unit"]
				fx.pillar(Vector3(ou.pos.x, 0, ou.pos.y), Color("#fff3c8"))
				fx.burst(_chest(ou), Color("#fff3c8"), 22, 2.6, 1.2, 1.0, 0.8)
				fx.number(_chest(ou) + Vector3(0, 1.0, 0), Loc.t("ui.fx.oath_save"), Color("#fff3c8"), 1.2)
			"oath_bind":
				var bu3: BUnit = e["unit"]
				var bs: BUnit = e["summoner"]
				fx.number(_chest(bu3) + Vector3(0, 0.9, 0), Loc.t("ui.fx.oath_bind"), Color("#ffd875"), 1.0)
				if bs != null:
					fx.streak(_chest(bs), _chest(bu3), Color("#ffd875"), 0.3, 0.8)
			"oath_redirect":
				# 召唤者挨的普攻转到守誓节点身上：一道细光从召唤者连过来
				var ru: BUnit = e["unit"]
				var rf: BUnit = e["from"]
				if rf != null and _gate("oathr:" + ru.uid, 0.4):
					fx.streak(_chest(rf), _chest(ru), Color("#ffd875"), 0.12, 0.3)
			"gold":
				var gu: BUnit = e.get("unit")
				if gu != null and int(e["amount"]) > 0 and int(e["team"]) == GC.TEAM_PLAYER:
					fx.number(_chest(gu) + Vector3(0, 0.6, 0), "+%d" % int(e["amount"]), Fx.COLORS["gold"], 0.95)
			"growth":
				var gru: BUnit = e["unit"]
				fx.number(_chest(gru) + Vector3(0, 0.5, 0), "+%d %s" % [int(round(float(e["amount"]))), Loc.t("stat." + str(e["stat"]))], Color("#8dffb0"), 0.8, 0.9, 1.1)
			"self_cost":
				var su: BUnit = e["unit"]
				fx.number(_chest(su), "-%d" % int(round(float(e["amount"]))), Color("#ff6a6a"), 0.8)
			"battle_go":
				banner.emit("ui.battle_go")
				# 开打：带 phantom_fx 的棋子身后出现光之虚影(从光里浮现)
				for pu0: BUnit in battle.units:
					if pu0.alive and not pu0.def.phantom_fx.is_empty():
						_spawn_phantom(pu0)
			"battle_end":
				for bsk: String in beast_spirits.keys():
					if is_instance_valid(beast_spirits[bsk]):
						(beast_spirits[bsk] as BeastSpirit).roar()
				for pk: String in phantoms.keys():
					if is_instance_valid(phantoms[pk]):
						(phantoms[pk] as KnightPhantom).vanish()
				phantoms.clear()
				for uid: String in views.keys():
					var wv: UnitView = views[uid]
					if wv.bu != null and wv.bu.alive and wv.bu.team == int(e["winner"]):
						wv.win_pose()


func _on_release(e: Dictionary) -> void:
	var u: BUnit = e["unit"]
	var t: BUnit = e["target"]
	var wc: Dictionary = GC.weapon_class(str(e.get("weapon_class", "")))
	if u.weapon_class() == str(e.get("weapon_class", "")):
		wc = u.wclass()                          # 单位自己改过的(清扫节点的双持近战 = 扔飞刀，不画近战刀光)
	var at: Vector2 = t.pos if t != null else (e["aim"] as Vector2 if e.get("aim") is Vector2 else u.pos + Vector2(sin(u.facing), cos(u.facing)))
	var dir := Vector3(at.x - u.pos.x, 0.0, at.y - u.pos.y).normalized()
	# 蓝之章的机械：炮台 / 载具的炮口火光(左右炮管轮流)，中继的掌心一闪
	if MECH.has(u.def.model):
		var mv: UnitView = _view(u)
		var mk: Dictionary = MECH[u.def.model]
		var mc := Color(str(mk["col"]))
		if mv != null and mk.has("muzzles"):
			var mi: int = int(_muzzle_n.get(u.uid, 0))
			_muzzle_n[u.uid] = mi + 1
			var mz: Array = mk["muzzles"]
			fx.mech_muzzle(mv.bone_point("Chest", mz[mi % mz.size()]), dir, mc, 1.3 if bool(mk["big"]) else 1.0)
		elif mv != null and u.is_ranged():
			fx.soft_flash(mv.bone_origin("Hand_R"), mc, 0.6, 0.15, 2.4)
	if bool(e.get("drawn", false)):
		# 拉弓出手：放专门的放箭动画(拉得越满放得越猛)，蓄力光点炸开
		var v0: UnitView = _view(u)
		if v0 != null:
			v0.play_release(str(wc.get("release_anim", "")), float(wc.get("windup", 0.0)))
		_drop_charge(u, true)
		# 瞄准眉心：瞄过的一枪画一道金色弹道光(倍率越高越粗)，大的一枪震一下屏幕
		if u.aim_passive() != null and t != null:
			_end_snipe_aim(u.uid)
			var sc: float = float(e.get("chant_scale", 1.0))
			var mz: Vector3 = v0.bone_point("Bow", SNIPER_MUZZLE) if v0 != null and u.weapon_class() == "rifle" else _chest(u) + dir * 0.5
			fx.sniper_shot(mz, _chest(t), clampf((sc - 1.0) / 3.0, 0.0, 1.0))
			if sc >= 3.0:
				shake.emit(0.05)
	if t == null:
		return
	if u.def.projectile == "beam":
		# 嫉妒的余烬：射线一直连着(每次出手续 0.7 秒)，命中点一小撮火星
		var bd: Dictionary = beams.get(u.uid, {})
		if bd.is_empty() or not is_instance_valid(bd["node"]):
			bd = {"node": fx.envy_beam()}
		bd["until"] = battle.time + 0.7
		bd["target"] = t
		beams[u.uid] = bd
		fx.beam_set(bd["node"], _envy_eye(u), _chest(t), 1.0)
		fx.beam_hit(_chest(t))
		return
	if not bool(wc.get("ranged", false)):
		var cls: String = str(e.get("weapon_class", ""))
		var c: Color = GC.faction_color(u.def.faction_id).lightened(0.55)
		var big: float = 1.35 if cls == "heavy" else (0.8 if cls == "dual" else 1.0)
		if u.def.hit_fx == "iaido":
			# 拔刀术：刀口形的斩光沿着这一刀的挥动平面绕着目标切过去；记下来给这一刀留的剑痕用
			var cut: Dictionary = _iaido_geom(u, t)
			_last_cut[t.uid] = cut
			fx.iaido_cut(cut["center"], cut["toward"], cut["normal"], float(cut["sweep"]), float(cut["radius"]) * 1.2)
		else:
			fx.slash(_chest(t) + dir * -0.25, dir, c, big)
		# 顿帧：攻击者的动作在命中这一下卡住；重武器再震一下屏幕
		var va: UnitView = _view(u)
		if va != null and not e.has("copy"):
			var multi: bool = u.attack_variant == "multi"
			# 拔刀术：第一刀只顿一下下 —— 后面的连斩按 0.08 秒的节奏出手，顿久了动作就跟不上命中
			var hs: float = 0.015 if u.def.hit_fx == "iaido" else (0.07 if multi else float(HITSTOP.get(cls, 0.04)))
			va.hitstop(hs / maxf(1.0, speed))
		if cls == "heavy":
			shake.emit(0.05 if u.attack_variant != "multi" else 0.035)
	elif bool(wc.get("ranged", false)) and u.weapon != null and ProjRegistry.has(u.weapon.projectile):
		# 通用武器分批文件的投射物：出手的小特效由它自己画(不画枪口火光)
		var vr7: UnitView = _view(u)
		var hand7: Vector3 = vr7.bone_origin("Hand_L" if e.has("copy") else "Hand_R") if vr7 != null else _chest(u)
		ProjRegistry.release(fx, u.weapon.projectile, hand7 + dir * 0.2, dir)
	elif str(wc.get("projectile", "")) == "bullet":
		var own_proj: String = u.weapon.projectile if u.weapon != null else ""
		if own_proj != "" and own_proj != "bullet":
			# 不射子弹的手枪(刃轮 / 纸牌 / 泡泡 / 声波环)：不画枪口火光，在出手的那只手上放它自己的出手小特效
			var vr: UnitView = _view(u)
			var hand: Vector3 = vr.bone_origin("Hand_L" if e.has("copy") else "Hand_R") if vr != null else _chest(u)
			fx.pistol_release(own_proj, hand + dir * 0.2, dir)
		else:
			# 枪口火光
			fx.burst(_chest(u) + dir * 0.55 + Vector3(0, 0.05, 0), Color("#ffd98a"), 5, 1.6, 0.6, 0.2, 0.18)
	elif str(e.get("weapon_class", "")) == "focus":
		var v: UnitView = _view(u)
		if v != null:
			v.set_glow(1.0)
			create_tween().tween_method(v.set_glow, 1.0, 0.0, 0.35)


## 追击副本 = 又一次真的普攻：远程副本自己会发射投射物(投射物由 projectile 事件画)，这里只补出手的火光/刀光
func _on_copy(e: Dictionary) -> void:
	var u: BUnit = e["unit"]
	_on_release({"unit": u, "target": e["target"], "weapon_class": e.get("weapon_class", ""), "aim": e.get("aim"), "copy": true})
	if not bool(e.get("own", false)) and u.def.hit_fx != "iaido":      # 拔刀连斩的追击是同一轮里的几刀，不飘"追击"
		fx.number(_chest(u) + Vector3(0, 0.6, 0), Loc.t("fx.pursuit"), Color("#ffe6a0"), 0.7)


## 收掉拉弓的蓄力光点：flash = 放箭(炸一下)，否则(被打断)直接消失
func _drop_charge(u: BUnit, flash: bool) -> void:
	var n: Node3D = charges.get(u.uid, null)
	charges.erase(u.uid)
	if n != null and is_instance_valid(n):
		fx.release_charge(n, GC.faction_color(u.def.faction_id).lightened(0.45), flash)


func _on_damage(e: Dictionary) -> void:
	var dst: BUnit = e["dst"]
	var src: BUnit = e.get("src") as BUnit
	var kind: String = str(e["kind"])
	var amount: float = float(e["amount"])
	var crit: bool = bool(e["crit"])
	var surface0: String = str(e.get("surface", ""))
	if surface0 == "status":
		# 诛影·蚀(踏影节点)：每一跳身上冒一小团青黑的影子
		if str(e.get("ability", "")).begins_with("shadow_rot") and _gate("srot:" + dst.uid, 0.45):
			fx.shadow_rot_tick(_chest(dst))
		# 持续伤害(燃烧等)：跳得很频繁，只飘小字、不让单位每跳一下都抖
		if amount >= 1.0 and _gate("dot:" + dst.uid, 0.9):
			fx.number(_chest(dst) + Vector3(0.25, 0.1, 0), "%d" % int(round(amount)), Color("#ff9a4a"), 0.6)
		return
	fx.damage_number(_chest(dst) + Vector3(0, 0.3, 0), amount, kind, crit, bool(e.get("splash", false)))
	# 温柔地(共歌节点)期间：伤害被泡泡接住了一半——命中处炸开一小圈泡泡
	if amount > 0.5 and not gentle_fx.is_empty() and battle.gentle_factor() > 0.0 and _gate("gentle_pop:" + dst.uid, 0.35):
		fx.bubble_pop(_chest(dst))
	var v: UnitView = _view(dst)
	# 拔刀术(一轮 3~5 刀 + 剑痕引爆时一串连锁)：命中由斩光 / 剑痕 / 残光自己表现，不再每一下都炸一团碎屑、闪一次白、抖一下
	# (十几下叠在一起就是一大团黄方块，目标一直是白的)
	var iai: bool = src != null and src.def.hit_fx == "iaido"
	if v != null and amount > 0.5 and (not iai or _gate("iai_flinch:" + dst.uid, 0.24)):
		var dir := Vector3(0, 0, 1)
		if src != null:
			dir = Vector3(dst.pos.x - src.pos.x, 0.0, dst.pos.y - src.pos.y).normalized()
		if iai:
			v.flinch(v.global_transform.basis.inverse() * dir, 0.28, 0.6)
		else:
			v.flinch(v.global_transform.basis.inverse() * dir)
	var col: Color = Fx.COLORS.get(kind, Color.WHITE)
	var surface: String = str(e.get("surface", ""))
	if iai:
		if crit and _gate("iai_crit:" + dst.uid, 0.15):
			fx.burst(_chest(dst), Fx.COLORS["crit"], 5, 2.6, 0.8)
	elif surface == "equipment":
		fx.burst(_chest(dst), col, 14, 3.0, 1.2)
		fx.ring(Vector3(dst.pos.x, 0, dst.pos.y), 0.9, col, 0.35)
	elif surface == "trait":
		fx.burst(_chest(dst), col, 6, 2.0, 0.9)
	elif crit:
		fx.burst(_chest(dst), Fx.COLORS["crit"], 12, 3.2, 1.2)
		shake.emit(0.04)
	else:
		fx.burst(_chest(dst), col.lightened(0.3), 4, 1.5, 0.7)
	if surface in ["equipment", "passive"] and amount > 0.5:
		feed.emit({"kind": "damage", "src": src, "dst": dst, "amount": amount, "dmg_kind": kind, "surface": surface,
			"equip": e.get("equip", ""), "ability": e.get("ability", ""), "crit": crit})


func _on_heal(e: Dictionary) -> void:
	var dst: BUnit = e["dst"]
	var amount: float = float(e["amount"])
	var surface: String = str(e.get("surface", ""))
	if amount >= 1.0 and surface != "lifesteal":
		var crit_h: bool = bool(e.get("crit", false))
		var hsize: float = 1.3 if crit_h else (0.95 if not bool(e.get("splash", false)) else 0.75)
		fx.number(_chest(dst) + Vector3(0, 0.3, 0), "+%d%s" % [int(round(amount)), "!" if crit_h else ""], Fx.COLORS["heal"].lightened(0.25) if crit_h else Fx.COLORS["heal"], hsize)
		fx.burst(_chest(dst), Fx.COLORS["heal"], 6, 1.4, 0.8, 1.0, 0.7)
	elif float(e.get("over", 0.0)) > 0.5 and surface == "equipment" and _gate("over:" + dst.uid, 1.2):
		fx.number(_chest(dst) + Vector3(0, 0.3, 0), Loc.t("fx.overheal"), Color("#bff5cf"), 0.7)
	# 白羽节点的治疗弹：一只白蝶从队友身上飞起
	if str(e.get("ability", "")) == "angel_heal" and amount >= 1.0 and _gate("aheal:" + dst.uid, 0.3):
		fx.angel_heal_mark(_chest(dst))
	var v: UnitView = _view(dst)
	if v != null and amount >= 1.0:
		v.pulse_bar()
	if surface in ["equipment", "passive"] and (amount >= 1.0 or float(e.get("over", 0.0)) > 0.5):
		feed.emit({"kind": "heal", "src": e.get("src"), "dst": dst, "amount": amount, "surface": surface, "equip": e.get("equip", ""),
			"ability": e.get("ability", "")})


func _on_trigger(e: Dictionary) -> void:
	var u: BUnit = e["unit"]
	# 光之虚影：它听的那个触发器真的触发了 → 转向那个敌人挥一次(最小间隔由虚影自己管)
	if phantoms.has(u.uid) and str(u.def.phantom_fx.get("trigger", "")) == str(e.get("trigger", "")) and is_instance_valid(phantoms[u.uid]):
		var pt0: BUnit = e.get("target") as BUnit
		(phantoms[u.uid] as KnightPhantom).swing(_chest(pt0) if pt0 != null else _chest(u))
	# 变奏节点·下一乐章(想加层但已经叠满 → 装备效果)：一条五线谱从她身上盘上去 + 和弦的闪光(一次叠满会连着触发好几下，按 1.5 秒一次)
	if str(e.get("trigger", "")) == "node_pianist_next" and u.alive and _gate("next:" + u.uid, 1.5):
		fx.next_movement(Vector3(u.pos.x, 0.0, u.pos.y), _chest(u), u.def.form == "angel")
	# 单位数据 trigger_fx：这个触发器真的触发时的专属表现(求知节点：举书念咒、字飞到目标身上)
	var tfx: Dictionary = u.def.trigger_fx.get(str(e.get("trigger", "")), {})
	if not tfx.is_empty():
		var tv: UnitView = _view(u)
		if tv != null and str(tfx.get("anim", "")) != "":
			tv.play_once(str(tfx["anim"]))
		var tt0: BUnit = e.get("target") as BUnit
		if tt0 == null and not (e.get("targets", []) as Array).is_empty():
			tt0 = (e["targets"] as Array)[0] as BUnit
		match str(tfx.get("fx", "")):
			"requiem":
				# 致将亡而未亡者(每一发)：一只蝴蝶(黑 / 白轮流)从她身上扑向送葬最多的敌人
				if tt0 != null:
					_dart_n += 1
					fx.butterfly_dart(_chest(u) + Vector3(0.0, 0.15, 0.0), _chest(tt0), "black" if _dart_n % 2 == 1 else "white")
			"kind_pulse":
				# 善良地：她身上一圈心形的脉冲；被打到的人头上的沉醉音符亮一下、冒一颗小心
				fx.kind_pulse(Vector3(u.pos.x, 0.0, u.pos.y), _chest(u))
				var kn := 0
				for kt0: Variant in e.get("targets", []):
					var ktu: BUnit = kt0 as BUnit
					if ktu == null or not ktu.alive:
						continue
					if is_instance_valid(intox_marks.get(ktu.uid)):
						(intox_marks[ktu.uid] as IntoxMarks).pulse()
					if kn < 12:
						var kv0: UnitView = _view(ktu)
						fx.kind_mark(_chest(ktu) + Vector3(0.0, (kv0.body_height if kv0 != null else 1.3) * 0.35, 0.0))
					kn += 1
			"recite":
				if tv != null:
					var book: Vector3 = tv.bone_origin("Hand_R") + Vector3(0.0, 0.18, 0.0)
					fx.recite_spell(book, _chest(tt0) if tt0 != null else book + Vector3(sin(tv.rotation.y), 0.0, cos(tv.rotation.y)) * 2.0,
						_chest(u) + Vector3(0.0, tv.body_height * 0.55, 0.0), Color(str(tfx.get("color", "#7fb4ff"))))
	var surfaces: Array = e["surfaces"]
	var eq: Array = e["equips"]
	var col: Color = Fx.COLORS["trigger"]
	if eq.is_empty() and surfaces.has("trait") and not surfaces.has("passive"):
		return          # 羁绊的常驻触发(每次命中都触发)不刷圈、不刷信息流，只在结果处(伤害/治疗)体现
	if str(e.get("timing", "")) == "OnBattleFrame" and not _gate("trigf:%s:%s" % [u.uid, str(e["trigger"])], 1.5):
		return          # 每个战斗帧都可能触发的(灭罪节点·她必尽灭邪恶：一秒 4 次)：圈和信息流 1.5 秒最多一次
	if not eq.is_empty():
		var ed: EquipmentDef = catalog.get_equipment(str(eq[0]))
		if ed != null:
			col = UIKit.weapon_color(ed)
			# 没有冷却、每次普攻都触发的武器效果(舞扇等)：武器名每 2.5 秒最多飘一次，别刷屏
			if _gate("trig:%s:%s" % [u.uid, ed.id], 2.5 if ed.abilities.size() > 0 and ed.abilities[0].has_keyword("basic") else 0.0):
				fx.number(_chest(u) + Vector3(0, 0.85, 0), "「%s」" % Loc.t("equipment.%s.name" % ed.id), col.lightened(0.3), 0.85, 0.8, 0.9)
	fx.ring(Vector3(u.pos.x, 0, u.pos.y), 0.85, col, 0.4)
	var v: UnitView = _view(u)
	if v != null:
		v.pulse_bar()
	# 濒死时触发(再来一次之类)：原地转一圈把身边的敌人砍开 + 大字
	if str(e.get("timing", "")) == "OnBeforeDeath":
		if v != null:
			v.play_skill("spin")
		fx.spin_slash(Vector3(u.pos.x, 0, u.pos.y), 2.4, col.lightened(0.2))
		var tkey: String = "unit.%s.trigger.%s" % [u.def.id, str(e["trigger"])]
		var tname: String = Describe_bold(Loc.t(tkey)) if Loc.has_key(tkey) else ""
		if tname != "":
			fx.number(_chest(u) + Vector3(0, 1.15, 0), tname + "！", Color("#ff5a4a"), 1.25, 0.9, 1.1)
		shake.emit(0.06)
	feed.emit({"kind": "trigger", "unit": u, "trigger": e["trigger"], "timing": e["timing"], "equips": eq,
		"surfaces": surfaces, "value": e.get("value", 0.0), "target": e.get("target")})


func _set_burning(u: BUnit, on: bool) -> void:
	if u == null:
		return
	var v: UnitView = _view(u)
	if on and u.alive and v != null:
		if not burn_fx.has(u.uid) or not is_instance_valid(burn_fx[u.uid]):
			var f: FireFX = FireFX.body(v.body_height)
			v.add_child(f)
			burn_fx[u.uid] = f
	elif burn_fx.has(u.uid):
		var f2: Node = burn_fx[u.uid]
		burn_fx.erase(u.uid)
		if is_instance_valid(f2):
			(f2 as FireFX).set_emitting(false)
			get_tree().create_timer(0.8).timeout.connect(f2.queue_free)


func _on_death(e: Dictionary) -> void:
	var u: BUnit = e["unit"]
	_set_burning(u, false)
	var v: UnitView = _view(u)
	if v != null:
		if bool(u.meta.get("finale_death", false)):
			v.die("death_magi", 0.3)                # 少女幻终之后：浮起来、张开双臂碎成彩色方块
			fx.magi_death(_chest(u))
		elif bool(u.meta.get("hush_death", false)):
			v.die("death_spy", 0.3)                 # 少女幻嘘之后：浮起来、化成一把文字散掉
			fx.glyph_burst(_chest(u))
		elif bool(u.meta.get("funeral_death", false)):
			v.die("death_medium", 0.3)              # 少女幻葬之后：浮起来、化成灵火散掉
			fx.spirit_puff(_chest(u), true)
		elif funeral_doomed.has(u.uid):
			v.die("vanish")                         # 送葬满层：不倒下，身体直接化掉(化成蝴蝶飞散由 Fx.funeral 放)
		elif bool(u.meta.get("selfless_cut", false)):
			v.die_cut((SELFLESS_DRAW + SELFLESS_HOLD) / maxf(0.05, speed))     # 无我斩开的：定格，等刀痕落下后一齐崩散
		elif MECH.has(u.def.model):
			# 蓝之章的机械：炸开(装甲碎片、火花、黑烟)；炮台 / 载具不倒地，整台炸掉
			var mk: Dictionary = MECH[u.def.model]
			if bool(mk["big"]):
				v.die("vanish")
			else:
				v.die()
			fx.mech_explode(_chest(u), Color(str(mk["col"])), bool(mk["big"]))
			shake.emit(0.05 if bool(mk["big"]) else 0.02)
		elif u.has_flag("spectral") or bool(u.meta.get("feral", false)):
			v.die("vanish")                         # 魂体 / 吟唱里召出来的幽灵：不倒下，化成一团灵火
			fx.spirit_puff(_chest(u))
		else:
			v.die()
			if u.def.model.begins_with("ember_"):
				# 余烬熄灭：身上的火一下炸开、塌成一堆冒烟的灰(首领 / 精英再大一号)
				var ec: Color = _ident_color(u, Color("#ff5a1a"))
				var big: float = 1.6 if bool(u.meta.get("boss", false)) else (1.25 if u.def.id.begins_with("elite_") else 1.0)
				fx.fire_puff(_chest(u), ec, int(10 * big), 0.5 * big, 1.6 * big, 0.6)
				fx.fire_puff(_chest(u), Color("#2a2220"), int(6 * big), 0.6 * big, 0.8, 1.1, 0.5, false)
				fx.scorch(Vector3(u.pos.x, 0.0, u.pos.y), 0.7 * big, ec, 2.4)
	if domains.has(u.uid):
		fx.magi_domain_end(domains[u.uid], false)
		domains.erase(u.uid)
	if glyph_domains.has(u.uid):
		fx.glyph_domain_end(glyph_domains[u.uid], [])
		glyph_domains.erase(u.uid)
	if soul_domains.has(u.uid):
		fx.soul_domain_end(soul_domains[u.uid]["node"], [])
		soul_domains.erase(u.uid)
	# 白羽节点：绕着飞的黑蝶散掉；她自己倒下时身边的蝴蝶散开飞走、身上飞出一群黑白蝴蝶
	if is_instance_valid(funeral_wreaths.get(u.uid)):
		(funeral_wreaths[u.uid] as FuneralWreath).set_stacks(0, 10)
	funeral_wreaths.erase(u.uid)
	if is_instance_valid(butterfly_auras.get(u.uid)):
		(butterfly_auras[u.uid] as ButterflyAura).scatter()
		fx.angel_fall(_chest(u))
	butterfly_auras.erase(u.uid)
	if u.has_flag("spectral") or bool(u.meta.get("feral", false)):
		feed.emit({"kind": "death", "unit": u, "killer": e.get("killer")})
		return                                      # 召唤的灵体一直在生灭：不炸碎块、不震屏
	for mk: Dictionary in [misled_marks, stun_marks]:
		if mk.has(u.uid):
			if is_instance_valid(mk[u.uid]):
				(mk[u.uid] as Node3D).queue_free()
			mk.erase(u.uid)
	if paint_orbs.has(u.uid):
		if is_instance_valid(paint_orbs[u.uid]):
			(paint_orbs[u.uid] as Node3D).queue_free()
		paint_orbs.erase(u.uid)
	_sync_stamens(u, 0)
	_sync_blood_aura(u, 0)
	if beast_spirits.has(u.uid):
		if is_instance_valid(beast_spirits[u.uid]):
			(beast_spirits[u.uid] as BeastSpirit).vanish()
		beast_spirits.erase(u.uid)
	if phantoms.has(u.uid):
		if is_instance_valid(phantoms[u.uid]):
			(phantoms[u.uid] as KnightPhantom).vanish()
		phantoms.erase(u.uid)
	if lily_counters.has(u.uid):
		if is_instance_valid(lily_counters[u.uid]):
			(lily_counters[u.uid] as Node3D).queue_free()
		lily_counters.erase(u.uid)
	var dlv: UnitView = _view(u)
	if dlv != null and dlv.light_weapon != null and is_instance_valid(dlv.light_weapon):
		dlv.light_weapon.set_charges(0)
	if petal_swirls.has(u.uid):
		fx.petal_swirl_end(petal_swirls[u.uid], false)
		petal_swirls.erase(u.uid)
	if astro_forms.has(u.uid):
		fx.outer_collapse(Vector3(u.pos.x, 0, u.pos.y))       # 外神之貌结束：虚空塌缩
		if is_instance_valid(astro_forms[u.uid]["node"]):
			(astro_forms[u.uid]["node"] as EldritchForm).collapse()
		astro_forms.erase(u.uid)
		var dav: UnitView = _view(u)
		if dav != null:
			dav.form_size = 1.0
			dav.set_size(u.size_mult(), true)         # 塌回原来的样子再倒下
			dav.set_void(0.0, 0.3)
	fx.burst(_chest(u), GC.faction_color(u.def.faction_id), 22, 3.6, 1.4, 0.8, 0.9)
	fx.ring(Vector3(u.pos.x, 0, u.pos.y), 1.3, Color("#ffffff"), 0.5)
	shake.emit(0.07)
	feed.emit({"kind": "death", "unit": u, "killer": e.get("killer")})


## 限流：距离上次放行不到 gap 秒就拦下
func _gate(key: String, gap: float) -> bool:
	if gap <= 0.0:
		return true
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < float(_text_gate.get(key, 0.0)):
		return false
	_text_gate[key] = now + gap / maxf(1.0, speed)
	return true


## 手写说明里的 [b]名字[/b]
static func Describe_bold(t: String) -> String:
	var i: int = t.find("[b]")
	var j: int = t.find("[/b]")
	return t.substr(i + 3, j - i - 3) if i >= 0 and j > i else ""
