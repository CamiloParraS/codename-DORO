// The live call's portrait, Peace Walker style: grayscale, contrast lifted, a fine halftone dot screen.
shader_type canvas_item;

uniform float dot_px = 4.0;  // halftone cell, in screen px
uniform float contrast = 1.3;
uniform float key = 0.0;   // above 0: luminance under this goes clear, so what sits behind shows (the Codec's dither)
uniform float lift = 0.0;  // added to the grey before the halftone

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	g = clamp((g - 0.5) * contrast + 0.52 + lift, 0.0, 1.0);
	float keep = key > 0.0 ? smoothstep(key, key + 0.08, dot(c.rgb, vec3(0.299, 0.587, 0.114))) : 1.0;
	vec2 cell = fract(FRAGCOORD.xy / dot_px) - 0.5;
	g *= 1.0 - smoothstep(0.34, 0.2, length(cell)) * 0.3;
	COLOR = vec4(vec3(g) * COLOR.rgb, c.a * COLOR.a * keep);  // modulate tints it (the live call card is mint)
}
