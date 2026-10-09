shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// 顶点色 = 体素颜色(已烘焙AO)，alpha = 发光强度(0..1 对应 0..16)
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float specular_amt : hint_range(0.0, 1.0) = 0.35;
uniform float emit_energy : hint_range(0.0, 8.0) = 0.5;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.1;
uniform float albedo_scale : hint_range(0.5, 1.5) = 0.9;
uniform vec3 rim_color : source_color = vec3(0.75, 0.92, 1.0);

void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = c * albedo_scale;
	ROUGHNESS = roughness;
	SPECULAR = specular_amt;
	EMISSION = c * COLOR.a * 16.0 * emit_energy;
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	EMISSION += rim_color * fres * rim_strength * 0.25;
}
