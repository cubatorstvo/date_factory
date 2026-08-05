shader_type spatial;
// Screen-space silhouette outline for interactables (next_pass on mesh materials).
// Constant pixel width reads as a flat 2D rim on girls and props alike.
render_mode blend_mix, cull_front, unshaded, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0, 0.35, 0.58, 1.0);
uniform float outline_width : hint_range(0.0, 12.0, 0.1) = 3.0;

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (outline_width > 0.001) {
		vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
		vec2 n = clip_normal.xy;
		float n_len = length(n);
		if (n_len > 0.0001) {
			vec2 offset = (n / n_len) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;
			clip_position.xy += offset;
		}
	}
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
