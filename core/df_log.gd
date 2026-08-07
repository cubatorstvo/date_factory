class_name DfLog
extends RefCounted
## Tiny debug logger for Date Factory infrastructure.
## Not an autoload: call DfLog.info/warn/error from code.
## Debug/info are suppressed outside debug/editor builds.


static func info(module: String, message: String) -> void:
	if not OS.is_debug_build() and not OS.has_feature("editor"):
		return
	print("[DF][%s] %s" % [module, message])


static func warn(module: String, message: String) -> void:
	push_warning("[DF][%s] %s" % [module, message])


static func error(module: String, message: String) -> void:
	push_error("[DF][%s] %s" % [module, message])
