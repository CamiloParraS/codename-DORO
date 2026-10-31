shader_type canvas_item;
// The game over screen's dither: an ordered 4x4 Bayer pattern of black cells that crowds in from the screen's
// edges and crawls a cell every 0.7 s, the HUD's plate fade at full-screen scale. One quad; nothing redrawn in script.

uniform float strength : hint_range(0.0, 1.0) = 0.2;
uniform float cell = 6.0;  // px per dither cell on the 1080 canvas

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 g = floor(UV * vec2(1920.0, 1080.0) / cell);
	float t = floor(TIME / 0.7);
	int ix = int(mod(g.x + t * 3.0, 4.0));
	int iy = int(mod(g.y + t, 4.0));
	float threshold = (BAYER[iy * 4 + ix] + 0.5) / 16.0;
	float edge = smoothstep(0.8, 1.3, length((UV - 0.5) * vec2(1.0, 0.8)) * 1.6);
	float dens = edge * clamp(strength * 4.0, 0.0, 1.0) * 0.8;
	COLOR = vec4(0.0, 0.0, 0.0, threshold < dens ? 0.9 : 0.0);
}
