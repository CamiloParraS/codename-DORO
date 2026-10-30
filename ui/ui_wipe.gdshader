shader_type canvas_item;
// Reveals an item (and children sharing this material) from one edge. `span` is the wiped Control's
// global x and width, so the cut lines up across every child.

uniform bool from_left = true;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 span = vec2(0.0, 1920.0);

varying float gx;

void vertex() {
	gx = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
}

void fragment() {
	float u = clamp((gx - span.x) / span.y, 0.0, 1.0);
	float edge = from_left ? u : 1.0 - u;
	if (edge > progress) {
		discard;
	}
}
