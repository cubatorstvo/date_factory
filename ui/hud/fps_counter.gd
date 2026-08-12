extends CanvasLayer
class_name FpsCounter
## Lightweight runtime FPS display controlled by the persisted display setting.

const UPDATE_INTERVAL_SECONDS: float = 0.25

@onready var _label: Label = %FpsLabel
var _elapsed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system != null and save_system.has_signal("settings_applied"):
		var callback: Callable = Callable(self, "_on_settings_applied")
		if not save_system.is_connected("settings_applied", callback):
			save_system.connect("settings_applied", callback)
	_refresh_visibility()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed < UPDATE_INTERVAL_SECONDS:
		return
	_elapsed = 0.0
	_update_label()


func _on_settings_applied() -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var enabled: bool = false
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system != null and save_system.has_method("get_settings"):
		var settings: Dictionary = save_system.call("get_settings")
		enabled = bool(settings.get("show_fps", false))
	visible = enabled
	_elapsed = 0.0
	if visible:
		_update_label()


func _update_label() -> void:
	_label.text = "FPS: %d" % int(Engine.get_frames_per_second())
