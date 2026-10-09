class_name BStatus
extends RefCounted
## 单位身上的状态：属性状态(每层加成)、标记(眩晕/嘲讽等)、周期伤害。stacking 关键词决定层数上限。

var id: String = ""
var stacks: int = 1
var max_stacks: int = 1
var expires_at: float = -1.0            # 模拟时间；-1 = 战斗内永久
var source_id: String = ""              # 施加者 instance_id
var flat_per_stack: Dictionary = {}     # stat -> flat
var pct_per_stack: Dictionary = {}      # stat -> pct
var flags: Array[String] = []           # stun / taunt / fear / silence / disarm
var eternal: bool = false               # 永恒：战斗结束后保留到棋子实例上
var dot: Dictionary = {}                # {kind, amount_per_stack, interval, next_at}
var hot: Dictionary = {}                # 每层持续回血 {pct(每层每秒回复最大生命的比例), interval, next_at}：每层单独一次回复
var meta: Dictionary = {}
var stack_effect: bool = true           # false = 层数只用来标记驱散进度，效果不随层数叠加(虚荣：1 层和 3 层一样)
var size: float = 1.0                   # 体型倍率(直径；虚荣 = √2，即面积翻倍)


func _stack_mult() -> float:
	return float(stacks) if stack_effect else (1.0 if stacks > 0 else 0.0)


func total_flat(stat: String) -> float:
	return float(flat_per_stack.get(stat, 0.0)) * _stack_mult()


func total_pct(stat: String) -> float:
	return float(pct_per_stack.get(stat, 0.0)) * _stack_mult()


## 标记：常驻的 flags，加上按层数解锁的 meta.flags_at({"5": ["debuff_immune"]}：5 层起才有)
func has_flag(f: String) -> bool:
	if flags.has(f):
		return true
	if meta.has("flags_at"):
		for th: Variant in (meta["flags_at"] as Dictionary).keys():
			if stacks >= int(th) and ((meta["flags_at"] as Dictionary)[th] as Array).has(f):
				return true
	return false
