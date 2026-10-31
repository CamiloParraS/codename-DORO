// The light column standing on an objective (areas/objective_marker.gd): the Extraction point's tall beacon and
// a walk-in step's short one. Bright at the foot, gone by fade_m, brighter at its silhouette than through its
// middle so it reads as a volume, with bands climbing it. The fade steps every half metre, the PSX stair-step.
// Alpha-blended, not additive, so it still shows against a bright overcast sky. Unlit, on an open CylinderMesh
// `height` tall centred on its origin.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(0.83, 0.74, 0.54);
uniform float energy = 0.6;  // overall opacity
uniform float height = 30.0;
uniform float fade_m = 20.0;
uniform float band_m = 1.2;   // one band's climb, metres
uniform float climb = 0.5;    // bands per second
uniform vec2 far_m = vec2(12.0, 60.0);  // fills in from the first distance to the second, so it reads across the Area
uniform float far_gain = 2.4;

varying float h;  // metres above the foot

void vertex() {
	h = VERTEX.y + height * 0.5;
}

void fragment() {
	float hq = floor(h * 2.0) * 0.5;
	float up = clamp(1.0 - hq / fade_m, 0.0, 1.0);
	up *= up;
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	float far = smoothstep(far_m.x, far_m.y, length(VERTEX));
	float body = mix(mix(0.06, 0.4, far), 1.0, edge * edge);  // near clear through the middle, up close
	float band = 0.6 + 0.4 * step(0.55, fract(h / band_m - TIME * climb));
	float foot = 1.0 - smoothstep(0.0, 0.6, h);
	ALBEDO = colour * 1.25;
	ALPHA = clamp(energy * (up * body * band * mix(1.0, far_gain, far) + foot * 0.5), 0.0, 0.9);
}
