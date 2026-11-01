shader_type canvas_item;
// A very light barrel distortion of the whole frame, HUD included: the corners bend in a little, like a
// visor. The picture is pre-scaled so the corners land exactly on the screen edge (no black borders).

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
uniform float strength = 0.05;   // 0 = off; 0.03-0.08 reads as subtle
uniform float corner_dark = 0.12; // a faint darkening in the corners, like the lens' falloff

void fragment() {
	vec2 d = UV - 0.5;
	float r2 = dot(d, d);
	vec2 uv = 0.5 + d / (1.0 + strength) * (1.0 + strength * r2 * 2.0);
	vec3 col = texture(screen, uv).rgb;
	col *= 1.0 - corner_dark * smoothstep(0.1, 0.5, r2);
	COLOR = vec4(col, 1.0);
}
