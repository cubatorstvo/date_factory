extends Node
## MODULE 28 — minimal fail-open Steam bootstrap. No gameplay/save state.
## Autoload name: SteamBridge

var available: bool = false
var _pump_callbacks: bool = false
var _boot_logged: bool = false
var _app_id: int = 0


func _ready() -> void:
	_app_id = _resolve_app_id()
	_try_init_steam()
	_emit_boot_log_once()


func _process(_delta: float) -> void:
	if not _pump_callbacks or not available:
		return
	var steam: Object = _steam_singleton()
	if steam != null and steam.has_method("run_callbacks"):
		steam.call("run_callbacks")


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_shutdown_steam()


func is_available() -> bool:
	return available


func get_app_id() -> int:
	return _app_id


func _resolve_app_id() -> int:
	var from_file: int = _read_generated_app_id()
	if from_file > 0:
		return from_file
	if ProjectSettings.has_setting("date_factory/steam/app_id"):
		var from_ps: int = int(ProjectSettings.get_setting("date_factory/steam/app_id"))
		if from_ps > 0:
			return from_ps
	return 0


func _read_generated_app_id() -> int:
	var path: String = "res://release/generated_steam_config.cfg"
	if not FileAccess.file_exists(path):
		return 0
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(path)
	if err != OK:
		return 0
	return int(cfg.get_value("steam", "app_id", 0))


func _is_headless() -> bool:
	if OS.has_feature("headless"):
		return true
	return DisplayServer.get_name() == "headless"


func _steam_singleton() -> Object:
	if Engine.has_singleton("Steam"):
		return Engine.get_singleton("Steam")
	var tree: SceneTree = get_tree()
	if tree != null:
		var n: Node = tree.root.get_node_or_null("Steam")
		if n != null:
			return n
	return null


func _try_init_steam() -> void:
	available = false
	_pump_callbacks = false
	# Headless QA must never depend on Steam client.
	if _is_headless():
		print("[SteamBridge] headless: Steam init skipped (unavailable)")
		return
	if _app_id <= 0:
		print("[SteamBridge] no AppID configured: Steam init skipped (unavailable)")
		return
	var steam: Object = _steam_singleton()
	if steam == null:
		print("[SteamBridge] Steam singleton missing: unavailable")
		return
	# Optional RestartAppIfNecessary only when AppID > 0.
	if steam.has_method("restartAppIfNecessary"):
		var needs_restart: Variant = steam.call("restartAppIfNecessary", _app_id)
		if bool(needs_restart):
			print("[SteamBridge] RestartAppIfNecessary requested quit")
			var tree: SceneTree = get_tree()
			if tree != null:
				tree.quit()
			return
	if not steam.has_method("steamInitEx"):
		print("[SteamBridge] steamInitEx missing: unavailable")
		return
	var init_result: Variant = steam.call("steamInitEx", _app_id, false)
	var status: int = 1
	var verbal: String = ""
	if init_result is Dictionary:
		var d: Dictionary = init_result
		status = int(d.get("status", 1))
		verbal = str(d.get("verbal", ""))
	elif typeof(init_result) == TYPE_BOOL:
		status = 0 if bool(init_result) else 1
	if status == 0:
		available = true
		_pump_callbacks = true
		print("[SteamBridge] Steam available (init ok)")
	else:
		available = false
		_pump_callbacks = false
		print("[SteamBridge] Steam init failed-open status=%s verbal=%s" % [status, verbal])


func _shutdown_steam() -> void:
	if not available:
		return
	var steam: Object = _steam_singleton()
	if steam != null and steam.has_method("steamShutdown"):
		steam.call("steamShutdown")
	available = false
	_pump_callbacks = false


func _emit_boot_log_once() -> void:
	if _boot_logged:
		return
	_boot_logged = true
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	var godot_ver: String = Engine.get_version_info().get("string", "?") as String
	var os_name: String = OS.get_name()
	var renderer: String = _renderer_name()
	var steam_status: String = "available" if available else "unavailable"
	# Always print so release file logging captures boot (DfLog.info is debug-gated).
	print("DATE FACTORY")
	print("version=%s" % version)
	print("save_schema=1")
	print("Godot=%s" % godot_ver)
	print("OS=%s" % os_name)
	print("renderer=%s" % renderer)
	print("Steam=%s" % steam_status)


func _renderer_name() -> String:
	var method: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	if method.strip_edges() != "":
		return method
	return "unknown"
