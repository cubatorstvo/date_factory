extends Node
## MODULE 24 world pose capture/restore smoke (MODULE_24 §§44–52).
## Run: res://world/test/world_save_pose_test.tscn --quit-after 20000

var _failed: int = 0
var _passed: int = 0
var _world: Node = null
var _gs: Node = null


func _ready() -> void:
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_24_WORLD_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_24_WORLD_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_24_WORLD_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_24_WORLD_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_24_WORLD_TEST] FAIL: %s" % label)
		print("MODULE_24_WORLD_TEST FAIL: %s" % label)


func _run_all() -> void:
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	await get_tree().process_frame
	await _test_pose_roundtrip()
	await _test_invalid_pose_keeps_spawn()
	await _test_unknown_location_apartment_fallback()
	await _test_title_boot_hooks()


func _test_pose_roundtrip() -> void:
	var boot: int = int(_world.call("reset_to_start"))
	_ok(boot == int(WorldTypes.WorldTravelResult.SUCCESS), "boot apartment")
	var travel: int = int(_world.call("request_travel", &"city_hub", &"spawn_default"))
	_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "travel city_hub")
	var player: PlayerController = _world.call("get_player") as PlayerController
	_ok(player != null, "player present")
	if player == null:
		return
	# Offset from spawn while staying on floor-ish area.
	var base: Vector3 = player.global_position
	var target: Vector3 = base + Vector3(0.35, 0.0, -0.25)
	var yaw: float = 0.7
	var pitch: float = -0.25
	player.velocity = Vector3(1.0, 0.0, 1.0)
	var apply_ok: bool = bool(player.apply_pose_dict({
		"position": [target.x, target.y, target.z],
		"yaw": yaw,
		"pitch": pitch,
	}))
	_ok(apply_ok, "apply_pose_dict ok")
	_ok(player.velocity == Vector3.ZERO, "velocity cleared on apply")
	_ok(player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY, "GAMEPLAY after apply")
	var exported: Dictionary = _world.call("export_world_save_state") as Dictionary
	_ok(String(exported.get("location_id", "")) == "city_hub", "export location_id")
	var pose: Dictionary = exported.get("player", {}) as Dictionary
	_ok(pose.has("position") and pose.has("yaw") and pose.has("pitch"), "export player keys")
	var pos_arr: Array = pose.get("position", []) as Array
	_ok(pos_arr.size() == 3, "export position array")
	if pos_arr.size() == 3:
		var exported_pos: Vector3 = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
		_ok(exported_pos.distance_to(target) < 0.05, "export position approx")
	_ok(is_equal_approx(float(pose.get("yaw", 0.0)), yaw), "export yaw")
	_ok(is_equal_approx(float(pose.get("pitch", 0.0)), pitch), "export pitch")
	# Move away, then restore.
	player.global_position = base + Vector3(2.0, 0.0, 2.0)
	var restore_ok: bool = bool(_world.call("restore_saved_location", &"city_hub", pose))
	_ok(restore_ok, "restore_saved_location ok")
	_ok(String(_world.get("current_location_id")) == "city_hub", "restored location")
	var restored: Vector3 = player.global_position
	_ok(restored.distance_to(target) < 0.15, "restored position approx")
	_ok(is_equal_approx(player.rotation.y, yaw), "restored yaw")
	var pivot: Node3D = player.get_node_or_null("CameraPivot") as Node3D
	if pivot != null:
		_ok(is_equal_approx(pivot.rotation.x, pitch), "restored pitch")
	else:
		_ok(false, "camera pivot")


func _test_invalid_pose_keeps_spawn() -> void:
	var travel: int = int(_world.call("request_travel", &"city_hub", &"spawn_default"))
	_ok(travel == int(WorldTypes.WorldTravelResult.SUCCESS), "invalid-pose setup travel")
	var player: PlayerController = _world.call("get_player") as PlayerController
	if player == null:
		_ok(false, "invalid-pose player")
		return
	var spawn_pos: Vector3 = player.global_position
	var bad_pose: Dictionary = {
		"position": [50000.0, 50000.0, 50000.0],
		"yaw": 0.0,
		"pitch": 0.0,
	}
	var restore_ok: bool = bool(_world.call("restore_saved_location", &"city_hub", bad_pose))
	_ok(restore_ok, "invalid pose restore still succeeds")
	_ok(String(_world.get("current_location_id")) == "city_hub", "invalid pose keeps location")
	# After restore travel, player starts at spawn; bad pose rejected → still near spawn.
	_ok(player.global_position.distance_to(spawn_pos) < 2.5, "invalid pose keeps spawn")


func _test_unknown_location_apartment_fallback() -> void:
	var pose: Dictionary = {
		"position": [0.0, 1.0, 0.0],
		"yaw": 0.0,
		"pitch": 0.0,
	}
	var restore_ok: bool = bool(_world.call("restore_saved_location", &"moon_base_unknown", pose))
	_ok(restore_ok, "unknown location restore ok via fallback")
	_ok(String(_world.get("current_location_id")) == "apartment", "unknown → apartment")


func _test_title_boot_hooks() -> void:
	_world.call("prepare_for_title")
	var deferred: int = int(_world.call("boot_from_main"))
	_ok(deferred == int(WorldTypes.WorldTravelResult.SUCCESS), "boot_from_main deferred ok")
	# prepare_for_title suppresses auto apartment travel; location may stay previous.
	var new_boot: int = int(_world.call("begin_new_game_boot"))
	_ok(new_boot == int(WorldTypes.WorldTravelResult.SUCCESS), "begin_new_game_boot")
	_ok(String(_world.get("current_location_id")) == "apartment", "new game apartment")
	_world.call("suppress_auto_reset_on_state_reset", true)
	_world.call("suppress_auto_reset_on_state_reset", false)
	_ok(true, "suppress_auto_reset hooks callable")
	_ok(_world.has_method("notify_post_load_visuals"), "notify_post_load_visuals exposed")
	_world.call("notify_post_load_visuals")
