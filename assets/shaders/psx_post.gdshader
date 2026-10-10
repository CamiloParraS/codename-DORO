// Full-screen 15-bit banding: 31 levels per channel, no dither.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float levels = 31.0;

void fragment() {
	COLOR = vec4(floor(texture(screen, SCREEN_UV).rgb * levels + 0.5) / levels, 1.0);
}
