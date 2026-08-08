class_name DateFactoryThemeBuilder
extends RefCounted
## Builds the shared bureaucratic dark Theme used by MODULE 22 presentation.

const ACCENT := Color(0.62, 0.68, 0.74, 1.0)
const TEXT := Color(0.93, 0.94, 0.95, 1.0)
const TEXT_MUTED := Color(0.72, 0.74, 0.76, 1.0)
const WARNING := Color(0.78, 0.48, 0.38, 1.0)
const PANEL_BG := Color(0.08, 0.09, 0.11, 0.88)
const BUTTON_BG := Color(0.14, 0.16, 0.19, 0.94)
const BUTTON_HOVER := Color(0.20, 0.23, 0.27, 0.96)
const BUTTON_PRESSED := Color(0.11, 0.13, 0.16, 0.96)
const BUTTON_DISABLED := Color(0.12, 0.12, 0.14, 0.7)


static func build() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 18)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "RichTextLabel", 18)
	theme.set_font_size("font_size", "LineEdit", 18)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_MUTED)
	theme.set_color("font_color", "RichTextLabel", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	var panel := _panel_style(PANEL_BG)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	var btn_normal := _panel_style(BUTTON_BG)
	var btn_hover := _panel_style(BUTTON_HOVER)
	var btn_pressed := _panel_style(BUTTON_PRESSED)
	var btn_disabled := _panel_style(BUTTON_DISABLED)
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box: StyleBoxFlat = btn_normal
		match style_name:
			"hover":
				box = btn_hover
			"pressed":
				box = btn_pressed
			"disabled":
				box = btn_disabled
			"focus":
				box = btn_hover.duplicate() as StyleBoxFlat
				box.border_color = ACCENT
				box.set_border_width_all(1)
		theme.set_stylebox(style_name, "Button", box)
	return theme


static func ensure_resource(path: String = "res://ui/theme/date_factory_theme.tres") -> Theme:
	if ResourceLoader.exists(path):
		var existing: Resource = load(path)
		if existing is Theme:
			return existing as Theme
	var theme: Theme = build()
	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		push_warning("[DateFactoryTheme] save failed: %s" % error_string(err))
	return theme


static func _panel_style(bg: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(4)
	box.set_content_margin_all(10)
	box.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
	box.set_border_width_all(1)
	return box
