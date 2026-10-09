extends "res://tools/anim_combat.gd"
## 跟着"棋子身体模型"走的非战斗动作(与手里拿什么武器无关)：
##   fidget[_<模型>]  待机小动作：备战/标题画面里站久了随机播一次(UnitView 负责计时，各棋子错开)，播放时武器收起
##   victory[_<模型>] 胜利动作：战斗胜利时循环播放，武器同样收起
## 通用模型不带后缀；专属模型 dancer / archer / nurse 各有一套，性格不同：
##   通用 — 伸懒腰(闭眼)，再左右张望
##   dancer — 张开双臂踮脚转一圈，落成单手叉腰、单手扬起的舞姿；胜利 = 左右扭胯交替举手的小舞步
##   archer — 手搭凉棚眺望远方、另一手叉腰，然后歪头活动脖子；胜利 = 叉腰 + 额前两指敬礼 + 眨一只眼
##   nurse — 双手合十闭眼祈祷，睁眼歪头，再把手叠在身前；胜利 = 小跳 + 双手捧在胸前，再挥手，翅膀扇得更快
##   berserker — 拳砸掌心、左右扭脖子、双臂屈肘秀肌肉；胜利 = 大开步双拳高举、仰头长嚎
##   darkknight — 把肩头的披风往后一甩、低头翻看手甲、回头一瞥；胜利 = 抚胸礼(右拳按在胸口)静立
##   warrior — 双手扶正头盔、左右晃头、耸肩换重心；胜利 = 右拳高举 + 左拳捶胸
##   magi — 双手背在身后踮脚晃、歪头，再朝前挥手；胜利 = 右手指天、左手叉腰、抬起左膝的变身定格 + 眨眼
##   bounty — 右手弹硬币、抬头看、接住，再双手叉腰环顾；胜利 = 叉腰 + 右手比枪"砰"一下 + 眨眼
##   shielder — 双手扶头顶的护目镜、甩甩头，再十指交叉往前伸懒腰；胜利 = 双拳高举原地蹦
##   vine — 双臂像树枝一样慢慢举起、随风左右摇，再重重跺一下脚；胜利 = 双臂张开高举、慢慢摇摆
##   peasant — 用手背抹一把额头的汗，双手撑着后腰往后伸个懒腰(闭眼)，再满意地点点头；胜利 = 左手叉腰、右拳一下下往上举，原地蹦(丰收了)
##   druid — 右手捋两下胡子、点点头，再把手背到身后、踮踮脚跟；胜利 = 右手掌心朝天举起(祝福)、左手按在胸口，慢慢点头、眯眼笑
##   witch — 摊开左手看着掌心(像托着一团火)，合上手，再用右手把长发往肩后一撩、半闭眼；胜利 = 左手叉腰、右手托着"火球"举在肩旁，轻轻晃 + 眨眼
##   basic — 低头看摊开的手心、左右歪头慢慢眨眼、挠后脑勺；胜利 = 两手举到肩旁小小地挥，歪着头晃
##   taoist — 左手背后、右手脸前竖剑诀闭眼默念，往前一点施符；胜利 = 左手叉腰、右手剑诀竖在脸旁，歪头眨眼
##   cowboy — 两指压低帽檐左右扫一眼，再竖指在嘴边吹一口(吹枪口)；胜利 = 左手叉腰、右手把帽子往上一推再压回去，往后仰着晃 + 眨眼
##   gladiator — 右拳砸进左掌、再抱臂扬起下巴睥睨四周；胜利 = 左手叉腰、右拳高举向观众一下下挥、转头致意 + 眨眼
##   leader — 扶帽檐、环视一圈，再抬手往前一指；胜利 = 立正敬礼、左手叉腰、点头 + 眨眼
##   medium — 双手捧着看不见的灵火低头看，再对着身边看不见的朋友歪头一笑、伸手摸摸空气；胜利 = 右手按胸、左手挥一挥 + 眨眼
##   dog(四足) — 低头嗅嗅地面、抬头喘气摇头；胜利 = 原地蹦跶、歪头
##   ghost(无腿) — 原地飘着转一圈、两只骨手摆一摆；胜利 = 双手举起晃、上下飘
##   spy — 左右瞟两眼、理一理西装领口、食指竖在唇前"嘘"；胜利 = 左手叉腰、右手食指抵唇，歪头眨眼
##   runner — 踮着脚尖拳击步小跳、拉一拉手套的护腕、勾脚拉伸大腿；胜利 = 左手叉腰、右拳高举一下下往上顶，右脚尖打拍子 + 眨眼
##   student — 推一下眼镜，托腮思考(另一只手托住手肘、歪头往上看)，再竖起食指"有了！"小跳一下；胜利 = 左手叉腰、右手食指在脸旁摇来摇去"果然如此"，一颠一颠 + 眨眼
##   noble — 右手抬到头侧拨一拨发间的花(歪头、半闭眼)，再左手提裙、右手按在心口行屈膝礼；胜利 = 左手按在心口、右手举在脸旁轻轻挥，身子轻晃 + 眨左眼
##           (正行节点的花蕊 / 再绽之花等战斗动作见文件末尾 NOBLE_TABLE 一节)
##   brave — 双手叉腰、挺胸仰头望天，坚定地点一下头，再把右手收到胸前慢慢攥紧拳头("我会保护大家")，龙尾跟着一甩；
##           胜利 = 右拳高举向天、左手按在心口，挺胸踮脚轻轻颠，龙尾左右摇 + 眨左眼(见文件末尾 BRAVE_TABLE 一节)
##   pacifist(坐轮椅的人鱼歌姬) — 右手按在心口、闭眼哼着歌左右轻晃，再睁眼歪头、抬起左手小小地挥一挥；
##           胜利 = 右手送出一个飞吻(眨左眼)、左手举在脸旁挥，坐在椅子里开心地晃(只动上半身；待机 / 移动 / 唱歌普攻见文件末尾 PACIFIST_TABLE 一节)
##   angel(白羽节点，羽翼天使枪手) — 双手合十闭眼祈祷，再慢慢张开双臂、羽翼大大展开扇一下，歪头半闭着眼静静地笑；
##           胜利 = 羽翼全展慢慢扇、右手掌心朝外举在头侧赐福、左手按在心口，脚尖离地轻轻浮动 + 眨左眼(翅膀自己控制，见文件末尾 ANGEL_TABLE 一节)
##   warden(守林节点，狮耳狮尾的荒野萨满少女) — 像猫一样伸懒腰(两手往前伸直、屁股往后撅、塌腰仰头)，再右手挠耳朵后面(头歪过去蹭着手)，甩甩头、尾巴一甩；
##           胜利 = 两爪举在头两侧挺胸仰头"吼"一声，再开心地原地蹦两下(歪头、眨左眼)，尾巴一直快快地摇
##           (狮子 / 巨蛛 / 巨蟾三种兽形的待机、移动、普攻和变身见文件末尾 WARDEN_TABLE 一节)
##   psychic(导向节点，金发猫耳的雷电魔导士) — 抬手搓指尖、被自己的静电"啪"地电了一下(一缩一跳、闭眼、鬓发炸开)，甩甩头甩甩手，再把指尖的火花往外一弹(眨左眼)；
##           胜利 = 右手举到头侧张开手掌引雷、左手叉腰，雷落下时全身一挺，再原地小跳 + 眨左眼
##           (普攻的吟唱 chant_psychic_<大类> / _hold 见文件末尾 PSY_TABLE 一节)
##   paladin(圣战节点，蓝发络腮胡的锤圣骑士，男性款) — 右手捋两下络腮胡(低头眯眼)，耸肩活动肩膀、左右扭脖子，再右拳按在胸口低头默祷；
##           胜利 = 大开步站定、右拳高举向天一下下往上顶(左拳叉腰)，再收回来"咚"地捶一下胸口(见文件末尾 PALADIN_TABLE 一节：裂地猛击 slam_paladin_<大类>)
##   rogue(巧运节点，银发精灵耳、红围巾黑长外套的幸运盗贼，男性款) — 右手拇指把硬币往上一弹、仰头追着它看，一把抄住"啪"地拍在左手背上，俯身掀开手掌偷看，
##           再得意地耸肩、左手一摊、眨左眼，把硬币塞进右胯前的腰包按两下；
##           胜利 = 重心压在左腿上往后仰、左手拇指勾着腰带，右手把硬币一抛、仰头看它落下一把抄住，顺手两指在眉边往外一甩敬礼 + 眨左眼(见文件末尾 ROGUE_TABLE 一节)
##   sister(心连节点，象牙白球形关节的发条人偶修女) — 双手十指交扣、低头闭眼祈祷，再"咔"地睁眼：发条走松了，头一格一格歪下去、身子塌下去、手垂下来，
##           右手在右腰侧拧看不见的发条钥匙、上弦三圈(每圈"咔哒"一顿，头拨回一格)，上满了一挺一颠、眨眼，再低头用两手把裙摆抚平；
##           胜利 = 交扣祈祷 → 提裙屈膝礼 → 双臂张开赐福，头"咔、咔、咔"一格一格地歪过去再拨回来(见 ROGUE_TABLE 之后的 SISTER_TABLE 一节)
##   killer(无我节点，墨绿长发、手臂和小腿爬着紫色诅咒纹的咒刃武士少女，半垂着眼、很沉静) — 右手抬到胸前、掌心朝上低头看发作的诅咒手，手指慢慢屈伸、发抖，
##           翻过来看手背、左手握住右手腕，慢慢攥成拳；再放下手，闭眼深吸一口气、长长地呼出来，半睁开眼；
##           胜利 = 侧过身半转、左手按着腰间看不见的刀(握着鞘口)，低头半闭眼，慢慢吸气、长长地呼气
##           (大太刀连鞘 / 出鞘的普攻与旋斩、开场拔刀 draw_killer 见 SISTER_TABLE 之后的 KILLER_TABLE 一节)
##   arcanist(奇兴节点，紫发龙角、灰色蝙蝠翼和龙鳞爪的骰子术士，赌徒) — 右爪托着一颗骰子低头看、在掌心里滚两下，攥起来凑到嘴边吹一口(闭眼、翅膀一收)，
##           往上一抛、仰头追着看、一把抄住，凑到眼前偷看 —— 点数不好：摇头、肩膀一塌、翅膀耷拉下来，再两手一摊耸耸肩；
##           胜利 = 中了头奖：两只龙爪高举成 V 字、蝙蝠翼全展每蹦一下扇一下，原地小蹦、两手轮流往上一顶 + 眨左眼
##           (战斗里随机"掷 2d10"的 roll_arcanist_<大类> 见 KILLER_TABLE 之后的 ARC_TABLE 一节；翅膀自己控制)
##   keeper(锁芯节点，绿发尖耳、蛇尾、黑金暗绿法袍的蛇系钥匙守护者，坏笑、自信的施法者) — 左手叉腰，右手掌心朝上手指一张"变"出一把小钥匙，
##           捏起来举到脸旁转两下(歪头看着它)，往后一收、往前一插，手腕一拧"咔哒"(身子一顿、蛇尾一甩)，歪头坏笑眨左眼，再拔出来往肩上一抛、手一张；
##           胜利 = 左手叉腰扭胯，右手捏着钥匙举在头侧亮一亮 → 往前一插、一拧"咔哒"开锁(眨左眼)→ 举回来，蛇尾得意地左右摆(见 ARC_TABLE 之后的 KEEPER_TABLE 一节)
##   pianist / pianist_angel(变奏节点，恶魔 / 天使两个形态共用) — 手搭上琴键(拿着大钢琴时就是真的在弹，否则是空气钢琴)，右手一串琶音、左手颤音，
##           闭眼陶醉地大幅摇摆 → 砸下最后一个和弦 → 右手按心口、左手摊开，屈膝行礼谢幕、眨左眼；
##           胜利 = 左手摊开，右手从心口往头侧一扬"噔噔！"(眨左眼) → 收回心口屈膝行礼(弹大钢琴的待机 / 移动 / 普攻见文件末尾 PIANIST_TABLE 一节)
## 收起武器 = 把武器骨(Bow / Weapon_L / Shield)缩到 0：动作间切换的交叉淡化会让武器平滑地缩进手里、再长出来。
## 手的朝向都用"胸腔局部"的手指方向 + 掌心方向来写(_hand)，转身时手势跟着上身一起转。

const STOW_BONES := ["Bow", "Weapon_L", "Shield"]
const FIDGET_DUR := {"leader": 4.0, "dog": 3.6, "ghost": 3.2, "medium": 4.0, "spy": 4.0, "runner": 4.0, "tinker": 4.0, "astronaut": 4.0, "maid": 4.0, "bird": 3.0, "wizard": 3.8, "hunter": 3.8, "samurai": 3.8, "cowboy": 3.8, "basic": 4.0, "taoist": 4.0, "gladiator": 3.8, "berserker": 3.6, "darkknight": 3.8, "warrior": 3.6, "magi": 4.0, "bounty": 3.6, "shielder": 3.8, "vine": 4.0, "peasant": 4.0, "student": 4.0, "witch": 4.0, "druid": 4.0}
const VICTORY_DUR := {"leader": 2.0, "dog": 1.2, "ghost": 1.6, "medium": 2.0, "spy": 2.0, "runner": 2.0, "tinker": 2.0, "astronaut": 1.6, "maid": 2.0, "bird": 1.6, "wizard": 2.0, "hunter": 1.6, "samurai": 2.0, "cowboy": 2.0, "basic": 2.0, "taoist": 2.0, "gladiator": 2.0, "berserker": 2.0, "darkknight": 2.4, "warrior": 2.0, "magi": 2.0, "bounty": 2.0, "shielder": 1.6, "vine": 2.4, "peasant": 1.6, "student": 2.0, "witch": 2.0, "druid": 2.4}
const RELAX_L := Vector3(15.2, 48.5, 1.6)        # 待机时手自然垂在身侧的位置(胸腔局部)


func table() -> Dictionary:
	var t: Dictionary = super.table()
	t["fidget"] = {"dur": 3.8, "loop": false, "fn": Callable(self, "fidget_base")}
	t["victory"] = {"dur": 1.6, "loop": true, "fn": Callable(self, "victory_base")}
	t["fidget_dancer"] = {"dur": 4.0, "loop": false, "fn": Callable(self, "fidget_dancer")}
	t["victory_dancer"] = {"dur": 2.4, "loop": true, "fn": Callable(self, "victory_dancer")}
	t["fidget_archer"] = {"dur": 3.6, "loop": false, "fn": Callable(self, "fidget_archer")}
	t["victory_archer"] = {"dur": 2.0, "loop": true, "fn": Callable(self, "victory_archer")}
	t["fidget_nurse"] = {"dur": 4.0, "loop": false, "fn": Callable(self, "fidget_nurse")}
	t["victory_nurse"] = {"dur": 2.0, "loop": true, "fn": Callable(self, "victory_nurse"), "wing_hz": 3.0, "wing_amp": 1.6}
	for m: String in ["berserker", "darkknight", "warrior", "magi", "bounty", "shielder", "vine", "peasant", "student", "witch", "druid", "gladiator", "basic", "taoist", "cowboy", "samurai", "hunter", "wizard", "bird", "maid", "astronaut", "tinker", "runner", "spy", "medium", "dog", "ghost", "leader"]:
		t["fidget_" + m] = {"dur": FIDGET_DUR[m], "loop": false, "fn": Callable(self, "fidget_" + m)}
		t["victory_" + m] = {"dur": VICTORY_DUR[m], "loop": true, "fn": Callable(self, "victory_" + m)}
	ember_table(t)
	vanity_table(t)
	samurai_table(t)
	hunter_table(t)
	wizard_table(t)
	maid_table(t)
	magi_table(t)
	runner_table(t)
	spy_table(t)
	medium_table(t)
	dog_table(t)
	red_table(t)
	red_human_table(t)
	blue_table(t)
	noble_table(t)
	brave_table(t)
	pacifist_table(t)
	angel_table(t)
	warden_table(t)
	psychic_table(t)
	paladin_table(t)
	rogue_table(t)
	sister_table(t)
	killer_table(t)
	arcanist_table(t)
	keeper_table(t)
	pianist_table(t)
	t["recite_student"] = {"dur": 0.8, "loop": false, "fn": Callable(self, "recite_student")}
	# 男性款：所有待机/跑步动作再烘一份 *_m(男性模型的 UnitSkin.anim 选用)；攻击由武器决定、男女共用
	for nm: String in t.keys().duplicate():
		if nm == "idle" or nm == "run" or nm.begins_with("idle_") or nm.begins_with("run_"):
			var d: Dictionary = (t[nm] as Dictionary).duplicate()
			d["fn"] = Callable(self, "_as_male").bind(t[nm]["fn"])
			t[nm + "_m"] = d
	return t


func _as_male(t: float, p, fn: Callable) -> void:
	male = true
	fn.call(t, p)
	male = false


# =============================================================== 通用小工具
func _stow(p) -> void:
	for b: String in STOW_BONES:
		p.scale_(b, Vector3.ONE * 0.001)


## 站姿底座：骨盆左右移(sway)/上下(bob)，上身扭转 yaw、前倾 lean、侧弯 roll(度)；spin = 整个人绕竖轴转(度)；
## 双脚：spread 半宽、lead > 0 左脚在前；tip = 踮脚程度(0..1)
func _base(p, sway: float, bob: float, yaw: float, lean: float, roll: float = 0.0, spin: float = 0.0,
		spread: float = 6.5, lead: float = 0.0, tip: float = 0.0) -> void:
	p.r("Root", 0.0, spin, 0.0)
	p.move("Hips", Vector3(sway, -1.7 + bob + 3.2 * tip, 0.0))
	p.r("Hips", lean * 0.35, yaw * 0.3, sway * 0.9)
	p.r("Spine", lean * 0.3, yaw * 0.3, roll * 0.45 - sway * 0.5)
	p.r("Chest", lean * 0.35, yaw * 0.4, roll * 0.55 - sway * 0.4)
	var q := Quaternion(Vector3.UP, deg_to_rad(spin))
	var fl: Vector3 = q * Vector3(spread, ANKLE_Y + 3.4 * tip, -0.5 + lead)
	var fr: Vector3 = q * Vector3(-spread, ANKLE_Y + 3.4 * tip, -0.5 - lead)
	legs(p, fl, fr, Lib.E(32.0 * tip, spin + 6.0, 0.0), Lib.E(32.0 * tip, spin - 6.0, 0.0), -26.0 * tip, -26.0 * tip)


## 头：pitch 低头为正、yaw 向左看为正、roll 向左歪为正(度)
func _head(p, pitch: float, yaw: float, roll: float) -> void:
	p.r("Neck", pitch * 0.3, yaw * 0.3, roll * 0.3)
	p.r("Head", pitch * 0.7, yaw * 0.7, roll * 0.7)


## 胸腔局部方向 → 世界方向
func _cdir(p, v: Vector3) -> Vector3:
	p.fk()
	return (p.gx[rig.ids["Chest"]].basis * v).normalized()


## 手势的朝向：手指指向 fingers、掌心朝向 palm(左手的胸腔局部量，右手自动镜像) → 胸腔局部旋转
func _gq(side: String, fingers: Vector3, palm: Vector3) -> Quaternion:
	var m: float = 1.0 if side == "L" else -1.0
	var f0 := Vector3(0, -1, 0)                  # 静止时：手指朝下、掌心朝身体内侧
	var p0 := Vector3(-m, 0, 0)
	var f1: Vector3 = Vector3(fingers.x * m, fingers.y, fingers.z).normalized()
	var p1: Vector3 = Vector3(palm.x * m, palm.y, palm.z)
	p1 = (p1 - f1 * p1.dot(f1)).normalized()
	var b0 := Basis(f0, p0, f0.cross(p0))
	var b1 := Basis(f1, p1, f1.cross(p1))
	return Quaternion((b1 * b0.inverse()).orthonormalized())


## 一只手(side = "L"/"R")：目标位置 at、肘的朝向 pole(左手的胸腔局部量，右手自动镜像)、手的胸腔局部旋转 q；curl = 手指弯曲(度)
func _hand_q(p, side: String, at: Vector3, pole: Vector3, q: Quaternion, curl: float = 14.0) -> void:
	var m: float = 1.0 if side == "L" else -1.0
	var tgt: Vector3 = follow(p, "Chest", Vector3(at.x * m, at.y, at.z))
	p.ik2("UpperArm_" + side, "LowerArm_" + side, "Hand_" + side, tgt, _cdir(p, Vector3(pole.x * m, pole.y, pole.z)))
	p.fk()
	var cq: Quaternion = Quaternion(p.gx[rig.ids["Chest"]].basis.orthonormalized())
	p.set_grot("Hand_" + side, cq * q)
	p.r("Fingers_" + side, -curl, 0, -22.0 * m * clampf(1.0 - curl / 60.0, 0.0, 1.0))
	p.r("Thumb_" + side, -10.0 - curl * 0.3, 0, 0)


func _hand(p, side: String, at: Vector3, pole: Vector3, fingers: Vector3, palm: Vector3, curl: float = 14.0) -> void:
	_hand_q(p, side, at, pole, _gq(side, fingers, palm), curl)


## 手自然垂在身侧(待机的手)
func _relax(p, side: String, k: float = 0.0) -> void:
	_hand(p, side, RELAX_L + Vector3(0.0, 0.4 * k, 0.0), Vector3(0.6, -0.2, -1.0), Vector3(0.1, -1.0, 0.12), Vector3(-1.0, 0.0, 0.2), 14.0)


## 叉腰：手背贴在腰侧，手指朝后下，肘向外
func _on_hip(p, side: String) -> void:
	_hand(p, side, Vector3(12.8, 50.5, -0.5), Vector3(1.0, 0.1, -0.7), Vector3(-0.2, -0.6, -1.0), Vector3(-1.0, 0.0, 0.0), 30.0)


## 在两个手势之间插值：a、b 是 [at, pole, fingers, palm, curl]；朝向用四元数球面插值(直接插手指/掌心向量，中途会退化翻转)
func _hand_mix(p, side: String, a: Array, b: Array, w: float) -> void:
	var at: Vector3 = (a[0] as Vector3).lerp(b[0], w)
	var pole: Vector3 = (a[1] as Vector3).lerp(b[1], w)
	var q: Quaternion = _gq(side, a[2], a[3]).slerp(_gq(side, b[2], b[3]), w)
	_hand_q(p, side, at, pole, q, lerpf(float(a[4]), float(b[4]), w))


const G_RELAX := [RELAX_L, Vector3(0.6, -0.2, -1.0), Vector3(0.1, -1.0, 0.12), Vector3(-1.0, 0.0, 0.2), 14.0]
const G_HIP := [Vector3(12.8, 50.5, -0.5), Vector3(1.0, 0.1, -0.7), Vector3(-0.2, -0.6, -1.0), Vector3(-1.0, 0.0, 0.0), 30.0]
const G_UP := [Vector3(18.8, 81.5, 2.5), Vector3(1.0, -0.3, -0.6), Vector3(0.1, 1.0, 0.0), Vector3(-0.5, 0.0, 1.0), 6.0]     # 举到头侧、掌心朝前
const G_OPEN := [Vector3(25.0, 61.0, 6.0), Vector3(0.2, -0.6, -1.0), Vector3(1.0, -0.15, 0.2), Vector3(0.0, -1.0, 0.3), 10.0]  # 张开到身侧、掌心朝下
const G_PRAY := [Vector3(2.4, 61.0, 12.5), Vector3(1.0, -0.8, 0.0), Vector3(0.0, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 4.0]    # 合十
const G_FOLD := [Vector3(3.0, 52.5, 10.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.6, -0.8, 0.1), Vector3(0.0, 0.2, -1.0), 20.0]  # 叠在身前


# =============================================================== 通用模型：伸懒腰 → 左右张望 (3.8s)
func fidget_base(t: float, p) -> void:
	p.reset()
	_stow(p)
	var up: float = kf_f([[0.0, 0.0], [0.55, 1.0], [1.45, 1.0], [1.95, 0.0]], t)
	var bend: float = kf_f([[0.0, 0.0], [0.55, 0.0], [0.9, 7.0], [1.25, -7.0], [1.5, 0.0]], t)
	_base(p, 0.5 * sin(t * 1.7), 0.0, 0.0, -9.0 * up, bend, 0.0, 6.5, 0.0, 0.55 * kf_f([[0.0, 0.0], [0.55, 1.0], [1.4, 1.0], [1.8, 0.0]], t))
	var look: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.35, 32.0, "o"], [2.7, 32.0], [3.05, -28.0], [3.35, -28.0], [3.8, 0.0]], t)
	_head(p, -9.0 * up + 2.0 * kf_f([[0.0, 0.0], [2.0, 0.0], [2.3, 1.0], [3.4, 1.0], [3.8, 0.0]], t), look, -bend * 0.6)
	for side: String in ["L", "R"]:
		_hand_mix(p, side, G_RELAX, [Vector3(18.8, 82.0, -0.5), Vector3(1.0, -0.2, -0.4), Vector3(0.25, 1.0, -0.1), Vector3(-0.6, 0.2, 0.8), 4.0], up)
	set_lids(p, minf(1.0, kf_f([[0.0, 0.0], [0.35, 0.0], [0.55, 1.0], [1.55, 1.0], [1.75, 0.0], [3.05, 0.0]], t) + blink_k(t, 3.1)))


# =============================================================== 通用模型：胜利(小跳 + 右拳举起 + 左手挥)(1.6s 循环)
func victory_base(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = absf(sin(th)) * 5.0
	_base(p, 0.0, hop * 0.9, 6.0 * sin(th), -6.0, 3.0 * sin(th), 0.0, 6.6, 0.0, 0.0)
	legs(p, Vector3(6.6, ANKLE_Y + hop * 0.9, -0.5), Vector3(-6.6, ANKLE_Y + hop * 0.9, -0.5), Lib.E(0, 8, 0), Lib.E(0, -8, 0))
	_head(p, -6.0 + 3.0 * sin(2.0 * th), 6.0 * sin(th), 3.0 * sin(th))
	# 右拳举到头侧、跟着节奏往上顶
	_hand(p, "R", Vector3(18.6, 80.5 + 2.0 * sin(2.0 * th), 3.5), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 1.0, 0.1), Vector3(-0.4, 0.0, 1.0), 85.0)
	# 左手在头侧挥
	_hand(p, "L", Vector3(19.0, 79.5, 3.5), Vector3(1.0, -0.3, -0.5), Vector3(0.35 * sin(2.0 * th), 1.0, 0.0), Vector3(0.0, 0.0, 1.0), 6.0)
	p.move("Halo", Vector3(0.0, 1.0 * sin(2.0 * th), 0.0))
	set_lids(p, 0.0)


# =============================================================== 起舞：张臂踮脚转一圈 → 舞姿定格 → 收 (4.0s)
func fidget_dancer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var spin: float = kf_f([[0.0, 0.0], [0.45, 0.0], [1.35, 360.0], [4.0, 360.0]], t)
	var tip: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.35, 1.0], [1.6, 0.0]], t)
	var pose: float = kf_f([[0.0, 0.0], [1.35, 0.0], [1.7, 1.0, "o"], [3.0, 1.0], [3.9, 0.0]], t)
	var open: float = kf_f([[0.0, 0.0], [0.45, 1.0], [1.35, 1.0], [1.7, 0.0]], t)
	var breath: float = 0.6 * sin(TAU * t / 1.3) * pose
	_base(p, 2.4 * pose, 0.6 * breath, 8.0 * pose, -3.0 * open, 5.0 * pose, spin, lerpf(6.5, 3.5, tip), 1.5 * pose, tip)
	_head(p, -4.0 * open - 2.0 * pose, -10.0 * pose, 9.0 * pose + 2.0 * breath)
	# 三段：垂手 → 张开(转圈) → 左手叉腰 + 右手扬到头侧 → 垂手
	var flair := [Vector3(18.8, 80.0, 4.0), Vector3(1.0, -0.2, -0.5), Vector3(0.3, 1.0, 0.1), Vector3(0.2, -0.2, 1.0), 4.0]
	if t < 1.35:
		_hand_mix(p, "L", G_RELAX, G_OPEN, open)
		_hand_mix(p, "R", G_RELAX, G_OPEN, open)
	elif t < 3.0:
		_hand_mix(p, "L", G_OPEN, G_HIP, pose)
		_hand_mix(p, "R", G_OPEN, flair, pose)
	else:
		var back: float = kf_f([[3.0, 0.0], [3.9, 1.0]], t)
		_hand_mix(p, "L", G_HIP, G_RELAX, back)
		_hand_mix(p, "R", flair, G_RELAX, back)
	set_lids(p, blink_k(t, 2.4))


# =============================================================== 起舞：胜利小舞步(左右扭胯、交替举手)(2.4s 循环)
func victory_dancer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var sw: float = sin(th)                       # +1 = 重心在左
	var bounce: float = absf(sin(th)) * 2.2
	_base(p, 2.8 * sw, bounce, 10.0 * sin(th + 0.5), -4.0, 6.0 * sw, 0.0, 6.8, 0.0, 0.25 + 0.25 * absf(cos(th)))
	_head(p, -5.0, -8.0 * sw, -10.0 * sw)
	var wl: float = 0.5 + 0.5 * sw                # 左手举起的程度
	var down := [Vector3(21.0, 56.0, 7.0), Vector3(0.4, -0.6, -1.0), Vector3(0.8, -0.6, 0.2), Vector3(0.0, -0.6, 1.0), 8.0]
	var raise := [Vector3(18.8, 81.0, 3.5), Vector3(1.0, -0.3, -0.5), Vector3(0.2 * cos(2.0 * th), 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 4.0]
	_hand_mix(p, "L", down, raise, Lib.smooth(wl))
	_hand_mix(p, "R", down, raise, Lib.smooth(1.0 - wl))
	set_lids(p, 0.0)


# =============================================================== 连射：手搭凉棚眺望 → 活动脖子 (3.6s)
func fidget_archer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var shade: float = kf_f([[0.0, 0.0], [0.5, 1.0, "o"], [1.7, 1.0], [2.1, 0.0]], t)
	var hip: float = kf_f([[0.0, 0.0], [0.45, 1.0], [2.9, 1.0], [3.5, 0.0]], t)
	var scan: float = kf_f([[0.0, 0.0], [0.5, 26.0], [0.8, 26.0], [1.5, -22.0], [1.7, -22.0], [2.1, 0.0]], t)
	var tilt: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.4, 13.0], [2.6, 13.0], [2.9, -12.0], [3.1, -12.0], [3.5, 0.0]], t)
	_base(p, 1.6 * hip, 0.0, 0.25 * scan, 5.0 * shade, 0.0, 0.0, 6.5, -1.0 * hip, 0.0)
	_head(p, -4.0 * shade, scan * 0.75, tilt - 3.0 * shade)
	# 右手：从太阳穴往前搭在眉上(手指朝前偏内、掌心朝下)
	_hand_mix(p, "R", G_RELAX, [Vector3(12.0, 81.5, 9.5), Vector3(1.0, -0.5, -0.3), Vector3(-0.55, 0.05, 1.0), Vector3(0.0, -1.0, 0.0), 6.0], shade)
	_hand_mix(p, "L", G_RELAX, G_HIP, hip)
	set_lids(p, kf_f([[0.0, 0.0], [2.35, 0.0], [2.45, 0.7], [3.0, 0.7], [3.1, 0.0]], t))


# =============================================================== 连射：胜利(叉腰 + 额前两指敬礼 + 眨右眼)(2.0s 循环)
func victory_archer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var flick: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [0.55, 0.0], [2.0, 0.0]], t)   # 从眉边往外一甩
	var bob: float = 0.5 * sin(2.0 * th)
	_base(p, 2.0, bob, -6.0, -2.0, -3.0, 0.0, 6.8, -1.5, 0.0)
	_head(p, -3.0, 6.0, -8.0 + 1.5 * sin(th))
	_on_hip(p, "L")
	var at: Vector3 = Vector3(11.5, 80.0, 10.0).lerp(Vector3(19.0, 82.0, 8.0), flick)
	_hand(p, "R", at, Vector3(1.0, -0.4, -0.3), Vector3(0.35 + 0.4 * flick, 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 4.0)
	# 眨右眼(另一只睁着)
	p.scale_("Eyelid_R", Vector3(1, 1, 1))
	p.move("Eyelid_R", Vector3(0, 0, 3.2))
	p.scale_("Eyelid_L", Vector3(1, 0.001, 1))


# =============================================================== 护理：合十闭眼 → 睁眼歪头 → 手叠身前 (4.0s)
func fidget_nurse(t: float, p) -> void:
	p.reset()
	_stow(p)
	var pray: float = kf_f([[0.0, 0.0], [0.6, 1.0], [2.3, 1.0], [2.8, 0.0]], t)
	var fold: float = kf_f([[0.0, 0.0], [2.3, 0.0], [2.8, 1.0], [3.4, 1.0], [3.95, 0.0]], t)
	var tilt: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.55, 11.0, "o"], [3.3, 11.0], [3.9, 0.0]], t)
	_base(p, 0.5 * sin(t * 1.9), 0.3 * sin(t * 3.1), 0.0, 4.0 * pray, 0.0, 0.0, 5.5, 0.0, 0.0)
	_head(p, 11.0 * pray, 0.0, tilt)
	for side: String in ["L", "R"]:
		if fold > 0.0:
			_hand_mix(p, side, G_PRAY if pray > 0.0 else G_RELAX, G_FOLD, fold)
			if t > 3.4:
				_hand_mix(p, side, G_FOLD, G_RELAX, kf_f([[3.4, 0.0], [3.95, 1.0]], t))
		else:
			_hand_mix(p, side, G_RELAX, G_PRAY, pray)
	set_lids(p, kf_f([[0.0, 0.0], [0.4, 0.0], [0.65, 1.0], [2.15, 1.0], [2.35, 0.0]], t))


# =============================================================== 护理：胜利(小跳 + 双手捧在胸前 → 右手挥，翅膀快扇)(2.0s 循环)
func victory_nurse(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var hop: float = absf(sin(2.0 * th)) * 3.2
	_base(p, 0.0, hop, 4.0 * sin(th), -4.0, 0.0, 0.0, 5.5, 0.0, 0.0)
	legs(p, Vector3(5.5, ANKLE_Y + hop, -0.5), Vector3(-5.5, ANKLE_Y + hop, -0.5), Lib.E(0, 6, 0), Lib.E(0, -6, 0))
	var wave: float = Lib.smooth(0.5 - 0.5 * cos(th))           # 0 = 捧在胸前，1 = 右手挥
	_head(p, -4.0, 6.0 * wave, 8.0 * sin(th))
	_hand(p, "L", G_PRAY[0], G_PRAY[1], G_PRAY[2], G_PRAY[3], 20.0)
	var wv := [Vector3(19.0, 79.5, 4.0), Vector3(1.0, -0.3, -0.5), Vector3(0.4 * sin(4.0 * th), 1.0, 0.0), Vector3(0.0, 0.0, 1.0), 6.0]
	_hand_mix(p, "R", [G_PRAY[0], G_PRAY[1], G_PRAY[2], G_PRAY[3], 20.0], wv, wave)
	set_lids(p, 0.0)


# =============================================================== 本批专属模型的小动作 / 胜利动作
const G_FIST_UP := [Vector3(18.8, 80.5, 3.5), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 1.0, 0.1), Vector3(-0.4, 0.0, 1.0), 85.0]
const G_FLEX := [Vector3(19.5, 73.5, 1.0), Vector3(1.0, -0.15, -0.2), Vector3(-0.1, 1.0, 0.0), Vector3(-1.0, 0.0, 0.0), 85.0]    # 屈肘秀肌肉
const G_BEHIND := [Vector3(5.0, 51.0, -8.5), Vector3(0.7, -0.2, -1.0), Vector3(-0.3, -1.0, 0.0), Vector3(0.0, 0.0, -1.0), 30.0]  # 手背在身后
const G_HELM := [Vector3(18.0, 82.5, 3.0), Vector3(1.0, -0.3, -0.4), Vector3(-0.2, 1.0, 0.1), Vector3(-1.0, 0.0, 0.1), 20.0]     # 扶头盔/护目镜
const G_PUSH := [Vector3(4.5, 60.0, 16.0), Vector3(1.0, -0.5, -0.3), Vector3(-1.0, 0.2, 0.0), Vector3(0.0, 0.0, 1.0), 40.0]       # 十指交叉往前推
const G_BRANCH := [Vector3(23.0, 75.0, 2.0), Vector3(0.6, -0.5, -0.8), Vector3(0.7, 0.7, 0.1), Vector3(0.0, -0.3, 1.0), 10.0]     # 树枝一样举起


## 在一串手势之间按时间插值：keys = [[t, 手势], ...]
func _hand_keys(p, side: String, keys: Array, t: float) -> void:
	if t <= float(keys[0][0]):
		_hand_mix(p, side, keys[0][1], keys[0][1], 0.0)
		return
	for i in range(keys.size() - 1):
		var t0: float = keys[i][0]
		var t1: float = keys[i + 1][0]
		if t <= t1:
			_hand_mix(p, side, keys[i][1], keys[i + 1][1], Lib.smooth((t - t0) / (t1 - t0)))
			return
	_hand_mix(p, side, keys[-1][1], keys[-1][1], 1.0)


## 眨一只眼(side 那只闭上，另一只睁着)
func _wink(p, side: String) -> void:
	var other: String = "L" if side == "R" else "R"
	p.scale_("Eyelid_" + side, Vector3(1, 1, 1))
	p.move("Eyelid_" + side, Vector3(0, 0, 3.2))
	p.scale_("Eyelid_" + other, Vector3(1, 0.001, 1))


func fidget_berserker(t: float, p) -> void:
	p.reset()
	_stow(p)
	var flex: float = kf_f([[0.0, 0.0], [1.5, 0.0], [1.9, 1.0, "o"], [2.7, 1.0], [3.4, 0.0]], t)
	var hit: float = kf_f([[0.0, 0.0], [0.42, 0.0], [0.5, 1.0, "o"], [0.75, 0.0]], t)
	var neck: float = kf_f([[0.0, 0.0], [0.8, 0.0], [1.0, 16.0], [1.15, 16.0], [1.35, -16.0], [1.5, -16.0], [1.7, 0.0]], t)
	_base(p, 0.0, -1.2 * hit - 1.0 * flex, 0.0, 6.0 * hit - 7.0 * flex, 0.0, 0.0, 7.5, 0.0, 0.0)
	_head(p, 4.0 * hit - 6.0 * flex, 0.0, neck)
	# 右拳砸进左掌(两手都在胸前正中附近，不交叉)
	var palm := [Vector3(3.5, 58.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.3, 0.2, 1.0), Vector3(-1.0, 0.0, 0.0), 10.0]
	var fist := [Vector3(1.5, 59.0, 13.5), Vector3(1.0, -0.6, -0.2), Vector3(0.2, 0.0, 1.0), Vector3(1.0, 0.0, 0.0), 88.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.35, palm], [0.9, palm], [1.3, G_RELAX], [1.5, G_RELAX], [1.9, G_FLEX], [2.7, G_FLEX], [3.4, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.35, fist], [0.9, fist], [1.3, G_RELAX], [1.5, G_RELAX], [1.9, G_FLEX], [2.7, G_FLEX], [3.4, G_RELAX]], t)
	set_lids(p, blink_k(t, 2.9))


func victory_berserker(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var pump: float = 0.5 + 0.5 * sin(2.0 * th)
	_base(p, 0.0, -2.2 + 0.8 * pump, 0.0, -9.0, 0.0, 0.0, 8.5, 0.0, 0.0)
	_head(p, -14.0 + 2.0 * pump, 0.0, 3.0 * sin(6.0 * th))
	for side: String in ["L", "R"]:
		var up: Array = G_FIST_UP.duplicate()
		up[0] = Vector3(19.5, 79.0 + 2.5 * pump, 4.0)
		_hand_mix(p, side, up, up, 0.0)
	set_lids(p, 0.0)


func fidget_darkknight(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [2.3, 0.0], [2.7, -34.0, "o"], [3.2, -34.0], [3.75, 0.0]], t)
	var gaze: float = kf_f([[0.0, 0.0], [1.2, 0.0], [1.5, 1.0], [2.2, 1.0], [2.5, 0.0]], t)
	_base(p, 0.0, 0.0, 0.3 * look, 0.0, 0.0, 0.0, 7.0, 0.5, 0.0)
	_head(p, 12.0 * gaze, 12.0 * gaze + 0.7 * look, 0.0)
	# 右手抓住右肩前的披风边 → 往后一甩
	var grab := [Vector3(13.5, 62.0, 7.5), Vector3(0.6, -1.0, 0.0), Vector3(0.0, 0.3, 1.0), Vector3(-1.0, 0.0, 0.0), 70.0]
	var sweep := [Vector3(20.0, 60.0, 1.0), Vector3(0.6, -0.7, -0.6), Vector3(1.0, -0.2, 0.0), Vector3(0.0, 0.0, -1.0), 40.0]
	var flung := [Vector3(19.0, 55.0, -6.0), Vector3(0.6, -0.3, -1.0), Vector3(0.3, -0.6, -1.0), Vector3(0.0, 0.0, -1.0), 20.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, grab], [0.55, grab], [0.85, sweep], [1.1, flung], [1.5, G_RELAX]], t)
	# 左手抬到胸前，翻看手甲
	var turn: float = clampf((t - 1.5) / 0.7, 0.0, 1.0)
	var look_hand := [Vector3(7.0, 60.0, 14.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 0.6, 1.0), Vector3(-0.8 + 1.6 * turn, 0.3, -0.2), 55.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [1.2, G_RELAX], [1.5, look_hand], [2.2, look_hand], [2.55, G_RELAX]], t)
	set_lids(p, blink_k(t, 3.3))


func victory_darkknight(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.0, 0.35 * sin(th), 0.0, -2.0, 0.0, 0.0, 5.5, 0.0, 0.0)
	_head(p, -5.0 + 1.0 * sin(th), 0.0, 0.0)
	# 右拳按在胸口(手在身体中线略偏左的正前方)
	_hand(p, "R", Vector3(-0.5, 61.5, 14.0), Vector3(1.0, -0.8, 0.1), Vector3(-0.9, 0.3, 0.1), Vector3(0.0, 0.0, -1.0), 88.0)
	_relax(p, "L", 0.4 * sin(th))
	set_lids(p, 0.0)


func fidget_warrior(t: float, p) -> void:
	p.reset()
	_stow(p)
	var helm: float = kf_f([[0.0, 0.0], [0.55, 1.0], [1.25, 1.0], [1.7, 0.0]], t)
	var wig: float = kf_f([[0.0, 0.0], [0.6, 0.0], [0.8, 8.0], [1.0, -6.0], [1.2, 0.0]], t)
	var shift: float = kf_f([[0.0, 0.0], [1.8, 0.0], [2.2, 2.6], [2.5, 2.6], [2.9, -2.6], [3.2, -2.6], [3.6, 0.0]], t)
	var shrug: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.3, 1.0], [2.5, 0.0], [2.8, 1.0], [3.0, 0.0]], t)
	_base(p, shift, 0.0, 0.0, 0.0, -shift, 0.0, 7.0, 0.0, 0.0)
	_head(p, -2.0 * helm, 0.0, wig + shift * 1.5)
	p.radd("Shoulder_L", 0, 0, 6.0 * shrug)
	p.radd("Shoulder_R", 0, 0, -6.0 * shrug)
	for side: String in ["L", "R"]:
		_hand_mix(p, side, G_RELAX, G_HELM, helm)
	set_lids(p, 0.0)


func victory_warrior(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var thump: float = kf_f([[0.0, 0.0], [0.12, 1.0, "o"], [0.4, 0.0], [1.0, 0.0], [1.12, 1.0, "o"], [1.4, 0.0], [2.0, 0.0]], t)
	_base(p, 0.0, 0.4 * sin(2.0 * th), 0.0, -4.0 + 3.0 * thump, 0.0, 0.0, 7.5, 0.0, 0.0)
	_head(p, -6.0, 0.0, 0.0)
	_hand_mix(p, "R", G_FIST_UP, G_FIST_UP, 0.0)
	# 左拳捶左胸
	var chest := [Vector3(4.5, 61.0 - 1.0 * thump, 11.0 - 1.5 * thump), Vector3(1.0, -0.8, -0.1), Vector3(-0.8, 0.3, 0.2), Vector3(0.0, 0.0, -1.0), 88.0]
	_hand_mix(p, "L", chest, chest, 0.0)
	set_lids(p, 0.0)


func fidget_magi(t: float, p) -> void:
	p.reset()
	_stow(p)
	var rock: float = kf_f([[0.0, 0.0], [0.6, 0.0], [1.0, 1.0], [2.3, 1.0], [2.5, 0.0]], t)
	var tip: float = (0.5 - 0.5 * cos(TAU * t / 0.9)) * rock
	var tilt: float = kf_f([[0.0, 0.0], [0.7, 0.0], [1.0, 12.0], [1.5, 12.0], [1.8, -10.0], [2.2, -10.0], [2.5, 0.0]], t)
	var wave: float = kf_f([[0.0, 0.0], [2.5, 0.0], [2.8, 1.0], [3.4, 1.0], [3.9, 0.0]], t)
	_base(p, 0.0, 0.0, 0.0, 2.0 * rock, 0.0, 0.0, 4.5, 0.0, 0.6 * tip)
	_head(p, 2.0, 0.0, tilt + 6.0 * wave)
	var wv := [Vector3(19.0, 79.5, 4.0), Vector3(1.0, -0.3, -0.5), Vector3(0.4 * sin(t * 18.0), 1.0, 0.0), Vector3(0.0, 0.0, 1.0), 6.0]
	# 手绕到身后要从胯外侧过去(不穿过胯)
	var outside := [Vector3(15.5, 49.0, -5.0), Vector3(0.7, -0.3, -1.0), Vector3(-0.1, -1.0, -0.2), Vector3(-0.5, 0.0, -0.8), 20.0]
	var side_up := [Vector3(22.0, 66.0, 2.0), Vector3(1.0, -0.6, -0.4), Vector3(0.6, 0.6, 0.2), Vector3(0.0, -0.3, 1.0), 10.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.3, outside], [0.6, G_BEHIND], [2.5, G_BEHIND], [2.75, outside], [3.05, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.3, outside], [0.6, G_BEHIND], [2.45, G_BEHIND], [2.65, outside], [2.85, side_up], [3.0, wv], [3.4, wv], [3.65, side_up], [3.95, G_RELAX]], t)
	set_lids(p, minf(1.0, blink_k(t, 1.3) + blink_k(t, 3.0)))


func victory_magi(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var hop: float = absf(sin(th)) * 2.5
	_base(p, -1.5, hop, -8.0, -4.0, 4.0, 0.0, 5.5, 0.0, 0.0)
	# 抬起左膝(右脚单脚着地)
	legs(p, Vector3(6.0, ANKLE_Y + 11.0 + hop, 5.0), Vector3(-5.5, ANKLE_Y + hop * 0.6, -0.5), Lib.E(25.0, 6.0, 0.0), Lib.E(0.0, -6.0, 0.0))
	_head(p, -4.0, -6.0, -9.0)
	var point := [Vector3(19.5, 81.5, 5.0), Vector3(1.0, -0.2, -0.4), Vector3(0.15, 1.0, 0.2), Vector3(-0.3, 0.0, 1.0), 45.0]
	_hand_mix(p, "R", point, point, 0.0)
	_on_hip(p, "L")
	_wink(p, "L")


func fidget_bounty(t: float, p) -> void:
	p.reset()
	_stow(p)
	var up: float = kf_f([[0.0, 0.0], [0.55, 0.0], [0.95, 1.0, "o"], [1.3, 0.0, "i"]], t)
	var down: float = kf_f([[0.0, 0.0], [0.3, 1.0], [1.5, 1.0], [1.8, 0.0]], t)
	var hips: float = kf_f([[0.0, 0.0], [1.7, 0.0], [2.1, 1.0], [3.2, 1.0], [3.6, 0.0]], t)
	var scan: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.5, 28.0], [2.8, 28.0], [3.1, -20.0], [3.4, 0.0]], t)
	_base(p, 1.5 * hips, 0.0, 0.0, 0.0, 0.0, 0.0, 6.8, -1.0 * hips, 0.0)
	_head(p, -16.0 * up + 6.0 * down * (1.0 - up), scan, 0.0)
	# 右手：掌心朝上 → 往上一弹 → 攥住 → 叉腰
	var palm_up := [Vector3(7.0, 57.0, 12.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.0, 1.0), Vector3(0.0, 1.0, 0.0), 25.0]
	var flick := [Vector3(7.5, 60.5, 13.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.5, 1.0), Vector3(0.0, 1.0, -0.3), 10.0]
	var catch := [Vector3(7.0, 58.0, 12.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.0, 1.0), Vector3(0.0, 1.0, 0.0), 80.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, palm_up], [0.55, palm_up], [0.62, flick], [1.2, flick], [1.35, catch], [1.7, catch], [2.1, G_HIP], [3.2, G_HIP], [3.6, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [1.7, G_RELAX], [2.1, G_HIP], [3.2, G_HIP], [3.6, G_RELAX]], t)
	set_lids(p, blink_k(t, 1.9))


func victory_bounty(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var bang: float = kf_f([[0.0, 0.0], [0.08, 1.0, "o"], [0.4, 0.0], [2.0, 0.0]], t)
	_base(p, 1.8, 0.3 * sin(2.0 * th), 10.0, -2.0, -2.0, 0.0, 7.0, 1.5, 0.0)
	_head(p, -2.0, -8.0, -7.0 + 1.0 * sin(th))
	_on_hip(p, "L")
	# 右手比枪指向前方，"砰"时往上一抬
	var gun := [Vector3(8.5, 64.0 + 3.0 * bang, 17.0 - 1.0 * bang), Vector3(1.0, -0.5, -0.3), Vector3(-0.1, 0.25 * bang, 1.0), Vector3(-1.0, 0.0, 0.0), 60.0]
	_hand_mix(p, "R", gun, gun, 0.0)
	_wink(p, "L")


func fidget_shielder(t: float, p) -> void:
	p.reset()
	_stow(p)
	var gog: float = kf_f([[0.0, 0.0], [0.5, 1.0], [1.3, 1.0], [1.6, 0.0]], t)
	var shake: float = kf_f([[0.0, 0.0], [1.55, 0.0], [1.65, 1.0], [2.1, 1.0], [2.2, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.6, 1.0, "o"], [3.2, 1.0], [3.75, 0.0]], t)
	_base(p, 0.0, 0.0, 0.0, 5.0 * push, 0.0, 0.0, 6.2, 0.0, 0.3 * push)
	_head(p, -3.0 * gog + 4.0 * push, 0.0, 10.0 * sin(t * 30.0) * shake)
	for side: String in ["L", "R"]:
		_hand_keys(p, side, [[0.0, G_RELAX], [0.5, G_HELM], [1.3, G_HELM], [1.6, G_RELAX], [2.2, G_RELAX], [2.6, G_PUSH], [3.2, G_PUSH], [3.75, G_RELAX]], t)
	set_lids(p, minf(1.0, kf_f([[0.0, 0.0], [2.5, 0.0], [2.6, 1.0], [3.1, 1.0], [3.2, 0.0]], t) + shake))


func victory_shielder(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = maxf(0.0, sin(th)) * 7.0
	_base(p, 0.0, hop, 0.0, -5.0, 0.0, 0.0, 6.0, 0.0, 0.0)
	legs(p, Vector3(6.0, ANKLE_Y + hop * 0.75, -0.5 - 0.3 * hop), Vector3(-6.0, ANKLE_Y + hop * 0.75, -0.5 - 0.3 * hop), Lib.E(10.0 * hop / 7.0, 6, 0), Lib.E(10.0 * hop / 7.0, -6, 0))
	_head(p, -8.0, 0.0, 4.0 * sin(th))
	for side: String in ["L", "R"]:
		var up: Array = G_FIST_UP.duplicate()
		up[0] = Vector3(19.0, 79.0 + 0.3 * hop, 4.0)
		_hand_mix(p, side, up, up, 0.0)
	set_lids(p, 0.0)


func fidget_vine(t: float, p) -> void:
	p.reset()
	_stow(p)
	var raise: float = kf_f([[0.0, 0.0], [0.9, 1.0], [2.5, 1.0], [3.0, 0.0]], t)
	var sway: float = sin(TAU * t / 1.6) * kf_f([[0.0, 0.0], [0.9, 1.0], [2.5, 1.0], [2.9, 0.0]], t)
	var lift: float = kf_f([[0.0, 0.0], [3.0, 0.0], [3.3, 1.0, "o"], [3.45, 0.0, "i"], [4.0, 0.0]], t)
	var stomp: float = kf_f([[0.0, 0.0], [3.45, 0.0], [3.5, 1.0], [3.8, 0.0]], t)
	_base(p, 1.2 * sway, -0.8 * stomp, 0.0, 0.0, 8.0 * sway, 0.0, 7.5, 0.0, 0.0)
	legs(p, Vector3(7.5, ANKLE_Y + 7.0 * lift, -0.5 + 2.0 * lift), Vector3(-7.5, ANKLE_Y, -0.5), Lib.E(0, 6, 0), Lib.E(0, -6, 0))
	for side: String in ["L", "R"]:
		_hand_mix(p, side, G_RELAX, G_BRANCH, raise)
	set_lids(p, 0.0)


func victory_vine(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 1.4 * sin(th), 0.5 * sin(2.0 * th), 0.0, -3.0, 7.0 * sin(th), 0.0, 8.0, 0.0, 0.0)
	var high: Array = G_BRANCH.duplicate()
	high[0] = Vector3(21.0, 79.0, 3.0)
	for side: String in ["L", "R"]:
		_hand_mix(p, side, high, high, 0.0)
	set_lids(p, 0.0)


# =============================================================== peasant 耕植节点：抹汗 → 撑腰伸懒腰 → 点头 (4.0s)；胜利 = 叉腰举拳蹦
const G_BROW := [Vector3(6.5, 84.0, 12.5), Vector3(1.0, -0.2, -0.5), Vector3(-1.0, 0.15, 0.0), Vector3(0.0, 0.0, -1.0), 30.0]      # 手背贴着额头
const G_BROW2 := [Vector3(-2.0, 84.5, 13.0), Vector3(1.0, -0.2, -0.5), Vector3(-1.0, 0.1, 0.0), Vector3(0.0, 0.0, -1.0), 30.0]    # 抹到另一边
const G_BACK := [Vector3(9.5, 48.5, -6.5), Vector3(0.8, -0.1, -0.8), Vector3(-0.3, -0.8, 0.2), Vector3(0.2, 0.0, -1.0), 40.0]      # 撑着后腰


func fidget_peasant(t: float, p) -> void:
	p.reset()
	_stow(p)
	var wipe: float = kf_f([[0.0, 0.0], [0.45, 1.0], [1.25, 1.0], [1.5, 0.0]], t)
	var arch: float = kf_f([[0.0, 0.0], [1.5, 0.0], [2.0, 1.0, "o"], [2.9, 1.0], [3.3, 0.0]], t)
	var nod: float = kf_f([[0.0, 0.0], [3.2, 0.0], [3.4, 1.0], [3.6, 0.0], [3.75, 0.6], [4.0, 0.0]], t)
	_base(p, 0.0, -0.8 * arch, 0.0, -11.0 * arch + 3.0 * wipe, 0.0, 0.0, 7.0, 0.0, 0.0)
	_head(p, 6.0 * wipe - 16.0 * arch + 10.0 * nod, 0.0, 4.0 * wipe)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.45, G_BROW], [0.75, G_BROW], [1.15, G_BROW2], [1.5, G_RELAX], [2.0, G_BACK], [2.9, G_BACK], [3.3, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [1.5, G_RELAX], [2.0, G_BACK], [2.9, G_BACK], [3.3, G_RELAX]], t)
	set_lids(p, maxf(arch, blink_k(t, 3.5)))


func victory_peasant(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = maxf(0.0, sin(th)) * 5.0
	var pump: float = maxf(0.0, sin(th))
	_base(p, 0.0, hop, 6.0, -4.0, 0.0, 0.0, 6.5, 0.0, 0.0)
	legs(p, Vector3(6.5, ANKLE_Y + hop * 0.8, -0.5), Vector3(-6.5, ANKLE_Y + hop * 0.8, -0.5), Lib.E(8.0 * hop / 5.0, 6, 0), Lib.E(8.0 * hop / 5.0, -6, 0))
	_head(p, -6.0, -6.0, -8.0 + 3.0 * sin(th))
	_on_hip(p, "L")
	var fist: Array = G_FIST_UP.duplicate()
	fist[0] = Vector3(18.0, 74.0 + 7.0 * pump, 4.0 + 1.5 * pump)
	_hand_mix(p, "R", fist, fist, 0.0)
	set_lids(p, 0.0)



# =============================================================== student(求知节点：眼镜 + 光环的学生)
const G_GLASSES := [Vector3(2.0, 80.0, 14.5), Vector3(1.0, -0.4, -0.3), Vector3(-0.1, 1.0, 0.25), Vector3(0.0, 0.1, -1.0), 70.0]    # 食指推眼镜
const G_CHIN := [Vector3(3.5, 75.0, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.3, 0.9, 0.3), Vector3(0.0, 0.3, -1.0), 75.0]       # 拳头托腮
const G_CRADLE := [Vector3(-3.5, 58.5, 10.0), Vector3(1.0, -0.4, -0.2), Vector3(-1.0, 0.0, 0.1), Vector3(0.0, 1.0, 0.2), 30.0]     # 横在身前托住另一只手肘
const G_CLAP_OPEN := [Vector3(8.5, 64.5, 13.0), Vector3(1.0, -0.8, 0.0), Vector3(0.0, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 4.0]    # 拍手前(双掌相对分开)
const G_CLAP := [Vector3(2.2, 64.5, 13.5), Vector3(1.0, -0.8, 0.0), Vector3(0.0, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 4.0]         # 拍手(双掌相合)


## 把咒语念出来！(触发器触发时 BattleView 放，0.8s)：右手把书一下子举到脸前(书面朝自己)，低头念一眼，
## 0.2s 左手往前一指(五指张开)、抬头喊出来、身子往前一探，然后收回
func recite_student(t: float, p) -> void:
	p.reset()
	var k: float = kf_f([[0.0, 0.0], [0.1, 1.0, "o"], [0.62, 1.0], [0.8, 0.0]], t)
	var shout: float = kf_f([[0.0, 0.0], [0.14, 0.0], [0.22, 1.0, "o"], [0.5, 1.0], [0.8, 0.0]], t)
	_twist(p, -6.0 * shout, -2.0 + 3.0 * k - 8.0 * shout, 1.0 * shout, 0.5, 0.4)
	_feet(p, 7.0, 1.5 * shout, 0.0, -1.0, 0.0, 8.0, -10.0)
	var cq: Quaternion = _chest_q(p)
	var grip: Vector3 = Vector3(-12.0, 51.5, 10.5).lerp(Vector3(-7.0, 63.0, 14.5), k)
	hold_bow(p, follow(p, "Chest", grip), grot(cq * Vector3(0.05, -0.55, 0.85), cq * Vector3(0.2, 0.75, -0.6)), _cdir(p, Vector3(-1.0, -0.6, -0.3)))
	fist_r(p, 55.0)
	var lh: Vector3 = Vector3(14.0, 52.0, 5.0).lerp(Vector3(9.5, 64.0, 21.0), shout)
	_hand(p, "L", lh, Vector3(1.0, -0.5, -0.3), Vector3(0.05, 0.25, 1.0), Vector3(0.0, 1.0, -0.2), 2.0 + 12.0 * (1.0 - shout))
	_head(p, 12.0 * k * (1.0 - shout) - 8.0 * shout, 0.0, 0.0)
	set_lids(p, 0.0)


func fidget_student(t: float, p) -> void:
	p.reset()
	_stow(p)
	var push: float = kf_f([[0.0, 0.0], [0.45, 0.0], [0.6, 1.0], [0.75, 0.0]], t)
	var think: float = kf_f([[0.0, 0.0], [0.9, 0.0], [1.3, 1.0, "o"], [2.4, 1.0], [2.65, 0.0]], t)
	var aha: float = kf_f([[0.0, 0.0], [2.55, 0.0], [2.75, 1.0, "o"], [3.3, 1.0], [3.7, 0.0]], t)
	var hop: float = kf_f([[0.0, 0.0], [2.7, 0.0], [2.85, 1.0], [3.0, 0.0]], t)
	var nod: float = 0.5 - 0.5 * cos(TAU * clampf((t - 1.4) / 1.0, 0.0, 1.0))
	_base(p, 0.0, 2.2 * hop - 0.6 * think, 8.0 * think, 3.0 * push + 2.0 * think - 3.0 * aha, 0.0, 0.0, 6.0, 0.0, 0.3 * hop)
	_head(p, 8.0 * push - 12.0 * think + 3.0 * nod * think - 8.0 * aha, 10.0 * think, 11.0 * think - 4.0 * aha)
	var gl_up: Array = G_GLASSES.duplicate()
	gl_up[0] = G_GLASSES[0] + Vector3(0.0, 1.6, 0.0)
	# "有了！"：拍一下手(张开 → 合上 → 弹开一点 → 放下)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, G_GLASSES], [0.6, gl_up], [0.85, G_GLASSES], [1.3, G_CHIN], [2.4, G_CHIN],
		[2.62, G_CLAP_OPEN], [2.78, G_CLAP], [3.25, G_CLAP], [3.45, G_CLAP_OPEN], [3.9, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.9, G_RELAX], [1.3, G_CRADLE], [2.4, G_CRADLE],
		[2.62, G_CLAP_OPEN], [2.78, G_CLAP], [3.25, G_CLAP], [3.45, G_CLAP_OPEN], [3.9, G_RELAX]], t)
	set_lids(p, maxf(0.75 * aha, minf(1.0, blink_k(t, 0.62) + blink_k(t, 3.75))))


## 胜利：左手叉腰，右手食指推着眼镜、下巴一抬(得意)，一颠一颠；眨一只眼
func victory_student(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var bounce: float = absf(sin(th * 2.0)) * 1.8
	var push: float = 0.5 - 0.5 * cos(th * 2.0)
	_base(p, 0.8 * sin(th), bounce, -8.0, -5.0, 3.0 * sin(th), 0.0, 6.0, 0.0, 0.0)
	_head(p, -10.0, -6.0, 6.0 + 3.0 * sin(th))
	_on_hip(p, "L")
	var gl: Array = G_GLASSES.duplicate()
	gl[0] = G_GLASSES[0] + Vector3(0.0, 1.2 * push, 0.4)
	_hand_mix(p, "R", gl, gl, 0.0)
	_wink(p, "L")


# =============================================================== witch(灾星节点：猫耳魔女)
const G_PALM_UP := [Vector3(8.0, 58.5, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.25, 1.0), Vector3(0.0, 1.0, 0.0), 22.0]     # 摊开手掌托着一团火
const G_PALM_FIST := [Vector3(8.0, 58.5, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.25, 1.0), Vector3(0.0, 1.0, 0.0), 85.0]
const G_HAIR := [Vector3(12.5, 79.5, -3.5), Vector3(1.0, -0.2, -0.6), Vector3(-0.3, -0.2, -1.0), Vector3(-1.0, 0.0, 0.0), 18.0]     # 把头发往肩后撩
const G_FIREBALL := [Vector3(17.5, 66.0, 5.0), Vector3(1.0, -0.5, -0.4), Vector3(0.0, 0.3, 1.0), Vector3(0.0, 1.0, 0.0), 28.0]    # 肩旁托着火球


func fidget_witch(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.5, 1.0, "o"], [1.7, 1.0], [2.0, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.45, 1.0, "o"], [2.75, 1.0], [3.2, 0.0]], t)
	var smug: float = kf_f([[0.0, 0.0], [2.4, 0.0], [2.6, 1.0], [3.4, 1.0], [3.8, 0.0]], t)
	_base(p, 0.0, 0.0, -6.0 * look + 5.0 * flick, 2.0 * look - 3.0 * flick, 4.0 * flick, 0.0, 6.0, 0.0, 0.0)
	_head(p, 14.0 * look - 8.0 * flick, -10.0 * look + 6.0 * flick, -4.0 * look + 10.0 * flick)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.5, G_PALM_UP], [1.4, G_PALM_UP], [1.6, G_PALM_FIST], [2.0, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [2.1, G_RELAX], [2.45, G_HAIR], [2.75, G_HAIR], [3.2, G_RELAX]], t)
	set_lids(p, maxf(0.55 * smug, blink_k(t, 1.1)))


func victory_witch(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.9 * sin(th), 0.6 * sin(th * 2.0), 8.0, -3.0, 3.0 * sin(th), 0.0, 6.0, 0.0, 0.0)
	_head(p, -6.0, 8.0, -7.0 + 3.0 * sin(th))
	_on_hip(p, "L")
	var fb: Array = G_FIREBALL.duplicate()
	fb[0] = G_FIREBALL[0] + Vector3(0.0, 0.8 * sin(th * 2.0), 0.0)
	_hand_mix(p, "R", fb, fb, 0.0)
	_wink(p, "R")


# =============================================================== druid(和星节点：长须的精灵德鲁伊，男性款)
const G_BEARD_TOP := [Vector3(2.5, 74.0, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, -0.6, 0.8), Vector3(0.0, 0.0, -1.0), 45.0]   # 捏着胡子根
const G_BEARD_LOW := [Vector3(2.0, 66.5, 14.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, -0.8, 0.6), Vector3(0.0, 0.0, -1.0), 60.0]   # 捋到胡子尖
const G_CHEST := [Vector3(4.0, 61.0, 11.5), Vector3(1.0, -0.5, -0.4), Vector3(-1.0, 0.2, 0.2), Vector3(0.0, 0.0, -1.0), 20.0]        # 按在胸口
const G_BLESS := [Vector3(19.0, 74.0, 6.0), Vector3(1.0, -0.4, -0.5), Vector3(0.2, 0.5, 1.0), Vector3(0.0, 1.0, 0.0), 10.0]          # 掌心朝天举起


func fidget_druid(t: float, p) -> void:
	p.reset()
	_stow(p)
	var stroke: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.8, 1.0], [2.1, 0.0]], t)
	var back: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.5, 1.0], [3.6, 1.0], [3.95, 0.0]], t)
	var rock: float = sin(clampf((t - 2.5) / 1.1, 0.0, 1.0) * TAU) * back
	var nod: float = kf_f([[0.0, 0.0], [0.9, 0.0], [1.05, 1.0], [1.2, 0.0], [1.35, 0.7], [1.5, 0.0]], t)
	_base(p, 0.0, 0.0, 0.0, 3.0 * stroke - 2.0 * back, 0.0, 0.0, 7.0, 0.0, 0.25 * maxf(0.0, rock))
	_head(p, 8.0 * stroke + 10.0 * nod - 6.0 * back, -6.0 * stroke, 3.0 * stroke)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, G_BEARD_TOP], [0.8, G_BEARD_LOW], [1.0, G_BEARD_TOP], [1.4, G_BEARD_LOW], [1.8, G_BEARD_LOW],
		[2.1, G_RELAX], [2.5, G_BEHIND], [3.6, G_BEHIND], [3.95, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [2.1, G_RELAX], [2.5, G_BEHIND], [3.6, G_BEHIND], [3.95, G_RELAX]], t)
	set_lids(p, maxf(0.4 * stroke, blink_k(t, 3.0)))


func victory_druid(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.6 * sin(th), 0.4 * sin(th * 2.0), 4.0, -2.0, 0.0, 0.0, 7.0, 0.0, 0.0)
	_head(p, 6.0 + 6.0 * maxf(0.0, sin(th)), 0.0, 2.0 * sin(th))
	var bl: Array = G_BLESS.duplicate()
	bl[0] = G_BLESS[0] + Vector3(0.0, 0.8 * sin(th), 0.0)
	_hand_mix(p, "R", bl, bl, 0.0)
	_hand_mix(p, "L", G_CHEST, G_CHEST, 0.0)
	set_lids(p, 0.55)



# =============================================================== 大罪的余烬(第一章·红之章的普通怪物)
## 愤怒 / 怠惰是人形(用人形的手势工具)；色欲(一团触手)和暴食(熔岩肉山)不是人形：骨头只是触手、嘴、胳膊的转轴，
## 动作直接写各骨头的转角。所有循环动作的频率都是 2π/时长 的整数倍(首尾接得上)。
const EMBER_TABLE := {
	"fidget_ember_wrath": [4.0, false], "victory_ember_wrath": [2.4, true],
	"fidget_ember_sloth": [3.6, false], "victory_ember_sloth": [2.0, true],
	"fidget_ember_lust": [3.6, false], "victory_ember_lust": [2.4, true],
	"fidget_ember_glut": [4.0, false], "victory_ember_glut": [2.4, true],
	"idle_lust": [2.4, true], "run_lust": [0.8, true], "attack_lust": [20.0 / 30.0, false],
	"idle_glut": [2.4, true], "run_glut": [0.8, true], "attack_glut": [20.0 / 30.0, false],
}


# =============================================================== 狩胜节点(角斗士)
## 小动作：右拳往左掌里一砸、扭扭手腕，再双臂抱在胸前、扬起下巴睥睨四周(半闭眼)；胜利：左手叉腰、右拳高举向观众一下下挥，转头左右致意 + 眨眼
func fidget_gladiator(t: float, p) -> void:
	p.reset()
	_stow(p)
	var hit: float = kf_f([[0.0, 0.0], [0.42, 0.0], [0.5, 1.0, "o"], [0.75, 0.0]], t)
	var cross: float = kf_f([[0.0, 0.0], [1.4, 0.0], [1.8, 1.0, "o"], [3.3, 1.0], [3.8, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [1.9, 0.0], [2.3, -22.0], [2.6, -22.0], [2.95, 20.0], [3.2, 20.0], [3.5, 0.0]], t)
	_base(p, 0.6 * sin(t * 1.6), -1.0 * hit, 0.0, 5.0 * hit - 5.0 * cross, 0.0, 0.0, 7.5, 1.0 * cross, 0.0)
	_head(p, 4.0 * hit - 10.0 * cross, look, 0.0)
	var palm := [Vector3(3.5, 58.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.3, 0.2, 1.0), Vector3(-1.0, 0.0, 0.0), 10.0]
	var fist := [Vector3(1.5, 59.0, 13.5), Vector3(1.0, -0.6, -0.2), Vector3(0.2, 0.0, 1.0), Vector3(1.0, 0.0, 0.0), 88.0]
	# 抱臂：两手都在胸前正中附近(Q 版短手够不到对侧手肘)，左手在下托着，右手搭在上面
	var arm_l := [Vector3(-3.5, 53.5, 11.5), Vector3(1.0, -0.7, -0.1), Vector3(-1.0, 0.1, 0.1), Vector3(0.0, 1.0, 0.2), 40.0]
	var arm_r := [Vector3(-4.0, 57.5, 13.0), Vector3(1.0, -0.6, -0.1), Vector3(-1.0, 0.0, 0.15), Vector3(0.0, -1.0, 0.2), 40.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.35, palm], [0.9, palm], [1.3, G_RELAX], [1.4, G_RELAX], [1.8, arm_l], [3.3, arm_l], [3.8, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.35, fist], [0.9, fist], [1.3, G_RELAX], [1.4, G_RELAX], [1.8, arm_r], [3.3, arm_r], [3.8, G_RELAX]], t)
	set_lids(p, maxf(0.45 * cross, blink_k(t, 1.2)))


func victory_gladiator(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var pump: float = maxf(0.0, sin(2.0 * th))
	_base(p, 0.8 * sin(th), 1.2 * pump, 8.0 * sin(th), -6.0, 0.0, 0.0, 8.0, 1.5, 0.0)
	_head(p, -8.0 - 2.0 * pump, 22.0 * sin(th), 4.0 * sin(th))
	_on_hip(p, "L")
	var up: Array = G_FIST_UP.duplicate()
	up[0] = Vector3(18.5, 78.5 + 3.0 * pump, 4.0 + 1.5 * pump)
	_hand_mix(p, "R", up, up, 0.0)
	if fmod(t, 2.0) > 1.2 and fmod(t, 2.0) < 1.6:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 空白节点(basic)：懵懂的见习节点
## 小动作：低头看自己摊开的两只手心，歪头、再往另一边歪，慢慢眨眼，最后用右手挠挠后脑勺；胜利：两手举到肩旁小小地挥(怯生生的"耶")，歪着头左右晃
func fidget_basic(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.4, 1.0], [2.0, 1.0], [2.4, 0.0]], t)
	var tilt: float = kf_f([[0.0, 0.0], [0.6, 0.0], [0.9, 14.0], [1.4, 14.0], [1.7, -14.0], [2.1, -14.0], [2.5, 0.0], [3.2, 8.0], [4.0, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.5), 0.0, 0.0, 6.0 * look, 0.0, 0.0, 6.5, 0.0, 0.0)
	_head(p, 18.0 * look, 0.0, tilt)
	var palms := [Vector3(7.5, 50.5, 13.0), Vector3(0.8, -0.6, -0.3), Vector3(-0.2, 0.15, 1.0), Vector3(0.0, 1.0, 0.0), 18.0]
	var scratch := [Vector3(10.0, 80.0, -6.0), Vector3(1.0, 0.2, -0.3), Vector3(-0.4, 0.6, -0.6), Vector3(0.0, 0.0, -1.0), 30.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.4, palms], [2.0, palms], [2.4, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, palms], [2.0, palms], [2.5, G_RELAX], [2.9, scratch], [3.5, scratch], [4.0, G_RELAX]], t)
	if t > 2.9 and t < 3.5:
		p.radd("Hand_R", 12.0 * sin(t * 40.0), 0.0, 0.0)
	set_lids(p, maxf(blink_k(t, 1.2), maxf(blink_k(t, 1.8), blink_k(t, 3.0))))


func victory_basic(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.8 * sin(th), 0.6 * absf(sin(2.0 * th)), 0.0, -3.0, 4.0 * sin(th), 0.0, 6.5, 0.0, 0.0)
	_head(p, -4.0, 0.0, 10.0 * sin(th))
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		_hand(p, side, Vector3(16.5, 66.0 + 1.5 * sin(2.0 * th + m), 7.0), Vector3(1.0, -0.6, -0.4),
			Vector3(0.25 * sin(2.0 * th) * m, 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 8.0)
	set_lids(p, blink_k(t, 1.1))


# =============================================================== 清心节点(taoist)：狡黠的狐狸小道士
## 小动作：左手背到身后，右手在脸前竖起剑诀(两指并拢朝上)、闭眼默念，然后往前一点(施符)，甩甩手收回；
## 胜利：左手叉腰，右手剑诀竖在脸旁，歪头 + 眨眼，身子跟着轻轻晃
func fidget_taoist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var seal: float = kf_f([[0.0, 0.0], [0.5, 1.0], [2.2, 1.0], [2.5, 0.0]], t)
	var point: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.45, 1.0, "o"], [2.9, 1.0], [3.4, 0.0]], t)
	_base(p, 0.3 * sin(t * 1.6), 0.0, -10.0 * seal + 8.0 * point, 3.0 * seal + 6.0 * point, 0.0, 0.0, 6.5, 1.5 * point, 0.0)
	_head(p, 6.0 * seal - 4.0 * point, 6.0 * seal, -4.0 * seal)
	var g_seal := [Vector3(-2.5, 70.5, 14.0), Vector3(-1.0, -0.4, -0.3), Vector3(0.0, 1.0, 0.1), Vector3(1.0, 0.0, 0.0), 30.0]
	var g_point := [Vector3(-7.0, 64.0, 19.0), Vector3(-1.0, -0.3, -0.2), Vector3(0.0, 0.3, 1.0), Vector3(1.0, 0.0, 0.0), 30.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.5, g_seal], [2.2, g_seal], [2.45, g_point], [2.9, g_point], [3.4, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.5, G_BEHIND], [2.9, G_BEHIND], [3.4, G_RELAX]], t)
	set_lids(p, 1.0 if t > 0.7 and t < 2.0 else blink_k(t, 3.6))


func victory_taoist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.9 * sin(th), 0.0, -6.0, -3.0, 3.0 * sin(th), 0.0, 6.8, 1.0, 0.0)
	_head(p, -3.0, 6.0, 9.0 + 4.0 * sin(th))
	_on_hip(p, "L")
	_hand(p, "R", Vector3(-11.0, 72.5, 9.0), Vector3(-1.0, -0.5, -0.4), Vector3(0.05, 1.0, 0.15), Vector3(1.0, 0.0, 0.3), 30.0)
	if fmod(t, 2.0) > 1.0 and fmod(t, 2.0) < 1.5:
		_wink(p, "R")
	else:
		set_lids(p, 0.0)


# =============================================================== 浪游节点(cowboy，男性款)：懒散的浪游牛仔
## 小动作：右手两指捏住帽檐往下一压、左右扫一眼，再把右手食指竖到嘴边吹一口(像吹枪口的烟)，甩甩手；
## 胜利：左手拇指勾着腰带，右手把帽子往上一推(露出脸)、再往下压，身子往后一仰轻轻晃 + 眨眼
func fidget_cowboy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var brim: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.6, 1.0], [1.9, 0.0]], t)
	var blow: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.4, 1.0], [3.2, 1.0], [3.6, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [0.6, 0.0], [0.9, 24.0], [1.15, 24.0], [1.45, -22.0], [1.65, -22.0], [1.9, 0.0]], t)
	_base(p, 0.5 * sin(t * 1.3), 0.0, 0.0, -2.0 * brim + 4.0 * blow, 0.0, 0.0, 7.0, 0.0, 0.0)
	_head(p, 10.0 * brim + 6.0 * blow, look, 0.0)
	var g_brim := [Vector3(-6.5, 84.0, 9.0), Vector3(-1.0, -0.2, -0.4), Vector3(0.1, 0.3, 1.0), Vector3(0.0, -1.0, 0.0), 40.0]
	var g_blow := [Vector3(-2.0, 74.5, 13.5), Vector3(-1.0, -0.5, -0.2), Vector3(0.0, 1.0, 0.1), Vector3(0.6, 0.0, 0.8), 70.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, g_brim], [1.6, g_brim], [1.9, G_RELAX], [2.1, G_RELAX], [2.4, g_blow], [3.2, g_blow], [3.6, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.6, G_HIP], [3.2, G_HIP], [3.8, G_RELAX]], t)
	set_lids(p, maxf(0.35 * brim, blink_k(t, 2.0)))


func victory_cowboy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var push: float = maxf(0.0, sin(th))
	_base(p, 0.7 * sin(th), 0.0, 4.0 * sin(th), -8.0, 2.0 * sin(th), 0.0, 7.5, 1.0, 0.0)
	_head(p, -10.0 - 4.0 * push, 0.0, 4.0 * sin(th))
	_on_hip(p, "L")
	var tip := [Vector3(-6.0, 85.0 + 2.0 * push, 8.5 - 1.5 * push), Vector3(-1.0, -0.2, -0.4), Vector3(0.1, 0.4, 1.0), Vector3(0.0, -1.0, 0.0), 40.0]
	_hand_mix(p, "R", tip, tip, 0.0)
	if fmod(t, 2.0) > 0.9 and fmod(t, 2.0) < 1.3:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


func ember_table(t: Dictionary) -> void:
	for nm: String in EMBER_TABLE.keys():
		t[nm] = {"dur": float(EMBER_TABLE[nm][0]), "loop": bool(EMBER_TABLE[nm][1]), "fn": Callable(self, nm)}


# ---------------------------------------------------------------- 愤怒的余烬：看着手里的火 / 把火举过头顶
## 火沿右手的局部 +Z(拇指那一侧)烧：手指朝前、掌心朝里 = 火苗朝上
const G_FLAME := [Vector3(7.0, 64.0, 11.0), Vector3(0.7, -0.5, -0.4), Vector3(0.1, 0.05, 1.0), Vector3(-1.0, 0.0, 0.1), 26.0]      # 托在胸前看着
const G_FLAME_UP := [Vector3(15.5, 87.0, 6.0), Vector3(1.0, -0.2, -0.5), Vector3(0.1, 0.2, 1.0), Vector3(-1.0, 0.0, 0.1), 20.0]     # 举过头顶
const G_FIST := [Vector3(14.5, 50.0, 3.0), Vector3(1.0, -0.1, -0.6), Vector3(0.1, -1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 80.0]


func fidget_ember_wrath(t: float, p) -> void:
	p.reset()
	_stow(p)
	var raise: float = kf_f([[0.0, 0.0], [0.5, 1.0], [2.9, 1.0], [3.5, 0.0]], t)
	var clench: float = kf_f([[0.0, 0.0], [1.8, 0.0], [2.1, 1.0], [2.6, 1.0], [2.9, 0.0]], t)
	_base(p, 0.4 * sin(t * TAU / 4.0), 0.0, -8.0 * raise, 5.0 * raise, 0.0, 0.0, 7.5)
	_head(p, 14.0 * raise, -16.0 * raise, 5.0 * raise)
	_hand_mix(p, "R", G_WR_FIRE, G_FLAME, raise)
	_hand_mix(p, "L", G_RELAX, G_FIST, clench)


func victory_ember_wrath(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.5 * sin(th), 0.6 * sin(th * 2.0), 6.0, -4.0, 0.0, 0.0, 8.0)
	_head(p, -12.0 + 3.0 * sin(th * 2.0), 6.0, 0.0)
	var up: Array = G_FLAME_UP.duplicate()
	up[0] = (G_FLAME_UP[0] as Vector3) + Vector3(0.0, 1.0 * sin(th * 2.0), 0.0)
	_hand_mix(p, "R", up, up, 0.0)
	_hand_mix(p, "L", G_FIST, G_FIST, 0.0)


# ---------------------------------------------------------------- 怠惰的余烬：歪头(像卡住的机器)、低头看炮口 / 把炮举起来
const G_CANNON_UP := [Vector3(12.0, 86.0, 4.0), Vector3(1.0, -0.2, -0.4), Vector3(0.05, 1.0, 0.15), Vector3(-0.3, 0.0, 1.0), 40.0]
const G_CANNON_LOOK := [Vector3(8.0, 60.0, 12.0), Vector3(0.8, -0.5, -0.4), Vector3(0.0, 0.2, 1.0), Vector3(-1.0, 0.0, 0.0), 40.0]


func fidget_ember_sloth(t: float, p) -> void:
	p.reset()
	_stow(p)
	# 0~1.6 秒：脑袋一顿一顿地歪向两边(像卡住)；1.8~3.4 秒：抬起炮口低头看
	var tilt: float = kf_f([[0.0, 0.0], [0.25, 18.0, "o"], [0.6, 18.0], [0.7, -16.0, "o"], [1.2, -16.0], [1.5, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [1.7, 0.0], [2.1, 1.0], [3.1, 1.0], [3.5, 0.0]], t)
	_base(p, 0.0, -0.4 * look, 0.0, 6.0 * look, 0.0, 0.0, 7.5)
	_head(p, 18.0 * look, -10.0 * look, tilt)
	_hand_mix(p, "R", G_RELAX, G_CANNON_LOOK, look)
	_relax(p, "L")


func victory_ember_sloth(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.0, 0.8 * absf(sin(th)), 0.0, -3.0, 2.0 * sin(th), 0.0, 8.0)
	_head(p, -8.0, 8.0 * sin(th), 0.0)
	_hand_mix(p, "R", G_CANNON_UP, G_CANNON_UP, 0.0)
	_hand_mix(p, "L", G_HIP, G_HIP, 0.0)


# ---------------------------------------------------------------- 色欲的余烬：一团蠕动的触手
## [骨头, 摆幅系数, 相位]：每条触手挂在一根骨头上，各自错开相位地摆
const LUST_BONES := [["Head", 1.0, 0.0], ["Neck", 0.7, 1.3], ["UpperArm_L", 1.0, 2.1], ["UpperArm_R", 1.0, 4.4], ["LowerArm_L", 0.9, 0.8],
	["LowerArm_R", 0.9, 3.6], ["Hand_L", 1.1, 5.0], ["Hand_R", 1.1, 1.9], ["Thigh_L", 0.8, 2.9], ["Thigh_R", 0.8, 5.6],
	["Shin_L", 0.9, 0.4], ["Shin_R", 0.9, 3.1], ["Foot_L", 0.6, 4.7], ["Foot_R", 0.6, 1.5], ["Toe_L", 0.7, 2.5], ["Toe_R", 0.7, 5.3],
	["Spine", 0.35, 3.9], ["Fingers_L", 1.2, 0.2], ["Fingers_R", 1.2, 2.7], ["Thumb_L", 1.2, 4.1], ["Thumb_R", 1.2, 0.9]]


## 蠕动：period = 一圈的时长(秒，必须整除动作时长)，amp = 摆幅(度)；lift = 所有触手整体往前扑(+) / 往后仰(-)(度)
func _writhe(p, t: float, period: float, amp: float, lift: float = 0.0) -> void:
	var w: float = TAU / period
	for e: Array in LUST_BONES:
		var k: float = float(e[1])
		var ph: float = float(e[2])
		p.r(str(e[0]), amp * k * sin(w * t + ph) + lift * k, amp * 0.5 * k * sin(w * t + ph * 1.7), amp * 0.8 * k * cos(w * t + ph))


func idle_lust(t: float, p) -> void:
	p.reset()
	_writhe(p, t, 2.4, 9.0)
	p.move("Hips", Vector3(0.0, 0.8 * sin(TAU * t / 2.4), 0.0))


func run_lust(t: float, p) -> void:
	p.reset()
	_writhe(p, t, 0.8, 8.0, 6.0)
	p.move("Hips", Vector3(0.0, 1.2 * absf(sin(TAU * t / 0.8)), 0.0))
	p.radd("Spine", 8.0, 0.0, 0.0)


## 普攻：触手往后一收(0 ~ 0.18 秒)，0.26 秒往前抽打(出手)，再慢慢收回
func attack_lust(t: float, p) -> void:
	p.reset()
	var lash: float = kf_f([[0.0, 0.0], [0.18, -0.45, "o"], [0.26, 1.0, "i"], [0.36, 0.9], [0.66, 0.0]], t)
	_writhe(p, t, 20.0 / 30.0, 5.0)
	for nm: String in ["Head", "Neck", "UpperArm_L", "UpperArm_R", "Thigh_L", "Thigh_R", "Hand_L", "Hand_R"]:
		p.radd(nm, 42.0 * lash, 0.0, 0.0)
	p.radd("Spine", 10.0 * lash, 0.0, 0.0)


func fidget_ember_lust(t: float, p) -> void:
	p.reset()
	_stow(p)
	# 所有触手慢慢往上舒展、张开，再收回来
	var open: float = kf_f([[0.0, 0.0], [1.0, 1.0], [2.4, 1.0], [3.4, 0.0]], t)
	_writhe(p, t, 1.2, 9.0 + 6.0 * open, -14.0 * open)
	p.move("Hips", Vector3(0.0, 1.5 * open, 0.0))


func victory_ember_lust(t: float, p) -> void:
	p.reset()
	_stow(p)
	_writhe(p, t, 0.8, 14.0, -18.0)
	p.move("Hips", Vector3(0.0, 1.5 * absf(sin(TAU * t / 0.8)), 0.0))


# ---------------------------------------------------------------- 暴食的余烬：熔岩肉山(张嘴 = 头往后仰；胳膊往前上方抬 = 绕 X 轴负转)
func _glut_arms(p, sway_l: float, sway_r: float, raise: float) -> void:
	p.r("UpperArm_L", -raise + sway_l, 0.0, 4.0)
	p.r("UpperArm_R", -raise + sway_r, 0.0, -4.0)
	p.r("LowerArm_L", -0.35 * raise + sway_l * 0.4, 0.0, 0.0)
	p.r("LowerArm_R", -0.35 * raise + sway_r * 0.4, 0.0, 0.0)


func idle_glut(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	var breath: float = 0.5 + 0.5 * sin(th)
	p.scale_("Spine", Vector3(1.0 + 0.02 * breath, 1.0 + 0.03 * breath, 1.0 + 0.02 * breath))
	p.move("Hips", Vector3(0.0, -0.6 * breath, 0.0))
	p.r("Head", -8.0 * breath, 2.0 * sin(th), 0.0)
	_glut_arms(p, 4.0 * sin(th), 4.0 * sin(th + 0.8), 0.0)


func run_glut(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 0.8
	p.r("Hips", 0.0, 5.0 * sin(th), 7.0 * sin(th))
	p.move("Hips", Vector3(0.0, 1.4 * absf(sin(th)), 0.0))
	p.r("Spine", 6.0, 0.0, -4.0 * sin(th))
	p.r("Head", -4.0 - 4.0 * absf(sin(th)), 0.0, 0.0)
	_glut_arms(p, 18.0 * sin(th), -18.0 * sin(th), 10.0)


## 普攻：张大嘴、双臂举起(0 ~ 0.2 秒)，0.26 秒双臂砸下 + 一口咬合(出手)，再收回
func attack_glut(t: float, p) -> void:
	p.reset()
	var up: float = kf_f([[0.0, 0.0], [0.2, 1.0, "o"], [0.26, -0.2, "i"], [0.4, -0.15], [0.66, 0.0]], t)
	var bite: float = kf_f([[0.0, 0.0], [0.2, 1.0], [0.26, -0.15, "i"], [0.45, 0.0]], t)
	p.r("Head", -26.0 * bite, 0.0, 0.0)
	p.r("Spine", 6.0 - 10.0 * maxf(up, 0.0) + 14.0 * maxf(-up * 5.0, 0.0), 0.0, 0.0)
	_glut_arms(p, 0.0, 0.0, 100.0 * maxf(up, 0.0) + 40.0 * maxf(-up * 5.0, 0.0))
	p.move("Hips", Vector3(0.0, -1.2 * maxf(-up * 5.0, 0.0), 0.0))


func fidget_ember_glut(t: float, p) -> void:
	p.reset()
	_stow(p)
	# 打一个大哈欠(嘴张到最大)，伸伸胳膊，再咂咂嘴
	var yawn: float = kf_f([[0.0, 0.0], [1.0, 1.0], [2.0, 1.0], [2.5, 0.0]], t)
	var smack: float = kf_f([[0.0, 0.0], [2.6, 0.0], [2.8, 1.0], [3.0, 0.0], [3.2, 1.0], [3.4, 0.0]], t)
	p.r("Head", -32.0 * yawn - 8.0 * smack, 0.0, 4.0 * yawn)
	p.r("Spine", -6.0 * yawn, 0.0, 0.0)
	p.scale_("Spine", Vector3.ONE * (1.0 + 0.04 * yawn))
	_glut_arms(p, 0.0, 0.0, 30.0 * yawn)
	p.radd("UpperArm_L", 0.0, 0.0, 20.0 * yawn)
	p.radd("UpperArm_R", 0.0, 0.0, -20.0 * yawn)


func victory_ember_glut(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	p.r("Head", -24.0 + 8.0 * sin(th * 3.0), 0.0, 0.0)
	p.move("Hips", Vector3(0.0, 1.2 * absf(sin(th * 2.0)), 0.0))
	_glut_arms(p, 22.0 * sin(th * 2.0), -22.0 * sin(th * 2.0), 120.0)


# ---------------------------------------------------------------- 虚荣的余烬(精英)：盘在地上的巨龙
## 翅膀是龙自己控制的(wing_custom：build_anims 不再叠妖精翅膀的扑动)。
## 翅膀骨静止时 = 模型里张开的样子；spread > 0 = 往前张得更开(绕竖轴)，flap > 0 = 翼尖往上(绕前后轴)
const VANITY_TABLE := {
	"fidget_ember_vanity": [4.0, false], "victory_ember_vanity": [2.4, true],
	"idle_vanity": [2.4, true], "run_vanity": [0.8, true], "attack_vanity": [20.0 / 30.0, false], "breath_vanity": [20.0 / 30.0, false],
}


func vanity_table(t: Dictionary) -> void:
	for nm: String in VANITY_TABLE.keys():
		t[nm] = {"dur": float(VANITY_TABLE[nm][0]), "loop": bool(VANITY_TABLE[nm][1]), "fn": Callable(self, nm), "wing_custom": true}


func _vwings(p, spread: float, flap: float) -> void:
	p.r("Wing_L", 0.0, -spread, flap)
	p.r("Wing_R", 0.0, spread, -flap)


## 呼吸：胸口起伏(0..1)
func _vbreathe(p, k: float) -> void:
	p.scale_("Chest", Vector3(1.0 + 0.025 * k, 1.0 + 0.015 * k, 1.0 + 0.03 * k))
	p.r("Spine", -2.0 * k, 0.0, 0.0)


func idle_vanity(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	var k: float = 0.5 + 0.5 * sin(th)
	_vbreathe(p, k)
	p.r("Neck", 3.0 * sin(th), 4.0 * sin(th + 1.0), 0.0)
	p.r("Head", -3.0 * k, 3.0 * sin(th + 0.6), 2.0 * sin(th))
	_vwings(p, 4.0 * sin(th + 0.5), 5.0 * sin(th))
	p.r("UpperArm_L", 2.0 * sin(th), 0.0, 0.0)
	p.r("UpperArm_R", 2.0 * sin(th + 1.2), 0.0, 0.0)


## 移动：身子左右扭着往前滑，翅膀半收着扇
func run_vanity(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 0.8
	p.move("Hips", Vector3(0.0, 1.0 * absf(sin(th)), 0.0))
	p.r("Hips", 4.0, 7.0 * sin(th), 3.0 * sin(th))
	p.r("Spine", 6.0, -6.0 * sin(th), 0.0)
	p.r("Neck", 8.0, -4.0 * sin(th), 0.0)
	p.r("Head", -6.0, 3.0 * sin(th), 0.0)
	_vwings(p, -10.0, 14.0 * sin(th))
	p.r("UpperArm_L", -10.0 + 8.0 * sin(th), 0.0, 0.0)
	p.r("UpperArm_R", -10.0 - 8.0 * sin(th), 0.0, 0.0)


## 爪击(没有虚荣时的普攻)：右爪高高扬起(0 ~ 0.2 秒)，0.26 秒往前下方挥落(出手)，再收回
func attack_vanity(t: float, p) -> void:
	p.reset()
	var up: float = kf_f([[0.0, 0.0], [0.2, 1.0, "o"], [0.26, -0.35, "i"], [0.4, -0.3], [0.66, 0.0]], t)
	var raise: float = maxf(up, 0.0)
	var slash: float = maxf(-up, 0.0) / 0.35
	p.r("UpperArm_R", -95.0 * raise + 20.0 * slash, 0.0, -25.0 * raise)
	p.r("LowerArm_R", -40.0 * raise - 10.0 * slash, 0.0, 0.0)
	p.r("Spine", -4.0 * raise + 8.0 * slash, -12.0 * raise + 14.0 * slash, 0.0)
	p.r("Neck", -6.0 * raise + 10.0 * slash, 0.0, 0.0)
	p.r("Head", -10.0 * raise, 0.0, 0.0)
	_vwings(p, 8.0 * raise - 6.0 * slash, 10.0 * raise)


## 龙息(带着虚荣时的普攻)：吸气、头往后仰(0 ~ 0.2 秒)，0.26 秒头猛地往前探、张开大嘴喷火(出手)，一直张到 0.5 秒再合上
func breath_vanity(t: float, p) -> void:
	p.reset()
	var rear: float = kf_f([[0.0, 0.0], [0.2, 1.0, "o"], [0.26, 0.0, "i"]], t)
	var blow: float = kf_f([[0.0, 0.0], [0.2, 0.0], [0.26, 1.0, "i"], [0.5, 0.9], [0.66, 0.0, "o"]], t)
	_vbreathe(p, rear)
	p.r("Spine", -6.0 * rear + 6.0 * blow, 0.0, 0.0)
	p.r("Neck", -18.0 * rear + 12.0 * blow, 0.0, 0.0)
	p.r("Head", -8.0 * rear - 32.0 * blow, 0.0, 0.0)
	_vwings(p, 14.0 * rear + 10.0 * blow, 18.0 * rear - 6.0 * blow)
	p.r("UpperArm_L", -15.0 * rear, 0.0, 10.0 * blow)
	p.r("UpperArm_R", -15.0 * rear, 0.0, -10.0 * blow)


## 待机小动作：抬起左爪端详金臂环，歪头欣赏，最后得意地抖一抖翅膀
func fidget_ember_vanity(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.6, 1.0], [2.4, 1.0], [3.0, 0.0]], t)
	var tilt: float = kf_f([[0.0, 0.0], [1.0, 0.0], [1.4, 1.0], [1.9, -0.6], [2.4, 0.0]], t)
	var shake: float = kf_f([[0.0, 0.0], [2.9, 0.0], [3.15, 1.0], [3.35, -0.8], [3.55, 0.6], [3.8, 0.0]], t)
	_vbreathe(p, 0.5 + 0.5 * sin(TAU * t / 2.0))
	p.r("UpperArm_L", -45.0 * look, 0.0, -10.0 * look)
	p.r("LowerArm_L", -55.0 * look, -20.0 * look, 0.0)
	p.r("Neck", 10.0 * look, 18.0 * look, 0.0)
	p.r("Head", 6.0 * look, 16.0 * look, 12.0 * tilt)
	_vwings(p, 6.0 * shake, 14.0 * shake + 3.0 * look)


## 胜利：张开双翼仰天长啸
func victory_ember_vanity(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var roar: float = 0.6 + 0.4 * sin(th)
	_vbreathe(p, 0.5 + 0.5 * sin(th * 2.0))
	p.r("Spine", -6.0, 0.0, 0.0)
	p.r("Neck", -20.0 * roar, 0.0, 0.0)
	p.r("Head", -22.0 * roar, 4.0 * sin(th), 0.0)
	_vwings(p, 16.0, 16.0 + 10.0 * sin(th * 2.0))
	p.r("UpperArm_L", -60.0, 0.0, 20.0)
	p.r("UpperArm_R", -60.0, 0.0, -20.0)
	p.r("LowerArm_L", -30.0, 0.0, 0.0)
	p.r("LowerArm_R", -30.0, 0.0, 0.0)


# =============================================================== 炽照节点：拔刀术(刀收在腰间的鞘里；刀鞘挂在髋骨上，见 model_weapons 的 SAYA_*)
# 待机 / 跑动：右手握着刀柄、刀在鞘里(刃朝上)，左手扶着鞘口；拔刀连斩 1 秒一轮：0.3 秒拔刀横斩出手，之后每 0.08 秒一刀，振刀，收刀入鞘。
# 拿的不是炽霞时没有刀鞘，动作照旧(刀"收"在看不见的鞘里)
const Wpn = preload("res://tools/model_weapons.gd")
const IAI_TABLE := {"idle_iaido": [3.2, true], "run_iaido": [20.0 / 30.0, true], "attack_iaido": [1.0, false]}


func samurai_table(t: Dictionary) -> void:
	for nm: String in IAI_TABLE.keys():
		t[nm] = {"dur": float(IAI_TABLE[nm][0]), "loop": bool(IAI_TABLE[nm][1]), "fn": Callable(self, nm)}
	t["attack_iaido"]["fps"] = 60.0                    # 连斩一刀只有 0.08 秒：按 60 帧烘焙


## 当前姿态下的鞘口、鞘的方向(往鞘尾)、刃朝向(世界)
func _saya(p) -> Array:
	var mouth: Vector3 = follow(p, "Hips", Wpn.SAYA_MOUTH)
	var hb: Basis = p.gx[rig.ids["Hips"]].basis.orthonormalized()
	return [mouth, (hb * Wpn.saya_dir()).normalized(), (hb * Wpn.saya_side()).normalized()]


## 刀在鞘里(slide = 已经拔出来多少体素)：握点与刀的朝向
func _sheathed(p, slide: float = 0.0) -> Array:
	var s: Array = _saya(p)
	var d: Vector3 = s[1]
	return [(s[0] as Vector3) - d * (Wpn.KATANA_ENTER + slide), wrot(d, s[2])]


## 左手扣着鞘口(从左外侧握住；鞘往后很快就进了腰带里，手不能再往后，不然会陷进肚子)；back = 往鞘尾方向再挪多少
func _left_on_saya(p, back: float = 0.0) -> void:
	var s: Array = _saya(p)
	var d: Vector3 = s[1]
	var hb: Basis = p.gx[rig.ids["Hips"]].basis.orthonormalized()
	var out: Vector3 = (hb * Vector3(1.0, 0.0, 0.35)).normalized()
	hold_left(p, (s[0] as Vector3) + d * (0.5 + back * 0.4) + out * 2.2, wrot(d, s[2]), Vector3(1.0, -0.6, -0.1))
	fist_l(p, 76.0)


## 拔刀术的架势：上身往前压一点、往左拧(右肩送到前面，右手才够得着左腰的刀柄)，头转回来看前方
func _iai_lean(p, k: float = 1.0) -> void:
	p.radd("Spine", 5.0 * k, 6.0 * k, 0.0)
	p.radd("Chest", 8.0 * k, 12.0 * k, 0.0)
	p.radd("Head", -8.0 * k, -15.0 * k, 0.0)
	p.radd("Shoulder_R", 0.0, 27.0 * k, -7.0 * k)        # 右肩往前送、往下沉一点(手要伸到左腰)


func _arms_idle(p, s1: float, th: float) -> void:
	if cur_kit != "iaido":
		super._arms_idle(p, s1, th)
		return
	_iai_lean(p)
	var sh: Array = _sheathed(p)
	hold_bow(p, sh[0], sh[1], Vector3(-1.0, -0.35, -0.25))
	fist_r(p, 82.0)
	_left_on_saya(p, 0.3 * s1)


func _arms_run(p, s: float, th: float) -> void:
	if cur_kit != "iaido":
		super._arms_run(p, s, th)
		return
	_iai_lean(p, 0.6)
	var sh: Array = _sheathed(p)
	hold_bow(p, sh[0], sh[1], Vector3(-1.0, -0.35, -0.25))
	fist_r(p, 82.0)
	_left_on_saya(p)


func idle_iaido(t: float, p) -> void:
	_set_kit("iaido")
	idle(t, p)


func run_iaido(t: float, p) -> void:
	_set_kit("iaido")
	run(t, p)


## 拔刀连斩的刀路：刀身方向(胸腔局部单位向量，x = 左、y = 上、z = 前)的关键帧，每一刀都在身前划弧、刀尖不朝后也不往腿里扎；
## 关键帧之间用 Catmull-Rom 连成一条光滑的路(相邻两刀首尾相接，转折处是一个小回环而不是折角，手腕的滚转才不会一帧翻过去)。
## 刃口 = 这一刻刀的运动方向(刃领着走)；握点 = 右肩 + "刀身方向往前收一点"× 臂长(手一直在身前)。
## 命中在出手 0.30，之后每 0.08 一刀(追击 2~4 下)，每一刀都在命中那一刻扫过正前方(刀光 + 目标身上的斩光 / 剑痕跟着这一刀的平面)；
## 一刀只有 0.08 秒，所以按 60 帧烘焙(表里 fps)，转折处是小回环：
##   ① 0.30 拔刀横斩(左 → 右) ② 0.38 袈裟斩(右上 → 左下) ③ 0.46 逆袈裟(左下 → 右上，比 ② 陡) ④ 0.54 横斩(右 → 左) ⑤ 0.62 举过头竖劈
##   0.70 血振(往右下一甩) 0.85 刀尖绕到左边、对准鞘口 → 收刀
const IAI_PATH := [
	[0.20, Vector3(0.90, -0.12, 0.42)],     # 刚出鞘：刀尖在左边(齐腰平着出来，别往腿上扫)
	[0.245, Vector3(0.70, -0.06, 0.71)],
	[0.27, Vector3(0.42, -0.04, 0.91)],
	[0.30, Vector3(0.0, -0.04, 1.0)],       # ① 拔刀横斩扫过正前方
	[0.32, Vector3(-0.62, 0.03, 0.78)],
	[0.337, Vector3(-0.86, 0.30, 0.42)],    #    收在右边，往上翻
	[0.352, Vector3(-0.50, 0.78, 0.38)],    #    右上
	[0.38, Vector3(0.0, 0.06, 1.0)],        # ② 袈裟斩：右上 → 左下
	[0.40, Vector3(0.56, -0.55, 0.62)],
	[0.415, Vector3(0.62, -0.72, 0.30)],    #    左下
	[0.43, Vector3(0.30, -0.86, 0.40)],     #    从下面兜过来
	[0.46, Vector3(-0.05, 0.0, 1.0)],       # ③ 逆袈裟：左下 → 右上(比 ② 陡)
	[0.48, Vector3(-0.45, 0.62, 0.64)],
	[0.495, Vector3(-0.70, 0.62, 0.30)],    #    右上
	[0.51, Vector3(-0.88, 0.15, 0.45)],     #    落到右边
	[0.54, Vector3(0.0, 0.06, 1.0)],        # ④ 横斩：右 → 左
	[0.56, Vector3(0.68, 0.16, 0.71)],
	[0.575, Vector3(0.70, 0.50, 0.50)],     #    左上，往头顶举
	[0.592, Vector3(0.15, 0.94, 0.30)],     #    举过头
	[0.62, Vector3(0.0, 0.12, 0.99)],       # ⑤ 竖劈过正前方
	[0.645, Vector3(0.0, -0.62, 0.79)],     #    劈到前下方
	[0.675, Vector3(-0.32, -0.30, 0.90)],
	[0.70, Vector3(-0.76, -0.50, 0.42)],    # 血振：甩到右下
	[0.77, Vector3(-0.72, -0.52, 0.46)],
	[0.81, Vector3(0.10, -0.42, 0.90)],     # 刀尖从右下绕回前面
	[0.85, Vector3(0.88, -0.38, 0.28)],     # 绕到左边(之后对准鞘口插回去)
]
const IAI_ARM := 15.0                   # 右肩到握点(体素)


## 刀身方向(胸腔局部)：关键帧之间按时间均匀走 Catmull-Rom
func _iai_dir(t: float) -> Vector3:
	var n: int = IAI_PATH.size()
	t = clampf(t, float(IAI_PATH[0][0]), float(IAI_PATH[n - 1][0]))
	var i: int = 0
	while i < n - 2 and t > float(IAI_PATH[i + 1][0]):
		i += 1
	var u: float = clampf((t - float(IAI_PATH[i][0])) / maxf(0.001, float(IAI_PATH[i + 1][0]) - float(IAI_PATH[i][0])), 0.0, 1.0)
	var p0: Vector3 = (IAI_PATH[maxi(i - 1, 0)][1] as Vector3).normalized()
	var p1: Vector3 = (IAI_PATH[i][1] as Vector3).normalized()
	var p2: Vector3 = (IAI_PATH[i + 1][1] as Vector3).normalized()
	var p3: Vector3 = (IAI_PATH[mini(i + 2, n - 1)][1] as Vector3).normalized()
	return _cr4(p0, p1, p2, p3, u).normalized()


static func _cr4(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


## 刃口朝向表(胸腔局部)：刃口 = 运动方向，但正负号保持连续 —— 刀来回折返时刃不跟着翻面(否则手腕一帧拧 180°)，
## 起点从"刃朝上"(鞘里的朝向)接过来。按 1/600 秒取样，用的时候线性插值
var _iai_edges: PackedVector3Array = PackedVector3Array()
const IAI_EDGE_DT := 1.0 / 600.0


func _iai_edge(t: float) -> Vector3:
	var t0: float = float(IAI_PATH[0][0])
	var t1: float = float(IAI_PATH[IAI_PATH.size() - 1][0])
	if _iai_edges.is_empty():
		var prev := Vector3(0.0, 1.0, 0.0)
		var k: int = 0
		while t0 + float(k) * IAI_EDGE_DT <= t1 + 1e-6:
			var tk: float = t0 + float(k) * IAI_EDGE_DT
			var d: Vector3 = _iai_dir(tk)
			var m: Vector3 = _iai_dir(minf(tk + 0.004, t1)) - _iai_dir(maxf(tk - 0.004, t0))
			m -= d * m.dot(d)
			if m.length() < 0.004:
				m = prev - d * prev.dot(d)                    # 停住：沿用上一刻
			m = m.normalized()
			if m.dot(prev) < 0.0:
				m = -m
			_iai_edges.append(m)
			prev = m
			k += 1
	var f: float = clampf((t - t0) / IAI_EDGE_DT, 0.0, float(_iai_edges.size() - 1))
	var i: int = int(floor(f))
	var j: int = mini(i + 1, _iai_edges.size() - 1)
	return _iai_edges[i].lerp(_iai_edges[j], f - float(i))


## 某一时刻刀的握点(世界)与朝向
func _iai_swing(p, t: float) -> Array:
	var d: Vector3 = _iai_dir(t)
	var e: Vector3 = _iai_edge(t)
	e = (e - d * e.dot(d)).normalized()
	var cq: Quaternion = _chest_q(p)
	var a: Vector3 = (d + Vector3(0.0, 0.0, 0.85)).normalized()
	p.fk()
	var grip: Vector3 = p.gpos_n("UpperArm_R") + cq * a * IAI_ARM
	return [grip, cq * wrot(d, e)]


func attack_iaido(t: float, p) -> void:
	p.reset()
	# ---- 身体：沉身蓄势(往右拧着收) → 拔刀横斩时一下拧到左 → 连斩跟着刀左右摆 → 血振 → 起身收刀
	var yaw: float = kf_f([[0.0, 12.0], [0.18, 22.0, "o"], [0.22, 18.0], [0.30, -18.0, "i"], [0.337, -24.0], [0.38, 4.0], [0.415, 12.0],
		[0.46, -8.0], [0.495, -18.0], [0.54, 8.0], [0.575, 16.0], [0.62, 0.0], [0.70, -16.0], [0.78, -10.0], [0.92, 8.0], [1.0, 12.0]], t)
	var lean: float = kf_f([[0.0, 7.0], [0.18, 14.0], [0.30, 12.0], [0.62, 16.0], [0.70, 12.0], [0.80, 9.0], [1.0, 7.0]], t)
	var drop: float = kf_f([[0.0, 0.5], [0.18, 4.5, "o"], [0.30, 3.5], [0.62, 4.5], [0.72, 3.5], [0.86, 1.5], [1.0, 0.5]], t)
	var push: float = kf_f([[0.0, 0.0], [0.16, -1.5], [0.30, 4.0, "i"], [0.66, 3.5], [0.92, 0.0]], t)
	_twist(p, yaw, lean, push, drop, 0.75)
	# ---- 脚：拔刀时右脚往前踏一大步，收刀时退回
	var rz: float = kf_f([[0.0, 0.0], [0.18, 0.0], [0.28, 8.0, "o"], [0.74, 8.0], [0.94, 0.0]], t)
	_feet(p, 7.5, -0.5, 0.0, rz, _arc(t, 0.18, 0.28, 3.5) + _arc(t, 0.76, 0.94, 1.5), 8.0, -8.0 - 10.0 * Lib.smooth(rz / 8.0))
	# ---- 刀：拇指推开鞘口(拔出一小截) → 出鞘(从鞘的方向转到左边) → 刀路 → 绕回左边、对准鞘 → 推回鞘里
	var slide: float = kf_f([[0.0, 0.0], [0.06, 0.0], [0.17, 9.0, "i"], [0.86, 9.0], [0.97, 0.0, "o"]], t)
	var engage: float = kf_f([[0.0, 0.0], [0.155, 0.0], [0.22, 1.0, "o"], [0.835, 1.0], [0.89, 0.0, "i"]], t)
	var sh: Array = _sheathed(p, slide)
	var sw: Array = _iai_swing(p, clampf(t, 0.20, 0.85))
	var grip: Vector3 = (sh[0] as Vector3).lerp(sw[0], engage)
	var rot: Quaternion = (sh[1] as Quaternion).slerp(sw[1], engage)
	hold_bow(p, grip, rot, Vector3(-1.0, -0.3, -0.3))
	fist_r(p, 84.0)
	# 出鞘：Q 版手短，拔不出整把刀的长度 —— 刀还在鞘里时先沿刀身方向缩短(看不见)，转出鞘口时只露一小截，
	# 随着横斩扫向前方再伸回全长，看起来就是刀从鞘口里抽出来，而不是一整把刀从腰后凭空转出来
	var reach: float = kf_f([[0.0, 1.0], [0.15, 1.0], [0.165, 0.3], [0.20, 0.34], [0.255, 1.0, "o"]], t)
	if reach < 0.999:
		p.scale_("Bow", Vector3(1.0, reach, 1.0))
	# ---- 左手：一直扶着鞘(拔刀时把鞘往后送一点)
	_left_on_saya(p, kf_f([[0.0, 0.0], [0.18, 2.5], [0.30, 1.0], [0.90, 1.0], [1.0, 0.0]], t))
	set_lids(p, 0.0)


## 待机小动作(3.8s)：闭目养神——低头、眼睛合上一会儿，抬头时右手在肩上捏一下、转转脖子
func fidget_samurai(t: float, p) -> void:
	p.reset()
	_stow(p)
	var rest: float = kf_f([[0.0, 0.0], [0.5, 1.0], [1.7, 1.0], [2.1, 0.0]], t)
	var rub: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.35, 1.0], [3.3, 1.0], [3.7, 0.0]], t)
	var roll: float = kf_f([[0.0, 0.0], [2.4, 0.0], [2.7, 10.0], [3.0, -10.0], [3.3, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.4), 0.0, 4.0, 3.0 + 4.0 * rest, 0.0, 0.0, 8.5, 0.0, 0.0)
	_head(p, 14.0 * rest + 4.0 * rub, 0.0, roll - 8.0 * rub)
	var g_shoulder := [Vector3(5.5, 70.0, 3.0), Vector3(1.0, -0.5, -0.2), Vector3(0.1, -0.3, -1.0), Vector3(1.0, 0.0, 0.0), 40.0]
	_hand_mix(p, "L", G_RELAX, G_HIP, 0.6)
	_hand_mix(p, "R", G_RELAX, g_shoulder, rub)
	set_lids(p, maxf(kf_f([[0.0, 0.0], [0.45, 0.0], [0.65, 1.0], [1.7, 1.0], [1.9, 0.0]], t), blink_k(t, 3.4)))


## 胜利(2.0s 循环)：两手抱在袖里、下巴微抬，站得很稳，只有呼吸
func victory_samurai(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.0, 0.3 * sin(th), 0.0, -4.0 + 0.8 * sin(th), 0.0, 0.0, 9.0, 0.0, 0.0)
	_head(p, -7.0 + 1.0 * sin(th), 6.0, 0.0)
	var fold_l := [Vector3(4.0, 56.0, 10.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.8, -0.1, 0.1), Vector3(0.0, -0.3, -1.0), 30.0]
	var fold_r := [Vector3(4.5, 58.0, 11.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.8, 0.1, 0.1), Vector3(0.0, 0.3, -1.0), 30.0]
	_hand_mix(p, "L", fold_l, fold_l, 0.0)
	_hand_mix(p, "R", fold_r, fold_r, 0.0)
	set_lids(p, 0.35 + 0.65 * blink_k(fmod(t, 2.0), 1.4))


# =============================================================== 追猎节点：钓鱼(意外渔获解锁后，猎人笔记的吟唱)
# 收起弓(双持武器也收起)，钓鱼竿 P_hunter_rod 绑在左手骨上：左手握竿、右手握竿尾，竿尖朝着前方的目标抖动；写完笔记时起竿把目标拽过来
const HUNT_TABLE := {"fish_hunter": [2.4, true], "fish_pull_hunter": [0.6, false]}
const ROD_GRIP := Vector3(6.0, 55.0, 12.0)              # 左手握竿的位置(静止坐标，跟着胸腔)
const ROD_AXIS := Vector3(-0.12, 0.55, 0.83)            # 竿身方向(胸腔局部)：朝前上方


func hunter_table(t: Dictionary) -> void:
	for nm: String in HUNT_TABLE.keys():
		t[nm] = {"dur": float(HUNT_TABLE[nm][0]), "loop": bool(HUNT_TABLE[nm][1]), "fn": Callable(self, nm)}


## 双手握竿：左手握在 grip(静止坐标)，竿身沿 axis(胸腔局部)；右手握竿尾
func _hold_rod(p, grip: Vector3, axis: Vector3) -> void:
	var a_w: Vector3 = _chest_dir(p, axis)
	var side: Vector3 = _chest_dir(p, Vector3(1.0, 0.0, 0.0))
	var rot: Quaternion = wrot(a_w, side)
	var g_w: Vector3 = follow(p, "Chest", grip)
	hold_left(p, g_w, rot, Vector3(1.0, -0.6, -0.2))
	fist_l(p, 80.0)
	hold_bow(p, g_w - a_w * 9.0, rot, Vector3(-1.0, -0.5, -0.2))
	fist_r(p, 80.0)


func fish_hunter(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	_twist(p, -6.0, -3.0 + 1.0 * s1, -0.5, 1.2 + 0.4 * s1, 0.6)
	_feet(p, 7.0, 2.5, 0.0, -1.5, 0.0, 10.0, -12.0)
	# 竿尖一抖一抖(鱼在咬钩)
	var twitch: float = 0.06 * maxf(0.0, sin(th * 3.0)) * (0.5 + 0.5 * s1)
	_hold_rod(p, ROD_GRIP + Vector3(0.0, 0.5 * s1, 0.0), (ROD_AXIS + Vector3(0.0, -twitch, 0.0)).normalized())
	_head(p, 4.0, 0.0, 2.0 * s1)
	set_lids(p, blink_k(fmod(t, 2.4), 1.6))


## 起竿：先往前一沉(蓄力)，猛地往后上方一扬把鱼拽过来，身子往后仰、右脚退半步，然后收
func fish_pull_hunter(t: float, p) -> void:
	p.reset()
	_stow(p)
	var yank: float = kf_f([[0.0, 0.0], [0.10, -0.25, "o"], [0.22, 1.0, "i"], [0.40, 1.0], [0.60, 0.6]], t)
	var y1: float = maxf(0.0, yank)
	_twist(p, -6.0 - 10.0 * y1, -3.0 - 14.0 * y1 + 6.0 * minf(0.0, yank), -0.5 - 2.0 * y1, 1.2 + 1.5 * y1, 0.6)
	_feet(p, 7.0, 2.5, 0.0, -1.5 - 2.5 * y1, _arc(t, 0.12, 0.24, 1.5), 10.0, -12.0)
	var axis: Vector3 = ROD_AXIS.lerp(Vector3(-0.1, 0.95, -0.25), y1).lerp(Vector3(-0.1, 0.25, 0.95), maxf(0.0, -yank) * 2.0).normalized()
	var grip: Vector3 = ROD_GRIP + Vector3(0.0, 6.0 * y1, -3.0 * y1)
	_hold_rod(p, grip, axis)
	_head(p, 4.0 - 10.0 * y1, 0.0, 0.0)
	set_lids(p, 0.0)


## 待机小动作(3.8s)：手搭凉棚左右张望，再挠挠头
func fidget_hunter(t: float, p) -> void:
	p.reset()
	_stow(p)
	var shade: float = kf_f([[0.0, 0.0], [0.35, 1.0], [2.1, 1.0], [2.45, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [0.5, 0.0], [0.85, 28.0, "o"], [1.25, 28.0], [1.65, -26.0], [2.0, -26.0], [2.3, 0.0]], t)
	var scratch: float = kf_f([[0.0, 0.0], [2.5, 0.0], [2.8, 1.0], [3.4, 1.0], [3.75, 0.0]], t)
	_base(p, 0.5 * sin(t * 1.6), 0.0, look * 0.25, 5.0 * shade, 0.0, 0.0, 7.5, 1.0, 0.25 * shade)
	_head(p, -4.0 * shade + 6.0 * scratch, look, 6.0 * scratch)
	var g_shade := [Vector3(-3.0, 84.5, 12.0), Vector3(1.0, -0.2, -0.4), Vector3(-1.0, 0.15, 0.1), Vector3(0.0, -1.0, 0.1), 10.0]
	var g_scratch := [Vector3(4.0, 91.0, 2.0), Vector3(1.0, -0.3, -0.5), Vector3(-0.3, 0.6, 0.2), Vector3(0.0, -1.0, 0.0), 40.0 + 30.0 * absf(sin(t * 22.0))]
	_hand_mix(p, "L", G_RELAX, G_HIP, 0.7)
	if scratch > 0.0:
		_hand_mix(p, "R", G_RELAX, g_scratch, scratch)
	else:
		_hand_mix(p, "R", G_RELAX, g_shade, shade)
	set_lids(p, maxf(0.3 * shade, blink_k(t, 3.0)))


## 胜利(1.6s 循环)：蹲着一蹦一蹦，右拳往上顶，左手叉腰
func victory_hunter(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = absf(sin(th)) * 4.0
	_base(p, 0.0, hop * 0.9 - 1.5, 6.0 * sin(th), 2.0, 3.0 * sin(th), 0.0, 8.0, 0.0, 0.0)
	legs(p, Vector3(8.0, ANKLE_Y + hop * 0.9, -0.5), Vector3(-8.0, ANKLE_Y + hop * 0.9, -0.5), Lib.E(0, 12, 0), Lib.E(0, -12, 0))
	_head(p, -8.0 + 3.0 * sin(2.0 * th), 6.0 * sin(th), 4.0 * sin(th))
	_hand(p, "R", Vector3(18.6, 80.5 + 2.5 * sin(2.0 * th), 3.5), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 1.0, 0.1), Vector3(-0.4, 0.0, 1.0), 85.0)
	_on_hip(p, "L")
	set_lids(p, 0.0)


# =============================================================== 巫术节点：吟唱 / 施放；鸟(渡鸦使魔，非人形：身体挂 Hips、翅膀挂上臂 UpperArm、腿挂 Shin/Foot)
const WIZ_TABLE := {"chant_wizard": [2.0, true], "cast_wizard": [0.5, false],
	"idle_bird": [2.0, true], "run_bird": [16.0 / 30.0, true], "attack_bird": [15.0 / 30.0, false], "hover_bird": [16.0 / 30.0, true]}


func wizard_table(t: Dictionary) -> void:
	for nm: String in WIZ_TABLE.keys():
		t[nm] = {"dur": float(WIZ_TABLE[nm][0]), "loop": bool(WIZ_TABLE[nm][1]), "fn": Callable(self, nm)}
	# 胜利：翅膀自己控制(展开)
	t["victory_wizard"]["wing_custom"] = true


## 吟唱(2s 循环)：法杖高举指天、杖尖画小圈，左手掌心朝前托着；身子微微后仰、轻轻浮动
func chant_wizard(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.0
	var s1: float = sin(th)
	_twist(p, -6.0, -4.0 + 1.0 * s1, -0.5, 0.8 + 0.6 * s1, 0.4)
	_feet(p, 7.5, 1.5, 0.0, -1.0, 0.0, 9.0, -11.0)
	var grip := Vector3(-13.0 + 1.2 * cos(th), 70.0 + 1.2 * s1, 11.0)
	var aim := Vector3(0.12 + 0.08 * cos(th), 0.78, 0.6).normalized()
	hold_bow(p, follow(p, "Chest", grip), grot(_chest_dir(p, aim), _chest_dir(p, Vector3(0.0, -0.6, 0.8))), Vector3(-1.0, -0.3, -0.5))
	fist_r(p, 70.0)
	_hand(p, "L", Vector3(13.0, 61.0 + 0.8 * s1, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(0.1, 1.0, 0.2), Vector3(0.0, 0.0, 1.0), 6.0)
	_head(p, -7.0 + 1.5 * s1, 6.0, 0.0)
	set_lids(p, 0.35)


## 施放(0.5s)：法杖往天上一挑(飞弹从杖尖升空)，再收回举着
func cast_wizard(t: float, p) -> void:
	p.reset()
	var k: float = kf_f([[0.0, 0.0], [0.10, -0.3, "o"], [0.20, 1.0, "i"], [0.32, 1.0], [0.5, 0.2]], t)
	var k1: float = maxf(0.0, k)
	_twist(p, -6.0, -4.0 - 8.0 * k1, -0.5 - 1.5 * k1, 0.8, 0.4)
	_feet(p, 7.5, 1.5, 0.0, -1.0, 0.0, 9.0, -11.0)
	var grip := Vector3(-13.0, 70.0, 11.0).lerp(Vector3(-11.0, 79.0, 8.0), k1).lerp(Vector3(-12.0, 65.0, 13.0), maxf(0.0, -k) * 2.0)
	var aim := Vector3(0.12, 0.78, 0.6).lerp(Vector3(0.05, 1.0, 0.1), k1).normalized()
	hold_bow(p, follow(p, "Chest", grip), grot(_chest_dir(p, aim), _chest_dir(p, Vector3(0.0, -0.6, 0.8))), Vector3(-1.0, -0.3, -0.5))
	fist_r(p, 75.0)
	_hand(p, "L", Vector3(13.0, 61.0, 13.0).lerp(Vector3(17.0, 66.0, 6.0), k1), Vector3(1.0, -0.6, -0.3), Vector3(0.1, 1.0, 0.2), Vector3(0.0, 0.0, 1.0), 6.0)
	_head(p, -7.0 - 8.0 * k1, 6.0, 0.0)
	set_lids(p, 0.0)


## 待机小动作(3.8s)：推一推眼镜，歪头想了想
func fidget_wizard(t: float, p) -> void:
	p.reset()
	_stow(p)
	var push: float = kf_f([[0.0, 0.0], [0.45, 1.0], [1.3, 1.0], [1.7, 0.0]], t)
	var think: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.4, 1.0], [3.3, 1.0], [3.75, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.5), 0.0, 3.0, 2.0 + 3.0 * push, 0.0, 0.0, 8.5, 0.0, 0.0)
	_head(p, 4.0 * push - 6.0 * think, 0.0, 9.0 * think)
	var g_glasses := [Vector3(-1.5, 81.5, 12.5), Vector3(1.0, -0.3, -0.4), Vector3(-0.2, 1.0, 0.3), Vector3(0.0, 0.0, -1.0), 55.0]
	var g_chin := [Vector3(-1.0, 75.0, 11.5), Vector3(1.0, -0.4, -0.3), Vector3(0.0, 1.0, 0.3), Vector3(0.0, 0.0, -1.0), 50.0]
	_hand_mix(p, "L", G_RELAX, G_HIP, 0.8)
	if think > 0.0:
		_hand_mix(p, "R", G_RELAX, g_chin, think)
	else:
		_hand_mix(p, "R", G_RELAX, g_glasses, push)
	set_lids(p, maxf(0.25 * think, blink_k(t, 1.9)))


## 胜利(2.0s 循环)：双翼展开、慢慢扇，右手按在胸口、微微欠身
func victory_wizard(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.0, 0.3 * sin(th), 0.0, 5.0 + 1.0 * sin(th), 0.0, 0.0, 8.5, 0.0, 0.0)
	_head(p, 8.0, 0.0, 4.0)
	p.r("Wing_L", 0.0, -28.0 - 6.0 * sin(th), 8.0 * sin(th))
	p.r("Wing_R", 0.0, 28.0 + 6.0 * sin(th), -8.0 * sin(th))
	var g_chest := [Vector3(-3.5, 63.0, 10.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.9, 0.2, 0.1), Vector3(0.0, 0.0, -1.0), 30.0]
	_hand_mix(p, "R", g_chest, g_chest, 0.0)
	_hand_mix(p, "L", G_BEHIND, G_BEHIND, 0.0)
	set_lids(p, 0.3)


# ---- 鸟：翅膀 = 上臂(z 转角张开：左 +、右 -)；身体 = 髋骨(x 正 = 往前俯)；头 = Head
func _bird_wings(p, spread: float, flap: float) -> void:
	p.r("UpperArm_L", flap * 0.3, 0.0, spread + flap)
	p.r("UpperArm_R", flap * 0.3, 0.0, -spread - flap)


func idle_bird(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.0
	p.move("Hips", Vector3(0.0, -1.0 + 0.5 * sin(2.0 * th), 0.0))
	p.r("Hips", 2.0 * sin(th), 0.0, 0.0)
	var look: float = kf_f([[0.0, 0.0], [0.3, 0.0], [0.38, 24.0], [0.9, 24.0], [0.98, -18.0], [1.5, -18.0], [1.58, 0.0], [2.0, 0.0]], t)
	p.r("Head", 4.0 * sin(th + 0.5), look, 6.0 * sin(th))
	_bird_wings(p, 4.0, 2.0 * sin(th))
	legs(p, Vector3(5.5, ANKLE_Y, -0.5), Vector3(-5.5, ANKLE_Y, -0.5), Lib.E(0, 8, 0), Lib.E(0, -8, 0))


## 鸟会飞(隐藏属性 flying)：移动时 UnitView 把它抬到空中(约 0.95 米)，站着打的时候低低地悬停(约 0.45 米)，没有敌人时落在地上(idle_bird)。
## 扇翅：翅膀角(上臂绕 z) 上 ~115° → 下 ~15°；下扑快(四成时间)、上抬慢，下扑时翅膀往前兜一点(绕 x)、身子被托起
static func _bird_beat(ph: float) -> float:
	var down: float = ph / 0.4 if ph < 0.4 else 1.0 - (ph - 0.4) / 0.6
	return Lib.smooth(clampf(down, 0.0, 1.0))


func _bird_flap(p, dk: float, top: float, bottom: float, sweep: float) -> void:
	var wing: float = lerpf(top, bottom, dk)
	p.r("UpperArm_L", sweep * dk - 6.0, 0.0, wing)
	p.r("UpperArm_R", sweep * dk - 6.0, 0.0, -wing)


## 飞(16f 循环，扇两下)：身子往前俯平、头往前伸，翅膀大幅上下扇，两腿往后收着、爪子并拢，尾羽拖在后面
func run_bird(t: float, p) -> void:
	p.reset()
	var T := 16.0 / 30.0
	var ph: float = fposmod(t / T * 2.0, 1.0)
	var dk: float = _bird_beat(ph)
	p.move("Hips", Vector3(0.0, 1.0 + 1.6 * sin(TAU * ph - 1.6), 0.0))
	p.r("Hips", 34.0 + 3.0 * sin(TAU * ph), 0.0, 0.0)
	p.r("Head", -28.0 - 3.0 * sin(TAU * ph), 0.0, 0.0)
	_bird_flap(p, dk, 118.0, 12.0, 14.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, 30.0, 0.0, 4.0 * m)
		p.r("Shin_" + side, 38.0, 0.0, 0.0)
		p.r("Foot_" + side, 48.0, 0.0, 0.0)


## 悬停(16f 循环，扇两下，幅度比飞小)：身子直一点、上下轻轻起伏，两腿垂在前下方、爪子张着
func hover_bird(t: float, p) -> void:
	p.reset()
	var T := 16.0 / 30.0
	var ph: float = fposmod(t / T * 2.0, 1.0)
	var dk: float = _bird_beat(ph)
	p.move("Hips", Vector3(0.0, 0.5 + 1.3 * sin(TAU * ph - 1.6), 0.0))
	p.r("Hips", 10.0 + 2.0 * sin(TAU * ph), 0.0, 0.0)
	p.r("Head", -8.0 - 2.0 * sin(TAU * ph), 6.0 * sin(TAU * t / T), 0.0)
	_bird_flap(p, dk, 108.0, 22.0, 18.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -16.0, 0.0, 5.0 * m)
		p.r("Shin_" + side, 28.0, 0.0, 0.0)
		p.r("Foot_" + side, 12.0, 0.0, 0.0)


## 攻击(0.5s，悬停着啄)：一边扇翅一边往后一缩、翅膀高高举起，再往前扑着连啄两下(0.18 / 0.28 秒，对上双持的两次出手)，爪子往前抓
func attack_bird(t: float, p) -> void:
	p.reset()
	var peck: float = kf_f([[0.0, 0.0], [0.10, -0.6, "o"], [0.18, 1.0, "i"], [0.22, 0.2], [0.28, 1.0, "i"], [0.34, 0.3], [0.5, 0.0]], t)
	var pk: float = maxf(0.0, peck)
	var back: float = maxf(0.0, -peck)
	var ph: float = fposmod(t / 0.25, 1.0)
	var dk: float = _bird_beat(ph)
	p.move("Hips", Vector3(0.0, 0.5 + 1.2 * sin(TAU * ph - 1.6) - 1.0 * pk, 4.0 * pk - 2.5 * back))
	p.r("Hips", 10.0 + 26.0 * pk - 12.0 * back, 0.0, 0.0)
	p.r("Head", -8.0 + 30.0 * pk - 16.0 * back, 0.0, 0.0)
	_bird_flap(p, dk, 112.0 + 12.0 * back, 22.0 + 25.0 * back, 18.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -16.0 - 30.0 * pk + 10.0 * back, 0.0, 5.0 * m)
		p.r("Shin_" + side, 28.0 - 10.0 * pk, 0.0, 0.0)
		p.r("Foot_" + side, 12.0 - 30.0 * pk, 0.0, 0.0)


## 待机小动作(3.0s)：低头梳理翅膀上的羽毛，抖一抖
func fidget_bird(t: float, p) -> void:
	p.reset()
	_stow(p)
	var preen: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.8, 1.0], [2.1, 0.0]], t)
	var shake_k: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.25, 1.0], [2.6, 1.0], [2.8, 0.0]], t)
	p.move("Hips", Vector3(0.0, -1.0, 0.0))
	p.r("Hips", 4.0 * preen, 0.0, 6.0 * sin(t * 40.0) * shake_k)
	p.r("Head", 30.0 * preen, 55.0 * preen + 6.0 * sin(t * 9.0) * preen, 20.0 * preen)
	_bird_wings(p, 6.0 + 10.0 * preen + 25.0 * shake_k, 8.0 * sin(t * 40.0) * shake_k)
	legs(p, Vector3(5.5, ANKLE_Y, -0.5), Vector3(-5.5, ANKLE_Y, -0.5), Lib.E(0, 8, 0), Lib.E(0, -8, 0))


func victory_bird(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = absf(sin(th)) * 3.0
	p.move("Hips", Vector3(0.0, -1.0 + hop, 0.0))
	p.r("Hips", -6.0, 0.0, 0.0)
	p.r("Head", -14.0, 10.0 * sin(th), 0.0)
	_bird_wings(p, 70.0, 20.0 * sin(th * 2.0))
	legs(p, Vector3(5.5, ANKLE_Y + hop * 0.9, -0.5), Vector3(-5.5, ANKLE_Y + hop * 0.9, -0.5), Lib.E(0, 8, 0), Lib.E(0, -8, 0))


# =============================================================== 清扫节点(女仆)：扔飞刀 / 转圈乱扔 / 提裙礼 + 看怀表 / 胜利
## attack_maid(15f = 双持的普攻间隔)：右手从耳边甩出一把(0.18 s = 出手)，左手紧跟着甩出一把(0.28 s = 追击副本的出手)，
##   甩出去的那一刻手里那把收掉(武器骨缩到 0)，过一会儿再从手里"变"出一把新的
## storm_maid(36f = 清洁世界)：两臂张开原地转两圈，0.36 s / 0.76 s 两轮出手时手腕一甩(手里的刀收掉再长出来)；双枪也用它
const MAID_TABLE := {"attack_maid": [15.0 * F, false], "storm_maid": [36.0 * F, false]}


func maid_table(t: Dictionary) -> void:
	for nm: String in MAID_TABLE.keys():
		t[nm] = {"dur": float(MAID_TABLE[nm][0]), "loop": bool(MAID_TABLE[nm][1]), "fn": Callable(self, nm)}


## 手里那把刀：出手瞬间收掉，regrow 秒后长回来(t 在 [rel, rel + regrow] 里由 0 → 1)
func _knife_scale(t: float, rel: float, gone: float, regrow: float) -> float:
	if t < rel:
		return 1.0
	if t < rel + gone:
		return 0.001
	return clampf((t - rel - gone) / regrow, 0.001, 1.0)


func attack_maid(t: float, p) -> void:
	p.reset()
	var rel_r := 0.18
	var rel_l := 0.28
	_twist(p, kf_f([[0.0, 0.0], [0.10, -22.0, "s"], [rel_r, 20.0, "i"], [0.21, 22.0], [rel_l, -18.0, "i"], [0.38, -7.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [0.10, -3.0], [rel_r, 6.0, "i"], [rel_l, 7.0, "i"], [0.40, 3.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [rel_r, 1.5], [rel_l, 2.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [0.09, 0.8], [rel_l, 1.6], [0.5, 0.0]], t), 0.8)
	var lz: float = kf_f([[0.0, 0.0], [0.09, 0.0], [rel_r, 3.5, "o"], [0.40, 3.5], [0.5, 0.0]], t)
	_feet(p, 7.0, lz, _arc(t, 0.08, rel_r, 1.6), -1.0 * Lib.smooth(t / 0.2), 0.0, 8.0, -10.0)
	var cq: Quaternion = _chest_q(p)
	# 右手：耳边 → 往前甩直 → 随势往下带 → 收回
	# (举手时从身体外侧绕上去，别让手经过肩膀附近——手离肩太近时肘的朝向会翻)
	var gr: Vector3 = kf_v([[0.0, DUAL_GRIP], [0.05, Vector3(-19.5, 60.0, 3.0)], [0.10, Vector3(-15.0, 79.0, -3.0), "s"], [rel_r, Vector3(-7.0, 63.0, 17.0), "i"],
		[0.26, Vector3(-5.0, 56.5, 15.5), "o"], [0.5, DUAL_GRIP]], t)
	var ar: Vector3 = kf_v([[0.0, DUAL_AXIS], [0.05, Vector3(-0.2, 0.8, 0.4)], [0.10, Vector3(0.05, 0.75, -0.55), "s"], [rel_r, Vector3(0.05, 0.12, 1.0), "i"],
		[0.26, Vector3(0.1, -0.4, 0.9)], [0.5, DUAL_AXIS]], t)
	var pr: Vector3 = kf_v([[0.0, Vector3(-1.0, -0.3, -0.5)], [0.05, Vector3(-0.3, -0.5, -1.0)], [0.10, Vector3(-1.0, 0.0, 0.5), "s"], [rel_r, Vector3(-1.0, -0.2, 0.2), "i"],
		[0.5, Vector3(-1.0, -0.3, -0.5)]], t)
	hold_bow(p, follow(p, "Chest", gr), cq * wrot(ar, Vector3(-1.0, 0.3, 0.0)), _chest_dir(p, pr))
	fist_r(p, 82.0 if t < rel_r or t > 0.34 else 25.0)
	# 左手：先在腰侧候着 → 举到耳边 → 往前甩 → 收回
	var gl: Vector3 = kf_v([[0.0, mx(DUAL_GRIP)], [0.11, Vector3(14.0, 50.5, 5.0)], [0.16, Vector3(19.5, 60.0, 3.0)], [0.21, Vector3(15.0, 79.0, -3.0), "s"],
		[rel_l, Vector3(7.0, 62.5, 17.0), "i"], [0.36, Vector3(6.0, 56.0, 15.0), "o"], [0.5, mx(DUAL_GRIP)]], t)
	var al: Vector3 = kf_v([[0.0, mx(DUAL_AXIS)], [0.11, Vector3(0.05, 0.6, 0.8)], [0.16, Vector3(0.2, 0.8, 0.4)], [0.21, Vector3(-0.05, 0.75, -0.55), "s"],
		[rel_l, Vector3(-0.05, 0.12, 1.0), "i"], [0.36, Vector3(-0.1, -0.4, 0.9)], [0.5, mx(DUAL_AXIS)]], t)
	var pl: Vector3 = kf_v([[0.0, Vector3(1.0, -0.4, -0.5)], [0.11, Vector3(1.0, -0.4, -0.5)], [0.16, Vector3(0.3, -0.5, -1.0)], [0.21, Vector3(1.0, 0.0, 0.5), "s"],
		[rel_l, Vector3(1.0, -0.2, 0.2), "i"], [0.5, Vector3(1.0, -0.4, -0.5)]], t)
	hold_left(p, follow(p, "Chest", gl), cq * mirror_q(wrot(mx(al), Vector3(-1.0, 0.3, 0.0))), _chest_dir(p, pl))
	fist_l(p, 82.0 if t < rel_l or t > 0.42 else 25.0)
	p.scale_("Bow", Vector3.ONE * _knife_scale(t, rel_r, 0.1, 0.12))
	p.scale_("Weapon_L", Vector3.ONE * _knife_scale(t, rel_l, 0.08, 0.1))
	set_lids(p, 0.0)


func storm_maid(t: float, p) -> void:
	p.reset()
	var rels := [0.36, 0.76]
	var spin: float = kf_f([[0.0, 0.0], [0.08, 20.0, "o"], [1.02, -720.0, "s"], [1.2, -720.0]], t)
	var open: float = kf_f([[0.0, 0.0], [0.16, 1.0, "s"], [1.0, 1.0], [1.18, 0.0]], t)
	var low: float = kf_f([[0.0, 0.0], [0.08, 1.2, "o"], [0.3, 0.8], [1.0, 0.8], [1.2, 0.0]], t)
	p.r("Root", 0.0, spin, 0.0)
	var qs := Quaternion(Vector3.UP, deg_to_rad(spin))
	_twist(p, 0.0, 6.0 * low, 0.0, 2.5 * low, 0.6)
	p.radd("Hips", 0.0, 0.0, -5.0 * open)
	var hop: float = _arc(t, 0.1, 0.3, 1.6) + _arc(t, 0.52, 0.66, 1.0)
	legs(p, qs * Vector3(7.5, ANKLE_Y + hop, 0.5), qs * Vector3(-7.5, ANKLE_Y, -1.0), Lib.E(0, spin + 10.0, 0), Lib.E(0, spin - 10.0, 0))
	# 出手时手腕一甩：刃尖从朝外甩到朝前(转圈的切线方向)
	var flick := 0.0
	for r: float in rels:
		flick = maxf(flick, _arc(t, r - 0.06, r + 0.1, 1.0))
	var cq: Quaternion = _chest_q(p)
	var r0: Quaternion = _dual_rot(DUAL_AXIS)
	var gr: Vector3 = DUAL_GRIP.lerp(Vector3(-21.5, 59.0 + 2.0 * flick, 4.0 - 3.0 * flick), open)
	var ar: Vector3 = Vector3(-1.0, 0.05, 0.1).lerp(Vector3(-0.35, 0.1, -1.0), flick).normalized()
	var qr: Quaternion = r0.slerp(wrot(ar, Vector3(0.0, 1.0, 0.0)), open)
	hold_bow(p, follow(p, "Chest", gr), cq * qr, _chest_dir(p, Vector3(-0.6, -0.8, -0.2)))
	fist_r(p, 84.0)
	var gl: Vector3 = mx(DUAL_GRIP).lerp(Vector3(21.5, 59.0 + 2.0 * flick, 4.0 + 3.0 * flick), open)
	var al: Vector3 = Vector3(1.0, 0.05, 0.1).lerp(Vector3(0.35, 0.1, 1.0), flick).normalized()
	var ql: Quaternion = mirror_q(r0).slerp(wrot(al, Vector3(0.0, 1.0, 0.0)), open)
	hold_left(p, follow(p, "Chest", gl), cq * ql, _chest_dir(p, Vector3(0.6, -0.8, -0.2)))
	fist_l(p, 84.0)
	var ks: float = minf(_knife_scale(t, float(rels[0]), 0.08, 0.1) if t < float(rels[1]) else 1.0, _knife_scale(t, float(rels[1]), 0.08, 0.1))
	p.scale_("Bow", Vector3.ONE * ks)
	p.scale_("Weapon_L", Vector3.ONE * ks)
	set_lids(p, 0.0)


## 待机小动作(4s)：双手捏起裙摆、右脚往后撤半步，屈膝低头行提裙礼 → 起身，左手托起怀表(掌心朝上)、右手轻点表盖，
## 低头看一眼 → 抬头眨眨眼点点头 → 放下
func fidget_maid(t: float, p) -> void:
	p.reset()
	_stow(p)
	var bow: float = kf_f([[0.0, 0.0], [0.35, 0.0], [0.75, 1.0, "s"], [1.15, 1.0], [1.5, 0.0, "s"]], t)
	var watch: float = kf_f([[0.0, 0.0], [1.6, 0.0], [1.9, 1.0], [3.2, 1.0], [3.6, 0.0]], t)
	var nod: float = _arc(t, 2.7, 3.05, 1.0)
	_base(p, 0.0, -2.6 * bow, 0.0, 9.0 * bow + 5.0 * watch, 0.0, 0.0, 6.0, 2.5 * bow, 0.0)
	_head(p, 16.0 * bow + 20.0 * watch * (1.0 - 0.9 * float(t > 2.6)) - 8.0 * nod, 0.0, 4.0 * nod)
	var g_skirt := [Vector3(15.5, 45.5, 4.5), Vector3(1.0, 0.0, -0.6), Vector3(0.25, -1.0, 0.35), Vector3(-0.6, 0.0, 0.8), 55.0]
	var g_lift := [Vector3(17.0, 47.5, 5.5), Vector3(1.0, 0.0, -0.6), Vector3(0.35, -1.0, 0.35), Vector3(-0.6, 0.0, 0.8), 60.0]
	var g_watch := [Vector3(6.0, 55.0, 12.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.5, 0.0, 1.0), Vector3(0.0, 1.0, 0.0), 25.0]
	var g_tap := [Vector3(1.0, 58.5, 13.5), Vector3(1.0, -0.4, -0.3), Vector3(-0.3, -0.5, 0.8), Vector3(0.0, -1.0, 0.0), 30.0]
	for side: String in ["L", "R"]:
		var last: Array = g_watch if side == "L" else g_tap
		_hand_keys(p, side, [[0.0, G_RELAX], [0.35, g_skirt], [0.75, g_lift], [1.15, g_lift], [1.5, G_RELAX], [1.6, G_RELAX], [1.9, last],
			[3.2, last], [3.6, G_RELAX]], t)
	set_lids(p, maxf(0.45 * bow, blink_k(t, 2.95)))


## 胜利(2s 循环)：双手叠在身前，身子轻轻一欠一欠地行礼，歪头 + 眨一只眼
func victory_maid(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var k: float = 0.5 - 0.5 * cos(th)
	_base(p, 0.4 * sin(th), -0.8 * k, 0.0, 4.0 + 7.0 * k, 3.0 * sin(th), 0.0, 6.0, 1.0, 0.0)
	_head(p, 6.0 + 6.0 * k, 0.0, 7.0 * sin(th))
	_hand_mix(p, "L", G_FOLD, G_FOLD, 0.0)
	_hand_mix(p, "R", G_FOLD, G_FOLD, 0.0)
	if fmod(t, 2.0) > 1.0 and fmod(t, 2.0) < 1.4:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 星旅节点(章鱼宇航员)：手搭凉棚望天 → 朝天上挥手 / 胜利 = 双手高举蹦跶
## 待机小动作(4s)：右手搭在额前望着天上(左右找一找)，找到了——左手高举朝天上大幅挥手，然后放下
func fidget_astronaut(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.4, 1.0], [2.0, 1.0], [2.3, 0.0]], t)
	var wave: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.35, 1.0], [3.5, 1.0], [3.85, 0.0]], t)
	var scan: float = kf_f([[0.0, 0.0], [0.6, 0.0], [1.0, 22.0], [1.4, 22.0], [1.75, -14.0], [2.0, -14.0], [2.3, 0.0]], t)
	var sway: float = sin(t * 9.0) * wave
	_base(p, 0.6 * sin(t * 1.4), 0.6 * wave * absf(sin(t * 9.0)), 0.0, -6.0 * look - 4.0 * wave, 2.5 * sway, 0.0, 6.5, 0.0, 0.0)
	_head(p, -18.0 * look - 12.0 * wave, scan, 5.0 * wave)
	var g_shade := [Vector3(3.0, 85.0, 10.5), Vector3(1.0, 0.2, -0.3), Vector3(-1.0, 0.1, 0.2), Vector3(0.0, -1.0, 0.2), 6.0]
	var g_wave_a := [Vector3(19.5, 84.0, 3.0), Vector3(1.0, -0.3, -0.5), Vector3(0.35, 1.0, 0.1), Vector3(-0.3, 0.0, 1.0), 6.0]
	var g_wave_b := [Vector3(14.5, 86.0, 4.0), Vector3(1.0, -0.3, -0.5), Vector3(-0.35, 1.0, 0.1), Vector3(-0.3, 0.0, 1.0), 6.0]
	_hand_mix(p, "R", G_RELAX, g_shade, look)
	if wave > 0.0:
		var w: float = 0.5 + 0.5 * sin(t * 9.0)
		var up: Array = [(g_wave_a[0] as Vector3).lerp(g_wave_b[0], w), g_wave_a[1], (g_wave_a[2] as Vector3).lerp(g_wave_b[2], w), g_wave_a[3], 6.0]
		_hand_mix(p, "L", G_RELAX, up, wave)
	else:
		_relax(p, "L")
	set_lids(p, blink_k(t, 1.2))


## 胜利(1.6s 循环)：双手高举，章鱼腿一蹦一蹦，歪头 + 眨眼
func victory_astronaut(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	var hop: float = maxf(0.0, sin(th))
	_base(p, 0.0, 1.6 * hop, 0.0, -6.0, 3.0 * sin(th * 0.5), 0.0, 6.5, 0.0, 0.0)
	_head(p, -14.0, 0.0, 8.0 * sin(th * 0.5))
	var g_hi := [Vector3(16.5, 87.0 + 1.5 * hop, 4.0), Vector3(1.0, -0.3, -0.5), Vector3(0.25, 1.0, 0.1), Vector3(-0.2, 0.0, 1.0), 40.0]
	_hand_mix(p, "L", g_hi, g_hi, 0.0)
	_hand_mix(p, "R", g_hi, g_hi, 0.0)
	if fmod(t, 1.6) > 0.7 and fmod(t, 1.6) < 1.1:
		_wink(p, "R")
	else:
		set_lids(p, 0.0)


# =============================================================== 改修节点(机械臂工匠，男)：拉下护目镜 → 端详机械手、一张一合 / 胜利 = 机械拳一下下往上举
## 待机小动作(4s)：双手把额头上的护目镜往下拉一拉，然后右手(机械臂)抬到面前、掌心朝上，手指一张一合，歪头端详；左手叉腰
func fidget_tinker(t: float, p) -> void:
	p.reset()
	_stow(p)
	var gog: float = kf_f([[0.0, 0.0], [0.35, 1.0], [1.3, 1.0], [1.6, 0.0]], t)
	var tug: float = _arc(t, 0.5, 1.1, 1.0)
	var look: float = kf_f([[0.0, 0.0], [1.7, 0.0], [2.05, 1.0], [3.4, 1.0], [3.8, 0.0]], t)
	_base(p, 0.5 * sin(t * 1.3), 0.0, 4.0 * look, 3.0 + 4.0 * look, 0.0, 0.0, 7.0, 0.0, 0.0)
	_head(p, 6.0 * gog + 14.0 * look, -8.0 * look, 8.0 * look)
	var g_gog := [Vector3(9.5, 83.0 - 2.5 * tug, 12.5), Vector3(1.0, -0.4, -0.1), Vector3(-0.4, 1.0, 0.2), Vector3(0.2, 0.0, -1.0), 50.0]
	var curl: float = 25.0 + 55.0 * (0.5 + 0.5 * sin(t * 7.0)) * look
	var g_palm := [Vector3(2.5, 62.0, 14.0), Vector3(1.0, -0.5, -0.3), Vector3(-0.4, 0.15, 1.0), Vector3(0.0, 1.0, 0.0), curl]
	if look > 0.0:
		_hand_mix(p, "R", G_RELAX, g_palm, look)
		_hand_mix(p, "L", G_RELAX, G_HIP, look)
	else:
		_hand_mix(p, "R", G_RELAX, g_gog, gog)
		_hand_mix(p, "L", G_RELAX, g_gog, gog)
	set_lids(p, maxf(0.2 * look, blink_k(t, 1.5)))


## 胜利(2s 循环)：左手叉腰，右手(机械臂)握拳一下下往上举，头往后仰着晃 + 眨眼
func victory_tinker(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var pump: float = maxf(0.0, sin(th * 2.0))
	_base(p, 0.6 * sin(th), 0.3 * pump, 0.0, -6.0, 2.0 * sin(th), 0.0, 7.5, 0.0, 0.0)
	_head(p, -10.0 - 3.0 * pump, 0.0, 5.0 * sin(th))
	_on_hip(p, "L")
	var g_fist := [Vector3(14.0, 82.0 + 4.0 * pump, 5.0), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 1.0, 0.2), Vector3(-0.8, 0.0, 0.4), 85.0]
	_hand_mix(p, "R", g_fist, g_fist, 0.0)
	if fmod(t, 2.0) > 1.0 and fmod(t, 2.0) < 1.4:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 幻彩节点
## attack_magi(72f = 2.4s = 她的攻击间隔，出手 0.75s)：大镰刀版的旋斩——压低蓄力 → 单手把镰刀甩开、原地转一圈(镰刃扫回正前方时出手)
##   → 转过头后顺势把镰刀往上一扛、搭在右肩，左手在眼边比个剪刀手 + 眨左眼 → 两手合握收回低架
## chant_magi(60f 循环 = 少女幻终的吟唱)：浮在半空(离地 20 cm 上下飘)，右手把镰刀竖在身侧、左手往前伸掌心朝外，
##   两脚并拢脚尖朝下，头微仰半闭眼
## death_magi(60f = 少女幻终之后的强制阵亡)：接着往上升，双臂慢慢张开、仰头闭眼，镰刀缩没(化成光、碎成方块由表现层做)
const MAGI_TABLE := {"attack_magi": [72.0 * F, false], "chant_magi": [120.0 * F, true], "death_magi": [60.0 * F, false]}
const MAGI_HIT := 0.75
const MAGI_FLOAT := 16.0         # 吟唱时离地的高度(体素)


func magi_table(t: Dictionary) -> void:
	for nm: String in MAGI_TABLE.keys():
		t[nm] = {"dur": float(MAGI_TABLE[nm][0]), "loop": bool(MAGI_TABLE[nm][1]), "fn": Callable(self, nm)}


## 两个整姿势之间插值(局部旋转 slerp、平移 / 缩放 lerp)；fa、fb 各自从 p.reset() 摆起
func _pose_mix(p, fa: Callable, fb: Callable, w: float) -> void:
	fa.call(p)
	if w <= 0.0:
		return
	var rot_a: Array[Quaternion] = p.rot.duplicate()
	var off_a: PackedVector3Array = p.off.duplicate()
	var scl_a: PackedVector3Array = p.scl.duplicate()
	fb.call(p)
	if w >= 1.0:
		return
	var off_b: PackedVector3Array = p.off.duplicate()
	var scl_b: PackedVector3Array = p.scl.duplicate()
	for i in range(p.n):
		p.rot[i] = rot_a[i].slerp(p.rot[i], w)
		off_b[i] = off_a[i].lerp(off_b[i], w)
		scl_b[i] = scl_a[i].lerp(scl_b[i], w)
	p.off = off_b
	p.scl = scl_b
	p.dirty = true


## 旋斩的时间轴压到她的节奏里：旋斩 0.95s 的出手 → 0.75s，之后放慢
static func _magi_warp(t: float) -> float:
	if t <= MAGI_HIT:
		return t * 0.95 / MAGI_HIT
	return 0.95 + (t - MAGI_HIT) * 0.9


func attack_magi(t: float, p) -> void:
	var whirl := func(pp) -> void: attack_heavy_whirl(_magi_warp(minf(t, 1.0)), pp)
	var pose := func(pp) -> void: _magi_pose(pp, t)
	var ready := func(pp) -> void: attack_heavy_whirl(1.6, pp)
	if t < 0.9:
		whirl.call(p)
	elif t < 1.95:
		_pose_mix(p, whirl, pose, Lib.smooth((t - 0.9) / 0.4))
	else:
		_pose_mix(p, pose, ready, Lib.smooth((t - 1.95) / 0.42))


## 扛镰刀 + 剪刀手的定格(t 只用来做轻微的晃动)
func _magi_pose(p, t: float) -> void:
	p.reset()
	var th: float = TAU * (t - 1.0) / 0.95
	_base(p, -1.4 + 0.3 * sin(th), 0.2 * sin(2.0 * th), -12.0, -3.0, 5.0, 0.0, 6.0, 1.5, 0.0)
	_head(p, -4.0, 6.0, 11.0 + 1.5 * sin(th))
	var cq: Quaternion = _chest_q(p)
	var axis: Vector3 = (cq * Vector3(-0.32, 0.8, -0.5)).normalized()
	hold_bow(p, follow(p, "Chest", Vector3(-11.5, 57.0, 9.5)), wrot(axis, cq * Vector3(-1.0, -0.1, 0.25)), _chest_dir(p, Vector3(-1.0, -0.7, 0.1)))
	fist_r(p, 85.0)
	_hand(p, "L", Vector3(14.0, 80.5, 8.5), Vector3(1.0, -0.4, -0.3), Vector3(-0.2, 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 4.0)     # 眼角外侧(别挡住脸)
	_wink(p, "L")


## 悬空的两条腿：并拢、脚尖朝下，膝盖微弯(bend 越大弯得越多)
func _magi_dangle(p, lift: float, bend: float) -> void:
	legs(p, Vector3(2.6, ANKLE_Y + lift + 1.0 + 3.0 * bend, -1.0 - 2.0 * bend), Vector3(-2.6, ANKLE_Y + lift + 2.0 + 4.0 * bend, -2.0 - 3.0 * bend),
		Lib.E(50.0, 4.0, 0.0), Lib.E(56.0, -4.0, 0.0), 8.0, 8.0)


## 少女幻终的吟唱(4 秒一圈)：悬在半空(UnitView 再整体抬高 1 米)慢慢转一整圈，双臂张开、胸口挺起、仰头——
## 黑白世界里只有她是彩色的；镰刀横握在右手往外伸，左手掌心朝外摊开，裙摆 / 双马尾由弹簧骨跟着甩
func chant_magi(t: float, p) -> void:
	p.reset()
	var T := 4.0
	var th: float = TAU * t / T
	var s1: float = sin(th * 2.0)
	var lift: float = MAGI_FLOAT + 2.0 * s1
	p.r("Root", 0.0, 360.0 * t / T, 0.0)
	p.move("Hips", Vector3(0.0, -1.7 + lift, 0.0))
	p.r("Hips", -6.0, 0.0, 3.0 * sin(th))
	p.r("Spine", -6.0 + 1.0 * s1, 0.0, 0.0)
	p.r("Chest", -9.0 + 1.0 * s1, 0.0, 0.0)
	_magi_dangle(p, lift, 0.35 + 0.15 * sin(th * 2.0 + 0.8))
	var cq: Quaternion = _chest_q(p)
	# 右手：镰刀横着往外伸(刃朝上外)
	hold_bow(p, follow(p, "Chest", Vector3(-24.0, 68.0 + 1.0 * s1, 8.0)), wrot(cq * Vector3(-0.85, 0.45, 0.25), cq * Vector3(0.0, 0.3, 1.0)),
		_chest_dir(p, Vector3(-0.3, -0.9, -0.3)))
	fist_r(p, 85.0)
	# 左手：张开到身侧、掌心朝外
	_hand(p, "L", Vector3(24.0, 72.0 + 1.2 * s1, 8.0), Vector3(0.4, -0.8, -0.3), Vector3(0.85, 0.45, 0.2), Vector3(0.0, 0.15, 1.0), 4.0)
	_head(p, -16.0 + 2.0 * s1, 0.0, 5.0 * sin(th))
	set_lids(p, 0.55)


func death_magi(t: float, p) -> void:
	p.reset()
	var f: float = Lib.smoother(t / 1.6)
	var lift: float = MAGI_FLOAT + 26.0 * f
	p.move("Hips", Vector3(0.0, -1.7 + lift, 0.0))
	p.r("Hips", -4.0 - 4.0 * f, 0.0, 0.0)
	p.r("Spine", -2.0 - 8.0 * f, 0.0, 0.0)
	p.r("Chest", -3.0 - 10.0 * f, 0.0, 0.0)
	_magi_dangle(p, lift, 0.4 + 0.5 * f)
	# 双臂慢慢张开(掌心朝前)、仰头
	p.r("UpperArm_L", -12.0 * f, 0.0, 18.0 + 62.0 * f)
	p.r("UpperArm_R", -12.0 * f, 0.0, -18.0 - 62.0 * f)
	p.r("LowerArm_L", -14.0 * f, 0.0, 0.0)
	p.r("LowerArm_R", -14.0 * f, 0.0, 0.0)
	p.r("Fingers_L", -8.0, 0.0, -10.0 * f)
	p.r("Fingers_R", -8.0, 0.0, 10.0 * f)
	_head(p, -10.0 - 18.0 * f, 0.0, 4.0 * f)
	p.scale_("Bow", Vector3.ONE * maxf(0.001, 1.0 - Lib.smooth(t / 0.45)))
	p.scale_("Weapon_L", Vector3.ONE * 0.001)
	set_lids(p, maxf(0.4, Lib.smooth(t / 0.5)))


# =============================================================== 迅游节点(男)
## run_runner(14f 循环 = 冲刺)：身体大幅前倾、步幅大、腾空时间长，双拳前后猛摆(手里是闪电手套)；UnitView 按 4.2 米/秒 = 原速放
## kick_runner(12f = 飞身踢)：动作从踢中的那一刻开始(逻辑层碰到目标就结算)：右腿已经蹬直在前上方、上身后仰、左腿收在身下，
##   双臂往后甩开配重 → 在空中停一下 → 收腿落地接回冲刺姿势(他一直在移动，位移由逻辑层给)
## fidget_runner(4s)：踮着脚尖原地小跳(拳击步)，拉一拉右手手套的护腕，再把右脚往后勾起来拉伸大腿
## victory_runner(2s 循环)：左手叉腰，右拳高举、一下下往上顶，右脚尖点地打拍子 + 眨眼
const RUNNER_TABLE := {"run_runner": [14.0 * F, true], "kick_runner": [12.0 * F, false]}


func runner_table(t: Dictionary) -> void:
	for nm: String in RUNNER_TABLE.keys():
		t[nm] = {"dur": float(RUNNER_TABLE[nm][0]), "loop": bool(RUNNER_TABLE[nm][1]), "fn": Callable(self, nm)}


## 冲刺时双拳的摆动：s = +1 右拳在前(左腿在前)，-1 右拳在后
func _runner_arms(p, s: float, th: float) -> void:
	var bob := Vector3(0.0, 1.2 * sin(2.0 * th), 0.0)
	var r0: Quaternion = _dual_rot(Vector3(-0.1, 0.35, 1.0))
	var gr: Vector3 = Vector3(-12.5, 52.0 + 6.0 * s, 4.0 + 9.0 * s) + bob
	var gl: Vector3 = Vector3(12.5, 52.0 - 6.0 * s, 4.0 - 9.0 * s) + bob
	hold_bow(p, follow(p, "Chest", gr), _chest_q(p) * r0, _chest_dir(p, Vector3(-0.6, -0.5, -0.7)))
	fist_r(p, 85.0)
	hold_left(p, follow(p, "Chest", gl), _chest_q(p) * mirror_q(r0), _chest_dir(p, Vector3(0.6, -0.5, -0.7)))
	fist_l(p, 85.0)


func run_runner(t: float, p) -> void:
	var T := 14.0 * F
	var ph := fposmod(t / T, 1.0)
	var th := TAU * ph
	p.reset()
	_set_kit("dual")
	var fl: Array = foot_track(ph, 19.0, 17.0, 0.32)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 19.0, 17.0, 0.32)
	var bob := 4.2 * absf(sin(th))
	p.move("Hips", Vector3(0.4 * sin(th), -9.0 + bob, 3.0))
	p.r("Hips", 16.0 + 2.0 * sin(2.0 * th), -11.0 * cos(th), 1.0 * sin(th))
	p.r("Spine", 6.0, 6.0 * cos(th), -1.0 * sin(th))
	p.r("Chest", 6.0 + 1.5 * sin(2.0 * th + 0.4), 10.0 * cos(th), -1.0 * sin(th))
	p.r("Head", -22.0 - 2.0 * sin(2.0 * th), -5.0 * cos(th), 1.0 * sin(th))
	legs(p, foot_target(1.0, fl, 7.0), foot_target(-1.0, fr, 7.0), Lib.E(fl[2], 8.0, 0), Lib.E(fr[2], -8.0, 0),
		-0.6 * maxf(float(fl[2]), 0.0), -0.6 * maxf(float(fr[2]), 0.0))
	_runner_arms(p, cos(th), th)
	set_lids(p, 0.0)


func kick_runner(t: float, p) -> void:
	p.reset()
	_set_kit("dual")
	var ext: float = kf_f([[0.0, 0.75], [0.05, 1.0, "o"], [0.2, 1.0], [0.3, 0.2, "s"], [0.4, 0.0]], t)       # 踢腿伸直的程度
	var air: float = kf_f([[0.0, 1.0], [0.22, 1.0], [0.34, 0.0, "i"], [0.4, 0.0]], t)                       # 离地
	var lean: float = kf_f([[0.0, -16.0], [0.06, -24.0, "o"], [0.2, -20.0], [0.32, 10.0, "s"], [0.4, 14.0]], t)
	var land: float = _arc(t, 0.3, 0.4, 1.0)
	p.move("Hips", Vector3(0.0, -6.0 + 9.0 * air - 3.0 * land, 2.0 - 3.0 * ext))
	p.r("Hips", lean * 0.45, -20.0 * ext, 4.0 * ext)
	p.r("Spine", lean * 0.3, -10.0 * ext, 3.0 * ext)
	p.r("Chest", lean * 0.25, -8.0 * ext, 2.0 * ext)
	p.r("Head", -lean * 0.5 - 6.0, 16.0 * ext, 0.0)
	# 右腿：蹬直在前上方(脚尖朝上、脚底对着目标)→ 收回落地；左腿：收在身下 → 落地
	var kick: Vector3 = Vector3(-4.0, ANKLE_Y + 9.0 * air + 34.0, 25.0).lerp(Vector3(-6.5, ANKLE_Y, -1.0), 1.0 - ext)
	var tuck: Vector3 = Vector3(5.5, ANKLE_Y + 9.0 * air + 16.0, -6.0).lerp(Vector3(6.5, ANKLE_Y, 1.5), 1.0 - air)
	legs(p, tuck, kick, Lib.E(30.0 * air, 6.0, 0.0), Lib.E(-70.0 * ext, -10.0, 0.0), 0.0, 0.0)
	# 双臂往后甩开配重(拳头朝后下)，落地时收回冲刺位
	var r0: Quaternion = _dual_rot(Vector3(-0.1, 0.35, 1.0))
	var gr: Vector3 = Vector3(-17.0, 55.0, -6.0).lerp(Vector3(-12.5, 52.0, 4.0), 1.0 - ext)
	var gl: Vector3 = Vector3(17.0, 60.0, -2.0).lerp(Vector3(12.5, 52.0, 4.0), 1.0 - ext)
	hold_bow(p, follow(p, "Chest", gr), _chest_q(p) * r0, _chest_dir(p, Vector3(-0.8, -0.4, -0.4)))
	fist_r(p, 85.0)
	hold_left(p, follow(p, "Chest", gl), _chest_q(p) * mirror_q(r0), _chest_dir(p, Vector3(0.8, -0.4, -0.4)))
	fist_l(p, 85.0)
	set_lids(p, 0.0)


func fidget_runner(t: float, p) -> void:
	p.reset()
	_stow(p)
	var bounce: float = kf_f([[0.0, 0.0], [0.3, 1.0], [1.4, 1.0], [1.7, 0.0]], t)
	var hop: float = absf(sin(TAU * t / 0.45)) * bounce
	var tug: float = kf_f([[0.0, 0.0], [1.7, 0.0], [1.95, 1.0], [2.5, 1.0], [2.7, 0.0]], t)
	var pull: float = _arc(t, 1.95, 2.25, 1.0) + _arc(t, 2.25, 2.5, 0.6)
	var stretch: float = kf_f([[0.0, 0.0], [2.7, 0.0], [3.0, 1.0], [3.6, 1.0], [3.9, 0.0]], t)
	_base(p, 0.6 * sin(TAU * t / 0.9) * bounce, 2.2 * hop - 1.0 * stretch, 0.0, 6.0 * bounce + 3.0 * tug, 0.0, 0.0, 7.5, 0.0, 0.5 * bounce)
	if stretch > 0.0:
		# 右脚往后勾起来，右手抓住脚背拉伸大腿(左腿单腿站)
		legs(p, Vector3(6.5, ANKLE_Y, 0.0), Vector3(-6.0, ANKLE_Y + 26.0 * stretch, -10.0 * stretch).lerp(Vector3(-7.5, ANKLE_Y, -0.5), 1.0 - stretch),
			Lib.E(0.0, 6.0, 0.0), Lib.E(-40.0 * stretch, -6.0, 0.0), 0.0, 0.0)
	_head(p, 4.0 * tug - 6.0 * bounce, -10.0 * tug, 0.0)
	var g_guard := [Vector3(-7.5, 66.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 1.0, 0.3), Vector3(0.0, 0.0, -1.0), 80.0]      # 拳头举在下巴前(左手的胸腔量)
	var g_wrist := [Vector3(4.0, 57.0 + 1.5 * pull, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(-1.0, 0.0, 0.2), Vector3(0.0, 1.0, 0.0), 70.0]
	var g_heel := [Vector3(13.5, 44.0, -9.0), Vector3(0.5, -0.2, -1.0), Vector3(0.0, -1.0, -0.2), Vector3(-1.0, 0.0, 0.0), 75.0]
	var g_wrist_r := [Vector3(10.0, 54.0, 12.0), Vector3(1.0, -0.5, -0.3), Vector3(-0.3, 0.2, 1.0), Vector3(0.0, -1.0, 0.0), 80.0]
	if stretch > 0.0:
		_hand_mix(p, "R", G_RELAX, g_heel, stretch)
		_hand_mix(p, "L", G_RELAX, G_HIP, stretch)
	elif tug > 0.0:
		_hand_mix(p, "L", G_RELAX, g_wrist, tug)
		_hand_mix(p, "R", G_RELAX, g_wrist_r, tug)
	else:
		_hand_mix(p, "L", G_RELAX, g_guard, bounce)
		_hand_mix(p, "R", G_RELAX, g_guard, bounce)
	set_lids(p, maxf(0.15 * stretch, blink_k(t, 1.6)))


func victory_runner(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var pump: float = maxf(0.0, sin(th * 2.0))
	var tap: float = maxf(0.0, sin(th * 4.0))
	_base(p, 0.5 * sin(th), 0.3 * pump, -6.0, -4.0, 3.0, 0.0, 7.5, 1.0, 0.0)
	legs(p, Vector3(6.5, ANKLE_Y, 0.5), Vector3(-7.5, ANKLE_Y + 1.5 * tap, 1.5), Lib.E(0.0, 6.0, 0.0), Lib.E(18.0 * tap, -10.0, 0.0), 0.0, -14.0 * tap)
	_head(p, -8.0 - 3.0 * pump, 6.0, -6.0)
	_on_hip(p, "L")
	var g_up := [Vector3(15.0, 86.0 + 3.0 * pump, 5.0), Vector3(1.0, -0.3, -0.5), Vector3(0.1, 1.0, 0.2), Vector3(-0.3, 0.0, 1.0), 85.0]     # 右拳高举(右手自动镜像)
	_hand_mix(p, "R", g_up, g_up, 0.0)
	if fmod(t, 2.0) > 0.9 and fmod(t, 2.0) < 1.35:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 幻形节点
## chant_spy(60f 循环 = 少女幻嘘的吟唱)：浮在半空，双臂往两侧张开、托着两捆书简(像在指挥满场的文字)，头微仰、半闭眼
## death_spy(60f = 少女幻嘘之后的强制阵亡)：接着往上升，右手食指竖在唇前("嘘——")，左手垂下，闭眼低头，书简缩没(化成文字散掉由表现层做)
## fidget_spy(4s)：左右瞟两眼(特工)，双手理一理西装领口，再竖起食指在唇前"嘘"
## victory_spy(2s 循环)：左手叉腰，右手食指抵在唇前，歪头 + 眨眼，轻轻晃
const SPY_TABLE := {"chant_spy": [90.0 * F, true], "death_spy": [60.0 * F, false]}
const G_SHH := [Vector3(1.2, 76.8, 12.8), Vector3(1.0, -0.5, -0.3), Vector3(-0.1, 1.0, 0.25), Vector3(-1.0, 0.0, 0.2), 40.0]   # 食指竖在唇前(右手自动镜像)


func spy_table(t: Dictionary) -> void:
	for nm: String in SPY_TABLE.keys():
		t[nm] = {"dur": float(SPY_TABLE[nm][0]), "loop": bool(SPY_TABLE[nm][1]), "fn": Callable(self, nm)}


## 少女幻嘘的吟唱(3 秒循环)：悬在半空，右手食指竖在唇前"嘘——"(右手的刀收起来)，左手反握着刀垂在身侧往外撇；
## 微微仰着脸、半闭眼，左右慢慢晃，像在对整片战场说悄悄话
func chant_spy(t: float, p) -> void:
	p.reset()
	var T := 3.0
	var th: float = TAU * t / T
	var s1: float = sin(th)
	var lift: float = MAGI_FLOAT + 1.6 * sin(th * 2.0)
	p.move("Hips", Vector3(0.8 * s1, -1.7 + lift, 0.0))
	p.r("Hips", 2.0, 6.0 * s1, 2.0 * s1)
	p.r("Spine", -3.0, 4.0 * s1, -1.0 * s1)
	p.r("Chest", -5.0 + 0.6 * sin(th * 2.0), 4.0 * s1, -1.0 * s1)
	_magi_dangle(p, lift, 0.3 + 0.1 * sin(th + 0.8))
	p.scale_("Bow", Vector3.ONE * 0.001)
	_hand_mix(p, "R", G_SHH, G_SHH, 0.0)
	var cq: Quaternion = _chest_q(p)
	hold_left(p, follow(p, "Chest", Vector3(19.0, 50.0 + 0.8 * s1, 6.0)), wrot(cq * Vector3(0.45, -0.85, 0.2), cq * Vector3(0.0, 0.0, 1.0)),
		_chest_dir(p, Vector3(0.6, -0.4, -0.6)))
	fist_l(p, 70.0)
	_head(p, -14.0 + 2.0 * sin(th * 2.0), -6.0 * s1, 8.0 + 3.0 * s1)        # 仰着脸(俯视的战斗镜头看得见竖在唇前的手指)
	set_lids(p, 0.6)


func death_spy(t: float, p) -> void:
	p.reset()
	var f: float = Lib.smoother(t / 1.6)
	var lift: float = MAGI_FLOAT + 22.0 * f
	p.move("Hips", Vector3(0.0, -1.7 + lift, 0.0))
	p.r("Hips", -2.0 + 3.0 * f, 0.0, 0.0)
	p.r("Spine", 4.0 * f, 0.0, 0.0)
	p.r("Chest", 4.0 * f, 0.0, 0.0)
	_magi_dangle(p, lift, 0.35 + 0.4 * f)
	_hand_mix(p, "R", G_RELAX, G_SHH, Lib.smooth(t / 0.5))
	_hand_mix(p, "L", G_RELAX, G_RELAX, 0.0)
	_head(p, 14.0 * f, 0.0, 6.0 * f)
	p.scale_("Bow", Vector3.ONE * maxf(0.001, 1.0 - Lib.smooth(t / 0.4)))
	p.scale_("Weapon_L", Vector3.ONE * maxf(0.001, 1.0 - Lib.smooth(t / 0.4)))
	set_lids(p, maxf(0.3, Lib.smooth((t - 0.3) / 0.5)))


func fidget_spy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.35, -1.0], [0.9, -1.0], [1.2, 1.0], [1.7, 1.0], [2.0, 0.0]], t)
	var lapel: float = kf_f([[0.0, 0.0], [1.9, 0.0], [2.2, 1.0], [2.8, 1.0], [3.0, 0.0]], t)
	var tug: float = _arc(t, 2.25, 2.55, 1.0)
	var shh: float = kf_f([[0.0, 0.0], [2.95, 0.0], [3.2, 1.0], [3.7, 1.0], [3.95, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.4), 0.0, 6.0 * look, 2.0 + 3.0 * lapel, 0.0, 0.0, 5.5, 1.0, 0.0)
	_head(p, 4.0 * lapel - 3.0 * shh, 22.0 * look, 6.0 * shh)
	var g_lapel := [Vector3(5.5, 62.0 + 1.5 * tug, 11.5), Vector3(1.0, -0.6, -0.3), Vector3(0.1, 1.0, 0.2), Vector3(-1.0, 0.0, 0.3), 60.0]
	if shh > 0.0:
		_hand_mix(p, "R", G_RELAX, G_SHH, shh)
		_hand_mix(p, "L", G_RELAX, G_HIP, shh)
	else:
		_hand_mix(p, "L", G_RELAX, g_lapel, lapel)
		_hand_mix(p, "R", G_RELAX, g_lapel, lapel)
	set_lids(p, maxf(0.25 * absf(look), blink_k(t, 3.4)))


func victory_spy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.6 * sin(th), 0.0, -4.0, 1.0, 3.0 * sin(th), 0.0, 5.5, 1.5, 0.0)
	_head(p, -2.0, 4.0, 9.0 + 2.0 * sin(th))
	_on_hip(p, "L")
	_hand_mix(p, "R", G_SHH, G_SHH, 0.0)
	if fmod(t, 2.0) > 0.8 and fmod(t, 2.0) < 1.3:
		_wink(p, "R")
	else:
		set_lids(p, 0.15)


# =============================================================== 幽灵犬(四足：身体整块挂 Hips，头 + 脖子挂 Neck，两条人腿链 = 对角的两对腿)
## idle_dog(3.2s 循环)：站着喘气，头一点一点；run_dog(20f 循环)：小跑(人形的交替迈腿 = 对角步态，身体不扭)；
## attack_dog(18f = 0.6s)：往后一缩 → 扑上去咬(0.2s)→ 落回来
const DOG_TABLE := {"idle_dog": [3.2, true], "run_dog": [20.0 * F, true], "attack_dog": [18.0 * F, false]}


func dog_table(t: Dictionary) -> void:
	for nm: String in DOG_TABLE.keys():
		t[nm] = {"dur": float(DOG_TABLE[nm][0]), "loop": bool(DOG_TABLE[nm][1]), "fn": Callable(self, nm)}


func idle_dog(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 0.8
	p.move("Hips", Vector3(0.0, 0.25 * sin(th), 0.0))
	p.r("Neck", 2.0 * sin(TAU * t / 1.6), 6.0 * sin(TAU * t / 3.2), 0.0)
	set_lids(p, blink_k(t, 1.7))


func run_dog(t: float, p) -> void:
	var T := 20.0 * F
	var ph := fposmod(t / T, 1.0)
	var th := TAU * ph
	p.reset()
	var fl: Array = foot_track(ph, 9.0, 7.0, 0.42)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 9.0, 7.0, 0.42)
	p.move("Hips", Vector3(0.0, 1.2 * absf(sin(th)), 0.0))
	p.r("Hips", 2.0 * sin(2.0 * th), 0.0, 0.0)
	p.r("Neck", -3.0 * sin(2.0 * th + 0.5), 0.0, 0.0)
	legs(p, foot_target(1.0, fl, 4.5), foot_target(-1.0, fr, 4.5), Lib.E(fl[2] * 0.5, 0, 0), Lib.E(fr[2] * 0.5, 0, 0), 0.0, 0.0)
	set_lids(p, 0.0)


func attack_dog(t: float, p) -> void:
	p.reset()
	var lunge: float = kf_f([[0.0, 0.0], [0.1, -0.4, "o"], [0.2, 1.0, "i"], [0.32, 1.0], [0.6, 0.0, "s"]], t)
	var up: float = _arc(t, 0.1, 0.34, 1.0)
	p.move("Hips", Vector3(0.0, 9.0 * up, 14.0 * lunge))
	p.r("Hips", -18.0 * up + 10.0 * maxf(0.0, -lunge), 0.0, 0.0)
	p.r("Neck", 28.0 * maxf(0.0, lunge) - 14.0 * up, 0.0, 0.0)
	legs(p, Vector3(6.5, ANKLE_Y + 7.0 * up, 1.0 + 11.0 * lunge), Vector3(-6.5, ANKLE_Y + 4.0 * up, -1.0 + 7.0 * lunge),
		Lib.E(0.0, 0.0, 0.0), Lib.E(0.0, 0.0, 0.0), 0.0, 0.0)
	set_lids(p, 0.0)


# =============================================================== 幻灵节点
## chant_medium(60f 循环 = 少女幻葬的吟唱)：浮在半空，右手托着翻开的魔典举在胸前、低头念，左手往旁边张开掌心朝上(灵魂在领域里转)
## death_medium(60f = 少女幻葬之后的强制阵亡)：接着往上升，魔典合上缩没，双手交叠在胸前、仰头闭眼(化成灵魂散掉由表现层做)
## fidget_medium(4s)：双手捧着一团看不见的灵火低头看(左手轻轻拨两下)，再抬头对着身边看不见的朋友歪头一笑、伸手摸摸空气
## victory_medium(2s 循环)：右手按在胸前，左手轻轻挥(和看不见的朋友打招呼)，歪头 + 眨眼(武器都收起)
const MEDIUM_TABLE := {"chant_medium": [90.0 * F, true], "death_medium": [60.0 * F, false]}


func medium_table(t: Dictionary) -> void:
	for nm: String in MEDIUM_TABLE.keys():
		t[nm] = {"dur": float(MEDIUM_TABLE[nm][0]), "loop": bool(MEDIUM_TABLE[nm][1]), "fn": Callable(self, nm)}


## 少女幻葬的吟唱(3 秒循环)：悬在半空，左手高高举起、掌心朝天召唤亡魂(指尖慢慢张合)，右手把摊开的魔典托在身前；
## 仰着头、胸口挺起，身子随着灵魂的回旋慢慢左右转
func chant_medium(t: float, p) -> void:
	p.reset()
	var T := 3.0
	var th: float = TAU * t / T
	var s1: float = sin(th)
	var lift: float = MAGI_FLOAT + 1.8 * sin(th * 2.0)
	p.move("Hips", Vector3(0.0, -1.7 + lift, 0.0))
	p.r("Hips", -3.0, 10.0 * s1, 0.0)
	p.r("Spine", -4.0 + 0.6 * sin(th * 2.0), 6.0 * s1, 0.0)
	p.r("Chest", -7.0 + 0.6 * sin(th * 2.0), 6.0 * s1, 0.0)
	_magi_dangle(p, lift, 0.3 + 0.12 * sin(th + 0.8))
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", Vector3(-8.0, 60.0 + 0.6 * s1, 16.0)), grot(cq * Vector3(0.1, -0.3, 1.0), cq * Vector3(0.0, 1.0, 0.3)),
		_chest_dir(p, Vector3(-1.0, -0.6, -0.4)))
	fist_r(p, 50.0)
	_hand(p, "L", Vector3(24.0, 80.0 + 1.5 * sin(th * 2.0), 9.0), Vector3(0.6, -0.8, -0.3), Vector3(0.55, 0.8, 0.2), Vector3(0.1, 0.4, 0.9),
		4.0 + 10.0 * (0.5 + 0.5 * sin(th * 2.0)))
	_head(p, -18.0 + 2.0 * sin(th * 2.0), -4.0 * s1, 4.0 * s1)
	set_lids(p, 0.5)


func death_medium(t: float, p) -> void:
	p.reset()
	var f: float = Lib.smoother(t / 1.6)
	var lift: float = MAGI_FLOAT + 24.0 * f
	p.move("Hips", Vector3(0.0, -1.7 + lift, 0.0))
	p.r("Spine", -4.0 * f, 0.0, 0.0)
	p.r("Chest", -6.0 * f, 0.0, 0.0)
	_magi_dangle(p, lift, 0.4 + 0.4 * f)
	var g_heart := [Vector3(3.5, 63.0, 11.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.8, 0.3, 0.2), Vector3(0.0, 0.0, -1.0), 20.0]
	_hand_mix(p, "R", G_RELAX, g_heart, Lib.smooth(t / 0.5))
	_hand_mix(p, "L", G_RELAX, g_heart, Lib.smooth((t - 0.1) / 0.5))
	_head(p, -14.0 * f, 0.0, 5.0 * f)
	p.scale_("Bow", Vector3.ONE * maxf(0.001, 1.0 - Lib.smooth(t / 0.4)))
	set_lids(p, maxf(0.4, Lib.smooth((t - 0.2) / 0.5)))


func fidget_medium(t: float, p) -> void:
	p.reset()
	_stow(p)
	var read: float = kf_f([[0.0, 0.0], [0.3, 1.0], [2.0, 1.0], [2.3, 0.0]], t)
	var flip: float = _arc(t, 0.8, 1.15, 1.0) + _arc(t, 1.4, 1.75, 1.0)
	var pet: float = kf_f([[0.0, 0.0], [2.3, 0.0], [2.6, 1.0], [3.6, 1.0], [3.95, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.3), 0.0, -6.0 * pet, 2.0 + 6.0 * read, 4.0 * pet, 0.0, 5.5, 1.0, 0.0)
	_head(p, 18.0 * read - 4.0 * pet, -16.0 * pet, 12.0 * pet)
	var g_book := [Vector3(-4.0, 58.0, 13.5), Vector3(1.0, -0.6, -0.3), Vector3(0.2, 0.2, 1.0), Vector3(0.0, 1.0, 0.0), 50.0]   # 右手托书(右手自动镜像)
	var g_page := [Vector3(-1.0 + 4.0 * flip, 60.5 + 1.5 * flip, 14.5), Vector3(1.0, -0.5, -0.3), Vector3(-0.6, 0.0, 0.8), Vector3(0.0, -1.0, 0.0), 30.0]
	var g_pet := [Vector3(19.0, 55.0 + 1.5 * sin(t * 9.0), 9.0), Vector3(0.8, -0.5, -0.4), Vector3(0.6, -0.2, 0.7), Vector3(0.0, -1.0, 0.0), 12.0]
	_hand_mix(p, "R", G_RELAX, g_book, maxf(read, 0.6))
	if pet > 0.0:
		_hand_mix(p, "L", G_RELAX, g_pet, pet)
	else:
		_hand_mix(p, "L", G_RELAX, g_page, read)
	set_lids(p, maxf(0.35 * read, blink_k(t, 3.1)))


func victory_medium(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	_base(p, 0.5 * sin(th), 0.3 * absf(sin(th)), 4.0, 1.0, -3.0 * sin(th), 0.0, 5.5, 1.0, 0.0)
	_head(p, 0.0, -6.0, -9.0 + 2.0 * sin(th))
	var g_hug := [Vector3(-3.0, 60.0, 12.0), Vector3(1.0, -0.6, -0.3), Vector3(0.5, 0.5, 0.6), Vector3(0.0, 0.0, -1.0), 45.0]
	var g_wave := [Vector3(19.0, 79.0, 5.0), Vector3(1.0, -0.3, -0.5), Vector3(0.35 * sin(t * 10.0), 1.0, 0.0), Vector3(0.0, 0.0, 1.0), 6.0]
	_hand_mix(p, "R", g_hug, g_hug, 0.0)
	_hand_mix(p, "L", g_wave, g_wave, 0.0)
	if fmod(t, 2.0) > 1.0 and fmod(t, 2.0) < 1.45:
		_wink(p, "L")
	else:
		set_lids(p, 0.2)


## 幽灵犬：低头嗅嗅地面 → 抬头喘气、甩甩头
func fidget_dog(t: float, p) -> void:
	p.reset()
	_stow(p)
	var sniff: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.8, 1.0], [2.2, 0.0]], t)
	var shake: float = _arc(t, 2.4, 3.2, 1.0)
	p.move("Hips", Vector3(0.0, 0.3 * sin(TAU * t / 0.8), 0.0))
	p.r("Neck", 32.0 * sniff + 3.0 * sin(t * 14.0) * sniff, 18.0 * sin(t * 20.0) * shake, 0.0)
	set_lids(p, blink_k(t, 2.9))


func victory_dog(t: float, p) -> void:
	p.reset()
	_stow(p)
	var hop: float = absf(sin(TAU * t / 0.6))
	p.move("Hips", Vector3(0.0, 4.0 * hop, 0.0))
	p.r("Hips", -6.0 * hop, 0.0, 0.0)
	p.r("Neck", -8.0, 0.0, 12.0 * sin(TAU * t / 1.2))
	legs(p, Vector3(6.5, ANKLE_Y + 3.0 * hop, 1.0), Vector3(-6.5, ANKLE_Y + 2.0 * hop, -1.0), Lib.E(0.0, 0.0, 0.0), Lib.E(0.0, 0.0, 0.0), 0.0, 0.0)
	set_lids(p, 0.0)


## 幽灵：原地飘着转一圈，两只骨手摆一摆
func fidget_ghost(t: float, p) -> void:
	p.reset()
	_stow(p)
	var spin: float = kf_f([[0.0, 0.0], [0.4, 0.0], [1.6, 360.0, "s"], [3.2, 360.0]], t)
	p.r("Root", 0.0, spin, 0.0)
	p.move("Hips", Vector3(0.0, 1.5 * sin(TAU * t / 1.6), 0.0))
	var wave: float = sin(t * 9.0) * kf_f([[0.0, 0.0], [1.8, 0.0], [2.1, 1.0], [2.9, 1.0], [3.2, 0.0]], t)
	p.r("UpperArm_L", 0.0, 0.0, 40.0 + 20.0 * wave)
	p.r("UpperArm_R", 0.0, 0.0, -40.0 - 20.0 * wave)
	set_lids(p, 0.0)


func victory_ghost(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 1.6
	p.move("Hips", Vector3(0.0, 2.0 * sin(th), 0.0))
	p.r("UpperArm_L", -10.0, 0.0, 140.0 + 15.0 * sin(th * 2.0))
	p.r("UpperArm_R", -10.0, 0.0, -140.0 - 15.0 * sin(th * 2.0))
	_head(p, -6.0, 0.0, 8.0 * sin(th))
	set_lids(p, 0.0)


# =============================================================== 真望节点
## fidget_leader(4s)：右手扶一扶帽檐、环视一圈，再抬手往前一指("前进")；victory_leader(2s 循环)：立正、右手举到帽檐敬礼，左手叉腰，轻轻点头 + 眨眼
func fidget_leader(t: float, p) -> void:
	p.reset()
	_stow(p)
	var cap: float = kf_f([[0.0, 0.0], [0.3, 1.0], [1.1, 1.0], [1.4, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [1.4, 0.0], [1.8, -1.0], [2.3, 1.0], [2.6, 0.0]], t)
	var point: float = kf_f([[0.0, 0.0], [2.6, 0.0], [2.9, 1.0], [3.6, 1.0], [3.95, 0.0]], t)
	_base(p, 0.3 * sin(t * 1.3), 0.0, 14.0 * look - 8.0 * point, -2.0 * point, 0.0, 0.0, 6.0, 1.0 + 2.0 * point, 0.0)
	_head(p, -3.0 * point + 4.0 * cap, 20.0 * look, 0.0)
	var g_cap := [Vector3(8.0, 86.0, 10.0), Vector3(1.0, -0.3, -0.4), Vector3(-0.5, 0.6, 0.6), Vector3(0.0, -1.0, 0.0), 30.0]      # 右手扶帽檐(右手自动镜像)
	var g_point := [Vector3(13.0, 68.0, 22.0), Vector3(1.0, -0.3, -0.2), Vector3(0.1, 0.15, 1.0), Vector3(-1.0, 0.0, 0.0), 55.0]
	if point > 0.0:
		_hand_mix(p, "R", G_RELAX, g_point, point)
	else:
		_hand_mix(p, "R", G_RELAX, g_cap, cap)
	_hand_mix(p, "L", G_RELAX, G_HIP, 0.85)
	set_lids(p, blink_k(t, 1.2))


func victory_leader(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var nod: float = maxf(0.0, sin(th))
	_base(p, 0.0, 0.0, 0.0, -2.0, 0.0, 0.0, 4.5, 0.0, 0.0)
	_head(p, -2.0 + 5.0 * nod, 0.0, 0.0)
	var g_salute := [Vector3(10.5, 82.5, 9.5), Vector3(1.0, -0.2, -0.3), Vector3(0.6, 0.5, 0.25), Vector3(0.0, -0.2, 1.0), 4.0]
	_hand_mix(p, "R", g_salute, g_salute, 0.0)
	_on_hip(p, "L")
	if fmod(t, 2.0) > 1.0 and fmod(t, 2.0) < 1.4:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 红之章的新余烬(2026-10-04)
## 傲慢的余烬 / 龙的余烬是人形(普攻、待机、跑步用法器 / 长柄的通用动作)，这里只有小动作和胜利动作；
## 嫉妒(眼球)、贪婪(魔典)、忧郁(水母)不是人形，动作直接写各骨头的转角(见下面各自的一节)。
const RED_TABLE := {
	"fidget_ember_pride": [4.0, false], "victory_ember_pride": [2.4, true],
	"fidget_ember_dragon": [4.0, false], "victory_ember_dragon": [2.0, true],
}


func red_table(t: Dictionary) -> void:
	for tbl: Dictionary in [RED_TABLE, ENVY_TABLE, MELANCHOLY_TABLE, GREED_TABLE, BARD_TABLE, PERFUMER_TABLE, VAMPIRE_TABLE, ABSOLVER_TABLE, SNIPER_TABLE, NEST_TABLE, COMMANDO_TABLE, KNIGHT_TABLE]:
		for nm: String in tbl.keys():
			t[nm] = {"dur": float(tbl[nm][0]), "loop": bool(tbl[nm][1]), "fn": Callable(self, nm)}


# ---------------------------------------------------------------- 傲慢的余烬：抬起爪子端详、轻蔑地一弹 / 叉腰、另一只手掌心朝上往前一摊
const G_CLAW_LOOK := [Vector3(6.0, 69.0, 12.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 0.8, 0.6), Vector3(-0.6, 0.0, -0.8), 34.0]
const G_FLICK := [Vector3(16.5, 63.0, 10.0), Vector3(1.0, -0.4, -0.3), Vector3(0.6, 0.2, 0.8), Vector3(0.0, -1.0, 0.0), 4.0]
const G_PRESENT := [Vector3(17.0, 65.0, 9.0), Vector3(1.0, -0.6, -0.3), Vector3(0.7, 0.0, 0.7), Vector3(0.0, 1.0, 0.0), 10.0]


func fidget_ember_pride(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.6, 1.0], [2.2, 1.0], [2.5, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [2.3, 0.0], [2.5, 1.0, "o"], [3.1, 1.0], [3.7, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 4.0), 0.0, -6.0 * look + 8.0 * flick, 2.0 * look - 4.0 * flick, 0.0, 0.0, 5.5)
	_head(p, 14.0 * look - 10.0 * flick, -14.0 * look + 10.0 * flick, 6.0 * look)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.6, G_CLAW_LOOK], [2.2, G_CLAW_LOOK], [2.5, G_FLICK], [3.1, G_FLICK], [3.7, G_RELAX]], t)
	_relax(p, "L")
	if look > 0.5:
		p.radd("Fingers_R", -8.0 * sin(t * 9.0), 0.0, 0.0)     # 一根根爪子翻过来看


func victory_ember_pride(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.6 * sin(th), 0.3 * sin(th * 2.0), 6.0, -5.0, 2.0 * sin(th), 0.0, 5.5)
	_head(p, -12.0, 8.0 + 4.0 * sin(th), 5.0)
	_on_hip(p, "L")
	var pr: Array = G_PRESENT.duplicate()
	pr[0] = (G_PRESENT[0] as Vector3) + Vector3(0.0, 1.0 * sin(th), 0.8 * sin(th))
	_hand_mix(p, "R", pr, pr, 0.0)


# ---------------------------------------------------------------- 龙的余烬：转转肩、抱臂斜眼一笑 / 叉腰、拳头高举(翅膀照常扇)
const G_DR_ARM_L := [Vector3(-3.5, 53.5, 11.5), Vector3(1.0, -0.7, -0.1), Vector3(-1.0, 0.1, 0.1), Vector3(0.0, 1.0, 0.2), 40.0]
const G_DR_ARM_R := [Vector3(-4.0, 57.5, 13.0), Vector3(1.0, -0.6, -0.1), Vector3(-1.0, 0.0, 0.15), Vector3(0.0, -1.0, 0.2), 40.0]


func fidget_ember_dragon(t: float, p) -> void:
	p.reset()
	_stow(p)
	var roll: float = kf_f([[0.0, 0.0], [0.3, 1.0], [1.2, 1.0], [1.5, 0.0]], t)
	var cross: float = kf_f([[0.0, 0.0], [1.6, 0.0], [2.0, 1.0, "o"], [3.4, 1.0], [3.9, 0.0]], t)
	_base(p, 0.5 * sin(t * TAU / 4.0), 0.0, 10.0 * roll * sin(t * 7.0), -5.0 * cross, 0.0, 0.0, 7.5, 1.0 * cross)
	_head(p, -6.0 * cross, 16.0 * cross, -6.0 * cross + 8.0 * roll * sin(t * 7.0))
	p.radd("Shoulder_R", 0.0, 0.0, 12.0 * roll * sin(t * 7.0))
	_hand_keys(p, "L", [[0.0, G_RELAX], [1.6, G_RELAX], [2.0, G_DR_ARM_L], [3.4, G_DR_ARM_L], [3.9, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [1.6, G_RELAX], [2.0, G_DR_ARM_R], [3.4, G_DR_ARM_R], [3.9, G_RELAX]], t)
	set_lids(p, maxf(0.4 * cross, blink_k(t, 1.0)))


func victory_ember_dragon(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var pump: float = maxf(0.0, sin(2.0 * th))
	_base(p, 0.8 * sin(th), 1.0 * pump, 6.0 * sin(th), -7.0, 0.0, 0.0, 8.0, 1.5)
	_head(p, -10.0 - 2.0 * pump, 14.0 * sin(th), 4.0 * sin(th))
	_on_hip(p, "L")
	var up: Array = G_FIST_UP.duplicate()
	up[0] = Vector3(18.5, 78.5 + 3.0 * pump, 4.0 + 1.5 * pump)
	_hand_mix(p, "R", up, up, 0.0)
	if fmod(t, 2.0) > 1.1 and fmod(t, 2.0) < 1.5:
		_wink(p, "R")
	else:
		set_lids(p, 0.0)


# ---------------------------------------------------------------- 嫉妒的余烬：浮空的眼球(tools/chars/ember_envy.gd)
## 挂骨：石球 + 眼珠 + 下眼睑 = Neck(转 Neck = 转眼珠：瞄准 / 东张西望)；上眼睑 = Head(Head 绕 X 正转 = 上眼睑沿球面往下盖 = 眯眼，
## Head 总角度保持在 -8° ~ +22° 之间：再往下上眼睑的上沿会漏出虹膜；负转 = 瞪大眼)；三块小余烬 = Halo(Head 的子骨：_envy_halo 抵消 Head 的转动，余烬不跟着眼睑走)。
## Hips 上下移 = 悬浮起伏，绕 X 正转 = 整个往前倾(触手都在 Hips 轴心下面，会跟着往后甩)。
## 触手：前左 / 前右 = Thigh → Shin 两节，左右两侧 = Hand，后左 / 后右 = LowerArm(Hand 的父骨)。触手骨绕 X 正转 = 尖往后(-Z)甩，绕 Z 转(乘左右号) = 往外张。
## 所有循环动作的频率都是 2π/时长 的整数倍(首尾接得上)。普攻每 0.5 秒一轮(持续光束)，起止都是 idle_envy 的 t = 0 姿势。
const ENVY_TABLE := {
	"idle_envy": [2.4, true], "run_envy": [0.8, true], "attack_envy": [15.0 / 30.0, false],
	"fidget_ember_envy": [3.6, false], "victory_ember_envy": [2.4, true],
}
## [骨头, 左右号(+1 = 左 / +X), 相位, 下一节骨头]
const ENVY_TENDRILS := [["Thigh_L", 1.0, 0.0, "Shin_L"], ["Thigh_R", -1.0, 2.1, "Shin_R"], ["LowerArm_L", 1.0, 3.0, ""], ["LowerArm_R", -1.0, 5.2, ""],
	["Hand_L", 1.0, 4.1, ""], ["Hand_R", -1.0, 0.9, ""]]


## 触手摆动：w = 角频率(循环动作里必须是 2π/时长 的整数倍)，amp = 摆幅(度)，trail = 整体往后拖(度)，flare = 往外张(度)。
## Hand 挂在 LowerArm 下面(跟着父骨一起转)：它自己的 trail / flare 只补差值
func _envy_tendrils(p, t: float, w: float, amp: float, trail: float = 0.0, flare: float = 0.0) -> void:
	for e: Array in ENVY_TENDRILS:
		var nm: String = e[0]
		var s: float = e[1]
		var a: float = w * t + float(e[2])
		var k: float = 0.6 if nm.begins_with("LowerArm") else (0.4 if nm.begins_with("Hand") else 1.0)
		var ka: float = 0.6 if nm.begins_with("LowerArm") else (0.8 if nm.begins_with("Hand") else 1.0)
		p.r(nm, trail * k + amp * ka * sin(a), amp * 0.35 * sin(a + 1.7), s * (flare * k + amp * 0.7 * ka * cos(a)))
		var low: String = e[3]
		if low != "":
			p.r(low, trail * 0.5 + amp * 1.3 * sin(a - 1.1), 0.0, s * (flare * 0.4 + amp * 0.9 * cos(a - 1.1)))


## 小余烬(Halo)：抵消 Head 的眯眼转动(squint = Head 绕 X 的角度)，再自己飘 off(体素，Head 空间)、绕竖轴转 yaw(度)
func _envy_halo(p, squint: float, off: Vector3, yaw: float) -> void:
	var hq := Quaternion(Vector3.RIGHT, deg_to_rad(squint)).inverse()
	var hl: Vector3 = rig.pos[rig.ids["Halo"]] - rig.pos[rig.ids["Head"]]
	p.rq("Halo", hq * Quaternion(Vector3.UP, deg_to_rad(yaw)))
	p.move("Halo", hq * (hl + off) - hl)


## 悬浮的基础姿势(= idle_envy 在 t 时刻，不含东张西望)；lean = 整个前倾，squint = 再眯多少，look = 眼珠往左(+X)转(度)
func _envy_hover(p, t: float, lean: float = 0.0, squint: float = 0.0, look: float = 0.0) -> void:
	var th: float = TAU * t / 2.4
	p.move("Hips", Vector3(0.0, 1.6 * sin(th), 0.0))
	p.r("Hips", 2.0 * sin(th + 1.2) + lean, 0.0, 2.2 * sin(th + 0.4))
	p.r("Neck", -1.4 * sin(th + 1.2), look, -1.1 * sin(th + 0.4))
	var sq: float = 4.0 + 2.0 * sin(2.0 * th) + squint
	p.r("Head", sq, 0.0, 0.0)
	_envy_halo(p, sq, Vector3(0.0, 1.2 * sin(th + 2.0), 0.0), 8.0 * sin(th))
	_envy_tendrils(p, t, TAU / 2.4, 7.0)


## 待机：悬浮着一上一下地起伏、轻轻晃，眼珠往左、往右瞟一下，眼睑半眯着一张一合，触手错开相位地摆
func idle_envy(t: float, p) -> void:
	p.reset()
	var glance: float = kf_f([[0.0, 0.0], [0.2, 0.0], [0.45, 9.0, "o"], [1.0, 9.0], [1.25, -7.0, "o"], [1.9, -7.0], [2.3, 0.0]], t)
	_envy_hover(p, t, 0.0, 0.0, glance)


## 移动：整个往前倾着飘(眼珠抬回来看着前方)，触手往后拖、摆得更快，小余烬落在后面
func run_envy(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 0.8
	p.move("Hips", Vector3(0.0, 1.0 * sin(th), 0.0))
	p.r("Hips", 14.0 + 2.0 * sin(th), 0.0, 3.0 * sin(th + 0.7))
	p.r("Neck", -10.0, 0.0, -2.0 * sin(th + 0.7))
	p.r("Head", 6.0, 0.0, 0.0)
	_envy_halo(p, 6.0, Vector3(0.0, -1.0 + 1.0 * sin(th + 1.5), -3.0), -5.0)
	_envy_tendrils(p, t, TAU / 0.8, 9.0, 14.0, 4.0)


## 普攻(持续光束，0.5 秒一轮)：0 ~ 0.1 秒往后一缩、眼睑眯紧(蓄力)；0.1 秒猛地往前一顶、眼睛瞪圆、触手往外一炸(出手)；0.5 秒回到起始姿势
func attack_envy(t: float, p) -> void:
	p.reset()
	var wind: float = kf_f([[0.0, 0.0], [0.08, 1.0, "o"], [0.1, 1.0], [0.14, 0.0]], t)
	var fire: float = kf_f([[0.0, 0.0], [0.09, 0.0], [0.12, 1.0, "o"], [0.22, 0.7], [0.5, 0.0]], t)
	_envy_hover(p, 0.0, -5.0 * wind + 6.0 * fire, 12.0 * wind - 9.0 * fire)
	p.madd("Hips", Vector3(0.0, 0.8 * wind, -1.5 * wind + 2.5 * fire))
	_envy_tendrils(p, 0.0, TAU / 2.4, 7.0, -6.0 * wind + 8.0 * fire, -4.0 * wind + 14.0 * fire)


## 待机小动作：疑神疑鬼地往左瞟、再往右瞟(整颗眼珠转过去，身子跟着歪，眼睑眯成一条缝)，回到正中，再狠狠眯一下、猛地瞪圆。
## 注意：Head 的总角度别超过 ~22°(上眼睑再往下滑，上沿会漏出一条虹膜)，所以不做整个闭眼的眨眼
func fidget_ember_envy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.4, 0.0], [0.85, 34.0, "o"], [1.55, 34.0], [2.05, -34.0, "o"], [2.75, -34.0], [3.15, 0.0]], t)
	var sq: float = kf_f([[0.0, 0.0], [0.5, 0.0], [0.9, 12.0], [1.6, 12.0], [1.8, 5.0], [2.1, 13.0], [2.8, 13.0], [3.05, 0.0], [3.25, 13.0, "o"], [3.42, -9.0, "o"], [3.6, 0.0]], t)
	_envy_hover(p, t, 0.0, sq, look)
	p.radd("Hips", 0.0, 0.0, -0.12 * look)


## 胜利：得意地一蹦一蹦、原地转一整圈，眼睛往上翘、眯成得意的半月，触手大大地张开摆
func victory_ember_envy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var spin: float = kf_f([[0.0, 0.0], [0.4, 0.0], [1.6, 360.0], [2.4, 360.0]], t)
	p.r("Root", 0.0, spin, 0.0)
	p.move("Hips", Vector3(0.0, 1.0 + 2.5 * absf(sin(1.5 * th)), 0.0))
	p.r("Hips", -4.0, 0.0, 3.0 * sin(th))
	p.r("Neck", -10.0 + 3.0 * sin(3.0 * th), 0.0, 0.0)
	var sq: float = 9.0 + 3.0 * sin(3.0 * th)
	p.r("Head", sq, 0.0, 0.0)
	_envy_halo(p, sq, Vector3(0.0, 2.0 * sin(2.0 * th + 1.0), 0.0), 20.0 * sin(th))
	_envy_tendrils(p, t, 2.0 * TAU / 2.4, 12.0, -4.0, 12.0)


const MELANCHOLY_TABLE := {
	"idle_melancholy": [2.4, true], "run_melancholy": [1.2, true],
	"fidget_ember_melancholy": [4.0, false], "victory_ember_melancholy": [2.4, true],
}


# ---------------------------------------------------------------- 忧郁的余烬(精英·坦克，从不攻击)：飘着的熔岩水母
## 伞盖挂 Head(脉动 = Head 缩放：收缩时变窄变高、舒张时变宽变扁)；外圈触手整条挂 Shoulder / UpperArm(根部离转轴近)；
## 内圈触手三节 UpperArm → LowerArm → Fingers；口腕 Spine → Thigh → Shin → Foot。Hand / Thumb / Spine / Chest 不转
## (内圈触手的下段 Fingers 是 Hand 的子骨，口柄挂在 Spine 上，转了会和伞盖 / 腿骨链错开)。普攻沿用待机。
## [骨头, 摆幅系数, 相位(弧度，沿触手往下越来越晚 = 往下传的波), 左右(+1 左 / -1 右), 收缩时往里收的系数, 往后拖的系数]
const MEL_BONES := [
	["Shoulder_L", 0.45, 0.0, 1.0, 0.5, 1.0], ["Shoulder_R", 0.45, 2.6, -1.0, 0.5, 1.0],
	["UpperArm_L", 0.55, 0.7, 1.0, 0.4, 0.2], ["UpperArm_R", 0.55, 3.3, -1.0, 0.4, 0.2],
	["LowerArm_L", 0.4, 1.5, 1.0, 0.3, 0.3], ["LowerArm_R", 0.4, 4.1, -1.0, 0.3, 0.3],
	["Fingers_L", 1.1, 2.4, 1.0, 0.6, 0.6], ["Fingers_R", 1.1, 5.0, -1.0, 0.6, 0.6],
	["Thigh_L", 0.6, 0.9, 1.0, 0.5, 1.0], ["Thigh_R", 0.6, 3.9, -1.0, 0.5, 1.0],
	["Shin_L", 0.9, 1.8, 1.0, 0.7, 0.5], ["Shin_R", 0.9, 4.8, -1.0, 0.7, 0.5],
	["Foot_L", 0.8, 2.7, 1.0, 0.6, 0.5], ["Foot_R", 0.8, 5.7, -1.0, 0.6, 0.5],
]


## 一次脉动的收缩量(0 = 舒张，1 = 收缩到底)：up 秒内很快收紧，剩下的时间慢慢舒张；按周期取模，往后错开 t 就是"跟在后面"
func _mel_pulse(t: float, dur: float, up: float) -> float:
	return kf_f([[0.0, 0.0], [up, 1.0], [dur, 0.0]], fposmod(t, dur))


## 伞盖：c > 0 收缩(变窄变高)，c < 0 比平时更宽更扁(泄气)
func _mel_bell(p, c: float) -> void:
	p.scale_("Head", Vector3(1.03 - 0.085 * c, 0.97 + 0.085 * c, 1.03 - 0.085 * c))


## 触手 / 口腕：每根骨头 = 慢慢摆(相位沿触手往下越来越晚) + 跟着伞盖的收缩往里收(比伞盖晚一点，越往下越晚)；
## amp = 摆幅(度)，period = 摆一圈的秒数(必须整除动作时长)，squeeze = 收缩时往里收(度)，up = 收缩用时(秒)，
## lift = 整体往后拖(+，绕 X 轴；跑动时触手往后飘)，spread = 整体往外张(+，度)
func _mel_tentacles(p, t: float, period: float, amp: float, squeeze: float, up: float, lift: float = 0.0, spread: float = 0.0) -> void:
	var w: float = TAU / period
	for e: Array in MEL_BONES:
		var k: float = float(e[1])
		var ph: float = float(e[2])
		var m: float = float(e[3])
		var sq: float = squeeze * float(e[4]) * _mel_pulse(t - 0.25 - 0.08 * ph, period, up)
		p.r(str(e[0]), amp * k * sin(w * t - ph) + lift * float(e[5]),
			amp * 0.3 * k * sin(w * t - ph * 1.3),
			(amp * 0.7 * k * cos(w * t - ph) - sq + spread * float(e[4])) * m)


func idle_melancholy(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	var c: float = _mel_pulse(t, 2.4, 0.75)
	var rise: float = _mel_pulse(t - 0.25, 2.4, 0.75)
	_mel_bell(p, c)
	p.move("Hips", Vector3(0.0, -1.2 + 2.4 * rise, 0.0))
	p.r("Hips", 1.2 * sin(th), 0.0, 0.9 * cos(th))
	p.r("Neck", 0.0, 0.0, 0.8 * sin(th + 0.8))
	_mel_tentacles(p, t, 2.4, 3.5, 5.0, 0.75)


## 移动：往前倾，一下更猛的脉动(0.4 秒收紧)，触手往后拖
func run_melancholy(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 1.2
	var c: float = _mel_pulse(t, 1.2, 0.4)
	var rise: float = _mel_pulse(t - 0.12, 1.2, 0.4)
	_mel_bell(p, 1.35 * c - 0.15)
	p.move("Hips", Vector3(0.0, -1.0 + 3.0 * rise, 0.0))
	p.r("Hips", 11.0 + 3.0 * c, 0.0, 1.2 * sin(th))
	_mel_tentacles(p, t, 1.2, 4.5, 8.0, 0.4, 6.0 - 3.0 * c)


## 待机小动作：叹一口气 —— 先微微吸一口(收紧、往上一提)，然后整个泄下去(往下沉、伞盖变宽变扁、往一边歪)，
## 触手往里蜷起来一点，停一会儿，再慢慢舒展回来
func fidget_ember_melancholy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var sigh: float = kf_f([[0.0, 0.0], [0.7, -0.35], [1.7, 1.0], [2.7, 1.0], [4.0, 0.0]], t)
	var curl: float = kf_f([[0.0, 0.0], [1.0, 0.0], [1.9, 1.0], [2.9, 1.0], [3.9, 0.0]], t)
	var droop: float = maxf(sigh, 0.0)
	_mel_bell(p, -0.7 * sigh)
	p.move("Hips", Vector3(0.0, -3.2 * sigh, 0.0))
	p.r("Hips", 4.0 * droop + 0.8 * sin(t * TAU / 2.0), 0.0, -5.0 * droop)
	p.r("Neck", 3.0 * droop, 0.0, -2.0 * droop)
	_mel_tentacles(p, t, 2.0, 2.5 * (1.0 - 0.5 * curl), 0.0, 0.7, -3.0 * curl, -2.0 * curl)
	# 蜷：越往下的关节往前、往里勾得越多(左右两边镜像)
	for s: String in ["_L", "_R"]:
		var m: float = 1.0 if s == "_L" else -1.0
		p.radd("LowerArm" + s, -4.0 * curl, 0.0, -3.0 * curl * m)
		p.radd("Fingers" + s, -14.0 * curl, 0.0, -8.0 * curl * m)
		p.radd("Shin" + s, -9.0 * curl, 0.0, -4.0 * curl * m)
		p.radd("Foot" + s, -16.0 * curl, 0.0, -6.0 * curl * m)


## 胜利：飘得高一点、一上一下地慢慢浮，触手摆得更开，整个身子左右慢慢转
func victory_ember_melancholy(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var c: float = _mel_pulse(t, 2.4, 0.7)
	_mel_bell(p, 0.9 * c)
	p.r("Root", 0.0, 22.0 * sin(th), 0.0)
	p.move("Hips", Vector3(0.0, 2.0 + 1.6 * sin(th - 0.6), 0.0))
	p.r("Hips", -2.0 + 1.5 * sin(th), 0.0, 1.5 * cos(th))
	_mel_tentacles(p, t, 2.4, 7.0, 6.0, 0.7, -2.0, 6.0)


# ---------------------------------------------------------------- 贪婪的余烬：悬在半空的魔典(模型 tools/chars/ember_greed.gd)
## 挂骨：书脊 Chest；左右两半 Shoulder_L / Shoulder_R；书缝里的主火 Eyelid_L、两页上的小火苗 + 火星 Eyelid_R；
## 书脊前端那条链子 Halo；书脊两侧两条链子 Thigh(大腿骨关节处弯一下)+ Shin(小腿骨关节处再弯)；书角的短坠子跟着两半。
## build_anims 只给 Root / Hips / Chest / Halo / Eyelid_* 烘位移、只给 Eyelid_*(和武器骨)烘缩放(POS_BONES / SCL_BONES)，所以：
##   整本书的飘、倾 = Hips 绕书本中心(GREED_ORG)转 + 位移；开合 = Shoulder 绕自己的关节、沿书脊方向(GREED_HINGE)转(合上 ≈ 86°)；
##   火 = Eyelid 绕火焰根部(GREED_FLAME)缩放 / 摆(缩到 0 = 火被吞回书里)；链子永远朝下垂(抵消书的倾斜)，各自错开相位地摆。
## 这几根骨头都用 _gb_set / _gb_aim 直接摆"想要的蒙皮变换 / 世界朝向"，父骨骼怎么转都会被抵消。
## 注意：通用动作(眨眼的 set_lids)会把 Eyelid 压扁 = 火看不见，这本书只该播下面这几个动作(吟唱也别退回通用 idle)。
const GREED_TABLE := {
	"idle_greed": [2.4, true], "run_greed": [0.8, true], "attack_greed": [27.0 / 30.0, false],
	"fidget_ember_greed": [4.0, false], "victory_ember_greed": [2.4, true],
}
const GREED_ORG := Vector3(0.0, 62.0, 0.0)              # 书本中心：整本书转动的支点
const GREED_HINGE := Vector3(0.0, -0.5, 0.8660254)       # 书脊方向(书页朝前仰 30°)：两半绕它开合
const GREED_N := Vector3(0.0, 0.8660254, 0.5)            # 书页法线
const GREED_FLAME := Vector3(0.0, 68.0, 2.0)             # 书缝里火焰的根部(法术从它上方 (0, 79, 2) 一带出手)
const GREED_FRONT := Vector3(0.5, 46.0, 8.5)             # 书脊前端那条链子(Halo)的挂点


## 把 bone 的蒙皮变换(相对静止姿势)设成 m：按父骨骼当前的姿势反算局部的旋转 / 位移 / 缩放
## (位移、缩放只有上面说的几根骨头会被烘进动画)。in_book = true：m 在书脊(Chest)的坐标系里；false：模型空间
func _gb_set(p, bone: String, m: Transform3D, in_book: bool) -> void:
	var i: int = rig.ids[bone]
	p.fk()
	var ref := Transform3D.IDENTITY
	if in_book:
		var ci: int = rig.ids["Chest"]
		ref = p.gx[ci] * Transform3D(Basis.IDENTITY, -rig.pos[ci])
	var want: Transform3D = ref * m * Transform3D(Basis.IDENTITY, rig.pos[i])
	var loc: Transform3D = p.gx[rig.parent[i]].affine_inverse() * want
	p.rot[i] = loc.basis.get_rotation_quaternion()
	p.scl[i] = loc.basis.get_scale()
	p.off[i] = loc.origin - p.rest_local[i]
	p.dirty = true


## 只能转的骨头：让它的世界朝向 = q(相对静止姿势)，关节位置由父骨骼决定
func _gb_aim(p, bone: String, q: Quaternion) -> void:
	var i: int = rig.ids[bone]
	p.fk()
	p.rq(bone, p.gx[rig.parent[i]].basis.get_rotation_quaternion().inverse() * q)


## 整本书：bob = 上下飘、fwd = 往前冲(体素)；pitch = 书页往前翻(+)/往后仰(-)，yaw = 向左转(+)，roll = 往右歪(+)(度)，都绕书本中心转
func _greed_body(p, bob: float, pitch: float, yaw: float, roll: float, fwd: float = 0.0) -> void:
	var q: Quaternion = Lib.E(pitch, yaw, roll)
	var a: Vector3 = GREED_ORG - rig.pos[rig.ids["Hips"]]
	p.rq("Hips", q)
	p.move("Hips", a - q * a + Vector3(0.0, bob, fwd))


## 两半往里合的角度(度)：0 = 模型里摊开的样子，负 = 再往外摊，86 ≈ 合上立起来(书口那头还留一条缝)
func _greed_halves(p, close_l: float, close_r: float) -> void:
	p.rq("Shoulder_L", Quaternion(GREED_HINGE, deg_to_rad(close_l)))
	p.rq("Shoulder_R", Quaternion(GREED_HINGE, deg_to_rad(-close_r)))


## 两半合上 c 度时，书页上那几簇小火苗(离书脊约 14 格)跟着抬高多少(体素，沿书页法线)
func _greed_lift(c: float) -> float:
	var r: float = deg_to_rad(c)
	return 10.5 * sin(r) + 4.7 * (cos(r) - 1.0)


## 火：bone = Eyelid_L(书缝主火) / Eyelid_R(书页小火苗)；k = 大小(1 = 模型原样，0 = 缩回书缝)，stretch = 往上拉长(+)/压扁(-)，
## lean_x = 火苗往前(+)/往后(-)歪，lean_z = 往右(+)/往左(-)歪(度，相对书本)；lift = 沿书页法线抬高(体素)
func _greed_flame(p, bone: String, k: float, stretch: float, lean_x: float, lean_z: float, lift: float = 0.0) -> void:
	var kk: float = maxf(k, 0.02)
	var sc := Vector3(kk * (1.0 - 0.4 * stretch), kk * (1.0 + stretch), kk * (1.0 - 0.4 * stretch))
	var b: Basis = Basis(Lib.E(lean_x, 0.0, lean_z)) * Basis.from_scale(sc)
	_gb_set(p, bone, Transform3D(b, GREED_FLAME - b * GREED_FLAME + GREED_N * lift), true)


## 链子(都相对"竖直朝下"，不跟着书倾斜)：sx = 下端往后甩(+)/往前甩(-)，sz = 往 +X 甩(+)(度)；
## amp = 各自错开相位的来回摆幅(度)，period = 摆一个来回的时长(秒；循环动作里要整除动作时长)
func _greed_chains(p, t: float, period: float, amp: float, sx: float, sz: float) -> void:
	var w: float = TAU / period
	# 书脊两侧：Thigh = 第一个关节，Shin = 第二个(晚一点、摆得更大)
	for e: Array in [["_L", 0.0], ["_R", 2.4]]:
		var ph: float = float(e[1])
		_gb_aim(p, "Thigh" + str(e[0]), Lib.E(sx + amp * sin(w * t + ph), 0.0, sz + 0.6 * amp * cos(w * t + ph * 1.3)))
		_gb_aim(p, "Shin" + str(e[0]), Lib.E(1.4 * sx + 1.5 * amp * sin(w * t + ph - 0.9), 0.0, 1.4 * sz + 0.9 * amp * cos(w * t + ph * 1.3 - 0.9)))
	# 书脊前端(Halo)：挂点跟着书走，链子绕挂点摆
	p.fk()
	var ci: int = rig.ids["Chest"]
	var top: Vector3 = (p.gx[ci] * Transform3D(Basis.IDENTITY, -rig.pos[ci])) * GREED_FRONT
	var q := Basis(Lib.E(sx + 1.2 * amp * sin(w * t + 4.0), 0.0, sz + 0.7 * amp * cos(w * t + 4.6)))
	_gb_set(p, "Halo", Transform3D(q, top - q * GREED_FRONT), false)


## 待机：上下飘，书"呼吸"(两半一开一合几度)，火苗跳动，链子错开相位地晃
func idle_greed(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	_greed_body(p, 1.8 * sin(th), 2.0 * sin(th + 0.8), 2.5 * sin(th + 2.0), 1.5 * sin(th + 1.0))
	var br: float = 3.0 + 3.5 * sin(th + 0.6)
	_greed_halves(p, br, br)
	_greed_flame(p, "Eyelid_L", 1.0 + 0.04 * sin(th * 3.0) + 0.03 * sin(th * 5.0 + 1.0), 0.06 * sin(th * 4.0 + 0.5),
		3.0 * sin(th * 2.0), 3.0 * sin(th * 3.0 + 1.2))
	_greed_flame(p, "Eyelid_R", 1.0 + 0.07 * sin(th * 4.0 + 2.0), 0.1 * sin(th * 5.0 + 0.3), 2.0 * sin(th * 3.0 + 0.4),
		2.0 * sin(th * 2.0 + 2.2), _greed_lift(br))
	_greed_chains(p, t, 2.4, 5.0, 1.5 * cos(th + 0.8), 0.0)


## 移动：往前倾着飘，书页微微扇动，火苗和链子往后拖
func run_greed(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 0.8
	var pitch: float = 12.0 + 2.0 * sin(th * 2.0 + 0.5)
	_greed_body(p, 1.4 * sin(th * 2.0), pitch, 4.0 * sin(th), 3.0 * sin(th + 0.4))
	var fl: float = 4.0 + 3.0 * sin(th * 2.0 + 1.0)
	_greed_halves(p, fl, fl)
	_greed_flame(p, "Eyelid_L", 1.0 + 0.05 * sin(th * 2.0), -0.05 + 0.06 * sin(th * 3.0), -pitch - 12.0 + 3.0 * sin(th * 2.0), 3.0 * sin(th))
	_greed_flame(p, "Eyelid_R", 0.95 + 0.06 * sin(th * 3.0 + 1.0), 0.08 * sin(th * 2.0), -pitch - 14.0, 2.0 * sin(th + 1.0), _greed_lift(fl))
	_greed_chains(p, t, 0.8, 6.0, 22.0, -3.0 * sin(th))


## 普攻(0.9 秒)：往后一缩、书合拢一半、火被吸进去(0 ~ 0.28 秒)，0.36 秒猛地摊开往前一送、火喷出来(出手)，再慢慢回到待机
func attack_greed(t: float, p) -> void:
	p.reset()
	var close: float = kf_f([[0.0, 0.0], [0.28, 26.0, "o"], [0.36, -14.0, "i"], [0.52, -10.0], [0.9, 0.0]], t)
	var pitch: float = kf_f([[0.0, 0.0], [0.28, -12.0, "o"], [0.36, 16.0, "i"], [0.5, 12.0], [0.9, 0.0]], t)
	var fwd: float = kf_f([[0.0, 0.0], [0.28, -2.5, "o"], [0.36, 3.5, "i"], [0.5, 3.0], [0.9, 0.0]], t)
	var bob: float = kf_f([[0.0, 0.0], [0.28, 2.2, "o"], [0.36, 0.0, "i"], [0.9, 0.0]], t)
	var fk: float = kf_f([[0.0, 1.0], [0.28, 0.5, "o"], [0.36, 1.6, "i"], [0.48, 1.3], [0.9, 1.0]], t)
	var st: float = kf_f([[0.0, 0.0], [0.28, -0.15], [0.36, 0.3, "i"], [0.5, 0.12], [0.9, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.28, -10.0], [0.36, 20.0, "i"], [0.55, 6.0], [0.9, 0.0]], t)
	var swing: float = kf_f([[0.0, 0.0], [0.28, -8.0], [0.36, -3.0], [0.48, 16.0], [0.66, -7.0], [0.9, 0.0]], t)
	_greed_body(p, bob, pitch, 0.0, 0.0, fwd)
	_greed_halves(p, close, close)
	_greed_flame(p, "Eyelid_L", fk, st, lean, 0.0)
	_greed_flame(p, "Eyelid_R", 0.1 + 0.9 * fk, st, lean, 0.0, _greed_lift(close))
	_greed_chains(p, t, 0.9, 2.0, swing, 0.0)


## 待机小动作：火被吞回书缝、书"啪"地合上，合着书哗啦哗啦地抖(像在数钱)，再摊开、火重新蹿起来
func fidget_ember_greed(t: float, p) -> void:
	p.reset()
	_stow(p)
	var close: float = kf_f([[0.0, 0.0], [0.22, -6.0, "o"], [0.42, 86.0, "i"], [0.5, 81.0], [0.58, 86.0], [2.9, 86.0], [3.3, -8.0, "o"], [3.75, 0.0]], t)
	var fk: float = kf_f([[0.0, 1.0], [0.18, 1.15], [0.34, 0.0, "i"], [3.05, 0.0], [3.4, 1.25, "o"], [3.8, 1.0]], t)
	var shake: float = kf_f([[0.0, 0.0], [0.55, 0.0], [0.7, 1.0], [2.6, 1.0], [2.85, 0.0]], t)
	# 数钱：一阵一阵地抖(每 0.5 秒一下重的)，合着的书页一张一合地咬
	var beat: float = maxf(sin(TAU * 2.0 * t), 0.0)
	var roll: float = shake * (6.0 * sin(TAU * 7.0 * t) + 3.0 * beat)
	var yaw: float = shake * 5.0 * sin(TAU * 4.5 * t + 1.0)
	var hop: float = shake * 1.6 * beat + 1.2 * kf_f([[0.0, 0.0], [0.42, 0.0], [0.5, 1.0], [0.7, 0.0], [3.3, 0.0], [3.45, 1.0], [3.8, 0.0]], t)
	var chatter: float = shake * 6.0 * maxf(sin(TAU * 4.0 * t), 0.0)
	_greed_body(p, hop, -4.0 * shake, yaw, roll)
	_greed_halves(p, close - chatter, close - chatter * 0.8)
	_greed_flame(p, "Eyelid_L", fk, 0.1 * (1.0 - fk), 0.0, 0.0)
	_greed_flame(p, "Eyelid_R", fk, 0.0, 0.0, 0.0, _greed_lift(clampf(close, -10.0, 20.0)))
	_greed_chains(p, t, 0.5, 3.0 + 8.0 * shake, 0.0, -1.2 * roll)


## 胜利：书一开一合地"哈哈大笑"，上下颠，火一下下窜高，链子乱晃
func victory_ember_greed(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var laugh: float = 0.5 + 0.5 * sin(th * 4.0)
	_greed_body(p, 2.5 * absf(sin(th * 2.0)), -6.0 + 3.0 * sin(th * 4.0 + 1.0), 4.0 * sin(th), 2.0 * sin(th * 2.0))
	_greed_halves(p, 36.0 * laugh, 36.0 * laugh)
	_greed_flame(p, "Eyelid_L", 1.1 + 0.15 * (1.0 - laugh), 0.12 * (1.0 - laugh), -4.0 + 3.0 * sin(th * 2.0), 4.0 * sin(th * 3.0))
	_greed_flame(p, "Eyelid_R", 1.05 + 0.1 * (1.0 - laugh), 0.1 * sin(th * 4.0), -3.0, 3.0 * sin(th * 2.0 + 1.0), _greed_lift(36.0 * laugh))
	_greed_chains(p, t, 0.6, 8.0, 0.0, 0.0)


# =============================================================== 红之章·人形余烬的专属待机 / 跑步 / 普攻(2026-10-04)
## 愤怒(法器，男)、怠惰(手弩，男)、傲慢(法器)、龙的余烬(长柄，带翅膀和尾巴)以前借用通用的持械动作，一点性格都没有；这里给每个一套自己的。
## 普攻的时长 / 出手时刻和各自的武器大类一致(GC.WEAPON_CLASSES)：法器 27f / 0.36 s，手弩 18f / 0.20 s，长柄 24f / 0.30 s(贯穿同样)；
## 普攻的首帧、末帧 = 待机 t = 0 的姿势(从待机进来、打完回待机都接得上)。待机 / 跑步照例也烘男性款 *_m(动作一样，男性模型选用)。
## 龙的余烬的翅膀自己控制(wing_custom)；尾巴(BTail 链)是弹簧骨，这里只给每节一个"主动"转角，弹簧在它上面晃。
const RED_HUMAN_TABLE := {
	"idle_wrath": [2.4, true], "run_wrath": [22.0 * F, true], "attack_wrath": [27.0 * F, false],
	"idle_sloth": [4.0, true], "run_sloth": [24.0 * F, true], "attack_sloth": [18.0 * F, false],
	"idle_pride": [4.0, true], "run_pride": [24.0 * F, true], "attack_pride": [27.0 * F, false],
	"idle_dragon": [3.2, true], "run_dragon": [20.0 * F, true], "attack_dragon": [24.0 * F, false], "pierce_dragon": [24.0 * F, false],
}


func red_human_table(t: Dictionary) -> void:
	for nm: String in RED_HUMAN_TABLE.keys():
		var d := {"dur": float(RED_HUMAN_TABLE[nm][0]), "loop": bool(RED_HUMAN_TABLE[nm][1]), "fn": Callable(self, nm)}
		if nm.ends_with("_dragon"):
			d["wing_custom"] = true
		t[nm] = d


## 和 _hand_keys 一样在一串手势之间插值，但每一段可以指定缓动：keys = [[t, 手势, 缓动("s" "i" "o" "l"，默认 "s")], ...]
func _hand_track(p, side: String, keys: Array, t: float) -> void:
	if t <= float(keys[0][0]):
		_hand_mix(p, side, keys[0][1], keys[0][1], 0.0)
		return
	for i in range(keys.size() - 1):
		var t0: float = keys[i][0]
		var t1: float = keys[i + 1][0]
		if t <= t1:
			var mode: String = str(keys[i + 1][2]) if (keys[i + 1] as Array).size() > 2 else "s"
			_hand_mix(p, side, keys[i][1], keys[i + 1][1], _ease(mode, (t - t0) / maxf(t1 - t0, 1e-6)))
			return
	_hand_mix(p, side, keys[-1][1], keys[-1][1], 1.0)


# ---------------------------------------------------------------- 愤怒的余烬(男，法器；火长在右手上：手指朝下 = 火苗朝上烧)
## 待机(2.4 s)：魁梧的身子弓着背、塌着肩扣向前，屈膝的大开步；一下下粗重地喘(猛吸一口、胸口鼓起、两肩耸起，再慢慢呼出去，1.2 s 一次)；
##   火手垂在大腿前外侧，爪子一张一合地捏着火(像在脉动)，左拳攥得发抖
## 跑(22f)：笨重地往前冲 —— 前倾、落脚沉胯、左右倒重心、肩膀跟着步子大幅前后扭；左拳大幅前后抡，火手往外撑着、火苗往后拖
## 普攻(27f = 0.9 s，出手 0.36 s)：深吸一口，火手往右后上方抡起、上身往右后拧、重心压到后脚、左手往前探着瞄(0 ~ 0.24 s)，顶点一顿
##   → 左脚重重踏出、整个人拧回来扑出去，火手从肩后过头顶往前甩出火球(出手)，左拳同时往腰后猛收
##   → 火手顺势砸到左膝前、弓背压低(随挥) → 喘着粗气慢慢直起来，回到待机
const WRATH_IDLE := 2.4
const WRATH_RUN := 22.0 * F
## 火长在右手上、沿手的局部 +Z(静止时朝前 = 拇指那一侧)烧：手指朝前 + 掌心朝里 = 火苗朝上(法器的握法)。
## 下面的手势都按"火苗朝上"挑手指 / 掌心：火苗方向 = 手指 × 掌心 绕过来的那一轴，只在出手那一下往后拖
const G_WR_FIRE := [Vector3(15.0, 47.5, 8.0), Vector3(0.8, -0.3, -0.8), Vector3(0.15, 0.33, 0.95), Vector3(-1.0, 0.0, 0.0), 34.0]   # 火手托在大腿前外侧(手腕往上翘：抵掉弓背的前倾，火苗朝上)
const G_WR_FIST := [Vector3(17.5, 49.5, 4.5), Vector3(0.7, -0.2, -0.9), Vector3(0.1, -1.0, 0.25), Vector3(-1.0, 0.0, 0.1), 88.0]   # 攥紧的左拳
## 火手抡起来的一路：掌心始终朝里，手指在身体的前后竖直面里转(朝前 → 朝上 → 过头顶往前甩 → 朝前)，不会翻面；
## 火苗跟着转：托着时朝上，抡到肩后时往后拖(蓄力)，过头顶时往后上方拖，出手后又朝上
const G_WR_RAISE := [Vector3(15.5, 62.0, 12.0), Vector3(1.0, -0.6, -0.3), Vector3(0.15, 0.2, 1.0), Vector3(-1.0, 0.0, 0.0), 24.0]   # 往前上方提起
const G_WR_UP := [Vector3(16.5, 76.0, 4.0), Vector3(1.0, -0.6, -0.4), Vector3(0.1, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 20.0]         # 举到头侧
const G_WR_COCK := [Vector3(16.5, 79.0, -6.0), Vector3(1.0, -0.6, -0.4), Vector3(0.1, 1.0, 0.0), Vector3(-1.0, 0.0, 0.0), 22.0]     # 抡到肩后上方(火苗往后拖)
const G_WR_COCK2 := [Vector3(17.0, 80.0, -7.5), Vector3(1.0, -0.55, -0.45), Vector3(0.1, 1.0, -0.1), Vector3(-1.0, 0.0, 0.0), 24.0]
const G_WR_OVER := [Vector3(14.5, 82.0, 8.0), Vector3(1.0, -0.2, -0.1), Vector3(0.05, 0.8, 0.6), Vector3(-1.0, 0.0, 0.0), 14.0]      # 过头顶(火苗往后拖)
const G_WR_THROW := [Vector3(7.5, 71.0, 16.0), Vector3(1.0, -0.5, -0.2), Vector3(0.0, 0.25, 1.0), Vector3(-1.0, 0.0, 0.0), 6.0]     # 出手：手臂往前甩直、爪子张开
const G_WR_FOLLOW := [Vector3(4.0, 52.0, 14.0), Vector3(1.0, -0.2, -0.3), Vector3(-0.1, 0.3, 0.95), Vector3(-1.0, 0.0, 0.0), 20.0]  # 随挥：砸到左膝前(上身压得很低，手腕翘着让火苗还往上烧)
const G_WR_REACH := [Vector3(10.0, 63.0, 16.0), Vector3(1.0, -0.5, -0.3), Vector3(0.05, 0.1, 1.0), Vector3(0.0, -1.0, 0.1), 18.0]   # 左手往前探着瞄
const G_WR_YANK := [Vector3(14.0, 53.0, -4.5), Vector3(0.8, 0.0, -0.8), Vector3(0.05, -0.3, 1.0), Vector3(-0.2, -1.0, -0.3), 92.0]   # 左拳猛收到腰后


## 喘息(0 = 呼尽，1 = 吸满)：猛地吸一口(周期的 38%)，再慢慢呼出去
static func _wr_breath(t: float, period: float) -> float:
	return kf_f([[0.0, 0.0], [period * 0.38, 1.0, "o"], [period, 0.0]], fposmod(t, period))


## 身体：heave = 喘息，yaw = 上身扭转(+ = 右肩往前)，lean = 再多前倾(度)，bob = 再多沉胯(+ = 往上)，sway = 重心往左(+)
func _wr_body(p, heave: float, yaw: float, lean: float, bob: float, sway: float) -> void:
	_base(p, sway, -2.8 + 0.7 * heave + bob, yaw, 19.0 - 4.0 * heave + lean, 0.0, 0.0, 9.5, 1.5)
	p.scale_("Chest", Vector3(1.0 + 0.035 * heave, 1.0 + 0.02 * heave, 1.0 + 0.045 * heave))
	# 塌着肩往前扣，吸气时两肩耸起来
	p.r("Shoulder_L", 0.0, -11.0, 6.0 + 7.0 * heave)
	p.r("Shoulder_R", 0.0, 11.0, -6.0 - 7.0 * heave)


## 火手的朝向直接摆成"火苗(手的局部 +Z)朝世界方向 flame"，手指顺着小臂(跑步时手臂前后摆，火苗也一直朝上、往后拖)
func _wr_fire_up(p, flame: Vector3) -> void:
	p.fk()
	var fa: Vector3 = (p.gpos_n("Hand_R") - p.gpos_n("LowerArm_R")).normalized()
	var z: Vector3 = flame.normalized()
	var fingers: Vector3 = fa - z * fa.dot(z)
	fingers = fingers.normalized() if fingers.length() > 0.05 else Vector3(0.0, 0.0, 1.0)
	var y: Vector3 = -fingers
	p.set_grot("Hand_R", Quaternion(Basis(y.cross(z), y, z).orthonormalized()))


## 待机的两只手(t = 待机时刻)：[火手, 左拳]
func _wr_idle_hands(t: float, heave: float) -> Array:
	var th: float = TAU * t / WRATH_IDLE
	var fire: Array = G_WR_FIRE.duplicate()
	fire[0] = (G_WR_FIRE[0] as Vector3) + Vector3(0.0, 0.8 * heave, 0.3 * sin(2.0 * th))
	fire[4] = 26.0 + 16.0 * (0.5 + 0.5 * sin(4.0 * th))
	var fist: Array = G_WR_FIST.duplicate()
	fist[0] = (G_WR_FIST[0] as Vector3) + Vector3(0.3 * sin(14.0 * th), 0.6 * heave + 0.25 * sin(17.0 * th + 1.0), 0.0)
	return [fire, fist]


func idle_wrath(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / WRATH_IDLE
	var hv: float = _wr_breath(t, WRATH_IDLE * 0.5)
	_wr_body(p, hv, 0.0, 0.0, 0.0, 0.5 * sin(th))
	_head(p, -17.0 - 4.0 * hv, 3.0 * sin(th), 1.5 * sin(3.0 * th))
	var g: Array = _wr_idle_hands(t, hv)
	_hand_mix(p, "R", g[0], g[0], 0.0)
	_hand_mix(p, "L", g[1], g[1], 0.0)
	set_lids(p, 0.0)


func run_wrath(t: float, p) -> void:
	p.reset()
	var ph: float = fposmod(t / WRATH_RUN, 1.0)
	var th: float = TAU * ph
	var fl: Array = foot_track(ph, 16.0, 10.0, 0.42)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 16.0, 10.0, 0.42)
	var s: float = cos(th)
	# 落脚那一下胯最低(半个周期一次)，左右倒重心；上身前倾、肩膀跟着步子大幅前后扭
	p.move("Hips", Vector3(2.2 * sin(th), -8.5 + 3.0 * pow(absf(sin(th)), 0.8), 1.5))
	p.r("Hips", 13.0 + 2.0 * sin(2.0 * th), -11.0 * s, 5.0 * sin(th))
	p.r("Spine", 6.0, 8.0 * s, -3.0 * sin(th))
	p.r("Chest", 5.0 + 2.0 * sin(2.0 * th + 0.5), 11.0 * s, -3.0 * sin(th))
	p.r("Shoulder_L", 0.0, -8.0 + 6.0 * s, 6.0)
	p.r("Shoulder_R", 0.0, 8.0 + 6.0 * s, -6.0)
	_head(p, -20.0 - 2.0 * sin(2.0 * th), -6.0 * s, 2.0 * sin(th))
	legs(p, foot_target(1.0, fl, 7.5), foot_target(-1.0, fr, 7.5), Lib.E(fl[2], 9.0, 0), Lib.E(fr[2], -9.0, 0),
		-0.6 * maxf(float(fl[2]), 0.0), -0.6 * maxf(float(fr[2]), 0.0))
	# 左拳大幅前后抡；火手往外撑、摆得小(小臂往前弯着、手腕往上翘：火苗朝上、往后拖)
	p.r("UpperArm_L", 40.0 * s - 6.0, 0.0, 16.0)
	p.r("LowerArm_L", -(60.0 + 20.0 * (0.5 - 0.5 * s)), 0.0, 0.0)
	p.r("Hand_L", -6.0, 0.0, 0.0)
	p.r("Fingers_L", -88.0, 0.0, 0.0)
	p.r("Thumb_L", -35.0, 0.0, 0.0)
	p.r("UpperArm_R", -26.0 * s - 10.0, 0.0, -20.0)
	p.r("LowerArm_R", -(48.0 + 14.0 * (0.5 + 0.5 * s)), 0.0, 0.0)
	_wr_fire_up(p, Vector3(0.0, 0.85, -0.5))
	p.r("Fingers_R", -34.0, 0.0, 22.0)
	p.r("Thumb_R", -14.0, 0.0, 0.0)
	set_lids(p, 0.0)


func attack_wrath(t: float, p) -> void:
	p.reset()
	var dur := 27.0 * F
	var hv: float = kf_f([[0.0, 0.0], [0.24, 1.0, "o"], [0.36, 0.0, "i"], [0.6, 0.6], [dur, 0.0]], t)
	var yaw: float = kf_f([[0.0, 0.0], [0.24, -36.0, "o"], [0.30, -40.0], [0.36, 24.0, "i"], [0.48, 30.0, "o"], [dur, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.24, -12.0, "o"], [0.30, -13.0], [0.36, 12.0, "i"], [0.50, 17.0, "o"], [dur, 0.0]], t)
	var bob: float = kf_f([[0.0, 0.0], [0.24, 1.2, "o"], [0.30, 1.4], [0.37, -3.2, "i"], [0.50, -3.6], [dur, 0.0]], t)
	var sway: float = kf_f([[0.0, 0.0], [0.24, -2.0], [0.30, -2.2], [0.36, 2.0, "i"], [0.60, 1.0], [dur, 0.0]], t)
	_wr_body(p, hv, yaw, lean, bob, sway)
	# 左脚(前脚)在出手时往前重重踏一步，打完收回来
	var lz: float = kf_f([[0.0, 1.5], [0.26, 0.5], [0.35, 7.0, "o"], [0.62, 7.0], [0.82, 1.5]], t)
	_feet(p, 9.5, lz, _arc(t, 0.26, 0.35, 3.5) + _arc(t, 0.62, 0.82, 1.5), -1.5, 0.0, 6.0, -6.0)
	_head(p, kf_f([[0.0, -17.0], [0.24, -22.0, "o"], [0.36, -14.0, "i"], [0.50, -8.0], [dur, -17.0]], t), -0.8 * yaw, 0.0)
	var g0: Array = _wr_idle_hands(0.0, 0.0)
	_hand_track(p, "R", [[0.0, g0[0]], [0.10, G_WR_RAISE, "i"], [0.17, G_WR_UP, "l"], [0.24, G_WR_COCK, "o"], [0.30, G_WR_COCK2],
		[0.33, G_WR_OVER, "i"], [0.36, G_WR_THROW, "l"], [0.48, G_WR_FOLLOW, "o"], [0.60, G_WR_FOLLOW], [dur, g0[0]]], t)
	_hand_track(p, "L", [[0.0, g0[1]], [0.22, G_WR_REACH], [0.29, G_WR_REACH], [0.40, G_WR_YANK], [0.55, G_WR_YANK], [dur, g0[1]]], t)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 怠惰的余烬(男，手弩；右小臂整条是一门炮 = 炮管跟着小臂走)
## 待机(4 s)：笨重的炉膛机器人大开步站着，慢慢左右晃，炉子低低地"突突"震；脑袋一点点往下耷拉、两肩跟着塌(打瞌睡)，
##   快睡着时脑袋往下一掉 → 猛地一抬惊醒(往上一挺)，再慢慢稳住；炮臂沉甸甸地垂着，跟着身子晃(钟摆似的慢半拍)
## 跑(24f)：沉重的跺步 —— 抬脚低、落脚重(落地的一下胯往下一顿)，左右大幅倒重心、上身跟着摇；炮臂垂着前后荡，左爪前后摆
## 普攻(18f = 0.6 s，出手 0.20 s)：上身往后一仰、把炮臂吃力地拽起来(0 ~ 0.15 s)，屈膝沉胯稳住、炮口平指目标
##   → 开炮(0.20 s)：后坐力把炮口顶得往上一跳、肩膀被顶回去、胯往后一滑、脑袋往后一甩 → 炮臂重重地掉回去垂着
const SLOTH_IDLE := 4.0
const SLOTH_RUN := 24.0 * F
const SLOTH_CANNON := Vector3(-3.0, -26.0, 0.0)          # 炮管方向(静止时，模型空间)：肘 → 炮口，比小臂骨更竖一点


## 炮臂：大臂往前抬 raise / 往外张 out(度)，小臂(= 炮管)指向世界方向 aim，炮管"上面"(静止时朝前的那一面)朝 top
func _sl_cannon(p, raise: float, out: float, aim: Vector3, top: Vector3) -> void:
	p.r("UpperArm_R", -raise, 0.0, -out)
	p.fk()
	var c0: Vector3 = SLOTH_CANNON.normalized()
	var z0: Vector3 = (Vector3(0.0, 0.0, 1.0) - c0 * c0.z).normalized()
	var d: Vector3 = aim.normalized()
	var u: Vector3 = (top - d * top.dot(d)).normalized()
	var b0 := Basis(c0, z0, c0.cross(z0))
	var b1 := Basis(d, u, d.cross(u))
	p.set_grot("LowerArm_R", Quaternion((b1 * b0.transposed()).orthonormalized()))


## 炮臂的姿态：pitch = 炮口仰角(度，-90 = 垂直朝下)，swing_x / swing_z = 垂着时往外(-)/往前(+)荡
func _sl_cannon_pitch(p, raise: float, out: float, pitch: float, swing_x: float, swing_z: float) -> void:
	var r: float = deg_to_rad(pitch)
	var hang: float = clampf(-pitch / 90.0, 0.0, 1.0)
	var aim := Vector3((-0.12 + swing_x) * hang, sin(r), cos(r) + swing_z * hang)
	_sl_cannon(p, raise, out, aim, Vector3(0.0, cos(r), -sin(r)))


## 身体：droop = 打瞌睡(0..1；< 0 = 惊醒时往上一挺)，sway = 重心往左(+)，yaw = 上身扭转(+ = 右肩往前)，lean = 前倾，
## bob = 沉胯(+ = 往上)，push = 胯往前(体素)，rz = 右脚(后脚)的前后位置
func _sl_body(p, droop: float, sway: float, yaw: float, lean: float, bob: float, push: float, rz: float = -1.0) -> void:
	var nod: float = maxf(droop, 0.0)
	var jolt: float = maxf(-droop, 0.0)
	p.move("Hips", Vector3(sway, -2.2 - 1.6 * nod + 1.4 * jolt + bob, push))
	p.r("Hips", lean * 0.4, yaw * 0.35, sway * 1.2)
	p.r("Spine", lean * 0.3 + 4.0 * nod - 3.0 * jolt, yaw * 0.3, -sway * 0.6)
	p.r("Chest", lean * 0.3 + 7.0 * nod - 4.0 * jolt, yaw * 0.35, -sway * 0.5)
	p.r("Shoulder_L", 0.0, 0.0, -7.0 * nod + 5.0 * jolt)
	p.r("Shoulder_R", 0.0, 0.0, 7.0 * nod - 5.0 * jolt)
	legs(p, Vector3(9.0, ANKLE_Y, 0.5), Vector3(-9.0, ANKLE_Y, -0.5 + rz), Lib.E(0, 10.0, 0), Lib.E(0, -10.0, 0))


## 打瞌睡的曲线(待机时刻 t)：慢慢耷拉 → 脑袋一掉 → 惊醒往上一挺 → 稳住
static func _sl_droop(t: float) -> float:
	return kf_f([[0.0, 0.0], [0.3, 0.0], [2.6, 1.0, "i"], [2.72, -0.5, "o"], [3.0, -0.25], [3.4, 0.06], [3.8, 0.0]], t)


func idle_sloth(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / SLOTH_IDLE
	var dr: float = _sl_droop(t)
	var jolt: float = maxf(-dr, 0.0)
	_sl_body(p, dr, 1.2 * sin(th), 0.0, 0.0, 0.3 * sin(30.0 * th), 0.0)
	_head(p, 26.0 * maxf(dr, 0.0) - 14.0 * jolt, 4.0 * sin(th), 10.0 * maxf(dr, 0.0) + 2.0 * sin(th))
	_sl_cannon_pitch(p, 2.0 + 6.0 * jolt, 5.0, -90.0, -0.08 * sin(th - 0.9), 0.06 * sin(th) + 0.35 * jolt)
	_hand(p, "L", RELAX_L + Vector3(2.0, -1.0 - 1.0 * maxf(dr, 0.0), 1.0), Vector3(0.6, -0.2, -1.0), Vector3(0.1, -1.0, 0.15), Vector3(-1.0, 0.0, 0.2), 30.0 - 26.0 * jolt)
	set_lids(p, 0.0)


func run_sloth(t: float, p) -> void:
	p.reset()
	var ph: float = fposmod(t / SLOTH_RUN, 1.0)
	var th: float = TAU * ph
	var fl: Array = foot_track(ph, 15.0, 6.5, 0.5)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 15.0, 6.5, 0.5)
	var s: float = cos(th)
	var up: float = pow(absf(sin(th)), 0.6)          # 落脚瞬间最低、尖的(沉重地一顿)
	p.move("Hips", Vector3(3.2 * sin(th), -6.0 + 2.6 * up, 0.5))
	p.r("Hips", 4.0, -6.0 * s, 5.0 * sin(th))
	p.r("Spine", 2.0, 3.0 * s, -3.0 * sin(th))
	p.r("Chest", 3.0 + 3.0 * (1.0 - up), 4.0 * s, -3.5 * sin(th))
	_head(p, -3.0 + 3.0 * (1.0 - up), -3.0 * s, -2.5 * sin(th))
	legs(p, foot_target(1.0, fl, 8.5), foot_target(-1.0, fr, 8.5), Lib.E(fl[2] * 0.6, 8.0, 0), Lib.E(fr[2] * 0.6, -8.0, 0))
	# 炮臂垂着前后荡(慢半拍)，左爪前后摆
	_sl_cannon_pitch(p, 4.0 * cos(th - 0.5), 6.0, -90.0, 0.04 * sin(th), 0.3 * cos(th - 0.5) - 0.05)
	p.r("UpperArm_L", 24.0 * s - 2.0, 0.0, 12.0)
	p.r("LowerArm_L", -30.0 - 10.0 * (0.5 - 0.5 * s), 0.0, 0.0)
	p.r("Fingers_L", -30.0, 0.0, -10.0)
	p.r("Thumb_L", -20.0, 0.0, 0.0)
	set_lids(p, 0.0)


func attack_sloth(t: float, p) -> void:
	p.reset()
	var dur := 18.0 * F
	var raise: float = kf_f([[0.0, 2.0], [0.15, 40.0], [0.20, 34.0], [0.235, 52.0, "o"], [0.36, 38.0], [0.50, 2.0, "i"], [dur, 2.0]], t)
	var pitch: float = kf_f([[0.0, -90.0], [0.14, 8.0], [0.20, 0.0], [0.235, 36.0, "o"], [0.36, 6.0], [0.50, -90.0, "i"], [dur, -90.0]], t)
	var yaw: float = kf_f([[0.0, 0.0], [0.15, 16.0, "o"], [0.20, 16.0], [0.235, 6.0, "o"], [0.40, 12.0], [dur, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.12, -7.0, "o"], [0.20, 4.0], [0.235, -9.0, "o"], [0.38, -2.0], [dur, 0.0]], t)
	var bob: float = kf_f([[0.0, 0.0], [0.15, -1.0], [0.20, -2.2], [0.25, -1.2], [0.42, -1.6], [0.52, -2.4, "i"], [dur, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.20, 0.5], [0.235, -2.2, "o"], [0.40, -0.8], [dur, 0.0]], t)
	var rz: float = kf_f([[0.0, -1.0], [0.15, -3.5], [0.45, -3.5], [dur, -1.0]], t)
	_sl_body(p, 0.0, kf_f([[0.0, 0.0], [0.15, -1.2], [0.25, -1.0], [dur, 0.0]], t), yaw, lean, bob, push, rz)
	_head(p, kf_f([[0.0, 0.0], [0.15, -4.0], [0.20, -2.0], [0.235, -12.0, "o"], [0.40, -4.0], [dur, 0.0]], t), -0.7 * yaw, 0.0)
	_sl_cannon_pitch(p, raise, kf_f([[0.0, 5.0], [0.15, 10.0], [0.45, 10.0], [dur, 5.0]], t), pitch, 0.0, 0.0)
	# 左爪：往左后张开配重，开炮时被震得往后一甩
	var g0 := [RELAX_L + Vector3(2.0, -1.0, 1.0), Vector3(0.6, -0.2, -1.0), Vector3(0.1, -1.0, 0.15), Vector3(-1.0, 0.0, 0.2), 30.0]
	var g_bal := [Vector3(20.0, 55.0, -2.0), Vector3(0.1, 0.3, -1.0), Vector3(0.5, -0.85, -0.1), Vector3(-0.85, -0.5, 0.2), 14.0]
	var g_kick := [Vector3(19.0, 58.5, -7.5), Vector3(0.3, 0.6, -0.5), Vector3(0.5, -0.75, -0.4), Vector3(-0.85, -0.5, 0.1), 8.0]
	_hand_track(p, "L", [[0.0, g0], [0.15, g_bal], [0.20, g_bal], [0.25, g_kick, "o"], [0.40, g_bal], [dur, g0]], t)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 傲慢的余烬(精英，法器；用爪子施法，长裙拖地)
## 待机(4 s)：挺直腰板、下巴高高抬着(从面具底下睨人)，左手叉在腰上，右爪抬在肩前、掌心朝上，爪尖一根根慢慢蜷起再张开、
##   手腕慢慢转；一口慢而深的呼吸(胸口起伏)，重心在两脚之间轻轻挪
## 跑(24f)：不跑 —— 裙底下小碎步滑过去：几乎不起伏，上身端着往前倾一点，左手仍叉腰，右爪低低地往前外侧伸着引路
## 普攻(27f = 0.9 s，出手 0.36 s)：右爪往上收到左肩前、手背对着敌人(蓄力)，上身往左拧、下巴抬得更高
##   → 一爪从左往右横扫出去、停成一个往前指的"敕令"(出手)，手往前一送 → 指着停一会儿 → 收回到肩前
const PRIDE_IDLE := 4.0
const PRIDE_RUN := 24.0 * F
const G_PR_CLAW := [Vector3(15.5, 67.0, 9.5), Vector3(1.0, -0.6, -0.4), Vector3(0.25, 0.6, 0.75), Vector3(-0.3, 0.9, 0.0), 38.0]   # 右爪抬在肩前、掌心朝上
const G_PR_GATHER := [Vector3(15.5, 80.0, 12.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.1, 1.0, 0.1), Vector3(0.0, -0.1, 1.0), 50.0]   # 举到右脸侧前方、掌心朝前、爪子收拢(蓄力；别往后上方举：高领两侧的羽毛挂在胸口上)
const G_PR_GATHER2 := [Vector3(15.5, 81.0, 11.0), Vector3(1.0, -0.6, -0.35), Vector3(-0.1, 1.0, 0.0), Vector3(0.0, 0.0, 1.0), 62.0]
const G_PR_SWEEP := [Vector3(14.0, 75.0, 16.0), Vector3(1.0, -0.4, -0.2), Vector3(0.1, 0.7, 0.7), Vector3(0.0, -0.7, 0.7), 20.0]   # 往前下方扫
const G_PR_CAST := [Vector3(12.5, 66.0, 18.0), Vector3(1.0, -0.6, -0.2), Vector3(0.18, 0.05, 1.0), Vector3(0.0, -1.0, 0.05), 4.0]    # 往前一指(敕令)
const G_PR_CAST2 := [Vector3(13.0, 66.5, 19.5), Vector3(1.0, -0.6, -0.2), Vector3(0.18, 0.1, 1.0), Vector3(0.0, -1.0, 0.1), 2.0]
const G_PR_LEAD := [Vector3(17.5, 55.0, 7.5), Vector3(0.8, -0.4, -0.6), Vector3(0.5, -0.5, 0.7), Vector3(0.0, -1.0, 0.0), 20.0]    # 跑：右爪低低地往前外侧伸


## 身体：br = 呼吸(0..1)，sway = 重心往左(+)，yaw = 上身扭转(+ = 右肩往前)，lean = 前倾(度)，bob = 沉胯(+ = 往上)
func _pr_body(p, br: float, sway: float, yaw: float, lean: float, bob: float) -> void:
	_base(p, 0.6 + sway, 0.3 * br + bob, -6.0 + yaw, -4.0 + lean - 1.5 * br, 2.0, 0.0, 4.2, 2.0)
	p.scale_("Chest", Vector3(1.0 + 0.02 * br, 1.0 + 0.012 * br, 1.0 + 0.028 * br))
	p.r("Shoulder_L", 0.0, 5.0, -2.0 + 2.0 * br)
	p.r("Shoulder_R", 0.0, -5.0, 2.0 - 2.0 * br)


## 待机的右爪(t = 待机时刻)
func _pr_claw(t: float) -> Array:
	var th: float = TAU * t / PRIDE_IDLE
	var br: float = 0.5 - 0.5 * cos(th)
	var claw: Array = G_PR_CLAW.duplicate()
	claw[0] = (G_PR_CLAW[0] as Vector3) + Vector3(0.0, 0.6 * br, 0.4 * sin(th))
	claw[2] = (G_PR_CLAW[2] as Vector3) + Vector3(0.15 * sin(2.0 * th), 0.0, 0.0)
	claw[4] = 38.0 + 14.0 * (0.5 - 0.5 * cos(2.0 * th))
	return claw


func idle_pride(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / PRIDE_IDLE
	var br: float = 0.5 - 0.5 * cos(th)
	_pr_body(p, br, 0.5 * sin(th), 0.0, 0.0, 0.0)
	_head(p, -13.0 - 1.5 * br, 8.0 + 3.0 * sin(th + 0.6), -4.0)
	_on_hip(p, "L")
	var claw: Array = _pr_claw(t)
	_hand_mix(p, "R", claw, claw, 0.0)
	set_lids(p, 0.0)


func run_pride(t: float, p) -> void:
	p.reset()
	var ph: float = fposmod(t / PRIDE_RUN, 1.0)
	var th: float = TAU * ph
	var fl: Array = foot_track(ph, 6.0, 2.5, 0.5)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 6.0, 2.5, 0.5)
	# 拖地长裙硬挂在 Hips 上：胯几乎不倾斜(不然裙摆会陷进地里 / 离地)，前倾放在腰和胸
	p.move("Hips", Vector3(0.5 * sin(th), -1.8 + 0.3 * cos(2.0 * th), 1.0))
	p.r("Hips", 1.0, -2.0 * cos(th), 0.5 * sin(th))
	p.r("Spine", 3.5, 1.5 * cos(th), -0.8 * sin(th))
	p.r("Chest", 3.5, 2.0 * cos(th), -0.6 * sin(th))
	_head(p, -12.0, -1.5 * cos(th), -2.0)
	legs(p, foot_target(1.0, fl, 4.0), foot_target(-1.0, fr, 4.0), Lib.E(float(fl[2]) * 0.4, 4.0, 0), Lib.E(float(fr[2]) * 0.4, -4.0, 0))
	_on_hip(p, "L")
	var lead: Array = G_PR_LEAD.duplicate()
	lead[0] = (G_PR_LEAD[0] as Vector3) + Vector3(0.0, 0.4 * sin(2.0 * th), 0.6 * cos(th))
	_hand_mix(p, "R", lead, lead, 0.0)
	set_lids(p, 0.0)


func attack_pride(t: float, p) -> void:
	p.reset()
	var dur := 27.0 * F
	var yaw: float = kf_f([[0.0, 0.0], [0.24, 16.0, "o"], [0.30, 18.0], [0.36, -6.0, "i"], [0.46, 2.0, "o"], [dur, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.24, -4.0, "o"], [0.30, -4.5], [0.36, 6.0, "i"], [0.62, 4.0], [dur, 0.0]], t)
	_pr_body(p, kf_f([[0.0, 0.0], [0.24, 1.0, "o"], [0.36, 0.2, "i"], [dur, 0.0]], t), 0.0, yaw, lean,
		kf_f([[0.0, 0.0], [0.24, 0.8, "o"], [0.36, -0.6, "i"], [0.6, -0.3], [dur, 0.0]], t))
	_head(p, kf_f([[0.0, -13.0], [0.24, -20.0, "o"], [0.36, -9.0, "i"], [0.62, -12.0], [dur, -13.0]], t),
		8.0 + 3.0 * sin(0.6) - 0.7 * yaw, -4.0)
	_on_hip(p, "L")
	_hand_track(p, "R", [[0.0, _pr_claw(0.0)], [0.24, G_PR_GATHER], [0.30, G_PR_GATHER2], [0.33, G_PR_SWEEP, "i"], [0.36, G_PR_CAST, "o"],
		[0.42, G_PR_CAST2, "o"], [0.62, G_PR_CAST], [dur, _pr_claw(0.0)]], t)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 龙的余烬(首领，长柄 = 熔岩薙刀；背上一对蝙蝠翼、身后一条龙尾)
## 待机(3.2 s)：左肩朝前的宽而低的架势(屈膝沉胯)，双手把薙刀斜举在身前、刀尖朝前上；翅膀半张，跟着呼吸慢慢一开一合(吸气时张开、翼尖抬起)，
##   尾巴慢慢左右甩；一呼一吸 1.6 s
## 跑(20f)：大幅前倾往前冲，两翼往后收紧、翼尖翘起(跟着步子颤)，薙刀压低在右侧、刀尖朝前下，尾巴往后拖着甩
## 普攻(24f = 0.8 s，出手 0.30 s)：大斜斩 —— 薙刀抡到右肩后上方、上身往右后拧、后仰，两翼猛地往前上方张开(0 ~ 0.18 s)，顶点一顿
##   → 左脚大步踏出、沉胯、拧腰前压，刀从右上方斜劈到左前下(出手)，两翼同时往下一扇 → 刀顺势带到左下、压低(随挥) → 收回架势
## 贯穿(24f，出手 0.30 s；[群攻2] 的群攻招式)：薙刀收到腰间、身子侧得更厉害、往后坐，两翼往后收紧(蓄力)
##   → 左脚一个大弓步扑出去、薙刀往前直刺(出手)，两翼往外一张、往下扇 → 刺到底停住 → 抽刀退回架势
const DRAGON_IDLE := 3.2
const DRAGON_RUN := 20.0 * F
const DR_YAW := -20.0                              # 左肩略朝前(扭得少：翅膀挂在胸口上，上身扭多了俯视镜头里一只翅膀会转成侧面)
const DR_LEAD := 3.5                               # 左脚在前
const DR_LEAN := 6.0
const DR_DROP := 3.5                               # 沉胯(屈膝)
const DR_GRIP := Vector3(-5.0, 50.5, 9.5)          # 右手握点(胸腔局部)
const DR_AXIS := Vector3(0.49, 0.62, 0.61)         # 刀身方向(胸腔局部)：侧身后在世界里指前上(斜举)
const DR_SPAN := 10.0
const DR_FOLD := 18.0                              # 翅膀半张：在模型张开的样子上往后收的角度
const DR_FLAP := 5.0


## 身体：yaw = 上身扭转(+ = 右肩往前)，lean = 前倾，drop = 沉胯(+ = 往下)，push = 胯往前送，sway = 重心往左(+)；
## 两只脚：lz / rz = 前后(+ 往前)，ll / rl = 抬脚高度(体素)
func _dr_body(p, yaw: float, lean: float, drop: float, push: float, sway: float, lz: float, ll: float, rz: float, rl: float) -> void:
	p.move("Hips", Vector3(sway, -1.7 - drop, push))
	p.r("Hips", lean * 0.4, yaw * 0.35, sway * 0.6)
	p.r("Spine", lean * 0.3, yaw * 0.3, -sway * 0.3)
	p.r("Chest", lean * 0.3, yaw * 0.35, -sway * 0.3)
	_feet(p, 9.0, lz, ll, rz, rl, -2.0, -26.0)


## 翅膀：fold = 往后收(度，0 = 模型里张开的样子，负 = 往前张得更开)，flap = 翼尖往上抬(度)。
## 翅膀挂在胸口上：先把上身(胯 + 腰 + 胸)累计的扭转抵消掉(comp = 抵消的比例)，两只翅膀始终对着棋子的朝向左右张开，
## 俯视的战斗镜头里两只都看得见(前倾 / 侧弯照样跟着上身)。要在身体摆好之后再调用
func _dr_wings(p, fold: float, flap: float, comp: float = 0.9) -> void:
	p.fk()
	var cq := Quaternion(p.gx[rig.ids["Chest"]].basis.orthonormalized())
	var f: Vector3 = cq * Vector3(0.0, 0.0, 1.0)
	var unyaw := Quaternion(Vector3.UP, -atan2(f.x, f.z) * comp)
	p.set_grot("Wing_L", unyaw * cq * Quaternion(Vector3.UP, deg_to_rad(fold)) * Quaternion(Vector3.BACK, deg_to_rad(flap)))
	p.set_grot("Wing_R", unyaw * cq * Quaternion(Vector3.UP, deg_to_rad(-fold)) * Quaternion(Vector3.BACK, deg_to_rad(-flap)))


## 尾巴的主动摆：沿尾巴往后传的波(phase = 相位，amp = 摆幅)，再加整体甩向左(+)的 swing、往上翘的 lift(度)
func _dr_tail(p, phase: float, amp: float, swing: float, lift: float) -> void:
	for k in range(5):
		var a: float = amp * sin(phase - 0.8 * float(k)) + swing * (0.6 + 0.2 * float(k))
		p.r("BTail%d" % (k + 1), lift * (1.0 - 0.15 * float(k)), -a, 0.0)


## 待机姿势(th = 待机相位，br = 呼吸)
func _dr_idle_pose(p, th: float, br: float) -> void:
	_dr_body(p, DR_YAW, DR_LEAN - 1.5 * br, DR_DROP - 0.6 * br, 0.0, 0.6 * sin(th), DR_LEAD, 0.0, -DR_LEAD, 0.0)
	p.scale_("Chest", Vector3(1.0 + 0.02 * br, 1.0 + 0.012 * br, 1.0 + 0.03 * br))
	_head(p, -6.0 - 2.0 * br, -0.85 * DR_YAW, 0.0)
	_dr_wings(p, DR_FOLD - 9.0 * br, DR_FLAP + 7.0 * br)
	_dr_tail(p, th, 24.0, 0.0, 4.0)
	_hold_pole(p, DR_GRIP + Vector3(0.0, 0.6 * br, 0.0), DR_AXIS, DR_SPAN)


func idle_dragon(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / DRAGON_IDLE
	_dr_idle_pose(p, th, 0.5 - 0.5 * cos(2.0 * th))
	set_lids(p, blink_k(t, 2.2))


func run_dragon(t: float, p) -> void:
	p.reset()
	var ph: float = fposmod(t / DRAGON_RUN, 1.0)
	var th: float = TAU * ph
	var fl: Array = foot_track(ph, 14.0, 12.0, 0.38)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 14.0, 12.0, 0.38)
	var s: float = cos(th)
	# 前倾压到 ~19°：再往前，脑袋探得太前，后发(马尾弹簧链)会被"背后的墙"顶得乱跳
	p.move("Hips", Vector3(1.0 * sin(th), -8.0 + 3.2 * absf(sin(th)), 1.0))
	p.r("Hips", 11.0 + 2.0 * sin(2.0 * th), -9.0 * s, 2.5 * sin(th))
	p.r("Spine", 4.5, 5.0 * s - 7.0, -1.5 * sin(th))
	p.r("Chest", 3.5 + 1.5 * sin(2.0 * th + 0.4), 5.0 * s - 8.0, -1.5 * sin(th))
	_head(p, -17.0 - 2.0 * sin(2.0 * th), 15.0 - 1.0 * s, 1.5 * sin(th))
	legs(p, foot_target(1.0, fl, 7.0), foot_target(-1.0, fr, 7.0), Lib.E(fl[2], 4.0, 0), Lib.E(fr[2], -4.0, 0),
		-0.6 * maxf(float(fl[2]), 0.0), -0.6 * maxf(float(fr[2]), 0.0))
	_dr_wings(p, 46.0 + 3.0 * sin(2.0 * th), 14.0 + 6.0 * sin(2.0 * th + 0.6))
	_dr_tail(p, th, 14.0, 0.0, -6.0)
	_hold_pole(p, Vector3(-6.0, 51.0 + 1.0 * sin(2.0 * th), 7.5 - 1.0 * s), Vector3(0.8, 0.25, 0.55), DR_SPAN)
	set_lids(p, 0.0)


## 大斜斩的挥动平面法线(世界)：刀身从右肩后上方经头顶劈到左前下；刃口朝向 = 法线 × 刀身，始终领着挥动方向
const DR_SWING_N := Vector3(0.9, 0.3, -0.3)


## Q 版短手两手合握时刀的朝向几乎全由左手够得着的地方决定，抡不出大弧(见 attack_heavy 的说明)：
## 所以抡刀这一段是右手单手(左手松开往前探着瞄，劈下时往腰后一收)，前后各有一段和两手合握的待机姿势逐节 slerp 过渡
func attack_dragon(t: float, p) -> void:
	p.reset()
	var dur := 24.0 * F
	var yaw: float = kf_f([[0.0, DR_YAW], [0.18, -50.0], [0.23, -54.0], [0.30, -4.0, "i"], [0.40, 4.0, "o"], [dur, DR_YAW]], t)
	var lean: float = kf_f([[0.0, DR_LEAN], [0.18, -8.0, "o"], [0.23, -9.0], [0.30, 15.0, "i"], [0.42, 17.0, "o"], [0.62, 9.0], [dur, DR_LEAN]], t)
	var drop: float = kf_f([[0.0, DR_DROP], [0.18, 0.5, "o"], [0.23, 0.0], [0.30, 6.0, "i"], [0.42, 6.5], [dur, DR_DROP]], t)
	var push: float = kf_f([[0.0, 0.0], [0.18, -1.5], [0.30, 4.0, "i"], [0.45, 3.5], [dur, 0.0]], t)
	var lz: float = kf_f([[0.0, DR_LEAD], [0.20, DR_LEAD], [0.29, 10.0, "o"], [0.55, 10.0], [0.75, DR_LEAD]], t)
	_dr_body(p, yaw, lean, drop, push, 0.0, lz, _arc(t, 0.20, 0.29, 3.5) + _arc(t, 0.56, 0.74, 1.5), -DR_LEAD, 0.0)
	_head(p, kf_f([[0.0, -6.0], [0.18, -14.0, "o"], [0.30, 4.0, "i"], [0.45, 2.0], [dur, -6.0]], t), -0.85 * yaw, 0.0)
	_dr_wings(p, kf_f([[0.0, DR_FOLD], [0.18, -10.0, "o"], [0.23, -14.0], [0.30, 8.0, "i"], [0.42, 14.0], [dur, DR_FOLD]], t),
		kf_f([[0.0, DR_FLAP], [0.18, 28.0, "o"], [0.23, 30.0], [0.30, -16.0, "i"], [0.42, -10.0, "o"], [dur, DR_FLAP]], t))
	_dr_tail(p, 0.0, 24.0, kf_f([[0.0, 0.0], [0.20, -18.0], [0.30, 28.0, "i"], [0.45, 20.0], [dur, 0.0]], t), 4.0)
	var two: float = kf_f([[0.0, 1.0], [0.07, 0.0], [0.45, 0.0], [0.72, 1.0]], t)        # 两手合握的程度
	var base: Array[Quaternion] = p.rot.duplicate()
	var rot_one: Array[Quaternion] = base
	if two < 1.0:
		_dr_one_hand(p, t)
		rot_one = p.rot.duplicate()
	if two > 0.0:
		p.rot = base.duplicate()
		_hold_pole(p, DR_GRIP, DR_AXIS, DR_SPAN)
		if two < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = rot_one[i].slerp(p.rot[i], two)
			p.dirty = true
	set_lids(p, 0.0)


## 单手抡刀那一段：右手握点(胸腔局部) + 刀身方向(世界)；左手松开往前探着瞄 → 劈下时猛收到腰后 → 再回到刀柄上
func _dr_one_hand(p, t: float) -> void:
	var grip: Vector3 = kf_v([[0.0, DR_GRIP], [0.09, Vector3(-16.5, 63.0, 4.0)], [0.18, Vector3(-13.0, 75.0, -1.5)], [0.23, Vector3(-13.0, 76.0, -2.5)],
		[0.26, Vector3(-10.0, 74.5, 8.0), "i"], [0.30, Vector3(-4.5, 56.0, 16.5), "l"], [0.36, Vector3(-3.5, 50.0, 15.5), "o"],
		[0.50, Vector3(-4.0, 50.0, 14.5)], [0.72, DR_GRIP]], t)
	var aw: Vector3 = kf_v([[0.0, Vector3(-0.2, 0.7, -0.7)], [0.18, Vector3(-0.25, 0.55, -0.8)], [0.23, Vector3(-0.2, 0.45, -0.87)],
		[0.26, Vector3(-0.3, 0.92, 0.2), "i"], [0.30, Vector3(0.25, -0.4, 0.88), "l"], [0.36, Vector3(0.75, -0.55, 0.37), "o"],
		[0.50, Vector3(0.72, -0.5, 0.48)], [0.72, Vector3(0.6, -0.3, 0.74)]], t).normalized()
	var engage: float = kf_f([[0.0, 0.0], [0.12, 1.0], [0.50, 1.0], [0.72, 0.0]], t)
	var q: Quaternion = _pole_rot(_chest_dir(p, DR_AXIS)).slerp(wrot(aw, DR_SWING_N.cross(aw)), engage)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", grip), q, cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	var g_hold := [Vector3(8.0, 56.0, 13.0), Vector3(1.0, -0.5, -0.2), Vector3(0.1, 0.2, 1.0), Vector3(0.0, -1.0, 0.2), 60.0]
	var g_point := [Vector3(13.0, 62.0, 16.0), Vector3(1.0, -0.5, -0.3), Vector3(0.1, 0.15, 1.0), Vector3(0.0, -1.0, 0.1), 10.0]
	var g_back := [Vector3(15.0, 52.0, -3.0), Vector3(0.8, 0.0, -0.8), Vector3(0.05, -0.3, 1.0), Vector3(0.0, -1.0, -0.3), 80.0]
	_hand_track(p, "L", [[0.0, g_hold], [0.16, g_point, "o"], [0.27, g_point], [0.34, g_back, "i"], [0.50, g_back], [0.72, g_hold]], t)


func pierce_dragon(t: float, p) -> void:
	p.reset()
	var dur := 24.0 * F
	var yaw: float = kf_f([[0.0, DR_YAW], [0.16, -48.0, "o"], [0.21, -50.0], [0.30, -16.0, "i"], [0.42, -14.0], [dur, DR_YAW]], t)
	var lean: float = kf_f([[0.0, DR_LEAN], [0.16, -4.0, "o"], [0.21, -5.0], [0.30, 17.0, "i"], [0.42, 17.0], [0.62, 9.0], [dur, DR_LEAN]], t)
	var drop: float = kf_f([[0.0, DR_DROP], [0.16, 5.0, "o"], [0.21, 5.5], [0.30, 6.5, "i"], [0.42, 6.5], [dur, DR_DROP]], t)
	var push: float = kf_f([[0.0, 0.0], [0.16, -4.0, "o"], [0.21, -4.5], [0.30, 9.0, "i"], [0.42, 9.5], [0.60, 3.0], [dur, 0.0]], t)
	var lz: float = kf_f([[0.0, DR_LEAD], [0.16, 2.0], [0.21, 2.0], [0.29, 14.0, "o"], [0.46, 14.0], [0.70, DR_LEAD]], t)
	_dr_body(p, yaw, lean, drop, push, 0.0, lz, _arc(t, 0.21, 0.29, 4.0) + _arc(t, 0.48, 0.68, 2.0), -DR_LEAD, 0.0)
	_head(p, kf_f([[0.0, -6.0], [0.16, -4.0], [0.30, -10.0, "i"], [0.45, -8.0], [dur, -6.0]], t), -0.85 * yaw, 0.0)
	_dr_wings(p, kf_f([[0.0, DR_FOLD], [0.16, 55.0, "o"], [0.21, 58.0], [0.28, -6.0, "i"], [0.36, 0.0], [0.50, 10.0], [dur, DR_FOLD]], t),
		kf_f([[0.0, DR_FLAP], [0.16, 14.0], [0.21, 16.0], [0.28, -20.0, "i"], [0.36, -12.0], [0.55, 0.0], [dur, DR_FLAP]], t))
	_dr_tail(p, 0.0, 24.0, kf_f([[0.0, 0.0], [0.20, 10.0], [0.30, -12.0, "i"], [0.50, -6.0], [dur, 0.0]], t),
		kf_f([[0.0, 4.0], [0.20, 10.0], [0.30, -6.0, "i"], [dur, 4.0]], t))
	var grip: Vector3 = kf_v([[0.0, DR_GRIP], [0.16, Vector3(-7.5, 50.0, 1.0), "o"], [0.21, Vector3(-7.5, 49.5, 0.0)],
		[0.30, Vector3(-3.0, 55.0, 14.0), "i"], [0.42, Vector3(-3.0, 55.0, 14.5), "o"], [0.58, Vector3(-4.0, 52.5, 10.0)], [dur, DR_GRIP]], t)
	var axis: Vector3 = kf_v([[0.0, DR_AXIS], [0.16, Vector3(0.88, 0.25, 0.4), "o"], [0.21, Vector3(0.88, 0.22, 0.42)],
		[0.30, Vector3(0.45, 0.42, 0.8), "i"], [0.42, Vector3(0.45, 0.42, 0.8)], [0.58, Vector3(0.5, 0.52, 0.68)], [dur, DR_AXIS]], t)
	var span: float = kf_f([[0.0, DR_SPAN], [0.16, 12.5, "o"], [0.21, 12.5], [0.30, 6.5, "i"], [0.42, 6.5], [0.62, 9.0], [dur, DR_SPAN]], t)
	_hold_pole(p, grip, axis, span)
	set_lids(p, 0.0)


# =============================================================== 心音节点(bard)：抱着鲁特琴的吟游诗人(2026-10-04)
## 演奏(perform_bard，纤心的乐奏的吟唱动作)：鲁特琴是挂在胸口的道具 P_bard_lute(tools/model_weapons.gd 的 lute_prop：琴颈朝右上)，
## 手里的武器收起来(_stow)；右手握琴颈、左手在音孔上扫弦，身子跟着节拍轻轻晃、歪头看琴。
## 小动作：手拢在耳边听、闭眼哼一段，再提起裙摆转半圈行礼；胜利：两手举到肩旁轻轻挥，原地转着圈、翅膀照常扇
const BARD_TABLE := {
	"perform_bard": [2.0, true], "fidget_bard": [4.0, false], "victory_bard": [2.4, true],
	"sing_bard": [4.0, true], "sing_bard_focus": [4.0, true],
}
const BARD_STRUM := Vector3(7.0, 51.7, 13.0)      # 扫弦的位置(音孔和琴码之间，胸腔局部)
const BARD_FRET := Vector3(18.0, 64.6, 11.9)      # 右手握琴颈的位置(左手约定：x 取正，右手自动镜像)
const BARD_V := Vector3(-0.449, -0.849, 0.277)     # 横过琴弦的方向(扫弦就是沿它来回)


func perform_bard(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var beat: float = sin(th * 2.0)
	_base(p, 0.5 * sin(th), 0.4 * absf(beat), -6.0, 4.0, 3.0 * sin(th), 0.0, 6.0, 0.5)
	_head(p, 12.0 + 2.0 * absf(beat), 10.0, 8.0 + 3.0 * sin(th))
	var sw: float = sin(th * 4.0)
	_hand(p, "L", BARD_STRUM + BARD_V * (1.6 * sw), Vector3(1.0, -0.5, -0.3), Vector3(0.25, -0.75, -0.2), Vector3(-0.18, -0.22, -0.96), 28.0)
	_hand(p, "R", BARD_FRET + Vector3(0.0, 0.3 * sin(th), 0.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.18, 0.25, 0.95), Vector3(-0.45, 0.85, -0.28),
		50.0 + 15.0 * maxf(0.0, sin(th * 2.0 + 1.0)))
	set_lids(p, maxf(0.35, blink_k(t, 1.3)))


## 唱歌(没拿无声琴时的演奏)：右手照常拿着武器(弓垂在身侧 / 法器端在身前)，挺胸、下巴微抬、闭着眼随着旋律轻轻晃；
## 左手一句一句地从胸口往前舒展开(掌心朝上，像把歌声递给演奏对象)，再收回胸口。4 秒一段，两句
const G_SING_HEART := [Vector3(4.5, 62.0, 11.0), Vector3(1.0, -0.5, -0.4), Vector3(-1.0, 0.25, 0.2), Vector3(0.0, 0.0, -1.0), 22.0]
const G_SING_OUT := [Vector3(23.5, 66.5, 11.5), Vector3(0.6, -0.8, -0.3), Vector3(0.7, 0.15, 0.7), Vector3(0.0, 1.0, 0.1), 6.0]
const G_SING_HIGH := [Vector3(22.0, 81.0, 7.5), Vector3(0.8, -0.5, -0.4), Vector3(0.45, 0.75, 0.5), Vector3(-0.2, 0.5, 0.85), 4.0]


func sing_bard(t: float, p) -> void:
	_sing(t, p, "bow")


func sing_bard_focus(t: float, p) -> void:
	_sing(t, p, "focus")


func _sing(t: float, p, kit: String) -> void:
	p.reset()
	var th: float = TAU * t / 4.0
	var s1: float = sin(th)
	var beat: float = sin(th * 4.0)
	# 两句：0~2 秒一句舒展到前方，2~4 秒一句扬到高处(长音)；句子之间回到胸口换气
	var reach: float = kf_f([[0.0, 0.0], [0.45, 1.0, "o"], [1.5, 1.0], [2.0, 0.0], [4.0, 0.0]], t)
	var high: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.5, 1.0, "o"], [3.5, 1.0], [4.0, 0.0]], t)
	var breath: float = kf_f([[0.0, 1.0], [0.3, 0.0], [1.8, 0.0], [2.05, 1.0], [2.3, 0.0], [3.8, 0.0], [4.0, 1.0]], t)
	_base(p, 0.6 * s1, 0.3 * absf(beat), -4.0 + 4.0 * s1, -4.0 - 3.0 * high + 2.0 * breath, 3.0 * s1, 0.0, 6.0, 0.8)
	_head(p, -10.0 - 6.0 * high + 3.0 * breath, 6.0 * s1 + 8.0 * reach, 6.0 * sin(th + 0.6))
	# 右手：拿着武器
	if kit == "focus":
		hold_bow(p, follow(p, "Chest", FOCUS_GRIP + Vector3(0.0, 0.5 * s1, 0.0)), grot(FOCUS_AIM, Vector3(0.0, 1.0, 0.15)), Vector3(-1.0, -0.5, -0.4))
		fist_r(p, 70.0)
	else:
		var bow_rot := Lib.E(BOW_REST_ROT.x + 2.0 * s1, BOW_REST_ROT.y, BOW_REST_ROT.z)
		hold_bow(p, follow(p, "Chest", BOW_REST_GRIP + Vector3(0.0, 0.5 * s1, 0.0)), bow_rot, Vector3(-0.5, -0.3, -1.0))
		fist_r(p, 75.0)
	# 左手：胸口 → 往前舒展 / 扬到高处 → 回到胸口
	if high > 0.0:
		_hand_mix(p, "L", G_SING_HEART, G_SING_HIGH, high)
	else:
		_hand_mix(p, "L", G_SING_HEART, G_SING_OUT, reach)
	set_lids(p, clampf(0.75 - 0.5 * reach - 0.2 * high, 0.0, 1.0) if blink_k(t, 1.9) <= 0.0 else 1.0)


func fidget_bard(t: float, p) -> void:
	p.reset()
	_stow(p)
	var listen: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.8, 1.0], [2.1, 0.0]], t)
	var bow_k: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.6, 1.0, "o"], [3.3, 1.0], [3.8, 0.0]], t)
	var spin: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.7, 180.0, "o"], [3.6, 180.0], [4.0, 360.0]], t)
	_base(p, 0.4 * sin(t * TAU / 2.0), 0.0, 0.0, 14.0 * bow_k, 0.0, spin, 6.0, 2.0 * bow_k)
	_head(p, 6.0 * listen + 12.0 * bow_k, 14.0 * listen, -14.0 * listen)
	var ear := [Vector3(13.0, 82.0, 4.0), Vector3(1.0, -0.1, -0.6), Vector3(0.0, 1.0, 0.2), Vector3(-1.0, 0.0, 0.3), 20.0]
	var skirt := [Vector3(13.5, 44.0, 4.0), Vector3(1.0, -0.2, -0.5), Vector3(0.3, -1.0, 0.4), Vector3(0.0, 0.0, 1.0), 60.0]
	var mid := [Vector3(12.0, 64.0, 10.0), Vector3(1.0, -0.4, -0.5), Vector3(0.2, 0.2, 1.0), Vector3(-0.8, 0.0, 0.2), 20.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.2, mid], [0.45, ear], [1.8, ear], [2.05, mid], [2.4, skirt], [3.3, skirt], [3.8, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [2.1, G_RELAX], [2.4, skirt], [3.3, skirt], [3.8, G_RELAX]], t)
	set_lids(p, 1.0 if listen > 0.6 else blink_k(t, 3.0))


func victory_bard(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.6 * sin(th * 2.0), 0.8 * absf(sin(th * 2.0)), 0.0, -4.0, 0.0, 30.0 * sin(th), 6.0)
	_head(p, -6.0, 0.0, 10.0 * sin(th))
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		_hand(p, side, Vector3(17.0, 72.0 + 2.0 * sin(th * 2.0 + m), 6.0), Vector3(1.0, -0.6, -0.4),
			Vector3(0.3 * sin(th * 2.0) * m, 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 8.0)
	set_lids(p, blink_k(t, 1.1))


# =============================================================== 调香节点(perfumer)：鹿角的调香师(2026-10-05)
## 小动作：左手在胸前轻轻往脸前扇(把香气扇过来)，闭眼一嗅，歪头笑；再把手背到身后晃一晃。
## 胜利：两臂向两侧舒展(宽袖展开)，慢慢原地转一圈，头随着轻轻摆
const PERFUMER_TABLE := {
	"fidget_perfumer": [4.0, false], "victory_perfumer": [2.4, true],
}


func fidget_perfumer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var waft: float = kf_f([[0.0, 0.0], [0.4, 1.0], [2.2, 1.0], [2.6, 0.0]], t)
	var sniff: float = kf_f([[0.0, 0.0], [1.2, 0.0], [1.5, 1.0, "o"], [2.3, 1.0], [2.6, 0.0]], t)
	var behind: float = kf_f([[0.0, 0.0], [2.6, 0.0], [3.0, 1.0], [3.6, 1.0], [4.0, 0.0]], t)
	_base(p, 0.4 * sin(t * TAU / 2.0), 0.0, 4.0 * waft, 4.0 * waft - 3.0 * sniff, 0.0, 0.0, 6.0, 0.5)
	_head(p, -8.0 * sniff + 4.0 * waft, 6.0 * waft, 10.0 * sniff + 6.0 * behind * sin(t * 6.0))
	var fan := [Vector3(6.0, 68.0 + 1.5 * sin(t * 9.0), 12.0), Vector3(1.0, -0.5, -0.3), Vector3(-0.4, 0.6, 0.6), Vector3(-0.6, 0.0, -0.8), 10.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.4, fan], [2.2, fan], [2.6, G_RELAX], [3.0, G_BEHIND], [3.6, G_BEHIND], [4.0, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [2.6, G_RELAX], [3.0, G_BEHIND], [3.6, G_BEHIND], [4.0, G_RELAX]], t)
	set_lids(p, 1.0 if sniff > 0.5 else blink_k(t, 3.2))


func victory_perfumer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.5 * sin(th * 2.0), 0.6 * absf(sin(th * 2.0)), 0.0, -3.0, 0.0, 360.0 * t / 2.4, 6.0)
	_head(p, -6.0, 0.0, 8.0 * sin(th * 2.0))
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		_hand(p, side, Vector3(21.0, 62.0 + 2.0 * sin(th * 2.0 + m), 2.0), Vector3(0.6, -0.8, -0.3),
			Vector3(1.0, 0.1 * sin(th * 2.0), 0.1), Vector3(0.0, 1.0, 0.0), 12.0)
	set_lids(p, 0.5)


# =============================================================== 血嗜节点(vampire，男性款)(2026-10-05)
## 至亲的故事：武器效果有吟唱时 chant_vampire(浮空：骨盆往上抬、两腿垂着，双手举过头顶托着血球，仰头)，吟唱结束 throw_vampire(双手往前一推把血球扔出去，落回地面)；
## 没有吟唱时 cast_vampire(左手往上一抬做出一颗小血球，再往前一甩)。小动作：右手扯一扯左手的手套、再理一理领口，斜眼一笑；胜利：右手按胸行一个贵族礼
const VAMPIRE_TABLE := {
	"chant_vampire": [2.0, true], "throw_vampire": [0.6, false], "cast_vampire": [0.6, false],
	"fidget_vampire": [4.0, false], "victory_vampire": [2.0, true],
}
const VAMP_LIFT := 30.0                            # 浮空：骨盆抬高多少体素(≈ 0.38 米)


## 浮空的腿：两腿自然垂着，脚尖朝下，随身体轻轻晃
func _vamp_dangle(p, sw: float) -> void:
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -8.0 + 4.0 * sw * m, 0.0, 3.0 * m)
		p.r("Shin_" + side, 22.0 - 3.0 * sw * m, 0.0, 0.0)
		p.r("Foot_" + side, 35.0, 0.0, 0.0)


func chant_vampire(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	p.move("Hips", Vector3(0.0, VAMP_LIFT + 1.5 * sin(th), 0.0))
	p.r("Hips", -3.0, 0.0, 0.0)
	p.r("Spine", -6.0, 0.0, 1.5 * sin(th))
	p.r("Chest", -8.0, 0.0, 0.0)
	_vamp_dangle(p, sin(th))
	_head(p, -24.0, 0.0, 2.0 * sin(th))
	var up := [Vector3(16.0, 83.0 + 0.8 * sin(th * 2.0), 4.0), Vector3(1.0, -0.3, -0.3), Vector3(0.2, 1.0, 0.1), Vector3(-0.8, 0.1, 0.5), 30.0]
	_hand_mix(p, "L", up, up, 0.0)
	_hand_mix(p, "R", up, up, 0.0)
	set_lids(p, 0.25)


func throw_vampire(t: float, p) -> void:
	p.reset()
	_stow(p)
	var k: float = kf_f([[0.0, 0.0], [0.05, -0.25, "o"], [0.15, 1.0, "i"], [0.6, 1.0]], t)
	var land: float = kf_f([[0.0, 0.0], [0.18, 0.0], [0.5, 1.0, "o"]], t)
	p.move("Hips", Vector3(0.0, VAMP_LIFT * (1.0 - land), 0.0))
	p.r("Spine", -6.0 + 14.0 * maxf(k, 0.0), 0.0, 0.0)
	p.r("Chest", -8.0 + 10.0 * maxf(k, 0.0), 0.0, 0.0)
	_vamp_dangle(p, 0.0)
	_head(p, -24.0 + 30.0 * maxf(k, 0.0), 0.0, 0.0)
	var up := [Vector3(16.0, 83.0, 4.0), Vector3(1.0, -0.3, -0.3), Vector3(0.2, 1.0, 0.1), Vector3(-0.8, 0.1, 0.5), 30.0]
	var mid := [Vector3(8.0, 88.0, 14.0), Vector3(1.0, -0.3, -0.3), Vector3(-0.3, 0.8, 0.5), Vector3(-0.4, 0.0, 0.9), 15.0]
	var push := [Vector3(6.5, 70.0, 20.0), Vector3(1.0, -0.4, -0.3), Vector3(-0.2, 0.2, 1.0), Vector3(-0.2, 0.0, 1.0), 6.0]
	var kk: float = clampf(k, 0.0, 1.0)
	for side: String in ["L", "R"]:
		if kk < 0.5:
			_hand_mix(p, side, up, mid, kk * 2.0)
		else:
			_hand_mix(p, side, mid, push, kk * 2.0 - 1.0)


func cast_vampire(t: float, p) -> void:
	p.reset()
	var raise: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [0.3, 1.0], [0.42, 0.4, "i"], [0.6, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [0.28, 0.0], [0.38, 1.0, "i"], [0.6, 0.0]], t)
	_base(p, 0.0, 0.0, -10.0 * raise, -3.0 * raise + 6.0 * flick, 0.0, 0.0, 8.0, 1.0)
	_head(p, -10.0 * raise + 6.0 * flick, -8.0 * raise, 0.0)
	var palm_up := [Vector3(13.0, 76.0, 8.0), Vector3(1.0, -0.4, -0.4), Vector3(0.0, 0.3, 1.0), Vector3(0.0, 1.0, 0.0), 30.0]
	var fling := [Vector3(10.0, 68.0, 18.0), Vector3(1.0, -0.4, -0.3), Vector3(-0.2, 0.6, 0.8), Vector3(0.0, 0.3, 1.0), 4.0]
	var lift := [Vector3(13.5, 60.0, 9.0), Vector3(1.0, -0.5, -0.4), Vector3(0.0, -0.3, 1.0), Vector3(-0.3, 0.6, 0.3), 25.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.09, lift], [0.18, palm_up], [0.28, palm_up], [0.42, fling], [0.6, G_RELAX]], t)
	_relax(p, "R")


func fidget_vampire(t: float, p) -> void:
	p.reset()
	_stow(p)
	var glove: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.8, 1.0], [2.1, 0.0]], t)
	var collar: float = kf_f([[0.0, 0.0], [2.1, 0.0], [2.5, 1.0], [3.4, 1.0], [3.8, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 2.0), 0.0, -6.0 * glove, 6.0 * glove, 0.0, 0.0, 8.0, 1.5)
	_head(p, 14.0 * glove - 4.0 * collar, -10.0 * glove + 12.0 * collar, 4.0 * collar)
	var wrist := [Vector3(2.0, 56.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.8, -0.2, 0.5), Vector3(0.0, -1.0, 0.0), 30.0]
	var tug := [Vector3(1.0, 57.0 + 1.2 * sin(t * 14.0), 14.0), Vector3(1.0, -0.6, -0.2), Vector3(1.0, 0.0, 0.3), Vector3(0.0, 1.0, 0.0), 70.0]
	var col := [Vector3(-3.0, 70.0, 9.0), Vector3(1.0, -0.4, -0.3), Vector3(0.2, 1.0, 0.2), Vector3(-1.0, 0.0, 0.2), 50.0]
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.4, wrist], [1.8, wrist], [2.1, G_RELAX]], t)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, tug], [1.8, tug], [2.1, G_RELAX], [2.5, col], [3.4, col], [3.8, G_RELAX]], t)
	set_lids(p, maxf(0.4 * collar, blink_k(t, 1.2)))


func victory_vampire(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.0
	var bow_k: float = 0.5 - 0.5 * cos(th)
	_base(p, 0.0, -0.5 * bow_k, 0.0, 18.0 * bow_k, 0.0, 0.0, 8.0, 2.5)
	_head(p, 10.0 * bow_k, 0.0, 0.0)
	var chest := [Vector3(-2.0, 64.0, 9.0), Vector3(1.0, -0.6, -0.2), Vector3(-1.0, 0.1, 0.1), Vector3(0.0, 0.0, -1.0), 20.0]
	var out := [Vector3(20.0, 58.0, 4.0), Vector3(0.4, -0.8, -0.3), Vector3(1.0, -0.3, 0.2), Vector3(0.0, -1.0, 0.3), 10.0]
	_hand_mix(p, "R", chest, chest, 0.0)
	_hand_mix(p, "L", out, out, 0.0)
	set_lids(p, 0.3)


# =============================================================== 灭罪节点(absolver)：金发白袍的圣女(2026-10-05)
## 她是唯一的光：战斗中一直在吟唱 chant_absolver——微微浮起，右手托着光之心举在胸前、左手扶在球侧，闭着眼、低头对着光；
## 袍子随浮动轻轻摆，身子极慢地左右晃(光束的本体由 BattleView 画在敌人那边，球顶往天上射一道细光)。
## 小动作和胜利照规矩收起武器：小动作 = 双手合十、闭眼低头祈祷一下；胜利 = 微微浮起、两臂往上张开(V 字，掌心朝天)，仰头
const ABSOLVER_TABLE := {
	"chant_absolver": [2.4, true], "fidget_absolver": [4.0, false], "victory_absolver": [2.4, true],
}
const ABS_FLOAT := 5.0                              # 吟唱浮起：骨盆抬高多少体素(≈ 6 厘米)


func chant_absolver(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	p.move("Hips", Vector3(0.0, ABS_FLOAT + 1.2 * s1, 0.0))
	p.r("Hips", -1.0, 1.5 * sin(th * 0.5), 0.0)
	p.r("Spine", 2.0 + 0.6 * s1, 0.0, 0.8 * sin(th * 0.5))
	p.r("Chest", 3.0 + 0.6 * s1, 0.0, 0.0)
	# 浮着的腿：并拢、脚尖微微朝下
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -4.0 + 1.5 * s1 * m, 0.0, 1.5 * m)
		p.r("Shin_" + side, 9.0 - 1.0 * s1 * m, 0.0, 0.0)
		p.r("Foot_" + side, 22.0, 0.0, 0.0)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", Vector3(-3.0, 50.0 + 0.7 * s1, 13.5)), grot(cq * Vector3(0.0, -0.25, 1.0), cq * Vector3(0.05, 1.0, 0.2)),
		_chest_dir(p, Vector3(-1.0, -0.7, -0.3)))
	fist_r(p, 35.0)
	_hand(p, "L", Vector3(7.0, 58.5 + 0.7 * s1, 12.5), Vector3(0.9, -0.6, -0.3), Vector3(0.0, 1.0, 0.25), Vector3(-1.0, 0.0, 0.1), 12.0)
	_head(p, 12.0 + 1.2 * s1, 0.0, 3.0 * sin(th * 0.5))
	set_lids(p, 1.0)


func fidget_absolver(t: float, p) -> void:
	p.reset()
	_stow(p)
	var pray: float = kf_f([[0.0, 0.0], [0.7, 1.0], [2.9, 1.0], [3.6, 0.0]], t)
	var bow_k: float = kf_f([[0.0, 0.0], [1.0, 0.0], [1.6, 1.0], [2.5, 1.0], [3.0, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 4.0), 0.0, 0.0, 2.0 + 6.0 * bow_k, 0.0, 0.0, 6.0, 0.5)
	_hand_mix(p, "L", G_RELAX, G_PRAY, pray)
	_hand_mix(p, "R", G_RELAX, G_PRAY, pray)
	_head(p, 4.0 * pray + 12.0 * bow_k, 0.0, 3.0 * bow_k)
	set_lids(p, 1.0 if pray > 0.6 else blink_k(t, 0.4))


func victory_absolver(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	p.move("Hips", Vector3(0.0, ABS_FLOAT * 0.6 + 1.0 * s1, 0.0))
	p.r("Spine", -5.0, 0.0, 0.0)
	p.r("Chest", -6.0, 0.0, 0.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -3.0 + 1.0 * s1 * m, 0.0, 2.0 * m)
		p.r("Shin_" + side, 7.0, 0.0, 0.0)
		p.r("Foot_" + side, 16.0, 0.0, 0.0)
	# 两臂往上张开(手够得着的 V 字)，掌心朝天，像在把光洒下来
	var up := [Vector3(16.0, 83.0 + 0.8 * s1, 4.0), Vector3(1.0, -0.3, -0.3), Vector3(0.2, 1.0, 0.1), Vector3(-0.3, 0.6, 0.6), 8.0]
	_hand_mix(p, "L", up, up, 0.0)
	_hand_mix(p, "R", up, up, 0.0)
	_head(p, -16.0 + 1.0 * s1, 0.0, 4.0 * sin(th * 0.5))
	set_lids(p, 0.6)


# =============================================================== 屏息节点(sniper)：金发猫耳的狙击手(2026-10-05)
## 瞄准眉心：拿步枪瞄准时(普攻的【吟唱】)换成 aim_sniper——比平时端枪压得更低、更稳：上身前倾，低头把脸贴在枪托上看瞄准镜，
## 两脚分得更开、膝盖微屈，几乎不晃，只有很慢的一呼一吸(眯着眼)。
## 小动作(收起武器)：舔一下右手食指举起来试风向(左手叉腰)，侧头看一眼，再把头发往肩后一撩；胜利(收起武器)：双臂交叉抱在胸前，微微歪头，尾巴似的披风轻摆
const SNIPER_TABLE := {
	"aim_sniper": [3.0, true], "fidget_sniper": [4.0, false], "victory_sniper": [2.4, true],
}


func aim_sniper(t: float, p) -> void:
	p.reset()
	var br: float = sin(TAU * t / 3.0)
	_twist(p, -26.0, 5.0 + 0.4 * br, -0.5, 3.0, 0.9)
	p.radd("Head", 9.0, -4.0, 5.0)
	_stance_feet(p, 8.5, 3.5)
	_hold_rifle(p, RIFLE_AIM_GRIP + Vector3(0.0, -1.0 + 0.15 * br, 0.5), Vector3(0.0, 0.01 * br, 1.0), Vector3(0.0, 1.0, 0.0), -16.0)
	set_lids(p, 0.45)


func fidget_sniper(t: float, p) -> void:
	p.reset()
	_stow(p)
	var wind: float = kf_f([[0.0, 0.0], [0.75, 1.0], [2.0, 1.0], [2.4, 0.0]], t)
	var look: float = kf_f([[0.0, 0.0], [0.8, 0.0], [1.2, 1.0], [1.8, 1.0], [2.1, 0.0]], t)
	var hair: float = kf_f([[0.0, 0.0], [2.4, 0.0], [2.8, 1.0], [3.4, 1.0], [3.9, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 4.0), 0.0, 0.0, 1.0, 0.0, 0.0, 7.0, 0.5)
	_head(p, -6.0 * wind, 22.0 * look - 10.0 * hair, 6.0 * hair)
	var finger := [Vector3(15.0, 79.0, 5.0), Vector3(1.0, -0.3, -0.5), Vector3(0.1, 1.0, 0.1), Vector3(-0.3, 0.0, 1.0), 60.0]
	var shoulder := [Vector3(14.5, 66.0, 6.0), Vector3(1.0, -0.2, -0.7), Vector3(0.0, 0.3, 1.0), Vector3(-1.0, 0.0, 0.0), 18.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.75, finger], [2.0, finger], [2.6, shoulder], [2.9, G_HAIR], [3.3, G_HAIR], [3.6, shoulder], [3.98, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.5, G_HIP], [2.0, G_HIP], [2.4, G_RELAX]], t)
	set_lids(p, maxf(0.3 * look, blink_k(t, 3.0)))


func victory_sniper(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.4 * sin(th), 0.0, 0.0, -2.0, 0.0, 0.0, 8.0, 1.5)
	_head(p, -4.0, 6.0, 8.0 + 2.0 * sin(th))
	var cross_l := [Vector3(-7.0, 61.0, 10.0), Vector3(1.0, -0.4, -0.3), Vector3(-1.0, 0.1, 0.0), Vector3(0.0, 0.0, -1.0), 30.0]
	var cross_r := [Vector3(7.5, 62.5, 11.0), Vector3(1.0, -0.4, -0.3), Vector3(-1.0, 0.1, 0.0), Vector3(0.0, 0.0, -1.0), 30.0]
	_hand_mix(p, "L", cross_l, cross_l, 0.0)
	_hand_mix(p, "R", cross_r, cross_r, 0.0)
	set_lids(p, 0.35)


# ---------------------------------------------------------------- 狙击窝(2026-10-07)：拿步枪停下来作战时单膝跪地，把枪架在身前的黑箱子上
## 箱子是 UnitView 放的道具(NestCrate，单位数据 wclass_overrides.rifle.nest)，这里只管人：
##   右膝着地(大腿几乎竖直、小腿往后平贴地面、脚尖点地)，左脚踏在前面、膝盖立起；上身挺直、右肩往后收，
##   脸往右贴到枪托上看瞄准镜(眯眼)，枪口朝正前方(模型 +Z)，护木前段搁在箱子上(NEST_REST = 搁点，UnitView 按它摆箱子)。
## nest_aim_sniper   跪姿瞄准 / 等待(3s 循环，只有很慢的呼吸)
## nest_fire_sniper  开枪(和步枪普攻同长 20f、同出手 0.10s)：后坐把右肩顶回去、上身一仰，枪口在箱子上一跳再压回来
## nest_reload_sniper 跪姿换弹(和步枪换弹同长 78f)：枪一直搁在箱子上不动(Bow 骨钉在世界里)，左手扶着护木；
##   右手离开握把 → 抬栓、拉栓(退壳)→ 去右胯的弹袋摸一发 → 压进机匣(两下)→ 推栓、压栓 → 回握把、脸贴回枪托
## nest_in_sniper    从站着到跪下(0.4s)；nest_shift_sniper 换角度：半起身挪一下再跪下(0.53s，箱子由 UnitView 换)
const NEST_DROP := 24.0                                  # 跪姿时髋部下沉(体素)：大腿 19 + 膝盖 3 = 髋高 22
const NEST_GRIP := Vector3(-4.5, 60.0, 11.0)             # 握点(胸腔局部静止坐标)
const NEST_LA := Vector3(7.5, ANKLE_Y, 15.0)             # 左脚(前脚)踝
const NEST_RA := Vector3(-6.5, 8.5, -19.0)               # 右脚踝(小腿平贴地面往后、脚尖点地)
const NEST_TABLE := {
	"nest_aim_sniper": [3.0, true], "nest_fire_sniper": [20.0 * F, false], "nest_reload_sniper": [78.0 * F, false],
	"nest_in_sniper": [12.0 * F, false], "nest_shift_sniper": [16.0 * F, false],
}


## 跪姿：recoil 后坐(0..1)，br 呼吸(-1..1)，rise 起身程度(0 = 跪着，1 = 站着端枪)，lift = 枪从箱子上抬起(体素)，shift = 挪步时髋部横移
func _nest_pose(p, recoil: float, br: float, rise: float = 0.0, lift: float = 0.0, shift: float = 0.0) -> void:
	var k: float = 1.0 - rise
	p.move("Hips", Vector3(shift, -1.7 - (NEST_DROP - 1.7) * k + 0.25 * br * k, -3.0 * k - 1.2 * recoil))
	p.r("Hips", 2.0 * k, -16.0, 0.0)
	p.r("Spine", 3.0 + 3.0 * k - 2.0 * recoil, -8.0, 0.0)
	p.r("Chest", 4.0 - 3.5 * recoil + 0.4 * br, -10.0, -1.5 * recoil)
	_head(p, 12.0 - 5.0 * recoil, 30.0, -9.0 + 3.0 * recoil)
	var la: Vector3 = Vector3(7.0, ANKLE_Y, 0.5).lerp(NEST_LA, k) + Vector3(shift, 0.0, 0.0)
	var ra: Vector3 = Vector3(-7.0, ANKLE_Y, -1.5).lerp(NEST_RA, k) + Vector3(shift, 0.0, 0.0)
	legs(p, la, ra, Lib.E(0.0, 12.0, 0.0), Lib.E(0.0, -8.0, 0.0).slerp(Lib.E(70.0, -8.0, 0.0), k), 0.0, -35.0 * k)
	_hold_rifle(p, NEST_GRIP + Vector3(0.0, 1.4 * recoil + lift, -3.0 * recoil), Vector3(0.0, -0.07 + 0.1 * recoil + 0.02 * lift, 1.0), Vector3(0.0, 1.0, 0.0), -12.0)
	# 双手防穿模会把枪往左肩那边转十来度：整个人绕竖轴转回去，让枪口正对前方(身体自然地斜对着目标线，右肩在后)
	var f: Vector3 = -(p.grot_n("Bow") * Vector3.UP)
	p.r("Root", 0.0, -rad_to_deg(atan2(f.x, f.z)), 0.0)


func nest_aim_sniper(t: float, p) -> void:
	p.reset()
	_nest_pose(p, 0.0, sin(TAU * t / 3.0))
	set_lids(p, 0.45)


func nest_fire_sniper(t: float, p) -> void:
	p.reset()
	var rc: float = kf_f([[0.0, 0.0], [0.10, 0.0], [0.13, 1.0, "o"], [0.30, 0.15], [0.42, -0.08], [0.56, 0.0], [20.0 * F, 0.0]], t)
	_nest_pose(p, rc, 0.0)
	set_lids(p, kf_f([[0.0, 0.45], [0.10, 0.45], [0.13, 1.0], [0.30, 0.6], [0.5, 0.45]], t))


func nest_in_sniper(t: float, p) -> void:
	p.reset()
	var r: float = kf_f([[0.0, 1.0], [12.0 * F, 0.0, "o"]], t)
	_nest_pose(p, 0.0, 0.0, r, 2.0 * r)
	set_lids(p, 0.45 * (1.0 - r))


func nest_shift_sniper(t: float, p) -> void:
	p.reset()
	var r: float = kf_f([[0.0, 0.0], [5.0 * F, 0.55, "o"], [9.0 * F, 0.5], [16.0 * F, 0.0, "i"]], t)
	var sh: float = kf_f([[0.0, 0.0], [5.0 * F, 0.0], [9.0 * F, 1.5], [16.0 * F, 0.0]], t)
	_nest_pose(p, 0.0, 0.0, r, 3.0 * r, sh)
	set_lids(p, 0.45 * (1.0 - r))


func nest_reload_sniper(t: float, p) -> void:
	p.reset()
	var look: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [1.80, 1.0], [2.10, 0.0]], t)
	_nest_pose(p, 0.0, 0.3 * sin(TAU * t / 2.6))
	# 抬头离开枪托、低头看机匣
	p.radd("Head", -4.0 * look, -10.0 * look, 6.0 * look)
	# 枪：记下这时(两手端着)的位置朝向，之后钉在世界里不动(搁在箱子上，左手扶着)
	var g: Vector3 = p.gpos_n("Bow")
	var q: Quaternion = p.grot_n("Bow")
	var right: Vector3 = q * Vector3(-1.0, 0.0, 0.0)       # 枪的右侧(拉机柄那边)
	var back: Vector3 = q * Vector3(0.0, 1.0, 0.0)         # 往后(枪托方向)
	var up: Vector3 = q * Vector3(0.0, 0.0, 1.0)
	var knob: Vector3 = g + right * 6.0 + back * 1.0 + up * 4.0
	var knob_up: Vector3 = knob + up * 2.5 - right * 1.0
	var knob_back: Vector3 = knob_up + back * 6.0
	var port: Vector3 = g - back * 5.0 + up * 7.5
	var pouch: Vector3 = Vector3(-11.5, 27.0, 3.0)
	var hand: Vector3 = kf_v([[0.0, g], [0.18, knob, "o"], [0.26, knob_up, "o"], [0.40, knob_back, "o"], [0.62, pouch], [0.80, pouch],
		[1.05, port + up * 2.0, "o"], [1.15, port - up * 1.0, "i"], [1.25, port + up * 1.0], [1.35, port - up * 1.0, "i"], [1.48, knob_back + up * 1.0],
		[1.56, knob_back], [1.68, knob_up, "i"], [1.76, knob, "i"], [2.05, g, "o"], [2.6, g]], t)
	var hq_pinch: Quaternion = q * Quaternion(Vector3(0.0, 1.0, 0.0), -0.9)
	var hq: Quaternion = kf_q([[0.0, q], [0.18, hq_pinch], [1.76, hq_pinch], [2.05, q]], t)
	hold_bow(p, hand, hq, Vector3(-1.0, -0.6, -0.3))
	fist_r(p, kf_f([[0.0, 80.0], [0.15, 40.0], [0.20, 75.0], [0.42, 75.0], [0.55, 30.0], [0.70, 60.0], [1.40, 60.0], [1.50, 75.0], [1.80, 75.0], [1.95, 40.0], [2.05, 80.0]], t))
	# 钉住枪：Bow 骨的世界位置 / 朝向回到原来那样(它是右手的子骨，手动了它就得反算回去)
	p.set_grot("Bow", q)
	p.set_gpos_via_off("Bow", g)
	set_lids(p, 0.2 * (1.0 - look) + 0.0)

# =============================================================== 止息节点(commando，模型 captain)：短发耳机的突击队员(2026-10-05)
## 画上句点的突进(只是表现，时长 = 突进时长，BattleView 按 lunge_start.style 放)：
##  · 拿近战武器 = lunge_commando_flip：蹲下起跳，从目标头顶向前空翻一圈(骨盆绕横轴转 360°，腾空高度由 UnitView.play_lunge 给)，
##    空翻中右手的黑色微冲(P_commando_smg)朝下对着目标扫射，落在它背后半蹲；
##  · 拿远程武器 = lunge_commando_slide：压低身子从目标身侧滑铲过去，右手的匕首(P_commando_knife)从左往右横着划一刀，滑到它背后起身。
## 小动作(收起武器)：右手按着耳机说了两句、点点头，再抬起左手腕看一眼表；胜利(收起武器)：右手两指从眉梢往外一挥敬礼，左手叉腰
const COMMANDO_TABLE := {
	"lunge_commando_flip": [0.6, false], "lunge_commando_slide": [0.6, false],
	"fidget_captain": [4.0, false], "victory_captain": [2.4, true],
}


## 节奏对齐 UnitView.LEAP_PREP / LEAP_LAND(0.18 / 0.85)：深蹲蓄力 → 蹬地 → 空翻(0.2 ~ 0.82) → 0.85 重重落地半蹲 → 收势
func lunge_commando_flip(t: float, p) -> void:
	p.reset()
	var u: float = t / 0.6
	var crouch: float = kf_f([[0.0, 0.5], [0.15, 1.15, "o"], [0.22, 0.0, "i"], [0.82, 0.0], [0.87, 1.25, "o"], [1.0, 0.6]], u)
	var spin: float = 360.0 * Lib.smoother(clampf((u - 0.2) / 0.62, 0.0, 1.0))       # 正 = 向前翻(头往前、往下)
	var tuck: float = _arc(u, 0.22, 0.82, 1.0)
	p.move("Hips", Vector3(0.0, -1.7 - 9.0 * crouch, 0.0))
	p.r("Hips", spin, 0.0, 0.0)
	p.r("Spine", 10.0 * tuck + 8.0 * crouch, 0.0, 0.0)
	p.r("Chest", 8.0 * tuck, 0.0, 0.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -40.0 * crouch - 75.0 * tuck, 0.0, 6.0 * m)
		p.r("Shin_" + side, 70.0 * crouch + 100.0 * tuck, 0.0, 0.0)
		p.r("Foot_" + side, -20.0 * crouch, 0.0, 0.0)
	_head(p, -10.0 * tuck + 6.0 * crouch, 0.0, 0.0)
	# 右手：微冲朝下对着目标(胸腔前下方)，空翻中一直开火
	var cq: Quaternion = _chest_q(p)
	var aim: Vector3 = Vector3(0.0, -0.35, 1.0).lerp(Vector3(0.0, -0.15, 1.0), tuck)     # 跟着胸口转：翻到脸朝下时正好朝下扫射
	hold_bow(p, follow(p, "Chest", Vector3(-6.0, 56.0 - 4.0 * tuck, 15.0)), cq * grot(aim, Vector3(0.0, 1.0, 0.3)), Vector3(-1.0, -0.6, -0.3))
	fist_r(p, 82.0)
	_hand(p, "L", Vector3(13.0, 60.0 - 6.0 * tuck, 8.0), Vector3(1.0, -0.4, -0.5), Vector3(0.3, -0.3, 1.0), Vector3(0.0, -1.0, 0.0), 30.0)
	set_lids(p, 0.2)


## 节奏对齐 UnitView.LEAP_PREP / LEAP_LAND：先微微一沉蓄力 → 0.18 一下扑低滑出去 → 0.85 停住 → 起身
func lunge_commando_slide(t: float, p) -> void:
	p.reset()
	var u: float = t / 0.6
	var low: float = kf_f([[0.0, 0.0], [0.14, 0.25, "o"], [0.24, 1.0, "o"], [0.82, 1.0], [1.0, 0.0, "i"]], u)
	var cut: float = kf_f([[0.0, 0.0], [0.3, 0.0], [0.55, 1.0, "o"], [0.8, 1.0], [1.0, 0.6]], u)
	p.move("Hips", Vector3(0.0, -1.7 - 16.0 * low, -2.0 * low))
	p.r("Hips", -14.0 * low, -20.0 * cut, 0.0)
	p.r("Spine", 6.0 * low, -12.0 * cut, 0.0)
	p.r("Chest", 4.0 * low, -10.0 * cut, 0.0)
	# 滑铲：左腿往前伸直，右腿屈膝压在身下
	p.r("Thigh_L", -70.0 * low, 0.0, 6.0)
	p.r("Shin_L", 8.0 * low, 0.0, 0.0)
	p.r("Foot_L", -10.0 * low, 0.0, 0.0)
	p.r("Thigh_R", -20.0 * low, 0.0, -10.0 * low)
	p.r("Shin_R", 110.0 * low, 0.0, 0.0)
	p.r("Foot_R", 20.0 * low, 0.0, 0.0)
	_head(p, 4.0 * low, -8.0 * cut, 0.0)
	# 右手匕首：从左前方横着往右后划(刃朝外)
	var cq: Quaternion = _chest_q(p)
	var g: Vector3 = Vector3(2.0, 58.0, 15.0).lerp(Vector3(-16.0, 57.0, 8.0), cut)
	var blade: Vector3 = Vector3(0.6, 0.1, 0.8).lerp(Vector3(-0.8, 0.0, 0.5), cut).normalized()
	hold_bow(p, follow(p, "Chest", g), cq * wrot(blade, Vector3(0.0, 1.0, 0.0)), Vector3(-1.0, -0.4, -0.5))
	fist_r(p, 85.0)
	_hand(p, "L", Vector3(16.0, 50.0 - 6.0 * low, -2.0), Vector3(1.0, -0.2, -0.6), Vector3(0.2, -1.0, -0.2), Vector3(-1.0, 0.0, 0.0), 20.0)
	set_lids(p, 0.25)


func fidget_captain(t: float, p) -> void:
	p.reset()
	_stow(p)
	var talk: float = kf_f([[0.0, 0.0], [0.5, 1.0], [2.0, 1.0], [2.4, 0.0]], t)
	var nod: float = _arc(t, 1.0, 1.4, 1.0) + _arc(t, 1.5, 1.9, 1.0)
	var watch: float = kf_f([[0.0, 0.0], [2.4, 0.0], [2.8, 1.0], [3.5, 1.0], [3.95, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 4.0), 0.0, 0.0, 1.0 + 3.0 * watch, 0.0, 0.0, 7.0, 0.5)
	_head(p, 8.0 * nod + 14.0 * watch, 6.0 * talk - 8.0 * watch, -5.0 * talk)
	var ear := [Vector3(13.0, 80.0, 3.0), Vector3(1.0, -0.2, -0.6), Vector3(0.1, 1.0, -0.2), Vector3(-1.0, 0.0, 0.0), 40.0]
	var wrist := [Vector3(5.0, 62.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.9, 0.2, 0.3), Vector3(0.0, 1.0, 0.0), 30.0]
	var shoulder := [Vector3(14.5, 66.0, 6.0), Vector3(1.0, -0.2, -0.7), Vector3(0.0, 0.3, 1.0), Vector3(-1.0, 0.0, 0.0), 30.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.35, shoulder], [0.65, ear], [1.9, ear], [2.15, shoulder], [2.5, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [2.4, G_RELAX], [2.8, wrist], [3.5, wrist], [3.95, G_RELAX]], t)
	set_lids(p, maxf(0.35 * watch, blink_k(t, 2.2)))


func victory_captain(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var flick: float = 0.5 + 0.5 * sin(th)
	_base(p, 0.3 * sin(th), 0.0, 0.0, -1.0, 0.0, 0.0, 8.0, 1.5)
	_head(p, -3.0, -6.0, 5.0)
	var brow := [Vector3(10.0, 85.0, 8.0), Vector3(1.0, -0.2, -0.5), Vector3(0.2, 1.0, 0.2), Vector3(-0.6, 0.0, 0.8), 55.0]
	var out := [Vector3(18.0, 85.0, 6.0), Vector3(1.0, -0.2, -0.5), Vector3(0.6, 0.8, 0.2), Vector3(-0.4, 0.0, 0.9), 55.0]
	_hand_mix(p, "R", brow, out, flick)
	_hand_mix(p, "L", G_HIP, G_HIP, 0.0)
	set_lids(p, 0.3)


# =============================================================== 踏影节点(knight_errant，男性款)：青发黑金袍的游侠(2026-10-05)
## 逆光：瞬移没有中间过程——原地留下一个沉进影子的残影(Fx.shadow_sink)，到了敌人背后从影子里升起来(UnitView.emerge 把模型从地下升上来，
## 同时放 emerge_knight_errant：压低的蹲姿起身，剑往身侧一横、左手护在胸前)。
## 小动作(收起武器)：掸一掸右袖，再用右手拨一下头上的黑羽发饰，侧头一瞥；胜利(收起武器)：抱拳礼(右拳抵左掌在胸前)，微微欠身
const KNIGHT_TABLE := {
	"emerge_knight_errant": [0.45, false], "fidget_knight_errant": [4.0, false], "victory_knight_errant": [2.4, true],
}


func emerge_knight_errant(t: float, p) -> void:
	p.reset()
	var u: float = clampf(t / 0.45, 0.0, 1.0)
	var low: float = 1.0 - Lib.smooth(u)
	p.move("Hips", Vector3(0.0, -1.7 - 14.0 * low, 0.0))
	p.r("Hips", 10.0 * low, 0.0, 0.0)
	p.r("Spine", 14.0 * low, 0.0, 0.0)
	p.r("Chest", 8.0 * low, 0.0, 0.0)
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.r("Thigh_" + side, -60.0 * low - 4.0, 0.0, 8.0 * m)
		p.r("Shin_" + side, 95.0 * low + 6.0, 0.0, 0.0)
		p.r("Foot_" + side, -30.0 * low, 0.0, 0.0)
	_head(p, -6.0 * low, 0.0, 0.0)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", Vector3(-15.0, 50.0, 6.0)), cq * wrot(Vector3(-0.5, -0.3, 0.8).normalized(), Vector3(0.0, 1.0, 0.0)), Vector3(-1.0, -0.4, -0.5))
	fist_r(p, 85.0)
	_hand(p, "L", Vector3(5.0, 62.0, 12.0), Vector3(1.0, -0.6, -0.3), Vector3(0.0, 1.0, 0.2), Vector3(-1.0, 0.0, 0.0), 10.0)
	set_lids(p, 0.2)


func fidget_knight_errant(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dust: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.6, 1.0], [2.0, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.4, 1.0], [3.3, 1.0], [3.8, 0.0]], t)
	_base(p, 0.3 * sin(t * TAU / 4.0), 0.0, -6.0 * dust, 2.0 + 4.0 * dust, 0.0, 0.0, 8.0, 1.0)
	_head(p, 10.0 * dust - 4.0 * flick, -10.0 * dust + 16.0 * flick, 4.0 * flick)
	var arm := [Vector3(-2.0, 60.0, 12.0), Vector3(1.0, -0.6, -0.2), Vector3(-1.0, -0.1, 0.2), Vector3(0.0, -1.0, 0.0), 20.0]
	var brush := [Vector3(-1.0, 58.0 + 1.5 * sin(t * 16.0), 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-1.0, -0.2, 0.2), Vector3(0.0, 0.0, -1.0), 10.0]
	var shoulder := [Vector3(14.5, 66.0, 6.0), Vector3(1.0, -0.2, -0.7), Vector3(0.0, 0.3, 1.0), Vector3(-1.0, 0.0, 0.0), 30.0]
	var orn := [Vector3(12.0, 84.0, -2.0), Vector3(1.0, -0.2, -0.6), Vector3(0.1, 1.0, -0.3), Vector3(-1.0, 0.0, 0.0), 40.0]
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, arm], [1.6, arm], [2.0, G_RELAX], [2.25, shoulder], [2.55, orn], [3.3, orn], [3.55, shoulder], [3.95, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.4, brush], [1.6, brush], [2.0, G_RELAX]], t)
	set_lids(p, maxf(0.3 * flick, blink_k(t, 1.1)))


func victory_knight_errant(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var bow_k: float = 0.5 - 0.5 * cos(th)
	_base(p, 0.0, -0.3 * bow_k, 0.0, 10.0 * bow_k, 0.0, 0.0, 8.0, 2.0)
	_head(p, 8.0 * bow_k, 0.0, 0.0)
	var fist := [Vector3(-1.5, 62.0, 13.0), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 1.0, 0.2), Vector3(-1.0, 0.0, 0.1), 90.0]
	var palm := [Vector3(1.5, 62.5, 13.5), Vector3(1.0, -0.6, -0.2), Vector3(0.0, 1.0, 0.2), Vector3(-1.0, 0.0, 0.0), 6.0]
	_hand_mix(p, "R", fist, fist, 0.0)
	_hand_mix(p, "L", palm, palm, 0.0)
	set_lids(p, 0.35)


# =============================================================== 正行节点(noble)：金发银甲的花骑士(2026-10-06)
## 持盾的坦克：拿剑 / 长枪 / 法器都是右手单手持、左臂挂盾(长枪 / 法器的持盾待机、跑步、普攻在 anim_combat：*_polearm_guard / *_focus_guard)。
## 花蕊(强化普攻，光刃 / 光炮由表现层画)——前方 120° 扇形、约 4.5 米：
##   attack_cone_noble_sword(20f，出手 0.26s)：剑抡到右肩后、整个人往右后拧到底(蓄力)→ 一停 → 左脚上步，整个身子从右往左拧过去，
##     剑平平地从右后方扫到左后方(0.18~0.34s，0.26s 正好扫过正前方)→ 随挥定住 → 收回剑盾架势；盾臂在横扫时收到身侧(别挡刀)
##   attack_cone_noble_polearm(24f，出手 0.30s)：单手长枪的枪尾不能甩过后背，所以枪一直夹在右肋下、大致指着胸口正前方，
##     横扫完全靠转身(扭腰 + 整个人原地拧 + 上步)：往右后拧到底 → 0.21~0.39s 拧到左前(0.30s 枪尖正指前方)
##   attack_cone_noble_focus(27f，出手 0.36s)：光炮——压低身子躲在盾后、盾顶到身前正中，法器收在右肩旁蓄能(微微发抖)
##     → 从盾的右缘把法器猛推出去(0.36s 开炮)→ 被后坐力顶得上身后仰、法器上跳 → 收回
## 再绽之花(吟唱 3 秒，花瓣由表现层画)：chant_noble = 骑士立誓礼(剑竖在脸前、剑柄在胸口，剑面对着脸)，盾垂在身侧，低头闭眼，随呼吸轻晃；
##   chant_noble_polearm(长枪竖在右侧、枪尾快点到地面)、chant_noble_focus(法器捧在胸前)。游戏按 <动作>_<武器大类> 自动挑
## 小动作 / 胜利照规矩收起武器(见文件开头)
const NOBLE_TABLE := {
	"attack_cone_noble_sword": [20.0 * F, false], "attack_cone_noble_polearm": [24.0 * F, false], "attack_cone_noble_focus": [27.0 * F, false],
	"chant_noble": [2.4, true], "chant_noble_polearm": [2.4, true], "chant_noble_focus": [2.4, true],
	"fidget_noble": [4.0, false], "victory_noble": [2.4, true],
}
const NOBLE_SHIELD_SIDE := Vector3(14.5, 50.5, 6.0)       # 盾垂在身侧时的左手(胸腔局部)


func noble_table(t: Dictionary) -> void:
	for nm: String in NOBLE_TABLE.keys():
		t[nm] = {"dur": float(NOBLE_TABLE[nm][0]), "loop": bool(NOBLE_TABLE[nm][1]), "fn": Callable(self, nm)}


## 横扫的剑身朝向：phi = 世界里的水平方位(度，0 = 正前方，正 = 往左)，el = 仰角(度)；刃口(局部 +Z)朝扫动方向(从右往左)
static func _sweep_q(phi: float, el: float) -> Quaternion:
	var a: float = deg_to_rad(phi)
	var e: float = deg_to_rad(el)
	var d := Vector3(sin(a) * cos(e), sin(e), cos(a) * cos(e))
	return wrot(d, Vector3.UP.cross(d).normalized())


## 横扫时的身体：yaw 扭腰、spin 整个人原地拧(脚踩在地上不动，腿跟着拧)；头转回来盯着前方
func _noble_body(p, yaw: float, spin: float, lean: float, push: float, drop: float) -> void:
	p.r("Root", 0.0, spin, 0.0)
	_twist(p, yaw, lean, push, drop, 0.85)
	p.radd("Head", 0.0, -spin * 0.9, 0.0)


## 横扫的脚：左脚(前脚)在横扫时往左前方踏一步，右脚蓄力时后撤半步、横扫时脚跟往外拧(以前脚掌为轴)
func _noble_feet(p, lead0: float, lz: float, llift: float, rz: float, rlift: float, pivot: float) -> void:
	var k: float = Lib.smooth((lz - lead0) / 5.0)
	legs(p, Vector3(6.5 + 1.5 * k, ANKLE_Y + llift, -0.5 + lz), Vector3(-6.5, ANKLE_Y + rlift, -0.5 + rz),
		Lib.E(0, 6.0 + 22.0 * k, 0), Lib.E(0, -6.0 - 28.0 * pivot, 0))


# ---------------------------------------------------------------- 花蕊·剑 (20f = 0.667s，出手 0.26s)
func attack_cone_noble_sword(t: float, p) -> void:
	p.reset()
	var dur := 20.0 * F
	var sw: float = Lib.smooth((t - 0.18) / 0.16)              # 横扫进度：0.18 → 0.34，0.26 正好扫过正前方
	_noble_body(p, kf_f([[0.0, 0.0], [0.12, -46.0, "o"], [0.17, -50.0], [0.35, 46.0, "s"], [0.45, 38.0], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.12, -12.0, "o"], [0.17, -14.0], [0.35, 13.0, "s"], [0.45, 10.0], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.12, -6.0, "o"], [0.18, -7.0], [0.26, 8.0, "s"], [0.34, 14.0, "o"], [0.46, 10.0], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.12, -2.5, "o"], [0.18, -2.8], [0.27, 3.5, "s"], [0.36, 4.5], [0.48, 3.5], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.12, 2.0, "o"], [0.18, 2.2], [0.27, 3.8, "s"], [0.36, 4.6, "o"], [0.48, 3.5], [dur, 0.0]], t))
	var lz: float = kf_f([[0.0, 0.0], [0.10, -0.5], [0.18, -0.5], [0.27, 5.0, "o"], [0.46, 5.0], [0.62, 0.0]], t)
	var rz: float = kf_f([[0.0, 0.0], [0.10, -2.5, "o"], [0.48, -2.5], [0.64, 0.0]], t)
	_noble_feet(p, 0.0, lz, _arc(t, 0.18, 0.27, 2.8) + _arc(t, 0.46, 0.62, 1.4), rz, _arc(t, 0.02, 0.10, 1.5) + _arc(t, 0.48, 0.64, 1.2),
		kf_f([[0.0, 0.0], [0.18, 0.0], [0.30, 1.0], [0.46, 1.0], [0.62, 0.0]], t))
	# 剑：抡到右肩后(剑尖朝右后上方) → 平扫(世界方位 -120° → +120°) → 随挥定住 → 收回
	var q_idle: Quaternion = Lib.E(SWORD_IDLE_ROT.x, SWORD_IDLE_ROT.y, SWORD_IDLE_ROT.z)
	var q: Quaternion
	var grip: Vector3
	if t < 0.18:
		q = kf_q([[0.0, q_idle], [0.06, wrot(Vector3(-0.55, 0.83, 0.1), Vector3(0.1, 0.0, 0.55))], [0.12, _sweep_q(-118.0, 36.0), "o"], [0.18, _sweep_q(-120.0, 32.0)]], t)
		grip = kf_v([[0.0, SWORD_IDLE_GRIP], [0.06, Vector3(-18.5, 57.0, 5.0)], [0.12, Vector3(-19.5, 61.5, -1.0), "o"], [0.18, Vector3(-19.5, 62.0, -1.5)]], t)
	elif t <= 0.34:
		q = _sweep_q(lerpf(-120.0, 120.0, sw), kf_f([[0.18, 32.0], [0.26, -3.0, "s"], [0.34, -8.0]], t))
		grip = kf_v([[0.0, Vector3(-19.5, 62.0, -1.5)], [0.25, Vector3(-17.5, 61.0, 7.5), "l"], [0.5, Vector3(-10.0, 60.0, 15.5), "l"],
			[0.75, Vector3(-4.0, 59.0, 17.0), "l"], [1.0, Vector3(-0.5, 58.5, 17.5), "l"]], sw)
	else:
		q = kf_q([[0.34, _sweep_q(120.0, -8.0)], [0.42, _sweep_q(118.0, -5.0)], [0.53, wrot(Vector3(0.45, 0.75, 0.5), Vector3(-0.2, 0.5, -0.85))], [dur, q_idle]], t)
		grip = kf_v([[0.34, Vector3(-0.5, 58.5, 17.5)], [0.42, Vector3(0.0, 58.0, 17.0)], [0.53, Vector3(-8.0, 53.0, 12.5)], [dur, SWORD_IDLE_GRIP]], t)
	var pole: Vector3 = kf_v([[0.0, Vector3(-1.0, -0.2, -0.5)], [0.12, Vector3(-0.8, -0.4, -0.5)], [0.18, Vector3(-0.8, -0.45, -0.4)],
		[0.26, Vector3(-0.5, -0.85, -0.1)], [0.34, Vector3(-0.4, -0.9, 0.2)], [0.44, Vector3(-0.6, -0.8, 0.1)], [dur, Vector3(-1.0, -0.2, -0.5)]], t)
	hold_bow(p, follow(p, "Chest", grip), q, pole)
	fist_r(p, 85.0)
	_noble_shield(p, t, 0.12, 0.18, 0.30, 0.44, dur)
	set_lids(p, 0.0)


## 横扫时的盾臂：蓄力时往前顶着护身(盾面对着正前方)，横扫时收到身侧(盾面跟着身体转)，随挥后回到护身位
func _noble_shield(p, t: float, t_wind: float, t_hold: float, t_in: float, t_out: float, dur: float) -> void:
	var at: Vector3 = kf_v([[0.0, SHIELD_GUARD], [t_wind, Vector3(7.0, 55.0, 12.5), "o"], [t_hold, Vector3(7.5, 55.0, 12.0)],
		[t_in, Vector3(13.0, 51.0, 4.0)], [t_out, Vector3(13.0, 50.5, 3.5)], [lerpf(t_out, dur, 0.6), Vector3(10.0, 52.0, 8.5)], [dur, SHIELD_GUARD]], t)
	var k: float = kf_f([[0.0, 0.0], [t_hold, 0.0], [t_in, 0.85], [t_out, 0.85], [dur, 0.0]], t)
	_shield_arm(p, at, lerpf(-12.0, 30.0, k), k, Vector3(0.7, -0.5, -0.6).lerp(Vector3(0.9, -0.3, -0.3), k))


# ---------------------------------------------------------------- 花蕊·长枪 (24f = 0.8s，出手 0.30s)
func attack_cone_noble_polearm(t: float, p) -> void:
	p.reset()
	var dur := 24.0 * F
	var sw: float = Lib.smooth((t - 0.21) / 0.18)              # 横扫进度：0.21 → 0.39，0.30 枪尖正指前方
	_noble_body(p, kf_f([[0.0, SPEAR1_YAW], [0.15, -48.0, "o"], [0.21, -52.0], [0.39, 46.0, "s"], [0.50, 38.0], [dur, SPEAR1_YAW]], t),
		kf_f([[0.0, 0.0], [0.15, -14.0, "o"], [0.21, -16.0], [0.39, 15.0, "s"], [0.50, 12.0], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.15, -6.0, "o"], [0.21, -7.0], [0.30, 8.0, "s"], [0.39, 13.0, "o"], [0.52, 9.0], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.15, -2.5, "o"], [0.21, -2.8], [0.31, 3.5, "s"], [0.40, 4.5], [0.54, 3.5], [dur, 0.0]], t),
		kf_f([[0.0, 0.0], [0.15, 2.0, "o"], [0.21, 2.4], [0.31, 4.0, "s"], [0.40, 4.8, "o"], [0.54, 3.5], [dur, 0.0]], t))
	var lz: float = kf_f([[0.0, SPEAR1_LEAD], [0.13, SPEAR1_LEAD - 0.5], [0.21, SPEAR1_LEAD - 0.5], [0.31, 6.5, "o"], [0.52, 6.5], [0.70, SPEAR1_LEAD]], t)
	var rz: float = kf_f([[0.0, -SPEAR1_LEAD], [0.12, -SPEAR1_LEAD - 2.0, "o"], [0.54, -SPEAR1_LEAD - 2.0], [0.72, -SPEAR1_LEAD]], t)
	_noble_feet(p, SPEAR1_LEAD, lz, _arc(t, 0.21, 0.31, 2.8) + _arc(t, 0.52, 0.70, 1.4), rz, _arc(t, 0.02, 0.12, 1.5) + _arc(t, 0.54, 0.72, 1.2),
		kf_f([[0.0, 0.0], [0.21, 0.0], [0.34, 1.0], [0.52, 1.0], [0.70, 0.0]], t))
	# 枪(胸腔局部)：夹在右肋下，枪尖从"右前" → "正前" → "左前"(加上转身：世界方位 ≈ -85° → 0° → +85°)；握点从右胯后侧送到身前
	var grip: Vector3
	var axis: Vector3
	if t < 0.21:
		grip = kf_v([[0.0, SPEAR1_GRIP], [0.15, Vector3(-16.0, 55.0, 2.0), "o"], [0.21, Vector3(-16.0, 55.5, 1.5)]], t)
		axis = kf_v([[0.0, SPEAR1_AXIS], [0.15, Vector3(-0.28, 0.22, 0.94), "o"], [0.21, Vector3(-0.28, 0.2, 0.94)]], t)
	elif t <= 0.39:
		grip = kf_v([[0.0, Vector3(-16.0, 55.5, 1.5)], [0.5, Vector3(-12.5, 57.5, 12.5), "l"], [1.0, Vector3(-9.0, 57.0, 14.0), "l"]], sw)
		axis = kf_v([[0.0, Vector3(-0.28, 0.2, 0.94)], [0.5, Vector3(0.06, -0.03, 1.0), "l"], [1.0, Vector3(0.42, -0.06, 0.9), "l"]], sw)
	else:
		grip = kf_v([[0.39, Vector3(-9.0, 57.0, 14.0)], [0.50, Vector3(-9.5, 56.5, 13.5)], [0.64, Vector3(-12.5, 52.0, 11.0)], [dur, SPEAR1_GRIP]], t)
		axis = kf_v([[0.39, Vector3(0.42, -0.06, 0.9)], [0.50, Vector3(0.38, -0.02, 0.92)], [0.64, Vector3(0.15, 0.3, 0.94)], [dur, SPEAR1_AXIS]], t)
	var pole: Vector3 = kf_v([[0.0, Vector3(-1.0, -0.3, -0.45)], [0.15, Vector3(-0.8, -0.2, -0.7)], [0.21, Vector3(-0.8, -0.2, -0.7)],
		[0.30, Vector3(-0.9, -0.4, -0.3)], [0.39, Vector3(-0.8, -0.6, 0.0)], [0.52, Vector3(-0.8, -0.6, 0.0)], [dur, Vector3(-1.0, -0.3, -0.45)]], t)
	_hold_spear1(p, grip, axis, _cdir(p, pole))
	_noble_shield(p, t, 0.15, 0.21, 0.34, 0.50, dur)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 花蕊·法器(光炮) (27f = 0.9s，出手 0.36s)
func attack_cone_noble_focus(t: float, p) -> void:
	p.reset()
	var dur := 27.0 * F
	var brace: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.62, 1.0], [dur, 0.0]], t)            # 压低身子躲在盾后
	var gather: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.30, 1.0], [0.36, 0.0, "i"]], t)
	var push: float = kf_f([[0.0, 0.0], [0.30, 0.0], [0.36, 1.0, "i"], [0.56, 0.85, "o"], [dur, 0.0]], t)
	var kick: float = kf_f([[0.0, 0.0], [0.36, 0.0], [0.40, 1.0, "o"], [0.62, 0.0]], t)               # 后坐：一下顶回来再慢慢稳住
	var hum: float = sin(TAU * t / 0.1) * kf_f([[0.0, 0.0], [0.16, 0.0], [0.24, 1.0], [0.33, 1.0], [0.36, 0.0]], t)     # 蓄能时微微发抖
	_twist(p, -16.0 * gather + 10.0 * push - 4.0 * kick, 9.0 * brace + 4.0 * push - 13.0 * kick, -1.0 * gather + 2.5 * push - 3.5 * kick,
		4.5 * brace + 1.0 * push - 1.0 * kick, 0.85)
	p.radd("Head", 3.0 * gather - 4.0 * push - 6.0 * kick, 0.0, 0.0)
	legs(p, Vector3(7.0 + 0.5 * brace, ANKLE_Y + _arc(t, 0.02, 0.18, 1.6), -0.5 + 1.0 + 3.0 * brace), Vector3(-7.0 - 0.5 * brace, ANKLE_Y, -0.5 - 1.0 - 1.8 * brace),
		Lib.E(0, 6.0 + 6.0 * brace, 0), Lib.E(0, -6.0 - 12.0 * brace, 0))
	# 法器：收到右肩旁蓄能 → 从盾的右缘推出去 → 后坐上跳
	var gc := Vector3(-15.0, 59.0, 1.5)
	var gp := Vector3(-7.0, 60.5, 21.0)
	var gv: Vector3 = FOCUS1_GRIP.lerp(gc, gather).lerp(gp, push) + Vector3(0.0, 2.5, -4.0) * kick + Vector3(0.15, 0.2, 0.0) * hum
	var aim: Vector3 = FOCUS1_AIM.lerp(Vector3(0.15, 0.45, 1.0), gather).lerp(Vector3(0.03, 0.04, 1.0), push) + Vector3(0.0, 0.5, 0.0) * kick
	var up: Vector3 = Vector3(0.0, 1.0, 0.15).lerp(Vector3(0.25, 1.0, -0.3), gather).lerp(Vector3(0.0, 1.0, 0.05), push)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gv), cq * grot(aim, up), _cdir(p, Vector3(-1.0, -0.5, -0.4).lerp(Vector3(-0.8, -0.6, 0.0), push)))
	fist_r(p, 72.0)
	# 盾：顶到身前正中、整个人缩在后面；开炮时跟着震一下
	var sh: Vector3 = SHIELD_GUARD.lerp(Vector3(4.5, 54.5, 14.5), brace) + Vector3(0.0, 0.8, -1.5) * kick
	_shield_arm(p, sh, -12.0 + 10.0 * brace, 0.0)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 再绽之花：立誓(吟唱，2.4s 循环)
func chant_noble(t: float, p) -> void:
	_noble_vow(t, p, "sword")


func chant_noble_polearm(t: float, p) -> void:
	_noble_vow(t, p, "polearm")


func chant_noble_focus(t: float, p) -> void:
	_noble_vow(t, p, "focus")


func _noble_vow(t: float, p, kit: String) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	_base(p, 0.35 * s1, 0.25 * sin(2.0 * th), 0.0, 3.0 + 0.8 * s1, 1.0 * s1, 0.0, 5.5, 0.5)
	p.radd("Chest", -0.8 * sin(th - 0.8), 0.0, 0.0)                 # 呼吸
	_head(p, 13.0 + 1.2 * sin(th - 0.4), 0.0, 2.0 * s1)
	var cq: Quaternion = _chest_q(p)
	match kit:
		"polearm":
			# 长枪竖在右侧、枪尖略前倾，枪尾快点到地面
			_hold_spear1(p, Vector3(-12.5, 52.5 + 0.3 * s1, 9.0), Vector3(0.0, 1.0, 0.1), _cdir(p, Vector3(-1.0, -0.5, -0.3)))
		"focus":
			# 法器捧在胸前，低头对着它
			hold_bow(p, follow(p, "Chest", Vector3(-3.0, 59.5 + 0.5 * s1, 14.0)), grot(cq * Vector3(0.0, -0.25, 1.0), cq * Vector3(0.05, 1.0, 0.2)),
				_cdir(p, Vector3(-1.0, -0.7, -0.3)))
			fist_r(p, 40.0)
		_:
			# 骑士立誓：剑柄握在胸口正前方，剑竖在脸前(剑面对着脸、略往前倾，别贴到刘海)
			hold_bow(p, follow(p, "Chest", Vector3(-2.5, 59.5 + 0.5 * s1, 15.0)), cq * wrot(Vector3(0.0, 1.0, 0.17), Vector3(1.0, 0.0, 0.0)),
				_cdir(p, Vector3(-1.0, -0.8, -0.2)))
			fist_r(p, 85.0)
	# 盾垂在身侧，盾面朝左前
	_shield_arm(p, NOBLE_SHIELD_SIDE + Vector3(0.0, 0.3 * s1, 0.0), 40.0, 1.0, Vector3(0.8, -0.4, -0.5))
	set_lids(p, 1.0)


# ---------------------------------------------------------------- 小动作(4.0s)：拨发间的花 → 屈膝礼
const G_NB_MID := [Vector3(16.5, 66.0, 7.5), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 0.5, 1.0), Vector3(-1.0, 0.0, 0.0), 20.0]       # 抬手途中(肩前)
const G_NB_FLOWER := [Vector3(16.5, 81.0, 1.5), Vector3(1.0, -0.3, -0.6), Vector3(-0.15, 1.0, 0.2), Vector3(-1.0, 0.0, 0.15), 22.0]  # 指尖碰着头侧的花
const G_NB_HEART := [Vector3(-1.5, 61.5, 13.0), Vector3(1.0, -0.4, 0.05), Vector3(-1.0, 0.25, 0.15), Vector3(0.0, 0.0, -1.0), 16.0]  # (右手)按在左胸心口
const G_NB_SKIRT := [Vector3(17.5, 45.5, 6.5), Vector3(0.8, -0.3, -0.6), Vector3(0.25, -0.7, 0.65), Vector3(-0.6, 0.0, 0.3), 62.0]  # 捏着裙边往外提


func fidget_noble(t: float, p) -> void:
	p.reset()
	_stow(p)
	var flower: float = kf_f([[0.0, 0.0], [0.55, 1.0], [1.6, 1.0], [1.95, 0.0]], t)
	var curtsy: float = kf_f([[0.0, 0.0], [2.05, 0.0], [2.6, 1.0, "o"], [3.25, 1.0], [3.85, 0.0]], t)
	_base(p, 0.4 * sin(t * TAU / 4.0) - 0.8 * flower, -4.5 * curtsy, -5.0 * flower, 1.5 * flower + 9.0 * curtsy, -4.0 * flower, 0.0,
		6.0 - 0.8 * curtsy, 3.5 * curtsy)
	_head(p, -2.0 * flower + 13.0 * curtsy, -10.0 * flower, -15.0 * flower + 3.0 * curtsy)
	# 右手：抬到头侧(经肩前，免得肘一下翻过去)、指尖在花上拨两下 → 经肩前落到心口 → 行礼 → 放下
	var stroke: Array = G_NB_FLOWER.duplicate()
	stroke[0] = (G_NB_FLOWER[0] as Vector3) + Vector3(0.3, 1.0, 0.6) * sin(TAU * (t - 0.55) / 0.52) * flower
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.28, G_NB_MID], [0.55, G_NB_FLOWER], [0.56, stroke], [1.6, stroke], [1.61, G_NB_FLOWER], [1.9, G_NB_MID],
		[2.25, G_NB_HEART], [3.25, G_NB_HEART], [3.85, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [2.05, G_RELAX], [2.55, G_NB_SKIRT], [3.25, G_NB_SKIRT], [3.85, G_RELAX]], t)
	set_lids(p, maxf(maxf(0.55 * flower, kf_f([[0.0, 0.0], [2.45, 0.0], [2.6, 1.0], [3.1, 1.0], [3.3, 0.0]], t)), blink_k(t, 3.6)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：左手按心口、右手举在脸旁轻轻挥，身子轻晃 + 眨左眼
func victory_noble(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	_base(p, 1.2 * s1, 0.4 * absf(sin(th)), 4.0 * s1, -3.0, 3.0 * s1, 0.0, 6.0, 1.0)
	_head(p, -4.0 + 1.0 * sin(2.0 * th), 5.0 * s1, 9.0 + 3.0 * s1)
	_hand(p, "L", Vector3(4.0, 61.0, 11.5), Vector3(1.0, -0.5, -0.4), Vector3(-1.0, 0.2, 0.2), Vector3(0.0, 0.0, -1.0), 16.0)
	_hand(p, "R", Vector3(18.0, 80.0 + 0.6 * sin(2.0 * th), 4.5), Vector3(1.0, -0.3, -0.5), Vector3(0.3 * sin(2.0 * th), 1.0, 0.1), Vector3(-0.2, 0.0, 1.0), 6.0)
	var ph: float = fmod(t, 2.4)
	if ph > 0.5 and ph < 1.7:
		_wink(p, "L")
	else:
		set_lids(p, blink_k(ph, 2.0))


# =============================================================== 执剑节点(brave)：蓝发龙角的龙骑士少女(2026-10-06)
## 天命的勇者：真诚、坚定，对自己的梦想有一点小骄傲。模型 tools/chars/brave.gd(女性款，龙尾挂 BTail 链)。
## 龙尾是弹簧骨(build_anims 的 BTail 链，world_hold 0.7：每节只有约 3 成的主动转角传到尾巴上)：沿用龙的余烬的 _dr_tail
## 给每节一个"主动"摆角、弹簧在它上面晃，所以主动摆幅给得比想看到的大；小动作里尾巴的主动摆幅首尾都收到 0(和待机的静止尾巴接上)。
## 小动作(收起武器，4.0s)：双手叉腰、挺胸仰头望天 → 坚定地点一下头 → 右手(经肚子前，免得肘一下翻过去)收到胸前、
##   慢慢攥紧拳头("我会保护大家")，低头看一眼拳头、再眯眼望向前方，龙尾跟着一甩 → 放下
## 胜利(收起武器，2.4s 循环)：右拳高举向天(举到头侧上方：Q 版手臂够不到头顶)、左手按在心口，挺胸仰头、上身往左微弯把右肩送高，
##   踮脚一下下轻颠(每循环两下)，龙尾左右摇 + 眨左眼
const BRAVE_TABLE := {"fidget_brave": [4.0, false], "victory_brave": [2.4, true]}
const G_BV_HIP := [Vector3(12.9, 51.0, 1.8), Vector3(1.0, 0.1, -0.5), Vector3(-0.3, -0.5, -0.8), Vector3(-1.0, 0.0, 0.0), 80.0]      # 拳头叉在腰侧(比 G_HIP 靠前一点：别整个藏进两侧的长发里)
const G_BV_MID := [Vector3(11.5, 55.0, 8.5), Vector3(1.0, -0.4, -0.5), Vector3(0.0, -0.3, 1.0), Vector3(-1.0, 0.0, 0.0), 30.0]      # 叉腰 → 胸前的途中(肚子外侧前方)
const G_BV_OPEN := [Vector3(6.0, 62.0, 13.5), Vector3(1.0, -0.7, -0.1), Vector3(0.05, 1.0, 0.2), Vector3(-0.5, 0.0, -0.85), 35.0]   # 手举在胸前、手指半张
const G_BV_FIST := [Vector3(5.5, 61.0, 13.0), Vector3(1.0, -0.7, -0.1), Vector3(0.05, 1.0, 0.2), Vector3(-0.5, 0.0, -0.85), 92.0]   # 攥紧的拳头(拳心朝自己)
const G_BV_UP := [Vector3(19.5, 80.0, 6.0), Vector3(1.0, -0.3, -0.5), Vector3(0.15, 1.0, 0.2), Vector3(-0.4, 0.0, 1.0), 88.0]      # 拳头高举(头侧上方偏外，离开头和头发的轮廓)


func brave_table(t: Dictionary) -> void:
	for nm: String in BRAVE_TABLE.keys():
		t[nm] = {"dur": float(BRAVE_TABLE[nm][0]), "loop": bool(BRAVE_TABLE[nm][1]), "fn": Callable(self, nm)}


# ---------------------------------------------------------------- 小动作(4.0s)：叉腰望天、点头 → 胸前攥拳
func fidget_brave(t: float, p) -> void:
	p.reset()
	_stow(p)
	var hips: float = kf_f([[0.0, 0.0], [0.45, 1.0, "o"], [3.3, 1.0], [3.9, 0.0]], t)              # 叉腰挺胸
	var fist: float = kf_f([[0.0, 0.0], [1.75, 0.0], [2.15, 1.0], [3.25, 1.0], [3.75, 0.0]], t)      # 右手在胸前
	var yosh: float = _arc(t, 2.3, 2.6, 1.0)                                                         # 攥紧拳头时整个人一顿
	var gaze: float = kf_f([[0.0, 0.0], [2.85, 0.0], [3.05, 1.0], [3.4, 1.0], [3.7, 0.0]], t)        # 眯眼望向前方
	_base(p, 0.4 * sin(t * TAU / 4.0), -0.8 * yosh, 5.0 * fist, -6.0 * hips + 2.0 * fist + 3.0 * yosh, 0.0, 0.0,
		6.5 + 1.0 * hips, 0.5 * hips)
	_head(p, kf_f([[0.0, 0.0], [0.4, -3.0], [0.85, -25.0, "o"], [1.2, -25.0], [1.42, 6.0], [1.62, -5.0], [2.1, -5.0], [2.35, 12.0],
			[2.65, 12.0], [3.0, -6.0], [3.3, -6.0], [3.9, 0.0]], t),
		kf_f([[0.0, 0.0], [0.85, 10.0], [1.2, 10.0], [1.5, 0.0], [2.1, 0.0], [2.35, -8.0], [2.7, -8.0], [2.95, 0.0], [4.0, 0.0]], t),
		kf_f([[0.0, 0.0], [0.85, -5.0], [1.2, -5.0], [1.5, 0.0], [4.0, 0.0]], t))
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.45, G_BV_HIP], [1.55, G_BV_HIP], [1.88, G_BV_MID], [2.15, G_BV_OPEN], [2.45, G_BV_FIST],
		[3.25, G_BV_FIST], [3.5, G_BV_MID], [3.9, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.45, G_BV_HIP], [3.3, G_BV_HIP], [3.9, G_RELAX]], t)
	# 龙尾：一直慢慢摆，挺胸时翘起来，攥拳那一下往左一甩再弹回
	var env: float = kf_f([[0.0, 0.0], [0.5, 1.0], [3.4, 1.0], [4.0, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [2.25, 0.0], [2.45, 36.0, "o"], [2.75, -14.0], [3.05, 6.0], [3.35, 0.0]], t)
	_dr_tail(p, TAU * t / 1.3, 24.0 * env, flick, 8.0 * hips + 0.3 * flick)
	set_lids(p, maxf(0.35 * gaze, maxf(blink_k(t, 1.7), blink_k(t, 3.75))))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：右拳高举向天、左手按心口，轻颠 + 摇尾巴 + 眨左眼
func victory_brave(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	var pump: float = 0.5 - 0.5 * cos(2.0 * th)                 # 每循环颠两下
	_base(p, 0.6 * s1, 1.2 * pump, 3.0 * s1, -6.0, 6.0, 0.0, 7.0, 1.0, 0.25 * pump)
	p.radd("Shoulder_R", 0.0, 0.0, -8.0)                        # 右肩耸起，拳头举得更高
	_head(p, -12.0 - 2.0 * pump, -6.0 + 3.0 * s1, 4.0 + 2.0 * s1)
	var up: Array = G_BV_UP.duplicate()
	up[0] = (G_BV_UP[0] as Vector3) + Vector3(0.3 * pump, 2.2 * pump, 0.5 * pump)      # 跟着颠一下下往上顶
	_hand_mix(p, "R", up, up, 0.0)
	_hand_mix(p, "L", G_CHEST, G_CHEST, 0.0)
	_dr_tail(p, 2.0 * th, 22.0, 34.0 * s1, 8.0)
	var ph: float = fmod(t, 2.4)
	if ph > 1.3 and ph < 1.9:
		_wink(p, "L")
	else:
		set_lids(p, 0.0)


# =============================================================== 共歌节点(pacifist)：坐在轮椅上的人鱼歌姬(2026-10-07)
## 模型 tools/chars/pacifist.gd：上半身照人形骨骼；鱼尾刚性挂 Hips(从腰铺过坐垫、在座位前沿弯下去、尾鳍立在地上)，
## 轮椅刚性挂 Root(不跟着身子动)，腿骨没有体素。所以这里的动作都是"坐着的上半身"：
##   · Hips 一直不动(不平移、不转)：鱼尾挂在它上面，Hips 一动尾巴就戳进坐垫 / 尾鳍离地；只转 Spine / Chest / 头
##   · 手不能穿过两侧的大轮(x ±13..16，y 0..36)和扶手(x ±11..14，y 48..51，z -9..10)：左手搭在扶手前端，
##     武器握在右扶手前端(剑 / 麦克风)、右扶手外侧(大剑)或右轮外侧(长枪)，柄和挂饰都垂在扶手、轮子、前面的旗子外面
##   · 扶手、轮子挂 Root，不跟上身晃：搭扶手的手、立在椅子边的武器用模型(世界)坐标钉住(_pf_on_chair 换算成胸腔局部)
##   · 拿武器一律是"拳头横握"(_pf_hold_flip phi = 90)：手指朝前、武器竖着从拳头里穿过去(像握麦克风 / 法杖)，
##     不用 hold_bow 那种手垂着、武器贴着手背往上的握法(坐着时手腕会折得很难看)；所以她持械的动作里武器骨 Bow 一直带着
##     绕 X 90° 的局部旋转(刀光 / 投射物读的是 Bow 的世界变换，不受影响；和通用动作交叉淡化时武器会在手里顺势转一下)
## 普攻 = 唱歌(不打人，歌声影响全场)：吸一口气(胸口挺起、两肩微微耸起)，右手把武器(她的专属武器是麦克风 = 单手剑大类，剑的握法)
##   举到下巴前像对着它唱；出手时刻左臂往外舒展开、掌心朝上，仰头、闭一下眼，再收回待机。时长 / 出手时刻和武器大类一致：
##   剑 20f / 0.26s，大剑 36f / 0.52s，长枪 24f / 0.30s；首帧、末帧 = 待机 t = 0 的姿势。
##   拿的是真剑时就是剑竖在脸前(像正行节点的骑士礼)。大剑 / 长枪时右手一直握着武器(大剑往上提、竖起来贴着右肩；
##   长枪提起来、出手时往地上一顿)，唱歌的动作主要是头 + 张开的左臂。
## 待机(3.2s)：坐直、轻轻呼吸、上身微微晃；左手搭在左扶手前端，右手小臂搭在右扶手上、拳头伸出扶手头竖握着武器
##   (剑 / 麦克风竖在拳头上；大剑握在扶手外侧、剑身往后靠在右肩外侧；长枪像法杖一样立在右轮外侧，枪尾快到地面)。
## 移动(20f)：轮椅自己滑(魔法，不推轮子)：上身微微前倾、一颠一颠，头发被带着飘；左手攥着扶手，武器收在身边拿稳
##   (剑 / 麦克风照旧竖握，长枪提起来、往后斜着扛，大剑扛到右肩上)。
## 小动作 / 胜利照规矩收起武器(见文件开头)，只动上半身。
const PACIFIST_TABLE := {
	"idle_pacifist_sword": [3.2, true], "idle_pacifist_heavy": [3.2, true], "idle_pacifist_polearm": [3.2, true],
	"run_pacifist_sword": [20.0 * F, true], "run_pacifist_heavy": [20.0 * F, true], "run_pacifist_polearm": [20.0 * F, true],
	"attack_pacifist_sword": [20.0 * F, false], "attack_pacifist_heavy": [36.0 * F, false], "attack_pacifist_polearm": [24.0 * F, false],
	"fidget_pacifist": [4.0, false], "victory_pacifist": [2.4, true],
}
const PF_IDLE := 3.2
const PF_RUN := 20.0 * F
const PF_REL := {"sword": [20.0 * F, 0.26], "heavy": [36.0 * F, 0.52], "polearm": [24.0 * F, 0.30]}    # 普攻：[时长, 出手时刻]
const PF_ARMREST := Vector3(12.5, 53.5, 1.5)              # 手搭在扶手前端时的手腕(模型坐标，左手；右手 x 取负)
## 武器(模型坐标 = 轮椅的坐标)：[握点(拳心), 武器朝向(+Y = 刃 / 话筒头), 指节朝向]
const PF_SWORD := [Vector3(-12.5, 56.5, 15.0), Vector3(-0.04, 1.0, 0.03), Vector3(0.05, 0.0, 1.0)]     # 拳头伸出右扶手头，麦克风竖着(挂饰垂在旗子前面)
const PF_SPEAR := [Vector3(-18.5, 55.0, 5.0), Vector3(0.04, 1.0, 0.06), Vector3(0.0, 0.0, 1.0)]       # 立在右轮外侧(轮子外缘 x -16)，枪尾离地十几格
const PF_SPEAR_RUN := [Vector3(-18.5, 62.0, 4.0), Vector3(0.03, 0.95, -0.3), Vector3(0.0, 0.3, 0.95)] # 移动：提起来、往后斜
const PF_HEAVY := [Vector3(-15.5, 56.5, 12.0), Vector3(-0.1, 0.92, -0.38), Vector3(0.0, 0.38, 0.92)]   # 握在右扶手前端外侧，剑身往后上方靠在右肩外侧
## 唱歌时的右手(胸腔局部)：麦克风举到下巴前偏右，话筒头朝上、略往里对着嘴，指节朝左前(手背朝右前)
const PF_MIC_HEAD := Vector3(-4.0, 74.0, 14.5)            # 话筒球头的球心(麦克风局部 y 13)：别碰到脸和下巴
const PF_MIC_AXIS := Vector3(0.2, 0.97, 0.0)
const PF_MIC_KNUCK := Vector3(0.75, 0.0, 0.66)
## 手势(胸腔局部，左手约定)：[at, pole, fingers, palm, curl]
const G_PF_LIFT := [Vector3(17.0, 58.0, 9.0), Vector3(0.8, -0.5, -0.4), Vector3(0.45, -0.3, 0.85), Vector3(0.1, 0.1, 1.0), 20.0]   # 从扶手上抬起来的途中(手心朝前；唱歌时只用它的位置)
const G_PF_OPEN := [Vector3(23.5, 63.5, 11.0), Vector3(0.6, -0.8, -0.3), Vector3(0.75, 0.15, 0.65), Vector3(0.0, 0.85, 0.5), 6.0]   # 往外舒展开、掌心朝上(略朝前)
const G_PF_HEART := [Vector3(-0.5, 61.5, 14.0), Vector3(1.0, -0.4, 0.05), Vector3(-1.0, 0.25, 0.15), Vector3(0.0, 0.0, -1.0), 16.0]   # (右手)按在左胸心口
const G_PF_MID := [Vector3(13.5, 62.0, 11.0), Vector3(1.0, -0.5, -0.4), Vector3(0.1, 0.4, 1.0), Vector3(-0.8, 0.0, 0.3), 20.0]    # 扶手 → 胸前 / 脸旁的途中
const G_PF_WAVE := [Vector3(18.0, 76.0, 7.0), Vector3(1.0, -0.4, -0.5), Vector3(0.1, 1.0, 0.1), Vector3(-0.2, 0.0, 1.0), 6.0]    # 举在脸旁挥手
const G_PF_KISS := [Vector3(2.0, 66.5, 15.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.15, 1.0, 0.2), Vector3(0.0, 0.0, -1.0), 24.0]  # (右手)指尖贴在唇前
const G_PF_BLOW := [Vector3(17.5, 72.0, 15.0), Vector3(0.8, -0.6, -0.2), Vector3(0.35, 0.55, 0.75), Vector3(0.0, 0.6, 0.8), 4.0]  # 飞吻送出去：手往前外上方摊开


func pacifist_table(t: Dictionary) -> void:
	for nm: String in PACIFIST_TABLE.keys():
		t[nm] = {"dur": float(PACIFIST_TABLE[nm][0]), "loop": bool(PACIFIST_TABLE[nm][1]), "fn": Callable(self, nm)}


## 坐着的上半身：Hips 不动；lean 前倾(+ = 往前，度)、yaw 扭转(+ = 右肩往前)、roll 侧弯(+ = 往左)、heave 吸气(0..1：胸口挺起、两肩耸起)、
## lift = 上半身整个往上提一点(体素，移动时的颠)
func _pf_body(p, lean: float, yaw: float, roll: float, heave: float = 0.0, lift: float = 0.0) -> void:
	p.r("Spine", lean * 0.45, yaw * 0.45, roll * 0.45)
	p.r("Chest", lean * 0.55 - 4.0 * heave, yaw * 0.55, roll * 0.55)
	if lift != 0.0:
		p.move("Chest", Vector3(0.0, lift, 0.0))
	p.r("Shoulder_L", 0.0, 0.0, 6.0 * heave)
	p.r("Shoulder_R", 0.0, 0.0, -6.0 * heave)


## 待机的上身 / 头的参数(th = 待机相位)：[lean, yaw, roll, heave, 头 pitch, 头 yaw, 头 roll, 武器跟着呼吸的上下]
static func _pf_idle_vals(th: float) -> Array:
	var br: float = 0.5 + 0.5 * sin(th)
	return [1.0 + 0.8 * sin(2.0 * th + 0.6), 2.0 * sin(th + 0.8), 1.5 * sin(th), 0.35 * br,
		2.0 + 1.5 * sin(th + 1.0), -3.0 * sin(th + 0.4), 3.0 * sin(th + 1.3), 0.5 * br - 0.25]


## 模型(世界)坐标的一点 → 此刻胸腔姿态下 follow(p, "Chest", ·) 映射到它的那个静止坐标(扶手挂在 Root 上，不跟着上身晃)
func _pf_on_chair(p, w: Vector3) -> Vector3:
	p.fk()
	var i: int = rig.ids["Chest"]
	return p.gx[i].affine_inverse() * w + rig.pos[i]


## 手搭在扶手前端(手心朝下、手指搭到扶手头)的手势，位置钉在扶手上；grip 0..1 = 攥紧扶手(移动时)
func _pf_armrest(p, side: String, grip: float = 0.0) -> Array:
	var m: float = 1.0 if side == "L" else -1.0
	var loc: Vector3 = _pf_on_chair(p, Vector3(PF_ARMREST.x * m, PF_ARMREST.y, PF_ARMREST.z))
	return [Vector3(loc.x * m, loc.y, loc.z), Vector3(0.9, -0.2, -0.6), Vector3(0.05, -0.35, 1.0), Vector3(0.0, -1.0, -0.3), 26.0 + 40.0 * grip]


## 一只手沿 a →(经过 via 这个位置)→ b 走一条二次贝塞尔弧(u = 0.5 时在 via)，朝向从 a 直接球面插值到 b
func _pf_hand_arc(p, side: String, a: Array, via: Vector3, b: Array, u: float) -> void:
	var a0: Vector3 = a[0]
	var b0: Vector3 = b[0]
	var c: Vector3 = 2.0 * via - 0.5 * (a0 + b0)
	var at: Vector3 = a0 * ((1.0 - u) * (1.0 - u)) + c * (2.0 * u * (1.0 - u)) + b0 * (u * u)
	var q: Quaternion = _gq(side, a[2], a[3]).slerp(_gq(side, b[2], b[3]), u)
	_hand_q(p, side, at, (a[1] as Vector3).lerp(b[1], u).normalized(), q, lerpf(float(a[4]), float(b[4]), u))


## 右手握武器，手腕往前翻 phi 度：0 = 平常的握法(同 hold_bow：手垂着、武器贴着手背往上)，90 = 拳头横握(手指朝 q 的局部 +Z、
## 武器竖着从拳头里穿过去)，180 = 手指朝上；武器骨 Bow 在手里反着转 phi，所以武器的世界朝向始终是 q、握点始终是 grip
func _pf_hold_flip(p, grip: Vector3, q: Quaternion, phi: float, pole: Vector3) -> void:
	var hq: Quaternion = q * Quaternion(Vector3.RIGHT, deg_to_rad(-phi))
	p.ik2("UpperArm_R", "LowerArm_R", "Hand_R", grip - hq * BOW_GRIP_OFF, pole)
	p.set_grot("Hand_R", hq)
	p.rq("Bow", Quaternion(Vector3.RIGHT, deg_to_rad(phi)))


## 拳头横握：grip 握点、axis 武器朝向、knuck 指节朝向(都是世界方向)
func _pf_fist(p, grip: Vector3, axis: Vector3, knuck: Vector3, pole: Vector3, curl: float = 84.0) -> void:
	_pf_hold_flip(p, grip, wrot(axis, knuck), 90.0, pole)
	fist_r(p, curl)


## 右手的武器(待机 / 移动)：[握点, 武器朝向, 指节朝向, 肘的朝向](世界)；bob = 跟着呼吸 / 颠的上下
func _pf_weapon(kit: String, bob: float, run: bool) -> Array:
	var w: Array = PF_SWORD
	var pole := Vector3(-0.9, -0.4, -0.4)
	match kit:
		"polearm":
			w = PF_SPEAR_RUN if run else PF_SPEAR
			pole = Vector3(-0.5, -0.6, -0.6)
		"heavy":
			w = PF_HEAVY
			pole = Vector3(-0.8, -0.4, -0.45)
	return [(w[0] as Vector3) + Vector3(0.0, bob, 0.0), (w[1] as Vector3).normalized(), w[2], pole.normalized()]


func _pf_hold_weapon(p, kit: String, bob: float, run: bool) -> void:
	if kit == "heavy" and run:
		# 移动时单手把大剑扛在右肩上(剑身往后上方，同通用的 run_heavy)，拳头在右肩前
		_pf_fist(p, follow(p, "Chest", Vector3(-11.0, 60.0, 7.5) + Vector3(0.0, bob, 0.0)), _chest_dir(p, Vector3(-0.45, 0.75, -0.75)),
			_chest_dir(p, Vector3(0.4, 0.5, 0.75)), _cdir(p, Vector3(-1.0, -0.8, -0.3)))
		return
	var w: Array = _pf_weapon(kit, bob, run)
	_pf_fist(p, w[0], w[1], w[2], w[3])


# ---------------------------------------------------------------- 待机(3.2s 循环)
func idle_pacifist_sword(t: float, p) -> void:
	_pf_idle(t, p, "sword")


func idle_pacifist_heavy(t: float, p) -> void:
	_pf_idle(t, p, "heavy")


func idle_pacifist_polearm(t: float, p) -> void:
	_pf_idle(t, p, "polearm")


func _pf_idle(t: float, p, kit: String) -> void:
	p.reset()
	var v: Array = _pf_idle_vals(TAU * t / PF_IDLE)
	_pf_body(p, v[0], v[1], v[2], v[3])
	_head(p, v[4], v[5], v[6])
	_pf_hold_weapon(p, kit, v[7], false)
	var g: Array = _pf_armrest(p, "L")
	_hand_mix(p, "L", g, g, 0.0)
	set_lids(p, blink_k(t, 2.05))


# ---------------------------------------------------------------- 移动(20f 循环)：轮椅自己滑
func run_pacifist_sword(t: float, p) -> void:
	_pf_run(t, p, "sword")


func run_pacifist_heavy(t: float, p) -> void:
	_pf_run(t, p, "heavy")


func run_pacifist_polearm(t: float, p) -> void:
	_pf_run(t, p, "polearm")


func _pf_run(t: float, p, kit: String) -> void:
	p.reset()
	var th: float = TAU * fposmod(t / PF_RUN, 1.0)
	var bob: float = sin(2.0 * th)                    # 一圈颠两下；前倾只给一点点：背后的头发披在靠背外面，上身一往前探头发就陷进靠背里
	_pf_body(p, 4.0 + 1.5 * bob, 2.0 * sin(th), 2.5 * sin(th + 0.5), 0.2 + 0.1 * bob, 0.5 * bob)
	_head(p, -5.0 - 1.0 * bob, -1.5 * sin(th), -1.5 * sin(th + 0.5))
	_pf_hold_weapon(p, kit, 0.6 * bob, true)
	var g: Array = _pf_armrest(p, "L", 1.0)
	_hand_mix(p, "L", g, g, 0.0)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 普攻 = 唱歌
func attack_pacifist_sword(t: float, p) -> void:
	_pf_sing(t, p, "sword")


func attack_pacifist_heavy(t: float, p) -> void:
	_pf_sing(t, p, "heavy")


func attack_pacifist_polearm(t: float, p) -> void:
	_pf_sing(t, p, "polearm")


func _pf_sing(t: float, p, kit: String) -> void:
	p.reset()
	var dur: float = float(PF_REL[kit][0])
	var rel: float = float(PF_REL[kit][1])
	var t_br: float = rel * 0.62                       # 吸满气
	var t_op: float = rel * 0.68                       # 左臂开始舒展
	var t_hold: float = rel + (dur - rel) * 0.38       # 这一句唱完，开始收
	var v: Array = _pf_idle_vals(0.0)
	var breath: float = kf_f([[0.0, 0.0], [t_br, 1.0, "o"], [rel, 0.55, "i"], [t_hold, 0.35], [dur, 0.0]], t)
	var sing: float = kf_f([[0.0, 0.0], [t_op, 0.0], [rel, 1.0, "o"], [t_hold, 0.9], [dur, 0.0]], t)
	var mic: float = kf_f([[0.0, 0.0], [t_br, 1.0], [t_hold, 1.0], [dur, 0.0]], t)
	_pf_body(p, float(v[0]) - 4.0 * sing, float(v[1]) + 5.0 * sing, float(v[2]) - 2.0 * sing, lerpf(float(v[3]), 1.0, breath))
	_head(p, float(v[4]) + 5.0 * mic * (1.0 - sing) - 17.0 * sing, float(v[5]) + 5.0 * sing, float(v[6]) + 7.0 * sing)
	var w: Array = _pf_weapon(kit, v[7], false)
	match kit:
		"polearm":
			# 长枪提起来(吸气) → 出手时往地上一顿 → 回
			var dy: float = kf_f([[0.0, 0.0], [t_br, 3.5, "o"], [t_op, 3.5], [rel, -1.5, "i"], [rel + 0.1, -0.9, "o"], [t_hold, -0.7], [dur, 0.0]], t)
			_pf_fist(p, (w[0] as Vector3) + Vector3(0.0, dy, 0.0), ((w[1] as Vector3) + Vector3(0.06, 0.0, 0.04) * breath).normalized(), w[2], w[3])
		"heavy":
			# 大剑往上提、竖起来贴着右肩
			var a2: Vector3 = (w[1] as Vector3).lerp(Vector3(-0.04, 1.0, -0.15).normalized(), mic).normalized()
			_pf_fist(p, (w[0] as Vector3) + Vector3(1.0, 4.0, -1.5) * mic, a2, w[2], w[3])
		_:
			# 剑 / 麦克风：从扶手头举到下巴前(往上 + 往里，略带一点往前的弧)，指节从朝前转到朝左前
			var cq: Quaternion = _chest_q(p)
			var ax: Vector3 = PF_MIC_AXIS.normalized()
			var g2: Vector3 = follow(p, "Chest", PF_MIC_HEAD - ax * 13.0 + Vector3(0.3, 0.5, 0.3) * sing)
			var g: Vector3 = (w[0] as Vector3).lerp(g2, mic) + Vector3(0.0, 0.0, 2.0) * sin(PI * mic)
			var q: Quaternion = wrot(w[1], w[2]).slerp(cq * wrot(ax, PF_MIC_KNUCK), mic)
			var pole: Vector3 = (w[3] as Vector3).lerp(_cdir(p, Vector3(-0.6, -0.8, -0.1)), mic).normalized()
			_pf_hold_flip(p, g, q, 90.0, pole)
			fist_r(p, 84.0)
	# 左手：扶手 → 往外上方舒展开(掌心朝上，出手时刻正好张到头) → 停住 → 收回扶手；位置走一条经过 G_PF_LIFT 的弧，
	# 朝向从"手心朝下"一路直接转到"掌心朝上"(分两段转的话，短的那段一帧要转 50° 以上)
	var arm: Array = _pf_armrest(p, "L")
	var open: float = kf_f([[0.0, 0.0], [maxf(0.0, rel - 0.26), 0.0], [rel, 1.0], [t_hold, 1.0], [dur, 0.0]], t)
	_pf_hand_arc(p, "L", arm, G_PF_LIFT[0], G_PF_OPEN, open)
	set_lids(p, kf_f([[0.0, 0.0], [t_op, 0.0], [rel, 1.0], [t_hold, 1.0], [lerpf(t_hold, dur, 0.3), 0.0]], t))


# ---------------------------------------------------------------- 小动作(4.0s)：手按心口闭眼哼歌、左右轻晃 → 抬左手小小地挥一挥
func fidget_pacifist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var hum: float = kf_f([[0.0, 0.0], [0.5, 1.0], [2.5, 1.0], [2.8, 0.0]], t)
	var sw: float = sin(clampf((t - 0.45) / 2.1, 0.0, 1.0) * TAU * 2.0) * hum         # 左右轻晃两下
	var wave: float = kf_f([[0.0, 0.0], [2.55, 0.0], [2.9, 1.0, "o"], [3.45, 1.0], [3.9, 0.0]], t)
	_pf_body(p, 1.5 - 1.0 * hum, 3.0 * sw, 5.0 * sw - 3.0 * wave, 0.2 + 0.25 * hum)
	_head(p, -4.0 * hum + 3.0 * wave, 6.0 * sw + 6.0 * wave, 9.0 * sw + 10.0 * wave)
	var arm_r: Array = _pf_armrest(p, "R")
	var arm_l: Array = _pf_armrest(p, "L")
	_hand_keys(p, "R", [[0.0, arm_r], [0.25, G_PF_MID], [0.5, G_PF_HEART], [3.3, G_PF_HEART], [3.65, G_PF_MID], [4.0, arm_r]], t)
	var wv: Array = G_PF_WAVE.duplicate()
	wv[2] = Vector3(0.45 * sin(TAU * (t - 2.9) / 0.36), 1.0, 0.1)          # 手腕左右摆(小小地挥)
	_hand_keys(p, "L", [[0.0, arm_l], [2.55, arm_l], [2.75, G_PF_MID], [2.9, wv], [3.45, wv], [3.7, G_PF_MID], [4.0, arm_l]], t)
	set_lids(p, maxf(kf_f([[0.0, 0.0], [0.35, 0.0], [0.55, 1.0], [2.45, 1.0], [2.6, 0.0]], t), blink_k(t, 3.55)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：右手飞吻、左手在脸旁挥，开心地晃 + 眨左眼
func victory_pacifist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	var bnc: float = 0.5 - 0.5 * cos(2.0 * th)
	_pf_body(p, -2.0 + 1.5 * bnc, 4.0 * s1, 4.0 * s1, 0.3 + 0.3 * bnc, 0.5 * bnc)
	_head(p, -6.0 - 1.5 * bnc, 6.0 * s1, 4.0 + 8.0 * s1)
	var ph: float = fmod(t, 2.4)
	# 右手：唇前 → 往前外上方送出去 → 摊开停一下 → 经胸前收回唇前
	_hand_track(p, "R", [[0.0, G_PF_KISS], [0.45, G_PF_KISS], [0.75, G_PF_BLOW, "o"], [1.5, G_PF_BLOW], [1.95, G_PF_MID], [2.4, G_PF_KISS]], ph)
	# 左手：举在脸旁挥
	var wv: Array = G_PF_WAVE.duplicate()
	wv[0] = (G_PF_WAVE[0] as Vector3) + Vector3(0.0, 1.0 * bnc, 0.0)
	wv[2] = Vector3(0.4 * sin(4.0 * th), 1.0, 0.1)
	_hand_mix(p, "L", wv, wv, 0.0)
	if ph > 0.6 and ph < 1.4:
		_wink(p, "L")
	else:
		set_lids(p, blink_k(ph, 2.0))


# =============================================================== 白羽节点(angel)：淡蓝长发、白色大羽翼的天使枪手(2026-10-07)
## 温柔又有点让人发毛的"死亡天使"：用治疗弹打队友、顺便给他们预订一场葬礼。模型 tools/chars/angel.gd(女性款)，
## 一对半收的白色大羽翼挂 Wing_L / Wing_R(翼根在背后肩胛，模型里翼展往外、往后斜 30°)。
## 这两个动作的翅膀自己控制(wing_custom：build_anims 不再叠妖精翅膀的扑动)，用 _ag_wings：
##   open  = 从模型静止的半收样子往外 / 往前张开(度；待机时扑动的平均姿势 = -10，30 = 翼展正朝两侧)
##   raise = 绕翼面法线把翼尖往上抬(度，负 = 往下压)；tilt = 绕翼展方向扭(正 = 翼面上沿往前扣，扇下去时兜着风)
##   一次"扇"= 翼尖抬高 → 往下、往前压(下扑比上抬快) → 慢慢抬回；下扑的时候身子被托起来一点。
## 小动作(收起武器，4.0s)：双手合十、低头闭眼祈祷，羽翼往里收拢一点(像把自己裹起来) → 双手分开、慢慢往两侧张开(掌心朝前上方)，
##   挺胸抬头，羽翼大大展开、抬高 → 一次又大又慢的扇动(脚跟被托得离地一点) → 歪头、半闭着眼静静地笑(没有嘴，靠眼睑)，
##   那一下停得稍微久了一点 → 双臂、羽翼慢慢收回待机
## 胜利(收起武器，2.4s 循环，扇两下)：羽翼全展、慢慢扇，右手掌心朝外举在头侧(赐福；Q 版手臂够不到头顶)，左手按在心口，
##   双脚离地、脚尖朝下，随着扇动上下浮动 + 眨左眼(其余时候半闭着眼)
const ANGEL_TABLE := {"fidget_angel": [4.0, false], "victory_angel": [2.4, true]}
const AG_WING_U := Vector3(0.866, 0.0, -0.5)               # 左翼翼展方向(模型静止，往外往后斜 30°)
const AG_WING_N := Vector3(0.5, 0.0, 0.866)                # 左翼翼面法线(朝前外)：绕它正转 = 翼尖往上
## 手势(胸腔局部，左手约定)：[at, pole, fingers, palm, curl]
const G_AG_PART := [Vector3(10.5, 63.0, 14.0), Vector3(1.0, -0.7, -0.2), Vector3(0.35, 0.75, 0.55), Vector3(0.1, 0.3, 1.0), 8.0]     # 合十的手分开(胸前，掌心朝前)
const G_AG_WELCOME := [Vector3(23.0, 63.0, 9.5), Vector3(0.5, -0.8, -0.4), Vector3(0.8, 0.1, 0.6), Vector3(0.0, 0.6, 0.8), 6.0]     # 往两侧张开双臂，掌心朝前上方
const G_AG_PRAY := [Vector3(2.4, 59.5, 13.5), Vector3(1.0, -0.8, 0.0), Vector3(0.0, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 4.0]       # 合十(比 G_PRAY 低一点、往前一点：低头时别顶到下巴)
const G_AG_BLESS := [Vector3(21.0, 77.0, 8.0), Vector3(1.0, -0.5, -0.5), Vector3(0.12, 1.0, 0.1), Vector3(-0.2, 0.0, 1.0), 8.0]     # 举在头侧赐福，掌心朝外(前)；往外放，离开脸和两侧的长发


func angel_table(t: Dictionary) -> void:
	for nm: String in ANGEL_TABLE.keys():
		t[nm] = {"dur": float(ANGEL_TABLE[nm][0]), "loop": bool(ANGEL_TABLE[nm][1]), "fn": Callable(self, nm), "wing_custom": true}


## 羽翼(左右对称；右翼 = 左翼的旋转对 X 平面镜像)
func _ag_wings(p, open: float, raise: float, tilt: float = 0.0) -> void:
	var q := Quaternion(Vector3.UP, deg_to_rad(-open)) * Quaternion(AG_WING_N, deg_to_rad(raise)) * Quaternion(AG_WING_U, deg_to_rad(tilt))
	p.rq("Wing_L", q)
	p.rq("Wing_R", Quaternion(q.x, -q.y, -q.z, q.w))


## 悬空：双脚离开地面 lift 体素、脚尖朝下，两脚一高一低
func _ag_hover(p, lift: float) -> void:
	legs(p, Vector3(5.0, ANKLE_Y + lift + 2.5, -0.5), Vector3(-5.0, ANKLE_Y + lift + 3.5, -1.5),
		Lib.E(28.0, 5.0, 0.0), Lib.E(34.0, -5.0, 0.0), 6.0, 6.0)


# ---------------------------------------------------------------- 小动作(4.0s)：合十祈祷 → 张开双臂、羽翼展开扇一下 → 歪头静静地笑
func fidget_angel(t: float, p) -> void:
	p.reset()
	_stow(p)
	var pray: float = kf_f([[0.0, 0.0], [0.6, 1.0], [1.7, 1.0], [2.1, 0.0]], t)
	var open: float = kf_f([[0.0, 0.0], [1.7, 0.0], [2.45, 1.0, "o"], [3.25, 1.0], [3.95, 0.0]], t)
	var lift: float = kf_f([[0.0, 0.0], [2.62, 0.0], [2.92, 1.0, "o"], [3.3, 0.0]], t)             # 下扑时被托起来
	var tilt: float = kf_f([[0.0, 0.0], [2.75, 0.0], [3.15, 1.0], [3.55, 1.0], [3.95, 0.0]], t)     # 歪头
	_base(p, 0.4 * sin(t * 1.6) * (1.0 - open), 0.6 * lift, 0.0, 5.0 * pray - 6.0 * open - 1.5 * lift, 3.0 * tilt, 0.0,
		6.0, 0.0, 0.35 * lift)
	_head(p, 12.0 * pray - 7.0 * open + 3.0 * tilt, 0.0, 13.0 * tilt)
	for side: String in ["L", "R"]:
		_hand_keys(p, side, [[0.0, G_RELAX], [0.6, G_AG_PRAY], [1.7, G_AG_PRAY], [2.0, G_AG_PART], [2.5, G_AG_WELCOME], [3.3, G_AG_WELCOME],
			[3.95, G_RELAX]], t)
	# 羽翼：祈祷时往里收拢 → 展开抬高 → 一次大而慢的扇动(下扑 2.55 ~ 2.95) → 抬回、慢慢收回待机的样子
	var w_open: float = kf_f([[0.0, -10.0], [0.6, -17.0], [1.7, -17.0], [2.5, 36.0, "o"], [2.95, 48.0], [3.35, 36.0], [3.95, -10.0]], t)
	var w_raise: float = kf_f([[0.0, 0.0], [0.6, -5.0], [1.7, -5.0], [2.55, 36.0, "o"], [2.95, -20.0], [3.4, 8.0], [3.95, 0.0]], t)
	var w_tilt: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.55, -8.0], [2.8, 12.0], [3.1, 0.0], [3.95, 0.0]], t)
	_ag_wings(p, w_open, w_raise, w_tilt)
	set_lids(p, kf_f([[0.0, 0.0], [0.35, 0.0], [0.6, 1.0], [1.8, 1.0], [2.15, 0.0], [2.85, 0.0], [3.2, 0.45], [3.6, 0.45], [3.9, 0.0]], t))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：羽翼全展慢慢扇、右手赐福、左手按心口，离地浮动 + 眨左眼
func victory_angel(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var s1: float = sin(th)
	var bu: float = fposmod(t / 1.2, 1.0)                      # 扇动的相位(每循环两下)：0 = 翼尖最高，0.42 = 压到最低
	var w_raise: float = kf_f([[0.0, 28.0], [0.42, -12.0], [1.0, 28.0]], bu)
	var w_open: float = kf_f([[0.0, 32.0], [0.42, 42.0], [1.0, 32.0]], bu)
	var w_tilt: float = kf_f([[0.0, -6.0], [0.22, 12.0], [0.42, 4.0], [0.72, -8.0], [1.0, -6.0]], bu)
	_ag_wings(p, w_open, w_raise, w_tilt)
	var lift: float = 3.0 + 1.6 * (0.5 - 0.5 * cos(TAU * (bu - 0.08)))     # 下扑之后浮得最高
	_base(p, 0.0, lift, 3.0 * s1, -4.0 + 0.8 * cos(TAU * bu), 2.0 * s1, 0.0, 5.5, 0.0, 0.0)
	_ag_hover(p, lift)
	_head(p, -3.0 + 1.0 * cos(TAU * bu), 4.0 * s1, 6.0 + 2.0 * s1)
	var bl: Array = G_AG_BLESS.duplicate()
	bl[0] = (G_AG_BLESS[0] as Vector3) + Vector3(0.0, 0.6 * sin(TAU * bu), 0.0)
	_hand_mix(p, "R", bl, bl, 0.0)
	_hand_mix(p, "L", G_CHEST, G_CHEST, 0.0)
	var ph: float = fmod(t, 2.4)
	if ph > 1.3 and ph < 1.9:
		_wink(p, "L")
	else:
		set_lids(p, 0.3)


# =============================================================== 守林节点(warden)：橄榄绿短发、狮耳狮尾的荒野萨满少女(2026-10-07)
## 模型 tools/chars/warden.gd(女性款，细长的金棕狮尾挂 BTail 链)。她用"兽形"战斗：开局是狮子，第一次"死"变成巨蛛、第二次变成巨蟾，
## 第三次变回本体(之后照常用武器：长柄 / 剑 / 法器的通用动作)。没有单独的兽形模型：人还是那个人，兽形靠动作(兽的姿态和攻击) + 灵体特效表现；
## 兽形时游戏会把武器骨藏起来，这里的兽形动作也照 _stow 把 Bow / Weapon_L / Shield 缩到 0。
## 尾巴是弹簧骨(BTail 链，world_hold 0.7)：沿用龙的余烬的 _dr_tail 给每节一个"主动"摆角，摆幅给得比想看到的大。
## Q 版小短手(肩到手腕约 20 体素)：手举不过头顶(只到头侧)；蹲得再深手也碰不到地，巨蟾得上身几乎趴平、蹲到底才按得到地。
## 裙子挂在 Hips 上：蹲得深时前倾主要放在腰和胸上(胯一往前倒，裙子前摆就戳进地里)。
## 兽形的普攻首帧、末帧 = 同一兽形待机 t = 0 的姿势(从待机进来、连着打、打完回待机都接得上)。
##   狮子 —— 凶猛、伺机扑杀：
##     待机(3.2s)：左脚在前的低伏架势(屈膝沉胯、重心压在前脚、后脚跟抬起)，上身前探、耸着肩、头压低但眼睛盯着前方，
##       两手像爪子一样举在身前(左爪高、右爪低)，爪子一张一收；低吼的呼吸(1.6s 一次：猛吸一口、胸口鼓起、肩耸高，
##       再一边低吼一边慢慢呼出去 —— 呼气时胸口和头细细地颤)；尾巴一下下左右抽打
##     移动(20f)：弓着背的扑跃式冲刺(两脚一前一后几乎同时落地、腾空很长，像大猫奔跑)，两只爪子在身前一刨一刨，尾巴拖在身后随着跃起上下甩
##     普攻(24f = 0.8s，出手 0.24s)：右爪往右后上方扬起、上身往右拧、重心后坐(0 ~ 0.13s)，一顿 → 左脚踏出、拧腰前扑，
##       右爪从头侧往前下方斜着撕过去(出手：爪子正好扫过正前方)，左爪往回收 → 爪子带到肚子前(随挥) → 收回待机；
##       游戏里还有追加的追击爪击，所以是一下干脆的单手爪击，能接着连播
##   巨蛛 —— 诡异、窸窸窣窣：
##     待机(3.2s)：极低极宽的蹲姿(两脚大大分开、脚尖和膝盖朝外)，上身前探，两臂往两侧低低地张开、肘往上拱、手指朝下勾着(像多出来的一对蛛腿)，
##       头歪着、时不时"咔"地一抽，两只"蛛腿"轮流抬起来点一下
##     移动(20f)：压得很低的碎步疾走(一个循环每只脚走两步)，两臂像蛛腿一样和对侧的脚一起交替往前点，头一直歪着
##     普攻(24f，出手 0.28s)：上身往后一仰、两手扬到头两侧、手指勾成獠牙(0 ~ 0.17s) → 往前下方猛扑、两手一起往前下方合拢咬下去(出手)
##       → 咬住、甩两下 → 退回待机
##   巨蟾 —— 笨重、敦实：
##     待机(3.2s)：蹲到底(两脚大大分开、膝盖朝外)，上身几乎趴平往前倾，两手按在两脚之间前面的地上(像青蛙)，
##       头仰起来看前方、半闭着眼；鼓着肚子一下下地喘(1.6s 一次：鼓起来、憋一下、再慢慢瘪下去)
##     移动(20f)：一跳一跳：落地蹲住 → 两腿一蹬整个人蹿起来往前飞、两手往前伸 → 手先着地、蹲住
##     普攻(30f = 1.0s，出手 0.35s)：鼓起肚子、上身往后一缩、头往后仰(蓄力，0 ~ 0.22s) → 上身和头猛地往前一探(出手：像舌头弹出去)，
##       两手往前在地上一拍 → 停一下 → 往回一缩(舌头收回来)，再慢慢回到待机
##   变身(shift_warden，24f = 0.8s，不循环)：从低伏的姿势往上一挺、后仰弓背、两臂大大张开、仰头"吼"(0.27s 吼到最高、颤着停一下)，
##     再往下一沉，落成两爪在身前的低伏姿势。变成哪种兽(以及最后变回本体)都播这一个，之后交叉淡化到下一个待机。
## 小动作(收起武器，4.0s)：像猫一样伸懒腰 —— 两手往前伸直、屁股往后撅、塌腰仰头(闭眼)，再拱一下背 → 直起身，
##   右手挠右耳后面(头歪过去蹭着手、眯着眼，手一下下挠；左手叉腰) → 甩一下头、尾巴大大地一甩 → 放下
## 胜利(收起武器，2.4s 循环)：两爪举在头两侧、挺胸仰头"吼"一声(颤着、眯眼) → 开心地原地蹦两下(歪头、眨左眼)，尾巴一直快快地摇
const WARDEN_TABLE := {
	"idle_warden_lion": [3.2, true], "run_warden_lion": [20.0 * F, true], "attack_warden_lion": [24.0 * F, false],
	"idle_warden_spider": [3.2, true], "run_warden_spider": [20.0 * F, true], "attack_warden_spider": [24.0 * F, false],
	"idle_warden_toad": [3.2, true], "run_warden_toad": [20.0 * F, true], "attack_warden_toad": [30.0 * F, false],
	"shift_warden": [24.0 * F, false],
	"fidget_warden": [4.0, false], "victory_warden": [2.4, true],
}
const WD_IDLE := 3.2
const WD_RUN := 20.0 * F


func warden_table(t: Dictionary) -> void:
	for nm: String in WARDEN_TABLE.keys():
		t[nm] = {"dur": float(WARDEN_TABLE[nm][0]), "loop": bool(WARDEN_TABLE[nm][1]), "fn": Callable(self, nm)}


## 兽形的身体：drop 沉胯、push 胯往前送、sway 重心往左(体素)；lean 上身前倾(度)：胯分 hk，腰、胸平分剩下的；
## yaw 上身扭转(+ = 右肩往前)，roll 侧弯(+ = 头顶往她的右侧)，hunch 0..1 = 耸肩
func _wd_body(p, drop: float, push: float, sway: float, lean: float, hk: float, yaw: float = 0.0, roll: float = 0.0, hunch: float = 0.0) -> void:
	p.move("Hips", Vector3(sway, -1.7 - drop, push))
	p.r("Hips", lean * hk, yaw * 0.3, sway * 0.6)
	var rest: float = lean * (1.0 - hk) * 0.5
	p.r("Spine", rest, yaw * 0.3, roll * 0.5 - sway * 0.3)
	p.r("Chest", rest, yaw * 0.4, roll * 0.5 - sway * 0.3)
	p.r("Shoulder_L", 0.0, 0.0, 8.0 * hunch)
	p.r("Shoulder_R", 0.0, 0.0, -8.0 * hunch)


## 鼓肚子(k = 0..1)：腰(肚子)鼓起来，胸腔反着缩回去大半(胸腔以上的头、手臂都是它的子骨，别跟着一起变大)
func _wd_puff(p, k: float) -> void:
	var s := Vector3(1.0 + 0.14 * k, 1.0 + 0.04 * k, 1.0 + 0.18 * k)
	p.scale_("Spine", s)
	p.scale_("Chest", Vector3(1.0 + 0.025 * k, 1.0 + 0.01 * k, 1.0 + 0.03 * k) / s)


## 手势统一换成世界量再插值：[手腕位置, 肘的朝向, 手的世界旋转, 手指弯曲]。
## 胸腔局部的手势(左手约定，同 _hand 的 [at, pole, fingers, palm, curl]) → 世界
func _wd_c(p, side: String, g: Array) -> Array:
	var m: float = 1.0 if side == "L" else -1.0
	var at: Vector3 = g[0]
	var pole: Vector3 = g[1]
	return [follow(p, "Chest", Vector3(at.x * m, at.y, at.z)), _cdir(p, Vector3(pole.x * m, pole.y, pole.z)),
		_chest_q(p) * _gq(side, g[2], g[3]), float(g[4])]


## 世界坐标的手势(左手约定，右手镜像 x)：at 手腕、pole 肘的朝向、fingers 手指方向、palm 掌心朝向
func _wd_w(side: String, at: Vector3, pole: Vector3, fingers: Vector3, palm: Vector3, curl: float) -> Array:
	var m: float = 1.0 if side == "L" else -1.0
	return [Vector3(at.x * m, at.y, at.z), Vector3(pole.x * m, pole.y, pole.z).normalized(), _gq(side, fingers, palm), curl]


func _wd_mix(a: Array, b: Array, w: float) -> Array:
	return [(a[0] as Vector3).lerp(b[0], w), (a[1] as Vector3).lerp(b[1], w).normalized(), (a[2] as Quaternion).slerp(b[2], w),
		lerpf(float(a[3]), float(b[3]), w)]


func _wd_put(p, side: String, g: Array) -> void:
	var m: float = 1.0 if side == "L" else -1.0
	p.ik2("UpperArm_" + side, "LowerArm_" + side, "Hand_" + side, g[0], g[1])
	p.fk()
	p.set_grot("Hand_" + side, g[2])
	var curl: float = g[3]
	p.r("Fingers_" + side, -curl, 0, -22.0 * m * clampf(1.0 - curl / 60.0, 0.0, 1.0))
	p.r("Thumb_" + side, -10.0 - curl * 0.3, 0, 0)


## 一串世界手势按时间插值：keys = [[t, 手势, 缓动("s" "i" "o" "l"，默认 "s")], ...]
func _wd_track(p, side: String, keys: Array, t: float) -> void:
	if t <= float(keys[0][0]):
		_wd_put(p, side, keys[0][1])
		return
	for i in range(keys.size() - 1):
		var t0: float = keys[i][0]
		var t1: float = keys[i + 1][0]
		if t <= t1:
			var mode: String = str(keys[i + 1][2]) if (keys[i + 1] as Array).size() > 2 else "s"
			_wd_put(p, side, _wd_mix(keys[i][1], keys[i + 1][1], _ease(mode, (t - t0) / maxf(t1 - t0, 1e-6))))
			return
	_wd_put(p, side, keys[-1][1])


# ---------------------------------------------------------------- 狮子
const WL_DROP := 11.0
const WL_LEAN := 32.0
const WL_PUSH := 1.5
const WL_HK := 0.4
const WL_HEAD := 0.0                          # 头的世界俯角：头压得低(上身前探)，眼睛往前盯
## 爪子(胸腔局部，左手约定)：举到肩前、手指朝上勾着、掌心朝前("嗷呜"的爪子)
const G_WL_FRONT := [Vector3(12.0, 65.5, 13.5), Vector3(1.0, -0.5, -0.5), Vector3(0.15, 0.85, 0.5), Vector3(0.0, -0.2, 1.0), 48.0]    # 左爪：高、靠前
const G_WL_BACK := [Vector3(12.5, 60.0, 11.5), Vector3(1.0, -0.4, -0.6), Vector3(0.2, 0.75, 0.6), Vector3(0.0, -0.3, 1.0), 48.0]      # 右爪：低一点、靠后


## 狮子的脚：左脚在前(lz 往前迈、llift 抬脚)，右脚在后、脚跟抬起(rtip)
func _wl_feet(p, lz: float = 0.0, llift: float = 0.0, rtip: float = 0.6) -> void:
	legs(p, Vector3(8.0, ANKLE_Y + llift, 3.0 + lz), Vector3(-8.0, ANKLE_Y + 3.0 * rtip, -5.5),
		Lib.E(0.0, 14.0, 0.0), Lib.E(30.0 * rtip, -24.0, 0.0), 0.0, -24.0 * rtip)


func idle_warden_lion(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / WD_IDLE
	var bp: float = fposmod(t / 1.6, 1.0)
	var br: float = kf_f([[0.0, 0.0], [0.3, 1.0, "o"], [1.0, 0.0]], bp)                      # 猛吸一口 → 慢慢呼出去
	var growl: float = kf_f([[0.0, 0.0], [0.34, 0.0], [0.45, 1.0], [0.85, 1.0], [1.0, 0.0]], bp) * sin(TAU * t / (4.0 * F))   # 呼气时低吼的颤
	var lean: float = WL_LEAN - 3.0 * br + 0.5 * growl
	_wd_body(p, WL_DROP - 0.8 * br, WL_PUSH, 0.7 * sin(th), lean, WL_HK, 2.0 * sin(th), 0.0, 0.5 + 0.5 * br)
	_wl_feet(p)
	_head(p, -lean + WL_HEAD - 2.0 * br + 0.8 * growl, 3.4 * sin(th), 2.0 * sin(2.0 * th))
	var gf: Array = G_WL_FRONT.duplicate()
	gf[0] = (G_WL_FRONT[0] as Vector3) + Vector3(0.0, 1.0 * br + 0.2 * growl, 0.5 * sin(th))
	gf[4] = 48.0 + 12.0 * sin(2.0 * th)
	var gb: Array = G_WL_BACK.duplicate()
	gb[0] = (G_WL_BACK[0] as Vector3) + Vector3(0.0, 0.8 * br + 0.2 * growl, -0.5 * sin(th))
	gb[4] = 48.0 - 10.0 * sin(2.0 * th)
	_hand_mix(p, "L", gf, gf, 0.0)
	_hand_mix(p, "R", gb, gb, 0.0)
	_dr_tail(p, 2.0 * th, 30.0, 18.0 * sin(th), 8.0)
	set_lids(p, blink_k(t, 2.4))


func run_warden_lion(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t / WD_RUN, 1.0)
	var th: float = TAU * ph
	# 扑跃：右脚落地(0.8)紧跟着左脚(1.0)，两脚着地时压得最低(0.1)，0.38 ~ 0.78 两脚腾空、跃到最高(0.6)
	var fl: Array = foot_track(ph, 15.0, 12.0, 0.38)
	var fr: Array = foot_track(fposmod(ph + 0.2, 1.0), 15.0, 12.0, 0.38)
	var air: float = 0.5 - 0.5 * cos(TAU * (ph - 0.1))
	var lean: float = 40.0 - 7.0 * air
	_wd_body(p, 12.0 - 5.0 * air, 2.0, 0.6 * sin(th), lean, 0.4, 4.0 * sin(th), 0.0, 0.6)
	legs(p, foot_target(1.0, fl, 6.5), foot_target(-1.0, fr, 6.5), Lib.E(fl[2], 6.0, 0), Lib.E(fr[2], -6.0, 0),
		-0.6 * maxf(float(fl[2]), 0.0), -0.6 * maxf(float(fr[2]), 0.0))
	_head(p, -lean + 2.0 - 3.0 * air, -1.2 * sin(th), 1.5 * sin(th))
	# 爪子在身前一刨一刨：落地前伸到最前 → 往下、往后刨 → 从下面收回来再往前伸
	for side: String in ["L", "R"]:
		var a: float = -TAU * (ph - (0.72 if side == "L" else 0.78))
		var w: float = 0.5 - 0.5 * cos(a)                      # 0 = 最前，1 = 最后
		var off := Vector3(0.0, 3.0 * sin(a), 0.0)
		var front := [Vector3(11.0, 59.0, 18.0) + off, Vector3(1.0, -0.6, -0.4), Vector3(0.1, 0.1, 1.0), Vector3(0.0, -1.0, 0.1), 50.0]
		var back := [Vector3(12.5, 53.0, 7.0) + off, Vector3(0.8, -0.3, -0.8), Vector3(0.1, -0.8, 0.6), Vector3(0.0, -0.6, -1.0), 62.0]
		_hand_mix(p, side, front, back, w)
	_dr_tail(p, th, 16.0, 0.0, 2.0 - 10.0 * cos(TAU * (ph - 0.35)))
	set_lids(p, 0.0)


func attack_warden_lion(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dur := 24.0 * F
	var yaw: float = kf_f([[0.0, 0.0], [0.13, -24.0, "o"], [0.155, -26.0], [0.27, 26.0, "i"], [0.40, 20.0, "o"], [dur, 0.0]], t)
	var lean: float = kf_f([[0.0, WL_LEAN], [0.13, 18.0, "o"], [0.17, 17.0], [0.27, 38.0, "i"], [0.42, 34.0], [dur, WL_LEAN]], t)
	var drop: float = kf_f([[0.0, WL_DROP], [0.13, 7.5, "o"], [0.17, 7.5], [0.27, 11.5, "i"], [0.45, 11.0], [dur, WL_DROP]], t)
	var push: float = kf_f([[0.0, WL_PUSH], [0.13, -1.5, "o"], [0.17, -1.8], [0.27, 4.5, "i"], [0.45, 4.0], [dur, WL_PUSH]], t)
	_wd_body(p, drop, push, 0.0, lean, WL_HK, yaw, 0.0, kf_f([[0.0, 0.5], [0.13, 1.0], [0.27, 0.7], [dur, 0.5]], t))
	var lz: float = kf_f([[0.0, 0.0], [0.16, 0.0], [0.25, 6.0, "o"], [0.5, 6.0], [0.72, 0.0]], t)
	_wl_feet(p, lz, _arc(t, 0.16, 0.25, 3.0) + _arc(t, 0.52, 0.72, 1.5), kf_f([[0.0, 0.6], [0.13, 0.25], [0.25, 0.8], [dur, 0.6]], t))
	_head(p, -lean + WL_HEAD + kf_f([[0.0, 0.0], [0.13, -6.0], [0.27, -8.0, "i"], [0.45, -6.0], [dur, 0.0]], t), -0.8 * yaw, kf_f([[0.0, 0.0], [0.13, 6.0], [0.27, -8.0, "i"], [0.45, -6.0], [dur, 0.0]], t))
	# 右爪：扬到右后上方(头侧) → 一顿 → 往前下方斜着撕过去(0.24s 正好扫过正前方) → 带到肚子前 → 收回
	var cock := [Vector3(16.0, 71.5, 1.5), Vector3(1.0, -0.2, -0.8), Vector3(0.25, 0.9, -0.15), Vector3(0.1, 0.0, 1.0), 45.0]
	var cock2 := [Vector3(16.5, 72.5, 0.5), Vector3(1.0, -0.15, -0.85), Vector3(0.25, 0.95, -0.2), Vector3(0.1, 0.0, 1.0), 40.0]
	var mid := [Vector3(11.0, 69.0, 12.0), Vector3(1.0, -0.4, -0.5), Vector3(0.0, 0.5, 0.85), Vector3(-0.3, -0.5, 0.6), 50.0]
	var hit := [Vector3(5.0, 61.5, 18.0), Vector3(1.0, -0.7, -0.2), Vector3(-0.35, -0.25, 0.9), Vector3(-0.6, -0.75, 0.2), 62.0]
	var fol := [Vector3(2.0, 58.0, 15.0), Vector3(1.0, -0.8, 0.0), Vector3(-0.5, -0.6, 0.6), Vector3(-0.5, -0.6, -0.4), 66.0]
	_hand_track(p, "R", [[0.0, G_WL_BACK], [0.12, cock, "o"], [0.15, cock2], [0.198, mid, "s"], [0.24, hit, "l"], [0.29, fol, "o"],
		[0.45, fol], [dur, G_WL_BACK]], t)
	# 左爪：扬爪时往前探着瞄 → 撕下去时往胸前收
	var lreach := [Vector3(11.5, 62.5, 16.5), Vector3(1.0, -0.5, -0.5), Vector3(0.15, 0.6, 0.8), Vector3(0.0, -0.4, 1.0), 45.0]
	var lpull := [Vector3(11.0, 58.0, 9.0), Vector3(1.0, -0.4, -0.7), Vector3(0.15, 0.6, 0.8), Vector3(0.0, -0.4, 1.0), 70.0]
	_hand_track(p, "L", [[0.0, G_WL_FRONT], [0.13, lreach, "o"], [0.17, lreach], [0.27, lpull, "o"], [0.45, lpull], [dur, G_WL_FRONT]], t)
	_dr_tail(p, 0.0, 30.0, kf_f([[0.0, 0.0], [0.13, -22.0, "o"], [0.27, 30.0, "i"], [0.45, 18.0], [dur, 0.0]], t),
		kf_f([[0.0, 8.0], [0.13, 14.0], [0.27, 4.0], [dur, 8.0]], t))
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 巨蛛
const WS_DROP := 20.0
const WS_LEAN := 44.0
const WS_HK := 0.2
const WS_HEAD := -6.0                         # 头的世界俯角(负 = 仰起来往前上方看)
const WS_TILT := 16.0                         # 歪头


func _ws_feet(p, lz: float = 0.0, llift: float = 0.0, rz: float = 0.0, rlift: float = 0.0) -> void:
	legs(p, Vector3(13.5, ANKLE_Y + llift, 0.5 + lz), Vector3(-13.5, ANKLE_Y + rlift, -0.5 + rz), Lib.E(0.0, 40.0, 0.0), Lib.E(0.0, -40.0, 0.0))


## 一只"蛛腿"手(世界坐标，左手约定)：往两侧低低地张开、肘往上拱、手指朝下勾着；lift 抬起来的程度(0..1)，dz 前后
func _ws_leg(side: String, base: Vector3, lift: float, dz: float = 0.0) -> Array:
	return _wd_w(side, base + Vector3(0.5 * lift, 5.0 * lift, dz + 2.0 * lift), Vector3(0.5, 1.0, 0.1),
		Vector3(0.35, -0.9, 0.3), Vector3(-0.3, -0.2, 0.95), 40.0 - 20.0 * lift)


const WS_LEG := Vector3(22.0, 32.0, 17.0)


func idle_warden_spider(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / WD_IDLE
	var br: float = 0.5 - 0.5 * cos(2.0 * th)
	# 头时不时"咔"地一抽(歪得更狠，停住，再慢慢回来)
	var jerk: float = kf_f([[0.0, 0.0], [0.85, 0.0], [0.92, 1.0, "o"], [1.5, 1.0], [1.9, 0.0], [2.35, 0.0], [2.41, -0.7, "o"], [2.8, -0.7], [3.2, 0.0]], t)
	var lean: float = WS_LEAN - 1.5 * br
	_wd_body(p, WS_DROP - 0.5 * br, 0.0, 0.5 * sin(th), lean, WS_HK, 0.0, 0.0, 0.8)
	_ws_feet(p)
	_head(p, -lean + WS_HEAD, 5.0 * jerk, WS_TILT + 10.0 * jerk)
	var tap_l: float = _arc(t, 0.45, 0.75, 1.0) + _arc(t, 1.95, 2.2, 0.7)
	var tap_r: float = _arc(t, 1.2, 1.45, 0.8) + _arc(t, 2.65, 2.95, 1.0)
	_wd_put(p, "L", _ws_leg("L", WS_LEG + Vector3(0.0, 0.3 * br, 0.0), tap_l))
	_wd_put(p, "R", _ws_leg("R", WS_LEG + Vector3(0.0, 0.3 * br, 0.0), tap_r))
	set_lids(p, blink_k(t, 1.7))


func run_warden_spider(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t / WD_RUN, 1.0)
	var ph2: float = fposmod(2.0 * ph, 1.0)                    # 一个循环每只脚走两步
	var th2: float = TAU * ph2
	var fl: Array = foot_track(ph2, 10.5, 6.0, 0.55)
	var fr: Array = foot_track(fposmod(ph2 + 0.5, 1.0), 10.5, 6.0, 0.55)
	var lean: float = WS_LEAN + 4.0
	_wd_body(p, WS_DROP + 0.6 * cos(2.0 * th2), 1.0, 1.2 * sin(th2), lean, WS_HK, 5.0 * cos(th2), 0.0, 0.8)
	legs(p, foot_target(1.0, fl, 13.0), foot_target(-1.0, fr, 13.0), Lib.E(float(fl[2]) * 0.5, 36.0, 0), Lib.E(float(fr[2]) * 0.5, -36.0, 0))
	_head(p, -lean + WS_HEAD, -4.0 * cos(th2), WS_TILT)
	# 两只"蛛腿"和对侧的脚一起走：抬起往前点 → 往后划
	for side: String in ["L", "R"]:
		var aph: float = fposmod(ph2 + (0.5 if side == "L" else 0.0) + 0.05, 1.0)
		var ft: Array = foot_track(aph, 5.0, 1.0, 0.5)
		_wd_put(p, side, _ws_leg(side, WS_LEG + Vector3(0.0, -0.5, 0.0), float(ft[1]), float(ft[0])))
	set_lids(p, 0.0)


func attack_warden_spider(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dur := 24.0 * F
	var lean: float = kf_f([[0.0, WS_LEAN], [0.17, 16.0, "o"], [0.21, 14.0], [0.28, 52.0, "i"], [0.40, 50.0], [dur, WS_LEAN]], t)
	var drop: float = kf_f([[0.0, WS_DROP], [0.17, 15.0, "o"], [0.21, 14.5], [0.28, 21.0, "i"], [0.42, 21.0], [dur, WS_DROP]], t)
	var push: float = kf_f([[0.0, 0.0], [0.17, -3.0, "o"], [0.21, -3.5], [0.28, 6.0, "i"], [0.42, 5.5], [dur, 0.0]], t)
	var shake: float = sin(TAU * (t - 0.30) / 0.1) * kf_f([[0.0, 0.0], [0.30, 0.0], [0.33, 1.0], [0.43, 1.0], [0.5, 0.0]], t)    # 咬住甩两下
	_wd_body(p, drop, push, 0.0, lean, WS_HK, 7.0 * shake, 0.0, 0.8)
	_ws_feet(p)
	_head(p, -lean + WS_HEAD + kf_f([[0.0, 0.0], [0.17, -10.0, "o"], [0.28, 12.0, "i"], [0.42, 10.0], [dur, 0.0]], t), -5.0 * shake,
		kf_f([[0.0, WS_TILT], [0.17, 4.0], [0.28, 8.0], [0.45, 8.0], [dur, WS_TILT]], t))
	# 两手：蛛腿 → 扬到头两侧、手指勾成獠牙 → 往前下方合拢咬下去 → 咬住 → 回到蛛腿
	for side: String in ["L", "R"]:
		var leg: Array = _ws_leg(side, WS_LEG, 0.0)
		var lift: Array = _wd_c(p, side, [Vector3(18.5, 62.0, 8.0), Vector3(1.0, 0.2, -0.6), Vector3(0.3, -0.2, 0.9), Vector3(-0.9, 0.0, 0.3), 50.0])
		var fang: Array = _wd_c(p, side, [Vector3(13.5, 73.0, 7.5), Vector3(1.0, -0.3, -0.6), Vector3(-0.25, -0.35, 0.9), Vector3(-0.9, 0.0, 0.25), 72.0])
		var bite: Array = _wd_c(p, side, [Vector3(5.5, 60.0, 17.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.35, -0.6, 0.7), Vector3(-0.9, 0.1, 0.3), 82.0])
		_wd_track(p, side, [[0.0, leg], [0.08, lift, "i"], [0.17, fang, "o"], [0.21, fang], [0.28, bite, "i"], [0.43, bite], [0.6, lift], [dur, leg]], t)
	set_lids(p, 0.0)


# ---------------------------------------------------------------- 巨蟾
const WT_DROP := 30.0
const WT_LEAN := 80.0
const WT_HK := 0.25
const WT_HEAD := -4.0
const WT_HAND := Vector3(6.0, 6.5, 22.0)        # 按在地上的手腕(世界，左手)


func _wt_feet(p, lift: float = 0.0, dz: float = 0.0, pitch: float = 0.0) -> void:
	legs(p, Vector3(12.0, ANKLE_Y + lift, -2.0 + dz), Vector3(-12.0, ANKLE_Y + lift, -2.0 + dz), Lib.E(pitch, 45.0, 0.0), Lib.E(pitch, -45.0, 0.0))


## 按在地上的手(世界)：手心朝下、手指朝前略往外，肘往外后拱
func _wt_hand(side: String, at: Vector3, lift: float = 0.0) -> Array:
	return _wd_w(side, at + Vector3(0.0, lift, 0.0), Vector3(1.0, 0.3, -0.5), Vector3(0.25, -0.5 - 0.1 * lift, 0.8), Vector3(0.0, -1.0, -0.3), 14.0 + 3.0 * lift)


func idle_warden_toad(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / WD_IDLE
	var bp: float = fposmod(t / 1.6, 1.0)
	var puff: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [0.42, 1.0], [0.9, 0.0], [1.0, 0.0]], bp)
	var lean: float = WT_LEAN - 3.0 * puff
	_wd_body(p, WT_DROP - 1.0 * puff, 0.0, 0.4 * sin(th), lean, WT_HK, 0.0, 0.0, 0.3)
	_wd_puff(p, puff)
	_wt_feet(p)
	_head(p, -lean + WT_HEAD + 2.0 * puff, 4.0 * sin(th), 3.0 * sin(2.0 * th))
	_wd_put(p, "L", _wt_hand("L", WT_HAND))
	_wd_put(p, "R", _wt_hand("R", WT_HAND))
	set_lids(p, maxf(0.3, kf_f([[0.0, 0.3], [2.3, 0.3], [2.5, 1.0], [2.75, 1.0], [3.0, 0.3]], t)))       # 半闭着眼，慢慢眨一下


func run_warden_toad(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t / WD_RUN, 1.0)
	# 0.9 落地 → 蹲住(到 0.3) → 0.3 ~ 0.4 蹬地 → 0.38 ~ 0.9 腾空
	var h: float = _arc(ph, 0.38, 0.9, 13.0)
	var ext: float = kf_f([[0.0, 0.0], [0.28, 0.0], [0.4, 1.0, "o"], [0.62, 0.5], [0.85, 0.1], [0.92, 0.0], [1.0, 0.0]], ph)    # 腿蹬直
	var land: float = kf_f([[0.0, 0.7], [0.1, 1.0], [0.3, 0.3], [0.38, 0.0], [0.88, 0.0], [0.95, 0.5], [1.0, 0.7]], ph)       # 落地压缩
	var sp: float = fposmod(ph - 0.9, 1.0)                        # 0 = 落地
	# 脚：着地时跟着地面往后滑，腾空时收起来往前带(滑的距离比真实的地速短一点：腿再往后伸就够不着了)
	var fz: float = lerpf(9.0, -9.0, sp / 0.48) if sp < 0.48 else lerpf(-9.0, 9.0, Lib.smoother((sp - 0.48) / 0.52))
	var tuck: float = _arc(ph, 0.45, 0.9, 6.0)                    # 空中收腿
	p.move("Root", Vector3(0.0, h, 0.0))
	var lean: float = WT_LEAN - 28.0 * ext + 4.0 * land
	_wd_body(p, WT_DROP - 13.0 * ext + 1.5 * land, 1.0 + 2.0 * ext, 0.0, lean, WT_HK, 0.0, 0.0, 0.3)
	_wt_feet(p, h + tuck, fz, -20.0 * ext + 10.0 * tuck / 6.0)
	_head(p, -lean + WT_HEAD - 6.0 * ext, 0.0, 0.0)
	# 手：落地后按在地上往后滑一点；蹬地时离地，空中跟着身子往前下方伸着(跟胸腔走：身子比手够得着的地方高得多)，比脚先着地
	var hz: float = lerpf(2.0, -7.0, sp / 0.45) if sp < 0.45 else lerpf(-1.0, 2.0, Lib.smoother((sp - 0.45) / 0.52))
	var air_w: float = kf_f([[0.0, 0.0], [0.27, 0.0], [0.4, 1.0], [0.76, 1.0], [0.87, 0.0], [1.0, 0.0]], ph)
	for side: String in ["L", "R"]:
		var g: Array = _wt_hand(side, WT_HAND + Vector3(0.0, 0.0, hz))
		g[0] = (g[0] as Vector3) + Vector3(0.0, h, 0.0)
		var reach: Array = _wd_c(p, side, [Vector3(9.0, 63.0, 18.5), Vector3(1.0, 0.2, -0.5), Vector3(0.2, -0.2, 1.0), Vector3(0.0, -1.0, 0.0), 22.0])
		_wd_put(p, side, _wd_mix(g, reach, air_w))
	set_lids(p, 0.3 * (1.0 - ext))


func attack_warden_toad(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dur := 30.0 * F
	var lean: float = kf_f([[0.0, WT_LEAN], [0.22, 56.0, "o"], [0.35, 88.0, "i"], [0.45, 88.0], [0.55, 66.0, "o"], [dur, WT_LEAN]], t)
	var push: float = kf_f([[0.0, 0.0], [0.22, -5.0, "o"], [0.35, 9.0, "i"], [0.45, 9.0], [0.55, -2.0, "o"], [dur, 0.0]], t)
	var thrust: float = kf_f([[0.0, 0.0], [0.24, 0.0], [0.35, 1.0, "i"], [0.45, 1.0], [0.53, -0.3, "o"], [0.7, 0.0]], t)    # 胸口(连头)往前一探
	var drop: float = kf_f([[0.0, WT_DROP], [0.22, WT_DROP - 3.0, "o"], [0.35, WT_DROP - 1.0, "i"], [0.55, WT_DROP + 0.5], [dur, WT_DROP]], t)
	var puff: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [0.33, 1.0], [0.37, 0.2, "i"], [0.6, 0.0], [dur, 0.0]], t)
	_wd_body(p, drop, push, 0.0, lean, WT_HK, 0.0, 0.0, kf_f([[0.0, 0.3], [0.22, 0.8], [0.35, 0.2], [dur, 0.3]], t))
	_wd_puff(p, puff)
	p.move("Chest", Vector3(0.0, 0.6, 2.2) * thrust)
	_wt_feet(p)
	_head(p, -lean + WT_HEAD + kf_f([[0.0, 0.0], [0.22, -20.0, "o"], [0.35, 16.0, "i"], [0.45, 16.0], [0.55, -6.0, "o"], [dur, 0.0]], t), 0.0, 0.0)
	# 两手：蓄力时按着地 → 抬起来 → 往前一拍(出手) → 按住 → 滑回原处
	var hz: float = kf_f([[0.0, 0.0], [0.24, 0.0], [0.35, 8.0, "i"], [0.45, 8.0], [0.55, 2.5, "o"], [0.75, 0.0], [dur, 0.0]], t)
	var hl: float = _arc(t, 0.22, 0.35, 4.0) + _arc(t, 0.52, 0.75, 2.0)
	for side: String in ["L", "R"]:
		_wd_put(p, side, _wt_hand(side, WT_HAND + Vector3(0.0, 0.0, hz), hl))
	set_lids(p, kf_f([[0.0, 0.3], [0.22, 0.0], [0.35, 0.0], [0.42, 0.6], [0.6, 0.3], [dur, 0.3]], t))


# ---------------------------------------------------------------- 变身(24f)：低伏 → 后仰弓背、两臂张开、仰头吼 → 落成低伏
func shift_warden(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dur := 24.0 * F
	var roar: float = kf_f([[0.0, 0.0], [0.27, 1.0, "o"], [0.45, 1.0], [0.68, 0.0, "s"], [dur, 0.0]], t)
	var end: float = kf_f([[0.0, 0.0], [0.45, 0.0], [0.68, 1.0, "s"], [dur, 1.0]], t)
	var tremor: float = sin(TAU * t / (4.0 * F)) * kf_f([[0.0, 0.0], [0.25, 0.0], [0.3, 1.0], [0.43, 1.0], [0.48, 0.0]], t)
	var lean: float = lerpf(lerpf(34.0, WL_LEAN, end), -8.0, roar)
	var drop: float = lerpf(lerpf(12.0, WL_DROP, end), 1.0, roar)
	_wd_body(p, drop, lerpf(0.0, WL_PUSH, end) - 1.5 * roar, 0.0, lean + 0.8 * tremor, lerpf(0.4, 0.2, roar), 0.0, 0.0, lerpf(0.3, 0.5, end) + 0.6 * roar)
	legs(p, Vector3(8.5, ANKLE_Y, 1.0), Vector3(-8.5, ANKLE_Y, -2.0), Lib.E(0.0, 16.0, 0.0), Lib.E(0.0, -16.0, 0.0))
	_head(p, -lean + lerpf(lerpf(14.0, WL_HEAD, end), -12.0, roar) + 1.2 * tremor, 0.0, 0.0)
	var low := [Vector3(9.0, 49.0, 10.0), Vector3(1.0, -0.3, -0.7), Vector3(0.1, -0.9, 0.4), Vector3(-0.6, 0.0, 0.8), 30.0]
	var via := [Vector3(19.0, 58.0, 8.0), Vector3(0.8, -0.5, -0.6), Vector3(0.6, 0.2, 0.75), Vector3(0.0, -0.5, 1.0), 25.0]
	var wide := [Vector3(26.5, 69.0, 3.5), Vector3(0.2, -0.8, -0.6), Vector3(1.0, 0.25, 0.1), Vector3(0.0, 0.0, 1.0), 30.0]
	var wide2 := [Vector3(27.0, 70.0, 2.5), Vector3(0.2, -0.8, -0.6), Vector3(1.0, 0.3, 0.05), Vector3(0.0, 0.0, 1.0), 40.0]
	var via2 := [Vector3(19.5, 63.0, 11.0), Vector3(0.9, -0.5, -0.5), Vector3(0.4, 0.5, 0.75), Vector3(0.0, -0.4, 1.0), 45.0]
	_hand_track(p, "L", [[0.0, low], [0.12, via, "i"], [0.27, wide, "o"], [0.45, wide2], [0.57, via2, "i"], [0.70, G_WL_FRONT, "o"], [dur, G_WL_FRONT]], t)
	_hand_track(p, "R", [[0.0, low], [0.12, via, "i"], [0.27, wide, "o"], [0.45, wide2], [0.57, via2, "i"], [0.70, G_WL_BACK, "o"], [dur, G_WL_BACK]], t)
	_dr_tail(p, TAU * t / 0.4, 14.0 * roar, kf_f([[0.0, 0.0], [0.27, -14.0], [0.45, 16.0], [0.7, 0.0]], t), 4.0 + 22.0 * roar)
	set_lids(p, 0.55 * roar)


# ---------------------------------------------------------------- 小动作(4.0s)：猫式伸懒腰 → 挠耳朵 → 甩头、甩尾巴
func fidget_warden(t: float, p) -> void:
	p.reset()
	_stow(p)
	var st: float = kf_f([[0.0, 0.0], [0.55, 1.0, "o"], [1.3, 1.0], [1.85, 0.0]], t)             # 伸懒腰
	var arch: float = kf_f([[0.0, 0.0], [1.3, 0.0], [1.55, 1.0], [1.85, 0.0]], t)               # 拱一下背
	var scr: float = kf_f([[0.0, 0.0], [1.95, 0.0], [2.35, 1.0, "o"], [3.1, 1.0], [3.5, 0.0]], t)   # 挠耳朵(头歪过去)
	var shk: float = sin(TAU * (t - 3.15) / 0.2) * kf_f([[0.0, 0.0], [3.1, 0.0], [3.2, 1.0], [3.45, 1.0], [3.6, 0.0]], t)   # 甩头
	var lean: float = 44.0 * st + 10.0 * arch
	_wd_body(p, 0.4 * st + 2.0 * arch, -4.0 * st - 1.0 * arch, 0.6 * sin(t * 1.6) * (1.0 - st), lean, lerpf(0.75, 0.3, arch / maxf(st + arch, 0.001)),
		-4.0 * scr, -5.0 * scr, 0.4 * arch)
	if arch > 0.0:
		p.radd("Spine", 8.0 * arch, 0.0, 0.0)          # 拱背：腰往上拱
	legs(p, Vector3(6.5, ANKLE_Y + 1.8 * st, -0.5), Vector3(-6.5, ANKLE_Y + 1.8 * st, -0.5), Lib.E(18.0 * st, 6.0, 0.0), Lib.E(18.0 * st, -6.0, 0.0), -14.0 * st, -14.0 * st)
	_head(p, -lean * 0.9 - 8.0 * st + 22.0 * arch - 3.0 * scr, -10.0 * scr + 14.0 * shk, 15.0 * scr + 4.0 * shk)
	# 两手：往前伸直(手心朝下、手指张开) → 右手挠耳朵、左手叉腰 → 放下
	var reach := [Vector3(9.0, 63.5, 18.5), Vector3(0.9, -0.6, -0.3), Vector3(0.05, 0.1, 1.0), Vector3(0.0, -1.0, 0.1), 0.0]
	var mid := [Vector3(15.5, 63.0, 9.5), Vector3(1.0, -0.4, -0.4), Vector3(0.1, 0.8, 0.5), Vector3(-0.6, 0.0, 0.8), 30.0]
	var ear: Array = [Vector3(18.5, 81.0, -2.0), Vector3(1.0, -0.3, -0.4), Vector3(-0.3, 1.0, -0.1), Vector3(-1.0, 0.0, 0.1), 45.0]
	var scratch: float = sin(TAU * (t - 2.3) / 0.2) * kf_f([[0.0, 0.0], [2.3, 0.0], [2.4, 1.0], [3.0, 1.0], [3.1, 0.0]], t)
	ear[0] = (ear[0] as Vector3) + Vector3(0.0, 1.2 * scratch, 0.6 * scratch)
	ear[4] = 45.0 + 25.0 * scratch
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.55, reach], [1.3, reach], [1.75, G_RELAX], [2.05, mid], [2.35, ear], [3.1, ear], [3.35, mid], [3.8, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.55, reach], [1.3, reach], [1.75, G_RELAX], [2.1, G_HIP], [3.3, G_HIP], [3.8, G_RELAX]], t)
	# 尾巴：伸懒腰时高高翘起、挠耳朵时慢慢摇，最后大大地一甩
	var swish: float = kf_f([[0.0, 0.0], [3.2, 0.0], [3.4, 40.0, "o"], [3.62, -30.0], [3.82, 8.0], [4.0, 0.0]], t)
	var env: float = kf_f([[0.0, 0.0], [0.4, 1.0], [3.5, 1.0], [4.0, 0.0]], t)
	_dr_tail(p, TAU * t / 1.2, 16.0 * env, swish, 22.0 * st + 6.0 * scr)
	set_lids(p, maxf(kf_f([[0.0, 0.0], [0.4, 0.0], [0.6, 1.0], [1.5, 1.0], [1.75, 0.0], [2.2, 0.0], [2.4, 0.7], [3.05, 0.7], [3.25, 0.0]], t), blink_k(t, 3.7)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：两爪举在头侧仰头吼 → 原地蹦两下，尾巴快快地摇
func victory_warden(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fmod(t, 2.4)
	var roar: float = kf_f([[0.0, 1.0], [0.85, 1.0], [1.1, 0.0], [2.15, 0.0], [2.4, 1.0]], ph)
	var hop: float = _arc(ph, 1.1, 1.6, 4.0) + _arc(ph, 1.6, 2.1, 4.0)
	var trem: float = sin(TAU * ph / (4.0 * F)) * kf_f([[0.0, 0.0], [0.1, 1.0], [0.75, 1.0], [0.9, 0.0]], ph)
	var tilt: float = sin(TAU * (ph - 1.1) / 1.0) * (1.0 - roar)
	_base(p, 0.0, hop - 0.6 * (1.0 - roar), 0.0, -5.0 * roar - 2.0 * (1.0 - roar) + 0.6 * trem, 5.0 * tilt, 0.0, 7.5, 0.0, 0.0)
	legs(p, Vector3(7.5, ANKLE_Y + hop, -0.5), Vector3(-7.5, ANKLE_Y + hop, -0.5), Lib.E(0.0, 10.0, 0.0), Lib.E(0.0, -10.0, 0.0))
	p.radd("Chest", -3.0 * roar, 0.0, 0.0)                      # 挺胸
	_head(p, -8.0 * roar - 3.0 * (1.0 - roar) + 1.0 * trem, 0.0, 9.0 * tilt)
	for side: String in ["L", "R"]:
		var g := [Vector3(18.5, 77.0 + 1.0 * roar + 0.3 * trem, 6.0) + Vector3(0.0, 0.5 * hop, 0.0), Vector3(1.0, -0.35, -0.5), Vector3(0.1, 1.0, 0.25),
			Vector3(-0.2, 0.0, 1.0), 50.0 + 12.0 * roar]
		_hand_mix(p, side, g, g, 0.0)
	_dr_tail(p, TAU * ph / 0.6, 26.0, 18.0 * sin(TAU * ph / 0.6), 14.0)
	if ph > 1.45 and ph < 1.95:
		_wink(p, "L")
	else:
		set_lids(p, 0.55 * roar)


# =============================================================== 导向节点(psychic)：金发猫耳、藏青水手服的雷电魔导士(2026-10-07)
## 模型 tools/chars/psychic.gd(女性款；猫耳是头上的刚体、没有耳朵骨 —— "耳朵一抖"靠头一抽表现；脸侧两缕鬓发挂 SideLock 链，
## 两侧 + 身后的三片长裙片挂 Cape 链)。按角色卡：两脚大开、一只手往前伸直五指张开放电、另一只手把魔导书托在身侧。
## 普攻 = 引雷【吟唱 3】：前摇结束后吟唱(和弓的拉弓同一套)：BattleView 放一次 chant_psychic_<大类>，再循环 chant_psychic_<大类>_hold，
## 放出去时 UnitView.resume_attack 从普攻动画的出手时刻接着放完。她能拿四个大类：法器(基础；书在右手 = Bow 骨) / 步枪 / 手弩 / 双枪：
##   chant_psychic_<大类>(10f)：首帧 = 普攻动画在出手时刻(PSY_WINDUP)的姿势 —— _pose_mix 从它混到 hold 的首帧(权重先快后慢)，
##     电流(细颤 / 鬓发 / 裙片)跟着慢慢长出来；末帧 = hold 的首帧(细颤、脉冲用同一条周期信号)
##   chant_psychic_<大类>_hold(40f 循环)：引雷 ——
##     法器 = 左手往左前方伸直、手指朝上张开(掌心朝着目标)，右手把书托到身体右侧，上身左肩向前、往前探；
##     手弩 = 手弩伸直指着目标(= 角色卡放电的那只手)，空着的左手往左侧平伸、掌心朝上托着一团电(稍稍偏后)；
##     双枪 = 两把枪往前伸直、往两边分开一点、枪身往里斜；步枪 = 抵肩举高一点、贴腮瞄准，身子压进枪里。三种都比出手时站得更开、蹲得更低。
##     "电流"：细颤(9 ~ 13 次/秒的正弦叠加，主要在伸出去的手 / 枪上，上身也跟着抖) + 每圈两次脉冲：4 帧猛地往前一顶 ——
##     手 / 书 / 枪 / 上身扭转往普攻出手的姿势收一截(大的一下：法器收 55%、其余 40 ~ 50%；小的一下是它的 0.55 倍)、手指一张、肩一耸、膝一沉、鬓发和裙片被往外吹开，
##     再用半圈慢慢松回引雷姿势；吟唱时一直眯着眼。
##   时长对齐【吟唱 3】：10f + 2 × 40f = 3.0s —— 吟唱不被打断时，出手正好落在 hold 的循环接缝上 = 大脉冲的顶点(离普攻出手姿势最近的一帧)，
##   resume_attack 的 0.04s 交叉淡化像是"顶到头、放出去"。
## 小动作(收起武器，4.0s)：抬起右手搓搓指尖(静电在攒，低头看) → "啪"地被自己电了一下：整个人一缩一跳、两臂一张、耸肩、闭眼，鬓发炸开 →
##   甩甩头、甩甩两只手 → 左手叉腰，得意地把右手举到脸旁，指尖往外一弹把火花弹走(歪头、眨左眼) → 放下
## 胜利(收起武器，2.4s 循环)：右手举到头侧、张开手掌"引雷"，左手叉腰 —— 雷落下来的那一下全身一挺、手一颤、鬓发炸开、眯眼，
##   接着原地小跳一下 + 眨左眼，落地后微微下蹲等下一道雷
const PSY_TABLE := {"fidget_psychic": [4.0, false], "victory_psychic": [2.4, true]}
const PSY_CLASSES := ["focus", "rifle", "crossbow", "pistols"]
const PSY_WINDUP := {"focus": 0.36, "rifle": 0.10, "crossbow": 0.20, "pistols": 0.12}      # = GC.WEAPON_CLASSES 的 windup(普攻出手时刻)
const PSY_IN := 10.0 * F             # chant_psychic_<大类>
const PSY_HOLD := 40.0 * F           # chant_psychic_<大类>_hold 的循环周期(细颤 / 脉冲信号的周期)
## 伸出去放电的那只手："停"的手势 —— 手指朝上、往外前方张开，掌心朝着目标(左手约定的胸腔局部方向，_gq 的参数)
const PSY_PALM_F := Vector3(0.35, 0.75, 0.55)
const PSY_PALM_P := Vector3(0.1, 0.25, 1.0)


func psychic_table(t: Dictionary) -> void:
	for c: String in PSY_CLASSES:
		t["chant_psychic_" + c] = {"dur": PSY_IN, "loop": false, "fn": Callable(self, "_psy_chant").bind(c)}
		t["chant_psychic_" + c + "_hold"] = {"dur": PSY_HOLD, "loop": true, "fn": Callable(self, "_psy_chant_hold").bind(c)}
	for nm: String in PSY_TABLE.keys():
		t[nm] = {"dur": float(PSY_TABLE[nm][0]), "loop": bool(PSY_TABLE[nm][1]), "fn": Callable(self, nm)}


## 电流信号：tc = 信号时刻(hold 的时间；起手动作里 = t - PSY_IN，末帧对上 hold 的 0)；周期 PSY_HOLD 内都是整数个周期(循环无缝)。
## 返回 [细颤位移(体素), 细颤转角(度), 脉冲 0..1, 上身的小抖动(度)]。
## 脉冲每圈两次，顶点正好在 0(大的一下，= 循环接缝 = 吟唱满 3 秒出手的那一刻)和 PSY_HOLD / 2(小的一下)：
## 4 帧猛地往前一顶(往普攻出手的姿势收一截)，再用半圈慢慢松回引雷姿势
const PSY_PULSE := [1.0, 0.55]


static func _psy_sig(tc: float) -> Array:
	var w: float = TAU * tc / PSY_HOLD
	var jit := Vector3(0.3 * sin(12.0 * w + 0.4) + 0.15 * sin(17.0 * w + 2.1),
		0.28 * sin(15.0 * w + 1.3) + 0.12 * sin(11.0 * w),
		0.2 * sin(13.0 * w + 0.8) + 0.1 * sin(16.0 * w + 2.6))
	var rot := Vector3(3.0 * sin(14.0 * w + 0.2) + 1.5 * sin(9.0 * w + 1.7), 2.5 * sin(11.0 * w + 2.4), 3.0 * sin(16.0 * w + 0.9) + 1.2 * sin(12.0 * w))
	var hu: float = fposmod(tc / (PSY_HOLD * 0.5), 2.0)
	var h: int = mini(int(hu), 1)                                      # 0 = 前半圈(从大脉冲松下来)，1 = 后半圈
	var u: float = hu - float(h)
	var surge: float = exp(-u * 4.5) * (1.0 - Lib.smooth((u - 0.5) / 0.3)) * float(PSY_PULSE[h]) + Lib.smooth((u - 0.8) / 0.2) * float(PSY_PULSE[1 - h])
	var body: float = 0.6 * sin(10.0 * w + 1.0) + 0.35 * sin(6.0 * w)
	return [jit, rot, surge, body]


## 起手(10f)：从普攻出手时刻的姿势混到 hold 的首帧(权重先快后慢)；电流慢慢长出来
func _psy_chant(t: float, p, cls: String) -> void:
	var u: float = clampf(t / PSY_IN, 0.0, 1.0)
	var w: float = 1.0 - pow(1.0 - u, 2.0)
	var atk := Callable(self, "attack_" + cls)
	var wu: float = PSY_WINDUP[cls]
	_pose_mix(p, func(pp) -> void: atk.call(wu, pp), func(pp) -> void: _psy_channel(pp, cls, t - PSY_IN, Lib.smooth(u)), w)


func _psy_chant_hold(t: float, p, cls: String) -> void:
	_psy_channel(p, cls, t, 1.0)


## 引雷姿势：tc = 电流信号时刻，env = 电流强度(0..1)。
## 每个大类两组数：引雷(脉冲 = 0)和普攻出手时刻(PSY_WINDUP 那一帧)的同一个量；脉冲时往出手姿势收 kp(手 / 枪 / 上身扭转)
func _psy_channel(p, cls: String, tc: float, env: float) -> void:
	p.reset()
	var sg: Array = _psy_sig(tc)
	var jit: Vector3 = (sg[0] as Vector3) * env
	var jr: Vector3 = (sg[1] as Vector3) * env
	var s: float = float(sg[2]) * env
	var body: float = float(sg[3]) * env
	p.r("Shoulder_L", 0.0, 0.0, 4.0 * s)          # 脉冲：肩一耸(先摆肩，再解手臂 IK)
	p.r("Shoulder_R", 0.0, 0.0, -4.0 * s)
	match cls:
		"focus":
			# 左手往左前方伸直放电，右手把书托到身体右侧；左肩向前
			var kp: float = 0.55 * s
			_twist(p, lerpf(-14.0, 10.0, kp), lerpf(7.0, 11.0, kp) + body, lerpf(1.5, 3.0, kp), 3.5 + 0.5 * s, 0.8)
			p.radd("Head", -3.0 + 0.15 * jr.x, 0.15 * jr.y, 0.0)
			_feet(p, 10.0, 3.5, 0.0, -2.5, 0.0, 14.0, -24.0)
			var cq: Quaternion = _chest_q(p)
			var book: Vector3 = Vector3(-18.0, 63.5, 8.0).lerp(Vector3(-6.0, 60.5, 19.0), kp) + jit * 0.3
			var aim: Vector3 = Vector3(0.15, 0.22, 1.0).lerp(Vector3(0.05, 0.08, 1.0), kp)
			var upv: Vector3 = Vector3(-0.5, 1.0, -0.25).lerp(Vector3(0.0, 1.0, 0.1), kp)
			hold_bow(p, follow(p, "Chest", book), cq * grot(aim, upv), Vector3(-1.0, -0.5, -0.5))
			fist_r(p, 70.0)
			_psy_thrust(p, Vector3(22.5, 67.5, 13.5).lerp(Vector3(6.0, 61.5, 17.5), kp) + Vector3(0.0, 0.0, 1.0) * s, jit, jr, s, cq, kp)
		"crossbow":
			# 手弩照样伸直指着目标(= 角色卡放电的那只手)；空着的左手往左侧平伸、掌心朝上托着一团电
			# (稍稍偏后，和普攻时往左后方展开保持平衡的那只手离得不远)
			var kp2: float = 0.4 * s
			_twist(p, lerpf(8.0, 16.0, kp2), lerpf(6.0, 3.0, kp2) + body, 1.5, lerpf(3.5, 1.0, kp2) + 0.5 * s, 0.9)
			p.radd("Head", 3.0 + 0.15 * jr.x, 0.15 * jr.y, -4.0)
			_feet(p, 10.0, 3.5, 0.0, -2.5, 0.0, 16.0, -24.0)
			var cq2: Quaternion = _chest_q(p)
			hold_bow(p, follow(p, "Chest", Vector3(-8.0, 63.5, 19.5).lerp(Vector3(-8.0, 63.0, 18.0), kp2) + jit * 0.3),
				grot(Vector3(0.02 + 0.004 * jr.y, 0.02 + 0.004 * jr.x, 1.0), Vector3(0.0, 1.0, 0.0)), Vector3(-1.0, -0.6, -0.2))
			fist_r(p, 82.0)
			_psy_orb(p, Vector3(27.0, 62.5, 1.5).lerp(Vector3(17.0, 56.0, -6.0), kp2) + jit, jr, s, cq2)
		"pistols":
			# 两把枪往前伸直、往两边分开一点、枪身往里斜，压低重心
			var kp3: float = 0.5 * s
			_twist(p, 0.0, lerpf(10.0, 4.0, kp3) + body, 1.0, lerpf(4.0, 2.0, kp3) + 0.5 * s, 0.9)
			p.radd("Head", -3.0 + 0.15 * jr.x, 0.15 * jr.y, 0.0)
			_feet(p, 10.0, 2.5, 0.0, -1.5, 0.0, 18.0, -18.0)
			var gr: Vector3 = Vector3(-10.0, 64.5, 19.5).lerp(Vector3(-7.5, 62.0, 18.0), kp3) + jit
			var gl: Vector3 = Vector3(10.0, 64.5, 19.5).lerp(Vector3(7.5, 62.0, 18.0), kp3) + Vector3(jit.z, -jit.x, jit.y)
			var k: float = 0.006
			var ar := Vector3(0.0 + k * jr.y, 0.03 + k * jr.x, 1.0)
			var al := Vector3(0.0 - k * jr.z, 0.03 + k * jr.y, 1.0)
			var cq3: Quaternion = _chest_q(p)
			var cant: float = lerpf(0.55, 0.35, kp3)
			hold_bow(p, follow(p, "Chest", gr), cq3 * grot(ar, Vector3(cant, 1.0, 0.0)), Vector3(-1.0, -0.6, -0.2))
			fist_r(p, 82.0)
			hold_left(p, follow(p, "Chest", gl), cq3 * mirror_q(grot(mx(al), mx(Vector3(-cant, 1.0, 0.0)))), Vector3(1.0, -0.6, -0.2))
			fist_l(p, 82.0)
		"rifle":
			# 抵肩举高一点、贴腮瞄准，身子压进枪里、膝盖再弯一点
			var kp4: float = 0.5 * s
			_twist(p, -26.0, lerpf(7.0, 2.0, kp4) + body, 0.5, lerpf(4.0, 1.0, kp4) + 0.5 * s, 0.9)
			p.radd("Head", lerpf(6.0, 0.0, kp4) + 0.1 * jr.x, lerpf(-3.0, 0.0, kp4), lerpf(4.0, 0.0, kp4))
			_stance_feet(p, 9.5, 4.0)
			var k2: float = 0.005
			_hold_rifle(p, RIFLE_AIM_GRIP + Vector3(0.0, 1.2, 1.0).lerp(Vector3.ZERO, kp4) + jit * 0.6,
				Vector3(k2 * jr.y, lerpf(0.05, 0.0, kp4) + k2 * jr.x, 1.0), Vector3(0.01 * jr.z, 1.0, 0.0), lerpf(-15.0, -14.0, kp4))
	_psy_static(p, env, s, jr)
	set_lids(p, 0.22 * env)


## 往前伸直、五指张开放电的左手(at = 胸腔局部的手腕位置)
## kp = 往法器普攻出手时左手的样子收多少(肘的朝向和它一样，手的朝向往它转)
func _psy_thrust(p, at: Vector3, jit: Vector3, jr: Vector3, s: float, cq: Quaternion, kp: float) -> void:
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", at + jit), Vector3(0.7, -0.5, -0.6))
	var q: Quaternion = _gq("L", PSY_PALM_F, PSY_PALM_P).slerp(Lib.E(-80.0, 10.0, 0.0), kp)
	p.set_grot("Hand_L", cq * q * Lib.E(jr.x, jr.y, jr.z))
	p.r("Fingers_L", 10.0 + 10.0 * s + 2.0 * jr.z, 0, 0)
	p.r("Thumb_L", 16.0 + 8.0 * s, 0, 0)


## 空着的手往身侧平伸，掌心朝上、五指张开微微拢着，像托着一团电(at = 胸腔局部的手腕位置；肘的朝向和手弩普攻时的左手一样)
func _psy_orb(p, at: Vector3, jr: Vector3, s: float, cq: Quaternion) -> void:
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", at), Vector3(0.6, -0.4, -0.8))
	p.set_grot("Hand_L", cq * _gq("L", Vector3(0.9, 0.15, 0.3), Vector3(0.0, 1.0, 0.0)) * Lib.E(jr.x, jr.y, jr.z))
	p.r("Fingers_L", -18.0 - 10.0 * s + 2.0 * jr.z, 0, 0)
	p.r("Thumb_L", 12.0 - 8.0 * s, 0, 0)


## 静电：鬓发往外飘起来、裙片被往外后方吹开(弹簧链以这里给的角度为"静止方向")
func _psy_static(p, env: float, s: float, jr: Vector3) -> void:
	var lift: float = env * (16.0 + 22.0 * s) + 0.5 * jr.z
	p.r("SideLock_L1", -6.0 * env, 0.0, lift)
	p.r("SideLock_R1", -6.0 * env, 0.0, -lift)
	var fl: float = env * (5.0 + 9.0 * s) + 0.3 * jr.y
	p.r("CapeC1", fl, 0.0, 0.0)
	p.r("Cape_L1", fl * 0.6, 0.0, fl)
	p.r("Cape_R1", fl * 0.6, 0.0, -fl)


# ---------------------------------------------------------------- 小动作(4.0s)：搓指尖 → 被电一下(缩、跳、闭眼) → 甩头甩手 → 弹走火花 + 眨眼
func fidget_psychic(t: float, p) -> void:
	p.reset()
	_stow(p)
	var zap: float = kf_f([[0.0, 0.0], [1.05, 0.0], [1.13, 1.0, "o"], [1.45, 0.25], [1.9, 0.0]], t)       # 被电的一缩
	var hop: float = _arc(t, 1.06, 1.32, 2.6)
	var look: float = kf_f([[0.0, 0.0], [0.45, 1.0], [1.05, 1.0], [1.3, 0.0]], t)                           # 低头看指尖
	var shake: float = kf_f([[0.0, 0.0], [1.4, 0.0], [1.55, 1.0], [2.15, 1.0], [2.4, 0.0]], t)
	var proud: float = kf_f([[0.0, 0.0], [2.35, 0.0], [2.7, 1.0], [3.45, 1.0], [3.95, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [2.85, 0.0], [2.93, 1.0, "o"], [3.3, 1.0], [3.6, 0.0]], t)
	var hs: float = sin(TAU * (t - 1.5) * 3.4) * shake                                                      # 甩头
	var twitch: float = _arc(t, 0.5, 0.62, 1.0) + _arc(t, 3.1, 3.22, 1.0)                                  # 猫似的耳朵一抖 → 头一抽
	_base(p, 0.4 * sin(t * 1.7) + 1.2 * proud, hop - 1.2 * zap, -6.0 * look + 4.0 * proud, 4.0 * look - 7.0 * zap + 2.0 * shake,
		-2.0 * proud + 2.0 * hs, 0.0, 6.5 + 0.8 * zap, -0.5 * proud, 0.0)
	var sp: float = 6.5 + 0.8 * zap
	var ld: float = -0.5 * proud
	legs(p, Vector3(sp, ANKLE_Y + hop, -0.5 + ld), Vector3(-sp, ANKLE_Y + hop, -0.5 - ld), Lib.E(0, 6, 0), Lib.E(0, -6, 0))
	p.r("Shoulder_L", 0.0, 0.0, 12.0 * zap)
	p.r("Shoulder_R", 0.0, 0.0, -12.0 * zap)
	_head(p, 18.0 * look - 9.0 * zap + 4.0 * shake * 0.3, -14.0 * look + 20.0 * hs - 6.0 * proud, 5.0 * twitch + 10.0 * proud - 4.0 * zap)
	# 右手：抬到胸前看指尖(搓) → 被电得往外一甩 → 甩手 → 举到脸旁 → 指尖往外一弹 → 放下
	var rub := [Vector3(7.0, 57.5, 12.5), Vector3(1.0, -0.6, -0.4), Vector3(0.05, 0.75, 0.6), Vector3(0.1, -0.8, 0.5), 45.0 + 15.0 * sin(t * 30.0)]
	var jolt := [Vector3(18.5, 62.0, 6.0), Vector3(0.6, -0.6, -0.6), Vector3(0.7, 0.6, 0.2), Vector3(0.0, -0.4, 1.0), 4.0]
	var flap_r := [Vector3(13.0, 52.0, 9.0) + Vector3(0.0, 1.2 * sin(TAU * t * 6.0), 0.0), Vector3(0.7, -0.4, -0.6),
		Vector3(0.3, -0.7 + 0.5 * sin(TAU * t * 6.0), 0.65), Vector3(0.0, -1.0, 0.0), 12.0]
	var cheek := [Vector3(14.0, 74.0, 9.5), Vector3(1.0, -0.4, -0.4), Vector3(0.1, 1.0, 0.3), Vector3(-0.5, 0.0, 1.0), 62.0]
	var flicked := [Vector3(20.0, 73.0, 11.0), Vector3(1.0, -0.4, -0.4), Vector3(0.75, 0.55, 0.4), Vector3(0.1, -0.2, 1.0), 0.0]
	var flap_l := [Vector3(13.0, 52.0, 9.0) + Vector3(0.0, -1.2 * sin(TAU * t * 6.0), 0.0), Vector3(0.7, -0.4, -0.6),
		Vector3(0.3, -0.7 - 0.5 * sin(TAU * t * 6.0), 0.65), Vector3(0.0, -1.0, 0.0), 12.0]
	var up_l := [Vector3(17.5, 60.0, 5.5), Vector3(0.6, -0.6, -0.6), Vector3(0.6, 0.4, 0.4), Vector3(0.0, -0.6, 1.0), 6.0]
	var r_keys := [[0.0, G_RELAX], [0.45, rub], [1.05, rub], [1.15, jolt], [1.4, jolt], [1.55, flap_r], [2.15, flap_r], [2.7, cheek],
		[2.85, cheek]]
	if t < 2.85:
		_hand_keys(p, "R", r_keys, t)
	elif t < 3.3:
		_hand_mix(p, "R", cheek, flicked, flick)
	else:
		_hand_mix(p, "R", flicked, G_RELAX, Lib.smooth((t - 3.3) / 0.65))
	if t < 2.15:
		_hand_keys(p, "L", [[0.0, G_RELAX], [1.05, G_RELAX], [1.15, up_l], [1.4, up_l], [1.55, flap_l], [2.15, flap_l]], t)
	else:
		_hand_keys(p, "L", [[2.15, flap_l], [2.6, G_HIP], [3.45, G_HIP], [3.95, G_RELAX]], t)
	# 被电那一下鬓发炸开，慢慢落回去
	var frizz: float = kf_f([[0.0, 0.0], [1.05, 0.0], [1.1, 1.0, "o"], [1.8, 0.35], [2.6, 0.0]], t)
	p.r("SideLock_L1", -8.0 * frizz, 0.0, 45.0 * frizz)
	p.r("SideLock_R1", -8.0 * frizz, 0.0, -45.0 * frizz)
	p.r("Cape_L1", 6.0 * frizz, 0.0, 10.0 * frizz)
	p.r("Cape_R1", 6.0 * frizz, 0.0, -10.0 * frizz)
	if t > 2.95 and t < 3.45:
		_wink(p, "L")
	else:
		set_lids(p, maxf(maxf(kf_f([[0.0, 0.0], [1.05, 0.0], [1.08, 1.0], [1.5, 1.0], [1.62, 0.0]], t), 0.3 * look), blink_k(t, 2.45)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：右手举到头侧引雷、左手叉腰 → 雷落下一挺 → 小跳 + 眨左眼
func victory_psychic(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var strike: float = kf_f([[0.0, 1.0], [0.08, 0.85], [0.6, 0.0], [2.4, 0.0]], ph) + kf_f([[0.0, 0.0], [2.32, 0.0], [2.4, 1.0, "i"]], ph)
	var crouch: float = kf_f([[0.0, 0.0], [1.95, 0.0], [2.3, 1.0], [2.4, 0.0, "i"]], ph)                 # 下一道雷之前微微蹲下等
	var hop: float = _arc(ph, 1.1, 1.5, 3.4)
	var trem: float = sin(TAU * ph / (3.0 * F)) * strike
	var th: float = TAU * ph / 2.4
	_base(p, 1.4, hop - 1.0 * crouch + 0.6 * strike, 4.0, -5.0 * strike - 2.0 + 2.5 * crouch, -4.0, 0.0, 7.0, 0.5, 0.0)
	legs(p, Vector3(7.0, ANKLE_Y + hop, 0.0), Vector3(-7.0, ANKLE_Y + hop, -1.0), Lib.E(0.0, 10.0, 0.0), Lib.E(0.0, -10.0, 0.0))
	p.r("Shoulder_R", 0.0, 0.0, -6.0 * strike)
	_head(p, -9.0 - 3.0 * strike + 2.0 * crouch, -10.0, -9.0 + 1.5 * sin(th))
	var up := [Vector3(18.0, 80.0 + 1.2 * strike + 0.4 * trem, 5.0) + Vector3(0.0, 0.6 * hop, 0.0), Vector3(1.0, -0.35, -0.5),
		Vector3(0.25 + 0.06 * trem, 1.0, 0.15), Vector3(-0.25, 0.0, 1.0), 0.0 - 6.0 * strike]
	_hand_mix(p, "R", up, up, 0.0)
	_on_hip(p, "L")
	p.r("SideLock_L1", -6.0 * strike, 0.0, 10.0 + 34.0 * strike)
	p.r("SideLock_R1", -6.0 * strike, 0.0, -10.0 - 34.0 * strike)
	var fl: float = 4.0 + 10.0 * strike
	p.r("Cape_L1", fl * 0.6, 0.0, fl)
	p.r("Cape_R1", fl * 0.6, 0.0, -fl)
	p.r("CapeC1", fl, 0.0, 0.0)
	if ph > 1.3 and ph < 1.85:
		_wink(p, "L")
	else:
		set_lids(p, 0.45 * minf(strike, 1.0))


# =============================================================== 圣战节点(paladin，男性款)：蓝发络腮胡、白金重甲 + 藏青披风的锤圣骑士(2026-10-07)
## 模型 tools/chars/paladin.gd(男性款：待机 / 跑步自动用 *_m；络腮胡长在头骨上，披风挂 Cape 链)。能拿三个大类：重(基础，专属武器是战锤
## W_heavy_warhammer：握点在原点、锤头在柄上 y 52..69、锤面 = 局部 ±Z)/ 剑 / 长柄。
## 被动「裂地猛击」：每 5 秒往前方猛砸地面，扇形震波(约 100°、3.5 米)。表现层放 slam_paladin_<大类>，0.30s 时在他面前生成地裂 + 结算伤害：
##   slam_paladin_heavy(24f = 0.8s，砸地 0.30s)：两手把锤抡到右肩后上方高举(上身往右后拧、后仰，重心先沉一下再拔起来)
##     → 0.23~0.30 整个人扑下去：上身从右后拧到右肩向前、猛地前压，右脚往前踏一步、深深屈膝，锤头从脑后经头顶划一个大弧砸到正前方地面
##     (0.30s 锤面贴地)→ 震一下(锤头弹起一点、身子跟着颤)→ 0.45s 起吃力地把锤提回来，收成右脚在前的低架(= idle_heavy_m)
##   slam_paladin_sword(24f，0.30s)：两手合握剑柄(左手压在右手上面)，蹲一下小跳起来、把剑倒提到脸前(剑尖朝下)
##     → 落地单膝深蹲、把剑尖朝前下方狠狠插进地里(0.30s，剑插进土里一截)→ 握着剑定住、震一下 → 拔剑起身、左手松开，回到单手持剑(= idle_sword_m)
##   slam_paladin_polearm(24f，0.30s)：两手把长柄竖着高举过头(枪尖朝天、略往后，枪杆从头的右侧上去)
##     → 左脚往前踏、沉身前压，像打桩一样把枪头从头顶砸进正前方的地里(0.30s)→ 震一下 → 收回侧身枪架(= idle_polearm_m)
##   三个的首尾都和该大类男性款待机 idle_<大类>_m 的 t = 0 对齐：开头 2 帧从待机混进来、最后 0.2s 混回待机(_pal_ends)，衔接没有跳变。
##   两手合握都走 two_hand()(自带防穿模松弛)。
## 小动作(收起武器，4.0s)：右手捋两下络腮胡(低头、眯眼)→ 耸肩活动肩膀、左右扭脖子("咔") → 右拳按在胸口、低头闭眼默祷 → 抬头放下手
## 胜利(收起武器，2.4s 循环)：大开步站定，右拳高举向天一下下往上顶(左拳叉腰)→ 收回来"咚"地捶一下胸口(身子一震、点头)→ 再举起
const PALADIN_TABLE := {"fidget_paladin": [4.0, false], "victory_paladin": [2.4, true]}
const PAL_CLASSES := ["heavy", "sword", "polearm"]
const PAL_SLAM := 24.0 * F             # slam_paladin_<大类> 的时长
const PAL_HIT := 0.30                  # 砸到地面的时刻(表现层在这一刻生成地裂、结算伤害)
const PAL_IN := 2.0 * F                # 开头从待机混进来的时长
const PAL_OUT := 0.2                   # 最后混回待机的时长


func paladin_table(t: Dictionary) -> void:
	for c: String in PAL_CLASSES:
		t["slam_paladin_" + c] = {"dur": PAL_SLAM, "loop": false, "fn": Callable(self, "slam_paladin_" + c)}
	for nm: String in PALADIN_TABLE.keys():
		t[nm] = {"dur": float(PALADIN_TABLE[nm][0]), "loop": bool(PALADIN_TABLE[nm][1]), "fn": Callable(self, nm)}


func slam_paladin_heavy(t: float, p) -> void:
	_pal_ends(t, p, "heavy", func(pp) -> void: _pal_slam_heavy(t, pp))


func slam_paladin_sword(t: float, p) -> void:
	_pal_ends(t, p, "sword", func(pp) -> void: _pal_slam_sword(t, pp))


func slam_paladin_polearm(t: float, p) -> void:
	_pal_ends(t, p, "polearm", func(pp) -> void: _pal_slam_polearm(t, pp))


## 首尾对齐男性款待机的 t = 0：开头 PAL_IN 内从待机混进来，最后 PAL_OUT 内混回待机(动作本身的首尾也摆在待机姿势附近，混合只消掉残差)
func _pal_ends(t: float, p, cls: String, body: Callable) -> void:
	var idle := func(pp) -> void: _as_male(0.0, pp, Callable(self, "idle_" + cls))
	var w_out: float = Lib.smooth((t - (PAL_SLAM - PAL_OUT)) / PAL_OUT)
	if w_out > 0.0:
		_pose_mix(p, body, idle, w_out)
	elif t < PAL_IN:
		_pose_mix(p, idle, body, Lib.smooth(t / PAL_IN))
	else:
		body.call(p)


## 身体：yaw 扭腰(正 = 右肩向前)、lean 前倾、push 骨盆前送、drop 沉胯(屈膝)、roll 侧弯；头转回来盯着前方。
## 前倾主要折在髋上(背挺直、屁股往后坐)：腰一弯肚子就顶到胸前握锤的手上(two_hand 会把武器整个绕右手转开)。
## 静止量照男性款待机(胸口略挺、肩膀往后)，这样首尾和待机对得上
func _pal_body(p, yaw: float, lean: float, push: float, drop: float, roll: float = 0.0, head_p: float = 0.0) -> void:
	p.move("Hips", Vector3(0.0, -1.7 - drop, push))
	p.r("Hips", lean * 0.7, yaw * 0.35, roll * 0.3)
	p.r("Spine", lean * 0.15 - 0.8, yaw * 0.3, roll * 0.3)
	p.r("Chest", lean * 0.15 - 1.25, yaw * 0.35, roll * 0.4)
	p.r("Shoulder_L", 0.0, 4.0, -2.8)
	p.r("Shoulder_R", 0.0, -4.0, 2.8)
	p.r("Head", 1.0 - lean * 0.45 + head_p, 1.2 - yaw * 0.8, 0.7 - roll * 0.5)


## 两手合握：右手握点(胸腔局部)、武器朝向(世界)、两手间距 span(< 0 = 左手在柄尾那边)、两肘朝向(世界)。
## Q 版短手 + 胸前的体积：两手合握只在胸前一小块地方解得开(大致 x -3..+2、y 58..65、z 13..17，胸腔局部)，左肘要往外前方撑(pole_l 带 +Z)，
## 否则左前臂横穿胸口、two_hand 的松弛会把武器整个绕右手转开——下面三个动作的握点 / 轴都是在这块地方里挑的(out/pal/th.gd 搜过)
func _pal_two(p, grip_c: Vector3, q: Quaternion, span: float, pole_r: Vector3, pole_l: Vector3) -> void:
	two_hand(p, follow(p, "Chest", grip_c), q, span, pole_r, pole_l, 4.0)


# ---------------------------------------------------------------- 裂地猛击·战锤 (24f = 0.8s，砸地 0.30s)
## 两手合握的锤柄轴 / 握点都写在胸腔局部(Q 版短手只够得着胸前一小块)，锤在世界里往哪指靠整个躯干扭转 + 前倾 / 后仰来摆：
## 举锤 = 上身往右后拧、后仰，锤柄从右肩外侧竖上去(锤头在脑后右上方)；砸下 = 上身拧到右肩向前、猛地前压，锤头从头顶右侧抡到正前方地面
func _pal_slam_heavy(t: float, p) -> void:
	p.reset()
	var dur := PAL_SLAM
	var shake: float = sin(TAU * (t - PAL_HIT) / 0.1) * exp(-(t - PAL_HIT) * 14.0) if t > PAL_HIT else 0.0     # 砸地后的震颤
	var yaw: float = kf_f([[0.0, HEAVY_YAW], [0.03, HEAVY_YAW + 2.0], [0.19, -30.0], [0.23, -32.0], [0.30, 40.0], [0.42, 44.0, "o"],
		[0.60, 40.0], [dur, HEAVY_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.03, 2.0], [0.19, -12.0], [0.23, -13.0], [0.30, 17.0], [0.36, 19.0, "o"], [0.46, 16.0],
		[0.62, 6.0], [dur, 0.0]], t) + 1.5 * shake
	var drop: float = kf_f([[0.0, 0.0], [0.03, 1.5], [0.19, -0.5], [0.23, -0.8], [0.30, 12.0, "i"], [0.34, 13.5, "o"], [0.46, 12.0],
		[0.64, 3.0], [dur, 0.0]], t) + 0.8 * shake
	var push: float = kf_f([[0.0, 0.0], [0.20, -2.5, "o"], [0.23, -2.8], [0.30, 4.0, "i"], [0.46, 3.5], [0.66, 1.0], [dur, 0.0]], t)
	_pal_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.27, 0.0], [0.31, 8.0, "o"], [0.45, 4.0], [0.7, 0.0]], t))
	# 脚：右脚(前脚)在砸下时往前踏一步，收势时退回；左脚踩住不动
	var rz: float = kf_f([[0.0, -HEAVY_LEAD], [0.19, -HEAVY_LEAD], [0.29, 7.5, "o"], [0.54, 7.5], [0.72, -HEAVY_LEAD]], t)
	_feet(p, 6.5 + 2.2, HEAVY_LEAD, 0.0, rz, _arc(t, 0.19, 0.29, 3.0) + _arc(t, 0.54, 0.72, 1.6), 6.0, -6.0 - 10.0 * Lib.smooth((rz + HEAVY_LEAD) / 4.5))
	# 锤柄轴(胸腔局部)：待机的低架 → 从右侧往上抡 → 竖在右肩外侧、锤头往后 → 过头顶 → 砸到前下方 → 弹一下 → 提回来
	var al: Vector3 = kf_v([[0.0, HEAVY_AXIS], [0.03, Vector3(-0.62, -0.5, 0.6)], [0.11, Vector3(-0.85, 0.45, 0.05)],
		[0.19, Vector3(-0.55, 0.83, -0.1), "o"], [0.23, Vector3(-0.52, 0.84, -0.14)], [0.265, Vector3(-0.55, 0.62, 0.56), "i"],
		[0.30, Vector3(-0.55, -0.3, 0.78), "i"], [0.34, Vector3(-0.55, -0.2, 0.8), "o"], [0.44, Vector3(-0.55, -0.27, 0.79)],
		[0.60, Vector3(-0.6, -0.4, 0.7)], [dur, HEAVY_AXIS]], t)
	var grip: Vector3 = kf_v([[0.0, HEAVY_GRIP], [0.03, Vector3(-2.5, 55.0, 12.0)], [0.11, Vector3(0.0, 59.0, 13.5)],
		[0.19, Vector3(2.0, 59.5, 14.5), "o"], [0.23, Vector3(2.0, 59.8, 14.5)], [0.265, Vector3(1.5, 60.0, 15.0), "i"],
		[0.30, Vector3(1.0, 59.0, 14.0), "i"], [0.34, Vector3(1.0, 60.0, 14.0), "o"], [0.44, Vector3(1.0, 59.5, 14.0)],
		[0.60, Vector3(-1.0, 58.0, 13.0)], [dur, HEAVY_GRIP]], t)
	# 两肘：待机时(世界方向)往外下；举锤 / 砸下时左肘往外前方撑(左前臂别横穿胸口)
	var ek: float = kf_f([[0.0, 0.0], [0.08, 1.0], [0.56, 1.0], [dur, 0.0]], t)
	_pal_two(p, grip, _heavy_rot(_chest_dir(p, al)), HEAVY_SPAN, Vector3(-1.0, -0.5, -0.2).lerp(_cdir(p, Vector3(-1.0, -0.3, 0.1)), ek),
		Vector3(1.0, -0.5, -0.1).lerp(_cdir(p, Vector3(1.0, -0.2, 0.5)), ek))
	set_lids(p, kf_f([[0.0, 0.0], [0.28, 0.0], [0.30, 0.6], [0.40, 0.6], [0.5, 0.0]], t))


# ---------------------------------------------------------------- 裂地猛击·剑 (24f = 0.8s，剑插进地里 0.30s)
## 两手合握剑柄(左手在右手下面一点，s = -5 往柄尾)：蹲一下小跳起来，空中把剑举到右肩后上方(上身略往右后拧、后仰)
## (右手先把剑提到胸前、左手再合上来，免得两手还没到胸前那块解得开的地方时剑被松弛甩到一边)
## → 落地深蹲前压、右肩送出去，剑刃朝下从头顶右侧劈下来，剑尖斜着插进身前的地里(0.30s)→ 握着剑定住、震一下 → 拔剑起身、左手松开回到单手竖持。
## 剑倒提(剑尖朝下)的双手握在 Q 版短手上解不开(左手要举到下巴前，正好在胡子里)，所以是"劈进去"：剑身的朝向和战锤一样用 _heavy_rot(刃口领着挥动方向)
func _pal_slam_sword(t: float, p) -> void:
	p.reset()
	var dur := PAL_SLAM
	var shake: float = sin(TAU * (t - PAL_HIT) / 0.1) * exp(-(t - PAL_HIT) * 14.0) if t > PAL_HIT else 0.0
	var hop: float = _arc(t, 0.11, 0.27, 6.0)                                             # 小跳：离地 6 体素
	var air: float = kf_f([[0.0, 0.0], [0.11, 0.0], [0.17, 1.0], [0.24, 1.0], [0.28, 0.0]], t)  # 腾空时收腿
	var yaw: float = kf_f([[0.0, 0.0], [0.08, -6.0], [0.18, -15.0], [0.24, -17.0], [0.30, 32.0], [0.46, 30.0], [0.62, 12.0], [dur, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.07, 8.0, "o"], [0.11, 4.0], [0.18, -6.0, "o"], [0.24, -7.0], [0.30, 32.0], [0.36, 34.0, "o"],
		[0.48, 30.0], [0.64, 10.0], [dur, 0.0]], t) + 1.5 * shake
	var drop: float = kf_f([[0.0, 0.0], [0.07, 5.0, "o"], [0.11, 1.0, "i"], [0.26, 0.0], [0.30, 13.0, "i"], [0.34, 14.0, "o"], [0.48, 12.5],
		[0.66, 3.0], [dur, 0.0]], t) + 0.8 * shake
	var push: float = kf_f([[0.0, 0.0], [0.07, -1.5], [0.20, 0.5], [0.30, 3.5, "i"], [0.48, 3.0], [dur, 0.0]], t)
	p.move("Root", Vector3(0.0, hop, 0.0))
	_pal_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.27, 0.0], [0.31, 6.0, "o"], [0.45, 3.0], [0.7, 0.0]], t))
	# 脚：腾空时左脚往前、右脚往后分开，落成弓步；收势时一步步收回
	var lz: float = kf_f([[0.0, 0.0], [0.13, 0.0], [0.27, 4.5, "o"], [0.52, 4.5], [0.66, 0.0]], t)
	var rz: float = kf_f([[0.0, 0.0], [0.13, 0.0], [0.27, -3.0, "o"], [0.60, -3.0], [0.74, 0.0]], t)
	var sp: float = 6.5 + 2.6 + 0.6 * air
	_feet(p, sp, lz, hop + 3.0 * air + _arc(t, 0.52, 0.66, 1.4), rz, hop + 2.5 * air + _arc(t, 0.60, 0.74, 1.4), 13.0, -13.0)
	# 剑：待机单手竖持 → 左手上来合握、剑举到右肩后上方 → 劈下插进前方地里 → 拔出来 → 左手松开、回到单手竖持
	var q_idle: Quaternion = Lib.E(SWORD_IDLE_ROT.x, SWORD_IDLE_ROT.y, SWORD_IDLE_ROT.z)
	var al: Vector3 = kf_v([[0.0, Vector3(-0.17, 0.8, 0.58)], [0.07, Vector3(-0.4, 0.85, 0.35), "o"], [0.11, Vector3(-0.45, 0.85, 0.25)], [0.18, Vector3(-0.55, 0.83, -0.1), "o"],
		[0.24, Vector3(-0.52, 0.84, -0.15)], [0.265, Vector3(-0.5, 0.5, 0.7), "i"], [0.30, Vector3(-0.4, -0.42, 0.81), "i"],
		[0.48, Vector3(-0.4, -0.4, 0.82)], [0.58, Vector3(-0.5, 0.5, 0.7)], [0.66, Vector3(-0.3, 0.75, 0.6)], [dur, Vector3(-0.17, 0.8, 0.58)]], t)
	var engage: float = kf_f([[0.0, 0.0], [0.08, 1.0], [0.60, 1.0], [0.72, 0.0]], t)
	var q: Quaternion = q_idle.slerp(_heavy_rot(_chest_dir(p, al)), engage)
	var grip: Vector3 = kf_v([[0.0, SWORD_IDLE_GRIP], [0.07, Vector3(0.0, 58.0, 15.0), "o"], [0.11, Vector3(1.5, 59.0, 15.0)], [0.18, Vector3(2.0, 59.5, 14.5), "o"],
		[0.24, Vector3(2.0, 60.0, 14.5)], [0.265, Vector3(1.5, 60.0, 15.0), "i"], [0.30, Vector3(1.0, 60.0, 15.5), "i"],
		[0.48, Vector3(1.0, 60.5, 15.5)], [0.58, Vector3(1.5, 60.0, 15.0)], [0.66, Vector3(-6.0, 54.0, 13.0)], [dur, SWORD_IDLE_GRIP]], t)
	var two: float = kf_f([[0.0, 0.0], [0.05, 0.0], [0.11, 1.0, "o"], [0.56, 1.0], [0.66, 0.0]], t)       # 左手合握的程度
	var base: Array[Quaternion] = p.rot.duplicate()
	# 单手：右手持剑、左手自然垂着(男性款待机的手)
	hold_bow(p, follow(p, "Chest", grip), q, Vector3(-1.0, -0.25, -0.35))
	fist_r(p, 80.0)
	male = true
	relax_l(p, 0.0)
	male = false
	if two > 0.0:
		var one: Array[Quaternion] = p.rot.duplicate()
		p.rot = base.duplicate()
		_pal_two(p, grip, q, -5.0, _cdir(p, Vector3(-1.0, -0.3, 0.1)), _cdir(p, Vector3(1.0, -0.2, 0.5)))
		if two < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = one[i].slerp(p.rot[i], two)
			p.dirty = true
	set_lids(p, kf_f([[0.0, 0.0], [0.28, 0.0], [0.30, 0.6], [0.42, 0.6], [0.52, 0.0]], t))


# ---------------------------------------------------------------- 裂地猛击·长柄 (24f = 0.8s，枪头砸进地里 0.30s)
## 长柄是左手在前(往枪头那边 span 9~10)：举起时上身往右拧(右肩向前)、后仰，枪从左肩外侧竖上去、枪尖在脑后左上方(枪杆躲开胡子和脸)
## → 0.23~0.30 上身拧回左肩向前、前压，左脚踏出，枪头从头顶左侧抡下来，像打桩一样斜着砸进正前方的地里 → 震一下 → 收回侧身枪架
func _pal_slam_polearm(t: float, p) -> void:
	p.reset()
	var dur := PAL_SLAM
	var shake: float = sin(TAU * (t - PAL_HIT) / 0.1) * exp(-(t - PAL_HIT) * 14.0) if t > PAL_HIT else 0.0
	var yaw: float = kf_f([[0.0, POLE_YAW], [0.03, POLE_YAW - 2.0], [0.11, -15.0], [0.19, 15.0, "o"], [0.23, 17.0], [0.30, -55.0],
		[0.46, -53.0], [0.62, -50.0], [dur, POLE_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.03, 2.0], [0.19, -10.0, "o"], [0.23, -11.0], [0.30, 24.0], [0.36, 26.0, "o"], [0.48, 22.0],
		[0.64, 8.0], [dur, 0.0]], t) + 1.5 * shake
	var drop: float = kf_f([[0.0, 0.0], [0.03, 1.5], [0.19, -1.0], [0.23, -1.2], [0.30, 10.0, "i"], [0.34, 11.0, "o"], [0.48, 9.5],
		[0.64, 3.0], [dur, 0.0]], t) + 0.8 * shake
	var push: float = kf_f([[0.0, 0.0], [0.20, -2.0, "o"], [0.30, 3.5, "i"], [0.48, 3.0], [dur, 0.0]], t)
	_pal_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.27, 0.0], [0.31, 6.0, "o"], [0.45, 3.0], [0.7, 0.0]], t))
	# 脚：左脚(前脚)随砸落往前踏一大步，重重落地；收势退回
	var lz: float = kf_f([[0.0, POLE_LEAD], [0.19, POLE_LEAD], [0.29, 8.5, "o"], [0.54, 8.5], [0.72, POLE_LEAD]], t)
	_feet(p, 6.5 + 2.2, lz, _arc(t, 0.19, 0.29, 3.0) + _arc(t, 0.54, 0.72, 1.6), -POLE_LEAD, 0.0, 6.0 + 10.0 * Lib.smooth((lz - POLE_LEAD) / 5.5), -6.0)
	# 长柄轴(胸腔局部)：侧身枪架 → 举到左肩外侧(枪尖朝后上)→ 从头顶左侧抡下来 → 砸进前下方 → 弹一下 → 收回
	var al: Vector3 = kf_v([[0.0, POLE_AXIS], [0.03, Vector3(0.82, 0.25, 0.5)], [0.11, Vector3(0.75, 0.6, 0.2)],
		[0.19, Vector3(0.65, 0.7, -0.3), "o"], [0.23, Vector3(0.63, 0.72, -0.32)], [0.265, Vector3(0.7, 0.5, 0.5), "i"],
		[0.30, Vector3(0.7, -0.26, 0.66), "i"], [0.34, Vector3(0.7, -0.18, 0.69), "o"], [0.46, Vector3(0.7, -0.24, 0.67)],
		[0.62, Vector3(0.75, -0.05, 0.62)], [dur, POLE_AXIS]], t)
	var grip: Vector3 = kf_v([[0.0, POLE_GRIP], [0.03, Vector3(-5.0, 51.5, 9.5)], [0.11, Vector3(-5.5, 52.5, 13.0)],
		[0.19, Vector3(-5.5, 53.5, 15.0), "o"], [0.23, Vector3(-5.5, 54.0, 15.0)], [0.265, Vector3(-4.5, 57.0, 11.0), "i"],
		[0.30, Vector3(-3.0, 60.0, 8.0), "i"], [0.34, Vector3(-3.0, 60.5, 8.0), "o"], [0.48, Vector3(-3.0, 60.0, 8.0)],
		[0.64, Vector3(-4.0, 56.0, 9.0)], [dur, POLE_GRIP]], t)
	var span: float = kf_f([[0.0, POLE_SPAN], [0.19, 9.0], [0.50, 9.0], [dur, POLE_SPAN]], t)
	var ek: float = kf_f([[0.0, 0.0], [0.08, 1.0], [0.56, 1.0], [dur, 0.0]], t)
	_pal_two(p, grip, _pole_rot(_chest_dir(p, al)), span, Vector3(-1.0, -0.5, -0.3).lerp(_cdir(p, Vector3(-1.0, -0.5, -0.3)), ek),
		Vector3(1.0, -0.5, -0.2).lerp(_cdir(p, Vector3(1.0, -0.3, 0.4)), ek))
	set_lids(p, kf_f([[0.0, 0.0], [0.28, 0.0], [0.30, 0.6], [0.40, 0.6], [0.5, 0.0]], t))


# ---------------------------------------------------------------- 小动作(4.0s)：捋胡子 → 活动肩膀、扭脖子 → 右拳按胸默祷 → 放下
const G_PAL_BEARD_TOP := [Vector3(5.0, 73.0, 15.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, -0.6, 0.8), Vector3(0.0, 0.0, -1.0), 45.0]   # 捏着胡子根(他的胡子往前凸到 z 12)
const G_PAL_BEARD_LOW := [Vector3(3.5, 66.0, 15.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, -0.8, 0.6), Vector3(0.0, 0.0, -1.0), 62.0]   # 捋到胡子尖
const G_PAL_PRAY := [Vector3(0.5, 59.5, 14.0), Vector3(1.0, -0.1, 0.05), Vector3(-0.8, 0.3, 0.2), Vector3(0.0, 0.0, -1.0), 90.0]      # (右手)拳头按在胸口正中(手短：按到左胸的话上臂会压进胸甲)
const G_PAL_HIP := [Vector3(13.5, 51.0, 0.5), Vector3(1.0, 0.1, -0.6), Vector3(-0.2, -0.6, -1.0), Vector3(-1.0, 0.0, 0.0), 80.0]       # 拳头叉在腰侧(重甲腰粗，往外放一点)


func fidget_paladin(t: float, p) -> void:
	p.reset()
	_stow(p)
	var stroke: float = kf_f([[0.0, 0.0], [0.4, 1.0], [1.45, 1.0], [1.7, 0.0]], t)
	var roll_k: float = kf_f([[0.0, 0.0], [1.6, 0.0], [1.75, 1.0], [2.35, 1.0], [2.5, 0.0]], t)       # 活动肩膀
	var pray: float = kf_f([[0.0, 0.0], [2.55, 0.0], [2.9, 1.0], [3.55, 1.0], [3.9, 0.0]], t)
	var ph: float = clampf((t - 1.75) / 0.6, 0.0, 1.0) * TAU
	# 扭脖子：往左歪 → "咔"(一顿) → 往右歪 → "咔"
	var crack: float = kf_f([[0.0, 0.0], [1.95, 0.0], [2.1, 14.0, "o"], [2.16, 16.0], [2.3, -13.0], [2.42, -15.0, "o"], [2.55, 0.0]], t)
	var nod: float = kf_f([[0.0, 0.0], [0.8, 0.0], [0.92, 1.0], [1.04, 0.0], [1.16, 0.7], [1.28, 0.0]], t)
	_base(p, 0.25 * sin(t * TAU / 4.0), -0.4 * pray, 0.0, 2.0 * stroke + 3.0 * pray, -0.25 * crack, 0.0, 8.9, 0.0)
	legs(p, Vector3(8.9, ANKLE_Y, -0.5), Vector3(-8.9, ANKLE_Y, -0.5), Lib.E(0, 12.0, 0), Lib.E(0, -12.0, 0))
	p.r("Shoulder_L", 4.0 * roll_k * (1.0 - cos(ph)) * 0.5, 4.0 - 3.0 * roll_k * sin(ph), -2.8 + 7.0 * roll_k * (0.5 - 0.5 * cos(ph)))
	p.r("Shoulder_R", 4.0 * roll_k * (1.0 - cos(ph)) * 0.5, -4.0 + 3.0 * roll_k * sin(ph), 2.8 - 7.0 * roll_k * (0.5 - 0.5 * cos(ph)))
	_head(p, 9.0 * stroke + 8.0 * nod + 13.0 * pray - 3.0 * roll_k, -7.0 * stroke, 3.0 * stroke + crack)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.4, G_PAL_BEARD_TOP], [0.75, G_PAL_BEARD_LOW], [0.95, G_PAL_BEARD_TOP], [1.3, G_PAL_BEARD_LOW],
		[1.45, G_PAL_BEARD_LOW], [1.75, G_RELAX], [2.55, G_RELAX], [2.9, G_PAL_PRAY], [3.55, G_PAL_PRAY], [3.95, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.4, G_PAL_HIP], [1.45, G_PAL_HIP], [1.75, G_RELAX], [4.0, G_RELAX]], t)
	set_lids(p, maxf(maxf(0.5 * stroke, pray), maxf(0.6 * clampf(absf(crack) / 14.0, 0.0, 1.0), blink_k(t, 3.95))))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：右拳高举一下下往上顶 → 捶胸 → 再举起
const G_PAL_FIST_UP := [Vector3(21.0, 83.0, 4.0), Vector3(1.0, -0.4, -0.5), Vector3(0.05, 1.0, 0.15), Vector3(-0.4, 0.0, 1.0), 88.0]   # 拳头高举(头侧上方偏外，躲开大肩甲和刺发)
const G_PAL_FIST_MID := [Vector3(17.5, 68.0, 11.0), Vector3(1.0, -0.5, -0.4), Vector3(-0.3, 0.8, 0.5), Vector3(-0.5, 0.0, 0.8), 88.0]  # 举起 ↔ 捶胸的途中(肩前)
const G_PAL_THUMP := [Vector3(0.5, 60.0, 14.0), Vector3(1.0, 0.0, 0.0), Vector3(-0.8, 0.3, 0.2), Vector3(0.0, 0.0, -1.0), 90.0]     # 拳头捶在胸口正中


func victory_paladin(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var pump: float = maxf(0.0, sin(TAU * ph / 0.5)) * kf_f([[0.0, 1.0], [0.95, 1.0], [1.05, 0.0], [2.2, 0.0], [2.4, 1.0]], ph)    # 拳头一下下往上顶
	var hit: float = kf_f([[0.0, 0.0], [1.28, 0.0], [1.36, 1.0, "i"], [1.5, 0.35, "o"], [1.85, 0.0], [2.4, 0.0]], ph)                  # 捶胸那一下的冲击
	var th: float = TAU * ph / 2.4
	_base(p, 0.0, 0.5 * pump - 0.9 * hit, 3.0, -5.0 + 7.0 * hit - 1.5 * pump, 0.0, 0.0, 9.5, 1.0)
	legs(p, Vector3(9.5, ANKLE_Y, 0.5), Vector3(-9.5, ANKLE_Y, -1.5), Lib.E(0, 14.0, 0), Lib.E(0, -14.0, 0))
	p.r("Shoulder_L", 0.0, 4.0, -2.8)
	var lift: float = kf_f([[0.0, 1.0], [1.0, 1.0], [1.2, 0.0], [2.05, 0.0], [2.3, 1.0]], ph)                 # 拳头举着的时候耸起右肩(举得更高)
	p.r("Shoulder_R", 0.0, -4.0, 2.8 - 10.0 * lift - 5.0 * pump)
	_head(p, -10.0 - 3.0 * pump + 10.0 * hit, -3.0, 2.0 * sin(th))
	var up: Array = G_PAL_FIST_UP.duplicate()
	up[0] = G_PAL_FIST_UP[0] + Vector3(0.0, 2.0 * pump, 0.5 * pump)
	var thump: Array = G_PAL_THUMP.duplicate()
	thump[0] = G_PAL_THUMP[0] + Vector3(0.0, 0.0, -1.2 * hit)
	_hand_keys(p, "R", [[0.0, up], [1.0, up], [1.18, G_PAL_FIST_MID], [1.34, thump], [1.85, thump], [2.05, G_PAL_FIST_MID], [2.4, up]], ph)
	_hand_mix(p, "L", G_PAL_HIP, G_PAL_HIP, 0.0)
	set_lids(p, 0.25 + 0.5 * hit)


# =============================================================== 巧运节点(rogue，男性款)：银发精灵耳、红围巾 + 炭黑长外套的幸运盗贼(2026-10-07)
## 模型 tools/chars/rogue.gd(男性款：待机 / 跑步自动用 *_m；红围巾的长尾挂 Cape 链、鬓发挂 SideLock 链，烘焙时自己甩)。
## 被动「每次普攻有概率摸到 1 金币」+「真骰」(坏结果重掷)：小动作和胜利都围着一枚硬币转 —— 身上没有硬币道具骨，硬币靠手势 + 视线"演"出来。
## 小动作(收起武器，4.3s)：右手攥拳托着硬币举到胸前、低头看 → 拇指往上一弹(手腕一挑)，抬头盯着硬币飞上去、落下来 → 右手一把抄住 →
##   左手抬到身前手背朝上，右手翻过来"啪"地把硬币拍在左手背上(身子一顿) → 俯身凑近、掀起手掌根偷看(眯眼、歪头) →
##   抬头得意一笑：耸肩、左手往外一摊、右手攥着硬币举到肩前，眨左眼 → 低头把硬币塞进右胯前的腰包、往里按两下 → 放下手
## 胜利(收起武器，2.4s 循环)：重心压在左腿上、右脚往外撇、上身往后仰的痞气站姿，左手拇指勾着腰带 ——
##   右手把硬币往上一抛，抬头看它落下来一把抄住，顺手两指在眉边往外一甩敬个礼 + 眨左眼，手落回胸前掌心朝上、沉一下等下一抛
const ROGUE_TABLE := {"fidget_rogue": [4.3, false], "victory_rogue": [2.4, true]}
# 手势(左手约定的胸腔局部量，右手自动镜像)：[手腕位置, 肘的朝向, 手指方向, 掌心方向, 手指弯曲]
const G_RG_RELAX := [Vector3(17.0, 49.5, 2.8), Vector3(0.6, -0.2, -1.0), Vector3(0.12, -1.0, 0.12), Vector3(-1.0, 0.0, 0.2), 32.0]   # 男性款垂手(离身体远一点、半握拳)
const G_RG_COIN := [Vector3(8.0, 58.5, 13.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.3, 0.15, 1.0), Vector3(-1.0, 0.0, 0.2), 72.0]      # (右手)攥拳托着硬币举在胸前，拇指在上
const G_RG_FLICK := [Vector3(8.5, 62.0, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.25, 0.6, 0.8), Vector3(-1.0, 0.0, 0.2), 40.0]    # 拇指一弹：手往上一抬、手腕一挑
const G_RG_READY := [Vector3(9.0, 60.0, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.3, 0.2, 1.0), Vector3(0.0, 1.0, -0.2), 12.0]     # 掌心朝上张着等硬币落下
const G_RG_CATCH := [Vector3(8.5, 61.0, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.3, 0.25, 1.0), Vector3(0.0, 1.0, -0.25), 88.0]  # 一把抄住
const G_RG_TURN := [Vector3(4.5, 63.5, 13.5), Vector3(1.0, -0.5, -0.3), Vector3(-0.45, 0.3, 0.85), Vector3(-1.0, 0.0, 0.0), 75.0]    # 攥着翻过来的途中(掌心朝里)
const G_RG_FLIP := [Vector3(0.0, 66.0, 13.0), Vector3(1.0, -0.3, 0.2), Vector3(-0.5, 0.1, 0.85), Vector3(0.0, -1.0, 0.1), 50.0]      # 翻过来扣着，举到左手背上方
const G_RG_SLAP := [Vector3(-1.0, 60.9, 13.1), Vector3(1.0, -0.3, 0.2), Vector3(-0.25, -0.05, 0.97), Vector3(0.0, -1.0, 0.0), 4.0]   # "啪"地拍在左手背上
const G_RG_PEEK := [Vector3(-1.0, 63.8, 12.5), Vector3(1.0, -0.3, 0.2), Vector3(-0.2, -0.5, 0.85), Vector3(0.0, -0.85, -0.5), 12.0]   # 掀起手掌根偷看(指尖还扣着)
const G_RG_PICK := [Vector3(-0.5, 62.5, 14.0), Vector3(1.0, -0.3, 0.2), Vector3(-0.45, -0.2, 0.85), Vector3(0.0, -0.9, -0.3), 70.0]  # 捏起硬币
const G_RG_SHOW := [Vector3(14.0, 68.0, 10.0), Vector3(1.0, -0.5, -0.4), Vector3(-0.1, 1.0, 0.3), Vector3(-0.5, 0.0, 0.85), 85.0]   # 攥着硬币举到肩前
const G_RG_POUCH := [Vector3(10.0, 50.5, 7.5), Vector3(0.9, -0.2, -0.6), Vector3(0.0, -1.0, 0.15), Vector3(-0.3, 0.0, -1.0), 45.0]   # 右胯前腰包的上方
const G_RG_TUCK := [Vector3(10.0, 47.5, 7.0), Vector3(0.9, -0.2, -0.6), Vector3(0.0, -1.0, 0.1), Vector3(-0.3, 0.0, -1.0), 18.0]    # 指尖塞进腰包
const G_RG_BACK_L := [Vector3(2.0, 58.5, 13.0), Vector3(1.0, -0.4, -0.3), Vector3(-0.15, 0.0, 1.0), Vector3(0.0, -1.0, 0.0), 8.0]    # 左手抬到身前、手背朝上
const G_RG_SHRUG_L := [Vector3(19.5, 55.0, 8.0), Vector3(0.6, -0.6, -0.6), Vector3(0.75, 0.0, 0.65), Vector3(0.0, 1.0, 0.0), 8.0]   # 左手往外一摊、掌心朝上
# 胜利
const G_RG_BELT := [Vector3(8.0, 51.5, 7.0), Vector3(1.0, -0.2, -0.6), Vector3(-0.25, -1.0, 0.25), Vector3(-0.2, 0.0, -1.0), 30.0]   # 左手拇指勾着腰带
const G_RG_TOSS := [Vector3(9.5, 64.5, 14.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.7, 0.7), Vector3(0.0, 0.6, -0.8), 4.0]      # 往上一抛(手一抬、手指张开)
const G_RG_BROW := [Vector3(10.0, 78.5, 14.5), Vector3(1.0, -0.4, -0.3), Vector3(-0.25, 1.0, 0.0), Vector3(0.0, -0.2, 1.0), 2.0]     # 两指并拢贴在眉梢(手挡在刘海前面)
const G_RG_SALUTE := [Vector3(18.5, 81.5, 13.0), Vector3(1.0, -0.4, -0.3), Vector3(0.6, 0.8, 0.1), Vector3(0.2, 0.0, 1.0), 2.0]    # 往外前方一甩


func rogue_table(t: Dictionary) -> void:
	for nm: String in ROGUE_TABLE.keys():
		t[nm] = {"dur": float(ROGUE_TABLE[nm][0]), "loop": bool(ROGUE_TABLE[nm][1]), "fn": Callable(self, nm)}


## 手势平移一下(冲击、按压)
static func _rg_at(g: Array, d: Vector3) -> Array:
	var r: Array = g.duplicate()
	r[0] = (g[0] as Vector3) + d
	return r


## 男性款站姿(= 男性款待机的脚)：两脚更开、脚尖外八
func _rg_stance(p) -> void:
	legs(p, Vector3(9.1, ANKLE_Y, -0.5), Vector3(-9.1, ANKLE_Y, -0.5), Lib.E(0, 13.0, 0), Lib.E(0, -13.0, 0))


# ---------------------------------------------------------------- 小动作(4.3s)：弹硬币 → 接住 → 拍在手背上 → 偷看 → 得意 → 塞进腰包
func fidget_rogue(t: float, p) -> void:
	p.reset()
	_stow(p)
	var up: float = kf_f([[0.0, 0.0], [0.6, 0.0], [0.95, 1.0, "o"], [1.3, 0.0, "i"]], t)                      # 硬币飞着：仰头看
	var slap: float = kf_f([[0.0, 0.0], [1.7, 0.0], [1.74, 1.0, "o"], [2.0, 0.0]], t)                          # 拍下去那一顿
	var peek: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.25, 1.0], [2.55, 1.0], [2.75, 0.0]], t)
	var smug: float = kf_f([[0.0, 0.0], [2.6, 0.0], [2.85, 1.0, "o"], [3.15, 1.0], [3.45, 0.0]], t)             # 耸肩、得意
	var pouch: float = kf_f([[0.0, 0.0], [3.15, 0.0], [3.45, 1.0], [3.9, 1.0], [4.2, 0.0]], t)                  # 弯腰往腰包里塞
	var push: float = _arc(t, 3.58, 3.7, 1.0) + _arc(t, 3.7, 3.82, 1.0)                                          # 往里按两下
	var cross: float = kf_f([[0.0, 0.0], [1.4, 0.0], [1.62, 1.0], [2.6, 1.0], [2.85, 0.0]], t)                  # 右手伸到身前偏左：右肩往前探
	var sway: float = kf_f([[0.0, 0.0], [0.4, 0.8], [1.6, 0.8], [2.0, -0.6], [2.6, -0.6], [3.0, 1.2], [3.4, -0.8], [3.9, -0.8], [4.3, 0.0]], t)
	var yaw: float = kf_f([[0.0, 0.0], [0.4, -4.0], [1.3, -3.0], [1.62, 5.0], [2.55, 6.0], [2.9, -3.0], [3.45, -7.0], [3.9, -7.0], [4.3, 0.0]], t)
	_base(p, sway, -0.9 * slap - 1.2 * pouch - 0.6 * _arc(t, 1.3, 1.5, 1.0), yaw + 4.0 * cross, -4.0 * up + 3.0 * slap + 7.0 * peek - 2.0 * smug + 7.0 * pouch,
		-8.0 * pouch + 2.0 * smug, 0.0, 9.1)
	_rg_stance(p)
	p.r("Shoulder_L", 0.0, 4.0 - 12.0 * kf_f([[0.0, 0.0], [1.2, 0.0], [1.5, 1.0], [2.6, 1.0], [2.9, 0.0]], t), -1.5 + 11.0 * smug)
	p.r("Shoulder_R", 0.0, -4.0 + 20.0 * cross, 1.5 - 11.0 * smug - 3.0 * pouch)
	# 头：看手 → 仰头追着硬币 → 接住低头 → 凑近偷看 → 抬头歪着 → 低头看腰包 → 回正
	var hp: float = kf_f([[0.0, 0.0], [0.4, 15.0], [0.6, 15.0], [0.66, 11.0], [0.95, -28.0, "o"], [1.3, 13.0, "i"], [1.5, 8.0], [1.74, 16.0],
		[2.0, 14.0], [2.25, 22.0], [2.55, 22.0], [2.85, -8.0, "o"], [3.15, -6.0], [3.45, 14.0], [3.9, 14.0], [4.25, 0.0]], t)
	var hy: float = kf_f([[0.0, 0.0], [0.4, -10.0], [0.95, -7.0], [1.3, -6.0], [1.7, 4.0], [2.25, 6.0], [2.55, 6.0], [2.85, -4.0],
		[3.15, -4.0], [3.45, -16.0], [3.9, -16.0], [4.25, 0.0]], t)
	var hr: float = kf_f([[0.0, 0.0], [0.4, 3.0], [1.7, 3.0], [2.25, 10.0], [2.55, 10.0], [2.85, -10.0, "o"], [3.15, -10.0], [3.45, -3.0], [4.25, 0.0]], t)
	_head(p, hp + 4.0 * slap, hy, hr)
	# 右手
	var slap_r: Array = _rg_at(G_RG_SLAP, Vector3(0.0, -1.5 * slap, 0.0))
	_hand_keys(p, "R", [[0.0, G_RG_RELAX], [0.4, G_RG_COIN], [0.52, _rg_at(G_RG_COIN, Vector3(0.0, -1.0, 0.0))], [0.6, G_RG_FLICK], [0.75, G_RG_FLICK],
		[1.05, G_RG_READY], [1.2, _rg_at(G_RG_READY, Vector3(0.0, 1.5, 0.0))], [1.32, G_RG_CATCH],
		[1.5, G_RG_TURN], [1.63, G_RG_FLIP], [1.72, slap_r], [2.0, slap_r], [2.25, G_RG_PEEK], [2.55, G_RG_PEEK], [2.7, G_RG_PICK], [2.95, G_RG_SHOW], [3.15, G_RG_SHOW],
		[3.45, G_RG_POUCH], [3.58, G_RG_TUCK], [3.9, G_RG_TUCK], [4.3, G_RG_RELAX]], t)
	if push > 0.0:
		p.radd("Hand_R", 12.0 * push, 0.0, 0.0)
	# 拇指：先扣紧(蓄力) → 一弹 → 松开
	p.radd("Thumb_R", kf_f([[0.0, 0.0], [0.35, 0.0], [0.5, -20.0], [0.57, -20.0], [0.65, 36.0, "l"], [0.85, 25.0], [1.1, 0.0]], t), 0.0, 0.0)
	# 左手：垂着 → 抬到身前手背朝上(被拍那一下往下一沉，偷看时往脸前抬一点) → 往外一摊 → 放下
	var back_l: Array = _rg_at(G_RG_BACK_L, Vector3(0.0, -1.5 * slap + 1.5 * peek, 0.5 * peek))
	_hand_keys(p, "L", [[0.0, G_RG_RELAX], [1.15, G_RG_RELAX], [1.5, back_l], [2.58, back_l], [3.0, G_RG_SHRUG_L], [3.15, G_RG_SHRUG_L],
		[3.55, G_RG_RELAX], [4.3, G_RG_RELAX]], t)
	if t > 2.85 and t < 3.3:
		_wink(p, "L")
	else:
		set_lids(p, maxf(maxf(0.3 * peek, 0.3 * smug), maxf(0.25 * pouch, blink_k(t, 4.0))))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：抛硬币 → 抄住 → 两指敬礼 + 眨眼 → 落回胸前
func victory_rogue(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var th: float = TAU * ph / 2.4
	var up: float = kf_f([[0.0, 0.0], [0.06, 0.0], [0.36, 1.0, "o"], [0.66, 0.0, "i"], [2.4, 0.0]], ph)        # 仰头看硬币
	var catch: float = kf_f([[0.0, 0.0], [0.64, 0.0], [0.68, 1.0, "o"], [0.95, 0.0], [2.4, 0.0]], ph)          # 抄住那一顿
	var sal: float = kf_f([[0.0, 0.0], [0.9, 0.0], [1.15, 1.0], [1.85, 1.0], [2.2, 0.0], [2.4, 0.0]], ph)     # 敬礼
	var dip: float = kf_f([[0.0, 1.0], [0.06, 0.0, "o"], [2.2, 0.0], [2.4, 1.0]], ph)                          # 抛之前沉一下
	_base(p, 3.0, 0.35 * sin(2.0 * th) - 0.8 * catch - 0.6 * dip, -6.0 + 4.0 * sal, -6.0 - 2.5 * up + 2.0 * catch - 1.5 * sal, -4.0, 0.0, 9.0)
	legs(p, Vector3(8.0, ANKLE_Y, -0.5), Vector3(-11.0, ANKLE_Y, 1.5), Lib.E(0, 10.0, 0), Lib.E(0, -24.0, 0))
	p.r("Shoulder_L", 0.0, 4.0, -1.5)
	p.r("Shoulder_R", 0.0, -4.0, 1.5 - 5.0 * sal)
	_head(p, -4.0 - 24.0 * up + 6.0 * catch + 2.0 * dip, -8.0 + 6.0 * sal, -9.0 + 1.5 * sin(th) - 3.0 * sal)
	var ready: Array = G_RG_READY
	var ready_hi: Array = _rg_at(ready, Vector3(0.0, 1.2, 0.0))
	ready_hi[4] = 30.0
	var caught: Array = _rg_at(G_RG_CATCH, Vector3(0.0, -1.5, 0.0))
	if ph > 0.76 and ph < 1.12:
		# 抄住 → 眉边：手往外前方绕一点(别从下巴前面直直地擦上去)，朝向照常均匀地转
		var w: float = Lib.smooth((ph - 0.76) / 0.36)
		_hand_q(p, "R", (caught[0] as Vector3).lerp(G_RG_BROW[0], w) + Vector3(3.0, 0.0, 1.5) * sin(PI * w), (caught[1] as Vector3).lerp(G_RG_BROW[1], w),
			_gq("R", caught[2], caught[3]).slerp(_gq("R", G_RG_BROW[2], G_RG_BROW[3]), w), lerpf(float(caught[4]), float(G_RG_BROW[4]), w))
	else:
		_hand_keys(p, "R", [[0.0, _rg_at(ready, Vector3(0.0, -1.5, 0.0))], [0.08, G_RG_TOSS], [0.3, ready], [0.58, ready_hi],
			[0.68, G_RG_CATCH], [0.76, caught], [1.12, G_RG_BROW], [1.22, G_RG_BROW], [1.37, G_RG_SALUTE],
			[1.85, G_RG_SALUTE], [2.2, ready], [2.4, _rg_at(ready, Vector3(0.0, -1.5, 0.0))]], ph)
	_hand_mix(p, "L", G_RG_BELT, G_RG_BELT, 0.0)
	if ph > 1.22 and ph < 1.8:
		_wink(p, "L")
	else:
		set_lids(p, 0.3 * (1.0 - up))


# =============================================================== 心连节点(sister)：量产型的发条人偶修女(2026-10-07)
## 模型 tools/chars/sister.gd(女性款)：象牙白球形关节的瓷质手脚、藏青头巾(前面两条垂片挂 SideLock 链、后片挂 Cape 链，烘焙时自己甩)。
## 温柔、虔诚，又带一点机械感(被动会召唤自己的复制品、给队友治疗)。"机械感"统一用 _ss_tick：头 / 眼皮像发条钟一样一格一格地拨
## (每格两三帧拨完、然后停住)，其余动作照常圆滑。
## 小动作(收起武器，4.3s)：双手十指交扣、低头闭眼祈祷 → 眼睛"咔"地睁开，发条走松了：头一格一格歪向右边、身子一点点塌下去、
##   双手软软地垂下来、眼皮半合 → 右手伸到右腰侧捏住看不见的发条钥匙，转三圈上弦(每转一圈"咔哒"一下：身子一顿、头往回拨一格、
##   眼皮睁开一格) → 上满了：身子一挺、轻轻一颠、眨一下眼 → 低头用两手把身前的裙摆往下抚平 → 放下手
## 胜利(收起武器，2.4s 循环)：双手交扣在胸前 → 两手往下捏起裙边、右脚后撤半步行屈膝礼(低头) → 起身、双臂往两侧张开
##   (掌心朝前上方，赐福)，头"咔、咔、咔"地一格一格歪过去、半闭着眼 → 再一格一格拨回来，双手收回胸前交扣
const SISTER_TABLE := {"fidget_sister": [4.3, false], "victory_sister": [2.4, true]}
# 手势(左手约定的胸腔局部量，右手自动镜像)：[手腕位置, 肘的朝向, 手指方向, 掌心方向, 手指弯曲]
const G_SS_PRAY := [Vector3(2.4, 59.5, 13.5), Vector3(1.0, -0.6, -0.15), Vector3(0.0, 1.0, 0.3), Vector3(-1.0, 0.0, 0.0), 40.0]      # 十指交扣在胸前(比 G_PRAY 低、靠前：低头时别顶到下巴)
const G_SS_LIMP := [Vector3(14.0, 49.5, 3.5), Vector3(0.6, -0.2, -1.0), Vector3(0.05, -1.0, 0.25), Vector3(-1.0, 0.0, 0.1), 4.0]    # 发条松了：手软软地垂着(略靠前，手指松开)
const G_SS_KEY := [Vector3(17.5, 54.0, 2.0), Vector3(0.7, -0.3, -0.8), Vector3(-0.6, -0.55, 0.55), Vector3(0.0, -1.0, 0.0), 70.0]  # (右手)捏着右腰侧的发条钥匙(钥匙轴朝外：转的时候手在身侧的竖直面里画圈)
const G_SS_SMOOTH_A := [Vector3(5.5, 52.5, 10.0), Vector3(1.0, -0.4, -0.4), Vector3(-0.1, -1.0, 0.15), Vector3(0.0, 0.1, -1.0), 8.0]  # 手掌贴在腹前(准备往下抚)
const G_SS_SMOOTH_B := [Vector3(10.5, 48.5, 9.0), Vector3(0.9, -0.3, -0.6), Vector3(0.25, -1.0, 0.1), Vector3(0.0, 0.0, -1.0), 8.0]   # 抚到胯前两侧
const G_SS_SKIRT := [Vector3(17.5, 49.5, 5.0), Vector3(0.8, -0.3, -0.6), Vector3(0.25, -0.75, 0.6), Vector3(-0.6, 0.0, 0.3), 62.0]  # 捏着裙边往外提(屈膝礼)
const G_SS_BLESS := [Vector3(25.0, 64.5, 9.0), Vector3(0.4, -0.8, -0.5), Vector3(0.9, 0.35, 0.3), Vector3(0.0, 0.45, 0.9), 6.0]  # 双臂往两侧张开赐福，掌心朝前上方


func sister_table(t: Dictionary) -> void:
	for nm: String in SISTER_TABLE.keys():
		t[nm] = {"dur": float(SISTER_TABLE[nm][0]), "loop": bool(SISTER_TABLE[nm][1]), "fn": Callable(self, nm)}


## 发条式的"一格一格"：t0 起每 step 秒拨一格(snap 秒内拨完、先快后慢，其余时间停住)，共 n 格；返回 0..1(拨完 = 1)
static func _ss_tick(t: float, t0: float, step: float, n: int, snap: float = 0.07) -> float:
	if t <= t0:
		return 0.0
	var k: int = int(floor((t - t0) / step))
	if k >= n:
		return 1.0
	return (float(k) + _ease("o", (t - t0 - float(k) * step) / snap)) / float(n)


## 两个手势之间按 w 线性混合(两个手势的朝向相近时用；差得远的走 _hand_mix 的球面插值)
static func _ss_lerp(a: Array, b: Array, w: float) -> Array:
	return [(a[0] as Vector3).lerp(b[0], w), (a[1] as Vector3).lerp(b[1], w), (a[2] as Vector3).lerp(b[2], w), (a[3] as Vector3).lerp(b[3], w),
		lerpf(float(a[4]), float(b[4]), w)]


# ---------------------------------------------------------------- 小动作(4.3s)：祈祷 → 发条走松(头一格格歪下去) → 腰侧上弦三圈 → 上满一颠 → 抚平裙摆
func fidget_sister(t: float, p) -> void:
	p.reset()
	_stow(p)
	var pray: float = kf_f([[0.0, 0.0], [0.5, 1.0], [1.3, 1.0], [1.6, 0.0]], t)
	# 发条走松(1.40 / 1.57 / 1.74 三格) × 上弦(2.55 / 2.85 / 3.15 每转完一圈拨回一格)
	var slack: float = _ss_tick(t, 1.4, 0.17, 3) * (1.0 - _ss_tick(t, 2.55, 0.3, 3))
	var crank: float = kf_f([[0.0, 0.0], [2.0, 0.0], [2.25, 1.0], [3.15, 1.0], [3.4, 0.0]], t)       # 右手在腰侧上弦
	var click: float = _arc(t, 2.55, 2.69, 1.0) + _arc(t, 2.85, 2.99, 1.0) + _arc(t, 3.15, 3.29, 1.0)  # 每转完一圈"咔哒"一顿
	var pop: float = _arc(t, 3.2, 3.48, 1.0)                                                           # 上满了：一挺一颠
	var smooth_k: float = kf_f([[0.0, 0.0], [3.35, 0.0], [3.6, 1.0], [3.95, 1.0], [4.3, 0.0]], t)      # 低头抚裙
	_base(p, 0.4 * sin(t * 1.7) * (1.0 - crank), -1.2 * slack - 0.5 * click + 0.9 * pop - 0.8 * smooth_k, -6.0 * crank,
		4.0 * pray + 5.0 * slack + 3.0 * crank - 3.0 * pop + 7.0 * smooth_k, -4.0 * slack, 0.0, 6.0, 0.0, 0.3 * pop)
	p.r("Shoulder_L", 0.0, 0.0, -4.0 * slack)
	p.r("Shoulder_R", 0.0, 0.0, 4.0 * slack - 3.0 * click)
	_head(p, 13.0 * pray + 7.0 * slack + 3.0 * crank - 4.0 * pop + 13.0 * smooth_k, -22.0 * crank, -18.0 * slack + 2.0 * click)
	# 右手：合十 → 垂下 → 腰侧捏住钥匙转三圈(手腕画小圈) → 贴到腹前往下抚 → 放下
	var r_k: float = 3.0 * kf_f([[0.0, 0.0], [2.15, 0.0], [2.35, 1.0], [3.05, 1.0], [3.2, 0.0]], t)
	var ph: float = clampf((t - 2.25) / 0.9, 0.0, 1.0) * 3.0 * TAU
	var key: Array = _rg_at(G_SS_KEY, Vector3(0.0, r_k * sin(ph), -r_k * cos(ph)))
	var wr := Basis(Vector3.RIGHT, 0.1 * r_k * sin(ph))                                              # 手腕跟着拧
	key[2] = wr * (G_SS_KEY[2] as Vector3)
	key[3] = wr * (G_SS_KEY[3] as Vector3)
	var limp: Array = _ss_lerp(G_RELAX, G_SS_LIMP, slack)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.5, G_SS_PRAY], [1.3, G_SS_PRAY], [1.65, limp], [1.92, limp], [2.25, key], [3.15, key],
		[3.45, G_SS_SMOOTH_A], [3.55, G_SS_SMOOTH_A], [3.95, G_SS_SMOOTH_B], [4.3, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.5, G_SS_PRAY], [1.3, G_SS_PRAY], [1.65, limp], [3.2, limp],
		[3.45, G_SS_SMOOTH_A], [3.55, G_SS_SMOOTH_A], [3.95, G_SS_SMOOTH_B], [4.3, G_RELAX]], t)
	# 眼皮：祈祷时闭上 → "咔"地睁开 → 跟着发条一格格半合 / 睁开 → 上满时眨一下 → 低头抚裙时半垂
	var shut: float = kf_f([[0.0, 0.0], [0.25, 0.0], [0.45, 1.0], [1.3, 1.0], [1.36, 0.0, "l"]], t)
	set_lids(p, maxf(maxf(shut, 0.45 * slack), maxf(0.35 * smooth_k, blink_k(t, 3.22))))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：交扣祈祷 → 提裙屈膝礼 → 张臂赐福(头一格格歪过去) → 收回
func victory_sister(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var pray: float = kf_f([[0.0, 1.0], [0.28, 1.0], [0.6, 0.0], [1.92, 0.0], [2.3, 1.0], [2.4, 1.0]], ph)
	var dip: float = kf_f([[0.0, 0.0], [0.36, 0.0], [0.76, 1.0], [0.98, 1.0], [1.34, 0.0], [2.4, 0.0]], ph)          # 屈膝
	var back: float = kf_f([[0.0, 0.0], [0.3, 0.0], [0.62, 1.0], [1.08, 1.0], [1.42, 0.0], [2.4, 0.0]], ph)          # 右脚后撤半步
	var bless: float = kf_f([[0.0, 0.0], [1.0, 0.0], [1.42, 1.0], [1.92, 1.0], [2.3, 0.0], [2.4, 0.0]], ph)
	var tilt: float = 13.0 * (_ss_tick(ph, 1.4, 0.12, 3) - _ss_tick(ph, 1.98, 0.1, 3))                              # 头一格格歪过去、再拨回来
	var breath: float = sin(TAU * ph / 1.2)
	_base(p, 0.0, -4.0 * dip + 0.3 * bless * breath, 0.0, 3.0 * pray + 8.0 * dip - 4.0 * bless, 2.0 * bless, 0.0,
		6.0 - 0.6 * dip, 3.5 * back, 0.3 * bless)
	_head(p, 8.0 * pray + 9.0 * dip - 6.0 * bless, 0.0, tilt)
	var bl: Array = _rg_at(G_SS_BLESS, Vector3(0.0, 0.5 * breath, 0.0))
	for side: String in ["L", "R"]:
		_hand_keys(p, side, [[0.0, G_SS_PRAY], [0.28, G_SS_PRAY], [0.62, G_SS_SKIRT], [0.98, G_SS_SKIRT], [1.42, bl], [1.92, bl],
			[2.3, G_SS_PRAY], [2.4, G_SS_PRAY]], ph)
	set_lids(p, 0.3 + 0.35 * dip + 0.15 * bless)


# =============================================================== 无我节点(killer)：咒刃武士少女(2026-10-07)
## 模型 tools/chars/killer.gd(女性款)：墨绿长发、墨绿和服、手臂 / 小腿上的紫色诅咒纹，半垂着眼、很沉静。
## 专属武器是一把大太刀(重武器大类，双手；W_heavy_odachi = 连鞘、W_heavy_odachi_drawn = 出鞘，刃口 = 局部 +Z，握点在原点、刀尖 y 94)：
##   平时刀不出鞘 —— 连着黑漆鞘双手抡(钝击)；只有被动「无我」的特殊战斗开场才拔刀(draw_killer)，之后用出鞘的那一套。
## 普攻 / 群攻的时长、出手时刻和重武器大类一致(36f / 0.52s，旋斩 48f / 0.95s)；首尾都对齐女性款 idle_heavy 的 t = 0
##   (开头 2 帧从待机混进来、最后 0.2s 混回待机，_kl_ends)，连着出招没有跳变。
##   attack_killer_sheathed(36f，0.52s)：双手连鞘，不慌不忙地把刀竖到右肩旁(八相)，停一拍 → 右脚贴地滑进半步，
##     拧腰从右上往左前下"袈裟"砸下去(0.52s 砸中：鞘身一顿、往回弹一点，身子跟着一震)→ 收回低架、右脚退回
##   whirl_killer_sheathed(48f，0.95s)：沉胯、右手把连鞘的刀拖到右后方 → 单手平平甩出去，以右脚为轴转一整圈(越转越快，
##     0.95s 扫回正前方)，左臂往反方向张开配重，长发甩开 → 被刀的惯性带过头一点、站定 → 两手合握收回低架
##   attack_killer_drawn(36f，0.52s)：拔刀术的架势 —— 右手把刀收到左腰(刀身从左拳里往后穿出去，像插在看不见的鞘里)，沉身、静止
##     → 一瞬间右脚踏出一大步，反手从左下往右上逆袈裟斩出(0.52s 刀刃扫过正前方)→ 刀停在右上方残心 → 往右下一振(血振)→ 两手合握收回低架
##   whirl_killer_drawn(48f，0.95s)：同样从左腰的拔刀架势起手，静止 → 反手拔刀横斩，顺势低身转一整圈(0.95s 扫回正前方)
##     → 低身定住残心、刀往右后一振 → 起身、两手合握收回低架
##   draw_killer(36f = 1.2s，不循环)：特殊战斗开场拔刀 —— 把连鞘的刀收到左腰的拔刀架势(鞘往左后方伸出去)，沉身低头、闭眼吸一口气，
##     拇指推开刀镡 → KL_SWAP(0.48s = 40%)该换网格(连鞘 → 出鞘)：0.28~0.50 刀一动不动，两种网格的柄相同、刀身与鞘几乎重合，
##     换的那一帧轮廓不变，只是黑漆鞘变成刀身(表现层在这一刻给鞘一团紫色的诅咒火就像鞘被烧掉)
##     → 右手顺着刀身抽出一截，刀尖出鞘口后反手往前平平划一道弧，停在右前方(睁眼、右脚踏出)→ 停一拍 → 两手合握落成低架(= idle_heavy)
## 小动作(收起武器，4.2s)：右手抬到胸前、掌心朝上低头看(诅咒纹在发作)，手指慢慢屈伸两下、发抖，翻过来看手背，左手握住右手腕，
##   慢慢攥成拳 → 放下手、闭眼深吸一口气、长长地呼出来(头歪一点、头发跟着晃)→ 半睁开眼
## 胜利(收起武器，2.4s 循环)：身子侧过去半转、左手按在左腰看不见的刀上(握着鞘口)，右手垂着，低着头半闭眼，慢慢地吸气、长长地呼气
const KILLER_TABLE := {"fidget_killer": [4.2, false], "victory_killer": [2.4, true]}
const KL_ATK := 36.0 * F               # 普攻(= 重武器大类的攻击间隔)
const KL_HIT := 0.52                   # 普攻出手
const KL_WHIRL := 48.0 * F             # 旋斩
const KL_WHIRL_HIT := 0.95             # 旋斩出手
const KL_DRAW := 36.0 * F              # 拔刀
const KL_SWAP := 0.48                  # draw_killer 里该换网格(连鞘 → 出鞘)的时刻(= 40%)：0.28~0.50 刀静止在拔刀架势里，这段里换轮廓都不变
const KL_IN := 2.0 * F                 # 开头从待机混进来
const KL_OUT := 0.2                    # 最后混回待机
# 拔刀术的架势(骨盆局部)：右手握点、刀身方向(往刀尖)、左拳扣在刀身上的位置(= 看不见的鞘口)
# (out/killer/hold.gd 搜过：右手要高一点、刀身往外撇，左拳才不陷进胯里、刀身也躲得开骨盆和大腿)；刃口朝外(水平，= 下 × 刀身)
const KL_IAI_GRIP := Vector3(3.0, 55.0, 15.0)
const KL_IAI_DIR := Vector3(0.75, -0.3, -0.82)
const KL_IAI_L := 14.0
# 逆袈裟斩的刀路：[t, 右手握点(胸腔局部), 刀身方向(世界), 刃口朝向(世界), easing]
const KL_GYAKU := [
	[0.465, Vector3(-2.0, 54.0, 16.0), Vector3(0.85, -0.35, 0.40), Vector3(-0.35, 0.19, 0.92), "i"],
	[0.50, Vector3(-7.0, 59.0, 16.0), Vector3(0.40, -0.05, 0.92), Vector3(-0.85, 0.35, 0.39), "l"],
	[0.52, Vector3(-11.0, 63.0, 13.5), Vector3(-0.12, 0.18, 0.98), Vector3(-0.79, 0.57, -0.2), "l"],
	[0.55, Vector3(-13.5, 67.5, 9.0), Vector3(-0.60, 0.58, 0.55), Vector3(-0.32, 0.47, -0.82), "o"],
	[0.60, Vector3(-14.0, 71.0, 5.0), Vector3(-0.50, 0.80, -0.33), Vector3(0.46, -0.08, -0.89), "o"],
	[0.76, Vector3(-14.0, 71.5, 4.5), Vector3(-0.47, 0.82, -0.33), Vector3(0.46, -0.06, -0.89), "s"],
	[0.84, Vector3(-15.5, 61.0, 10.0), Vector3(-0.55, 0.05, 0.83), Vector3(-0.84, -0.03, -0.55), "s"],
	[0.875, Vector3(-16.5, 56.0, 9.0), Vector3(-0.75, -0.30, 0.58), Vector3(-0.55, -0.18, -0.81), "o"],
	[1.2, Vector3(-16.0, 56.5, 9.5), Vector3(-0.74, -0.32, 0.58), Vector3(-0.55, -0.18, -0.81), "s"],
]


func killer_table(t: Dictionary) -> void:
	for nm: String in ["attack_killer_sheathed", "attack_killer_drawn"]:
		t[nm] = {"dur": KL_ATK, "loop": false, "fn": Callable(self, nm)}
	for nm2: String in ["whirl_killer_sheathed", "whirl_killer_drawn"]:
		t[nm2] = {"dur": KL_WHIRL, "loop": false, "fn": Callable(self, nm2)}
	t["draw_killer"] = {"dur": KL_DRAW, "loop": false, "fn": Callable(self, "draw_killer")}
	for nm3: String in KILLER_TABLE.keys():
		t[nm3] = {"dur": float(KILLER_TABLE[nm3][0]), "loop": bool(KILLER_TABLE[nm3][1]), "fn": Callable(self, nm3)}


func attack_killer_sheathed(t: float, p) -> void:
	_kl_ends(t, p, KL_ATK, func(pp) -> void: _kl_kesa(t, pp))


func attack_killer_drawn(t: float, p) -> void:
	_kl_ends(t, p, KL_ATK, func(pp) -> void: _kl_gyaku(t, pp))


func whirl_killer_sheathed(t: float, p) -> void:
	_kl_ends(t, p, KL_WHIRL, func(pp) -> void: _kl_whirl(t, pp, false))


func whirl_killer_drawn(t: float, p) -> void:
	_kl_ends(t, p, KL_WHIRL, func(pp) -> void: _kl_whirl(t, pp, true))


func draw_killer(t: float, p) -> void:
	_kl_ends(t, p, KL_DRAW, func(pp) -> void: _kl_draw(t, pp))


## 首尾对齐女性款待机 idle_heavy 的 t = 0：开头 KL_IN 内从待机混进来，最后 KL_OUT 内混回待机(动作本身的首尾也摆在待机姿势附近，混合只消掉残差)
func _kl_ends(t: float, p, dur: float, body: Callable) -> void:
	var idle := func(pp) -> void: idle_heavy(0.0, pp)
	var w_out: float = Lib.smooth((t - (dur - KL_OUT)) / KL_OUT)
	if w_out > 0.0:
		_pose_mix(p, body, idle, w_out)
	elif t < KL_IN:
		_pose_mix(p, idle, body, Lib.smooth(t / KL_IN))
	else:
		body.call(p)


## 身体：yaw 扭腰(正 = 右肩向前)、lean 前倾(主要折在髋上)、push 骨盆前送、drop 沉胯、roll 侧弯；头转回来盯着前方。静止量照女性款待机的 t = 0
func _kl_body(p, yaw: float, lean: float, push: float, drop: float, roll: float = 0.0, head_p: float = 0.0, head_y: float = 0.0) -> void:
	p.move("Hips", Vector3(0.0, -1.7 - drop, push))
	p.r("Hips", lean * 0.7, yaw * 0.35, roll * 0.3)
	p.r("Spine", lean * 0.15 - 0.8, yaw * 0.3, roll * 0.3)
	p.r("Chest", lean * 0.15 + 0.55, yaw * 0.35, roll * 0.4)
	p.r("Shoulder_L", 0.0, 0.0, -1.3)
	p.r("Shoulder_R", 0.0, 0.0, 1.3)
	p.r("Head", 1.0 - lean * 0.45 + head_p, 1.95 - yaw * 0.8 + head_y, 1.85 - roll * 0.5)


## 单手段(one)与两手合握的低架(当前身体下的 _hold_heavy)按 w(1 = 两手合握)逐节 slerp；frame = 整个人转过的角度(旋斩)
func _kl_blend_two(p, w: float, one: Callable, frame: Quaternion = Quaternion.IDENTITY) -> void:
	var base: Array[Quaternion] = p.rot.duplicate()
	var rot_one: Array[Quaternion] = base
	if w < 1.0:
		one.call(p)
		rot_one = p.rot.duplicate()
	if w > 0.0:
		p.rot = base.duplicate()
		if frame.is_equal_approx(Quaternion.IDENTITY):
			_hold_heavy(p, HEAVY_GRIP, HEAVY_AXIS)
		else:
			_hold_heavy(p, HEAVY_GRIP, HEAVY_AXIS, HEAVY_SPAN, frame, Vector3.RIGHT.cross(HEAVY_AXIS.normalized()))
		if w < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = rot_one[i].slerp(p.rot[i], w)
			p.dirty = true


## 拔刀术的架势：[右手握点(世界), 刀的朝向(世界，刃口朝外 = 下 × 刀身), 左拳的位置(世界)]；biki = 左手把"鞘"往后送的程度
func _kl_iai(p, biki: float = 0.0) -> Array:
	p.fk()
	var hb: Basis = p.gx[rig.ids["Hips"]].basis.orthonormalized()
	var d: Vector3 = KL_IAI_DIR.normalized()
	var l_at: Vector3 = KL_IAI_GRIP + d * (KL_IAI_L + 2.0 * biki) + Vector3(0.8, 0.0, 0.0) * biki
	return [follow(p, "Hips", KL_IAI_GRIP), Quaternion(hb) * wrot(d, Vector3.DOWN.cross(d)), follow(p, "Hips", l_at)]


## 当前身体下两手合握低架的武器：[握点(世界), 朝向(世界)](two_hand 松弛之后的真实朝向)
func _kl_idle_wpn(p) -> Array:
	var keep: Array[Quaternion] = p.rot.duplicate()
	_hold_heavy(p, HEAVY_GRIP, HEAVY_AXIS)
	var r: Array = [p.gpos_n("Bow"), p.grot_n("Bow")]
	p.rot = keep
	p.dirty = true
	return r


## 低架 → 拔刀架势(u 0..1)：刀尖从右前方经左前方绕到左后方(先整把刀绕竖轴转一半，再转到架势：途中刃口转成朝外)，握点移到左腰
func _kl_to_iai(p, u: float, idle_w: Array, hold: Array) -> Array:
	var q0: Quaternion = idle_w[1]
	var q1: Quaternion = hold[1]
	var a0: Vector3 = q0 * Vector3.UP
	var a1: Vector3 = q1 * Vector3.UP
	var turn: float = fposmod(atan2(a1.x, a1.z) - atan2(a0.x, a0.z), TAU)      # 逆时针(俯视)= 经过左前方
	var qm: Quaternion = Quaternion(Vector3.UP, turn * 0.5) * q0
	var v: float = Lib.smooth(u)
	var q: Quaternion = q0.slerp(qm, v * 2.0) if v < 0.5 else qm.slerp(q1, v * 2.0 - 1.0)
	return [(idle_w[0] as Vector3).lerp(hold[0], v), q]


# ---------------------------------------------------------------- 连鞘·袈裟打(36f，0.52s 砸中)
## 两手合握(Q 版短手只在胸前一小块地方解得开：握点 / 轴都写在胸腔局部，往哪砸靠整个躯干扭转 + 前倾来摆，和圣战节点的锤同一套可行域)：
## 八相 = 上身往右后拧、略后仰，鞘竖在右肩旁 → 拧到右肩向前、前压，鞘从右上往左前下砸到对手的肩腰高度(不砸地)，砸中后顿住、回弹
func _kl_kesa(t: float, p) -> void:
	p.reset()
	var dur := KL_ATK
	var dt: float = t - KL_HIT
	var shake: float = sin(TAU * dt / 0.09) * exp(-dt * 16.0) if dt > 0.0 else 0.0     # 砸中后的震颤
	var yaw: float = kf_f([[0.0, HEAVY_YAW], [0.06, HEAVY_YAW + 2.0], [0.30, -26.0, "o"], [0.43, -31.0], [0.505, 48.0, "i"], [0.53, 52.0, "o"],
		[0.64, 49.0], [0.84, 44.0], [dur, HEAVY_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.06, 1.5], [0.30, -7.0, "o"], [0.43, -8.0], [0.505, 10.0, "i"], [0.53, 11.0, "o"], [0.66, 9.0],
		[0.88, 4.0], [dur, 0.0]], t) + 1.2 * shake
	var drop: float = kf_f([[0.0, 0.0], [0.06, 1.0], [0.30, 0.3], [0.43, 0.0], [0.505, 5.0, "i"], [0.53, 6.0, "o"], [0.68, 5.0],
		[0.92, 1.5], [dur, 0.0]], t) + 0.6 * shake
	var push: float = kf_f([[0.0, 0.0], [0.30, -1.5, "o"], [0.43, -2.0], [0.505, 3.5, "i"], [0.64, 3.5], [0.92, 1.0], [dur, 0.0]], t)
	_kl_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.50, 0.0], [0.54, 5.0, "o"], [0.7, 2.0], [0.95, 0.0]], t))
	# 脚：右脚(前脚)贴地往前滑半步、左脚跟上一点，收势时退回
	var rz: float = kf_f([[0.0, 3.0], [0.41, 3.0], [0.51, 8.0, "o"], [0.86, 8.0], [1.06, 3.0]], t)
	var lz: float = kf_f([[0.0, -3.0], [0.52, -3.0], [0.64, -0.5, "o"], [0.90, -0.5], [1.10, -3.0]], t)
	var k: float = Lib.smooth((rz - 3.0) / 5.0)
	_feet(p, 6.5, lz, _arc(t, 0.52, 0.64, 0.8) + _arc(t, 0.90, 1.10, 0.8), rz, _arc(t, 0.42, 0.52, 1.2) + _arc(t, 0.86, 1.06, 1.0),
		6.0 + 6.0 * k, -6.0 - 10.0 * k)
	# 鞘的轴(胸腔局部)：低架 → 从右侧竖起来(八相) → 停一拍 → 从右肩上方往前下砸 → 顿住、回弹 → 收回
	var al: Vector3 = kf_v([[0.0, HEAVY_AXIS], [0.06, Vector3(-0.62, -0.5, 0.6)], [0.18, Vector3(-0.78, 0.35, 0.52)],
		[0.30, Vector3(-0.55, 0.83, -0.1), "o"], [0.43, Vector3(-0.52, 0.84, -0.16)], [0.465, Vector3(-0.55, 0.62, 0.56), "i"],
		[0.505, Vector3(-0.6, 0.06, 0.8), "i"], [0.53, Vector3(-0.6, 0.0, 0.8), "o"], [0.64, Vector3(-0.6, 0.1, 0.79)],
		[0.86, Vector3(-0.6, -0.2, 0.77)], [dur, HEAVY_AXIS]], t)
	var grip: Vector3 = kf_v([[0.0, HEAVY_GRIP], [0.06, Vector3(-2.5, 55.0, 12.0)], [0.18, Vector3(0.0, 58.5, 13.5)],
		[0.30, Vector3(2.0, 59.5, 14.5), "o"], [0.43, Vector3(2.0, 59.8, 14.5)], [0.465, Vector3(1.5, 60.0, 15.0), "i"],
		[0.505, Vector3(1.0, 59.5, 15.0), "i"], [0.53, Vector3(1.0, 59.0, 15.0), "o"], [0.64, Vector3(1.0, 59.8, 14.8)],
		[0.86, Vector3(-1.0, 58.0, 13.5)], [dur, HEAVY_GRIP]], t)
	var ek: float = kf_f([[0.0, 0.0], [0.10, 1.0], [0.80, 1.0], [dur, 0.0]], t)
	two_hand(p, follow(p, "Chest", grip), _heavy_rot(_chest_dir(p, al)), HEAVY_SPAN,
		Vector3(-1.0, -0.5, -0.2).lerp(_cdir(p, Vector3(-1.0, -0.3, 0.1)), ek), Vector3(1.0, -0.5, -0.1).lerp(_cdir(p, Vector3(1.0, -0.2, 0.5)), ek), 4.0)
	set_lids(p, kf_f([[0.0, 0.0], [0.2, 0.35], [0.46, 0.35], [0.52, 0.55], [0.7, 0.4], [1.0, 0.15], [dur, 0.0]], t))


# ---------------------------------------------------------------- 出鞘·逆袈裟(36f，0.52s 斩过正前方)
## 右手单手(刀路完全可控、手臂能伸直)：低架 → 刀收到左腰的拔刀架势(左拳扣着"鞘口") → 反手从左下往右上斩出 → 右上方残心 → 往右下血振；
## 两手合握的低架与单手段之间按骨骼逐节 slerp 过渡
func _kl_gyaku(t: float, p) -> void:
	p.reset()
	var dur := KL_ATK
	var yaw: float = kf_f([[0.0, HEAVY_YAW], [0.22, 54.0], [0.44, 57.0], [0.52, -22.0, "i"], [0.58, -38.0, "o"], [0.76, -36.0], [0.86, -18.0],
		[1.0, 20.0], [dur, HEAVY_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.22, 11.0], [0.44, 13.0], [0.52, 7.0], [0.58, 3.0, "o"], [0.76, 3.0], [0.86, 9.0, "o"], [1.0, 5.0],
		[dur, 0.0]], t)
	var drop: float = kf_f([[0.0, 0.0], [0.22, 5.0], [0.44, 6.0], [0.52, 3.5], [0.60, 2.5], [0.76, 3.0], [0.88, 5.0, "o"], [1.04, 2.0], [dur, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.22, -1.0], [0.44, -1.5], [0.52, 5.0, "i"], [0.84, 5.0], [1.04, 1.5], [dur, 0.0]], t)
	_kl_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.22, -4.0], [0.44, -4.0], [0.52, 0.0], [dur, 0.0]], t))
	# 脚：拔刀那一下右脚往前踏出一大步(后脚蹬地)，收势退回
	var rz: float = kf_f([[0.0, 3.0], [0.44, 3.0], [0.53, 11.0, "o"], [0.90, 11.0], [1.10, 3.0]], t)
	var lz: float = kf_f([[0.0, -3.0], [0.22, -4.5], [0.50, -4.5], [0.62, -2.0, "o"], [0.95, -2.0], [1.12, -3.0]], t)
	var k: float = Lib.smooth((rz - 3.0) / 8.0)
	_feet(p, 6.8, lz, _arc(t, 0.12, 0.22, 1.0) + _arc(t, 0.52, 0.62, 1.2) + _arc(t, 0.95, 1.12, 0.8), rz,
		_arc(t, 0.44, 0.53, 2.5) + _arc(t, 0.90, 1.10, 1.2), 10.0, -6.0 - 12.0 * k)
	var two: float = kf_f([[0.0, 1.0], [0.16, 0.0], [0.92, 0.0], [1.12, 1.0]], t)
	_kl_blend_two(p, two, func(pp) -> void: _kl_gyaku_arms(pp, t))
	set_lids(p, kf_f([[0.0, 0.0], [0.2, 0.4], [0.44, 0.5], [0.50, 0.2], [0.6, 0.3], [0.8, 0.4], [1.0, 0.15], [dur, 0.0]], t))


func _kl_gyaku_arms(p, t: float) -> void:
	var idle_w: Array = _kl_idle_wpn(p) if t < 0.20 else []
	var held: float = kf_f([[0.0, 0.0], [0.20, 1.0], [0.44, 1.0], [0.48, 0.0, "i"]], t)
	p.radd("Shoulder_R", 0.0, 27.0 * held, -7.0 * held)     # 右肩往前送(右手才够得着左腰)
	var cq: Quaternion = _chest_q(p)
	var hold: Array = _kl_iai(p, kf_f([[0.0, 0.0], [0.44, 0.0], [0.50, 1.0, "o"]], t))
	var g: Vector3
	var q: Quaternion
	if t < 0.20:
		var gq: Array = _kl_to_iai(p, t / 0.20, idle_w, hold)
		g = gq[0]
		q = gq[1]
	else:
		var gk: Array = [[0.44, hold[0]]]
		var qk: Array = [[0.44, hold[1]]]
		for kk: Array in KL_GYAKU:
			gk.append([kk[0], follow(p, "Chest", kk[1]), kk[4]])
			qk.append([kk[0], wrot(kk[2], kk[3]), kk[4]])
		g = kf_v(gk, t)
		q = kf_q(qk, t)
	hold_bow(p, g, q, cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	# 左手：扣在左腰的"鞘口"上(刀身从拳里穿出去)，拔刀时把鞘往后一送，之后一直按在左腰
	hold_left(p, hold[2], hold[1], Vector3(1.0, -0.6, -0.1))
	fist_l(p, 76.0)


# ---------------------------------------------------------------- 旋斩(48f，0.95s 扫回正前方)：连鞘 / 出鞘两套
## 刀扫过正前方的时刻 = 转体角 + 扭腰 + 刀在胸腔局部的朝向 = -360°，转速最快的时候出手
func _kl_whirl(t: float, p, drawn: bool) -> void:
	p.reset()
	var dur := KL_WHIRL
	var spin: float
	var yaw: float
	var lean: float
	var drop: float
	var roll: float
	var two: float
	if drawn:
		spin = kf_f([[0.0, 0.0], [0.50, 3.0], [0.70, -30.0, "i"], [0.95, -306.0, "l"], [1.10, -372.0, "o"], [1.38, -363.0], [dur, -360.0]], t)
		yaw = kf_f([[0.0, HEAVY_YAW], [0.26, 54.0], [0.50, 57.0], [0.72, 0.0], [0.80, -4.0], [1.10, -8.0], [1.24, -4.0], [dur, HEAVY_YAW]], t)
		lean = kf_f([[0.0, 0.0], [0.26, 12.0], [0.56, 14.0], [0.68, 10.0], [1.10, 12.0], [1.24, 14.0], [dur, 0.0]], t)
		drop = kf_f([[0.0, 0.0], [0.26, 6.0], [0.56, 7.0], [0.70, 7.5], [1.10, 8.5, "o"], [1.26, 8.0], [dur, 0.0]], t)
		roll = kf_f([[0.0, 0.0], [0.62, 0.0], [0.78, -8.0], [1.0, -8.0], [1.2, 0.0]], t)
		two = kf_f([[0.0, 1.0], [0.18, 0.0], [1.30, 0.0], [1.52, 1.0]], t)
	else:
		spin = kf_f([[0.0, 0.0], [0.40, 18.0, "o"], [0.50, 20.0], [0.80, -130.0, "i"], [0.95, -310.0, "l"], [1.12, -385.0, "o"], [1.38, -362.0], [dur, -360.0]], t)
		yaw = kf_f([[0.0, HEAVY_YAW], [0.40, -36.0, "o"], [0.50, -40.0], [0.66, 6.0], [1.2, 8.0], [dur, HEAVY_YAW]], t)
		lean = kf_f([[0.0, 0.0], [0.40, 6.0], [0.66, 9.0], [1.2, 8.0], [dur, 0.0]], t)
		drop = 5.0 * kf_f([[0.0, 0.0], [0.40, 1.0, "o"], [1.2, 1.0], [dur, 0.0]], t)
		roll = kf_f([[0.0, 0.0], [0.55, 0.0], [0.8, -7.0], [1.08, -7.0], [1.3, 0.0]], t)
		two = kf_f([[0.0, 1.0], [0.12, 0.0], [1.24, 0.0], [1.48, 1.0]], t)
	_kl_body(p, yaw, lean, 0.0, drop, roll, 0.0)
	# 原地转：Root 转、脚的目标也按同一个角度转，转的时候小碎步(以右脚为轴，左脚绕着走)
	p.r("Root", 0.0, spin, 0.0)
	var qs := Quaternion(Vector3.UP, deg_to_rad(spin))
	var lead: float = kf_f([[0.0, HEAVY_LEAD], [0.40, -5.0], [0.56, -1.0], [1.3, -1.0], [dur, HEAVY_LEAD]], t)
	var t0: float = 0.60 if drawn else 0.52
	var hop_l: float = _arc(t, t0, t0 + 0.14, 1.6) + _arc(t, t0 + 0.26, t0 + 0.40, 1.6) + _arc(t, 1.30, 1.48, 1.0)
	var hop_r: float = _arc(t, t0 + 0.14, t0 + 0.27, 1.0) + _arc(t, t0 + 0.40, t0 + 0.54, 1.0)
	var sp: float = 6.5 + drop * 0.15
	legs(p, qs * Vector3(sp, ANKLE_Y + hop_l, -0.5 + lead), qs * Vector3(-sp, ANKLE_Y + hop_r, -0.5 - lead), Lib.E(0, spin + 6.0, 0), Lib.E(0, spin - 6.0, 0))
	_kl_blend_two(p, two, func(pp) -> void: _kl_whirl_arms(pp, t, drawn), qs)
	if drawn:
		set_lids(p, kf_f([[0.0, 0.0], [0.26, 0.45], [0.50, 0.5], [0.56, 0.15], [1.1, 0.3], [1.3, 0.4], [dur, 0.0]], t))
	else:
		set_lids(p, kf_f([[0.0, 0.0], [0.3, 0.35], [0.9, 0.35], [1.2, 0.3], [dur, 0.0]], t))


## 旋斩的单手段：握点、刀身方向都在胸腔局部(跟着身体转)；刃口朝转动方向(绕 -Y 转：刀身上一点的速度方向 = 下 × 刀身)
func _kl_whirl_arms(p, t: float, drawn: bool) -> void:
	var cq: Quaternion = _chest_q(p)
	var g: Vector3
	var a_w: Vector3
	if drawn:
		var idle_w: Array = _kl_idle_wpn(p) if t < 0.26 else []
		var held: float = kf_f([[0.0, 0.0], [0.26, 1.0], [0.52, 1.0], [0.66, 0.0]], t)
		p.radd("Shoulder_R", 0.0, 27.0 * held, -7.0 * held)
		cq = _chest_q(p)
		var hold: Array = _kl_iai(p, kf_f([[0.0, 0.0], [0.50, 0.0], [0.58, 1.0, "o"]], t))
		if t < 0.50:
			# 低架 → 拔刀架势
			var gq: Array = _kl_to_iai(p, t / 0.26, idle_w, hold) if t < 0.26 else hold
			hold_bow(p, gq[0], gq[1], cq * Vector3(-1.0, -0.4, -0.25))
			fist_r(p, 85.0)
			hold_left(p, hold[2], hold[1], Vector3(1.0, -0.6, -0.1))
			fist_l(p, 76.0)
			return
		var ci: Basis = Basis(cq).inverse()
		var a0: Vector3 = ci * ((hold[1] as Quaternion) * Vector3.UP)
		var g0: Vector3 = p.gx[rig.ids["Chest"]].affine_inverse() * (hold[0] as Vector3) + rig.pos[rig.ids["Chest"]]
		# 拔刀：刀身从架势(左后)经左边、正前方划到右前方伸直 —— 按一个平滑的进度 u 走折线(中间垫左边 / 正前方两个方向，向量直接插值转大角度时中途会缩短)
		var al: Vector3
		var gl: Vector3
		if t < 0.76:
			var u: float = Lib.smooth((t - 0.50) / 0.26)
			al = kf_v([[0.0, a0], [0.35, Vector3(0.98, -0.14, 0.1), "l"], [0.65, Vector3(0.1, -0.12, 0.99), "l"], [1.0, Vector3(-0.82, -0.12, 0.56), "l"]], u)
			gl = kf_v([[0.0, g0], [0.35, Vector3(-1.0, 53.0, 18.0), "l"], [0.65, Vector3(-5.0, 54.5, 17.0), "l"], [1.0, Vector3(-14.5, 55.5, 15.0), "l"]], u)
		else:
			al = kf_v([[0.76, Vector3(-0.82, -0.12, 0.56)], [1.10, Vector3(-0.82, -0.14, 0.56)], [1.17, Vector3(-0.8, -0.3, -0.52), "o"],
				[1.30, Vector3(-0.78, -0.32, -0.5)], [1.45, Vector3(-0.6, -0.4, 0.68)]], t)
			gl = kf_v([[0.76, Vector3(-14.5, 55.5, 15.0)], [1.10, Vector3(-14.5, 55.0, 14.5)], [1.17, Vector3(-15.5, 55.0, 6.0), "o"],
				[1.30, Vector3(-15.0, 55.0, 6.5)], [1.45, Vector3(-8.0, 54.0, 12.0)]], t)
		al = al.normalized()
		g = follow(p, "Chest", gl)
		a_w = (cq * al).normalized()
		# 左手：架势里扣着鞘口，拔刀后往左后方张开配重
		var out: Vector3 = follow(p, "Chest", Vector3(18.0, 60.0, -5.0))
		var wl: float = kf_f([[0.52, 0.0], [0.64, 1.0]], t)
		var side_w0: Vector3 = Vector3.DOWN.cross(a_w)
		var q1: Quaternion = wrot(a_w, side_w0 if side_w0.length() > 0.2 else cq * Vector3.FORWARD)
		hold_bow(p, g, q1, cq * Vector3(-1.0, -0.4, -0.25))
		fist_r(p, 85.0)
		var base: Array[Quaternion] = p.rot.duplicate()
		hold_left(p, hold[2], hold[1], Vector3(1.0, -0.6, -0.1))
		fist_l(p, 76.0)
		if wl > 0.0:
			var at_hip: Array[Quaternion] = p.rot.duplicate()
			p.rot = base.duplicate()
			hold_left(p, out, cq * Lib.E(0.0, -20.0, 70.0), cq * Vector3(1.0, -0.25, 0.1))
			fist_l(p, 10.0)
			if wl < 1.0:
				for nm: String in ["Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L", "Fingers_L", "Thumb_L"]:
					var i: int = rig.ids[nm]
					p.rot[i] = at_hip[i].slerp(p.rot[i], wl)
				p.dirty = true
		return
	# 连鞘：右手把刀拖到右后方(蓄力) → 平平甩出去、手臂伸直 → 收
	var ext: float = kf_f([[0.0, 0.0], [0.40, 0.2], [0.62, 1.0, "i"], [1.18, 1.0], [1.42, 0.3]], t)
	var wind: float = kf_f([[0.0, 0.0], [0.40, 1.0, "o"], [0.50, 1.0], [0.64, 0.0]], t)
	var grip: Vector3 = HEAVY_GRIP.lerp(Vector3(-15.0, 60.0, 15.0), ext) + Vector3(-4.0, 1.0, -9.0) * wind
	var axis: Vector3 = Vector3(-0.3, -0.45, 0.84).lerp(Vector3(-0.86, 0.0, 0.52), ext).lerp(Vector3(-0.35, -0.12, -0.93), wind).normalized()
	a_w = (cq * axis).normalized()
	var engage: float = kf_f([[0.0, 0.0], [0.16, 1.0], [1.26, 1.0], [1.50, 0.0]], t)
	var side_w: Vector3 = Vector3.DOWN.cross(a_w)
	var q: Quaternion = _heavy_rot(a_w).slerp(wrot(a_w, side_w if side_w.length() > 0.2 else cq * Vector3.FORWARD), engage)
	g = follow(p, "Chest", grip)
	hold_bow(p, g, q, cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	# 左手：往左后方张开配重(掌心朝下)
	hold_left(p, follow(p, "Chest", Vector3(18.0, 61.0, -4.0)), cq * Lib.E(0.0, -20.0, 70.0), cq * Vector3(1.0, -0.25, 0.1))
	fist_l(p, 10.0)


# ---------------------------------------------------------------- 拔刀(36f = 1.2s)
## 0.00~0.28 把连鞘的刀收到左腰的拔刀架势(和出鞘普攻同一个架势：右手握柄、左拳扣着鞘口，鞘往左后方伸出去)，沉身低头 →
## 0.28~0.50 闭眼吸一口气，左手拇指把刀镡推开一点(鲤口を切る) → KL_SWAP 换网格(连鞘 → 出鞘：这时刀一动不动，
## 出鞘网格和连鞘网格的柄一模一样、刀身和鞘几乎重合，换的那一帧轮廓不变) → 0.50~0.60 右手顺着刀身往前慢慢抽出一截(左拳 = 鞘口，往后送)，睁眼 →
## 0.60~0.84 刀尖出鞘口，反手往前平平划出一道弧(越划越快、过了正前方再慢下来)，停在右前方(手臂伸直、刀身水平，右脚踏出) → 停一拍(残心) → 两手合握落成低架(= idle_heavy)
func _kl_draw(t: float, p) -> void:
	p.reset()
	var dur := KL_DRAW
	var breath: float = _arc(t, 0.24, 0.56, 1.0)
	var yaw: float = kf_f([[0.0, HEAVY_YAW], [0.28, 54.0], [0.50, 56.0], [0.60, 50.0], [0.86, -22.0], [0.96, -20.0], [1.12, HEAVY_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.28, 10.0], [0.50, 11.0], [0.60, 10.0], [0.84, 4.0], [0.96, 4.0], [1.12, 0.0]], t) - 2.5 * breath
	var drop: float = kf_f([[0.0, 0.0], [0.28, 4.5], [0.50, 5.0], [0.60, 5.0], [0.84, 3.0], [0.96, 3.0], [1.12, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.28, -1.0], [0.62, -1.0], [0.84, 3.0, "o"], [0.96, 3.0], [1.12, 0.0]], t)
	_kl_body(p, yaw, lean, push, drop, 0.0, kf_f([[0.0, 0.0], [0.28, 8.0], [0.50, 9.0], [0.64, -2.0, "o"], [0.96, -2.0], [dur, 0.0]], t))
	p.radd("Shoulder_L", 0.0, 0.0, -2.0 * breath)
	p.radd("Shoulder_R", 0.0, 0.0, 2.0 * breath)
	# 脚：架势里左脚往后撤一点；划出去那一下右脚往前踏一步，收势退回
	var rz: float = kf_f([[0.0, 3.0], [0.66, 3.0], [0.80, 8.0, "o"], [0.96, 8.0], [1.12, 3.0]], t)
	var lz: float = kf_f([[0.0, -3.0], [0.28, -4.5], [0.80, -4.5], [0.92, -3.0], [dur, -3.0]], t)
	_feet(p, 6.8, lz, _arc(t, 0.14, 0.28, 1.0) + _arc(t, 0.80, 0.92, 0.8), rz, _arc(t, 0.66, 0.80, 1.8) + _arc(t, 0.96, 1.12, 1.0),
		10.0 - 4.0 * Lib.smooth((t - 0.92) / 0.2), -6.0 - 10.0 * Lib.smooth((rz - 3.0) / 5.0))
	var two: float = kf_f([[0.0, 1.0], [0.18, 0.0], [0.96, 0.0], [1.12, 1.0]], t)
	_kl_blend_two(p, two, func(pp) -> void: _kl_draw_arms(pp, t))
	set_lids(p, kf_f([[0.0, 0.0], [0.22, 0.4], [0.34, 1.0], [0.52, 1.0], [0.60, 0.25, "o"], [0.96, 0.3], [1.08, 0.0], [dur, 0.0]], t))


func _kl_draw_arms(p, t: float) -> void:
	var idle_w: Array = _kl_idle_wpn(p) if t < 0.28 else []
	var held: float = kf_f([[0.0, 0.0], [0.28, 1.0], [0.60, 1.0], [0.77, 0.0, "i"]], t)
	p.radd("Shoulder_R", 0.0, 27.0 * held, -7.0 * held)
	var cq: Quaternion = _chest_q(p)
	var hold: Array = _kl_iai(p, kf_f([[0.0, 0.0], [0.52, 0.0], [0.64, 1.0, "o"]], t))
	var pull: float = kf_f([[0.0, 0.0], [0.38, 0.0], [0.44, 1.0], [0.50, 1.0], [0.60, 9.0, "i"]], t)      # 推开刀镡 → 顺着刀身往前抽
	var d_w: Vector3 = (hold[1] as Quaternion) * Vector3.UP
	if t < 0.28:
		var gq: Array = _kl_to_iai(p, t / 0.28, idle_w, hold)
		hold_bow(p, gq[0], gq[1], cq * Vector3(-1.0, -0.4, -0.25))
	elif t < 0.60:
		hold_bow(p, (hold[0] as Vector3) - d_w * pull, hold[1], cq * Vector3(-1.0, -0.4, -0.25))
	else:
		# 出鞘口：刀身方向 / 握点(胸腔局部)从架势划到右前方，刃口朝划动的方向(俯视顺时针：下 × 刀身)
		var ci: Basis = Basis(cq).inverse()
		var ci_x: Transform3D = p.gx[rig.ids["Chest"]].affine_inverse()
		var rp: Vector3 = rig.pos[rig.ids["Chest"]]
		var a0: Vector3 = ci * d_w
		var g0: Vector3 = ci_x * ((hold[0] as Vector3) - d_w * pull) + rp
		# (中间垫一个"指向左边"的关键帧：向量直接插值转 150° 时中途会缩短、角速度忽快忽慢)
		var al: Vector3 = kf_v([[0.60, a0], [0.69, Vector3(0.98, -0.12, 0.12), "i"], [0.745, Vector3(0.15, 0.0, 0.99), "l"], [0.86, Vector3(-0.84, 0.12, 0.53), "o"],
			[0.96, Vector3(-0.82, 0.1, 0.56)], [1.06, Vector3(-0.7, -0.15, 0.7)]], t).normalized()
		var gl: Vector3 = kf_v([[0.60, g0], [0.69, Vector3(-1.0, 54.0, 19.0), "i"], [0.745, Vector3(-5.0, 56.0, 17.5), "l"], [0.86, Vector3(-15.0, 58.0, 14.0), "o"],
			[0.96, Vector3(-14.5, 58.0, 14.5)], [1.06, Vector3(-9.0, 56.0, 14.0)]], t)
		var a_w: Vector3 = (cq * al).normalized()
		var sw: Vector3 = Vector3.DOWN.cross(a_w)
		hold_bow(p, follow(p, "Chest", gl), wrot(a_w, sw if sw.length() > 0.2 else cq * Vector3.FORWARD), cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	# 左手：扣着鞘口(刀身从拳里穿出去)，抽刀时把鞘往后送
	hold_left(p, hold[2], hold[1], Vector3(1.0, -0.6, -0.1))
	fist_l(p, 76.0)


# ---------------------------------------------------------------- 小动作(4.2s)：看着发作的诅咒手 → 屈伸手指、翻过来 → 攥拳 → 闭眼深呼吸 → 半睁眼
const G_KL_PALM := [Vector3(3.0, 61.5, 17.0), Vector3(1.0, -0.6, -0.2), Vector3(0.3, 0.35, 0.9), Vector3(0.0, 0.95, -0.3), 8.0]     # (右手)掌心朝上托在胸前
const G_KL_BACK := [Vector3(2.5, 62.5, 17.0), Vector3(1.0, -0.6, -0.2), Vector3(0.3, 0.45, 0.85), Vector3(0.0, -0.9, 0.35), 12.0]   # 翻过来看手背
const G_KL_FIST := [Vector3(6.0, 58.5, 13.5), Vector3(1.0, -0.6, -0.3), Vector3(0.2, 0.3, 0.95), Vector3(-0.6, 0.6, 0.2), 88.0]     # 慢慢攥成拳
const G_KL_GRAB := [Vector3(2.5, 58.5, 18.0), Vector3(1.0, -0.4, 0.4), Vector3(-0.95, 0.1, 0.25), Vector3(-0.2, 0.3, -0.3), 55.0]  # (左手)握住右手腕


func fidget_killer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.45, 1.0], [2.0, 1.0], [2.35, 0.0]], t)
	var calm: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.6, 1.0], [3.5, 1.0], [3.9, 0.0]], t)        # 闭眼深呼吸
	var br: float = kf_f([[0.0, 0.0], [2.3, 0.0], [2.9, 1.0], [3.7, 0.0]], t)                     # 吸 → 呼
	var shiver: float = kf_f([[0.0, 0.0], [0.7, 0.0], [0.8, 1.0], [1.0, 0.3], [1.35, 1.0], [1.55, 0.3], [1.8, 1.0], [2.0, 0.0]], t)
	var jit: float = shiver * sin(TAU * t * 9.0)
	_base(p, 0.35 * sin(t * 1.6), -0.6 * calm + 0.4 * br, 6.0 * look, 4.0 * look - 3.0 * br + 2.0 * calm, 3.0 * calm, 0.0, 6.5)
	p.r("Shoulder_L", 0.0, 0.0, -2.0 * br)
	p.r("Shoulder_R", 0.0, 0.0, 2.0 * br)
	_head(p, 13.0 * look - 5.0 * br + 6.0 * calm, -5.0 * look, 4.0 * look + 5.0 * calm * (1.0 - br))
	var curl: float = kf_f([[0.45, 8.0], [0.75, 70.0], [0.95, 62.0], [1.15, 12.0], [1.45, 80.0], [1.6, 74.0], [1.75, 20.0], [2.0, 88.0]], t)
	var palm: Array = G_KL_PALM.duplicate()
	palm[0] = (G_KL_PALM[0] as Vector3) + Vector3(0.0, 0.25 * jit, 0.0)
	var back: Array = G_KL_BACK.duplicate()
	back[0] = (G_KL_BACK[0] as Vector3) + Vector3(0.0, 0.25 * jit, 0.0)
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.45, palm], [1.15, palm], [1.4, back], [1.75, back], [2.0, G_KL_FIST], [2.4, G_RELAX], [4.2, G_RELAX]], t)
	if t > 0.45 and t < 2.0:
		p.r("Fingers_R", -curl - 6.0 * jit, 0, 22.0 * clampf(1.0 - curl / 60.0, 0.0, 1.0))
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.6, G_RELAX], [0.95, G_KL_GRAB], [1.9, G_KL_GRAB], [2.3, G_RELAX], [4.2, G_RELAX]], t)
	var lids: float = maxf(0.3 * look, calm)
	lids = minf(lids, kf_f([[0.0, 1.0], [3.5, 1.0], [3.75, 0.3], [4.0, 0.3], [4.2, 0.0]], t))
	set_lids(p, maxf(lids, blink_k(t, 0.5)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：侧过身、左手按着腰间的刀，低头半闭眼，慢慢吸气、长长地呼气
func victory_killer(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var th: float = TAU * ph / 2.4
	var br: float = kf_f([[0.0, 0.0], [0.8, 1.0], [2.4, 0.0]], ph)       # 吸气快、呼气慢
	_base(p, 0.5 * sin(th), 0.5 * br, 12.0, 3.0 - 3.0 * br, 2.0 * sin(th), -38.0, 6.5, 1.5)
	p.r("Shoulder_L", 0.0, 0.0, -2.5 * br)
	p.r("Shoulder_R", 0.0, 0.0, 2.5 * br)
	_head(p, 12.0 - 5.0 * br, 14.0, 5.0 + 2.5 * sin(th + 0.6))
	_left_on_saya(p, 0.3 * br)
	_hand_mix(p, "R", G_RELAX, G_RELAX, 0.0)
	set_lids(p, 0.45 + 0.3 * (1.0 - br))


# =============================================================== 奇兴节点(arcanist)：紫发龙角、灰色蝙蝠翼的骰子术士(2026-10-07)
## 模型 tools/chars/arcanist.gd(女性款)：紫色波波头、一对往后弯的灰色小龙角；背后一对灰色蝙蝠翼挂 Wing_L / Wing_R
## (翼根在背后肩胛，翼展往外往后斜 30°，和白羽节点的羽翼同一个角度 —— 直接用 _ag_wings，open / raise / tilt 的口径见 ANGEL_TABLE 一节)；
## 上臂以下是比人手粗一圈的灰色龙鳞手臂 + 龙爪手(手势离身体留宽一点)。赌徒法师：每隔几秒"掷 2d10"，随机一个效果砸到战场上。
## 能拿两个大类：法器(基础；书 / 宝珠在右手 = Bow 骨) / 长柄(双手；专属武器是骰子法杖 W_polearm_dice)。
## 本节的动作都自己控制翅膀(wing_custom)；首尾的翅膀 = 待机扑动在 t = 0 的姿势：_ag_wings(-10, 0, 0) = build_anims 的 fold 10°、flap 0。
##   roll_arcanist_<大类>(24f = 0.8s，不循环)：掷骰 —— 游戏在随机时刻用 play_once 放(跑动时也会放，所以脚踩着不动)；
##     首尾对齐女性款 idle_<大类> 的 t = 0(开头 2 帧从待机混进来、最后 0.2s 混回待机，_ar_roll)，放完 UnitView 从 t = 0 接回待机。
##     空着的左手攥着骰子抬到左肩前晃一晃(上身往右拧、往后靠、膝盖一沉蓄力)→ 往前一甩、爪子"啪"地张开(AR_REL = 0.30s 出手：
##     踮脚、上身往前送，蝙蝠翼猛地张开扬起)→ 手停在前方、低头看骰子落地、歪头半眯眼 → 手和翅膀慢慢收回待机。
##     法器：右手的书跟着身子走、出手时往上一托；长柄：左手松开杖、右手单手把杖竖起来(杖头朝天，上身从侧身枪架拧回来一点)，
##     出手那一下把杖往上一顶，之后杖放回枪架、左手重新握上(两手合握 ↔ 单手之间按手臂骨逐节 slerp，_ar_staff)。
## 小动作(收起武器，4.2s)：右爪摊开托着一颗骰子低头看、在掌心里滚两下 → 攥起来凑到嘴边"呼"地吹一口(闭眼、翅膀往里一收)
##   → 往上一抛(翅膀一扬)、仰头追着看 → 一把抄住，凑到眼前张开一条缝偷看 → 点数不好：摇头、肩膀一塌、翅膀耷拉下来
##   → 两手一摊耸耸肩、歪头(翅膀一抖)→ 放下手
## 胜利(收起武器，2.4s 循环，蹦两下)：中了头奖 —— 两只龙爪高高举成 V 字、爪子张开，蝙蝠翼全展、每蹦一下往下扇一下，
##   原地小蹦、落地一沉，两只手轮流往上一顶、头歪向那一边，仰着头开心地眯眼 + 第二下眨左眼
const ARC_TABLE := {"fidget_arcanist": [4.2, false], "victory_arcanist": [2.4, true]}
const AR_ROLL := 24.0 * F              # 掷骰
const AR_REL := 0.30                   # 骰子出手
const AR_IN := 2.0 * F                 # 开头从待机混进来
const AR_OUT := 0.2                    # 最后混回待机
# 掷骰的左手(胸腔局部，左手约定)：[手腕位置, 肘的朝向, 手指方向, 掌心方向, 手指弯曲]
# 法器 = 正面朝前；长柄 = 左肩在前的侧身(胸腔还朝右前方)，往前甩的方向在胸腔局部偏左
const G_AR_SHAKE := [Vector3(13.0, 66.0, 10.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.1, 0.5, 0.86), Vector3(-0.95, 0.2, 0.1), 82.0]   # 攥着骰子举在左肩前晃
const G_AR_COCK := [Vector3(15.5, 70.0, 5.5), Vector3(1.0, -0.5, -0.5), Vector3(0.05, 1.0, 0.15), Vector3(-0.2, 0.0, 1.0), 86.0]       # 往后上方一收(蓄力，掌心朝前)
const G_AR_THROW := [Vector3(14.5, 65.5, 15.5), Vector3(1.0, -0.7, -0.1), Vector3(0.35, 0.05, 0.94), Vector3(0.0, -1.0, 0.05), -6.0]  # 往前一甩、爪子张开(掌心朝下)
const G_AR_FOLLOW := [Vector3(14.5, 61.5, 15.0), Vector3(1.0, -0.5, -0.2), Vector3(0.3, -0.35, 0.88), Vector3(0.0, -0.9, -0.4), 4.0]    # 随挥：手往前下垂一点
const G_AR_THROW_P := [Vector3(17.5, 65.0, 13.5), Vector3(1.0, -0.6, -0.15), Vector3(0.55, -0.05, 0.84), Vector3(0.0, -1.0, 0.05), -6.0]
const G_AR_FOLLOW_P := [Vector3(16.0, 59.0, 13.0), Vector3(1.0, -0.5, -0.2), Vector3(0.5, -0.4, 0.77), Vector3(0.0, -0.9, -0.4), 4.0]
const G_AR_REGRIP := [Vector3(7.0, 58.5, 14.5), Vector3(0.7, -0.7, 0.0), Vector3(-0.81, -0.31, -0.5), Vector3(-0.54, 0.07, 0.84), 40.0]   # (长柄)刚松开 / 快握回去的左手：朝向 = 握在杖上的样子(idle_polearm 量出来的)，只是离杖一点、爪子半张
# 长柄单手竖杖(胸腔局部)：握点、杖头方向；出手时往上一顶
const AR_UP_GRIP := Vector3(-12.0, 58.0, 11.5)
const AR_MID_GRIP := Vector3(-9.5, 55.5, 11.5)          # 竖起 / 放下的途中：杖头先往前上方抬(从右前方绕上去，别横扫过脸)
const AR_MID_AXIS := Vector3(0.1, 0.55, 0.83)
const AR_UP_AXIS := Vector3(-0.08, 1.0, 0.12)
const AR_THRUST_GRIP := Vector3(-12.5, 64.0, 12.0)
const AR_THRUST_AXIS := Vector3(-0.05, 1.0, 0.06)
# 小动作 / 胜利的手势
const G_AF_PALM := [Vector3(7.0, 59.0, 13.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.25, 1.0), Vector3(0.0, 1.0, 0.0), 24.0]      # (右爪)摊开托着骰子
const G_AF_BLOW := [Vector3(3.0, 70.5, 16.5), Vector3(1.0, -0.4, -0.1), Vector3(-0.35, 0.6, 0.7), Vector3(0.0, 0.2, -1.0), 72.0]    # 攥着凑到嘴边(往前一点、肘往外：粗龙鳞上臂别擦着胸口)
const G_AF_PEEK := [Vector3(5.5, 64.5, 15.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.25, 0.4, 0.9), Vector3(0.0, 0.8, -0.55), 48.0]   # 凑到眼前、爪子张开一条缝
const G_AF_DROOP := [Vector3(14.5, 49.5, 3.5), Vector3(0.6, -0.2, -1.0), Vector3(0.05, -1.0, 0.2), Vector3(-1.0, 0.0, 0.1), 60.0]  # 攥着骰子垂下来(泄气)
const G_AF_SHRUG := [Vector3(19.5, 56.0, 8.5), Vector3(0.6, -0.6, -0.6), Vector3(0.75, 0.05, 0.65), Vector3(0.0, 1.0, 0.0), 10.0]  # 两手一摊、掌心朝上
const G_AV_UP := [Vector3(20.0, 77.0, 7.5), Vector3(1.0, -0.4, -0.4), Vector3(0.45, 0.85, 0.3), Vector3(-0.1, 0.1, 1.0), 20.0]       # 龙爪往外前上方高举成 V 字、爪子张开，掌心朝前(往前举一点：别和身后同色的翅膀叠在一起)     # 龙爪高举成 V 字、爪子张开，掌心朝前


func arcanist_table(t: Dictionary) -> void:
	for c: String in ["focus", "polearm"]:
		t["roll_arcanist_" + c] = {"dur": AR_ROLL, "loop": false, "fn": Callable(self, "_ar_roll").bind(c), "wing_custom": true}
	for nm: String in ARC_TABLE.keys():
		t[nm] = {"dur": float(ARC_TABLE[nm][0]), "loop": bool(ARC_TABLE[nm][1]), "fn": Callable(self, nm), "wing_custom": true}


## 掷骰：首尾对齐女性款 idle_<大类> 的 t = 0(开头 AR_IN 内从待机混进来，最后 AR_OUT 内混回待机；动作本身的首尾也摆在待机附近，混合只消掉残差)。
## 翅膀在混合之后单独摆(待机动作本身不碰翅膀骨，扑动是烘焙时叠上去的)
func _ar_roll(t: float, p, kit: String) -> void:
	var idle_fn := Callable(self, "idle_" + kit)
	var idle0 := func(pp) -> void: idle_fn.call(0.0, pp)
	var body := func(pp) -> void: _ar_roll_body(t, pp, kit)
	var w_out: float = Lib.smooth((t - (AR_ROLL - AR_OUT)) / AR_OUT)
	if w_out > 0.0:
		_pose_mix(p, body, idle0, w_out)
	elif t < AR_IN:
		_pose_mix(p, idle0, body, Lib.smooth(t / AR_IN))
	else:
		body.call(p)
	# 蓄力时往里一收 → 出手猛地张开扬起(下沿往前扣) → 慢慢收回待机的样子
	var w_open: float = kf_f([[0.0, -10.0], [0.17, -17.0], [0.31, 24.0, "o"], [0.44, 28.0], [0.8, -10.0]], t)
	var w_raise: float = kf_f([[0.0, 0.0], [0.17, -6.0], [0.31, 22.0, "o"], [0.42, 12.0], [0.58, 3.0], [0.8, 0.0]], t)
	var w_tilt: float = kf_f([[0.0, 0.0], [0.2, -5.0], [0.31, 10.0], [0.5, 2.0], [0.8, 0.0]], t)
	_ag_wings(p, w_open, w_raise, w_tilt)


## 身体：yaw 扭腰(正 = 右肩向前；长柄在侧身枪架 POLE_YAW 上再扭)、lean 前倾、drop 沉胯、roll 侧弯(正 = 往右弯)、tip 踮脚；
## hp / hy / hr = 头的 低头 / 向左看 / 向左歪(度)。静止量照女性款待机的 t = 0；脚踩在待机的位置(长柄 = 左脚在前)
func _ar_body(p, kit: String, yaw: float, lean: float, drop: float, roll: float, tip: float, hp: float, hy: float, hr: float) -> void:
	var yt: float = yaw + (POLE_YAW if kit == "polearm" else 0.0)
	p.move("Hips", Vector3(0.0, -1.7 - drop + 3.2 * tip, 0.0))
	p.r("Hips", lean * 0.35, yt * 0.35, roll * 0.3)
	p.r("Spine", -0.8 + lean * 0.3, yt * 0.3, roll * 0.3)
	p.r("Chest", 0.55 + lean * 0.35, yt * 0.35, roll * 0.4)
	p.r("Shoulder_L", 0.0, 0.0, -1.3)
	p.r("Shoulder_R", 0.0, 0.0, 1.3)
	p.r("Neck", hp * 0.3, hy * 0.3, hr * 0.3)
	p.r("Head", 1.0 + hp * 0.7, 1.95 - yt * 0.8 + hy * 0.7, 1.85 + hr * 0.7)
	var lead: float = POLE_LEAD if kit == "polearm" else 0.0
	legs(p, Vector3(6.5, ANKLE_Y + 3.4 * tip, -0.5 + lead), Vector3(-6.5, ANKLE_Y + 3.4 * tip, -0.5 - lead),
		Lib.E(32.0 * tip, 6.0, 0.0), Lib.E(32.0 * tip, -6.0, 0.0), -26.0 * tip, -26.0 * tip)


## 左手指的弯曲(覆盖 _hand_mix 插出来的值：甩出去之前一直攥紧，出手那一下"啪"地张开)
func _ar_curl(p, side: String, curl: float) -> void:
	var m: float = 1.0 if side == "L" else -1.0
	p.r("Fingers_" + side, -curl, 0, -22.0 * m * clampf(1.0 - curl / 60.0, 0.0, 1.0))
	p.r("Thumb_" + side, -10.0 - curl * 0.3, 0, 0)


func _ar_roll_body(t: float, p, kit: String) -> void:
	p.reset()
	var pole: bool = kit == "polearm"
	var drop: float = kf_f([[0.0, 0.0], [0.15, 1.3], [0.27, 0.5, "i"], [0.34, 0.0], [0.8, 0.0]], t)
	var tip: float = kf_f([[0.0, 0.0], [0.22, 0.0], [0.31, 0.4, "o"], [0.42, 0.4], [0.62, 0.0]], t)
	var yaw: float
	if pole:
		yaw = kf_f([[0.0, 0.0], [0.17, 24.0, "o"], [0.30, 12.0, "i"], [0.42, 13.0], [0.70, 0.0]], t)
	else:
		yaw = kf_f([[0.0, 0.0], [0.17, 10.0, "o"], [0.30, -12.0, "i"], [0.42, -10.0], [0.72, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.17, -5.0, "o"], [0.30, 7.0, "i"], [0.45, 5.0], [0.72, 0.0]], t)
	var roll: float = kf_f([[0.0, 0.0], [0.17, 3.0], [0.30, -3.0, "i"], [0.5, -2.0], [0.72, 0.0]], t)
	var hp: float = kf_f([[0.0, 0.0], [0.12, 6.0], [0.2, 3.0], [0.31, 9.0, "o"], [0.5, 12.0], [0.74, 0.0]], t)
	var hy: float = kf_f([[0.0, 0.0], [0.12, 16.0], [0.2, 13.0], [0.31, -3.0, "o"], [0.5, -5.0], [0.74, 0.0]], t)
	var hr: float = kf_f([[0.0, 0.0], [0.12, 8.0], [0.22, 5.0], [0.33, -6.0], [0.55, -9.0], [0.76, 0.0]], t)
	_ar_body(p, kit, yaw, lean, drop, roll, tip, hp, hy, hr)
	# 左手：攥着骰子晃一下(一个来回) → 往后上方一收 → 往前甩出去 → 随挥 → 收回(法器 = 垂手 / 长柄 = 回去握杖)
	var rat: float = 0.9 * sin(TAU * (t - 0.1) / 0.1) * kf_f([[0.0, 0.0], [0.1, 0.0], [0.13, 1.0], [0.17, 1.0], [0.2, 0.0]], t)
	var shake: Array = _rg_at(G_AR_SHAKE, Vector3(0.0, rat, 0.4 * rat))
	var keys_l: Array
	var curl: float
	if pole:
		# 松开杖的手(朝向 = 握杖的样子)和蓄力的拳掌心都朝前：直接转过去(绕掌心法线转)，不经过肩前晃骰子那一下(那样手腕要多拧一圈)
		keys_l = [[0.0, G_AR_REGRIP], [0.03, G_AR_REGRIP], [0.2, _rg_at(G_AR_COCK, Vector3(0.0, rat, 0.4 * rat))], [AR_REL, G_AR_THROW_P, "i"],
			[0.4, G_AR_FOLLOW_P, "o"], [0.62, G_AR_REGRIP], [0.8, G_AR_REGRIP]]
		curl = kf_f([[0.0, 60.0], [0.12, 82.0], [0.27, 86.0], [0.33, -8.0, "l"], [0.45, 0.0], [0.6, 40.0]], t)
	else:
		keys_l = [[0.0, G_RELAX], [0.12, shake], [0.2, G_AR_COCK], [AR_REL, G_AR_THROW, "i"], [0.4, G_AR_FOLLOW, "o"], [0.5, G_AR_FOLLOW],
			[0.78, G_RELAX]]
		curl = kf_f([[0.0, 14.0], [0.1, 82.0], [0.27, 86.0], [0.33, -8.0, "l"], [0.48, 0.0], [0.78, 14.0]], t)
	var left := func(pp) -> void:
		_hand_track(pp, "L", keys_l, t)
		_ar_curl(pp, "L", curl)
	if pole:
		# 杖：枪架 → 竖起来(杖头朝天) → 出手往上一顶 → 竖着 → 放回枪架；左手 0 ~ 0.1 松开，0.55 ~ 0.72 握回去
		var grip: Vector3 = kf_v([[0.0, POLE_GRIP], [0.09, AR_MID_GRIP, "o"], [0.18, AR_UP_GRIP], [0.26, AR_UP_GRIP + Vector3(0.0, -1.5, 0.0)],
			[0.31, AR_THRUST_GRIP, "o"], [0.42, AR_THRUST_GRIP], [0.46, AR_UP_GRIP], [0.53, AR_MID_GRIP], [0.61, POLE_GRIP]], t)
		var axis: Vector3 = kf_v([[0.0, POLE_AXIS], [0.09, AR_MID_AXIS], [0.18, AR_UP_AXIS], [0.26, AR_UP_AXIS], [0.31, AR_THRUST_AXIS, "o"],
			[0.42, AR_THRUST_AXIS], [0.46, AR_UP_AXIS], [0.53, AR_MID_AXIS], [0.61, POLE_AXIS]], t)
		var w_two: float = kf_f([[0.0, 1.0], [0.1, 0.0], [0.55, 0.0], [0.72, 1.0]], t)
		_ar_staff(p, grip, axis, w_two, left)
	else:
		# 书跟着胸腔走，出手时往上一托(书面朝上一翻)
		var lift: float = _arc(t, 0.22, 0.52, 1.0)
		var cq: Quaternion = _chest_q(p)
		hold_bow(p, follow(p, "Chest", FOCUS_GRIP + Vector3(-0.5, 2.5, 1.0) * lift), cq * grot(FOCUS_AIM.lerp(Vector3(0.3, 0.3, 1.0), lift), Vector3(0.0, 1.0, 0.15)),
			Vector3(-1.0, -0.5, -0.4))
		fist_r(p, 70.0)
		left.call(p)
	# 眼：晃骰子时眯着 → 出手睁大 → 看着骰子落地半眯(得意) → 睁开
	set_lids(p, kf_f([[0.0, 0.0], [0.1, 0.3], [0.22, 0.3], [0.29, 0.0], [0.38, 0.0], [0.48, 0.35], [0.62, 0.35], [0.74, 0.0]], t))


## 长柄：w_two = 1 两手合握(_hold_pole，和待机同一套 two_hand)，0 = 右手单手握杖、左手由 left 摆；中间按手臂骨逐节 slerp
func _ar_staff(p, grip: Vector3, axis: Vector3, w_two: float, left: Callable) -> void:
	var base: Array[Quaternion] = p.rot.duplicate()
	var rot_one: Array[Quaternion] = base
	if w_two < 1.0:
		hold_bow(p, follow(p, "Chest", grip), _pole_rot(_chest_dir(p, axis)), Vector3(-1.0, -0.5, -0.3))
		fist_r(p, 84.0)
		left.call(p)
		rot_one = p.rot.duplicate()
	if w_two > 0.0:
		p.rot = base.duplicate()
		p.dirty = true
		_hold_pole(p, grip, axis)
		if w_two < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = rot_one[i].slerp(p.rot[i], w_two)
			p.dirty = true


# ---------------------------------------------------------------- 小动作(4.2s)：掌心滚骰子 → 凑到嘴边吹一口 → 往上一抛、抄住 → 偷看 → 摇头泄气 → 两手一摊
func fidget_arcanist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var look: float = kf_f([[0.0, 0.0], [0.45, 1.0], [1.15, 1.0], [1.45, 0.0]], t)          # 低头看掌心的骰子
	var blow: float = kf_f([[0.0, 0.0], [1.2, 0.0], [1.45, 1.0], [1.75, 1.0], [1.92, 0.0]], t)
	var puff: float = _arc(t, 1.48, 1.74, 1.0)                                                # "呼"地吹一口
	var up: float = kf_f([[0.0, 0.0], [1.95, 0.0], [2.2, 1.0, "o"], [2.45, 0.0, "i"]], t)     # 仰头追着骰子
	var catch: float = kf_f([[0.0, 0.0], [2.43, 0.0], [2.47, 1.0, "o"], [2.7, 0.0]], t)       # 抄住那一顿
	var peek: float = kf_f([[0.0, 0.0], [2.55, 0.0], [2.85, 1.0], [3.05, 1.0], [3.2, 0.0]], t)
	var sad: float = kf_f([[0.0, 0.0], [3.0, 0.0], [3.2, 1.0], [3.5, 1.0], [3.72, 0.0]], t)
	var no: float = sin(TAU * (t - 3.12) * 3.2) * kf_f([[0.0, 0.0], [3.08, 0.0], [3.18, 1.0], [3.42, 1.0], [3.56, 0.0]], t)   # 摇头
	var shrug: float = kf_f([[0.0, 0.0], [3.5, 0.0], [3.75, 1.0, "o"], [3.92, 1.0], [4.2, 0.0]], t)
	_base(p, 0.4 * sin(t * 1.7), -0.8 * catch - 1.2 * sad + 0.4 * shrug + 0.5 * puff, -5.0 * look + 3.0 * blow - 2.0 * peek,
		5.0 * look + 3.0 * blow - 2.0 * puff - 3.0 * up + 6.0 * peek + 5.0 * sad - 2.0 * shrug, 2.0 * shrug, 0.0, 6.5)
	p.r("Shoulder_L", 0.0, 0.0, -1.3 - 5.0 * sad + 10.0 * shrug + 3.0 * puff)
	p.r("Shoulder_R", 0.0, 0.0, 1.3 + 5.0 * sad - 10.0 * shrug - 3.0 * puff)
	_head(p, 16.0 * look + 7.0 * blow + 3.0 * puff - 28.0 * up + 5.0 * catch + 20.0 * peek + 14.0 * sad - 5.0 * shrug,
		-8.0 * look - 4.0 * blow - 3.0 * peek + 14.0 * no,
		5.0 * look * sin(TAU * (t - 0.45) / 0.7) - 4.0 * sad + 12.0 * shrug)
	# 右爪：摊开托着骰子(在掌心里滚：手画小圈、手指一张一合)→ 攥起来凑到嘴边 → 往下一沉、往上一抛 → 张着等 → 抄住 → 凑到眼前偷看
	#   → 泄气地垂下来 → 两手一摊 → 放下
	var w: float = TAU * (t - 0.45) / 0.35
	var roll_k: float = kf_f([[0.0, 0.0], [0.5, 0.0], [0.6, 1.0], [1.05, 1.0], [1.15, 0.0]], t)
	var palm: Array = _rg_at(G_AF_PALM, Vector3(0.7 * sin(w), 0.5 * cos(w), 0.0) * roll_k)
	var blow_g: Array = _rg_at(G_AF_BLOW, Vector3(0.0, 0.0, 0.6) * puff)
	var ready_hi: Array = _rg_at(G_RG_READY, Vector3(0.0, 1.2, 0.0))
	_hand_keys(p, "R", [[0.0, G_RELAX], [0.45, palm], [1.15, palm], [1.45, G_AF_BLOW], [1.75, blow_g], [1.9, G_RG_COIN], [1.98, G_RG_FLICK],
		[2.08, G_RG_FLICK], [2.3, G_RG_READY], [2.42, ready_hi], [2.47, G_RG_CATCH], [2.85, G_AF_PEEK], [3.05, G_AF_PEEK], [3.25, G_AF_DROOP],
		[3.5, G_AF_DROOP], [3.75, G_AF_SHRUG], [3.92, G_AF_SHRUG], [4.2, G_RELAX]], t)
	if roll_k > 0.0:
		_ar_curl(p, "R", 24.0 + 34.0 * (0.5 - 0.5 * cos(w)) * roll_k)
	# 拇指：抛之前扣紧 → 一弹 → 松开
	p.radd("Thumb_R", kf_f([[0.0, 0.0], [1.88, 0.0], [1.94, -18.0], [1.98, 30.0, "l"], [2.15, 0.0]], t), 0.0, 0.0)
	_hand_keys(p, "L", [[0.0, G_RELAX], [3.5, G_RELAX], [3.75, G_AF_SHRUG], [3.92, G_AF_SHRUG], [4.2, G_RELAX]], t)
	# 翅膀：平时照待机那样轻轻扑(首尾 = 待机 t = 0 的姿势) → 吹的时候往里收 → 抛的时候一扬 → 泄气耷拉下来 → 耸肩时一抖
	var env: float = 1.0 - Lib.smooth((t - 3.85) / 0.35)
	var fl: float = sin(TAU * 1.25 * t) * env * (1.0 - 0.7 * maxf(blow, sad))
	var toss: float = _arc(t, 1.95, 2.4, 1.0)
	var flick: float = _arc(t, 3.55, 4.05, 1.0)
	_ag_wings(p, -10.0 - 12.0 * fl - 9.0 * blow + 9.0 * toss - 7.0 * sad + 20.0 * flick, 5.0 * fl + 14.0 * toss - 18.0 * sad + 12.0 * flick, -6.0 * sad + 5.0 * flick)
	var shut: float = kf_f([[0.0, 0.0], [1.3, 0.0], [1.42, 1.0], [1.78, 1.0], [1.88, 0.0]], t)     # 吹的时候闭眼
	set_lids(p, maxf(maxf(shut, 0.3 * look), maxf(maxf(0.4 * peek, 0.55 * sad), blink_k(t, 3.95))))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：龙爪高举成 V 字，原地蹦两下(两手轮流往上一顶)，翅膀全展每蹦一下扇一下
func victory_arcanist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var u: float = fposmod(t / 1.2, 1.0)                      # 每 1.2s 蹦一下、扇一下
	var hop: float = _arc(u, 0.18, 0.6, 3.2)
	var crouch: float = kf_f([[0.0, 0.5], [0.1, 1.0], [0.2, 0.0, "o"], [0.6, 0.0], [0.68, 1.0, "o"], [0.85, 0.3], [1.0, 0.5]], u)
	var pump_l: float = _arc(ph, 0.12, 0.72, 1.0)
	var pump_r: float = _arc(ph, 1.32, 1.92, 1.0)
	var th: float = TAU * ph / 2.4
	_base(p, 0.6 * sin(th), hop - 1.6 * crouch, 3.0 * sin(th), -5.0 - 1.5 * hop / 3.2 + 3.0 * crouch, 4.0 * (pump_r - pump_l), 0.0, 6.5)
	legs(p, Vector3(6.5, ANKLE_Y + hop, -0.5), Vector3(-6.5, ANKLE_Y + hop, -0.5), Lib.E(10.0 * hop / 3.2, 6.0, 0.0), Lib.E(10.0 * hop / 3.2, -6.0, 0.0))
	p.r("Shoulder_L", 0.0, 0.0, 3.0 + 4.0 * pump_l)
	p.r("Shoulder_R", 0.0, 0.0, -3.0 - 4.0 * pump_r)
	_head(p, -10.0 - 3.0 * hop / 3.2 + 3.0 * crouch, 5.0 * sin(th), 7.0 * (pump_l - pump_r) + 1.5 * sin(2.0 * th))
	var dip := Vector3(0.0, -1.0 * crouch, 0.0)
	var gl: Array = _rg_at(G_AV_UP, dip + Vector3(0.3, 1.8, 0.3) * pump_l)
	var gr: Array = _rg_at(G_AV_UP, dip + Vector3(0.3, 1.8, 0.3) * pump_r)
	_hand_mix(p, "L", gl, gl, 0.0)
	_hand_mix(p, "R", gr, gr, 0.0)
	_ar_curl(p, "L", 20.0 + 30.0 * pump_l)
	_ar_curl(p, "R", 20.0 + 30.0 * pump_r)
	# 翅膀全展：起跳时往下扑(托着她蹦起来) → 慢慢抬回
	var w_raise: float = kf_f([[0.0, 26.0], [0.16, 30.0], [0.45, -12.0, "o"], [1.0, 26.0]], u)
	var w_open: float = kf_f([[0.0, 34.0], [0.45, 44.0], [1.0, 34.0]], u)
	var w_tilt: float = kf_f([[0.0, -6.0], [0.25, 12.0], [0.45, 4.0], [0.75, -8.0], [1.0, -6.0]], u)
	_ag_wings(p, w_open, w_raise, w_tilt)
	if ph > 1.35 and ph < 1.9:
		_wink(p, "L")
	else:
		set_lids(p, 0.5)


# =============================================================== 锁芯节点(keeper)：绿发尖耳、蛇尾、黑金暗绿法袍的蛇系钥匙守护者(2026-10-08)
## 模型 tools/chars/keeper.gd(女性款，没有翅膀)：墨绿喇叭垂袖(手势离身体留宽一点)；一条粗壮的蛇尾挂 BTail 链 —— 从腰后垂到地面、
## 往左后方卷一个大弯再翘起来。蛇尾是弹簧骨(build_anims 的 BTail 链，world_hold 0.7：每节只有约 3 成的主动转角传到尾巴上)：
## 沿用 _dr_tail 给每节一个"主动"摆角，摆幅给得比想看到的大；只左右摆、不抬(尾巴贴着地：一抬，地上那段就压进地里 / 翘到半空)。
## 正 = 往左甩 —— 卷起来的尾梢在左后方，往左甩会把它扫向左腿 / 裙片，所以摆动的中心往右偏一点。
## 专属武器是巨大的钥匙「开与闭」(W_polearm_key)，动作里收起；手势里"捏着"的是一把看不见的小钥匙(拇指和食指)。坏笑、自信的施法者：
## 小动作(收起武器，4.0s)：左手叉腰、胯往左一顶；右手抬到胸前掌心朝上，手指"啪"地一张 —— 变出一把小钥匙 → 捏起来举到脸旁，
##   手腕来回转两下(歪头看着它、半眯眼)→ 往后一收、再往前一插(上身跟着往前送)→ 手腕一拧"咔哒"(身子一顿、蛇尾一甩)
##   → 歪头坏笑、眨左眼 → 拔出来往肩上一抛、手一张(没了)→ 放下手
## 胜利(收起武器，2.4s 循环)：左手叉腰、胯往左顶着轻轻扭；右手捏着钥匙举在头侧亮一亮(手腕转一转)→ 往前一插、一拧"咔哒"开锁
##   (身子一顿、眨左眼)→ 再举回头侧；蛇尾得意地左右摆
const KEEPER_TABLE := {"fidget_keeper": [4.0, false], "victory_keeper": [2.4, true]}
# 手势(左手约定的胸腔局部量，右手自动镜像)：[手腕位置, 肘的朝向, 手指方向, 掌心方向, 手指弯曲]
const G_KP_PALM := [Vector3(10.0, 56.5, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.25, 1.0), Vector3(0.0, 1.0, 0.0), 28.0]     # 掌心朝上摊在胸前
const G_KP_POOF := [Vector3(10.0, 58.0, 14.5), Vector3(1.0, -0.6, -0.3), Vector3(-0.15, 0.45, 0.9), Vector3(0.0, 1.0, -0.3), -8.0]   # 手指"啪"地一张(变出钥匙)
const G_KP_PINCH := [Vector3(10.0, 57.5, 14.0), Vector3(1.0, -0.6, -0.3), Vector3(-0.2, 0.35, 0.95), Vector3(-0.3, 0.9, -0.2), 62.0]  # 捏起来
const G_KP_SHOW := [Vector3(16.0, 69.5, 9.0), Vector3(1.0, -0.5, -0.5), Vector3(0.1, 0.95, 0.3), Vector3(-0.9, 0.0, 0.4), 66.0]    # 捏着举到脸旁外侧(手指朝上、掌心朝里，别挡脸)
const G_KP_COCK := [Vector3(13.0, 61.0, 7.5), Vector3(1.0, -0.3, -0.7), Vector3(-0.1, 0.05, 1.0), Vector3(-1.0, 0.0, 0.0), 72.0]    # 往后一收(拳在胸侧，手指朝前)
const G_KP_INSERT := [Vector3(6.5, 62.5, 17.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0), 72.0]   # 往前一插(钥匙竖着：掌心朝里)
const G_KP_TURN := [Vector3(6.5, 62.5, 17.5), Vector3(1.0, -0.6, -0.2), Vector3(-0.2, 0.0, 1.0), Vector3(0.0, -1.0, 0.0), 72.0]     # 一拧(前臂内旋，掌心转到朝下)
const G_KP_FLIP := [Vector3(14.5, 71.5, 9.0), Vector3(1.0, -0.5, -0.5), Vector3(0.05, 1.0, 0.25), Vector3(-0.4, 0.0, 0.9), 40.0]    # 拔出来往肩上一抛
const G_KV_UP := [Vector3(18.5, 78.5, 6.5), Vector3(1.0, -0.4, -0.5), Vector3(0.1, 1.0, 0.15), Vector3(-0.35, 0.0, 1.0), 66.0]     # (胜利)捏着钥匙举在头侧
const G_KP_HIP := [Vector3(13.6, 51.0, 0.5), Vector3(1.0, 0.1, -0.7), Vector3(-0.2, -0.6, -1.0), Vector3(-1.0, 0.0, 0.0), 30.0]      # 叉腰(比 G_HIP 往外前一点：手腕别陷进腰带)


func keeper_table(t: Dictionary) -> void:
	for nm: String in KEEPER_TABLE.keys():
		t[nm] = {"dur": float(KEEPER_TABLE[nm][0]), "loop": bool(KEEPER_TABLE[nm][1]), "fn": Callable(self, nm)}


## 手势绕手指方向转 deg 度(手腕来回拧：转钥匙)
static func _kp_twist(g: Array, deg: float) -> Array:
	var r: Array = g.duplicate()
	r[3] = Basis((g[2] as Vector3).normalized(), deg_to_rad(deg)) * (g[3] as Vector3)
	return r


# ---------------------------------------------------------------- 小动作(4.0s)：变出钥匙 → 举到脸旁转两下 → 一收一插 → 一拧"咔哒" → 坏笑眨眼 → 往肩上一抛
func fidget_keeper(t: float, p) -> void:
	p.reset()
	_stow(p)
	var hip: float = kf_f([[0.0, 0.0], [0.45, 1.0], [3.2, 1.0], [3.8, 0.0]], t)                  # 左手叉腰、胯往左顶
	var click: float = _arc(t, 1.9, 2.1, 1.0)                                                    # "咔哒"那一顿
	var thrust: float = kf_f([[0.0, 0.0], [1.5, 0.0], [1.72, 1.0], [2.0, 0.0]], t)               # 往前一插：重心往前(右)带一下
	var yaw: float = kf_f([[0.0, 0.0], [0.4, -4.0], [1.3, -4.0], [1.52, -11.0, "o"], [1.72, 9.0, "i"], [2.55, 7.0], [3.0, -3.0], [3.85, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.4, 3.0], [0.85, -2.0], [1.3, -2.0], [1.52, -4.0], [1.72, 6.0, "i"], [2.0, 5.0], [2.55, 4.0], [3.0, -3.0],
		[3.85, 0.0]], t)
	var roll: float = kf_f([[0.0, 0.0], [0.85, -3.0], [1.3, -3.0], [1.72, 0.0], [2.05, 4.0], [2.6, 4.0], [3.85, 0.0]], t)
	_base(p, 1.4 * hip - 0.8 * thrust, -0.7 * click, yaw, lean + 2.0 * click, roll, 0.0, 6.5 + 0.5 * hip)
	# 头：低头看掌心 → 歪头看着脸旁的钥匙 → 看着往前插的手 → "咔哒"之后往左一歪(坏笑) → 看一眼抛到肩上的钥匙 → 回正
	_head(p, kf_f([[0.0, 0.0], [0.4, 14.0], [0.62, 12.0], [0.85, 2.0], [1.3, 2.0], [1.52, 4.0], [1.75, 6.0], [2.0, 3.0], [2.6, 3.0], [2.95, -4.0],
			[3.2, -3.0], [3.9, 0.0]], t) + 3.0 * click,
		kf_f([[0.0, 0.0], [0.4, -14.0], [0.85, -20.0], [1.3, -20.0], [1.52, -6.0], [1.75, -2.0], [2.05, 4.0], [2.6, 4.0], [2.95, -12.0], [3.2, -8.0],
			[3.9, 0.0]], t),
		kf_f([[0.0, 0.0], [0.4, 4.0], [0.85, -10.0], [1.3, -10.0], [1.52, 0.0], [1.95, 0.0], [2.15, 13.0, "o"], [2.6, 13.0], [2.95, 4.0], [3.9, 0.0]], t))
	# 右手：掌心朝上 → 一张(变出来) → 捏起 → 举到脸旁转两下 → 往后一收 → 往前一插 → 一拧(咔哒那一下往下一压) → 拔出来 → 往肩上一抛、手一张 → 放下
	var tw: float = 42.0 * sin(TAU * (t - 0.85) / 0.225) if (t > 0.85 and t < 1.3) else 0.0
	var show_tw: Array = _kp_twist(G_KP_SHOW, tw)
	var turn: Array = _rg_at(G_KP_TURN, Vector3(0.0, -0.6, 0.6) * click)
	var pull: Array = _rg_at(G_KP_TURN, Vector3(2.0, 1.5, -5.0))
	var flip_open: Array = G_KP_FLIP.duplicate()
	flip_open[4] = -8.0
	_hand_track(p, "R", [[0.0, G_RELAX], [0.4, G_KP_PALM], [0.5, G_KP_POOF, "o"], [0.62, G_KP_PINCH], [0.85, show_tw], [1.3, show_tw],
		[1.52, G_KP_COCK, "o"], [1.72, G_KP_INSERT, "i"], [1.8, G_KP_INSERT], [1.95, turn, "o"], [2.55, turn], [2.78, pull], [3.0, G_KP_FLIP, "o"],
		[3.15, flip_open], [3.85, G_RELAX]], t)
	_hand_keys(p, "L", [[0.0, G_RELAX], [0.45, G_KP_HIP], [3.2, G_KP_HIP], [3.8, G_RELAX]], t)
	# 蛇尾：慢慢地游动着摆(首尾收到 0 = 待机)，"咔哒"那一下往右一甩再弹回
	var env: float = kf_f([[0.0, 0.0], [0.5, 1.0], [3.3, 1.0], [4.0, 0.0]], t)
	var flick: float = kf_f([[0.0, 0.0], [1.9, 0.0], [2.05, -34.0, "o"], [2.35, 14.0], [2.65, -5.0], [2.95, 0.0]], t)
	_dr_tail(p, TAU * t / 1.6, 14.0 * env, flick - 6.0 * env, 0.0)
	# 眼：一直半眯着(坏笑)，"咔哒"时眯一下，歪头时眨左眼，最后眨一下眼
	if t > 2.15 and t < 2.6:
		_wink(p, "L")
	else:
		set_lids(p, maxf(maxf(0.3 * kf_f([[0.0, 0.0], [0.4, 1.0], [3.5, 1.0], [3.8, 0.0]], t), 0.5 * click), blink_k(t, 3.62)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：钥匙举在头侧亮一亮 → 往前一插、一拧"咔哒"开锁 → 举回来；叉腰扭胯、摇蛇尾
func victory_keeper(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var th: float = TAU * ph / 2.4
	var fwd: float = kf_f([[0.0, 0.0], [0.3, 0.0], [0.62, 1.0, "i"], [1.35, 1.0], [1.75, 0.0], [2.4, 0.0]], ph)     # 0 = 举在头侧，1 = 往前插着
	var click: float = _arc(ph, 0.84, 1.02, 1.0)
	_base(p, 1.8 + 0.7 * sin(th), 0.4 * sin(2.0 * th) - 0.7 * click, 3.0 + 7.0 * fwd, -4.0 + 5.0 * fwd + 2.0 * click, 3.0 + 2.0 * sin(th), 0.0, 7.0, 1.0)
	_head(p, lerpf(-8.0, 3.0, fwd) + 2.0 * click, lerpf(-10.0, -3.0, fwd) + 3.0 * sin(th), 8.0 + 3.0 * sin(th) + 4.0 * click)
	# 右手：举在头侧时手腕来回转一下(亮一亮钥匙；跨过循环接缝那一段)
	var u: float = fposmod(ph - 1.75, 2.4)
	var tw: float = 24.0 * sin(TAU * u / 0.95) if u < 0.95 else 0.0
	var up: Array = _kp_twist(_rg_at(G_KV_UP, Vector3(0.0, 0.6 * sin(2.0 * th), 0.0)), tw)
	var turn: Array = _rg_at(G_KP_TURN, Vector3(0.0, -0.6, 0.6) * click)
	_hand_track(p, "R", [[0.0, up], [0.3, up], [0.62, G_KP_INSERT, "i"], [0.7, G_KP_INSERT], [0.86, turn, "o"], [1.35, turn], [1.75, up], [2.4, up]], ph)
	_hand_mix(p, "L", G_KP_HIP, G_KP_HIP, 0.0)
	_dr_tail(p, 2.0 * th, 16.0, -6.0 + 24.0 * sin(th), 0.0)
	if ph > 0.9 and ph < 1.4:
		_wink(p, "L")
	else:
		set_lids(p, 0.35)


# =============================================================== 蓝之章的机械造物：哨戒炮台(固定：Hips 底座不动 + Chest 炮塔)、场域载具(悬浮：整体挂 Hips + Chest 小炮塔)
## 普攻的时长 / 出手时刻和武器大类一致：炮台 = 步枪 20f / 0.10 s，载具 = 手弩 18f / 0.20 s。待机 / 跑步照例也烘男性款 *_m。
const BLUE_TABLE := {
	"idle_turret": [2.4, true], "run_turret": [2.4, true], "attack_turret": [20.0 * F, false],
	"idle_hover": [2.4, true], "run_hover": [18.0 * F, true], "attack_hover": [18.0 * F, false],
	"fidget_turret_sentry": [3.0, false], "victory_turret_sentry": [2.4, true],
	"fidget_vehicle_field": [3.2, false], "victory_vehicle_field": [2.4, true],
	"fidget_droid_assault": [3.6, false], "victory_droid_assault": [2.4, true],
	"fidget_droid_relay": [3.6, false], "victory_droid_relay": [2.4, true],
	"broadcast_droid_relay": [0.8, false],
}


func blue_table(t: Dictionary) -> void:
	for nm: String in BLUE_TABLE.keys():
		t[nm] = {"dur": float(BLUE_TABLE[nm][0]), "loop": bool(BLUE_TABLE[nm][1]), "fn": Callable(self, nm)}


## 炮台待机(2.4s 循环)：底座不动，炮塔一段一段地扫视——转过去、停住、炮口点一下(锁定)、再转回来，像在搜索目标
func idle_turret(t: float, p) -> void:
	p.reset()
	var yaw: float = kf_f([[0.0, 0.0], [0.45, 14.0, "o"], [0.95, 14.0], [1.45, -12.0, "o"], [1.95, -12.0], [2.4, 0.0, "o"]], t)
	var nod: float = _arc(t, 0.5, 0.75, 1.0) + _arc(t, 1.5, 1.75, 1.0)
	p.r("Chest", -3.0 * nod, yaw, 0.0)
	p.move("Chest", Vector3(0.0, 0.3 * nod, 0.0))


func run_turret(t: float, p) -> void:
	idle_turret(t, p)


## 炮台开火(20f)：出手(0.10 s)后炮塔往后一坐、抬一下，再回来
func attack_turret(t: float, p) -> void:
	p.reset()
	var kick: float = kf_f([[0.0, 0.0], [0.06, -0.15], [0.10, 0.0], [0.13, 1.0, "o"], [0.30, 0.2], [0.45, -0.05], [20.0 * F, 0.0]], t)
	var jit: float = 1.5 * sin(t * 90.0) * maxf(0.0, kick)
	p.move("Chest", Vector3(0.0, 0.6 * kick, -4.0 * kick))
	p.r("Chest", -7.0 * kick, jit, 0.0)
	p.move("Hips", Vector3(0.0, -0.4 * maxf(0.0, kick), 0.0))


## 载具待机：悬浮起伏，轻轻摇晃；车顶的炮塔慢慢左右扫
func idle_hover(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / 2.4
	p.move("Hips", Vector3(0.0, 1.2 * sin(th), 0.0))
	p.r("Hips", 1.5 * sin(th * 0.5 + 1.0), 0.0, 1.5 * sin(th))
	p.r("Chest", 0.0, 18.0 * sin(th), 0.0)


## 载具行驶(18f 循环)：车头压低往前冲，快速的小起伏
func run_hover(t: float, p) -> void:
	p.reset()
	var th: float = TAU * t / (18.0 * F)
	p.move("Hips", Vector3(0.0, 0.8 * sin(th * 2.0), 0.0))
	p.r("Hips", -6.0, 0.0, 2.0 * sin(th))


## 载具开火(18f)：出手(0.20 s)后车顶炮塔后坐、整车往后一沉
func attack_hover(t: float, p) -> void:
	p.reset()
	var kick: float = kf_f([[0.0, 0.0], [0.20, 0.0], [0.23, 1.0, "o"], [0.36, 0.0], [18.0 * F, 0.0]], t)
	p.move("Chest", Vector3(0.0, 0.0, -2.0 * kick))
	p.move("Hips", Vector3(0.0, 0.5 * kick, -0.8 * kick))
	p.r("Hips", 2.0 * kick, 0.0, 0.0)


# ---------------------------------------------------------------- 四台机器的待机小动作 / 胜利(武器照例收起；机器没有眼皮，不眨眼)
## 炮台自检(3.0s)：炮塔猛地甩向左、停住、再甩向右，最后回正时炮口抬起点一下头
func fidget_turret_sentry(t: float, p) -> void:
	p.reset()
	_stow(p)
	var yaw: float = kf_f([[0.0, 0.0], [0.25, 38.0, "o"], [0.9, 38.0], [1.15, -38.0, "o"], [1.8, -38.0], [2.2, 0.0, "o"], [3.0, 0.0]], t)
	var nod: float = kf_f([[0.0, 0.0], [2.2, 0.0], [2.45, 1.0, "o"], [2.75, 0.0], [3.0, 0.0]], t)
	p.r("Chest", -14.0 * nod, yaw, 0.0)
	p.move("Chest", Vector3(0.0, 1.0 * nod, 0.0))


## 炮台胜利(2.4s 循环)：炮口高高抬起，炮塔左右转着"庆祝"，炮塔一颤一颤地往上顶
func victory_turret_sentry(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	p.r("Chest", -26.0 - 4.0 * sin(th * 2.0), 24.0 * sin(th), 0.0)
	p.move("Chest", Vector3(0.0, 1.5 + 1.0 * absf(sin(th * 2.0)), 0.0))


## 载具自检(3.2s)：车头先压一下，车顶炮塔整整转一圈，车身跟着往炮口那侧侧倾，最后浮回来
func fidget_vehicle_field(t: float, p) -> void:
	p.reset()
	_stow(p)
	var dip: float = kf_f([[0.0, 0.0], [0.35, 1.0, "o"], [0.9, 0.0], [3.2, 0.0]], t)
	var spin: float = kf_f([[0.0, 0.0], [0.8, 0.0], [2.3, 360.0], [3.2, 360.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.8, 0.0], [1.2, 1.0], [2.0, 1.0], [2.5, 0.0], [3.2, 0.0]], t)
	p.move("Hips", Vector3(0.0, 1.2 * sin(TAU * t / 2.4) - 1.5 * dip, 0.0))
	p.r("Hips", -7.0 * dip, 0.0, 3.0 * lean * sin(deg_to_rad(spin)))
	p.r("Chest", 0.0, spin, 0.0)


## 载具胜利(2.4s 循环)：浮得更高、一跳一跳，车顶炮塔左右摆，车身跟着摇
func victory_vehicle_field(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	p.move("Hips", Vector3(0.0, 3.0 + 1.6 * sin(th * 2.0), 0.0))
	p.r("Hips", -3.0 * sin(th * 2.0), 0.0, 5.0 * sin(th))
	p.r("Chest", -8.0, 30.0 * sin(th), 0.0)


## 中继广播(0.8s，BattleView 在它给队友挂增幅链路时放)：两臂往外上方展开、掌心朝上，上身挺起、仰头(天线对着天)，再收回待机
const G_RELAY_UP := [Vector3(19.0, 70.0, 6.0), Vector3(1.0, -0.5, -0.4), Vector3(0.6, 0.6, 0.4), Vector3(0.0, 1.0, 0.2), 10.0]


func broadcast_droid_relay(t: float, p) -> void:
	p.reset()
	var up: float = kf_f([[0.0, 0.0], [0.26, 1.0], [0.5, 1.0], [0.8, 0.0]], t)
	_base(p, 0.0, -0.6 * up, 0.0, -6.0 * up, 0.0, 0.0, 6.5)
	_head(p, -14.0 * up, 0.0, 0.0)
	_hand_mix(p, "L", G_RELAX, G_RELAY_UP, up)
	_hand_mix(p, "R", G_RELAX, G_RELAY_UP, up)
	p.scale_("Bow", Vector3.ONE * 0.001)


# 突击仿生人：把右臂的刃举到面罩前检视(翻两下手腕)、左手握拳；胜利 = 双拳交替往上顶
const G_DA_CHECK := [Vector3(7.0, 66.0, 15.0), Vector3(1.0, -0.3, -0.3), Vector3(0.0, 1.0, 0.25), Vector3(-1.0, 0.0, 0.0), 75.0]


func fidget_droid_assault(t: float, p) -> void:
	p.reset()
	_stow(p)
	var raise: float = kf_f([[0.0, 0.0], [0.5, 1.0, "o"], [2.6, 1.0], [3.2, 0.0], [3.6, 0.0]], t)
	var twist: float = kf_f([[0.0, 0.0], [0.9, 0.0], [1.3, 1.0], [1.7, 0.0], [2.1, 1.0], [2.5, 0.0], [3.6, 0.0]], t)
	var roll: float = kf_f([[0.0, 0.0], [2.8, 0.0], [3.1, 1.0], [3.5, 0.0], [3.6, 0.0]], t)
	_base(p, 0.3 * sin(t * 1.4), -0.4 * roll, 6.0 * raise, 2.0 * raise, 0.0, 0.0, 7.0)
	_head(p, 8.0 * raise, -10.0 * raise, -4.0 * twist)
	var chk: Array = G_DA_CHECK.duplicate()
	chk[3] = Vector3(-1.0, 0.0, 0.0).lerp(Vector3(0.0, 0.0, -1.0), twist)
	_hand_mix(p, "R", G_RELAX, chk, raise)
	_hand_mix(p, "L", G_RELAX, G_FIST, raise * 0.6)
	p.r("Shoulder_L", 0.0, 0.0, 6.0 * roll)
	p.r("Shoulder_R", 0.0, 0.0, -6.0 * roll)


func victory_droid_assault(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	var pump_r: float = 0.5 + 0.5 * sin(th * 2.0)
	var pump_l: float = 0.5 - 0.5 * sin(th * 2.0)
	_base(p, 0.6 * sin(th), 1.0 * absf(sin(th * 2.0)), 5.0 * sin(th), -5.0, 0.0, 0.0, 8.0)
	_head(p, -10.0, 4.0 * sin(th), 0.0)
	var up_r: Array = G_FIST_UP.duplicate()
	up_r[0] = (G_FIST_UP[0] as Vector3) + Vector3(0.0, 3.0 * pump_r, 0.0)
	var up_l: Array = G_FIST_UP.duplicate()
	up_l[0] = (G_FIST_UP[0] as Vector3) + Vector3(0.0, 3.0 * pump_l, 0.0)
	_hand_mix(p, "R", up_r, up_r, 0.0)
	_hand_mix(p, "L", up_l, up_l, 0.0)


# 增幅中继：两只掌心发射器张开到身侧校准(头跟着左右扫)；胜利 = 双掌举过头顶托着信号
const G_RX_EMIT := [Vector3(19.0, 64.0, 9.0), Vector3(0.6, -0.5, -0.6), Vector3(0.3, 1.0, 0.2), Vector3(0.3, 0.0, 1.0), 10.0]
const G_RX_UP := [Vector3(9.0, 84.0, 8.0), Vector3(1.0, -0.2, -0.5), Vector3(0.1, 1.0, 0.1), Vector3(0.0, 0.0, 1.0), 10.0]


func fidget_droid_relay(t: float, p) -> void:
	p.reset()
	_stow(p)
	var open: float = kf_f([[0.0, 0.0], [0.6, 1.0, "o"], [2.7, 1.0], [3.3, 0.0], [3.6, 0.0]], t)
	var scan: float = sin(TAU * (t - 0.6) / 1.4) * kf_f([[0.0, 0.0], [0.6, 0.0], [0.9, 1.0], [2.4, 1.0], [2.8, 0.0], [3.6, 0.0]], t)
	_base(p, 0.3 * sin(t * 1.5), 0.5 * open, 0.0, -4.0 * open, 0.0, 0.0, 6.5)
	_head(p, -6.0 * open, 10.0 * scan, 8.0 * scan)
	_hand_mix(p, "L", G_RELAX, G_RX_EMIT, open)
	_hand_mix(p, "R", G_RELAX, G_RX_EMIT, open)


func victory_droid_relay(t: float, p) -> void:
	p.reset()
	_stow(p)
	var th: float = TAU * t / 2.4
	_base(p, 0.4 * sin(th), 0.8 * sin(th * 2.0), 0.0, -5.0, 0.0, 0.0, 7.0, 0.0, 0.3 + 0.3 * sin(th * 2.0))
	_head(p, -14.0 + 3.0 * sin(th * 2.0), 0.0, 5.0 * sin(th))
	var up: Array = G_RX_UP.duplicate()
	up[0] = (G_RX_UP[0] as Vector3) + Vector3(1.5 * sin(th), 1.5 * sin(th * 2.0), 0.0)
	_hand_mix(p, "L", up, up, 0.0)
	_hand_mix(p, "R", up, up, 0.0)



# =============================================================== 变奏节点(pianist 恶魔形态 / pianist_angel 天使形态)：站在大三角钢琴后面弹(2026-10-08)
## 模型 tools/chars/pianist.gd / pianist_angel.gd(女性款，同一副身体；翅膀挂 Wing_L/R)。她本人的专属法器「黑键 / 白键」是一台大三角钢琴
## (tools/model_weapons.gd 的 grand_piano：W_focus_grand / W_focus_grand_white)，整台刚性挂在 Root 上、放在她身前，所以她拿它时
## 用这里的三个动作代替 idle / run / attack_focus(数据：anim_overrides["focus@grand"] / ["focus@grand_white"])：
##   · 手钉在琴键上(_pn_key：模型坐标跟着 Root 走，再换算成胸腔局部)，手腕在琴键前沿上方、手指往前下搭在白键上；
##     Bow 骨不缩(钢琴不在 Bow 上，手里也没有别的东西)
##   · 待机(3.2s)：轻轻地弹 —— 左手低音一小节(0.8s)一个和弦、在几个把位之间挪，右手每拍一个音(和左手错开半拍)、手腕跟着旋律慢慢移、
##     左右轻轻转，身子随着节奏左右摆(1.6s 一个来回)、一小节点一下头，半垂着眼
##   · 普攻(27f = 0.9s，出手 0.36s，同法器大类)：吸一口气，双手从琴键上高高抬起(踮脚、后仰、抬头，翅膀往后收) → 0.36s 重重砸下一个大和弦
##     (双手张得比平时宽，身子往前一扑、沉胯、低头闭眼，翅膀猛地一张) → 余音里手腕弹一下 → 回到待机 t = 0 的姿势；翅膀自己控制(wing_custom)
##   · 移动(20f)：她和钢琴一起离地悬浮着滑行(Root 抬起 2~3 格、一起一伏)，翅膀扇得快；双脚垂着、脚尖朝下，往后收(不碰琴身)；
##     手一直搭在琴键上轻轻弹
## 小动作 / 胜利照规矩收起武器(缩 Bow / Weapon_L / Shield)；钢琴挂在 Root 上收不起来，所以"空气钢琴"的手位就是琴键的位置(拿着大钢琴时就是真的在弹)：
##   小动作(4.0s)：手搭上琴键，右手一串往高音滑的琶音、左手颤音，身子大幅摇摆、闭眼陶醉 → 双手抬起、砸下最后一个和弦
##     → 右手按在心口、左手往外摊开，屈膝行礼谢幕(右脚往后撤半步) → 起身、眨左眼 → 手放下
##   胜利(2.4s 循环)：左手往外摊开(向观众介绍)，右手从心口往头侧一扬"噔噔！"(眨左眼) → 收回心口、屈膝行礼 → 起身
##   两个身体共用一套：fidget_pianist_angel / victory_pianist_angel 是同一个函数换个名字登记(char_anim 按身体模型名找)
const PIANIST_TABLE := {
	"idle_pianist_play": [3.2, true], "run_pianist_play": [20.0 * F, true], "attack_pianist_play": [27.0 * F, false],
	"fidget_pianist": [4.0, false], "victory_pianist": [2.4, true],
}
const PN_IDLE := 3.2
const PN_RUN := 20.0 * F
const PN_ATK := 27.0 * F                                   # = GC.WEAPON_CLASSES["focus"] 的 interval
const PN_REL := 0.36                                       # = 法器的出手时刻(windup)
const PN_WRIST_Y := Wpn.GRAND_KEY_Y + 4.5                  # 弹琴时手腕的高度(模型坐标)：手指往前下搭到白键面上
const PN_WRIST_Z := Wpn.GRAND_KEY_Z0 - 0.5                 # 手腕在琴键前沿稍前(再往里会贴到肚子)，指尖落在琴键中后段
const PN_POLE := Vector3(1.0, -0.25, -0.55)                # 肘往外、往后(左手约定，右手自动镜像)
const PN_FING := Vector3(0.05, -0.5, 1.0)                  # 手指往前下
const PN_PALM := Vector3(0.0, -1.0, 0.0)                   # 掌心朝下
## 手势(胸腔局部，左手约定)：[手腕位置, 肘的朝向, 手指方向, 掌心方向, 手指弯曲]
const G_PN_LIFT := [Vector3(10.5, 65.5, 11.5), Vector3(1.0, -0.4, -0.45), Vector3(0.05, -0.8, 0.6), Vector3(0.0, -1.0, 0.2), 14.0]   # 双手高高抬起(手腕领着，手指垂着)
const G_PN_LIFT2 := [Vector3(11.0, 67.0, 11.0), Vector3(1.0, -0.4, -0.45), Vector3(0.05, -0.85, 0.5), Vector3(0.0, -1.0, 0.25), 10.0]  # 抬到顶(一顿)
const G_PN_OPEN := [Vector3(22.5, 61.0, 10.0), Vector3(0.6, -0.8, -0.3), Vector3(0.8, 0.05, 0.6), Vector3(0.0, 0.9, 0.4), 8.0]       # 往外摊开、掌心朝上(介绍)
const G_PN_TADA := [Vector3(19.5, 79.5, 6.0), Vector3(1.0, -0.3, -0.5), Vector3(0.2, 1.0, 0.15), Vector3(0.0, 0.15, 1.0), 4.0]      # 扬到头侧、掌心朝前"噔噔！"
const G_PN_TURN := [Vector3(16.0, 58.5, 11.5), Vector3(0.8, -0.6, -0.3), Vector3(0.45, -0.1, 0.9), Vector3(-1.0, 0.0, 0.2), 14.0]    # 从琴键上翻到"摊开"的途中(掌心朝里：手掌分两段翻过来)


func pianist_table(t: Dictionary) -> void:
	for nm: String in PIANIST_TABLE.keys():
		t[nm] = {"dur": float(PIANIST_TABLE[nm][0]), "loop": bool(PIANIST_TABLE[nm][1]), "fn": Callable(self, nm)}
	t["attack_pianist_play"]["wing_custom"] = true          # 砸和弦时翅膀猛地一张
	t["run_pianist_play"]["wing_hz"] = 3.0                  # 悬浮滑行：翅膀扇得快(20f 里两下)
	t["run_pianist_play"]["wing_amp"] = 1.5
	t["victory_pianist"]["wing_hz"] = 2.5
	# 天使形态(pianist_angel)：同一套小动作 / 胜利，换个名字登记
	t["fidget_pianist_angel"] = (t["fidget_pianist"] as Dictionary).duplicate()
	t["victory_pianist_angel"] = (t["victory_pianist"] as Dictionary).duplicate()


## 一只手搭在琴键上：kx = 手腕的 x(模型坐标；左手 > 0、右手 < 0)，dip = 往下按的深度，curl = 手指弯曲，roll = 手腕绕手指方向转(度)，dz = 前后挪。
## 钢琴挂在 Root 上：琴键的位置跟着 Root 走，再换算成"此刻胸腔姿态下的静止坐标"(_pf_on_chair)；返回 _hand_mix 用的手势(左手约定)
func _pn_key(p, side: String, kx: float, dip: float = 0.0, curl: float = 30.0, roll: float = 0.0, dz: float = 0.0) -> Array:
	var m: float = 1.0 if side == "L" else -1.0
	var loc: Vector3 = _pf_on_chair(p, follow(p, "Root", Vector3(kx, PN_WRIST_Y - dip, PN_WRIST_Z + dz)))
	var g: Array = [Vector3(loc.x * m, loc.y, loc.z), PN_POLE, PN_FING, PN_PALM, curl]
	return _kp_twist(g, roll) if roll != 0.0 else g


## 按键的力度包络：u = 离按下那一刻的时间；rise 秒按到底、fall 秒松开(都是平滑的)
static func _pn_press(u: float, rise: float = 0.05, fall: float = 0.25) -> float:
	if u < 0.0 or u > rise + fall:
		return 0.0
	if u < rise:
		return Lib.smooth(u / rise)
	return 1.0 - Lib.smooth((u - rise) / fall)


## 站在琴后弹琴的身子(th = 待机相位)：随着节奏左右摆(1.6s)、一小节(0.8s)往前送一下、点头；再叠加 lean / bob / head / tip / roll
func _pn_stand(p, th: float, lean: float = 0.0, bob: float = 0.0, head: float = 0.0, tip: float = 0.0, roll: float = 0.0, lead: float = 0.0) -> void:
	var s2: float = sin(2.0 * th)
	var beat: float = 0.5 - 0.5 * cos(4.0 * th)
	_base(p, 0.7 * s2, -0.3 * beat + bob, 3.0 * sin(2.0 * th + 0.6), 5.0 + 1.2 * beat + lean, 1.5 * s2 + roll, 0.0, 6.0, lead, tip)
	_head(p, 4.0 + 2.5 * sin(4.0 * th + 0.9) + head, 4.0 * sin(2.0 * th + 0.3), 4.5 * sin(2.0 * th + 0.5))     # 只微微低头：俯视镜头里还看得见脸
	p.move("Halo", Vector3(0.0, 0.9 * sin(2.0 * th), 0.0))
	p.r("Halo", 2.0 * sin(th), 0.0, 2.5 * sin(2.0 * th + 0.7))


## 待机时两只手的手势(t = 待机时间)：[左手, 右手]。左手低音：每小节(0.8s)一个和弦 + 半小节一个轻音，把位 9 → 11 → 9.5 → 7.5；
## 右手旋律：和左手错开半拍(0.2s 起)每拍(0.4s)一个音，手腕慢慢移、每个音左右转一下
func _pn_idle_hands(p, t: float) -> Array:
	var lx: float = kf_f([[0.0, 9.0], [0.55, 9.0], [0.75, 11.0], [1.35, 11.0], [1.55, 9.5], [2.15, 9.5], [2.35, 7.5], [2.95, 7.5], [3.15, 9.0], [3.2, 9.0]], t)
	var rx: float = kf_f([[0.0, -7.0], [0.3, -7.0], [0.75, -9.0], [1.1, -9.0], [1.55, -6.5], [1.9, -6.5], [2.35, -8.5], [2.7, -8.5], [3.15, -7.0], [3.2, -7.0]], t)
	var pl: float = _pn_press(fposmod(t, 0.8)) + 0.4 * _pn_press(fposmod(t - 0.4, 0.8))
	var pr: float = _pn_press(fposmod(t - 0.2, 0.4), 0.04, 0.22)
	var gl: Array = _pn_key(p, "L", lx, 1.3 * pl, 28.0 + 16.0 * pl)
	var gr: Array = _pn_key(p, "R", rx, 0.8 * pr, 30.0 + 14.0 * pr, 7.0 * sin(TAU * t / 0.8))
	return [gl, gr]


## 翅膀(和 build_anims 的待机扑动同一个口径：fold = 往后收的角度，flap = 上下扇)；fold 10、flap 0 = 待机扑动在 t = 0 的样子
func _pn_wings(p, fold: float, flap: float) -> void:
	p.rq("Wing_L", Quaternion(Vector3.UP, deg_to_rad(fold)) * Quaternion(Vector3.BACK, deg_to_rad(flap)))
	p.rq("Wing_R", Quaternion(Vector3.UP, deg_to_rad(-fold)) * Quaternion(Vector3.BACK, deg_to_rad(-flap)))


# ---------------------------------------------------------------- 待机(3.2s 循环)：轻轻地弹
func idle_pianist_play(t: float, p) -> void:
	p.reset()
	_pn_stand(p, TAU * t / PN_IDLE)
	var g: Array = _pn_idle_hands(p, fposmod(t, PN_IDLE))
	_hand_mix(p, "L", g[0], g[0], 0.0)
	_hand_mix(p, "R", g[1], g[1], 0.0)
	set_lids(p, maxf(0.25, blink_k(fposmod(t, PN_IDLE), 2.05)))


# ---------------------------------------------------------------- 普攻(27f = 0.9s，出手 0.36s)：双手高高抬起 → 重重砸下一个和弦 → 回待机
func attack_pianist_play(t: float, p) -> void:
	p.reset()
	var up: float = kf_f([[0.0, 0.0], [0.22, 1.0, "o"], [0.30, 1.0], [PN_REL, 0.0, "i"]], t)
	var hit: float = kf_f([[0.0, 0.0], [0.30, 0.0], [PN_REL, 1.0, "i"], [0.52, 0.85], [PN_ATK, 0.0]], t)
	var bounce: float = _arc(t, PN_REL + 0.02, 0.48, 1.0)
	_pn_stand(p, 0.0, -7.0 * up + 9.0 * hit, 0.8 * up - 1.6 * hit, -14.0 * up + 9.0 * hit, 0.35 * up)
	p.r("Shoulder_L", 0.0, 0.0, 5.0 * up - 3.0 * hit)
	p.r("Shoulder_R", 0.0, 0.0, -5.0 * up + 3.0 * hit)
	p.move("Halo", Vector3(0.0, 1.2 * up - 0.8 * hit, 0.0))
	var g0: Array = _pn_idle_hands(p, 0.0)
	var sl: Array = _pn_key(p, "L", 11.5, 1.6 - 0.9 * bounce, 58.0)
	var sr: Array = _pn_key(p, "R", -10.5, 1.6 - 0.9 * bounce, 58.0)
	_hand_track(p, "L", [[0.0, g0[0]], [0.22, G_PN_LIFT, "o"], [0.30, G_PN_LIFT2], [PN_REL, sl, "l"], [0.56, sl], [PN_ATK, g0[0]]], t)
	_hand_track(p, "R", [[0.0, g0[1]], [0.22, G_PN_LIFT, "o"], [0.30, G_PN_LIFT2], [PN_REL, sr, "l"], [0.56, sr], [PN_ATK, g0[1]]], t)
	# 翅膀：抬手时往后收 → 砸下去猛地一张(往前、往上扇) → 慢慢回到待机扑动的起点
	_pn_wings(p, kf_f([[0.0, 10.0], [0.22, 22.0], [0.30, 24.0], [0.40, -24.0, "o"], [0.56, -18.0], [PN_ATK, 10.0]], t),
		kf_f([[0.0, 0.0], [0.22, -5.0], [0.30, -6.0], [0.40, 12.0, "o"], [0.56, 8.0], [PN_ATK, 0.0]], t))
	set_lids(p, kf_f([[0.0, 0.25], [0.22, 0.0], [0.33, 0.0], [0.38, 1.0], [0.56, 1.0], [0.7, 0.25], [PN_ATK, 0.25]], t))


# ---------------------------------------------------------------- 移动(20f 循环)：和钢琴一起悬浮着滑行
func run_pianist_play(t: float, p) -> void:
	p.reset()
	var u: float = fposmod(t, PN_RUN)
	var th: float = TAU * u / PN_RUN
	var lift: float = 2.6 + 0.7 * sin(th)
	p.move("Root", Vector3(0.0, lift, 0.0))
	var lean: float = 7.0 + 1.0 * sin(th + 0.8)
	p.move("Hips", Vector3(0.4 * sin(th), -1.2 + 0.4 * sin(th + 0.6), 0.0))
	p.r("Hips", lean * 0.3, 0.0, 0.5 * sin(th))
	p.r("Spine", lean * 0.3, 2.0 * sin(th), 1.5 * sin(th))
	p.r("Chest", lean * 0.4, 2.0 * sin(th), 1.0 * sin(th))
	_head(p, 4.0 - 1.5 * sin(th + 1.0), 0.0, 2.0 * sin(th))
	# 双脚垂着、脚尖朝下，往后收；两脚一高一低轻轻晃
	var sw: float = sin(th)
	legs(p, Vector3(5.0, ANKLE_Y + lift + 4.5 + 0.8 * sw, -2.0 - 1.0 * sw), Vector3(-5.0, ANKLE_Y + lift + 5.5 - 0.8 * sw, -3.0 + 1.0 * sw),
		Lib.E(32.0, 5.0, 0.0), Lib.E(38.0, -5.0, 0.0), 8.0, 8.0)
	# 手：搭在琴键上轻轻弹(右手两下、左手一下)
	var pr: float = _pn_press(fposmod(u, PN_RUN * 0.5), 0.04, 0.2)
	var pl: float = _pn_press(fposmod(u - 0.1, PN_RUN), 0.05, 0.3)
	var gl: Array = _pn_key(p, "L", 9.0, 1.0 * pl, 28.0 + 14.0 * pl)
	var gr: Array = _pn_key(p, "R", -7.5, 0.7 * pr, 30.0 + 12.0 * pr, 6.0 * sin(th))
	_hand_mix(p, "L", gl, gl, 0.0)
	_hand_mix(p, "R", gr, gr, 0.0)
	p.move("Halo", Vector3(0.0, 0.8 * sin(th - 0.8), 0.0))
	p.r("Halo", 3.0 * sin(th), 0.0, 2.0 * sin(th + 0.5))
	set_lids(p, 0.2)


# ---------------------------------------------------------------- 小动作(4.0s)：琶音 + 颤音陶醉 → 砸下最后一个和弦 → 右手按心口、左手摊开，屈膝谢幕 → 眨眼
func fidget_pianist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var play: float = kf_f([[0.0, 0.0], [0.4, 1.0], [2.2, 1.0], [2.55, 0.0]], t)
	var rock: float = sin(TAU * (t - 0.45) / 1.05) * kf_f([[0.0, 0.0], [0.45, 0.0], [0.7, 1.0], [1.35, 1.0], [1.6, 0.0]], t)
	var up: float = kf_f([[0.0, 0.0], [1.5, 0.0], [1.68, 1.0, "o"], [1.76, 1.0], [1.84, 0.0, "i"]], t)
	var hit: float = kf_f([[0.0, 0.0], [1.76, 0.0], [1.84, 1.0, "i"], [2.2, 0.6], [2.5, 0.0]], t)
	var bow: float = kf_f([[0.0, 0.0], [2.45, 0.0], [2.85, 1.0, "o"], [3.2, 1.0], [3.6, 0.0]], t)
	_base(p, 1.2 * rock, -0.5 * play - 1.4 * hit - 2.0 * bow + 0.6 * up, 5.0 * rock, 4.0 * play - 6.0 * up + 8.0 * hit + 18.0 * bow, 6.0 * rock, 0.0,
		6.0, 2.5 * bow, 0.3 * up)
	_head(p, 8.0 * play - 12.0 * up + 8.0 * hit + 16.0 * bow, 7.0 * rock - 6.0 * bow, 9.0 * rock + 6.0 * bow)
	var th: float = TAU * t / PN_IDLE
	p.move("Halo", Vector3(0.0, 0.9 * sin(2.0 * th), 0.0))
	# 右手：琴键上一串往高音(右)滑的琶音(0.5 → 1.0s)、再弹回来 → 抬起、砸下 → 按在心口 → 放下
	var rx: float = kf_f([[0.0, -7.0], [0.5, -6.5], [1.0, -16.0, "i"], [1.25, -7.5, "o"], [1.84, -10.5]], t)
	var rp: float = _pn_press(fposmod(t - 0.5, 0.125), 0.03, 0.08) if (t > 0.5 and t < 1.0) else _pn_press(fposmod(t - 1.25, 0.2), 0.04, 0.14)
	var kr: Array = _pn_key(p, "R", rx, 0.6 * rp + 1.6 * hit, 22.0 + 20.0 * rp + 30.0 * hit, 10.0 * sin(TAU * t / 0.25))
	# 左手：颤音(两个把位快速交替) → 抬起、砸下 → 往外摊开 → 放下
	var lp: float = _pn_press(fposmod(t - 0.45, 0.16), 0.03, 0.1)
	var kl: Array = _pn_key(p, "L", 9.0 + 2.5 * hit, 0.8 * lp + 1.6 * hit, 26.0 + 18.0 * lp + 30.0 * hit, 12.0 * sin(TAU * (t - 0.45) / 0.32))
	_hand_track(p, "R", [[0.0, G_RELAX], [0.4, kr], [1.5, kr], [1.68, G_PN_LIFT, "o"], [1.76, G_PN_LIFT2], [1.84, kr, "l"], [2.2, kr],
		[2.6, G_PF_HEART], [3.3, G_PF_HEART], [3.75, G_RELAX]], t)
	_hand_track(p, "L", [[0.0, G_RELAX], [0.4, kl], [1.5, kl], [1.68, G_PN_LIFT, "o"], [1.76, G_PN_LIFT2], [1.84, kl, "l"], [2.2, kl],
		[2.42, G_PN_TURN], [2.65, G_PN_OPEN], [3.3, G_PN_OPEN], [3.75, G_RELAX]], t)
	if t > 3.3 and t < 3.6:
		_wink(p, "L")
	else:
		set_lids(p, maxf(kf_f([[0.0, 0.0], [0.55, 0.0], [0.75, 1.0], [1.45, 1.0], [1.6, 0.0], [1.84, 0.0], [1.88, 1.0], [2.1, 1.0], [2.3, 0.0],
			[2.6, 0.0], [2.85, 0.6], [3.2, 0.6], [3.3, 0.0]], t), blink_k(t, 3.75)))


# ---------------------------------------------------------------- 胜利(2.4s 循环)：右手从心口往头侧一扬"噔噔！" → 收回心口、屈膝行礼 → 起身
func victory_pianist(t: float, p) -> void:
	p.reset()
	_stow(p)
	var ph: float = fposmod(t, 2.4)
	var th: float = TAU * ph / 2.4
	var tada: float = kf_f([[0.0, 0.0], [0.45, 1.0, "o"], [1.15, 1.0], [1.45, 0.0], [2.4, 0.0]], ph)
	var bow: float = kf_f([[0.0, 0.0], [1.4, 0.0], [1.75, 1.0, "o"], [2.05, 1.0], [2.4, 0.0]], ph)
	_base(p, 0.8 * sin(th), 0.5 * sin(2.0 * th) * tada - 1.8 * bow, 5.0 * tada, -5.0 * tada + 17.0 * bow, 3.0 * tada, 0.0, 6.0, 2.5 * bow)
	_head(p, -7.0 * tada + 15.0 * bow, 8.0 * tada, 7.0 * tada + 3.0 * sin(th))
	p.move("Halo", Vector3(0.0, 1.0 * sin(2.0 * th), 0.0))
	var td: Array = _kp_twist(G_PN_TADA, 14.0 * sin(TAU * ph / 0.35) * kf_f([[0.0, 0.0], [0.45, 0.0], [0.55, 1.0], [1.0, 1.0], [1.1, 0.0]], ph))
	_hand_track(p, "R", [[0.0, G_PF_HEART], [0.45, td], [1.15, td], [1.45, G_PF_HEART], [2.4, G_PF_HEART]], ph)
	var op: Array = _rg_at(G_PN_OPEN, Vector3(0.0, 1.0 * sin(th), 0.0))
	_hand_mix(p, "L", op, op, 0.0)
	if ph > 0.55 and ph < 1.05:
		_wink(p, "L")
	else:
		set_lids(p, maxf(0.5 * bow, blink_k(ph, 2.2)))
