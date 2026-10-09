shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled, cull_disabled, shadows_disabled;

// 头顶血条(始终面向相机)：底槽 + 生命 + 护盾(叠在生命之后) + 星级 + 阵营色边
instance uniform float hp = 1.0;
instance uniform float shield = 0.0;
instance uniform float stars = 1.0;
instance uniform vec4 fill_color : source_color = vec4(0.32, 0.85, 0.42, 1.0);
instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float pulse = 0.0;
instance uniform vec4 eq0 : source_color = vec4(0.0);
instance uniform vec4 eq1 : source_color = vec4(0.0);
instance uniform vec4 eq2 : source_color = vec4(0.0);

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float box(vec2 p, vec2 c, vec2 h) {
	vec2 d = abs(p - c) - h;
	return max(d.x, d.y);
}

void fragment() {
	vec2 uv = vec2(v_uv.x, 1.0 - v_uv.y);
	vec4 col = vec4(0.0);
	float d_bg = box(uv, vec2(0.5, 0.31), vec2(0.5, 0.25));
	if (d_bg < 0.0) {
		col = vec4(0.05, 0.05, 0.07, 0.86);
		float bx = (uv.x - 0.02) / 0.96;
		float by = (uv.y - 0.09) / 0.44;
		if (bx > 0.0 && bx < 1.0 && by > 0.0 && by < 1.0) {
			vec3 base = fill_color.rgb;
			float h = clamp(hp, 0.0, 1.0);
			float s = clamp(shield, 0.0, 1.0);
			col = vec4(0.14, 0.14, 0.17, 0.95);
			if (bx < h) {
				float shade = 0.82 + 0.28 * (1.0 - by);
				col = vec4(base * shade, 1.0);
			} else if (bx < min(1.0, h + s)) {
				col = vec4(0.62, 0.86, 1.0, 1.0);
			}
			float tick = step(0.985, fract(bx * 6.0)) * 0.10;
			col.rgb -= vec3(tick);
		}
		if (d_bg > -0.035) {
			col.rgb = mix(col.rgb, tint.rgb, 0.85);
		}
	}
	// 星级小方块：1~3 星金色；共享召唤物能到 9 星 → 每 3 星换一档颜色(4~6 星玫红、7~9 星紫白)，方块数 = 这一档里的第几星
	float st = max(1.0, floor(stars + 0.5));
	float tier = floor((st - 1.0) / 3.0);
	float pips = st - tier * 3.0;
	vec3 pip_col = tier < 0.5 ? vec3(1.0, 0.82, 0.25) : (tier < 1.5 ? vec3(1.0, 0.36, 0.42) : vec3(0.86, 0.7, 1.0));
	for (int i = 0; i < 3; i++) {
		if (float(i) < pips - 0.5) {
			float cx = 0.075 + float(i) * 0.115;
			float d = box(uv, vec2(cx, 0.80), vec2(0.045, 0.14));
			if (d < 0.0) {
				col = vec4(pip_col, 1.0);
			}
		}
	}
	// 装备槽小方块(右侧)：颜色=装备大类色，暗=空槽，alpha 0=未解锁
	vec4 eqs[3] = vec4[3](eq0, eq1, eq2);
	for (int i = 0; i < 3; i++) {
		if (eqs[i].a > 0.01) {
			float cx = 0.70 + float(i) * 0.115;
			float d = box(uv, vec2(cx, 0.80), vec2(0.045, 0.14));
			if (d < 0.0) {
				col = vec4(eqs[i].rgb, 1.0);
				if (eqs[i].a < 0.5) {
					col = vec4(0.35, 0.36, 0.42, 0.9);
				}
			}
		}
	}
	col.rgb += vec3(pulse * 0.35);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
