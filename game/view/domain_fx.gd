class_name DomainFX
extends Node3D
## "少女幻 x"三个大招的领域：一个包住镜头的大球(cull_front)，逐像素读屏幕颜色 + 深度还原世界坐标，按到领域中心的水平距离改写画面。
##   ink    少女幻终(幻彩)：领域里的世界变成黑白的水墨 / 漫画——亮处是纸白、暗处是墨黑、中间调是网点，物体轮廓勾一圈墨线；
##          领域外整张地图褪成灰色(世界的颜色都被她抽走了)；她自己留着颜色
##   hush   少女幻嘘(幻形)：领域里去色 + 冷紫，横向的扫描线和一条条错位撕裂的"信号干扰"，红蓝错开(看见的东西都不可信)；领域外压暗一点
##   spirit 少女幻葬(幻灵)：领域里是冷紫蓝的冥界，画面像隔着水一样慢慢扭动，暗处泛出一点灵光；领域外压暗一点
##   timestop 清洁世界(清扫节点)：时间停止——从她身上扩出去一道波前(波前上一圈反相的负片 + 亮边)，扫过的世界褪成冷灰(留一点青)，
##          画面上一圈圈很淡的表盘刻度在转；她自己留着颜色。收掉时(时间恢复)一下子负片闪一下再回色
##   lullaby 温柔地(共歌节点)：整个战场沉进一场温柔的水下梦境——画面像隔着水一样轻轻晃、整体往粉紫偏一点，
##          地上一张慢慢流动的焦散光网(水面透下来的光)，屏幕上方斜着几道淡淡的光柱、四角一圈粉色的柔光晕；
##          张开时从她身上扩出去一道粉色的水波前。不改明暗关系(单位照样看得清)
## 领域的边界(地面上)：ink = 毛糙的墨圈，hush = 一圈断断续续的亮紫数据线，spirit = 一圈发光的魂火
## 张开(open)：从中心撑到满半径，同时整体强度从 0 到 1；收掉(close)：ink 的终结一击 = 黑白反相闪几下再往外扩；其它 = 强度淡到 0。
## 渲染优先级很靠前：别的半透明特效、文字在它后面画，不会被改色

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 center = vec3(0.0);
uniform float radius = 3.0;
uniform float strength = 1.0;     // 领域里的效果强度(张开 / 收掉)
uniform float outer = 0.0;        // 领域外的效果强度
uniform int mode = 0;             // 0 ink / 1 hush / 2 spirit / 3 timestop / 4 lullaby
uniform float flash_inv = 0.0;    // 反相(ink 的终结闪烁)
uniform float flash_thr = 0.0;    // 纯黑白二值(ink 的终结闪烁)
uniform vec3 keep = vec3(0.0);    // 留色的圆柱(她自己)
uniform float keep_r = 0.0;
uniform float keep_h = 2.6;
uniform vec4 tint : source_color = vec4(0.62, 0.5, 1.0, 1.0);

// 着色器内建矩阵在自定义函数里拿不到：从 fragment() 传进来
vec3 world_at(vec2 uv, mat4 ip, mat4 iv) {
	float depth = textureLod(depth_tex, uv, 0.0).r;
	vec4 v = ip * vec4(uv * 2.0 - 1.0, depth, 1.0);
	v.xyz /= v.w;
	return (iv * vec4(v.xyz, 1.0)).xyz;
}
float lin_depth(vec2 uv, mat4 ip) {
	float depth = textureLod(depth_tex, uv, 0.0).r;
	vec4 v = ip * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -v.z / v.w;
}
// 屏幕纹理是线性色：亮度先换成感知亮度(≈ sRGB)，阈值才和眼睛看到的一致
float luma(vec3 c) { return pow(max(dot(c, vec3(0.299, 0.587, 0.114)), 0.0), 1.0 / 2.2); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// 水下焦散(Dave Hoskins 的无缝水波焦散)：p 每 1 个单位平铺一次，返回 0..1 的细亮纹
float caustic(vec2 p0, float t) {
	vec2 p = mod(p0 * 6.2831853, 6.2831853) - 250.0;
	vec2 i = p;
	float c = 1.0;
	float inten = 0.005;
	for (int n = 0; n < 4; n++) {
		float tt = t * (1.0 - (3.5 / float(n + 1)));
		i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
		c += 1.0 / length(vec2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
	}
	c /= 4.0;
	c = 1.17 - pow(c, 1.4);
	return pow(abs(c), 8.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	mat4 IP = INV_PROJECTION_MATRIX;
	mat4 IV = INV_VIEW_MATRIX;
	vec3 wp = world_at(uv, IP, IV);
	float d = length(wp.xz - center.xz);
	bool far_px = textureLod(depth_tex, uv, 0.0).r <= 0.00001;        // 天空 / 远处(反向深度：0 = 无穷远)
	float inside = (far_px ? 0.0 : 1.0) * (1.0 - smoothstep(radius - 0.06, radius, d));
	vec3 c = textureLod(screen_tex, uv, 0.0).rgb;
	vec3 o = c;
	float k_in = strength * inside;
	if (mode == 0) {
		// ---- 水墨黑白：中间调用 45° 的网点，亮 = 纸白，暗 = 墨黑；轮廓(深度跳变 + 亮度跳变)勾墨线
		float g = luma(c);
		vec2 px = 1.0 / VIEWPORT_SIZE;
		float z0 = lin_depth(uv, IP);
		// 深度的二阶差(拉普拉斯)：平地 / 斜面上是 0，物体轮廓才有跳变
		float dz = abs(lin_depth(uv + vec2(px.x * 1.5, 0.0), IP) + lin_depth(uv - vec2(px.x * 1.5, 0.0), IP) - 2.0 * z0)
			+ abs(lin_depth(uv + vec2(0.0, px.y * 1.5), IP) + lin_depth(uv - vec2(0.0, px.y * 1.5), IP) - 2.0 * z0);
		float gl = luma(textureLod(screen_tex, uv + vec2(px.x * 1.5, 0.0), 0.0).rgb);
		float gu = luma(textureLod(screen_tex, uv + vec2(0.0, px.y * 1.5), 0.0).rgb);
		float edge = max(smoothstep(0.08, 0.2, dz), smoothstep(0.07, 0.17, abs(gl - g) + abs(gu - g)));
		vec2 sp = FRAGCOORD.xy * mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) / 7.0;
		float dots = length(fract(sp) - 0.5);
		float tone = smoothstep(0.08, 0.5, g);                          // 0 = 墨，1 = 纸(暗的红之章地面落在中间调 = 网点，不是一片墨黑)
		float ink = (tone > 0.82) ? 1.0 : ((tone < 0.22) ? 0.0 : step(0.5 * (1.0 - tone) + 0.08, dots));
		float bw = mix(ink, 0.0, edge);
		vec3 paper = vec3(0.93, 0.91, 0.86);        // 线性色
		vec3 ink_col = vec3(0.004, 0.0035, 0.005);
		vec3 inked = mix(ink_col, paper, bw);
		// 她自己留着颜色
		float keepk = 0.0;
		if (keep_r > 0.0 && length(wp.xz - keep.xz) < keep_r && wp.y > keep.y - 0.1 && wp.y < keep.y + keep_h) {
			keepk = 1.0 - flash_thr;
		}
		o = mix(c, inked, k_in * (1.0 - keepk));
		// 领域外：整张地图褪成灰
		o = mix(o, vec3(pow(g, 2.2)) * 0.85, outer * (1.0 - inside) * (1.0 - keepk));
		// 终结一击：纯黑白二值 + 反相
		o = mix(o, vec3(step(0.3, g)), flash_thr * inside);
		o = mix(o, vec3(1.0) - o, flash_inv * inside);
		// 边界：毛糙的墨圈(地面上)
		float rn = noise(vec2(atan(wp.z - center.z, wp.x - center.x) * 9.0, TIME * 0.6)) * 0.22;
		float band = smoothstep(0.16 + rn, 0.0, abs(d - radius + 0.05)) * (far_px ? 0.0 : 1.0) * step(wp.y, 0.35);
		o = mix(o, ink_col, band * strength * 0.9);
	} else if (mode == 1) {
		// ---- 信号干扰：横向一条条撕裂错位、红蓝分离、扫描线、冷紫去色
		float row = floor(uv.y * 48.0);
		float t = floor(TIME * 10.0);
		float tear = step(0.78, hash(vec2(row, t))) * (hash(vec2(row + 3.0, t)) - 0.5) * 0.09
			+ step(0.93, hash(vec2(floor(uv.y * 9.0), t + 7.0))) * (hash(vec2(t, 2.0)) - 0.5) * 0.05;
		vec2 uv2 = uv + vec2(tear * k_in, 0.0);
		vec3 wp2 = world_at(uv2, IP, IV);
		float in2 = 1.0 - smoothstep(radius - 0.06, radius, length(wp2.xz - center.xz));
		vec2 uvs = mix(uv, uv2, in2);
		float sh = 0.007 * k_in;
		vec3 cs = vec3(textureLod(screen_tex, uvs + vec2(sh, 0.0), 0.0).r, textureLod(screen_tex, uvs, 0.0).g, textureLod(screen_tex, uvs - vec2(sh, 0.0), 0.0).b);
		float g = luma(cs);
		float gl2 = pow(g, 2.2);
		vec3 cold = mix(vec3(gl2), tint.rgb * (0.12 + 0.9 * gl2), 0.55);
		float scan = 0.82 + 0.18 * sin(FRAGCOORD.y * 1.6 + TIME * 6.0);
		// 偶尔一整块闪成噪点(信号断了一下)
		float blk = step(0.97, hash(floor(uv * vec2(12.0, 20.0)) + vec2(t * 0.37, t)));
		cold = mix(cold, vec3(hash(FRAGCOORD.xy + t)) * tint.rgb * 1.4, blk);
		o = mix(c, cold * scan, k_in);
		o = mix(o, o * 0.78, outer * (1.0 - inside));
		float seg = step(0.45, noise(vec2(atan(wp.z - center.z, wp.x - center.x) * 14.0, floor(TIME * 8.0))));
		float band = smoothstep(0.07, 0.0, abs(d - radius + 0.04)) * (far_px ? 0.0 : 1.0) * step(wp.y, 0.35) * seg;
		o = mix(o, vec3(0.9, 0.82, 1.0), band * strength);
	} else if (mode == 3) {
		// ---- 时间停止：冷灰(留一点青) + 她留色；波前一圈负片 + 亮边；收掉时整张负片闪一下
		float g = luma(c);
		float gl4 = pow(g, 2.2);
		vec3 frozen = mix(vec3(gl4), tint.rgb * (0.08 + 1.05 * gl4), 0.28) * 0.92;
		float keepk = 0.0;
		if (keep_r > 0.0 && length(wp.xz - keep.xz) < keep_r && wp.y > keep.y - 0.1 && wp.y < keep.y + keep_h) {
			keepk = 1.0;
		}
		o = mix(c, frozen, k_in * (1.0 - keepk));
		// 波前：扩张中的那一圈负片 + 亮边
		float wave = (far_px ? 0.0 : 1.0) * (1.0 - smoothstep(0.0, 1.6, radius - d)) * step(d, radius) * (1.0 - step(30.0, radius));
		o = mix(o, vec3(1.0) - o, wave * 0.85 * strength * (1.0 - keepk));
		float rim = smoothstep(0.22, 0.0, abs(d - radius)) * (far_px ? 0.0 : 1.0);
		o = mix(o, vec3(0.85, 0.95, 1.0) * 1.4, rim * strength);
		// 一圈圈很淡的表盘刻度(以她为中心，世界坐标，慢慢转)
		float ang = atan(wp.z - center.z, wp.x - center.x) + TIME * 0.4;
		float ticks = step(0.92, fract(ang / 6.2831853 * 60.0)) * step(abs(fract(d / 2.5) - 0.5), 0.06) * step(wp.y, 0.3);
		o = mix(o, vec3(0.9, 0.95, 1.0), ticks * 0.35 * k_in * (1.0 - keepk));
		o = mix(o, vec3(1.0) - o, flash_inv * (1.0 - keepk));
	} else if (mode == 4) {
		// ---- 水下的梦：轻轻晃 + 偏粉紫 + 地上的焦散光网 + 斜光柱 + 四角粉晕(乘法调色为主：白地 / 暗地都看得出来，不洗白)
		vec2 wob = vec2(sin(uv.y * 30.0 + TIME * 1.3), cos(uv.x * 26.0 + TIME * 1.1)) * 0.0035 * k_in;
		vec3 cw = textureLod(screen_tex, uv + wob, 0.0).rgb;
		vec3 dream = cw * mix(vec3(1.0), vec3(0.97, 0.86, 0.96), 0.6) + tint.rgb * 0.015;
		// 焦散：水面透下来的细光网(迭代扭曲的经典写法，世界坐标、约 2.9 米一块无缝平铺，只铺在地面附近)
		float caus = caustic(wp.xz * 0.35, TIME * 0.5);
		float ground = (far_px ? 0.0 : 1.0) * (1.0 - smoothstep(0.05, 0.6, wp.y));
		// 白地上"变亮"看不出来：网眼之间压暗一点、亮纹再提一点，亮地 / 暗地都看得出一张网
		dream *= mix(1.0, 0.9 + 0.2 * clamp(caus, 0.0, 1.0), ground);
		dream = mix(dream, max(dream, vec3(0.9, 0.74, 0.86)) * 1.12, clamp(caus, 0.0, 1.0) * 0.42 * ground);
		// 斜着的光柱(屏幕上方亮、往下淡)
		float sh = noise(vec2((uv.x + uv.y * 0.45) * 7.0 + TIME * 0.08, TIME * 0.05));
		dream += vec3(1.0, 0.9, 0.97) * pow(sh, 3.0) * (1.0 - uv.y) * 0.1;
		// 四角的粉色柔光晕(乘法：暗地上不发白)
		float vig = smoothstep(0.42, 0.95, length((uv - 0.5) * vec2(1.25, 1.0)) * 1.25);
		dream = mix(dream, dream * vec3(1.0, 0.7, 0.88) + tint.rgb * 0.04, vig * 0.65);
		o = mix(c, dream, k_in);
		// 张开时的水波前：一圈粉色的亮边 + 后面一小段往外推的折射
		float rim = smoothstep(0.45, 0.0, abs(d - radius)) * (far_px ? 0.0 : 1.0) * (1.0 - step(26.0, radius));
		o = mix(o, vec3(1.0, 0.55, 0.78) * 1.25, rim * strength * 0.75);
	} else {
		// ---- 冥界：隔着水一样慢慢扭动、冷紫蓝、暗处泛灵光
		vec2 wob = vec2(sin(uv.y * 40.0 + TIME * 1.8), cos(uv.x * 36.0 + TIME * 1.5)) * 0.006 * k_in;
		vec3 cw = textureLod(screen_tex, uv + wob, 0.0).rgb;
		float g = luma(cw);
		float gl3 = pow(g, 2.2);
		// 冷紫蓝、保留明暗(暗处更暗、亮处泛白光)
		vec3 ghost = tint.rgb * (0.03 + 1.6 * gl3) + vec3(0.8, 0.85, 1.0) * gl3 * gl3 * 0.6;
		// 地面上飘过一层层的冥雾(世界坐标，慢慢流动)
		vec2 mp = wp.xz * 0.9 + vec2(TIME * 0.25, TIME * 0.12);
		float mist = smoothstep(0.45, 0.85, noise(mp) * 0.65 + noise(mp * 2.3 - TIME * 0.2) * 0.35);
		ghost += tint.rgb * mist * 0.22 * (1.0 - smoothstep(0.2, 1.2, wp.y));
		float vig = smoothstep(radius * 0.4, radius, d);
		ghost *= 1.0 - 0.3 * vig;
		o = mix(c, ghost, k_in * 0.92);
		o = mix(o, o * 0.72, outer * (1.0 - inside));
		float fl = 0.6 + 0.4 * noise(vec2(atan(wp.z - center.z, wp.x - center.x) * 6.0 + TIME * 1.2, TIME));
		float band = smoothstep(0.12, 0.0, abs(d - radius + 0.06)) * (far_px ? 0.0 : 1.0) * step(wp.y, 0.35);
		o = mix(o, vec3(0.85, 0.75, 1.0) * 1.3, band * fl * strength);
	}
	ALBEDO = o;
}
"""

static var _shader: Shader = null

var mode: String = "ink"
var radius: float = 3.0
var mat: ShaderMaterial


static func make(p_mode: String, at: Vector3, p_radius: float, tint: Color = Color(0.62, 0.5, 1.0)) -> DomainFX:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var d := DomainFX.new()
	d.mode = p_mode
	d.radius = p_radius
	d.position = Vector3(at.x, 0.0, at.z)
	d.mat = ShaderMaterial.new()
	d.mat.shader = _shader
	d.mat.render_priority = -20
	d.mat.set_shader_parameter("mode", {"ink": 0, "hush": 1, "spirit": 2, "timestop": 3, "lullaby": 4}.get(p_mode, 0))
	d.mat.set_shader_parameter("radius", 0.2)
	d.mat.set_shader_parameter("strength", 0.0)
	d.mat.set_shader_parameter("outer", 0.0)
	d.mat.set_shader_parameter("tint", tint)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 180.0                 # 包住镜头：领域内外都由着色器按世界坐标判断
	sm.height = 360.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = d.mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	d.add_child(mi)
	return d


func _ready() -> void:
	mat.set_shader_parameter("center", global_position)


## 张开：dur 秒撑满；outer = 领域外的效果强度
func open(dur: float, outer_k: float) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(r: float) -> void: mat.set_shader_parameter("radius", r), 0.2, radius, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(k: float) -> void: mat.set_shader_parameter("strength", k), 0.0, 1.0, dur * 0.6)
	tw.tween_method(func(k: float) -> void: mat.set_shader_parameter("outer", k), 0.0, outer_k, dur * 1.6)


## 她自己留着颜色(ink)：每帧跟着她(悬浮时 y 往上)
func set_keep(at: Vector3, r: float, h: float) -> void:
	mat.set_shader_parameter("keep", at)
	mat.set_shader_parameter("keep_r", r)
	mat.set_shader_parameter("keep_h", h)


## 收掉。flash = ink 的终结一击(反相闪几下、纯黑白、再往外扩着褪掉)；否则强度淡出。timestop：负片闪一下、一下子回色(时间恢复)
func close(dur: float, flash: bool) -> void:
	if has_meta("closing"):
		return
	set_meta("closing", true)
	var tw := create_tween()
	if mode == "timestop":
		tw.tween_method(func(k: float) -> void:
			mat.set_shader_parameter("flash_inv", 1.0 if k < 0.18 else 0.0)
			mat.set_shader_parameter("strength", 1.0 - clampf((k - 0.18) / 0.82, 0.0, 1.0)), 0.0, 1.0, dur)
	elif flash:
		tw.tween_method(func(k: float) -> void:
			var hold: float = clampf(1.0 - (k - 0.6) / 0.4, 0.0, 1.0)
			mat.set_shader_parameter("flash_thr", hold)
			mat.set_shader_parameter("flash_inv", 1.0 if k < 0.6 and int(k * 10.0) % 2 == 0 else 0.0)
			mat.set_shader_parameter("strength", hold)
			mat.set_shader_parameter("outer", 0.85 * hold)
			mat.set_shader_parameter("radius", radius * (1.0 + 0.5 * clampf(k / 0.25, 0.0, 1.0))), 0.0, 1.0, dur)
	else:
		tw.set_parallel(true)
		tw.tween_method(func(k: float) -> void: mat.set_shader_parameter("strength", k), 1.0, 0.0, dur)
		tw.tween_method(func(k: float) -> void: mat.set_shader_parameter("outer", k), float(mat.get_shader_parameter("outer")), 0.0, dur)
		tw.set_parallel(false)
	tw.tween_callback(queue_free)
