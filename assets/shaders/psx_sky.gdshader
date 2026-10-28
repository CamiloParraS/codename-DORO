// The Areas' sky: the fog colour at the horizon (so far geometry melts into it) up to a zenith colour, with a
// soft glow and a small disc where the Sun (or moon) sits. Banded later by the PSX post pass like the rest.
shader_type sky;

uniform vec3 horizon : source_color = vec3(0.24, 0.29, 0.4);
uniform vec3 zenith : source_color = vec3(0.08, 0.1, 0.16);
uniform float glow = 0.5;   // the halo round the light
uniform float disc = 1.0;   // the light's own disc

void sky() {
	float up = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 c = mix(horizon, zenith, smoothstep(0.0, 0.55, up));
	if (LIGHT0_ENABLED) {
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		c += LIGHT0_COLOR * (pow(s, 6.0) * 0.35 * glow + pow(s, 40.0) * 0.5 * glow + step(0.9992, s) * disc);
	}
	COLOR = c;
}
