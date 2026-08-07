extends Node
## MODULE 07A Slap Minigame self-test (formulas, FSM, perks, host integration).
## Run: res://minigames/slap/test/slap_minigame_test.tscn --quit-after 8000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _re: Node = null
var _host: SlapCompetitionHost = null
var _finish_count: int = 0
var _last_encounter: RivalEncounterResult = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_re = get_node("/root/RivalEncounters")
	await get_tree().process_frame
	_ensure_host()
	if not _re.encounter_finished.is_connected(_on_finished):
		_re.encounter_finished.connect(_on_finished)
	_run_sync_tests()
	await _run_integration_tests()
	if _failed == 0:
		DfLog.info("MODULE_07A_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_07A_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_07A_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_07A_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
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
		push_error("[MODULE_07A_TEST] FAIL: %s" % label)
		print("MODULE_07A_TEST FAIL: %s" % label)


func _ensure_host() -> void:
	var existing: Node = get_tree().root.get_node_or_null("SlapCompetitionHost")
	if existing != null:
		_host = existing as SlapCompetitionHost
	else:
		_host = SlapCompetitionHost.new()
		_host.name = "SlapCompetitionHost"
		get_tree().root.add_child(_host)
	_host.enabled = true


func _new_match(
	player_lv: int = 4,
	rival_lv: int = 4,
	story: bool = false,
	perks: Dictionary = {},
	rng_seed: int = 1,
) -> SlapMatch:
	var m: SlapMatch = SlapMatch.new()
	m.setup(player_lv, rival_lv, story, perks, rng_seed)
	return m


func _hit_normal(m: SlapMatch) -> void:
	m.debug_set_zone(0.5, m.target_width)
	var outer: float = m.target_start + (m.perfect_start - m.target_start) * 0.5
	if outer >= m.perfect_start:
		outer = m.target_start + 0.001
	m.set_pointer(outer)
	m.press_primary()


func _hit_perfect(m: SlapMatch) -> void:
	m.debug_set_zone(0.5, m.target_width)
	m.set_pointer(m.target_center)
	m.press_primary()


func _miss(m: SlapMatch) -> void:
	m.debug_set_zone(0.5, m.target_width)
	m.set_pointer(0.01)
	m.press_primary()


func _run_sync_tests() -> void:
	_test_formulas()
	_test_timing_boundaries()
	_test_grades()
	_test_fsm_core()
	_test_streak()
	_test_perks()
	_test_specials_exclusive()
	_test_result_once()


func _test_formulas() -> void:
	_ok(is_equal_approx(SlapTiming.compute_target_width(0), 0.20), "77 width eq")
	_ok(is_equal_approx(SlapTiming.compute_pointer_speed(0), 0.70), "77 speed eq")
	_ok(is_equal_approx(SlapTiming.compute_target_width(4), 0.25), "78 width +4")
	_ok(is_equal_approx(SlapTiming.compute_pointer_speed(4), 0.60), "78 speed +4")
	_ok(is_equal_approx(SlapTiming.compute_target_width(-4), 0.15), "79 width -4")
	_ok(is_equal_approx(SlapTiming.compute_pointer_speed(-4), 0.80), "79 speed -4")
	_ok(is_equal_approx(SlapTiming.compute_target_width(100), 0.28), "80 width clamp hi")
	_ok(is_equal_approx(SlapTiming.compute_pointer_speed(100), 0.55), "80 speed clamp lo")
	_ok(is_equal_approx(SlapTiming.compute_target_width(-100), 0.12), "80 width clamp lo")
	_ok(is_equal_approx(SlapTiming.compute_pointer_speed(-100), 0.95), "80 speed clamp hi")


func _test_timing_boundaries() -> void:
	_ok(
		SlapTiming.evaluate_timing(0.4, 0.4, 0.6, 0.47, 0.53) == SlapTiming.Result.HIT,
		"91 start HIT inclusive",
	)
	_ok(
		SlapTiming.evaluate_timing(0.6, 0.4, 0.6, 0.47, 0.53) == SlapTiming.Result.HIT,
		"91 end HIT inclusive",
	)
	_ok(
		SlapTiming.evaluate_timing(0.47, 0.4, 0.6, 0.47, 0.53) == SlapTiming.Result.PERFECT,
		"91 perfect start",
	)
	_ok(
		SlapTiming.evaluate_timing(0.39, 0.4, 0.6, 0.47, 0.53) == SlapTiming.Result.MISS,
		"91 outside miss",
	)


func _test_grades() -> void:
	_ok(SlapTiming.compute_victory_grade(3, 3, 2) == GameTypes.VictoryGrade.CLOSE, "89 3:2 CLOSE")
	_ok(SlapTiming.compute_victory_grade(3, 3, 1) == GameTypes.VictoryGrade.CRUSHING, "89 3:1 CRUSHING")
	_ok(SlapTiming.compute_victory_grade(3, 3, 0) == GameTypes.VictoryGrade.CRUSHING, "89 3:0 CRUSHING")
	_ok(SlapTiming.compute_victory_grade(5, 5, 4) == GameTypes.VictoryGrade.CLOSE, "90 5:4 CLOSE")
	_ok(SlapTiming.compute_victory_grade(5, 5, 3) == GameTypes.VictoryGrade.CLOSE, "90 5:3 CLOSE")
	_ok(SlapTiming.compute_victory_grade(5, 5, 2) == GameTypes.VictoryGrade.CRUSHING, "90 5:2 CRUSHING")
	_ok(SlapTiming.compute_victory_grade(3, 3, 2) == GameTypes.VictoryGrade.CLOSE, "89 loss grade uses winner margin")


func _test_fsm_core() -> void:
	var m: SlapMatch = _new_match()
	_ok(m.phase == SlapMatch.Phase.ATTACK, "start ATTACK")
	_ok(m.target_score == 3, "87 ordinary target 3")
	_hit_normal(m)
	_ok(m.player_score == 1 and m.rival_score == 0, "81 attack hit 1:0")
	_ok(m.phase == SlapMatch.Phase.DEFENSE, "81 phase DEFENSE")
	_hit_perfect(m)
	_ok(m.player_score == 1 and m.rival_score == 0, "84 defense block")
	_ok(m.phase == SlapMatch.Phase.ATTACK, "84 back to ATTACK")

	var m2: SlapMatch = _new_match()
	_miss(m2)
	_ok(m2.player_score == 0 and m2.rival_score == 0, "82 attack miss no score")
	_ok(m2.phase == SlapMatch.Phase.DEFENSE, "82 to DEFENSE")

	var m3: SlapMatch = _new_match()
	m3.set_pointer(0.0)
	for _i in 200:
		m3.tick(0.05)
		if m3.phase == SlapMatch.Phase.DEFENSE or m3.ended:
			break
	_ok(m3.phase == SlapMatch.Phase.DEFENSE, "83 timeout to DEFENSE")
	_ok(m3.player_score == 0 and m3.rival_score == 0, "83 timeout no score")

	var m4: SlapMatch = _new_match()
	_hit_normal(m4)
	_miss(m4)
	_ok(m4.player_score == 1 and m4.rival_score == 1, "85 defense miss 1:1")
	_ok(m4.phase == SlapMatch.Phase.ATTACK, "85 after defense miss ATTACK")

	var m5: SlapMatch = _new_match()
	m5.debug_set_zone(0.5)
	m5.set_pointer(0.01)
	_ok(m5.press_primary(), "86 first press accepted")
	# Immediate phase advance clears consume flags; same-phase reject via half_resolved.
	m5.half_resolved = true
	m5.primary_consumed = true
	_ok(not m5.press_primary(), "86 second press rejected")

	var m6: SlapMatch = _new_match(4, 4, true)
	_ok(m6.target_score == 5, "88 story target 5")

	var m7: SlapMatch = _new_match()
	for _j in 3:
		_hit_perfect(m7)
		if m7.ended:
			break
		_hit_perfect(m7)
	_ok(m7.ended, "87 match ends at target")
	_ok(m7.player_score >= 3, "87 player reached 3")
	var res7: RivalCompetitionResult = m7.build_result_once()
	_ok(res7 != null, "110 typed result")
	_ok(res7.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN, "110 PLAYER_WIN")


func _test_streak() -> void:
	var m: SlapMatch = _new_match()
	_hit_perfect(m)
	_hit_perfect(m)
	_hit_perfect(m)
	_ok(m.streak == 3, "92 streak 3")
	_ok(is_equal_approx(m.get_perfect_fraction(), 0.45), "92 perfect frac 0.45")
	_miss(m)
	_ok(m.streak == 0, "92 miss resets streak")


func _test_perks() -> void:
	var nw: SlapMatch = _new_match(4, 4, false, {"no_warmup": true}, 3)
	_ok(is_equal_approx(nw.target_width, 0.25), "93 first width *1.25")
	_hit_normal(nw)
	_hit_perfect(nw)
	_ok(is_equal_approx(nw.target_width, 0.20), "93 second attack normal width")

	var tc: SlapMatch = _new_match(4, 4, false, {"tough_cheek": true}, 4)
	# Enter DEFENSE with streak 4 without finishing ordinary match (target 3).
	_hit_perfect(tc)
	_ok(tc.phase == SlapMatch.Phase.DEFENSE, "94 on defense")
	tc.streak = 4
	_ok(tc.streak == 4, "94 streak 4 before")
	_miss(tc)
	_ok(tc.rival_score == 1, "94 rival +1")
	_ok(tc.streak == 2, "94 streak halved to 2")
	_ok(tc.used_tough_cheek, "94 perk used")
	_miss(tc)
	_miss(tc)
	_ok(tc.streak == 0, "94 second miss full reset")

	var tc0: SlapMatch = _new_match(4, 4, false, {"tough_cheek": true}, 5)
	_miss(tc0)
	_miss(tc0)
	_ok(tc0.rival_score == 1, "95 rival +1")
	_ok(not tc0.used_tough_cheek, "95 not consumed at streak0")
	_ok(tc0.streak == 0, "95 streak stays 0")

	var ds: SlapMatch = _new_match(4, 4, false, {"double_slap": true}, 6)
	_ok(ds.arm_double_slap(), "96 arm Q")
	_hit_perfect(ds)
	_ok(ds.player_score == 2, "96 perfect +2")
	_ok(not ds.defense_penalty_pending, "96 no penalty on perfect")

	var ds2: SlapMatch = _new_match(4, 4, false, {"double_slap": true}, 7)
	ds2.arm_double_slap()
	_hit_normal(ds2)
	_ok(ds2.player_score == 1, "97 normal +1")
	_ok(ds2.phase == SlapMatch.Phase.DEFENSE, "97 in defense")
	_ok(is_equal_approx(ds2.target_width, maxf(0.20 * 0.65, 0.08)), "97 defense width *0.65")

	var ds3: SlapMatch = _new_match(4, 4, false, {"double_slap": true}, 8)
	ds3.arm_double_slap()
	_miss(ds3)
	_ok(ds3.player_score == 0, "98 miss +0")
	_ok(is_equal_approx(ds3.target_width, maxf(0.20 * 0.65, 0.08)), "98 miss penalty")

	var ca: SlapMatch = _new_match(4, 4, false, {"counter_argument": true}, 9)
	_hit_normal(ca)
	_hit_perfect(ca)
	_ok(ca.counter_armed, "99 counter armed")
	_hit_perfect(ca)
	_ok(ca.player_score == 3, "99 perfect attack +2 total")

	var ca3: SlapMatch = _new_match(4, 4, false, {"counter_argument": true}, 11)
	_hit_normal(ca3)
	_hit_perfect(ca3)
	_hit_normal(ca3)
	_ok(not ca3.counter_armed, "100 consumed")
	_miss(ca3)
	var score_before: int = ca3.player_score
	_hit_perfect(ca3)
	_ok(ca3.player_score == score_before + 1, "100 following perfect no old bonus")

	var stack: SlapMatch = _new_match(4, 4, false, {
		"double_slap": true,
		"counter_argument": true,
	}, 12)
	_hit_normal(stack)
	_hit_perfect(stack)
	_ok(stack.counter_armed, "101 counter ready")
	stack.arm_double_slap()
	_hit_perfect(stack)
	_ok(stack.player_score == 4, "101 +3 from special (1 prior + 3)")

	var mr: SlapMatch = _new_match(4, 4, false, {"mass_reserve": true}, 13)
	_miss(mr)
	_ok(mr.phase == SlapMatch.Phase.ATTACK, "102 stay ATTACK")
	_ok(mr.used_mass_reserve, "102 used")
	_ok(mr.streak == 0, "102 streak 0")
	_miss(mr)
	_ok(mr.phase == SlapMatch.Phase.DEFENSE, "102 second miss to DEFENSE")

	var mr2: SlapMatch = _new_match(4, 4, false, {
		"mass_reserve": true,
		"double_slap": true,
	}, 14)
	mr2.arm_double_slap()
	_miss(mr2)
	_ok(mr2.phase == SlapMatch.Phase.DEFENSE, "103 double miss no mass reserve")
	_ok(not mr2.used_mass_reserve, "103 mass unused")

	var th0: SlapMatch = _new_match(4, 4, false, {"two_handed": true}, 15)
	_ok(not th0.perk_two_handed, "104 unavailable ordinary")
	_ok(not th0.arm_two_handed(), "104 R ignored")

	var th: SlapMatch = _new_match(4, 4, true, {"two_handed": true}, 16)
	_ok(th.perk_two_handed, "105 available story")
	th.arm_two_handed()
	_hit_perfect(th)
	_ok(th.player_score == 2, "105 perfect +2")

	var th2: SlapMatch = _new_match(4, 4, true, {"two_handed": true}, 17)
	th2.arm_two_handed()
	_hit_normal(th2)
	_ok(th2.rival_score == 2, "106 rival +2")
	_ok(th2.streak == 0, "106 streak 0")
	_ok(th2.phase == SlapMatch.Phase.ATTACK, "106 skip DEFENSE")

	var th3: SlapMatch = _new_match(4, 4, true, {"two_handed": true}, 18)
	th3.arm_two_handed()
	_miss(th3)
	_ok(th3.rival_score == 2, "107 miss rival +2")

	var end_m: SlapMatch = _new_match(4, 4, false, {"double_slap": true}, 19)
	_hit_perfect(end_m)
	_hit_perfect(end_m)
	_hit_perfect(end_m)
	_hit_perfect(end_m)
	_ok(end_m.player_score == 2, "109 score 2")
	end_m.arm_double_slap()
	_hit_perfect(end_m)
	_ok(end_m.ended, "109 ends immediately")
	_ok(end_m.player_score >= 3, "109 score >=3")


func _test_specials_exclusive() -> void:
	var m: SlapMatch = _new_match(4, 4, true, {
		"double_slap": true,
		"two_handed": true,
	}, 20)
	_ok(m.arm_double_slap(), "108 arm Q")
	_ok(not m.arm_two_handed(), "108 R rejected")
	_ok(m.double_armed, "108 double remains")
	var m2: SlapMatch = _new_match(4, 4, true, {
		"double_slap": true,
		"two_handed": true,
	}, 21)
	_ok(m2.arm_two_handed(), "108b arm R")
	_ok(not m2.arm_double_slap(), "108b Q rejected")


func _test_result_once() -> void:
	var m: SlapMatch = _new_match()
	for _i in 5:
		_hit_perfect(m)
		if m.ended:
			break
		_hit_perfect(m)
	var r1: RivalCompetitionResult = m.build_result_once()
	_ok(r1 != null, "111 result exists")
	m.set_pointer(0.5)
	_ok(not m.press_primary(), "111 input disabled after end")


func _load_rival_fixture(path: String) -> void:
	var def: RivalDefinition = load(path) as RivalDefinition
	_ok(def != null, "load %s" % path)
	if def != null:
		_re.call("register_rival_definition", def)


func _run_integration_tests() -> void:
	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	_re.call("clear_rival_overrides")
	_load_rival_fixture("res://data/test/rival_test_low.tres")
	_load_rival_fixture("res://data/test/rival_test_story.tres")
	_host.enabled = true

	_finish_count = 0
	_last_encounter = null
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_low",
		GameTypes.RivalEncounterInitiator.PLAYER,
		GameTypes.RivalEncounterContext.WORLD,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "112 start ok")
	# choose_competition() already begins competition (MODULE 06).
	var choose: Dictionary = _re.call("choose_competition", GameTypes.CompetitionType.SLAP) as Dictionary
	_ok(bool(choose.get("ok", false)), "112 choose+begin SLAP")
	var mg: SlapMinigame = _host.get_active_minigame()
	if mg != null:
		mg.auto_tick = false
		mg.accept_input = false
	await get_tree().process_frame
	mg = _host.get_active_minigame()
	_ok(mg != null and mg.match_state != null, "112 slap minigame active")
	if mg == null or mg.match_state == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	var sm: SlapMatch = mg.match_state
	while not sm.ended:
		_hit_perfect(sm)
		if sm.ended:
			break
		_hit_perfect(sm)
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_finish_count == 1, "112 encounter finished once")
	_ok(_last_encounter != null, "112 encounter result")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			"112 PLAYER_WIN",
		)
	var before: int = _finish_count
	if is_instance_valid(mg):
		mg.force_finish_emit()
	_ok(_finish_count == before, "111 host single submit")
	_ok(_host.get_active_minigame() == null, "112 cleanup")

	# Loss path on story rival
	_re.call("force_clear_session")
	_finish_count = 0
	_last_encounter = null
	var start2: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_story",
		GameTypes.RivalEncounterInitiator.PLAYER,
		GameTypes.RivalEncounterContext.WORLD,
	) as Dictionary
	_ok(bool(start2.get("ok", false)), "112b start story")
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	mg = _host.get_active_minigame()
	if mg != null:
		mg.auto_tick = false
		mg.accept_input = false
	await get_tree().process_frame
	mg = _host.get_active_minigame()
	_ok(mg != null, "112b minigame")
	if mg == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	sm = mg.match_state
	while not sm.ended:
		_miss(sm)
		if sm.ended:
			break
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_last_encounter != null, "112b loss result")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
			"112b PLAYER_LOSS",
		)
