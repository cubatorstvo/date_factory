class_name ThemeFactory
extends RefCounted
## Builds the one project Theme. Change fonts/sizes here + UiStyle colors.

const FONT_PATHS := {
	"display": "res://assets/fonts/Outfit-Bold.ttf",
	"display_medium": "res://assets/fonts/Outfit-SemiBold.ttf",
	"body": "res://assets/fonts/DMSans-Regular.ttf",
	"body_medium": "res://assets/fonts/DMSans-Medium.ttf",
	"body_bold": "res://assets/fonts/DMSans-Bold.ttf",
}

static func build() -> Theme:
	var theme := Theme.new()
	UiStyle.apply_theme(theme)
	var display_font := _load_font(FONT_PATHS.display, _load_font(FONT_PATHS.body_bold))
	var body_font := _load_font(FONT_PATHS.body, display_font)
	var medium_font := _load_font(FONT_PATHS.body_medium, body_font)
	var bold_font := _load_font(FONT_PATHS.body_bold, display_font)
	for type_name in ["Label", "Button", "CheckBox", "OptionButton", "LineEdit", "ItemList", "TabBar", "ProgressBar"]:
		theme.set_font("font", type_name, body_font)
	theme.set_font("font", "Button", medium_font)
	theme.set_font("font", "TabBar", medium_font)
	theme.set_font_size("font_size", "Button", UiStyle.SIZE_BODY)
	theme.set_font_size("font_size", "LineEdit", UiStyle.SIZE_BODY)
	theme.set_font_size("font_size", "CheckBox", UiStyle.SIZE_BODY)
	# Variation fonts (inherit Label base unless overridden)
	for var_name in ["BrandTitle", "TitleLabel", "ModalTitle", "SectionLabel"]:
		theme.set_font("font", var_name, display_font if var_name != "SectionLabel" else bold_font)
	for var_name in ["Tagline", "ControlsHint", "DateTitle", "DateHint", "DateEmotion", "HudMoney", "HudGoal", "HudHint", "HudToast", "HudWarn"]:
		theme.set_font("font", var_name, body_font)
	theme.set_font("font", "DateTitle", medium_font)
	theme.set_font("font", "SectionLabel", bold_font)
	return theme

static func _load_font(path: String, fallback: Font = null) -> Font:
	if ResourceLoader.exists(path):
		var font := load(path) as Font
		if font != null:
			return font
	return fallback
