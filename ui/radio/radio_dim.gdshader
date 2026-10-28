// The radio mode's world dim: a camera-locked full-screen quad that pulls the screen's saturation down.
// Never shared with the fills: a shader that writes POSITION in any branch overrides it for every material.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 1.0;  // fade-in
uniform float desat = 0.25;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.5, 1.0);  // a 1x1 QuadMesh covers the whole screen
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	ALBEDO = mix(c, vec3(dot(c, vec3(0.299, 0.587, 0.114))), desat * amount);
	ALPHA = 1.0;
}
