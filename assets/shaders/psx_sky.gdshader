// The Areas' sky: the fog colour at the horizon (so far geometry melts into it) up to a zenith colour, with a
// soft glow and a small disc where the Sun (or moon) sits, drifting clouds lit from the light's side, and
// stars that fade in as the sky darkens. Banded later by the PSX post pass like the rest.
shader_type sky;

uniform vec3 horizon : source_color = vec3(0.24, 0.29, 0.4);
uniform vec3 zenith : source_color = vec3(0.08, 0.1, 0.16);
uniform float glow = 0.5;   // the halo round the light
uniform float disc = 1.0;   // the light's own disc
uniform float clouds : hint_range(0.0, 1.0) = 0.5;   // how much of the sky they cover
uniform float cloud_light = 0.6;                      // how brightly the light catches their edges
uniform float cloud_speed = 0.004;
uniform float stars : hint_range(0.0, 1.0) = 0.0;     // 0 hides them (a bright day), 1 is a clear night
uniform vec3 ground : source_color = vec3(0.04, 0.045, 0.06);  // below the horizon, under the far sea and hills

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);  // quintic: no visible creases on the cell edges
	return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80)) * p * 2.03 + vec2(17.1, 5.7);  // turned each octave so the lattice never lines up
		a *= 0.5;
	}
	return v;
}

void sky() {
	float up = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 c = mix(horizon, zenith, smoothstep(0.0, 0.55, up));
	// a brighter band hugging the horizon, where the light's haze gathers
	c += horizon * 0.25 * exp(-up * 14.0);

	// stars: a jittered point per cell on the dome, twinkling slowly, hidden near the horizon haze
	if (stars > 0.0 && EYEDIR.y > 0.0) {
		vec2 sp = EYEDIR.xz / (EYEDIR.y + 0.35) * 38.0;
		vec2 cell = floor(sp);
		float r = hash21(cell);
		vec2 off = vec2(hash21(cell + 7.1), hash21(cell + 13.7)) * 0.6 + 0.2;
		float d = length(fract(sp) - off);
		float tw = 0.7 + 0.3 * sin(TIME * (1.5 + r * 3.0) + r * 40.0);
		float s = step(0.93, r) * smoothstep(0.09, 0.0, d) * tw;
		c += vec3(0.85, 0.9, 1.0) * s * stars * smoothstep(0.05, 0.35, up);
	}

	if (LIGHT0_ENABLED) {
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		c += LIGHT0_COLOR * (pow(s, 6.0) * 0.35 * glow + pow(s, 40.0) * 0.5 * glow + step(0.9992, s) * disc);
	}

	// clouds on a flat layer overhead, thinning to nothing at the horizon; the side facing the light is lit
	if (clouds > 0.0 && EYEDIR.y > 0.02) {
		vec2 cp = EYEDIR.xz / (EYEDIR.y + 0.45) * 1.7 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.4);
		float n = fbm(cp);
		float cover = smoothstep(1.0 - clouds * 0.8, 1.0 - clouds * 0.8 + 0.4, n);
		cover *= smoothstep(0.02, 0.4, EYEDIR.y);
		// shade by sampling the cloud a step toward the light: thinner there means a lit edge
		vec2 toward = normalize(LIGHT0_DIRECTION.xz + vec2(0.0001));
		float n2 = fbm(cp + toward * 0.12);
		float lit = clamp((n - n2) * 2.0 + 0.5, 0.0, 1.0);
		vec3 base = mix(zenith, horizon, 0.55) * 0.55 + 0.04;
		vec3 cc = base + (LIGHT0_ENABLED ? LIGHT0_COLOR : vec3(0.0)) * lit * cloud_light * 0.5;
		c = mix(c, cc, cover * 0.7);
	}

	if (EYEDIR.y < 0.0) {
		c = mix(horizon * 1.25, ground, smoothstep(0.0, 0.25, -EYEDIR.y));
	}
	COLOR = c;
}
