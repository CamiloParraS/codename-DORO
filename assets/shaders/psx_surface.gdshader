// PSX surface: nearest-filtered texture on world-space box UVs (tile_m metres per repeat).
// Per-pixel lighting and shadows; deliberately no vertex snapping and no affine texturing.
// With side_tex set, upward faces wear albedo_tex and the rest wear side_tex (a deck over a hull).
shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform sampler2D side_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform bool split = false;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tile_m = 2.0;
uniform float side_tile_m = 2.0;
uniform vec3 emission : source_color = vec3(0.0);  // a lamp, a screen, a lit sign: bloomed by the Area's glow
uniform float emission_energy = 1.0;
uniform float gloss = 0.0;  // 0 matte; wet planks and metal catch the lights at 0.3 to 0.6
uniform float wear = 0.22;   // large-scale blotching of the albedo, so a 128 px tile stops repeating across a yard
uniform float streak = 0.18; // rain-streak grime down vertical faces
uniform float wet = 0.0;     // damp, darker, glossier patches on upward faces (quay, planks, dirt)
uniform float rim = 0.12;   // grazing faces pick up a little sky, so a silhouette parts from what stands behind it

varying vec2 box_uv;
varying vec2 side_uv;
varying float top;
varying vec3 wpos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = abs(mat3(MODEL_MATRIX) * NORMAL);
	vec2 uv = n.y > 0.5 ? wp.xz : (n.x > 0.5 ? vec2(wp.z, -wp.y) : vec2(wp.x, -wp.y));
	box_uv = uv / tile_m;
	side_uv = uv / side_tile_m;
	top = n.y > 0.5 ? 1.0 : 0.0;
	wpos = wp;
}

void fragment() {
	vec3 c = split && top < 0.5 ? texture(side_tex, side_uv).rgb : texture(albedo_tex, box_uv).rgb;
	vec2 sp = top > 0.5 ? wpos.xz : vec2(wpos.x + wpos.z, wpos.y);
	float blotch = vnoise(sp * 0.16) * 0.6 + vnoise(sp * 0.55) * 0.4;
	c *= 1.0 + (blotch - 0.5) * 2.0 * wear;
	if (top < 0.5) {
		float s = vnoise(vec2((wpos.x + wpos.z) * 2.6, wpos.y * 0.22));
		c *= 1.0 - smoothstep(0.55, 0.9, s) * streak;
	}
	float damp = top > 0.5 ? wet * smoothstep(0.52, 0.68, vnoise(wpos.xz * 0.3 + 11.0)) : 0.0;
	c *= 1.0 - damp * 0.3;
	ALBEDO = c * tint;
	float g = clamp(gloss + damp * 0.55, 0.0, 1.0);
	ROUGHNESS = 1.0 - g * 0.75;
	SPECULAR = g * 0.5;
	float grazing = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emission * emission_energy + ALBEDO * grazing * rim;
}
