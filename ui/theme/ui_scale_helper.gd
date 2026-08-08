class_name UiScaleHelper
extends RefCounted
## Runtime-only UI scale presets (MODULE 22). Not persisted.

const PRESET_100: float = 1.0
const PRESET_125: float = 1.25
const PRESET_150: float = 1.5

static var _current_scale: float = PRESET_100


static func get_ui_scale() -> float:
	return _current_scale


static func set_ui_scale(scale: float) -> void:
	var clamped: float = clampf(scale, 0.5, 2.0)
	_current_scale = clamped


static func set_ui_scale_percent(percent: int) -> void:
	match percent:
		100:
			set_ui_scale(PRESET_100)
		125:
			set_ui_scale(PRESET_125)
		150:
			set_ui_scale(PRESET_150)
		_:
			set_ui_scale(float(percent) / 100.0)


static func apply_to_control(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	root.scale = Vector2(_current_scale, _current_scale)


static func apply_to_canvas_item(root: CanvasItem) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Control:
		apply_to_control(root as Control)
