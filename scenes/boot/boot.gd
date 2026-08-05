extends Control
## Main menu entry point.

@onready var continue_button: Button = $Center/Panel/Content/Continue
@onready var transition: CanvasLayer = $TransitionOverlay


func _ready() -> void:
	var theme_service := load("res://scenes/ui/chrome/date_factory_theme.gd")
	if theme_service:
		theme_service.apply(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Shipping Continue: only normal save_slot_1. QA full-access is never menu-wired.
	_refresh_continue_availability()
	$Center/Panel/Content/NewGame.pressed.connect(_new)
	continue_button.pressed.connect(_continue)
	$Center/Panel/Content/Settings.pressed.connect(_open_settings)
	$Center/Panel/Content/Quit.pressed.connect(_quit)
	Sfx.start_menu_bed()
	# Ensure menu is never stuck behind a black fade layer.
	if transition:
		var dim := transition.get_node_or_null("Dim") as ColorRect
		if dim:
			dim.modulate.a = 0.0
			dim.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _open_settings() -> void:
	var settings := $SettingsMenu
	if settings and settings.has_method("open"):
		settings.open()


func _refresh_continue_availability() -> void:
	var has_normal_save: bool = Game.save != null and Game.save.has_save()
	continue_button.disabled = not has_normal_save


func _new() -> void:
	# Always stage_1 production start — never QA unlock matrix.
	Game.new_game()
	await _enter_game()


func _continue() -> void:
	# Guard even if button state races; never touch QA profile path.
	if Game.save == null or not Game.save.has_save():
		_refresh_continue_availability()
		return
	Game.load_game()
	await _enter_game()


func _enter_game() -> void:
	if transition and transition.has_method("fade_out"):
		await transition.fade_out(0.25)
	Sfx.stop_menu_bed()
	get_tree().change_scene_to_file("res://scenes/boot/main.tscn")


func _quit() -> void:
	get_tree().quit()
