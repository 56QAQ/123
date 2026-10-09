class_name IntoxMarks
extends Node3D
## 【沉醉】(共歌节点·美妙地)的层数标记：挂在单位视图上，头部周围一圈慢慢绕着转、上下轻轻起伏的小音符。
## 层数越多音符越多(1~4 层 1 枚 … 17~20 层 5 枚)、越大、颜色从浅粉往深玫红走；
## 沉沦之梦挂着时变色：队友(梦之增幅)= 金色、往上浮一点；敌人(梦之沉沦)= 暗紫、往下坠一点、转得更慢。
## 善良地触发到这个单位时 pulse()：音符一下子胀大、亮一下再回去。BattleView 每隔一会儿 set_state 同步一次(不监听状态事件：
## 永恒的沉醉是开战时直接挂回去的)

const COL_LOW := Color("#ffb8da")
const COL_HIGH := Color("#ff3d96")
const COL_AMP := Color("#ffc83a")
const COL_SINK := Color("#8f55ff")
const MAX_NOTES := 5

var fx: Fx
var stacks := 0
var dream := 0                       # 1 = 梦之增幅(队友)、-1 = 梦之沉沦(敌人)、0 = 没有
var radius := 0.36
var height := 1.25
var _notes: Array[MeshInstance3D] = []
var _t := 0.0
var _pulse := 0.0
var _dream_k := 0.0                  # 变色 / 浮沉的过渡(带符号)


static func create(p_fx: Fx, parent: Node3D, p_height: float, p_radius: float) -> IntoxMarks:
	var m := IntoxMarks.new()
	m.fx = p_fx
	m.height = p_height
	m.radius = p_radius
	m.name = "IntoxMarks"
	parent.add_child(m)
	m._t = randf() * 10.0
	return m


func set_state(n: int, p_dream: int) -> void:
	if n == stacks and p_dream == dream:
		return
	var grew: bool = n > stacks
	stacks = n
	dream = p_dream
	var want: int = clampi(1 + (n - 1) / 4, 1, MAX_NOTES) if n > 0 else 0
	while _notes.size() < want:
		var mi := MeshInstance3D.new()
		mi.mesh = fx.note2_mesh() if _notes.size() % 2 == 1 else fx.note_mesh()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_notes.append(mi)
	while _notes.size() > want:
		(_notes.pop_back() as MeshInstance3D).queue_free()
	_recolor()
	if grew:
		_pulse = maxf(_pulse, 0.45)


## 善良地打到这里：胀大、亮一下
func pulse() -> void:
	_pulse = 1.0
	_recolor(true)


func _recolor(bright: bool = false) -> void:
	var c: Color = COL_LOW.lerp(COL_HIGH, clampf(float(stacks - 1) / 19.0, 0.0, 1.0))
	if dream > 0:
		c = COL_AMP
	elif dream < 0:
		c = COL_SINK
	var e: float = 3.6 if bright else (2.2 + 0.05 * float(stacks))
	for mi: MeshInstance3D in _notes:
		mi.material_override = fx._icon_mat(c, snappedf(e, 0.2))


func _process(delta: float) -> void:
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	_t += dt * (0.55 if dream < 0 else 1.0)
	_dream_k = move_toward(_dream_k, float(dream), dt * 2.5)
	if _pulse > 0.0:
		var was_bright: bool = _pulse > 0.5
		_pulse = maxf(0.0, _pulse - dt * 2.2)
		if was_bright and _pulse <= 0.5:
			_recolor()
	var n: int = _notes.size()
	var sz: float = (0.85 + 0.022 * float(stacks)) * (1.0 + 0.7 * _pulse * _pulse)
	for i in range(n):
		var a: float = _t * 1.4 + TAU * float(i) / float(maxi(1, n))
		var bob: float = 0.05 * sin(_t * 2.6 + float(i) * 1.7)
		var y: float = height + bob + (0.08 * _dream_k if _dream_k > 0.0 else 0.14 * _dream_k)      # 别顶到头顶的血条
		var mi: MeshInstance3D = _notes[i]
		mi.position = Vector3(cos(a) * radius, y, sin(a) * radius)
		mi.scale = Vector3.ONE * sz
