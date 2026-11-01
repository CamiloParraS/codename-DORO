shader_type canvas_item;
// The screen-to-screen cut: black dither cells sweep in from the left (progress 0 -> 1) and, on the next screen,
// sweep out the same way (progress 1 -> 2). One quad; the cell and the Bayer pattern are the HUD plates'.

uniform float progress = 0.0;
uniform float cell = 12.0;  // px on the 1080 canvas

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 g = floor(UV * vec2(1920.0, 1080.0) / cell);
	float th = (BAYER[int(mod(g.y, 4.0)) * 4 + int(mod(g.x, 4.0))] + 0.5) / 16.0;
	float cover;
	if (progress <= 1.0) {
		cover = progress * 2.0 - UV.x;  // sweeping in: the left fills first
	} else {
		cover = 1.0 - ((progress - 1.0) * 2.0 - UV.x);  // sweeping out: the left clears first
	}
	COLOR = vec4(0.0, 0.0, 0.0, step(th, clamp(cover, 0.0, 1.0)));
}
