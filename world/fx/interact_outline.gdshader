shader_type spatial;
// Focus rim: current interact target only. Additive fresnel, not a silhouette hull.
render_mode blend_add, unshaded, cull_back, shadows_disabled, depth_draw_never;

uniform vec4 rim_color : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float rim_power : hint_range(0.5, 8.0, 0.1) = 2.4;
uniform float rim_intensity : hint_range(0.0, 4.0, 0.05) = 1.35;
uniform float highlight_on : hint_range(0.0, 1.0, 1.0) = 0.0;

void fragment() {
	if (highlight_on < 0.5) {
		discard;
	}
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - ndv, rim_power);
	ALBEDO = rim_color.rgb * rim * rim_intensity;
	ALPHA = rim * rim_color.a;
}
