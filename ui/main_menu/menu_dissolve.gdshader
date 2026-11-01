shader_type canvas_item;
// The menu backdrop's pictures. The grade pulls each towards one duotone (`shadow` to `highlight` by luminance),
// keeping `keep` of its own colour, so pictures shot in different light read as one camera; a vignette darkens the
// screen's edges. The slide change: the new picture arrives as blocks of pixels, in ordered (Bayer) order, in a few
// hard steps. `progress` is already quantised by the script; 1.0 shows the whole picture.

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float block = 10.0;  // screen px per block
uniform vec3 shadow : source_color = vec3(0.035, 0.05, 0.058);
uniform vec3 highlight : source_color = vec3(0.81, 0.83, 0.82);
uniform float keep : hint_range(0.0, 1.0) = 0.62;
uniform float vignette : hint_range(0.0, 1.0) = 0.3;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	ivec2 p = ivec2(floor(FRAGCOORD.xy / block)) & ivec2(3);
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	if (threshold > progress) {
		discard;
	}
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 duo = mix(shadow, highlight, smoothstep(0.02, 0.95, l));
	c = mix(duo, c, keep);
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 0.8);
	c *= 1.0 - vignette * smoothstep(0.25, 0.75, length(d) * 1.4);
	COLOR.rgb = c;
}
