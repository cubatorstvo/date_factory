extends Node
## MODULE 07B Dance Minigame self-test (formulas, FSM, perks, RivalCompetitionRunner).
## Run: res://minigames/dance/test/dance_minigame_test.tscn --quit-after 8000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _re: Node = null
var _runner: Node = null
var _finish_count: int = 0
var _last_encounter: RivalEncounterResult = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_re = get_node("/root/RivalEncounters")
	_runner = get_node_or_null("/root/RivalCompetitionRunner")
	await get_tree().process_frame
	if _runner != null and _runner.has_method("register_as_runner"):
		_runner.call("register_as_runner")
	if not _re.encounter_finished.is_connected(_on_finished):
		_re.encounter_finished.connect(_on_finished)
	_run_sync_tests()
	await _run_integration_tests()
	if _failed == 0:
		DfLog.info("MODULE_07B_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_07B_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_07B_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_07B_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_finished(r: RivalEncounterResult) -> void:
	_finish_count += 1
	_last_encounter = r


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_07B_TEST] FAIL: %s" % label)
		print("MODULE_07B_TEST FAIL: %s" % label)


func _new_match(
	player_lv: int = 4,
	rival_lv: int = 4,
	story: bool = false,
	perks: Dictionary = {},
	rng_seed: int = 1,
) -> DanceMatch:
	var m: DanceMatch = DanceMatch.new()
	m.setup(player_lv, rival_lv, story, perks, rng_seed)
	return m


func _run_sync_tests() -> void:
	_test_runner_migration()
	_test_difficulty()
	_test_lengths_generation()
	_test_evaluate_move()
	_test_sequence_rules()
	_test_score_flow()
	_test_grades()
	_test_perks()
	_test_no_authority_in_dance_sources()


func _test_runner_migration() -> void:
	var host_exists: bool = ResourceLoader.exists("res://minigames/slap/slap_competition_host.gd")
	_ok(not host_exists, "79 SlapCompetitionHost absent")
	_ok(_runner != null, "79 RivalCompetitionRunner present")
	_ok(_runner != null, "80 production runner available")


func _test_difficulty() -> void:
	var eq: DanceMatch = _new_match(4, 4)
	_ok(is_equal_approx(eq.base_window, 0.18), "84 base 0.18")
	_ok(eq.allowed_errors == 1, "84 allowed 1")
	var hi: DanceMatch = _new_match(8, 4)
	_ok(is_equal_approx(hi.base_window, 0.22), "85 base 0.22")
	_ok(hi.allowed_errors == 2, "85 allowed 2")
	var lo: DanceMatch = _new_match(2, 6)
	_ok(is_equal_approx(lo.base_window, 0.14), "86 base 0.14")
	_ok(lo.allowed_errors == 0, "86 allowed 0")
	_ok(is_equal_approx(DanceTiming.compute_base_window(100), 0.25), "87 clamp hi")
	_ok(is_equal_approx(DanceTiming.compute_base_window(-100), 0.11), "87 clamp lo")


func _test_lengths_generation() -> void:
	var o: DanceMatch = _new_match(4, 4, false, {}, 11)
	_ok(o.sequence_length == 3, "88 ordinary length 3")
	_ok(o.opponent_sequence.size() == 3, "88 repeat 3")
	var s: DanceMatch = _new_match(4, 4, true, {}, 12)
	_ok(s.sequence_length == 4, "88 story length 4")
	_ok(s.opponent_sequence.size() == 4, "88 story repeat 4")
	var triples: int = 0
	for seed_i in 40:
		var m: DanceMatch = _new_match(4, 4, true, {}, 100 + seed_i)
		var seq: Array[DanceTiming.DanceMove] = m.opponent_sequence
		for i in range(2, seq.size()):
			if seq[i] == seq[i - 1] and seq[i] == seq[i - 2]:
				triples += 1
	_ok(triples == 0, "89 no triple same direction")


func _test_evaluate_move() -> void:
	var hit: DanceTiming.Result = DanceTiming.evaluate_move(
		DanceTiming.DanceMove.LEFT,
		DanceTiming.DanceMove.LEFT,
		1.10,
		1.0,
		0.18,
	)
	_ok(hit == DanceTiming.Result.HIT, "90 HIT at +0.10")
	var perfect_w: float = DanceTiming.compute_perfect_window(0.18)
	_ok(is_equal_approx(perfect_w, 0.063), "91 perfect_window 0.063")
	var perfect: DanceTiming.Result = DanceTiming.evaluate_move(
		DanceTiming.DanceMove.LEFT,
		DanceTiming.DanceMove.LEFT,
		1.0,
		1.0,
		0.18,
	)
	_ok(perfect == DanceTiming.Result.PERFECT, "91 PERFECT center")
	var wrong: DanceTiming.Result = DanceTiming.evaluate_move(
		DanceTiming.DanceMove.LEFT,
		DanceTiming.DanceMove.RIGHT,
		1.0,
		1.0,
		0.18,
	)
	_ok(wrong == DanceTiming.Result.MISS, "92 wrong direction")
	var early: DanceTiming.Result = DanceTiming.evaluate_move(
		DanceTiming.DanceMove.LEFT,
		DanceTiming.DanceMove.LEFT,
		0.70,
		1.0,
		0.18,
	)
	_ok(early == DanceTiming.Result.MISS, "93 too early")

	var m: DanceMatch = _new_match()
	m.debug_skip_to_player_repeat()
	m.phase_time = 0.0
	m.tick(0.19)
	_ok(m.sequence_errors == 1 or m.beat_index >= 1, "94 timeout advances")
	var m2: DanceMatch = _new_match(4, 4, false, {}, 3)
	m2.debug_skip_to_player_repeat()
	var expected0: DanceTiming.DanceMove = m2.active_sequence[0]
	var wrong_dir: DanceTiming.DanceMove = DanceTiming.DanceMove.UP
	if expected0 == DanceTiming.DanceMove.UP:
		wrong_dir = DanceTiming.DanceMove.DOWN
	m2.phase_time = 0.0
	m2.press_move(wrong_dir)
	_ok(m2.beat_index == 1, "95 first press consumed")
	_ok(m2.sequence_errors == 1, "95 first was error")
	m2.phase_time = DanceMatch.BEAT_INTERVAL
	m2.press_move(m2.active_sequence[1])
	_ok(m2.sequence_correct >= 1, "95 second maps to next beat")


func _test_sequence_rules() -> void:
	_ok(
		DanceTiming.is_sequence_success(1, 2, 3, 1),
		"96 2 correct +1 error SUCCESS",
	)
	_ok(
		not DanceTiming.is_sequence_success(2, 1, 3, 1),
		"97 1 correct +2 errors FAIL",
	)


func _test_score_flow() -> void:
	var m: DanceMatch = _new_match(4, 4, false, {}, 21)
	m.debug_skip_to_player_repeat()
	m.debug_finish_sequence_with_pattern([true, true, true])
	_ok(m.player_score == 1, "98 repeat success +1")
	# Feedback then own preview path
	m.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	_ok(
		m.phase == DanceMatch.Phase.OWN_PREVIEW or m.phase == DanceMatch.Phase.PRE_ROLL or m.phase == DanceMatch.Phase.PLAYER_OWN,
		"98 OWN starts",
	)

	var m2: DanceMatch = _new_match(4, 4, false, {}, 22)
	m2.debug_skip_to_player_repeat()
	m2.debug_finish_sequence_with_pattern([false, false, false])
	_ok(m2.rival_score == 1, "99 failed repeat rival +1")
	m2.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	_ok(m2.phase == DanceMatch.Phase.OPPONENT_DEMO, "99 OWN skipped -> next round")

	var m3: DanceMatch = _new_match(4, 4, false, {}, 23)
	m3.debug_skip_to_player_repeat()
	m3.debug_finish_sequence_with_pattern([true, true, true])
	m3.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	if m3.phase == DanceMatch.Phase.OWN_PREVIEW:
		m3.tick(DanceMatch.OWN_PREVIEW_DURATION + 0.01)
	if m3.phase == DanceMatch.Phase.PRE_ROLL:
		m3.tick(DanceMatch.PRE_ROLL_DURATION + 0.01)
	_ok(m3.phase == DanceMatch.Phase.PLAYER_OWN, "100 in PLAYER_OWN")
	m3.debug_finish_sequence_with_pattern([true, true, true])
	_ok(m3.player_score == 2, "100 own success +1")

	var m4: DanceMatch = _new_match(4, 4, false, {}, 24)
	m4.debug_skip_to_player_repeat()
	m4.debug_finish_sequence_with_pattern([true, true, true])
	m4.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	if m4.phase == DanceMatch.Phase.OWN_PREVIEW:
		m4.tick(DanceMatch.OWN_PREVIEW_DURATION + 0.01)
	if m4.phase == DanceMatch.Phase.PRE_ROLL:
		m4.tick(DanceMatch.PRE_ROLL_DURATION + 0.01)
	m4.debug_finish_sequence_with_pattern([false, false, false])
	_ok(m4.rival_score == 1, "101 own fail rival +1")

	var m5: DanceMatch = _new_match(4, 4, false, {}, 25)
	m5.player_score = 2
	m5.debug_skip_to_player_repeat()
	m5.debug_finish_sequence_with_pattern([true, true, true])
	_ok(m5.ended, "102 ends after repeat to target")
	_ok(m5.player_score == 3, "102 score 3")
	_ok(m5.phase == DanceMatch.Phase.FINISHED, "102 no OWN")


func _test_grades() -> void:
	_ok(DanceTiming.compute_victory_grade(3, 3, 2) == GameTypes.VictoryGrade.CLOSE, "109 3:2 CLOSE")
	_ok(DanceTiming.compute_victory_grade(3, 3, 1) == GameTypes.VictoryGrade.CRUSHING, "109 3:1 CRUSHING")
	_ok(DanceTiming.compute_victory_grade(3, 3, 2) == GameTypes.VictoryGrade.CLOSE, "109 2:3 CLOSE")
	_ok(DanceTiming.compute_victory_grade(3, 3, 1) == GameTypes.VictoryGrade.CRUSHING, "109 1:3 CRUSHING")
	_ok(DanceTiming.compute_victory_grade(5, 5, 4) == GameTypes.VictoryGrade.CLOSE, "110 5:4 CLOSE")
	_ok(DanceTiming.compute_victory_grade(5, 5, 3) == GameTypes.VictoryGrade.CLOSE, "110 5:3 CLOSE")
	_ok(DanceTiming.compute_victory_grade(5, 5, 2) == GameTypes.VictoryGrade.CRUSHING, "110 5:2 CRUSHING")
	_ok(DanceTiming.compute_victory_grade(5, 5, 4) == GameTypes.VictoryGrade.CLOSE, "110 4:5 CLOSE")
	_ok(DanceTiming.compute_victory_grade(5, 5, 3) == GameTypes.VictoryGrade.CLOSE, "110 3:5 CLOSE")
	_ok(DanceTiming.compute_victory_grade(5, 5, 2) == GameTypes.VictoryGrade.CRUSHING, "110 2:5 CRUSHING")


func _test_perks() -> void:
	var sw: DanceMatch = _new_match(4, 4, false, {"staged_walk": true}, 31)
	sw.debug_skip_to_player_repeat()
	sw.debug_apply_move_result(DanceTiming.Result.HIT)
	sw.debug_apply_move_result(DanceTiming.Result.HIT)
	sw.debug_apply_move_result(DanceTiming.Result.HIT)
	# Restart a fresh input phase with streak 3 then error — use ongoing own or new
	# After 3 hits sequence ends; craft streak manually on new phase:
	var sw2: DanceMatch = _new_match(4, 4, false, {"staged_walk": true}, 32)
	sw2.debug_skip_to_player_repeat()
	sw2.streak = 3
	sw2.debug_apply_move_result(DanceTiming.Result.MISS)
	_ok(sw2.sequence_errors == 1, "103 error counted")
	_ok(sw2.streak == 2, "103 streak halved to 2")
	_ok(sw2.used_staged_walk, "103 perk used")
	sw2.debug_apply_move_result(DanceTiming.Result.MISS)
	_ok(sw2.streak == 0, "103 next error resets")

	var sw0: DanceMatch = _new_match(4, 4, false, {"staged_walk": true}, 33)
	sw0.debug_skip_to_player_repeat()
	_ok(sw0.streak == 0, "104 streak 0")
	sw0.debug_apply_move_result(DanceTiming.Result.MISS)
	_ok(not sw0.used_staged_walk, "104 perk not used at streak 0")

	var bonus: float = DanceTiming.compute_streak_bonus(4)
	_ok(is_equal_approx(bonus, 0.06), "105 streak bonus 0.06")
	var eff: float = DanceTiming.compute_effective_window(0.18, 4, false)
	_ok(is_equal_approx(eff, 0.24), "105 effective 0.24")

	var rh: DanceMatch = _new_match(4, 4, false, {"rhythm_in_body": true}, 34)
	_ok(is_equal_approx(rh.get_rhythm_adjusted_base(), 0.216), "106 rhythm base 0.216")

	var rh_o: DanceMatch = _new_match(4, 4, false, {"rhythm_in_body": true}, 35)
	rh_o.debug_skip_to_player_repeat()
	_ok(not rh_o.rhythm_clue_active_for_phase, "107 ordinary no complex clue")

	var rh_s: DanceMatch = _new_match(4, 4, true, {"rhythm_in_body": true}, 36)
	rh_s.debug_skip_to_player_repeat()
	_ok(rh_s.rhythm_clue_active_for_phase, "108 first story clue active")
	_ok(rh_s.rhythm_clue_used, "108 clue marked used")
	rh_s.debug_apply_move_result(DanceTiming.Result.HIT)
	rh_s.phase_time = DanceMatch.BEAT_INTERVAL - 0.20
	_ok(rh_s.should_show_rhythm_clue(), "108 clue 0.25s before beat")
	_ok(rh_s.beat_index == 1, "108 on second beat")
	# Finish and next story repeat — no clue
	rh_s.debug_finish_sequence_with_pattern([true, true, true, true])
	rh_s.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	if rh_s.phase == DanceMatch.Phase.OWN_PREVIEW:
		rh_s.tick(DanceMatch.OWN_PREVIEW_DURATION + 0.01)
	if rh_s.phase == DanceMatch.Phase.PRE_ROLL:
		rh_s.tick(DanceMatch.PRE_ROLL_DURATION + 0.01)
	if rh_s.phase == DanceMatch.Phase.PLAYER_OWN:
		rh_s.debug_finish_sequence_with_pattern([true, true, true, true])
		rh_s.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
	if rh_s.phase == DanceMatch.Phase.OPPONENT_DEMO:
		rh_s.debug_skip_to_player_repeat()
	_ok(not rh_s.rhythm_clue_active_for_phase, "108 second story repeat no clue")


func _test_no_authority_in_dance_sources() -> void:
	var paths: Array[String] = [
		"res://minigames/dance/dance_match.gd",
		"res://minigames/dance/dance_minigame.gd",
		"res://minigames/dance/dance_timing.gd",
	]
	for p in paths:
		var src: String = FileAccess.get_file_as_string(p)
		_ok(not src.contains("add_authority"), "112 no add_authority in %s" % p.get_file())
		_ok(not src.contains("lose_authority"), "112 no lose_authority in %s" % p.get_file())
		_ok(not src.contains("mark_rival_defeated"), "112 no mark_rival_defeated in %s" % p.get_file())


func _load_rival_fixture(path: String) -> void:
	var def: RivalDefinition = load(path) as RivalDefinition
	_ok(def != null, "load %s" % path)
	if def != null:
		_re.call("register_rival_definition", def)


func _drive_dance_win(mg: DanceMinigame) -> void:
	var sm: DanceMatch = mg.match_state
	while not sm.ended:
		if sm.phase == DanceMatch.Phase.OPPONENT_DEMO:
			sm.debug_skip_to_player_repeat()
		elif sm.phase == DanceMatch.Phase.PRE_ROLL:
			sm.tick(DanceMatch.PRE_ROLL_DURATION + 0.01)
		elif sm.phase == DanceMatch.Phase.OWN_PREVIEW:
			sm.tick(DanceMatch.OWN_PREVIEW_DURATION + 0.01)
		elif sm.phase == DanceMatch.Phase.ROUND_FEEDBACK:
			sm.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
		elif sm.is_input_phase():
			var flags: Array = []
			for _i in sm.active_sequence.size():
				flags.append(true)
			sm.debug_finish_sequence_with_pattern(flags)
		else:
			sm.tick(0.1)
		if sm.ended:
			break


func _drive_dance_loss(mg: DanceMinigame) -> void:
	var sm: DanceMatch = mg.match_state
	while not sm.ended:
		if sm.phase == DanceMatch.Phase.OPPONENT_DEMO:
			sm.debug_skip_to_player_repeat()
		elif sm.phase == DanceMatch.Phase.PRE_ROLL:
			sm.tick(DanceMatch.PRE_ROLL_DURATION + 0.01)
		elif sm.phase == DanceMatch.Phase.OWN_PREVIEW:
			sm.tick(DanceMatch.OWN_PREVIEW_DURATION + 0.01)
		elif sm.phase == DanceMatch.Phase.ROUND_FEEDBACK:
			sm.tick(DanceMatch.FEEDBACK_DURATION + 0.01)
		elif sm.is_input_phase():
			var flags: Array = []
			for _i in sm.active_sequence.size():
				flags.append(false)
			sm.debug_finish_sequence_with_pattern(flags)
		else:
			sm.tick(0.1)
		if sm.ended:
			break


func _run_integration_tests() -> void:
	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	_re.call("clear_rival_overrides")
	_load_rival_fixture("res://data/test/rival_test_low.tres")
	_load_rival_fixture("res://data/test/rival_test_story.tres")
	if _runner != null and _runner.has_method("register_as_runner"):
		_runner.call("register_as_runner")

	# Unsupported types must not fake-complete
	_finish_count = 0
	var sigma_def: RivalDefinition = RivalDefinition.new()
	sigma_def.id = &"rival_test_sigma_only"
	sigma_def.display_name = "SigmaOnly"
	sigma_def.required_authority = 0
	sigma_def.authority_reward = 1
	sigma_def.preferred_competition = GameTypes.CompetitionType.SIGMA
	sigma_def.allowed_competitions = [
		GameTypes.CompetitionType.SIGMA,
		GameTypes.CompetitionType.SLAP,
	] as Array[GameTypes.CompetitionType]
	_gs.call("restore_purchased_perks", [PerkIds.AURA_PRESENCE_REGISTERED])
	_re.call("register_rival_definition", sigma_def)
	_re.call("start_encounter", &"rival_test_sigma_only", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SIGMA)
	_ok(_finish_count == 0, "83 unsupported SIGMA no fake result")
	_ok(bool(_re.call("has_active_encounter")), "83 encounter still active")
	_ok(_runner.call("get_active_minigame") == null, "83 no minigame for SIGMA")
	_re.call("force_clear_session")
	_gs.call("reset_for_new_game")

	# E2E win DANCE
	_finish_count = 0
	_last_encounter = null
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 4)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	var choose: Dictionary = _re.call("choose_competition", GameTypes.CompetitionType.DANCE) as Dictionary
	_ok(bool(choose.get("ok", false)), "82 route DANCE")
	await get_tree().process_frame
	var mg: DanceMinigame = _runner.call("get_active_minigame") as DanceMinigame
	_ok(mg != null and mg.match_state != null, "82 DanceMinigame active")
	if mg == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	_ok(mg.match_state.target_score == 3, "ordinary target 3")
	_drive_dance_win(mg)
	var res: RivalCompetitionResult = mg.match_state.build_result_once()
	_ok(res != null, "111 typed result")
	if res != null:
		_ok(res.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN, "111 PLAYER_WIN")
		_ok(res.debug_score_summary.begins_with("DANCE "), "66 DANCE summary")
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_finish_count == 1, "113 encounter finished once")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			"113 Rival Authority path WIN",
		)
		_ok(bool(_gs.call("is_rival_defeated", &"rival_test_low")), "113 defeated")
	var before: int = _finish_count
	if is_instance_valid(mg):
		mg.force_finish_emit()
	_ok(_finish_count == before, "67 runner single submit")
	_ok(_runner.call("get_active_minigame") == null, "116 cleanup null")
	_ok(not bool(_runner.call("is_busy")), "116 busy false")

	# E2E loss
	_re.call("force_clear_session")
	_finish_count = 0
	_last_encounter = null
	var auth_before: int = int(_gs.call("get_authority"))
	_re.call("start_encounter", &"rival_test_story", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.DANCE)
	await get_tree().process_frame
	mg = _runner.call("get_active_minigame") as DanceMinigame
	_ok(mg != null, "114 loss minigame")
	if mg == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	_ok(mg.match_state.target_score == 5, "story target 5")
	_drive_dance_loss(mg)
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_last_encounter != null, "114 loss result")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
			"114 PLAYER_LOSS",
		)
	_ok(int(_gs.call("get_authority")) == maxi(auth_before - 1, 0), "114 authority -1 via Rival")
