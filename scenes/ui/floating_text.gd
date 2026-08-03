class_name FloatingText
extends RefCounted
## Lightweight reward feedback rendered above the HUD toast.

static func spawn(hud_root: Control, message: String, kind: StringName) -> void:
	var label := Label.new()
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = &"HudToast"
	label.add_theme_color_override("font_color", UiStyle.OK if kind == &"money" else UiStyle.MONEY)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(-180.0, 128.0)
	label.size = Vector2(360.0, 36.0)
	label.modulate.a = 0.0
	hud_root.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(label, "position:y", 88.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(label.queue_free)
