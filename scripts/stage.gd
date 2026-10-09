extends RefCounted
## 展示舞台：灰米色背景、柔和阴影、SSAO、泛光。tools/shot.gd 与运行时 viewer 共用。

const GROUND_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform vec3 shadow_tint : source_color = vec3(0.16, 0.15, 0.15);
uniform float strength = 0.5;
uniform float fade_radius = 3.2;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	ALBEDO = shadow_tint;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = 0.0;
}
void light() {
	float fade = 1.0 - smoothstep(fade_radius * 0.35, fade_radius, length(wpos.xz));
	ALPHA = clamp(ALPHA + (1.0 - ATTENUATION) * strength * fade, 0.0, 1.0);
}
"""

static func build(parent: Node, bg: Color = Color("#b5afa6"), transparent: bool = false) -> Dictionary:
	var out := {}
	var env := Environment.new()
	if transparent:
		env.background_mode = Environment.BG_CLEAR_COLOR
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#efe6dc")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 0.9
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 2.4
	env.ssao_enabled = true
	env.ssao_radius = 0.07
	env.ssao_intensity = 1.6
	env.ssao_power = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	parent.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42, 38, 0)
	sun.light_energy = 0.95
	sun.light_color = Color("#fff4e6")
	sun.shadow_enabled = true
	sun.shadow_blur = 2.2
	sun.directional_shadow_max_distance = 12.0
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 1.0
	parent.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.28
	fill.light_color = Color("#dfe9ff")
	fill.shadow_enabled = false
	parent.add_child(fill)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(14, 14)
	ground.mesh = pm
	var sh := Shader.new()
	sh.code = GROUND_SHADER
	var gm := ShaderMaterial.new()
	gm.shader = sh
	ground.material_override = gm
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ground)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = 20.0
	cam.near = 0.05
	cam.far = 60.0
	parent.add_child(cam)
	out["camera"] = cam
	out["sun"] = sun
	out["env"] = env
	return out
