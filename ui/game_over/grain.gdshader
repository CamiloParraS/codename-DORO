shader_type canvas_item;
// Film grain for the game over screen: hashed noise re-rolled 24 times a second, laid over with an overlay-ish
// blend (a light additive/subtractive speck). One full-screen quad; nothing is redrawn per frame in script.

uniform float strength : hint_range(0.0, 1.0) = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * 24.0);
	float n = hash(floor(FRAGCOORD.xy / 2.0) + frame * 17.0) - 0.5;
	COLOR = vec4(vec3(n > 0.0 ? 1.0 : 0.0), abs(n) * strength * 0.5);
}
