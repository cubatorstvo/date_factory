extends Node
## MODULE 12 World & Location Framework self-test (spec §§117–155).
## Run: res://world/test/world_location_test.tscn --quit-after 20000

var _failed: int = 0
var _passed: int = 0
var _world: Node = null
var _gs: Node = null
var _story: Node = null
var _db: Node = null
var _changed_pairs: Array[String] = []
var _rejected: Array[int] = []
var _busy_from_loading: int = -1
var _nested_busy_armed: bool = false


func _ready() -> void:
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	_story = get_node("/root/Story")
	_db = get_node("/root/ContentDB")
	await get_tree().process_frame
	if _world.has_signal("location_changed") and not _world.is_connected("location_changed", _on_location_changed):
		_world.connect("location_changed", _on_location_changed)
	if _world.has_signal("travel_rejected") and not _world.is_connected("travel_rejected", _on_travel_rejected):
		_world.connect("travel_rejected", _on_travel_rejected)
	if _world.has_signal("location_loading") and not _world.is_connected("location_loading", _on_location_loading):
		_world.connect("location_loading", _on_location_loading)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_12_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_12_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_12_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_12_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_12_TEST] FAIL: %s" % label)
		print("MODULE_12_TEST FAIL: %s" % label)


func _on_location_changed(new_id: StringName, prev_id: StringName) -> void:
	_changed_pairs.append("%s<-%s" % [String(new_id), String(prev_id)])


func _on_travel_rejected(_target: StringName, reason: WorldTypes.WorldTravelResult) -> void:
	_rejected.append(int(reason))


func _on_location_loading(_location_id: StringName) -> void:
	if _nested_busy_armed:
		_busy_from_loading = int(_world.call("request_travel", &"cafe", &"spawn_default"))
		_nested_busy_armed = false


func _travel(id: StringName, spawn: StringName = &"spawn_default") -> int:
	return int(_world.call("request_travel", id, spawn))


func _access(id: StringName) -> WorldAccessResult:
	return _world.call("get_location_access", id) as WorldAccessResult


func _stage() -> int:
	return int(_gs.call("get_stage"))


func _restore(stage: GameTypes.GameStage) -> void:
	_gs.call("restore_stage", stage)
	await get_tree().process_frame


func _reset_state() -> void:
	_gs.call("reset_for_new_game")
	await get_tree().process_frame


func _run_all() -> void:
	_test_contentdb_paths()
	await _test_start_apartment()
	await _test_prologue_access()
	await _test_stage1_access()
	await _test_public_gate()
	await _test_late_access_matrix()
	await _test_gamestate_unlock_not_bypass()
	await _test_travel_roundtrips()
	await _test_locked_unknown_busy()
	await _test_scene_spawn_errors()
	await _test_markers_and_npc()
	await _test_phone()
	await _test_downgrade_and_reset()
	await _test_no_mutations()


func _test_contentdb_paths() -> void:
	var locs: Array = _db.call("list_locations") as Array
	_ok(locs.size() == 9, "117 locations count 9")
	var ids: Array[StringName] = [
		&"apartment", &"city_hub", &"cafe", &"gym", &"appearance_space",
		&"salary_mine", &"laboratory", &"production_area", &"final_location",
	]
	for lid in ids:
		var def: LocationDefinition = _db.call("get_location", lid) as LocationDefinition
		_ok(def != null and def.scene_path != "", "118 path non-empty %s" % String(lid))
		var errors: Array = _world.call("validate_location_scene", lid) as Array
		_ok(errors.is_empty(), "118/119 validate %s (%s)" % [String(lid), ",".join(errors)])
	var catalog_result: Dictionary = _db.call("validate_all") as Dictionary
	_ok(bool(catalog_result.get("ok", false)), "ContentDB validate_all ok")


func _test_start_apartment() -> void:
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	await _reset_state()
	_world.call("clear_scene_path_overrides_for_test")
	_world.call("clear_access_provider_for_test")
	_world.call("set_spawn_fallback_enabled_for_test", true)
	var boot: int = int(_world.call("reset_to_start"))
	_ok(boot == int(WorldTypes.WorldTravelResult.SUCCESS), "120 reset_to_start SUCCESS")
	_ok(String(_world.get("current_location_id")) == "apartment", "120 current apartment")
	var player: PlayerController = _world.call("get_player") as PlayerController
	_ok(player != null, "120 player present")
	if player != null:
		_ok(player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY, "120 GAMEPLAY")


func _expect_access(id: StringName, available: bool, label: String) -> void:
	var a: WorldAccessResult = _access(id)
	if available:
		_ok(a != null and a.status == WorldTypes.WorldAccessStatus.AVAILABLE, label)
	else:
		_ok(a != null and a.status == WorldTypes.WorldAccessStatus.LOCKED_STORY, label)


func _test_prologue_access() -> void:
	await _restore(GameTypes.GameStage.PROLOGUE)
	_expect_access(&"apartment", true, "121 apartment AVAILABLE")
	for lid in [&"city_hub", &"cafe", &"gym", &"appearance_space", &"salary_mine", &"laboratory", &"production_area", &"final_location"]:
		_expect_access(lid, false, "121 %s LOCKED" % String(lid))


func _test_stage1_access() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_expect_access(&"apartment", true, "122 apartment")
	_expect_access(&"city_hub", true, "122 city")
	_expect_access(&"cafe", true, "122 cafe")
	_expect_access(&"gym", true, "122 gym")
	_expect_access(&"appearance_space", true, "122 appearance")
	_expect_access(&"salary_mine", false, "122 mine locked")
	_expect_access(&"laboratory", false, "122 lab locked")
	_expect_access(&"production_area", false, "122 production locked")
	_expect_access(&"final_location", false, "122 final locked")


func _test_public_gate() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "123 travel city")
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	_ok(loc != null, "123 location")
	var gate: WorldFeatureGate = null
	if loc != null:
		gate = loc.find_feature_gate(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS)
	_ok(gate != null, "123 PUBLIC gate exists")
	if gate != null:
		_ok(not gate.is_unlocked(), "123 STAGE1 locked")
		_ok(gate.is_barrier_visible(), "123 barrier visible")
		_ok(gate.is_collision_enabled(), "123 collision enabled")
	await _restore(GameTypes.GameStage.STAGE_2)
	_world.call("refresh_current_gates")
	await get_tree().process_frame
	if gate != null and is_instance_valid(gate):
		_ok(gate.is_unlocked(), "124 STAGE2 unlocked")
		_ok(not gate.is_barrier_visible(), "124 barrier hidden")
		_ok(not gate.is_collision_enabled(), "124 collision off")
	else:
		_ok(false, "124 gate still valid")


func _test_late_access_matrix() -> void:
	await _restore(GameTypes.GameStage.STAGE_2)
	_expect_access(&"salary_mine", false, "125 STAGE2 mine locked")
	await _restore(GameTypes.GameStage.STAGE_3)
	_expect_access(&"salary_mine", true, "125 STAGE3 mine available")
	_ok(not bool(_gs.call("is_location_unlocked", &"salary_mine")), "129 GS unlock empty seam")
	await _restore(GameTypes.GameStage.STAGE_4)
	_expect_access(&"laboratory", false, "126 STAGE4 lab locked")
	await _restore(GameTypes.GameStage.STAGE_5)
	_expect_access(&"laboratory", true, "126 STAGE5 lab available")
	_expect_access(&"production_area", false, "127 STAGE5 production locked")
	await _restore(GameTypes.GameStage.STAGE_6)
	_expect_access(&"production_area", true, "127 STAGE6 production available")
	_expect_access(&"final_location", false, "128 STAGE6 final locked")
	await _restore(GameTypes.GameStage.FINALE)
	_expect_access(&"final_location", true, "128 FINALE final available")


func _test_gamestate_unlock_not_bypass() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_gs.call("unlock_location", &"laboratory")
	_expect_access(&"laboratory", false, "130 unlock_location does not bypass Story")


func _test_travel_roundtrips() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(int(_world.call("reset_to_start")) == int(WorldTypes.WorldTravelResult.SUCCESS), "131 reset apt")
	var player: PlayerController = _world.call("get_player") as PlayerController
	if player != null:
		player.velocity = Vector3(3, 0, 3)
	_changed_pairs.clear()
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "131 apt->city")
	_ok(String(_world.get("current_location_id")) == "city_hub", "131 current city")
	if player != null:
		_ok(player.velocity == Vector3.ZERO, "131 velocity zero")
	_ok(_changed_pairs.size() >= 1, "140 location_changed emitted")
	_ok(_travel(&"apartment") == int(WorldTypes.WorldTravelResult.SUCCESS), "132 city->apt")
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "133 back city")
	for spoke in [&"cafe", &"gym", &"appearance_space"]:
		_ok(_travel(spoke) == int(WorldTypes.WorldTravelResult.SUCCESS), "133 to %s" % String(spoke))
		_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "133 from %s" % String(spoke))
	await _restore(GameTypes.GameStage.FINALE)
	for spoke2 in [&"salary_mine", &"laboratory", &"production_area", &"final_location"]:
		_ok(_travel(spoke2) == int(WorldTypes.WorldTravelResult.SUCCESS), "133 late to %s" % String(spoke2))
		_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "133 late from %s" % String(spoke2))


func _test_locked_unknown_busy() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "134 setup city")
	var before: String = String(_world.get("current_location_id"))
	var pos_before: Vector3 = Vector3.ZERO
	var player: PlayerController = _world.call("get_player") as PlayerController
	if player != null:
		pos_before = player.global_position
	_rejected.clear()
	_ok(_travel(&"salary_mine") == int(WorldTypes.WorldTravelResult.LOCKED), "134 LOCKED")
	_ok(String(_world.get("current_location_id")) == before, "134 no mutation id")
	if player != null:
		_ok(player.global_position.is_equal_approx(pos_before), "134 no mutation pos")
	_ok(not bool(_world.call("is_busy")), "134 not busy after reject")
	_ok(_travel(&"moon_base") == int(WorldTypes.WorldTravelResult.UNKNOWN_LOCATION), "135 UNKNOWN")
	_nested_busy_armed = true
	_busy_from_loading = -1
	var ok_travel: int = _travel(&"cafe")
	_ok(ok_travel == int(WorldTypes.WorldTravelResult.SUCCESS), "139 primary travel ok")
	_ok(_busy_from_loading == int(WorldTypes.WorldTravelResult.BUSY), "139 nested BUSY")


func _test_scene_spawn_errors() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "136 setup")
	var before: String = String(_world.get("current_location_id"))
	_world.call("set_scene_path_override_for_test", &"cafe", "res://world/test/fixtures/does_not_exist.tscn")
	var missing: int = _travel(&"cafe")
	_ok(
		missing == int(WorldTypes.WorldTravelResult.SCENE_MISSING)
		or missing == int(WorldTypes.WorldTravelResult.LOAD_FAILED),
		"136 SCENE_MISSING/LOAD_FAILED"
	)
	_ok(String(_world.get("current_location_id")) == before, "136 intact after missing")
	_world.call("set_scene_path_override_for_test", &"gym", "res://world/test/fixtures/spawn_missing_location.tscn")
	_world.call("set_spawn_fallback_enabled_for_test", false)
	var spawn_miss: int = _travel(&"gym", &"spawn_nope")
	_ok(spawn_miss == int(WorldTypes.WorldTravelResult.SPAWN_MISSING), "137 SPAWN_MISSING")
	_ok(String(_world.get("current_location_id")) == before, "137 intact after spawn miss")
	_world.call("clear_scene_path_overrides_for_test")
	_world.call("set_spawn_fallback_enabled_for_test", true)
	_ok(_travel(&"cafe", &"spawn_does_not_exist") == int(WorldTypes.WorldTravelResult.SUCCESS), "138 spawn fallback")
	_ok(String(_world.get("current_location_id")) == "cafe", "138 fallback arrived cafe")
	var dup_packed: PackedScene = load("res://world/test/fixtures/duplicate_spawn_location.tscn") as PackedScene
	var dup: WorldLocation = dup_packed.instantiate() as WorldLocation
	var dup_errors: Array[String] = dup.validate_markers()
	_ok(not dup_errors.is_empty(), "142 duplicate marker validation")
	dup.free()


func _test_markers_and_npc() -> void:
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "143 city load")
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	_ok(loc != null and loc.get_player_spawn(&"spawn_default") != null, "141 spawn_default")
	_ok(loc.get_player_spawn(&"missing_spawn") == null, "141 missing spawn null")
	_ok(loc.get_npc_spawn(&"npc_city_01") != null, "141 npc marker")
	_ok(loc.get_story_event_point(&"story_point_city_01") != null, "145 story point")
	var girls: int = 0
	var rivals: int = 0
	for n in loc.find_children("*", "GirlActor", true, false):
		girls += 1
	for n2 in loc.find_children("*", "RivalActor", true, false):
		rivals += 1
	_ok(girls == 0 and rivals == 0, "143 no auto NPC spawn")
	var actor_scene: PackedScene = load("res://characters/framework/character_actor.tscn") as PackedScene
	if actor_scene != null:
		var actor: Node3D = actor_scene.instantiate() as Node3D
		var marker: NpcSpawnPoint = loc.get_npc_spawn(&"npc_city_01")
		loc.add_child(actor)
		if marker != null:
			actor.global_transform = marker.global_transform
			_ok(actor.global_transform.origin.is_equal_approx(marker.global_transform.origin), "144 character place")
		actor.queue_free()
	else:
		_ok(false, "144 character_actor scene")


func _test_phone() -> void:
	await _restore(GameTypes.GameStage.PROLOGUE)
	_ok(int(_world.call("reset_to_start")) == int(WorldTypes.WorldTravelResult.SUCCESS), "146 apt")
	var loc: WorldLocation = _world.call("get_current_location") as WorldLocation
	var phone_node: PhoneInteractable = null
	if loc != null:
		for n in loc.find_children("*", "PhoneInteractable", true, false):
			phone_node = n as PhoneInteractable
			break
	_ok(phone_node != null, "146 phone interactable")
	var player: PlayerController = _world.call("get_player") as PlayerController
	if phone_node != null and player != null:
		phone_node.interact(player)
		await get_tree().process_frame
		var journal: PhoneJournal = _world.call("get_phone_journal") as PhoneJournal
		_ok(journal != null and journal.is_open(), "146 phone open")
		_ok(player.get_control_mode() == PlayerController.ControlMode.MODAL_UI, "146 MODAL_UI")
		# Transition while phone open should not be usable via player interact query.
		_ok(player.get_control_mode() != PlayerController.ControlMode.GAMEPLAY, "147 no gameplay interact")
		if journal != null:
			journal.close()
			await get_tree().process_frame
			_ok(player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY, "146 close GAMEPLAY")


func _test_downgrade_and_reset() -> void:
	await _restore(GameTypes.GameStage.STAGE_5)
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "151 setup city")
	_ok(_travel(&"laboratory") == int(WorldTypes.WorldTravelResult.SUCCESS), "151 enter lab")
	await _restore(GameTypes.GameStage.STAGE_1)
	_ok(String(_world.get("current_location_id")) == "laboratory", "151 stay in lab")
	_ok(_travel(&"city_hub") == int(WorldTypes.WorldTravelResult.SUCCESS), "151 leave to city")
	_ok(_travel(&"laboratory") == int(WorldTypes.WorldTravelResult.LOCKED), "151 re-enter blocked")
	_ok(int(_world.call("reset_to_start")) == int(WorldTypes.WorldTravelResult.SUCCESS), "152 reset")
	_ok(String(_world.get("current_location_id")) == "apartment", "152 apartment")


func _test_no_mutations() -> void:
	await _restore(GameTypes.GameStage.FINALE)
	var stage_before: int = _stage()
	var money_before: int = int(_gs.call("get_money"))
	var flag_before: bool = bool(_gs.call("get_story_flag", &"module12_probe"))
	for lid in [&"city_hub", &"salary_mine", &"laboratory", &"production_area", &"final_location", &"apartment"]:
		_ok(_travel(lid) == int(WorldTypes.WorldTravelResult.SUCCESS), "153/154 travel %s" % String(lid))
	_ok(_stage() == stage_before, "153 no stage mutation")
	_ok(int(_gs.call("get_money")) == money_before, "154 no money mutation")
	_ok(bool(_gs.call("get_story_flag", &"module12_probe")) == flag_before, "155 no story flag")
