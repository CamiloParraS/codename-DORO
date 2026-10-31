// Full-screen 15-bit banding: 31 levels per channel, with the PSone's 4x4 ordered dither on the 480-line
// grid (so fog and sky gradients stipple instead of ringing), a soft vignette, and the optional lens
// passes (edge colour fringe, scanlines) that psx_look switches from the options.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float levels = 31.0;
uniform float lines = 480.0;     // the 3D's internal height: one dither cell per rendered pixel
uniform float dither = 1.0;      // in banding steps, at full brightness; half that in the darks
uniform float vignette = 0.15;
uniform float fringe = 0.0015;   // red/blue split at the screen edge, in screen widths
uniform float scanlines = 0.0;   // 0 off; dark gap between the 480 lines

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	float edge = dot(uv, uv) * 4.0;
	vec2 shift = uv * fringe * edge;
	vec3 c = vec3(texture(screen, SCREEN_UV + shift).r, texture(screen, SCREEN_UV).g, texture(screen, SCREEN_UV - shift).b);
	vec2 cell_px = floor(FRAGCOORD.xy * lines * SCREEN_PIXEL_SIZE.y);
	c *= 1.0 - vignette * smoothstep(0.35, 1.0, dot(uv, uv) * 2.0);
	float lum = dot(c, vec3(0.3, 0.59, 0.11));
	c *= 1.0 - scanlines * step(1.0, mod(cell_px.y, 2.0)) * 0.5;
	ivec2 cell = ivec2(cell_px) % 4;
	float b = (BAYER[cell.y * 4 + cell.x] / 16.0 - 0.5) * dither * mix(0.5, 1.0, smoothstep(0.05, 0.35, lum));
	COLOR = vec4(floor(c * levels + 0.5 + b) / levels, 1.0);
}
