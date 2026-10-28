// A radio-mode referent's flat fill: no depth test and no fog, so it shows through walls at any range.
// Drawn after the dim (higher render_priority).
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform vec4 colour : source_color = vec4(1.0);
uniform bool hatch = false;  // 2x2 checker stipple
uniform float pulse = 0.0;   // brightness flicker

void fragment() {
	if (hatch && mod(floor(FRAGCOORD.x / 2.0) + floor(FRAGCOORD.y / 2.0), 2.0) < 1.0) {
		discard;
	}
	ALBEDO = colour.rgb * (1.0 + 0.35 * pulse * sin(TIME * 18.0));
	ALPHA = colour.a;
}
