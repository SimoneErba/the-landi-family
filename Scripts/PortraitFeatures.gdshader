shader_type canvas_item;
render_mode unshaded;

// Work in cell coordinates even when the TextureRect uses an AtlasTexture.
uniform vec4 cell_region;
uniform float face_length = 0.5;
uniform float jaw_width = 0.5;
uniform float eye_spacing = 0.5;
uniform float eye_size = 0.5;
uniform float nose_length = 0.5;
uniform float nose_width = 0.5;
uniform float mouth_width = 0.5;
uniform float skin_tone = 0.5;
uniform float hair_color = 0.5;
uniform float hair_wave = 0.5;
uniform float grey_amount = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

float area(vec2 point, vec2 center, vec2 radius) {
	return 1.0 - smoothstep(0.3, 1.0, length((point - center) / radius));
}

void fragment() {
	vec2 p = (UV - cell_region.xy) / cell_region.zw;
	vec2 q = p;
	float head = area(p, vec2(0.5, 0.49), vec2(0.37, 0.47));
	q.y = 0.49 + (q.y - 0.49) * (1.0 - (face_length - 0.5) * 0.24 * head);
	float jaw = area(p, vec2(0.5, 0.65), vec2(0.32, 0.25));
	q.x = 0.5 + (q.x - 0.5) * (1.0 - (jaw_width - 0.5) * 0.28 * jaw);
	for (int side = 0; side < 2; side++) {
		float sign_x = side == 0 ? -1.0 : 1.0;
		vec2 eye = vec2(0.5 + sign_x * 0.11, 0.44);
		float weight = area(p, eye, vec2(0.115, 0.09));
		q.x -= sign_x * (eye_spacing - 0.5) * 0.045 * weight;
		q += (q - eye) * (0.5 - eye_size) * 0.32 * weight;
	}
	float nose = area(p, vec2(0.5, 0.54), vec2(0.085, 0.115));
	q.x += (q.x - 0.5) * (0.5 - nose_width) * 0.5 * nose;
	q.y += (q.y - 0.49) * (0.5 - nose_length) * 0.4 * nose;
	float mouth = area(p, vec2(0.5, 0.65), vec2(0.13, 0.07));
	q.x += (q.x - 0.5) * (0.5 - mouth_width) * 0.45 * mouth;
	float hair = area(p, vec2(0.5, 0.23), vec2(0.3, 0.19));
	q.x += sin(q.y * 65.0) * (hair_wave - 0.5) * 0.012 * hair;
	vec2 source_uv = cell_region.xy + clamp(q, vec2(0.002), vec2(0.998)) * cell_region.zw;
	vec4 ink = texture(TEXTURE, source_uv);
	float brightness = dot(ink.rgb, vec3(0.299, 0.587, 0.114));
	float skin = area(p, vec2(0.5, 0.55), vec2(0.23, 0.25));
	// Preserve graphite lines and parchment; tint only midtone facial washes.
	float wash = smoothstep(0.2, 0.45, brightness);
	ink.rgb *= 1.0 - (skin_tone - 0.5) * 0.32 * skin * wash;
	float hair_ink = hair * (1.0 - smoothstep(0.48, 0.78, brightness));
	ink.rgb = mix(ink.rgb, ink.rgb * vec3(1.0 + (hair_color - 0.5) * 0.65, 1.0 + (hair_color - 0.5) * 0.3, 1.0), hair_ink);
	ink.rgb = mix(ink.rgb, vec3(brightness * 0.7 + 0.23, brightness * 0.67 + 0.22, brightness * 0.62 + 0.2), hair_ink * grey_amount * 0.45);
	COLOR = ink * vertex_tint;
}
