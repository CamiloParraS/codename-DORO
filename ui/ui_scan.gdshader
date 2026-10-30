shader_type canvas_item;
// Static scanlines (about 5% black on a 3 px period) over a full-screen UI, with an optional slow light band
// and a backdrop drift. Never on the HUD.

uniform float line_strength : hint_range(0.0, 0.3) = 0.05;
uniform float line_period = 3.0;
uniform float band_strength : hint_range(0.0, 0.2) = 0.04;
uniform float band_secs = 9.0;
uniform bool band_on = false;
uniform sampler2D backdrop : source_color, filter_linear;
uniform bool use_backdrop = false;
uniform float drift = 0.0;

void fragment() {
	vec4 c = vec4(0.0);
	if (use_backdrop) {
		float k = 1.0 + drift * 0.04 * fract(TIME / 40.0);
		vec2 uv = (UV - 0.5) / k + 0.5 + vec2(drift * 0.01 * fract(TIME / 40.0), 0.0);
		c = texture(backdrop, uv);
	}
	float dark = mod(FRAGCOORD.y, line_period) < 1.0 ? line_strength : 0.0;
	c.rgb *= 1.0 - dark;
	c.a = max(c.a, dark);
	if (band_on) {
		float d = abs(UV.y - (1.0 - fract(TIME / band_secs)));
		float glow = band_strength * smoothstep(0.08, 0.0, d);
		c.rgb += vec3(glow);
		c.a = max(c.a, glow);
	}
	COLOR = c;
}
