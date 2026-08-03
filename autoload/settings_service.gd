extends Node

const SETTINGS_PATH := "user://settings.cfg"
const BUS_NAMES := [&"Master", &"Music", &"SFX", &"UI", &"Ambient"]

var master_vol: float = 1.0
var music_vol: float = 0.75
var sfx_vol: float = 0.85
var ui_vol: float = 0.85
var ambient_vol: float = 0.65
var mouse_sens: float = 1.0
var invert_y: bool = true
var fov: float = 80.0
var head_bob: bool = true
var camera_shake: float = 0.75
var fullscreen: bool = false
var window_width: int = 1280
var window_height: int = 720

func _ready() -> void:
	load_settings()
	apply_all()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for property_name in _settings_keys():
		if config.has_section_key("settings", property_name):
			set(property_name, config.get_value("settings", property_name))
	_clamp_values()

func save_settings() -> void:
	var config := ConfigFile.new()
	for property_name in _settings_keys():
		config.set_value("settings", property_name, get(property_name))
	config.save(SETTINGS_PATH)

func apply_all() -> void:
	_ensure_buses()
	_apply_bus(&"Master", master_vol)
	_apply_bus(&"Music", music_vol)
	_apply_bus(&"SFX", sfx_vol)
	_apply_bus(&"UI", ui_vol)
	_apply_bus(&"Ambient", ambient_vol)
	var window := get_tree().root
	window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen:
		window.size = Vector2i(window_width, window_height)

func get_setting(property_name: StringName) -> Variant:
	return get(property_name)

func set_setting(property_name: StringName, value: Variant, apply: bool = false) -> void:
	if property_name in _settings_keys():
		set(property_name, value)
		_clamp_values()
		if apply:
			apply_all()

func _settings_keys() -> Array[StringName]:
	return [&"master_vol", &"music_vol", &"sfx_vol", &"ui_vol", &"ambient_vol", &"mouse_sens", &"invert_y", &"fov", &"head_bob", &"camera_shake", &"fullscreen", &"window_width", &"window_height"]

func _clamp_values() -> void:
	master_vol = clampf(master_vol, 0.0, 1.0)
	music_vol = clampf(music_vol, 0.0, 1.0)
	sfx_vol = clampf(sfx_vol, 0.0, 1.0)
	ui_vol = clampf(ui_vol, 0.0, 1.0)
	ambient_vol = clampf(ambient_vol, 0.0, 1.0)
	mouse_sens = clampf(mouse_sens, 0.5, 3.0)
	fov = clampf(fov, 60.0, 110.0)
	camera_shake = clampf(camera_shake, 0.0, 1.0)
	window_width = clampi(window_width, 800, 3840)
	window_height = clampi(window_height, 600, 2160)

func _ensure_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)

func _apply_bus(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
