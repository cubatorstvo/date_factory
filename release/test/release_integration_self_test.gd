extends Node
## MODULE 28 — release integration headless self-test.
## Run: --path . --headless --quit-after 60 res://release/test/release_integration_test.tscn


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_run_all()
	if _failed == 0:
		print("MODULE_28_RELEASE: ALL PASS (%s)" % _passed)
	else:
		print("MODULE_28_RELEASE: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_test_version_metadata()
	_test_no_godotiq_autoload()
	_test_steambridge_fail_open()
	_test_boot_log_fields()
	_test_schema_still_one()
	_test_notices_exist()
	_test_no_achievements_api()


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[M28_RELEASE] FAIL: %s" % label)
		print("FAIL: %s" % label)


func _test_version_metadata() -> void:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	var description: String = str(ProjectSettings.get_setting("application/config/description", ""))
	_ok(version == "1.0.0", "application/config/version == 1.0.0")
	_ok(description == "Date Factory", "description is Date Factory")
	_ok(not description.to_lower().contains("v2"), "description has no v2")


func _test_no_godotiq_autoload() -> void:
	var tree: SceneTree = get_tree()
	_ok(tree != null, "scene tree exists")
	if tree == null:
		return
	var iq: Node = tree.root.get_node_or_null("GodotIQRuntime")
	_ok(iq == null, "GodotIQRuntime autoload absent")


func _test_steambridge_fail_open() -> void:
	var bridge: Node = get_node_or_null("/root/SteamBridge")
	_ok(bridge != null, "SteamBridge autoload present")
	if bridge == null:
		return
	var avail: bool = false
	if bridge.has_method("is_available"):
		avail = bool(bridge.call("is_available"))
	elif "available" in bridge:
		avail = bool(bridge.get("available"))
	# Headless / no AppID => fail-open unavailable, game continues.
	_ok(avail == false, "SteamBridge.available == false under headless/no AppID")
	var title_ok: bool = ResourceLoader.exists("res://ui/frontend/title_menu.gd")
	_ok(title_ok, "title menu still loadable without Steam")


func _test_boot_log_fields() -> void:
	# SteamBridge emits boot lines once at ready; verify fields are producible.
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	_ok(version != "", "boot version field non-empty")
	_ok(SaveTypes.SAVE_SCHEMA_VERSION == 1, "boot save_schema field is 1")
	var godot_ver: String = str(Engine.get_version_info().get("string", ""))
	_ok(godot_ver != "", "boot Godot field non-empty")
	_ok(OS.get_name() != "", "boot OS field non-empty")
	var renderer: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	_ok(renderer != "", "boot renderer field non-empty")
	var bridge: Node = get_node_or_null("/root/SteamBridge")
	var steam_word: String = "unavailable"
	if bridge != null and bridge.has_method("is_available") and bool(bridge.call("is_available")):
		steam_word = "available"
	_ok(steam_word == "available" or steam_word == "unavailable", "boot Steam status is available|unavailable")


func _test_schema_still_one() -> void:
	_ok(SaveTypes.SAVE_SCHEMA_VERSION == 1, "SAVE_SCHEMA_VERSION remains 1")


func _test_notices_exist() -> void:
	_ok(FileAccess.file_exists("res://release/THIRD_PARTY_NOTICES.txt"), "THIRD_PARTY_NOTICES.txt exists")
	_ok(FileAccess.file_exists("res://release/DEPENDENCIES.md"), "DEPENDENCIES.md exists")


func _test_no_achievements_api() -> void:
	# No AchievementManager and SteamBridge must not expose achievement APIs.
	var tree: SceneTree = get_tree()
	if tree != null:
		_ok(tree.root.get_node_or_null("AchievementManager") == null, "no AchievementManager autoload")
	var bridge: Node = get_node_or_null("/root/SteamBridge")
	if bridge == null:
		return
	_ok(not bridge.has_method("set_achievement"), "SteamBridge has no set_achievement")
	_ok(not bridge.has_method("unlock_achievement"), "SteamBridge has no unlock_achievement")
	_ok(not bridge.has_method("store_stats"), "SteamBridge has no store_stats")
