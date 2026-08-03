class_name UiStyle
extends RefCounted
## Single source of truth for DATE FACTORY UI colors/sizes.
## Visuals are applied via ThemeFactory → root.theme.
## Scenes should use theme_type_variation, not local color/size copies.
## ColorRects (dim/bg) use chrome/ui_fill.gd with a fill_role.

const BG_DEEP := Color("140C18")
const PANEL := Color("241828")
const PANEL_HI := Color("322036")
const STROKE := Color("E8B86D")
const ACCENT := Color("FF4D8D")
const ACCENT_2 := Color("6EE7FF")
const OK := Color("5DDEA4")
const WARN := Color("FFB454")
const BAD := Color("FF6B6B")
const TEXT := Color("F7F0E8")
const TEXT_DIM := Color("B5A8B8")
const MONEY := Color("F0D078")

const DIM_OVERLAY := Color(0.05, 0.02, 0.08, 0.62)
const DIM_SOFT := Color(0.05, 0.02, 0.08, 0.18)
const ACCENT_GLOW := Color(1.0, 0.3, 0.55, 0.08)

const SIZE_BRAND := 48
const SIZE_TITLE := 34
const SIZE_MODAL_TITLE := 26
const SIZE_SECTION := 20
const SIZE_BODY := 16
const SIZE_SMALL := 13


static func panel_box(color: Color = PANEL, radius: int = 14, border_color: Color = STROKE, border_width: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


static func button_box(state: StringName) -> StyleBoxFlat:
	match state:
		&"hover":
			return panel_box(ACCENT.lightened(0.08), 10, STROKE, 2)
		&"pressed":
			return panel_box(ACCENT.darkened(0.18), 10, STROKE.darkened(0.2), 2)
		&"disabled":
			return panel_box(PANEL_HI.darkened(0.12), 10, TEXT_DIM.darkened(0.3), 1)
		&"focus":
			return panel_box(ACCENT, 10, TEXT, 2)
		_:
			return panel_box(ACCENT, 10, STROKE, 2)


static func fill_color(role: StringName) -> Color:
	match role:
		&"bg":
			return BG_DEEP
		&"accent_glow":
			return ACCENT_GLOW
		&"dim_soft":
			return DIM_SOFT
		_:
			return DIM_OVERLAY


static func apply_theme(theme: Theme) -> void:
	_apply_base_controls(theme)
	_apply_label_variations(theme)


static func _apply_base_controls(theme: Theme) -> void:
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		theme.set_stylebox(str(state), "Button", button_box(state))
	theme.set_constant("outline_size", "Button", 0)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", BG_DEEP)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_font_size("font_size", "Label", SIZE_BODY)

	theme.set_stylebox("panel", "PanelContainer", panel_box())
	theme.set_stylebox("panel", "TabContainer", panel_box(PANEL_HI, 10, STROKE, 1))
	theme.set_stylebox("panel", "ItemList", panel_box(PANEL, 10))
	theme.set_stylebox("normal", "LineEdit", panel_box(PANEL_HI, 8, STROKE, 1))
	theme.set_stylebox("read_only", "LineEdit", panel_box(PANEL, 8, TEXT_DIM, 1))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_color("font_selected_color", "ItemList", BG_DEEP)
	theme.set_color("guide_color", "HSlider", TEXT_DIM)
	theme.set_stylebox("slider", "HSlider", panel_box(PANEL_HI, 6, STROKE, 1))
	theme.set_stylebox("grabber_area", "HSlider", panel_box(ACCENT, 8, STROKE, 1))
	theme.set_stylebox("background", "ProgressBar", panel_box(PANEL, 8, STROKE, 1))
	theme.set_stylebox("fill", "ProgressBar", panel_box(ACCENT, 8, ACCENT, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_stylebox("normal", "OptionButton", panel_box(PANEL_HI, 8, STROKE, 1))


static func _apply_label_variations(theme: Theme) -> void:
	# Boot / hero
	_label_var(theme, "BrandTitle", ACCENT, SIZE_BRAND)
	_label_var(theme, "Tagline", TEXT, 17)
	_label_var(theme, "ControlsHint", TEXT_DIM, SIZE_SMALL)
	# Shared modal chrome
	_label_var(theme, "ModalTitle", ACCENT, SIZE_MODAL_TITLE)
	_label_var(theme, "TitleLabel", ACCENT, SIZE_TITLE)
	_label_var(theme, "SectionLabel", TEXT, SIZE_SECTION)
	# Date overlay
	_label_var(theme, "DateTitle", ACCENT, 20)
	_label_var(theme, "DateHint", ACCENT_2, SIZE_SMALL)
	_label_var(theme, "DateEmotion", Color(1.0, 0.75, 0.85), SIZE_BODY)
	# HUD
	_label_var(theme, "HudMoney", MONEY, SIZE_BODY)
	_label_var(theme, "HudGoal", ACCENT_2, 15)
	_label_var(theme, "HudHint", STROKE, SIZE_BODY)
	_label_var(theme, "HudToast", TEXT, 18)
	_label_var(theme, "HudWarn", WARN, SIZE_BODY)


static func _label_var(theme: Theme, type_name: String, color: Color, size: int) -> void:
	theme.set_type_variation(type_name, "Label")
	theme.set_color("font_color", type_name, color)
	theme.set_font_size("font_size", type_name, size)
