extends Node
## MODULE 27 Wave C — scripted full-game integration harness (§§118–122).
## Route A clean mainline + Route B imperfect + save continuation.
## Run: res://game/qa/test/full_game_integration_test.tscn


const _HelpersScript = preload("res://game/qa/test/full_game_integration_helpers.gd")

var _failed: int = 0
var _passed: int = 0
var _h = null
var _controller: FinalDateController = null
var _final_location: Node3D = null
var _runner: Node = null


func _ready() -> void:
	_h = _HelpersScript.new()
	_h.bind_autoloads(get_tree())
	_h.set_ok_callback(Callable(self, "_ok"))
	_h.attach_fake_runner()
	_h.connect_stage_tracker()
	_runner = get_node_or_null("/root/RivalCompetitionRunner")
	await get_tree().process_frame
	await _run_all()
	_h.restore_runner()
	if _failed == 0:
		DfLog.info("MODULE_27_FULL_GAME", "ALL PASS (%s)" % _passed)
		print("MODULE_27_FULL_GAME: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_27_FULL_GAME", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_27_FULL_GAME: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_27_FULL_GAME] FAIL: %s" % label)
		print("MODULE_27_FULL_GAME FAIL: %s" % label)


func _run_all() -> void:
	await _test_route_a_clean_mainline()
	_dispose_final_harness()
	await get_tree().process_frame
	_test_route_b_imperfect()
	_dispose_final_harness()
	await get_tree().process_frame
	await _test_save_continuation()
	_dispose_final_harness()
	_h.reset_clean()


func _progress_early_story_to_stage4() -> void:
	# PROLOGUE → neighbor → STAGE_1
	_h.assert_stage(int(GameTypes.GameStage.PROLOGUE), "A start PROLOGUE")
	_h.conquer_girl(StoryIds.GIRL_NEIGHBOR, "neighbor")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_1), "A neighbor → STAGE_1")
	# STAGE_1: rival then actress → STAGE_2
	_h.win_rival(StoryIds.RIVAL_ACTRESS, "actress_rival")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_1), "A actress rival alone keeps STAGE_1")
	_h.conquer_girl(StoryIds.GIRL_ACTRESS, "actress")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_2), "A actress → STAGE_2")
	_ok(int(_h.gs.call("get_authority")) == 2, "A auth after actress rival = 2")
	# STAGE_2: mine
	_h.win_rival(StoryIds.RIVAL_MINE_BOSS, "mine_rival")
	_h.conquer_girl(StoryIds.GIRL_MINE_BOSS, "mine_boss")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_3), "A mine → STAGE_3")
	_ok(int(_h.gs.call("get_authority")) == 4, "A auth after mine rival = 4")
	# STAGE_3: editor
	_h.win_rival(StoryIds.RIVAL_MAGAZINE_EDITOR, "editor_rival")
	_ok(int(_h.gs.call("get_authority")) == 7, "A auth after editor rival = 7")
	_h.conquer_girl(StoryIds.GIRL_MAGAZINE_EDITOR, "editor")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_4), "A editor → STAGE_4")
	_ok(bool(_h.story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "A MEDIA unlocked")


func _progress_media_overload_scientist() -> void:
	_h.drive_media_to_overload()
	_h.drive_overload_recognition()
	# Scientist rival + girl → STAGE_5
	_h.win_rival(StoryIds.RIVAL_SCIENTIST, "scientist_rival")
	_ok(int(_h.gs.call("get_authority")) == 10, "A auth after scientist rival = 10")
	_h.conquer_girl(StoryIds.GIRL_SCIENTIST, "scientist")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_5), "A scientist → STAGE_5")
	_ok(bool(_h.story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "A LAB unlocked")


func _progress_clone_president_stage6() -> void:
	_h.commit_first_clone_work()
	_h.run_president_xp_bridge(10, 420.0)
	_h.win_rival(StoryIds.RIVAL_PRESIDENT, "president_rival")
	_ok(int(_h.gs.call("get_authority")) == 15, "A auth after president rival = 15")
	_h.conquer_girl(StoryIds.GIRL_PRESIDENT, "president")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_6), "A president → STAGE_6")
	_ok(bool(_h.story.call("is_feature_unlocked", StoryTypes.StoryFeature.WORLD_EXPANSION)), "A WORLD unlocked")
	_h.run_stage6_reach(520.0)
	_h.assert_stage(int(GameTypes.GameStage.FINALE), "A Reach100 → FINALE")


func _dispose_final_harness() -> void:
	if _controller != null and is_instance_valid(_controller):
		if _controller.is_attempt_active():
			_controller.abort_attempt_to_gameplay()
		_controller.set_test_auto_win_exhibition(false)
	if _final_location != null and is_instance_valid(_final_location):
		_final_location.queue_free()
	_final_location = null
	_controller = null
	if _h != null and _h.re != null:
		_h.re.call("force_clear_session")
	# Re-attach fake rival seam after FinalDate may have touched the runner.
	if _h != null and _h.fake_runner != null:
		_h.fake_runner.attach(_h.re)
		_h.fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)


func _ensure_final_harness() -> void:
	if _controller != null and is_instance_valid(_controller):
		return
	_final_location = Node3D.new()
	_final_location.name = "final_location"
	add_child(_final_location)
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
		var m: Marker3D = Marker3D.new()
		m.name = mn
		m.position = Vector3(float(i), 0.0, 0.0)
		_final_location.add_child(m)
		i += 1
	var gate_b: StaticBody3D = StaticBody3D.new()
	gate_b.name = "final_gate_zone_b"
	gate_b.collision_layer = 1
	_final_location.add_child(gate_b)
	var gate_c: StaticBody3D = StaticBody3D.new()
	gate_c.name = "final_gate_zone_c"
	gate_c.collision_layer = 1
	_final_location.add_child(gate_c)
	_controller = FinalDateController.new()
	_controller.name = "FinalDateController"
	_final_location.add_child(_controller)


func _choose_final(option_id: StringName) -> void:
	_ok(_controller.select_event_option(option_id), "final choose %s" % String(option_id))
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null and ui.get_mode() == "plain":
		ui.press_continue()


func _do_final_rival_checkpoint(checkpoint_id: StringName) -> void:
	_controller.notify_checkpoint(checkpoint_id)
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null and ui.is_open():
		ui.press_continue()
	var waited: int = 0
	while _runner != null and bool(_runner.call("is_busy")) and waited < 180:
		await get_tree().process_frame
		waited += 1
	_ok(_runner == null or not bool(_runner.call("is_busy")), "final rival done %s" % String(checkpoint_id))


func _run_final_date_success() -> void:
	_ensure_final_harness()
	_ok(int(_h.gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "finale stage before final date")
	_ok(int(_h.gs.call("get_world_reach")) >= 100, "reach100 before final date")
	# Boost characteristics for scoring options.
	_h.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_h.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_h.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	_h.gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)
	_controller.set_test_auto_win_exhibition(true)
	_ok(_controller.can_start_final_date(), "can_start_final_date")
	_ok(_controller.start_final_date(null), "start_final_date")
	_ok(_controller.get_phase() == FinalDateTypes.Phase.INTRO, "final INTRO")
	var intro_ui: FinalDateUI = _controller.get_ui()
	if intro_ui != null and intro_ui.is_open():
		intro_ui.press_continue()
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_1)
	_choose_final(&"aura")
	await _do_final_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_1)
	_ok(_controller.did_rival_1_win(), "final rival1 win")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_2)
	_choose_final(&"muscle")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_MOVE_TABLE)
	await _do_final_rival_checkpoint(FinalDateTypes.CHECKPOINT_RIVAL_2)
	_ok(_controller.did_rival_2_win(), "final rival2 win")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_3)
	_choose_final(&"appearance")
	_controller.notify_checkpoint(FinalDateTypes.CHECKPOINT_EVENT_4)
	_choose_final(&"capital")
	_ok(bool(_h.gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)), "final target conquered")
	_ok(_controller.get_phase() == FinalDateTypes.Phase.SUCCESS, "final SUCCESS phase")
	var ui: FinalDateUI = _controller.get_ui()
	if ui != null:
		if ui.get_mode() == "success_dialogue":
			ui.press_continue()
		if ui.get_mode() == "ending":
			_ok(ui.press_continue(), "ending continue")
	_ok(not _controller.is_attempt_active(), "ending closed attempt")
	_controller.set_test_auto_win_exhibition(false)


func _test_route_a_clean_mainline() -> void:
	print("MODULE_27_FULL_GAME: Route A start")
	_h.reset_clean()
	_progress_early_story_to_stage4()
	_progress_media_overload_scientist()
	_progress_clone_president_stage6()
	await _run_final_date_success()
	_h.assert_stage_monotonic()
	var expected_auth: Array[int] = [0, 2, 4, 7, 10, 15]
	# auth_history starts with 0 at reset, then appends after each rival outcome.
	_ok(_h.auth_history.size() >= 6, "A auth samples >=6")
	if _h.auth_history.size() >= 6:
		var sample: Array[int] = []
		sample.append(_h.auth_history[0])
		# Collect post-win values from Route A rival wins only (ignore Route B later).
		var wins_seen: int = 0
		for i in range(1, _h.auth_history.size()):
			if wins_seen >= 5:
				break
			# Route A only wins; values should be nondecreasing by reward steps.
			sample.append(_h.auth_history[i])
			wins_seen += 1
		_ok(sample == expected_auth, "A auth ladder exact %s" % str(sample))
	_ok(int(_h.gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "A ending reachable FINALE")
	_ok(bool(_h.gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)), "A ending target conquered")
	print("MODULE_27_FULL_GAME: Route A done passed=%s failed=%s" % [_passed, _failed])


func _test_route_b_imperfect() -> void:
	print("MODULE_27_FULL_GAME: Route B start")
	_h.reset_clean()
	_h.conquer_girl(StoryIds.GIRL_NEIGHBOR, "B neighbor")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_1), "B STAGE_1")
	var auth0: int = int(_h.gs.call("get_authority"))
	# Story rival LOSS — Authority unchanged for story.
	_h.lose_rival(StoryIds.RIVAL_ACTRESS, "B actress loss")
	_ok(int(_h.gs.call("get_authority")) == auth0, "B story loss Auth unchanged")
	_ok(not bool(_h.gs.call("is_rival_defeated", StoryIds.RIVAL_ACTRESS)), "B not defeated after loss")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_1), "B still STAGE_1 after loss")
	# Retry WIN
	_h.win_rival(StoryIds.RIVAL_ACTRESS, "B actress retry win")
	_ok(bool(_h.gs.call("is_rival_defeated", StoryIds.RIVAL_ACTRESS)), "B defeated after retry")
	_ok(int(_h.gs.call("get_authority")) == auth0 + 2, "B Auth +2 after retry win")
	# Discovery FAILURE → day advance → SUCCESS
	_h.discover_failure(StoryIds.GIRL_ACTRESS)
	var retry_days: int = int(_h.gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_ACTRESS))
	_ok(retry_days > 0, "B discovery cooldown >0")
	for _i in range(retry_days):
		_h.day.call("advance_day")
	_ok(int(_h.gs.call("get_girl_retry_days_remaining", StoryIds.GIRL_ACTRESS)) == 0, "B cooldown cleared")
	_h.discover_success(StoryIds.GIRL_ACTRESS)
	# Partial date → cooldown → recovery +5
	var partial: RelationshipDateResult = _h.apply_partial_date(StoryIds.GIRL_ACTRESS, 2)
	_ok(partial != null and partial.ok, "B partial date ok")
	_ok(int(_h.gs.call("get_girl_relationship", StoryIds.GIRL_ACTRESS)) == 2, "B rel=2 after partial")
	var cd: int = int(_h.gs.call("get_girl_date_cooldown_days_remaining", StoryIds.GIRL_ACTRESS))
	_ok(cd > 0, "B date cooldown >0")
	for _j in range(cd):
		_h.day.call("advance_day")
	_ok(_h.conquer_girl(StoryIds.GIRL_ACTRESS, "B actress recovery +5"), "B recovery conquer")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_2), "B recovery → STAGE_2")
	print("MODULE_27_FULL_GAME: Route B done")


func _test_save_continuation() -> void:
	print("MODULE_27_FULL_GAME: Save continuation start")
	await get_tree().process_frame
	_h.reset_clean()
	# Build through Media→Overload via production APIs.
	_progress_early_story_to_stage4()
	_h.drive_media_to_overload()
	var stage_mid: int = _h.stage()
	var att_mid: int = int(_h.media.call("get_attention"))
	var offers_mid: int = int(_h.media.call("get_incoming_offer_count"))
	var overload_mid: bool = bool(_h.overload.call("is_started"))
	var xp_mid: int = int(_h.gs.call("get_experience"))
	_ok(overload_mid, "save checkpoint overload started")
	_ok(SaveTypes.SAVE_SCHEMA_VERSION == 1, "schema v1")
	_ok(_h.ensure_saveable_world(), "saveable world before MANUAL_1")
	var save_r: SaveResult = _h.ss.call("save_slot", SaveTypes.Slot.MANUAL_1) as SaveResult
	_ok(save_r != null and save_r.ok, "save_slot MANUAL_1")
	var meta: SaveSlotMetadata = _h.ss.call("get_slot_metadata", SaveTypes.Slot.MANUAL_1) as SaveSlotMetadata
	_ok(meta != null and meta.exists and meta.valid, "save metadata valid")
	_ok(meta.schema_version == 1, "save metadata schema 1")
	# Mutate live state away from saved snapshot.
	_h.gs.call("set_media_attention", 0)
	_h.day.call("advance_day")
	_h.day.call("advance_day")
	var load_r: SaveResult = _h.ss.call("load_slot", SaveTypes.Slot.MANUAL_1) as SaveResult
	_ok(load_r != null and load_r.ok, "load_slot MANUAL_1")
	if _h.fake_runner != null:
		_h.fake_runner.attach(_h.re)
		_h.fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)
	_h.ensure_saveable_world()
	_ok(_h.stage() == stage_mid, "stage restored")
	_ok(int(_h.media.call("get_attention")) == att_mid, "attention restored")
	_ok(int(_h.media.call("get_incoming_offer_count")) == offers_mid, "offers restored")
	_ok(bool(_h.overload.call("is_started")) == overload_mid, "overload started restored")
	_ok(int(_h.gs.call("get_experience")) == xp_mid, "xp restored")
	# Continue story after load: recognition → scientist → STAGE_5 (Clone checkpoint path).
	_h.drive_overload_recognition()
	_h.win_rival(StoryIds.RIVAL_SCIENTIST, "save scientist rival")
	_h.conquer_girl(StoryIds.GIRL_SCIENTIST, "save scientist")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_5), "save continue → STAGE_5")
	# Second save around Clone→Stage6 boundary.
	_h.commit_first_clone_work()
	var clones_mid: int = int(_h.gs.call("get_total_clones"))
	_ok(_h.ensure_saveable_world(), "saveable world before MANUAL_2")
	var save2: SaveResult = _h.ss.call("save_slot", SaveTypes.Slot.MANUAL_2) as SaveResult
	_ok(save2 != null and save2.ok, "save_slot MANUAL_2 clone")
	_h.gs.call("set_clone_counts", 0, 0, 0)
	var load2: SaveResult = _h.ss.call("load_slot", SaveTypes.Slot.MANUAL_2) as SaveResult
	_ok(load2 != null and load2.ok, "load_slot MANUAL_2")
	if _h.fake_runner != null:
		_h.fake_runner.attach(_h.re)
		_h.fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)
	_ok(int(_h.gs.call("get_total_clones")) == clones_mid, "clones restored")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_5), "stage5 after clone load")
	_h.run_president_xp_bridge(10, 420.0)
	_h.win_rival(StoryIds.RIVAL_PRESIDENT, "save president rival")
	_h.conquer_girl(StoryIds.GIRL_PRESIDENT, "save president")
	_h.assert_stage(int(GameTypes.GameStage.STAGE_6), "save continue → STAGE_6")
	print("MODULE_27_FULL_GAME: Save continuation done")
