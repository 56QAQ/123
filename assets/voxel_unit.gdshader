shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// 棋子体素着色器：顶点色(已烘焙 AO) + UV.x=材质类别 + UV.y=体素随机数。
// 类别 1 强调色、2 发梢 按阵营换色相；3 发色 换成 hair_color(按亮度比保留明暗)；4 肤色 按 skin_color 等比换色。
// dissolve 用于出场/死亡的体素崩解。ghost = 半透明紫色虚影(迅游节点穿过别人 / 地形时)：4×4 抖动镂空 + 紫色调，仍走不透明管线(不用排序)。
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float specular_amt : hint_range(0.0, 1.0) = 0.3;
uniform float emit_energy : hint_range(0.0, 8.0) = 0.5;
uniform float albedo_scale : hint_range(0.5, 1.5) = 0.92;

instance uniform float accent_hue = 0.517;
instance uniform float accent_sat = 1.0;
instance uniform float accent_val = 1.0;
instance uniform vec4 hair_color = vec4(1.0);          // sRGB，与顶点色同一空间
instance uniform float hair_ref = 0.0;                  // 模型原本发色的亮度；0 = 不换发色
instance uniform vec4 skin_color = vec4(0.973, 0.804, 0.722, 1.0);
const vec3 SKIN_REF = vec3(0.973, 0.804, 0.722);         // 调色板里的基础肤色 #f8cdb8
instance uniform float hit_flash = 0.0;
instance uniform float dissolve = 0.0;
instance uniform float glow_boost = 0.0;
instance uniform vec4 dissolve_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
instance uniform float ghost = 0.0;
// 虚影的颜色(线性色)：默认紫色；踏影节点的凝暗 = 墨青(UnitView.set_ghost_tint)
instance uniform vec4 ghost_tint = vec4(0.62, 0.32, 1.0, 1.0);
// 怪物的身份表现(模型元数据 IDENTITY，UnitSkin 设)：rim_color = 轮廓光颜色(sRGB) + a = 强度；lava_pulse = 发光体素(熔岩)的流动脉动幅度
instance uniform vec4 rim_color = vec4(0.0);
instance uniform float lava_pulse = 0.0;
// 星旅节点·外神之貌(真实形态)：身体化成星空——深紫黑的底(按原来的明暗留一点形)、里面一颗颗闪烁的星、缓缓流动的星云，外轮廓一圈品红的光
instance uniform float void_k = 0.0;
// 石化(奇兴节点·自久远的过去而来)：整个人变成灰石——按原来的明暗留形，体素间一点深浅不一的石纹，不发光
instance uniform float stone = 0.0;
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
const vec3 GHOST_COL = vec3(0.62, 0.32, 1.0);

varying float v_class;
varying float v_hash;
varying vec3 v_obj;
varying vec3 v_cyl;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	v_class = UV.x;
	v_hash = UV.y;
	v_obj = VERTEX;
	// 轮廓光用"绕身体竖轴的圆柱法线"(体素的面法线一格一格的，拿它算菲涅耳会整面整面地亮)：外轮廓上亮、正对镜头的地方暗
	vec2 hxz = VERTEX.xz;
	v_cyl = (MODELVIEW_MATRIX * vec4(length(hxz) > 1e-4 ? normalize(vec3(hxz.x, 0.0, hxz.y)) : vec3(0.0, 0.0, 1.0), 0.0)).xyz;
}

void fragment() {
	if (v_hash < dissolve) {
		discard;
	}
	if (ghost > 0.001) {
		int bi = (int(FRAGCOORD.y) % 4) * 4 + (int(FRAGCOORD.x) % 4);
		if ((BAYER[bi] + 0.5) / 16.0 < ghost * 0.55) {
			discard;
		}
	}
	vec3 c = COLOR.rgb;
	if (v_class > 0.5 && v_class < 2.5) {
		vec3 h = rgb2hsv(c);
		h.x = fract(h.x + (accent_hue - 0.517));
		h.y = clamp(h.y * accent_sat, 0.0, 1.0);
		h.z = clamp(h.z * accent_val, 0.0, 1.0);
		c = hsv2rgb(h);
	} else if (v_class > 2.5 && v_class < 3.5) {
		if (hair_ref > 0.0) {
			float l = dot(c, vec3(0.299, 0.587, 0.114));
			c = clamp(hair_color.rgb * (l / hair_ref), 0.0, 1.0);
		}
	} else if (v_class > 3.5) {
		c = clamp(c * (skin_color.rgb / SKIN_REF), 0.0, 1.0);
	}
	vec3 lin = pow(c, vec3(2.2));
	lin = mix(lin, ghost_tint.rgb * (0.35 + 0.65 * dot(lin, vec3(0.3, 0.5, 0.2))), ghost * 0.7);
	vec3 void_em = vec3(0.0);
	if (void_k > 0.001) {
		float l = dot(lin, vec3(0.3, 0.5, 0.2));
		float neb = sin(v_obj.x * 9.0 + TIME * 0.7) * sin(v_obj.y * 7.0 - TIME * 0.5) * sin(v_obj.z * 8.0 + TIME * 0.6);
		vec3 deep = mix(vec3(0.012, 0.0, 0.03), vec3(0.09, 0.015, 0.2), 0.5 + 0.5 * neb);
		lin = mix(lin, deep * (0.35 + 0.9 * l), void_k);
		vec3 cell = floor(v_obj * 55.0);
		float h = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		float star = step(0.955, h) * (0.45 + 0.55 * sin(TIME * (2.0 + 3.0 * h) + h * 40.0));
		void_em += mix(vec3(0.75, 0.6, 1.0), vec3(1.0, 0.85, 0.95), h) * max(star, 0.0) * 4.0;
		void_em += vec3(0.12, 0.02, 0.25) * (0.5 + 0.5 * neb) * 0.15;
		float vfr = 1.0 - abs(dot(normalize(v_cyl), normalize(VIEW)));
		void_em += vec3(0.7, 0.15, 1.0) * pow(vfr, 4.0) * 1.3;
		void_em *= void_k;
	}
	if (stone > 0.001) {
		float sl = dot(lin, vec3(0.3, 0.5, 0.2));
		float grain = fract(sin(dot(floor(v_obj * 80.0), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		vec3 rock = vec3(0.30, 0.29, 0.27) * (0.55 + 0.9 * sqrt(sl)) * (0.85 + 0.3 * grain);
		lin = mix(lin, rock, stone);
	}
	ALBEDO = mix(lin * albedo_scale, vec3(1.0), hit_flash * 0.85);
	ROUGHNESS = roughness;
	SPECULAR = specular_amt;
	vec3 em = lin * COLOR.a * 16.0 * emit_energy * (1.0 + glow_boost * 3.0);
	if (lava_pulse > 0.001 && COLOR.a > 0.001) {
		// 熔岩在裂缝里往上流：沿高度的一道道亮带往上走 + 每一小块各自慢慢明灭
		float wave = sin(v_obj.y * 10.0 - TIME * 2.8 + v_hash * 1.5);
		float slow = sin(TIME * 1.4 + v_hash * 6.2831);
		em *= max(0.25, 1.0 + lava_pulse * (0.45 * wave + 0.25 * slow));
	}
	if (rim_color.a > 0.001) {
		float fr = 1.0 - abs(dot(normalize(v_cyl), normalize(VIEW)));
		float side = 1.0 - clamp(dot(normalize(NORMAL), mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
		em += pow(rim_color.rgb, vec3(2.2)) * pow(fr, 4.0) * side * rim_color.a * 2.0;
	}
	float edge = 1.0 - smoothstep(dissolve, dissolve + 0.10, v_hash);
	em += dissolve_color.rgb * edge * step(0.001, dissolve) * 3.0;
	em += vec3(1.0) * hit_flash * 0.5;
	em += ghost_tint.rgb * ghost * 0.9;
	em = mix(em, em * 0.3, void_k) + void_em;
	em *= 1.0 - stone;
	EMISSION = em;
}
