extends Node
## MODULE 21 FinalDateController self-test.
## Run: res://game/final_date/test/final_date_test.tscn --quit-after 90000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _story: Node = null
var _dating: Node = null
var _runner: Node = null
var _controller: FinalDateController = null
var _phone: PhoneJournal = null
var _location: Node3D = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_story = get_node("/root/Story")
	_dating = get_node("/root/DatingCore")
	_runner = get_node("/root/RivalCompetitionRunner")
	await get_tree().process_frame
	_build_harness()
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_21_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_21_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_21_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_21_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_21_TEST] FAIL: %s" % label)
		print("MODULE_21_TEST FAIL: %s" % label)


func _build_harness() -> void:
	_location = Node3D.new()
	_location.name = "final_location"
	add_child(_location)
	var marker_names: Array[String] = [
		"final_attempt_start",
		"final_target_signal_marker",
		"final_target_orbit_marker",
		"final_target_table_marker",
		"final_rival_ceremonial_marker",
		"final_rival_gravity_marker",
		"final_checkpoint_event_1",
		"final_checkpoint_rival_1",
		"final_checkpoint_event_2",
		"final_checkpoint_rival_2",
		"final_checkpoint_event_3",
		"final_checkpoint_event_4",
		"final_walk_checkpoint_a",
		"final_walk_checkpoint_b",
		"final_walk_checkpoint_c",
	]
	var i: int = 0
	for mn in marker_names:
		var m := Marker3D.new()
		m.name = mn
		m.position = Vector3(float(i), 0.0, 0.0)
		_location.add_child(m)
		i += 1
	var gate_b := StaticBody3D.new()
	gate_b.name = "final_gate_zone_b"
	gate_b.collision_layer = 1
	_location.add_child(gate_b)
	var gate_c := StaticBody3D.new()
	gate_c.name = "final_gate_zone_c"
	gate_c.collision_layer = 1
	_location.add_child(gate_c)
	_controller = FinalDateController.new()
	_controller.name = "FinalDateController"
	_location.add_child(_controller)
	var packed_phone: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	_phone = packed_phone.instantiate() as PhoneJournal if packed_phone != null else null
	add_child(_phone)


func _reset_finale_ready() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("restore_stage", GameTypes.GameStage.FINALE)
	_gs.call("set_world_reach", 100)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)
	if _controller.is_attempt_active():
		_controller.abort_attempt_to_gameplay()


func _run_all() -> void:
	_test_locked_before_finale()
	await _test_success_path()
	await _test_fail_no_mutation_and_retry()
	_test_already_conquered_locks()
	_test_no_dating_core()
	_test_phone_states()
	_test_scoring_rules()


func _test_locked_before_finale() -> void:
	_gs.call("reset_for_new_game")
	# Keep Reach below 100 so LateGameExpansion does not auto-enter FINALE.
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	_gs.call("set_world_reach", 50)
	_ok(int(_gs.call("get_stage")) != int(GameTypes.GameStage.FINALE), "88 still STAGE_6")
	_ok(not _controller.can_start_final_date(), "88 locked before FINALE")
	_ok(not bool(_gs.call("is_girl_discovered", FinalDateTypes.GIRL_ID)), "88 no discover")
	_ok(not bool(_gs.call("has_girl_contact", FinalDateTypes.GIRL_ID)), "88 no contact")


func _advance_intro_to_event1() -> void:
	_ok(_controller.get_phase() == FinalDateTypes.Phase.INTRO, "89 phase INTRO")
	_ok(_controller.get_ui() != null and _controller.get_ui().is_open(), "89 intro ui")
	_controller.get_ui().press_continue()
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)


func _choose(option_id: StringName) -> void:
	_ok(_controller.select_event_option(option_id), "select %s" % String(option_id))
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null and ui.get_mode() == "plain":
		ui.press_continue()


func _do_rival_checkpoint(checkpoint_id: StringName) -> void:
	_controller.notify_checkpoint(checkpoint_id)
	var ui: FinalDateUI = _controller.get_ui()
	_ok(ui != null and ui.is_open(), "rival staging ui %s" % String(checkpoint_id))
	ui.press_continue()
	var waited: int = 0
	while bool(_runner.call("is_busy")) and waited < 120:
		await get_tree().process_frame
		waited += 1
	_ok(not bool(_runner.call("is_busy")), "rival finished %s" % String(checkpoint_id))


func _test_success_path() -> void:
	_reset_finale_ready()
	_controller.set_test_auto_win_exhibition(true)
	var xp0: int = int(_gs.call("get_experience"))
	var up0: int = int(_gs.call("get_upgrade_points"))
	_ok(_controller.can_start_final_date(), "89 can start")
	_ok(_controller.start_final_date(null), "89 start")
	_ok(_controller.is_attempt_active(), "89 attempt active")
	_ok(_controller.get_connection_score() == 0, "89 score0")
	_ok(not _controller.did_rival_1_win() and not _controller.did_rival_2_win(), "89 rivals false")
	_ok(_controller.get_target_actor() != null, "89 target spawned")
	_ok(not bool(_dating.call("is_date_active")), "no DatingCore session")
	_advance_intro_to_event1()
	_ok(_controller.get_phase() == FinalDateTypes.Phase.EVENT_1, "event1 phase")
	_choose(&"aura")
	await _do_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1)
	_ok(_controller.did_rival_1_win(), "97 rival1 won")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_2)
	_choose(&"muscle")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_MOVE_TABLE)
	await _do_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_2)
	_ok(_controller.did_rival_2_win(), "98 rival2 won")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_3)
	_choose(&"appearance")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_4)
	_choose(&"capital")
	var assessment: Dictionary = _controller.assess_final_score()
	# score already finalized inside controller; variety should apply
	_ok(int(_gs.call("get_girl_relationship", FinalDateTypes.GIRL_ID)) == 5, "58 relationship 5")
	_ok(bool(_gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)), "60 conquered")
	_ok(int(_gs.call("get_experience")) == xp0 + 1, "58 xp +1")
	_ok(int(_gs.call("get_upgrade_points")) == up0 + 1, "58 up +1")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "82 stage stays FINALE")
	_ok(_controller.get_phase() == FinalDateTypes.Phase.SUCCESS, "success phase")
	var ui: FinalDateUI = _controller.get_ui()
	_ok(ui != null and ui.get_mode() == "success_dialogue", "61 success dialogue")
	ui.press_continue()
	_ok(ui.get_mode() == "ending", "62 ending screen")
	_ok(String(ui.get_mode()) == "ending", "ending mode")
	var ending_ok: bool = ui.press_continue()
	_ok(ending_ok, "64 continue")
	_ok(not _controller.is_attempt_active(), "post-ending not active")
	_ok(not _controller.can_start_final_date(), "22 no second reward start")
	# second success attempt must not grant again
	var xp1: int = int(_gs.call("get_experience"))
	_ok(xp1 == xp0 + 1, "exactly once xp")
	_controller.set_test_auto_win_exhibition(false)


func _test_fail_no_mutation_and_retry() -> void:
	_reset_finale_ready()
	_controller.set_test_auto_win_exhibition(false)
	var money0: int = int(_gs.call("get_money"))
	var auth0: int = int(_gs.call("get_authority"))
	var xp0: int = int(_gs.call("get_experience"))
	var up0: int = int(_gs.call("get_upgrade_points"))
	var reach0: int = int(_gs.call("get_world_reach"))
	_controller.start_final_date(null)
	_advance_intro_to_event1()
	_choose(&"neutral")
	# Force rival1 loss via manual exhibition callback path: launch then emit loss.
	_controller.set_test_auto_win_exhibition(false)
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1)
	_controller.get_ui().press_continue()
	var waited: int = 0
	while (not bool(_runner.call("is_busy"))) and waited < 30:
		await get_tree().process_frame
		waited += 1
	if bool(_runner.call("is_busy")):
		var mg: CanvasLayer = _runner.call("get_active_minigame") as CanvasLayer
		var result := RivalCompetitionResult.new()
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		result.debug_score_summary = "final_date_force_loss"
		mg.emit_signal("match_finished", result)
		var w2: int = 0
		while bool(_runner.call("is_busy")) and w2 < 60:
			await get_tree().process_frame
			w2 += 1
	_ok(_controller.get_phase() == FinalDateTypes.Phase.FAILURE, "96 failure phase")
	_ok(_controller.get_failure_reason() == FinalDateTypes.FailureReason.RIVAL_LOSS, "96 rival loss")
	_ok(int(_gs.call("get_money")) == money0, "101 money")
	_ok(int(_gs.call("get_authority")) == auth0, "101 authority")
	_ok(int(_gs.call("get_experience")) == xp0, "101 xp")
	_ok(int(_gs.call("get_upgrade_points")) == up0, "101 up")
	_ok(int(_gs.call("get_girl_relationship", FinalDateTypes.GIRL_ID)) == 0, "101 rel")
	_ok(not bool(_gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)), "101 not conquered")
	_ok(not bool(_gs.call("is_rival_defeated", FinalDateTypes.RIVAL_CEREMONIAL_ID)), "101 no defeat")
	_ok(int(_gs.call("get_world_reach")) == reach0, "101 reach")
	# Retry full attempt
	_controller.set_test_auto_win_exhibition(true)
	_controller.get_ui().press_retry()
	_ok(_controller.is_attempt_active(), "53 retry active")
	_ok(_controller.get_phase() == FinalDateTypes.Phase.INTRO, "53 retry INTRO")
	_ok(_controller.get_connection_score() == 0, "53 score reset")
	_ok(not _controller.did_rival_1_win(), "53 rival reset")
	_controller.abort_attempt_to_gameplay()
	_ok(not _controller.is_attempt_active(), "54 abort")
	_ok(_controller.can_start_final_date(), "54 can start again")
	_controller.set_test_auto_win_exhibition(false)


func _test_already_conquered_locks() -> void:
	_reset_finale_ready()
	_gs.call("mark_girl_discovered", FinalDateTypes.GIRL_ID)
	_gs.call("add_girl_contact", FinalDateTypes.GIRL_ID)
	_gs.call("set_girl_relationship", FinalDateTypes.GIRL_ID, 5)
	_gs.call("mark_girl_conquered", FinalDateTypes.GIRL_ID)
	_ok(not _controller.can_start_final_date(), "22 conquered locks start")


func _test_no_dating_core() -> void:
	_reset_finale_ready()
	_controller.set_test_auto_win_exhibition(true)
	_controller.start_final_date(null)
	_ok(not bool(_dating.call("is_date_active")), "112 no DatingCore")
	var src: String = FileAccess.get_file_as_string("res://game/final_date/final_date_controller.gd")
	_ok(not src.contains("start_date("), "112 no DatingCore start_date")
	_ok(not src.contains("mark_rival_defeated"), "81 no mark_rival_defeated")
	_controller.abort_attempt_to_gameplay()
	_controller.set_test_auto_win_exhibition(false)


func _test_phone_states() -> void:
	_reset_finale_ready()
	_phone.refresh()
	var before: String = _phone.get_story_text()
	_ok(before.contains("ФИНАЛ"), "113 phone before FINALE title")
	_ok(before.contains("Внеземной сигнал обнаружен."), "113 phone before signal")
	_controller.start_final_date(null)
	_phone.refresh()
	var mid: String = _phone.get_story_text()
	_ok(mid.contains("Последняя"), "113 phone in progress name")
	_ok(mid.contains("Финальное свидание"), "113 phone in progress")
	_controller.abort_attempt_to_gameplay()
	_gs.call("set_girl_relationship", FinalDateTypes.GIRL_ID, 5)
	_gs.call("mark_girl_conquered", FinalDateTypes.GIRL_ID)
	_phone.refresh()
	var done: String = _phone.get_story_text()
	_ok(done.contains("ФИНАЛ ЗАВЕРШЁН"), "113 phone completed")
	_ok(done.contains("Последняя: +5"), "113 phone +5")


func _test_scoring_rules() -> void:
	_reset_finale_ready()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 1)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 1)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 1)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)
	_controller.start_final_date(null)
	_controller.get_ui().press_continue()
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
	var choices: Array[Dictionary] = _controller.build_event_choices(1)
	var muscle_enabled: bool = false
	var aura_enabled: bool = false
	var neutral_enabled: bool = false
	for c in choices:
		var oid: String = String(c.get("id", ""))
		if oid == "muscle":
			muscle_enabled = bool(c.get("enabled", false))
		elif oid == "aura":
			aura_enabled = bool(c.get("enabled", false))
		elif oid == "neutral":
			neutral_enabled = bool(c.get("enabled", false))
	_ok(not muscle_enabled, "91 muscle disabled at 1")
	_ok(aura_enabled, "91 aura enabled at 2")
	_ok(neutral_enabled, "91 neutral enabled")
	_controller.abort_attempt_to_gameplay()
	# specialized aura x4 => score 4, no variety
	_controller.connection_score = 4
	_controller.used_characteristics = {int(FinalDateTypes.EventOptionKind.AURA): true}
	_controller.rival_1_won = true
	_controller.rival_2_won = true
	var a: Dictionary = _controller.assess_final_score()
	_ok(int(a.get("score", 0)) == 4, "92 specialized score4")
	_ok(not bool(a.get("variety", true)), "92 no variety")
	_ok(bool(a.get("passed", false)), "92 pass")
	# diverse => +1 variety
	_controller.connection_score = 4
	_controller.used_characteristics = {
		int(FinalDateTypes.EventOptionKind.MUSCLE): true,
		int(FinalDateTypes.EventOptionKind.APPEARANCE): true,
		int(FinalDateTypes.EventOptionKind.CAPITAL): true,
		int(FinalDateTypes.EventOptionKind.AURA): true,
	}
	var b: Dictionary = _controller.assess_final_score()
	_ok(int(b.get("score", 0)) == 5, "93 diverse score5")
	_ok(bool(b.get("variety", false)), "93 variety")
	# neutrals fail
	_controller.connection_score = 0
	_controller.used_characteristics.clear()
	var cdict: Dictionary = _controller.assess_final_score()
	_ok(int(cdict.get("score", -1)) == 0, "94 neutral0")
	_ok(not bool(cdict.get("passed", true)), "94 fail")
	# threshold 2 fail / 3 pass
	_controller.connection_score = 2
	_controller.used_characteristics = {
		int(FinalDateTypes.EventOptionKind.MUSCLE): true,
		int(FinalDateTypes.EventOptionKind.AURA): true,
	}
	var d: Dictionary = _controller.assess_final_score()
	_ok(int(d.get("score", 0)) == 2 and not bool(d.get("passed", true)), "95 score2 fail")
	_controller.connection_score = 3
	var e: Dictionary = _controller.assess_final_score()
	_ok(int(e.get("score", 0)) == 3 and bool(e.get("passed", false)), "95 score3 pass")
