// The sea: slow swell in the vertices, ripples on a coarse world grid (nearest, like a 128 px texture), the sky
// colour at grazing angles, and foam where it laps a quay, a piling or a hull (from the depth buffer).
shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform vec3 deep : source_color = vec3(0.03, 0.07, 0.12);
uniform vec3 shallow : source_color = vec3(0.07, 0.16, 0.2);
uniform vec3 sky : source_color = vec3(0.24, 0.29, 0.4);   // the Area's fog: what the water reflects at a slant
uniform vec3 foam : source_color = vec3(0.7, 0.75, 0.78);
uniform float swell = 0.12;      // metres
uniform float texel = 0.25;      // metres per ripple pixel
uniform float foam_m = 0.7;      // foam width against anything standing in the water
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 wp;

float wave(vec2 p, float t) {
	return sin(p.x * 0.35 + t * 0.9) * 0.6 + sin(p.y * 0.27 - t * 0.7) * 0.5 + sin((p.x + p.y) * 0.6 + t * 1.3) * 0.25;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise on a grid, so the ripples step like a nearest-filtered texture.
float ripple(vec2 p) {
	vec2 i = floor(p);
	vec2 f = smoothstep(0.0, 1.0, fract(p));
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += wave(wp.xz, TIME) * swell;
	float e = 0.5;
	float dx = (wave(wp.xz + vec2(e, 0), TIME) - wave(wp.xz - vec2(e, 0), TIME)) * swell / (2.0 * e);
	float dz = (wave(wp.xz + vec2(0, e), TIME) - wave(wp.xz - vec2(0, e), TIME)) * swell / (2.0 * e);
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	vec2 g = floor(wp.xz / texel) * texel;   // snap to the ripple grid: nearest-filtered look
	float t = TIME * 0.35;
	float r = ripple(g * 0.6 + vec2(t, t * 0.6)) + ripple(g * 1.3 - vec2(t * 0.8, -t)) - 1.0;
	vec3 n = normalize(vec3(r * 0.35, 1.0, r * 0.25));
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(n, 0.0)).xyz, 0.6));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 c = mix(deep, shallow, clamp(r + 0.5, 0.0, 1.0) * 0.45);
	c = mix(c, sky, fres * 0.8);
	// foam: how far behind the water surface the opaque scene is, in metres
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float gap = -behind.z / behind.w - -VERTEX.z;
	float lap = foam_m * (0.7 + 0.3 * sin(TIME * 1.5 + g.x * 0.8 + g.y * 0.6));
	float f = step(gap, lap) * step(0.35, ripple(g * 2.0 + TIME * 0.3) + 0.3 * (1.0 - gap / lap));
	c = mix(c, foam, f * 0.85);
	ALBEDO = c;
	ROUGHNESS = mix(0.08, 0.6, f);
	SPECULAR = 0.6;
	ALPHA = mix(0.9, 1.0, f);
}
