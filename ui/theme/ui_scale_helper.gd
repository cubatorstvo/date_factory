class_name UiScaleHelper
extends RefCounted
## Accessibility scale presets. Layout stays full-rect and reflows through Containers.

const PRESET_100: float = 1.0
const PRESET_125: float = 1.25
const PRESET_150: float = 1.5
const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const BASE_THEME_META: StringName = &"_df_base_theme"
const REGISTERED_META: StringName = &"_df_ui_scale_registered"

static var _current_scale: float = PRESET_100
static var _registered_roots: Array[WeakRef] = []


static func get_ui_scale() -> float:
	return _current_scale


static func set_ui_scale(scale: float) -> void:
	var clamped: float = clampf(scale, 0.5, 2.0)
	if is_equal_approx(_current_scale, clamped):
		return
	_current_scale = clamped
	_refresh_registered_roots()


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
	root.scale = Vector2.ONE
	root.pivot_offset = Vector2.ZERO
	if not root.has_meta(BASE_THEME_META):
		var base_theme: Theme = root.theme
		if base_theme == null and ResourceLoader.exists(THEME_PATH):
			base_theme = load(THEME_PATH) as Theme
		if base_theme != null:
			root.set_meta(BASE_THEME_META, base_theme)
	if not root.has_meta(REGISTERED_META):
		root.set_meta(REGISTERED_META, true)
		_registered_roots.append(weakref(root))
	_apply_scaled_theme(root)


static func apply_to_canvas_item(root: CanvasItem) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Control:
		apply_to_control(root as Control)


static func _apply_scaled_theme(root: Control) -> void:
	var base_theme: Theme = root.get_meta(BASE_THEME_META, null) as Theme
	if base_theme == null:
		return
	var scaled_theme: Theme = base_theme.duplicate(true) as Theme
	scaled_theme.default_font_size = maxi(1, int(round(float(base_theme.default_font_size) * _current_scale)))
	for theme_type: StringName in base_theme.get_type_list():
		for font_size_name: StringName in base_theme.get_font_size_list(theme_type):
			var base_size: int = base_theme.get_font_size(font_size_name, theme_type)
			scaled_theme.set_font_size(
				font_size_name,
				theme_type,
				maxi(1, int(round(float(base_size) * _current_scale)))
			)
	root.theme = scaled_theme


static func _refresh_registered_roots() -> void:
	var alive: Array[WeakRef] = []
	for weak_root: WeakRef in _registered_roots:
		var root: Control = weak_root.get_ref() as Control
		if root == null or not is_instance_valid(root):
			continue
		alive.append(weak_root)
		_apply_scaled_theme(root)
	_registered_roots = alive
