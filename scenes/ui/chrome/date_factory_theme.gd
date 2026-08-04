class_name DateFactoryTheme
extends RefCounted
## Applies the production UI theme at CanvasLayer and scene boundaries.

const THEME_PATH := "res://assets/ui/date_factory_theme.tres"


static func apply(root: Node) -> void:
	var production_theme := load(THEME_PATH) as Theme
	if production_theme == null:
		push_warning("DATE FACTORY theme is missing")
		return
	if root is Control:
		(root as Control).theme = production_theme
	for node: Node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null:
			continue
		if not control.get_parent() is Control:
			control.theme = production_theme
	for node: Node in root.find_children("*", "BaseButton", true, false):
		bind_button(node as BaseButton)


static func bind_button(button: BaseButton) -> void:
	if button == null or button.has_meta(&"df_audio_bound"):
		return
	button.set_meta(&"df_audio_bound", true)
	# Menus/popups: activate on release so press-during-mouse-mode-swap cannot fire.
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			Sfx.play_ui(&"hover")
	)
	button.focus_entered.connect(func() -> void:
		if not button.disabled:
			Sfx.play_ui(&"hover")
	)
	button.pressed.connect(func() -> void: Sfx.play_ui(&"click"))
