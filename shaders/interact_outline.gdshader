shader_type spatial;
// Inverse-hull outline for interactables (next_pass on mesh materials).
// Idle = thin cool rim; focus = thicker accent. Common Godot 4 pattern.
render_mode blend_mix, cull_front, unshaded, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.43, 0.91, 1.0, 0.9);
uniform float outline_width : hint_range(0.0, 0.15, 0.001) = 0.02;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
