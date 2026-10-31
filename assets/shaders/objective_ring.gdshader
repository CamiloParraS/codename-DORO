// The ground mark under an objective (areas/objective_marker.gd): a dashed outer ring turning slowly, a thin
// inner ring, and a pulse running out from the centre. Radius stepped into bands, the PSX stair-step.
// Additive and unlit, on a flat PlaneMesh as wide as the ring.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(0.83, 0.74, 0.54);
uniform float energy = 1.4;
uniform float bands = 20.0;      // radial steps across the ring
uniform float dashes = 10.0;     // around the outer ring
uniform float pulse_s = 1.8;     // one pulse from centre to edge

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float rq = floor(r * bands) / bands;
	float a = atan(p.y, p.x) / TAU + 0.5;
	float dash = step(0.38, fract(a * dashes + TIME * 0.12));
	float outer = step(0.84, rq) * step(rq, 0.91) * dash;  // two bands
	float inner = step(0.58, rq) * step(rq, 0.62);  // one band
	float t = fract(TIME / pulse_s);
	float tq = floor(t * bands) / bands;
	float pulse = (1.0 - step(0.5 / bands, abs(rq - tq))) * (1.0 - t) * (1.0 - t);
	float fill = (1.0 - r) * 0.18;
	ALBEDO = colour * energy * (outer + inner * 0.55 + pulse * 0.9 + fill);
}
