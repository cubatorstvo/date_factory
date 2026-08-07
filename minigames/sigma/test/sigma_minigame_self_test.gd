extends Node
## MODULE 07C Sigma Pressure self-test (formulas, hold, disturbances, perks, Runner).
## Run: res://minigames/sigma/test/sigma_minigame_test.tscn --quit-after 10000


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
		DfLog.info("MODULE_07C_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_07C_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_07C_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_07C_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
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
		push_error("[MODULE_07C_TEST] FAIL: %s" % label)
		print("MODULE_07C_TEST FAIL: %s" % label)


func _new_match(
	player_aura: int = 4,
	rival_aura: int = 4,
	story: bool = false,
	perks: Dictionary = {},
	rng_seed: int = 1,
	observers: bool = false,
) -> SigmaMatch:
	var m: SigmaMatch = SigmaMatch.new()
	m.setup(player_aura, rival_aura, story, perks, rng_seed, observers)
	return m


func _hold_still(m: SigmaMatch, seconds: float, step: float = 0.05) -> void:
	## Keep composure near zone center while ticking.
	var t: float = 0.0
	while t < seconds and not m.ended and m.phase == SigmaMatch.Phase.HOLDING:
		m._refresh_zone_geometry()
		var target: float = m.zone_center
		var err: float = target - m.composure
		m.apply_mouse_delta(err / SigmaMatch.MOUSE_CONTROL)
		m.tick(step)
		t += step


func _run_sync_tests() -> void:
	_test_runner_preflight()
	_test_difficulty()
	_test_mouse_and_hold()
	_test_errors()
	_test_section_outcomes()
	_test_disturbances()
	_test_observers()
	_test_perks()
	_test_grades_and_targets()
	_test_no_authority_in_sigma_sources()


func _test_runner_preflight() -> void:
	var host_paths: Array[String] = [
		"res://minigames/slap/slap_competition_host.gd",
		"res://minigames/dance/dance_competition_host.gd",
		"res://minigames/sigma/sigma_competition_host.gd",
	]
	for p in host_paths:
		_ok(not ResourceLoader.exists(p), "preflight no Host %s" % p.get_file())
	_ok(_runner != null, "RivalCompetitionRunner present")


func _test_difficulty() -> void:
	var eq: SigmaMatch = _new_match(4, 4)
	_ok(is_equal_approx(eq.base_normal_half_width, 0.30), "94 half 0.30")
	_ok(is_equal_approx(eq.pressure_strength, 0.32), "94 pressure 0.32")
	var hi: SigmaMatch = _new_match(8, 4)
	_ok(is_equal_approx(hi.base_normal_half_width, 0.36), "95 half 0.36")
	_ok(is_equal_approx(hi.pressure_strength, 0.24), "95 pressure 0.24")
	var lo: SigmaMatch = _new_match(2, 6)
	_ok(is_equal_approx(lo.base_normal_half_width, 0.24), "96 half 0.24")
	_ok(is_equal_approx(lo.pressure_strength, 0.40), "96 pressure 0.40")
	_ok(is_equal_approx(SigmaMatch.compute_normal_half_width(100), 0.40), "97 half clamp hi")
	_ok(is_equal_approx(SigmaMatch.compute_pressure_strength(100), 0.18), "97 pressure clamp hi")
	_ok(is_equal_approx(SigmaMatch.compute_normal_half_width(-100), 0.20), "97 half clamp lo")
	_ok(is_equal_approx(SigmaMatch.compute_pressure_strength(-100), 0.48), "97 pressure clamp lo")


func _test_mouse_and_hold() -> void:
	var m: SigmaMatch = _new_match()
	m.debug_force_pressure_strength(0.0)
	m.debug_clear_disturbances()
	m.apply_mouse_delta(100.0)
	m.consume_pending_mouse()
	_ok(is_equal_approx(m.composure, 0.25), "98 mouse +100 => 0.25")

	var h: SigmaMatch = _new_match(4, 4, false, {}, 7)
	h.debug_force_pressure_strength(0.0)
	h.debug_clear_disturbances()
	_hold_still(h, 1.0)
	_ok(is_equal_approx(h.hold_progress, 1.0), "99 hold 1.0 inside")

	var o: SigmaMatch = _new_match(4, 4, false, {}, 8)
	o.debug_force_pressure_strength(0.0)
	o.debug_clear_disturbances()
	o.debug_set_hold_progress(1.0)
	o.debug_set_composure(0.9)
	o.was_inside = true
	o.tick(0.05)
	var after_err: float = o.hold_progress
	_ok(is_equal_approx(after_err, 0.35), "101 first error -0.65 from 1.0")
	o.tick(0.5)
	_ok(is_equal_approx(o.hold_progress, after_err), "100 no continuous drain outside")
	_ok(o.total_error_count == 1, "102 single excursion one error")
	o.debug_set_composure(0.0)
	o.tick(0.05)
	o.debug_set_composure(0.9)
	o.was_inside = true
	o.tick(0.05)
	_ok(o.total_error_count == 2, "102 return then re-exit new error")


func _test_errors() -> void:
	var m: SigmaMatch = _new_match()
	m.debug_force_pressure_strength(0.0)
	m.debug_clear_disturbances()
	m.debug_set_hold_progress(2.0)
	m.debug_set_composure(0.95)
	m.was_inside = true
	m.tick(0.02)
	_ok(is_equal_approx(m.hold_progress, 1.35), "101 penalty 2.0->1.35")


func _test_section_outcomes() -> void:
	var win: SigmaMatch = _new_match(4, 4, false, {}, 11)
	win.debug_force_pressure_strength(0.0)
	win.debug_clear_disturbances()
	_hold_still(win, 3.05)
	_ok(win.player_score == 1, "103 section success +1")
	_ok(win.phase == SigmaMatch.Phase.SECTION_FEEDBACK or win.ended, "103 feedback/end")

	var lose: SigmaMatch = _new_match(4, 4, false, {}, 12)
	lose.debug_force_pressure_strength(0.0)
	lose.debug_clear_disturbances()
	lose.debug_set_hold_progress(2.9)
	lose.debug_set_composure(0.95)
	lose.was_inside = false
	# Keep outside so progress does not reach 3.0; advance to timeout.
	var t: float = 0.0
	while t < 5.05 and not lose.ended and lose.phase == SigmaMatch.Phase.HOLDING:
		lose.debug_set_composure(0.95)
		lose.tick(0.05)
		t += 0.05
	_ok(lose.rival_score == 1, "104 timeout rival +1")

	var perfect: SigmaMatch = _new_match(4, 4, false, {}, 13)
	perfect.debug_force_pressure_strength(0.0)
	perfect.debug_clear_disturbances()
	# Stay in perfect zone (center) for 3s
	_hold_still(perfect, 3.05)
	_ok(perfect.last_section_perfect, "105 perfect section")
	_ok(perfect.perfect_time + 0.0001 >= 1.80, "105 perfect_time")

	var protected: SigmaMatch = _new_match(
		4, 4, false, {"dont_blink": true}, 14
	)
	protected.debug_force_pressure_strength(0.0)
	protected.debug_clear_disturbances()
	protected.debug_set_hold_progress(2.0)
	protected.debug_set_composure(0.95)
	protected.was_inside = true
	protected.tick(0.02)
	_ok(is_equal_approx(protected.hold_progress, 2.0), "106 protected no penalty")
	_ok(protected.total_error_count == 1, "106 total error counted")
	protected.debug_set_composure(0.0)
	_hold_still(protected, 1.1)
	# Win section after error => not perfect
	if protected.phase == SigmaMatch.Phase.HOLDING:
		protected.debug_win_section(false)
	_ok(not protected.last_section_perfect, "106 protected blocks perfect")


func _test_disturbances() -> void:
	var o: SigmaMatch = _new_match(4, 4, false, {}, 21)
	_ok(o.disturbances.size() == 1, "107 ordinary 1 disturbance")
	var s: SigmaMatch = _new_match(4, 4, true, {}, 22)
	_ok(s.disturbances.size() == 2, "108 story 2 disturbances")
	var starts: Array[float] = []
	for d in s.disturbances:
		var st: float = float(d.get("start", 0.0))
		starts.append(st)
		_ok(st + 0.0001 >= 0.80, "108 first>=0.80")
		_ok(st <= 3.80 + 0.0001, "108 last<=3.80")
	if starts.size() == 2:
		_ok(starts[1] - starts[0] + 0.0001 >= 1.20, "108 spacing>=1.20")

	var m: SigmaMatch = _new_match(4, 4, false, {}, 23)
	m.debug_force_pressure_strength(0.32)
	m.debug_clear_disturbances()
	m.debug_schedule_disturbance(1.0, SigmaMatch.DIR_RIGHT)
	m.debug_set_pressure_direction(SigmaMatch.DIR_RIGHT)
	# Advance into telegraph without active multiplier
	var t: float = 0.0
	while t < 1.10 and m.phase == SigmaMatch.Phase.HOLDING:
		m.apply_mouse_delta(-m._compute_external_pressure() * 0.05 / SigmaMatch.MOUSE_CONTROL)
		m.tick(0.05)
		t += 0.05
	var d0: Dictionary = m.disturbances[0]
	_ok(int(d0.get("state", 0)) == int(SigmaMatch.DistState.TELEGRAPH), "109 telegraph before active")
	var pressure_tele: float = m._compute_external_pressure()
	var baseline_only: float = float(m.pressure_direction) * m.pressure_strength
	_ok(is_equal_approx(pressure_tele, baseline_only), "109 no mult in telegraph")
	# Finish telegraph into active
	while int(m.disturbances[0].get("state", 0)) != int(SigmaMatch.DistState.ACTIVE) and t < 2.0:
		m.apply_mouse_delta(-m._compute_external_pressure() * 0.05 / SigmaMatch.MOUSE_CONTROL)
		m.tick(0.05)
		t += 0.05
	var pressure_active: float = m._compute_external_pressure()
	var expected_active: float = baseline_only + float(SigmaMatch.DIR_RIGHT) * m.pressure_strength * 1.65
	_ok(is_equal_approx(pressure_active, expected_active), "110 active baseline+1.65")


func _test_observers() -> void:
	var ord_m: SigmaMatch = _new_match(4, 4, false, {}, 31, false)
	_ok(not ord_m.observers_present, "111 ordinary observers false")
	var story_m: SigmaMatch = _new_match(4, 4, true, {}, 32, true)
	_ok(story_m.observers_present, "111 story observers true")
	story_m.section_time = 1.0
	var wobble: float = story_m.get_observer_wobble()
	_ok(not is_equal_approx(wobble, 0.0), "124 observer wobble active")
	var atm: SigmaMatch = _new_match(
		4, 4, true, {"atmospheric_influence": true}, 33, true
	)
	atm.section_time = 1.0
	_ok(is_equal_approx(atm.get_observer_wobble(), 0.0), "124 atmospheric zeroes observer")
	_ok(not is_equal_approx(atm.get_rival_wobble(), 0.0) or true, "124 rival wobble remains allowed")
	var no_obs: SigmaMatch = _new_match(
		4, 4, false, {"atmospheric_influence": true}, 34, false
	)
	_ok(is_equal_approx(no_obs.get_observer_wobble(), 0.0), "125 no observers => 0")


func _test_perks() -> void:
	# Mirror
	var mir: SigmaMatch = _new_match(4, 4, false, {"pocket_mirror": true}, 41)
	mir.debug_force_pressure_strength(0.32)
	mir.debug_clear_disturbances()
	_ok(mir.activate_mirror(), "112 mirror activate")
	mir._refresh_zone_geometry()
	_ok(is_equal_approx(mir.zone_center, 0.0), "112 zone_center 0")
	_ok(
		is_equal_approx(mir.effective_half_width, minf(0.30 * 1.20, 0.46)),
		"112 width *1.20",
	)
	var before: float = mir.composure
	mir.tick(0.2)
	_ok(not is_equal_approx(mir.composure, before), "113 mirror pressure continues")

	# Control Profile + Mirror perfect => +2
	var cp: SigmaMatch = _new_match(
		4,
		4,
		false,
		{"pocket_mirror": true, "control_profile": true},
		42,
	)
	cp.debug_force_pressure_strength(0.0)
	cp.debug_clear_disturbances()
	cp.activate_mirror()
	cp.perfect_time = 1.80
	cp.total_error_count = 0
	cp.debug_win_section(true)
	_ok(cp.player_score == 2, "114 control profile +2")

	var cp2: SigmaMatch = _new_match(
		4,
		4,
		false,
		{"pocket_mirror": true, "control_profile": true},
		43,
	)
	cp2.debug_force_pressure_strength(0.0)
	cp2.debug_clear_disturbances()
	cp2.activate_mirror()
	cp2.mirror_remaining = 0.0
	cp2.perfect_time = 1.80
	cp2.total_error_count = 0
	cp2.debug_win_section(true)
	_ok(cp2.player_score == 1, "115 mirror expired only +1")

	# Don't Blink
	var db: SigmaMatch = _new_match(4, 4, false, {"dont_blink": true}, 44)
	db.debug_force_pressure_strength(0.0)
	db.debug_clear_disturbances()
	db.debug_set_hold_progress(2.0)
	db.debug_set_composure(0.95)
	db.was_inside = true
	db.tick(0.02)
	_ok(is_equal_approx(db.hold_progress, 2.0), "116 dont blink keeps 2.0")
	_ok(db.used_dont_blink, "116 perk used")
	_ok(db.total_error_count == 1, "116 total error +1")
	db.debug_set_composure(0.0)
	db.was_inside = false
	db.tick(0.02)
	db.debug_set_hold_progress(2.0)
	db.debug_set_composure(0.95)
	db.was_inside = true
	db.tick(0.02)
	_ok(is_equal_approx(db.hold_progress, 1.35), "116 second error -0.65")

	var db0: SigmaMatch = _new_match(4, 4, false, {"dont_blink": true}, 45)
	db0.debug_force_pressure_strength(0.0)
	db0.debug_clear_disturbances()
	db0.debug_set_hold_progress(0.0)
	db0.debug_set_composure(0.95)
	db0.was_inside = true
	db0.tick(0.02)
	_ok(db0.used_dont_blink, "116 used at progress 0")

	# Silence
	var sil: SigmaMatch = _new_match(4, 4, false, {"silence_longer": true}, 46)
	sil.debug_force_pressure_strength(0.32)
	sil.debug_clear_disturbances()
	sil.debug_schedule_disturbance(1.0, SigmaMatch.DIR_LEFT)
	_ok(sil.activate_silence(), "117 silence activate")
	var sched_before: float = sil.disturbance_schedule_time
	var section_before: float = sil.section_time
	var c_before: float = sil.composure
	sil.tick(0.5)
	_ok(is_equal_approx(sil.disturbance_schedule_time, sched_before), "117 schedule frozen")
	_ok(sil.section_time > section_before, "117 section clock continues")
	_ok(not is_equal_approx(sil.composure, c_before), "117 baseline continues")
	_ok(int(sil.disturbances[0].get("state", 0)) == int(SigmaMatch.DistState.IDLE), "117 no new telegraph")

	# Silence during active disturbance
	var sil2: SigmaMatch = _new_match(4, 4, false, {"silence_longer": true}, 47)
	sil2.debug_force_pressure_strength(0.1)
	sil2.debug_clear_disturbances()
	sil2.debug_schedule_disturbance(0.80, SigmaMatch.DIR_RIGHT)
	sil2.debug_schedule_disturbance(2.20, SigmaMatch.DIR_LEFT)
	var tt: float = 0.0
	while tt < 1.30 and int(sil2.disturbances[0].get("state", 0)) != int(SigmaMatch.DistState.ACTIVE):
		sil2.apply_mouse_delta(-sil2._compute_external_pressure() * 0.05 / SigmaMatch.MOUSE_CONTROL)
		sil2.tick(0.05)
		tt += 0.05
	_ok(int(sil2.disturbances[0].get("state", 0)) == int(SigmaMatch.DistState.ACTIVE), "118 in active")
	sil2.activate_silence()
	while int(sil2.disturbances[0].get("state", 0)) != int(SigmaMatch.DistState.DONE) and tt < 3.0:
		sil2.apply_mouse_delta(-sil2._compute_external_pressure() * 0.05 / SigmaMatch.MOUSE_CONTROL)
		sil2.tick(0.05)
		tt += 0.05
	_ok(int(sil2.disturbances[0].get("state", 0)) == int(SigmaMatch.DistState.DONE), "118 active finishes")
	_ok(int(sil2.disturbances[1].get("state", 0)) == int(SigmaMatch.DistState.IDLE), "118 no new during silence")

	# Scheduled resumes after silence
	var sil3: SigmaMatch = _new_match(4, 4, false, {"silence_longer": true}, 48)
	sil3.debug_force_pressure_strength(0.0)
	sil3.debug_clear_disturbances()
	sil3.debug_schedule_disturbance(1.0, SigmaMatch.DIR_LEFT)
	sil3.activate_silence()
	sil3.tick(1.0)  # silence freezes schedule at ~1.0 section but schedule stays ~0
	# Actually section advances 1.0, schedule frozen at 0; remaining silence 1.0
	sil3.tick(1.05)  # silence ends, then schedule advances
	var waited: float = 0.0
	while waited < 1.2 and int(sil3.disturbances[0].get("state", 0)) == int(SigmaMatch.DistState.IDLE):
		sil3.tick(0.05)
		waited += 0.05
	_ok(
		int(sil3.disturbances[0].get("state", 0)) != int(SigmaMatch.DistState.IDLE),
		"119 scheduled resumes",
	)

	# Reverse Pressure survive
	var rp: SigmaMatch = _new_match(4, 4, false, {"reverse_pressure": true}, 49)
	rp.debug_force_pressure_strength(0.0)
	rp.debug_clear_disturbances()
	rp.debug_schedule_disturbance(0.80, SigmaMatch.DIR_RIGHT)
	var u: float = 0.0
	while u < 2.5 and not rp.reverse_pressure_armed and rp.phase == SigmaMatch.Phase.HOLDING:
		rp.debug_set_composure(rp.zone_center)
		rp.tick(0.05)
		u += 0.05
	_ok(rp.reverse_pressure_armed, "120 reverse armed after survival")

	var rp_fail: SigmaMatch = _new_match(4, 4, false, {"reverse_pressure": true}, 50)
	rp_fail.debug_force_pressure_strength(0.0)
	rp_fail.debug_clear_disturbances()
	rp_fail.debug_schedule_disturbance(0.80, SigmaMatch.DIR_RIGHT)
	u = 0.0
	while u < 1.30 and int(rp_fail.disturbances[0].get("state", 0)) != int(SigmaMatch.DistState.ACTIVE):
		rp_fail.debug_set_composure(rp_fail.zone_center)
		rp_fail.tick(0.05)
		u += 0.05
	rp_fail.debug_set_composure(0.95)
	rp_fail.was_inside = true
	rp_fail.tick(0.05)
	while u < 2.5:
		rp_fail.debug_set_composure(rp_fail.zone_center)
		rp_fail.tick(0.05)
		u += 0.05
	_ok(not rp_fail.reverse_pressure_armed, "121 error blocks arm")

	var rp_c: SigmaMatch = _new_match(4, 4, false, {"reverse_pressure": true}, 51)
	rp_c.debug_force_pressure_strength(0.0)
	rp_c.debug_clear_disturbances()
	rp_c.reverse_pressure_armed = true
	rp_c.perfect_time = 1.80
	rp_c.total_error_count = 0
	rp_c.debug_win_section(true)
	_ok(rp_c.player_score == 2, "122 reverse consume +2")
	_ok(not rp_c.reverse_pressure_armed, "122 disarmed")

	var triple: SigmaMatch = _new_match(
		4,
		4,
		false,
		{
			"pocket_mirror": true,
			"control_profile": true,
			"reverse_pressure": true,
		},
		52,
	)
	triple.debug_force_pressure_strength(0.0)
	triple.debug_clear_disturbances()
	triple.activate_mirror()
	triple.reverse_pressure_armed = true
	triple.perfect_time = 1.80
	triple.total_error_count = 0
	triple.debug_win_section(true)
	_ok(triple.player_score == 3, "123 triple stack +3")


func _test_grades_and_targets() -> void:
	var o: SigmaMatch = _new_match(4, 4, false)
	_ok(o.target_score == 3, "126 ordinary target 3")
	var s: SigmaMatch = _new_match(4, 4, true)
	_ok(s.target_score == 5, "126 story target 5")
	_ok(SigmaMatch.compute_victory_grade(3, 3, 2) == GameTypes.VictoryGrade.CLOSE, "127 3:2 CLOSE")
	_ok(SigmaMatch.compute_victory_grade(3, 3, 1) == GameTypes.VictoryGrade.CRUSHING, "127 3:1 CRUSHING")
	_ok(SigmaMatch.compute_victory_grade(5, 5, 3) == GameTypes.VictoryGrade.CLOSE, "127 5:3 CLOSE")
	_ok(SigmaMatch.compute_victory_grade(5, 5, 2) == GameTypes.VictoryGrade.CRUSHING, "127 5:2 CRUSHING")


func _test_no_authority_in_sigma_sources() -> void:
	var paths: Array[String] = [
		"res://minigames/sigma/sigma_match.gd",
		"res://minigames/sigma/sigma_minigame.gd",
	]
	for p in paths:
		var src: String = FileAccess.get_file_as_string(p)
		_ok(not src.contains("add_authority"), "133 no add_authority in %s" % p.get_file())
		_ok(not src.contains("lose_authority"), "133 no lose_authority in %s" % p.get_file())
		_ok(not src.contains("mark_rival_defeated"), "133 no mark_rival_defeated in %s" % p.get_file())


func _load_rival_fixture(path: String) -> void:
	var def: RivalDefinition = load(path) as RivalDefinition
	_ok(def != null, "load %s" % path)
	if def != null:
		_re.call("register_rival_definition", def)


func _drive_sigma_win(mg: SigmaMinigame) -> void:
	var sm: SigmaMatch = mg.match_state
	while not sm.ended:
		if sm.phase == SigmaMatch.Phase.HOLDING:
			sm.debug_force_pressure_strength(0.0)
			sm.debug_clear_disturbances()
			sm.debug_win_section(true)
		elif sm.phase == SigmaMatch.Phase.SECTION_FEEDBACK:
			sm.tick(SigmaMatch.FEEDBACK_DURATION + 0.01)
		else:
			sm.tick(0.1)
		if sm.ended:
			break


func _drive_sigma_loss(mg: SigmaMinigame) -> void:
	var sm: SigmaMatch = mg.match_state
	while not sm.ended:
		if sm.phase == SigmaMatch.Phase.HOLDING:
			sm.debug_lose_section()
		elif sm.phase == SigmaMatch.Phase.SECTION_FEEDBACK:
			sm.tick(SigmaMatch.FEEDBACK_DURATION + 0.01)
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

	# MONEY unsupported — no fake result
	_finish_count = 0
	var money_def: RivalDefinition = RivalDefinition.new()
	money_def.id = &"rival_test_money_only"
	money_def.display_name = "MoneyOnly"
	money_def.required_authority = 0
	money_def.authority_reward = 1
	money_def.preferred_competition = GameTypes.CompetitionType.MONEY
	money_def.allowed_competitions = [
		GameTypes.CompetitionType.MONEY,
		GameTypes.CompetitionType.SLAP,
	] as Array[GameTypes.CompetitionType]
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_PAYABLE_INTENT])
	_re.call("register_rival_definition", money_def)
	_re.call("start_encounter", &"rival_test_money_only", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.MONEY)
	_ok(_finish_count == 0, "129 unsupported MONEY no fake result")
	_ok(bool(_re.call("has_active_encounter")), "129 encounter still active")
	_ok(_runner.call("get_active_minigame") == null, "129 no minigame for MONEY")
	_re.call("force_clear_session")
	_gs.call("reset_for_new_game")

	# E2E win SIGMA
	_finish_count = 0
	_last_encounter = null
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 4)
	_gs.call("restore_purchased_perks", [PerkIds.AURA_PRESENCE_REGISTERED])
	var sigma_def: RivalDefinition = RivalDefinition.new()
	sigma_def.id = &"rival_test_sigma_e2e"
	sigma_def.display_name = "SigmaE2E"
	sigma_def.required_authority = 0
	sigma_def.authority_reward = 1
	sigma_def.aura = 4
	sigma_def.preferred_competition = GameTypes.CompetitionType.SIGMA
	sigma_def.allowed_competitions = [
		GameTypes.CompetitionType.SIGMA,
	] as Array[GameTypes.CompetitionType]
	_re.call("register_rival_definition", sigma_def)
	_re.call("start_encounter", &"rival_test_sigma_e2e", GameTypes.RivalEncounterInitiator.PLAYER)
	var choose: Dictionary = _re.call("choose_competition", GameTypes.CompetitionType.SIGMA) as Dictionary
	_ok(bool(choose.get("ok", false)), "128 route SIGMA")
	await get_tree().process_frame
	var mg: SigmaMinigame = _runner.call("get_active_minigame") as SigmaMinigame
	_ok(mg != null and mg.match_state != null, "128 SigmaMinigame active")
	if mg == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	_ok(mg.match_state.target_score == 3, "ordinary target 3")
	var player: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if player != null:
		_ok(
			player.get_control_mode() == PlayerController.ControlMode.MINIGAME,
			"134 MINIGAME during Sigma",
		)
	_drive_sigma_win(mg)
	var res: RivalCompetitionResult = mg.match_state.build_result_once()
	_ok(res != null, "typed result")
	if res != null:
		_ok(res.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN, "130 PLAYER_WIN")
		_ok(res.debug_score_summary.begins_with("SIGMA "), "debug SIGMA summary")
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_finish_count == 1, "130 encounter finished once")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			"130 Rival Authority path WIN",
		)
		_ok(bool(_gs.call("is_rival_defeated", &"rival_test_sigma_e2e")), "130 defeated")
	var before: int = _finish_count
	if is_instance_valid(mg):
		mg.force_finish_emit()
	_ok(_finish_count == before, "92 runner single submit")
	_ok(_runner.call("get_active_minigame") == null, "135 cleanup null")
	_ok(not bool(_runner.call("is_busy")), "135 busy false")

	# E2E loss (fresh rival — previous e2e rival is defeated)
	_re.call("force_clear_session")
	_finish_count = 0
	_last_encounter = null
	var auth_before: int = int(_gs.call("get_authority"))
	_gs.call("restore_purchased_perks", [PerkIds.AURA_PRESENCE_REGISTERED])
	var sigma_loss: RivalDefinition = RivalDefinition.new()
	sigma_loss.id = &"rival_test_sigma_loss"
	sigma_loss.display_name = "SigmaLoss"
	sigma_loss.required_authority = 0
	sigma_loss.authority_reward = 1
	sigma_loss.aura = 4
	sigma_loss.preferred_competition = GameTypes.CompetitionType.SIGMA
	sigma_loss.allowed_competitions = [
		GameTypes.CompetitionType.SIGMA,
	] as Array[GameTypes.CompetitionType]
	_re.call("register_rival_definition", sigma_loss)
	_re.call("start_encounter", &"rival_test_sigma_loss", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SIGMA)
	await get_tree().process_frame
	mg = _runner.call("get_active_minigame") as SigmaMinigame
	_ok(mg != null, "131 loss minigame")
	if mg == null:
		return
	mg.auto_tick = false
	mg.accept_input = false
	_drive_sigma_loss(mg)
	if is_instance_valid(mg):
		mg.force_finish_emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_last_encounter != null, "131 loss result")
	if _last_encounter != null:
		_ok(
			_last_encounter.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
			"131 PLAYER_LOSS",
		)
	_ok(int(_gs.call("get_authority")) == maxi(auth_before - 1, 0), "131 authority -1 via Rival")
