class_name BattleReport
extends RefCounted
## 详细战报(逻辑层，不依赖场景树)：Battle.fx 的每个伤害 / 治疗 / 护盾 / 阵亡事件都记一笔——
## 谁、用哪个来源(普攻 / 被动 / 武器效果 / 羁绊 / 地形…)、什么伤害类型、打到谁、暴击没有、
## 被护盾吸收多少、被护甲 / 魔抗 / 减伤挡掉多少、过量治疗多少；再加上击杀与阵亡时刻。
## 结算界面(ReportPanel)按单位 / 来源 / 目标汇总显示；来源的名字由界面层按 (单位, surface, ability, equip) 去查文本。

const KINDS: Array[String] = ["physical", "magic", "true"]

var rows: Dictionary = {}        # uid -> 单位一行(见 _row)
var order: Array[String] = []    # 出场顺序(界面排序的兜底)


## 来源键：普攻都算一个来源("na")；其余按 surface + 能力 + 装备区分
static func source_key(surface: String, ability: String, equip: String) -> String:
	if surface == "normal_attack":
		return "na"
	return "%s|%s|%s" % [surface, ability.get_slice("#", 0), equip]


func _row(u: BUnit) -> Dictionary:
	if not rows.has(u.uid):
		order.append(u.uid)
		rows[u.uid] = {"uid": u.uid, "def": u.def.id, "team": u.team, "star": u.star, "summon": u.is_summon,
			"dealt": 0.0, "dealt_kind": {}, "dealt_cat": {}, "hits": 0, "crits": 0,
			"taken": 0.0, "taken_kind": {}, "taken_cat": {}, "absorbed": 0.0, "mitigated": 0.0, "hp_lost": 0.0,
			"heal": 0.0, "overheal": 0.0, "healed": 0.0,
			"shield": 0.0, "shielded": 0.0,
			"kills": 0, "death": -1.0, "alive": true, "hp": 0.0, "max_hp": 1.0,
			"src": {},        # 来源键 -> {surface, ability, equip, dmg, kind{}, hits, crits, heal, over, shield}
			"to": {},         # 目标 uid -> {dmg, kind{}, heal, shield}
			"from": {},       # 攻击者 uid("" = 没有施加者：地形、战场机制) -> {dmg, kind{}}
			"from_src": {},   # 攻击者 uid + 来源键 -> {uid, def, surface, ability, equip, dmg, kind{}, hits}
			"heal_from": {},  # 治疗者 uid -> 治疗量
		}
	return rows[u.uid]


static func _src_entry(r: Dictionary, e: Dictionary) -> Dictionary:
	var surface: String = str(e.get("surface", ""))
	var ability: String = str(e.get("ability", "")).get_slice("#", 0)     # 各自独立的状态实例(燃烧#3)算同一个来源
	var equip: String = str(e.get("equip", ""))
	var k: String = source_key(surface, ability, equip)
	var srcs: Dictionary = r["src"]
	if not srcs.has(k):
		srcs[k] = {"key": k, "surface": surface, "ability": ability, "equip": equip,
			"dmg": 0.0, "kind": {}, "hits": 0, "crits": 0, "heal": 0.0, "over": 0.0, "shield": 0.0, "casts": 0}
	return srcs[k]


static func _add(d: Dictionary, key: String, v: float) -> void:
	d[key] = float(d.get(key, 0.0)) + v


static func _sub(d: Dictionary, key: String) -> Dictionary:
	if not d.has(key):
		d[key] = {"dmg": 0.0, "kind": {}, "heal": 0.0, "shield": 0.0, "hits": 0}
	return d[key]


## Battle.fx 的每个事件都过一遍(只看伤害 / 治疗 / 护盾 / 阵亡)
func consume(e: Dictionary, time: float) -> void:
	match str(e.get("t", "")):
		"damage":
			var amount: float = float(e["amount"])
			if amount <= 0.0:
				return
			var dst: BUnit = e["dst"]
			var src: BUnit = e.get("src") as BUnit
			var kind: String = str(e.get("kind", "physical"))
			var cat: String = str(e.get("category", "skill"))
			var crit: bool = bool(e.get("crit", false))
			var rd: Dictionary = _row(dst)
			rd["taken"] = float(rd["taken"]) + amount
			_add(rd["taken_kind"], kind, amount)
			_add(rd["taken_cat"], cat, amount)
			rd["absorbed"] = float(rd["absorbed"]) + float(e.get("absorbed", 0.0))
			rd["mitigated"] = float(rd["mitigated"]) + float(e.get("mitigated", 0.0))
			rd["hp_lost"] = float(rd["hp_lost"]) + maxf(0.0, amount - float(e.get("absorbed", 0.0)) - float(e.get("overkill", 0.0)))
			var suid: String = src.uid if src != null else ""
			var fr: Dictionary = _sub(rd["from"], suid)
			fr["dmg"] = float(fr["dmg"]) + amount
			_add(fr["kind"], kind, amount)
			var fk: String = suid + "#" + source_key(str(e.get("surface", "")), str(e.get("ability", "")), str(e.get("equip", "")))
			var fs: Dictionary = rd["from_src"]
			if not fs.has(fk):
				fs[fk] = {"uid": suid, "def": src.def.id if src != null else "", "surface": str(e.get("surface", "")),
					"ability": str(e.get("ability", "")).get_slice("#", 0), "equip": str(e.get("equip", "")), "dmg": 0.0, "kind": {}, "hits": 0}
			var fse: Dictionary = fs[fk]
			fse["dmg"] = float(fse["dmg"]) + amount
			_add(fse["kind"], kind, amount)
			fse["hits"] = int(fse["hits"]) + 1
			if src == null:
				return
			var rs: Dictionary = _row(src)
			rs["dealt"] = float(rs["dealt"]) + amount
			_add(rs["dealt_kind"], kind, amount)
			_add(rs["dealt_cat"], cat, amount)
			rs["hits"] = int(rs["hits"]) + 1
			if crit:
				rs["crits"] = int(rs["crits"]) + 1
			var se: Dictionary = _src_entry(rs, e)
			se["dmg"] = float(se["dmg"]) + amount
			_add(se["kind"], kind, amount)
			se["hits"] = int(se["hits"]) + 1
			if crit:
				se["crits"] = int(se["crits"]) + 1
			var to: Dictionary = _sub(rs["to"], dst.uid)
			to["dmg"] = float(to["dmg"]) + amount
			_add(to["kind"], kind, amount)
			to["hits"] = int(to["hits"]) + 1
		"heal":
			var dst2: BUnit = e["dst"]
			var src2: BUnit = e.get("src") as BUnit
			var applied: float = float(e.get("amount", 0.0))
			var over: float = float(e.get("over", 0.0))
			if applied + over <= 0.0:
				return
			var rd2: Dictionary = _row(dst2)
			rd2["healed"] = float(rd2["healed"]) + applied
			if src2 == null:
				return
			_add(rd2["heal_from"], src2.uid, applied)
			var rs2: Dictionary = _row(src2)
			rs2["heal"] = float(rs2["heal"]) + applied
			rs2["overheal"] = float(rs2["overheal"]) + over
			var se2: Dictionary = _src_entry(rs2, e)
			se2["heal"] = float(se2["heal"]) + applied
			se2["over"] = float(se2["over"]) + over
			se2["casts"] = int(se2["casts"]) + 1
			var to2: Dictionary = _sub(rs2["to"], dst2.uid)
			to2["heal"] = float(to2["heal"]) + applied
		"shield":
			var dst3: BUnit = e["dst"]
			var src3: BUnit = e.get("src") as BUnit
			var amt3: float = float(e.get("amount", 0.0))
			if amt3 <= 0.0:
				return
			var rd3: Dictionary = _row(dst3)
			rd3["shielded"] = float(rd3["shielded"]) + amt3
			if src3 == null:
				return
			var rs3: Dictionary = _row(src3)
			rs3["shield"] = float(rs3["shield"]) + amt3
			var se3: Dictionary = _src_entry(rs3, e)
			se3["shield"] = float(se3["shield"]) + amt3
			se3["casts"] = int(se3["casts"]) + 1
			var to3: Dictionary = _sub(rs3["to"], dst3.uid)
			to3["shield"] = float(to3["shield"]) + amt3
		"death":
			var vu: BUnit = e["unit"]
			var rv: Dictionary = _row(vu)
			if float(rv["death"]) < 0.0:
				rv["death"] = maxf(0.0, time - GC.START_DELAY)
			var ku: BUnit = e.get("killer") as BUnit
			if ku != null and ku.team != vu.team:
				var rk: Dictionary = _row(ku)
				rk["kills"] = int(rk["kills"]) + 1


## 战斗结束时补齐：一下都没出手、也没挨打的单位也要有一行；记下存活 / 生命
func finalize(units: Array[BUnit], duration: float) -> void:
	for u: BUnit in units:
		var r: Dictionary = _row(u)
		r["alive"] = u.alive and not u.meta.has("entered_truck")
		r["hp"] = u.hp
		r["max_hp"] = u.get_stats().max_health
		r["star"] = u.star
	set_meta("duration", duration)


func duration() -> float:
	return float(get_meta("duration", 0.0))


## 某一队的单位行(召唤物也在内)
func team_rows(team: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for uid: String in order:
		var r: Dictionary = rows[uid]
		if int(r["team"]) == team:
			out.append(r)
	return out


## 一队在某项指标上的总量(算占比用)：dealt / taken / heal / shield
func team_total(team: int, metric: String) -> float:
	var s := 0.0
	for r: Dictionary in team_rows(team):
		s += float(r.get(metric, 0.0))
	return s
