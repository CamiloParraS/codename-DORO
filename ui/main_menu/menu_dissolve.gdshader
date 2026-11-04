shader_type canvas_item;
// The menu backdrop's pictures. The grade pulls each towards one duotone (`shadow` to `highlight` by luminance),
// keeping `keep` of its own colour, so pictures shot in different light read as one camera; a vignette darkens the
// screen's edges. The slide change: the new picture fades in over the last by `progress`; 1.0 shows the whole picture.

uniform float zoom = 1.0;      // the slow push-in, about the centre
uniform vec2 shift = vec2(0.0);  // the pan, in fractions of the screen
uniform vec2 cover = vec2(1.0);  // the part of the picture that fills the screen (cropped to cover)
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec3 shadow : source_color = vec3(0.035, 0.05, 0.058);
uniform vec3 highlight : source_color = vec3(0.81, 0.83, 0.82);
uniform float keep : hint_range(0.0, 1.0) = 0.62;
uniform float vignette : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// posed here, not by the node's transform, so the glide is never snapped to whole pixels
	vec2 uv = 0.5 + (UV - 0.5 - shift) / zoom * cover;
	vec4 tex = texture(TEXTURE, uv);
	vec3 c = tex.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 duo = mix(shadow, highlight, smoothstep(0.02, 0.95, l));
	c = mix(duo, c, keep);
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 0.8);
	c *= 1.0 - vignette * smoothstep(0.25, 0.75, length(d) * 1.4);
	COLOR = vec4(c, tex.a * progress);
}
