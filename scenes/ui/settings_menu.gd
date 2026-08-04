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
@onready var motion_effects: CheckBox = $Center/Panel/Content/MotionEffects
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
	var panel := $Center/Panel as Control
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.26)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.26)


func close() -> void:
	var panel := $Center/Panel as Control
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.16)
	tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.16)
	await tween.finished
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
	if motion_effects:
		settings.motion_effects = motion_effects.button_pressed
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
	if motion_effects:
		motion_effects.button_pressed = bool(settings.motion_effects)
	if fullscreen:
		fullscreen.button_pressed = bool(settings.fullscreen)
