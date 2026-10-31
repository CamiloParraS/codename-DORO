// An item's glint (areas/objective_marker.gd), drawn over its own material as material_overlay: a bright band
// sweeping across it every `period` s, and a slow breathing rim that parts it from a dark room.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(0.83, 0.74, 0.54);
uniform float period = 2.8;
uniform float size_m = 0.4;  // the item's width: the band crosses it in a fifth of the period

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float t = fract(TIME / period) * 5.0 - 2.0;  // -2..3, on the item only for 0..1
	float s = (lp.x + lp.z) / size_m + 0.5;
	float band = 1.0 - smoothstep(0.0, 0.08, abs(s - t));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float breathe = 0.5 + 0.5 * sin(TIME * 2.2);
	ALBEDO = colour * (band * 0.9 + rim * (0.1 + 0.2 * breathe));
}
