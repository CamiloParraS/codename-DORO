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

varying vec2 box_uv;
varying vec2 side_uv;
varying float top;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = abs(mat3(MODEL_MATRIX) * NORMAL);
	vec2 uv = n.y > 0.5 ? wp.xz : (n.x > 0.5 ? vec2(wp.z, -wp.y) : vec2(wp.x, -wp.y));
	box_uv = uv / tile_m;
	side_uv = uv / side_tile_m;
	top = n.y > 0.5 ? 1.0 : 0.0;
}

void fragment() {
	vec3 c = split && top < 0.5 ? texture(side_tex, side_uv).rgb : texture(albedo_tex, box_uv).rgb;
	ALBEDO = c * tint;
	ROUGHNESS = 1.0;
}
