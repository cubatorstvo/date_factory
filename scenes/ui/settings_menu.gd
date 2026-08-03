class_name SettingsMenu
extends CanvasLayer

const BINDINGS := {
	"Master": &"master_vol",
	"Music": &"music_vol",
	"Sfx": &"sfx_vol",
	"Ui": &"ui_vol",
	"Ambient": &"ambient_vol",
	"Sensitivity": &"mouse_sens",
	"Fov": &"fov",
	"Shake": &"camera_shake",
}

@onready var fullscreen: CheckBox = $Center/Panel/Content/Fullscreen
@onready var invert_y: CheckBox = $Center/Panel/Content/InvertY
@onready var head_bob: CheckBox = $Center/Panel/Content/HeadBob
@onready var apply_button: Button = $Center/Panel/Content/Actions/Apply
@onready var back_button: Button = $Center/Panel/Content/Actions/Back


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("settings_ui")
	if apply_button:
		apply_button.pressed.connect(apply)
	if back_button:
		back_button.pressed.connect(close)


func open() -> void:
	_load_values()
	visible = true


func close() -> void:
	visible = false


func apply() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return
	var content := $Center/Panel/Content
	for node_name in BINDINGS:
		var slider := content.get_node_or_null(NodePath(node_name)) as HSlider
		if slider:
			settings.set_setting(BINDINGS[node_name], slider.value)
	if invert_y:
		settings.invert_y = invert_y.button_pressed
	if head_bob:
		settings.head_bob = head_bob.button_pressed
	if fullscreen:
		settings.fullscreen = fullscreen.button_pressed
	settings.apply_all()
	settings.save_settings()
	Sfx.play_ui(&"confirm")
	close()


func _load_values() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return
	var content := $Center/Panel/Content
	for node_name in BINDINGS:
		var slider := content.get_node_or_null(NodePath(node_name)) as HSlider
		if slider:
			slider.value = float(settings.get_setting(BINDINGS[node_name]))
	if invert_y:
		invert_y.button_pressed = bool(settings.invert_y)
	if head_bob:
		head_bob.button_pressed = bool(settings.head_bob)
	if fullscreen:
		fullscreen.button_pressed = bool(settings.fullscreen)
