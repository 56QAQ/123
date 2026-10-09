class_name RangeRing
extends MeshInstance3D
## 攻击范围环：贴地的圆盘(淡淡的填充 + 清晰的边缘)，可选虚线旋转(用于"换武器后的射程"预览)。
## 半径 = 单位能打到的圆心距(射程米数 + 目标半径的一部分，与 BattleAI 的出手判定一致)。

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float fill = 0.10;
uniform float edge = 0.03;
uniform float dashes = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) { discard; }
	float ring = smoothstep(1.0 - edge * 2.2, 1.0 - edge, r) * (1.0 - smoothstep(1.0 - edge * 0.25, 1.0, r));
	if (dashes > 0.5) {
		float ang = atan(p.y, p.x) / 6.2831853;
		ring *= step(0.45, fract(ang * dashes + TIME * 0.08));
	}
	float body = fill * smoothstep(0.35, 1.0, r);
	ALBEDO = color.rgb;
	ALPHA = clamp(body + ring, 0.0, 1.0) * color.a;
}
"""

static var _shader: Shader = null
var _mat: ShaderMaterial
var radius: float = 1.0


func _init() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.render_priority = 5
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## r：半径(米)；dashed：虚线(预览)
func show_at(pos: Vector3, r: float, color: Color, dashed: bool = false) -> void:
	radius = maxf(0.2, r)
	position = Vector3(pos.x, maxf(pos.y, 0.0) + 0.02 + (0.004 if dashed else 0.0), pos.z)
	scale = Vector3(radius, 1.0, radius)
	_mat.set_shader_parameter("color", color)
	_mat.set_shader_parameter("edge", clampf(0.06 / radius, 0.004, 0.2))
	_mat.set_shader_parameter("dashes", round(radius * 5.0) if dashed else 0.0)
	_mat.set_shader_parameter("fill", 0.0 if dashed else 0.13)
	visible = true


## 单位的实际出手距离(圆心距)：射程米数 + 典型目标半径的 0.6 倍
static func reach_of(stats: StatBlock) -> float:
	return stats.range_meters() + 0.45 * 0.6
