extends Node
## MODULE 06 Rival Encounter Framework self-test (spec §§82–107 + contamination).
## Run: res://game/rivals/test/rival_encounter_test.tscn --quit-after 5000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _re: Node = null
var _runner: RivalFakeCompetitionRunner = null
var _finish_count: int = 0
var _won_count: int = 0
var _lost_count: int = 0
var _request_count_via_signal: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_re = get_node("/root/RivalEncounters")
	await get_tree().process_frame
	_runner = RivalFakeCompetitionRunner.new()
	_runner.attach(_re)
	_re.connect("encounter_finished", _on_finished)
	_re.connect("encounter_won", _on_won)
	_re.connect("encounter_lost", _on_lost)
	_re.connect("competition_requested", _on_requested)
	_load_fixtures()
	_run_all()
	await _run_exhibition_tests()
	if _failed == 0:
		DfLog.info("MODULE_06_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_06_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_06_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_06_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_finished(_r: RivalEncounterResult) -> void:
	_finish_count += 1


func _on_won(_r: RivalEncounterResult) -> void:
	_won_count += 1


func _on_lost(_r: RivalEncounterResult) -> void:
	_lost_count += 1


func _on_requested(_r: RivalCompetitionRequest) -> void:
	_request_count_via_signal += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_06_TEST] FAIL: %s" % label)
		print("MODULE_06_TEST FAIL: %s" % label)


func _load_fixtures() -> void:
	_re.call("clear_rival_overrides")
	var paths: Array[String] = [
		"res://data/test/rival_test_low.tres",
		"res://data/test/rival_test_high.tres",
		"res://data/test/rival_test_story.tres",
		"res://data/test/rival_test_money.tres",
		"res://data/test/rival_test_sigma.tres",
		"res://data/test/rival_test_dance_money.tres",
		"res://data/test/rival_test_local.tres",
	]
	for p in paths:
		var def: RivalDefinition = load(p) as RivalDefinition
		_ok(def != null, "load fixture %s" % p)
		if def != null:
			_re.call("register_rival_definition", def)
	# Heroic / characteristic fixtures built in code
	var heroic: RivalDefinition = RivalDefinition.new()
	heroic.id = &"rival_test_heroic"
	heroic.display_name = "Heroic"
	heroic.required_authority = 0
	heroic.authority_reward = 1
	heroic.muscle = 5
	heroic.appearance = 3
	heroic.capital = 3
	heroic.aura = 3
	heroic.preferred_competition = GameTypes.CompetitionType.SLAP
	heroic.allowed_competitions = [
		GameTypes.CompetitionType.SLAP,
		GameTypes.CompetitionType.DANCE,
	] as Array[GameTypes.CompetitionType]
	_re.call("register_rival_definition", heroic)
	var dance_hard: RivalDefinition = RivalDefinition.new()
	dance_hard.id = &"rival_test_dance_hard"
	dance_hard.display_name = "Dance Hard"
	dance_hard.required_authority = 0
	dance_hard.authority_reward = 1
	dance_hard.muscle = 8
	dance_hard.appearance = 3
	dance_hard.capital = 3
	dance_hard.aura = 3
	dance_hard.preferred_competition = GameTypes.CompetitionType.DANCE
	dance_hard.allowed_competitions = [
		GameTypes.CompetitionType.SLAP,
		GameTypes.CompetitionType.DANCE,
	] as Array[GameTypes.CompetitionType]
	_re.call("register_rival_definition", dance_hard)


func _reset_run() -> void:
	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	_runner.reset_counts()
	_runner.auto_submit = true
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CLOSE,
	)


func _run_all() -> void:
	_test_player_initiates()
	_test_low_authority_refusal()
	_test_rival_initiates_bypass()
	_test_default_access()
	_test_capital_access()
	_test_aura_access()
	_test_intersection()
	_test_preferred_locked()
	_test_right_to_say_nothing()
	_test_no_override_without_perk()
	_test_she_already_started_no_rival_effect()
	_test_win()
	_test_crushing_win_same_reward()
	_test_repeat_defeat()
	_test_loss()
	_test_crushing_loss()
	_test_loss_at_zero()
	_test_ordinary_loss_still_minus_one()
	_test_story_loss_no_authority()
	_test_heroic_qualifies()
	_test_heroic_does_not_qualify()
	_test_heroic_relevant_characteristic()
	_test_local_significance_available()
	_test_local_significance_below()
	_test_local_significance_story()
	_test_local_significance_victory()
	_test_session_snapshot()
	_test_duplicate_result()
	_test_no_relationship_contamination()
	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	if _runner != null:
		_runner.restore_production_runner()


func _test_player_initiates() -> void:
	_reset_run()
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_low",
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "82 start player ok")
	var session: RivalEncounterSession = _re.call("get_active_session") as RivalEncounterSession
	_ok(session != null, "82 session exists")
	_ok(session.initiator == GameTypes.RivalEncounterInitiator.PLAYER, "82 initiator PLAYER")
	_ok(session.phase == GameTypes.RivalEncounterPhase.CHOOSING, "82 choosing")
	_ok(not session.has_chosen_competition, "82 player chooses later")


func _test_low_authority_refusal() -> void:
	_reset_run()
	_gs.call("add_authority", 2)
	var auth_before: int = int(_gs.call("get_authority"))
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	_ok(not bool(start.get("ok", true)), "83 refused")
	_ok(start.get("reason", &"") == _re.REASON_RIVAL_REFUSED_LOW_AUTHORITY, "83 reason")
	_ok(_re.call("get_active_session") == null or not bool(_re.call("has_active_encounter")), "83 no active")
	_ok(int(_gs.call("get_authority")) == auth_before, "83 auth unchanged")


func _test_rival_initiates_bypass() -> void:
	_reset_run()
	_gs.call("add_authority", 2)
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "84 rival start ok")
	var session: RivalEncounterSession = _re.call("get_active_session") as RivalEncounterSession
	_ok(session.initiator == GameTypes.RivalEncounterInitiator.RIVAL, "84 initiator RIVAL")
	_ok(session.has_chosen_competition, "84 preferred chosen")
	_ok(session.chosen_competition == GameTypes.CompetitionType.DANCE, "84 preferred DANCE")


func _test_default_access() -> void:
	_reset_run()
	var unlocked: Array = _re.call("get_unlocked_competitions") as Array
	_ok(unlocked.has(GameTypes.CompetitionType.SLAP), "85 SLAP")
	_ok(unlocked.has(GameTypes.CompetitionType.DANCE), "85 DANCE")
	_ok(not unlocked.has(GameTypes.CompetitionType.MONEY), "85 MONEY locked")
	_ok(not unlocked.has(GameTypes.CompetitionType.SIGMA), "85 SIGMA locked")


func _test_capital_access() -> void:
	_reset_run()
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_PAYABLE_INTENT])
	var unlocked: Array = _re.call("get_unlocked_competitions") as Array
	_ok(unlocked.has(GameTypes.CompetitionType.MONEY), "86 MONEY available")


func _test_aura_access() -> void:
	_reset_run()
	_gs.call("restore_purchased_perks", [PerkIds.AURA_PRESENCE_REGISTERED])
	var unlocked: Array = _re.call("get_unlocked_competitions") as Array
	_ok(unlocked.has(GameTypes.CompetitionType.SIGMA), "87 SIGMA available")


func _test_intersection() -> void:
	_reset_run()
	var available: Array = _re.call("get_available_competitions", &"rival_test_dance_money") as Array
	_ok(available.size() == 1, "88 size 1")
	_ok(available.has(GameTypes.CompetitionType.DANCE), "88 only DANCE")
	_ok(not available.has(GameTypes.CompetitionType.MONEY), "88 MONEY filtered")


func _test_preferred_locked() -> void:
	_reset_run()
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_money",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(not bool(start.get("ok", true)), "89 locked")
	_ok(start.get("reason", &"") == _re.REASON_COMPETITION_LOCKED, "89 COMPETITION_LOCKED")


func _test_right_to_say_nothing() -> void:
	_reset_run()
	_gs.call("restore_purchased_perks", [PerkIds.AURA_RIGHT_TO_SAY_NOTHING])
	_gs.call("add_authority", 5)
	var auth_before: int = int(_gs.call("get_authority"))
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_low",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "90 start")
	_ok(bool(_re.call("can_override_competition")), "90 can override")
	var keep: RivalEncounterSession = _re.call("get_active_session") as RivalEncounterSession
	_ok(keep.chosen_competition == GameTypes.CompetitionType.SLAP, "90 keep SLAP default")
	var ov: Dictionary = _re.call("override_competition", GameTypes.CompetitionType.DANCE) as Dictionary
	_ok(bool(ov.get("ok", false)), "90 override DANCE")
	_ok(keep.chosen_competition == GameTypes.CompetitionType.DANCE, "90 chosen DANCE")
	_ok(keep.override_used, "90 override_used")
	_ok(int(_gs.call("get_authority")) == auth_before, "90 no auth penalty")


func _test_no_override_without_perk() -> void:
	_reset_run()
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_low",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "91 start")
	_ok(not bool(_re.call("can_override_competition")), "91 cannot override")
	var ov: Dictionary = _re.call("override_competition", GameTypes.CompetitionType.DANCE) as Dictionary
	_ok(not bool(ov.get("ok", true)), "91 override rejected")
	var session: RivalEncounterSession = _re.call("get_active_session") as RivalEncounterSession
	_ok(session.chosen_competition == GameTypes.CompetitionType.SLAP, "91 remains SLAP")


func _test_she_already_started_no_rival_effect() -> void:
	# Static: RivalEncounters source must not reference SHE_ALREADY_STARTED.
	var src: String = FileAccess.get_file_as_string("res://game/rivals/rival_encounters.gd")
	_ok(not src.contains("SHE_ALREADY_STARTED"), "92 no SHE_ALREADY_STARTED in RivalEncounters")
	_ok(not src.contains("perk_aura_she_already_started"), "92 no she_already id in RivalEncounters")
	_reset_run()
	_gs.call("restore_purchased_perks", [PerkIds.AURA_SHE_ALREADY_STARTED])
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_low",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "92 start")
	_ok(not bool(_re.call("can_override_competition")), "92 she_already does not grant override")


func _test_win() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CLOSE,
	)
	# RIVAL initiator bypasses required_authority so before=4 matches spec §93.
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "93 start")
	var begin: Dictionary = _re.call("begin_competition") as Dictionary
	_ok(bool(begin.get("ok", false)), "93 begin+run")
	_ok(int(_gs.call("get_authority")) == 7, "93 authority 4+3=7")
	_ok(bool(_gs.call("is_rival_defeated", &"rival_test_high")), "93 defeated")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(result != null and result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN, "93 win")
	_ok(result.authority_delta == 3, "93 delta +3")


func _test_crushing_win_same_reward() -> void:
	_reset_run()
	_gs.call("add_authority", 5)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CRUSHING,
	)
	var start: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "94 start")
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 8, "94 crushing still +3")


func _test_repeat_defeat() -> void:
	# Continue from prior defeat of high, or re-win then retry
	_reset_run()
	_gs.call("add_authority", 5)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_high", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	var auth: int = int(_gs.call("get_authority"))
	var again: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	_ok(not bool(again.get("ok", true)), "95 blocked")
	_ok(again.get("reason", &"") == _re.REASON_ALREADY_DEFEATED, "95 ALREADY_DEFEATED")
	_ok(int(_gs.call("get_authority")) == auth, "95 auth unchanged")


func _test_loss() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 3, "96 auth 3")
	_ok(not bool(_gs.call("is_rival_defeated", &"rival_test_low")), "96 not defeated")


func _test_crushing_loss() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CRUSHING,
	)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 3, "97 crushing loss still -1")


func _test_loss_at_zero() -> void:
	_reset_run()
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 0, "98 still 0")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(result != null and result.authority_delta == 0, "98 delta 0")
	_ok(result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS, "98 still loss")


## MODULE 26 §68 — ordinary rival loss still −1 (floor 0 covered by §98).
func _test_ordinary_loss_still_minus_one() -> void:
	_reset_run()
	_gs.call("add_authority", 5)
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 4, "M26 ordinary loss 5→4")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(result != null and result.authority_delta == -1, "M26 ordinary loss delta -1")
	_ok(not bool(_gs.call("is_rival_defeated", &"rival_test_low")), "M26 ordinary loss not defeated")


## MODULE 26 §67 — Earth story rival loss: Authority unchanged, retry remains legal.
func _test_story_loss_no_authority() -> void:
	var story_specs: Array[Dictionary] = [
		{"id": &"rival_actress", "path": "res://data/content/rivals/rival_actress.tres", "required": 0},
		{"id": &"rival_mine_boss", "path": "res://data/content/rivals/rival_mine_boss.tres", "required": 2},
		{"id": &"rival_magazine_editor", "path": "res://data/content/rivals/rival_magazine_editor.tres", "required": 4},
		{"id": &"rival_scientist", "path": "res://data/content/rivals/rival_scientist.tres", "required": 7},
		{"id": &"rival_president", "path": "res://data/content/rivals/rival_president.tres", "required": 10},
	]
	for spec_v in story_specs:
		var spec: Dictionary = spec_v
		var rival_id: StringName = spec["id"] as StringName
		var path: String = str(spec["path"])
		var required: int = int(spec["required"])
		var def: RivalDefinition = load(path) as RivalDefinition
		_ok(def != null and def.is_story, "M26 story load %s" % String(rival_id))
		if def == null:
			continue
		_ok(def.required_authority == required, "M26 story required %s=%d" % [String(rival_id), required])
		_re.call("register_rival_definition", def)
		_reset_run()
		if required > 0:
			_gs.call("add_authority", required)
		var auth_before: int = int(_gs.call("get_authority"))
		_ok(auth_before == required, "M26 story auth set %s" % String(rival_id))
		_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
			GameTypes.VictoryGrade.CLOSE,
		)
		var available: Array = _re.call("get_available_competitions", rival_id) as Array
		_ok(not available.is_empty(), "M26 story has competition %s" % String(rival_id))
		if available.is_empty():
			continue
		var ctype: GameTypes.CompetitionType = available[0] as GameTypes.CompetitionType
		var start: Dictionary = _re.call(
			"start_encounter",
			rival_id,
			GameTypes.RivalEncounterInitiator.PLAYER,
		) as Dictionary
		_ok(bool(start.get("ok", false)), "M26 story start %s" % String(rival_id))
		var choose: Dictionary = _re.call("choose_competition", ctype) as Dictionary
		_ok(bool(choose.get("ok", false)), "M26 story force loss %s" % String(rival_id))
		_ok(int(_gs.call("get_authority")) == auth_before, "M26 story auth unchanged %s" % String(rival_id))
		_ok(not bool(_gs.call("is_rival_defeated", rival_id)), "M26 story not defeated %s" % String(rival_id))
		var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
		_ok(result != null and result.authority_delta == 0, "M26 story delta 0 %s" % String(rival_id))
		_ok(result != null and not result.heroic_defeat_triggered, "M26 story not heroic %s" % String(rival_id))
		_re.call("force_clear_session")
		var can: Dictionary = _re.call("can_challenge", rival_id) as Dictionary
		_ok(bool(can.get("ok", false)), "M26 story retry legal %s" % String(rival_id))
		var retry: Dictionary = _re.call(
			"start_encounter",
			rival_id,
			GameTypes.RivalEncounterInitiator.PLAYER,
		) as Dictionary
		_ok(bool(retry.get("ok", false)), "M26 story retry start %s" % String(rival_id))
		_re.call("force_clear_session")


func _test_heroic_qualifies() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 3)
	_gs.call("restore_purchased_perks", [PerkIds.MUSCLE_HEROIC_DEFEAT])
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_heroic", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 4, "99 auth unchanged")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(result.heroic_defeat_triggered, "99 heroic true")


func _test_heroic_does_not_qualify() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 4)
	_gs.call("restore_purchased_perks", [PerkIds.MUSCLE_HEROIC_DEFEAT])
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_heroic", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_authority")) == 3, "100 auth -1")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(not result.heroic_defeat_triggered, "100 heroic false")


func _test_heroic_relevant_characteristic() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 1)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 3)
	_gs.call("restore_purchased_perks", [PerkIds.MUSCLE_HEROIC_DEFEAT])
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
		GameTypes.VictoryGrade.CLOSE,
	)
	# rival muscle 8 but DANCE compares appearance 3 vs player 3 — not >= +2
	_re.call("start_encounter", &"rival_test_dance_hard", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.DANCE)
	_ok(int(_gs.call("get_authority")) == 3, "101 uses appearance not muscle")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(not result.heroic_defeat_triggered, "101 not heroic on equal appearance")


func _test_local_significance_available() -> void:
	_reset_run()
	_gs.call("add_authority", 5)
	_gs.call("restore_purchased_perks", [PerkIds.AURA_LOCAL_SIGNIFICANCE])
	_re.call("start_encounter", &"rival_test_local", GameTypes.RivalEncounterInitiator.PLAYER)
	_ok(bool(_re.call("can_use_local_significance")), "102 concession available")


func _test_local_significance_below() -> void:
	_reset_run()
	_gs.call("add_authority", 4)
	_gs.call("restore_purchased_perks", [PerkIds.AURA_LOCAL_SIGNIFICANCE])
	_re.call("start_encounter", &"rival_test_local", GameTypes.RivalEncounterInitiator.PLAYER)
	_ok(not bool(_re.call("can_use_local_significance")), "103 below margin")


func _test_local_significance_story() -> void:
	_reset_run()
	_gs.call("add_authority", 100)
	_gs.call("restore_purchased_perks", [PerkIds.AURA_LOCAL_SIGNIFICANCE])
	_re.call("start_encounter", &"rival_test_story", GameTypes.RivalEncounterInitiator.PLAYER)
	_ok(not bool(_re.call("can_use_local_significance")), "104 story immune")


func _test_local_significance_victory() -> void:
	_reset_run()
	_gs.call("add_authority", 5)
	_gs.call("restore_purchased_perks", [PerkIds.AURA_LOCAL_SIGNIFICANCE])
	_runner.reset_counts()
	var req_before: int = _request_count_via_signal
	_re.call("start_encounter", &"rival_test_local", GameTypes.RivalEncounterInitiator.PLAYER)
	var used: Dictionary = _re.call("use_local_significance") as Dictionary
	_ok(bool(used.get("ok", false)), "105 concession ok")
	_ok(_request_count_via_signal == req_before, "105 no minigame request")
	_ok(_runner.request_count == 0, "105 fake runner unused")
	_ok(bool(_gs.call("is_rival_defeated", &"rival_test_local")), "105 defeated")
	_ok(int(_gs.call("get_authority")) == 7, "105 +2 reward")
	var result: RivalEncounterResult = _re.call("get_last_result") as RivalEncounterResult
	_ok(result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN, "105 WIN")
	_ok(result.victory_grade == GameTypes.VictoryGrade.CRUSHING, "105 CRUSHING")
	_ok(result.concession_used, "105 concession_used")


func _test_session_snapshot() -> void:
	_reset_run()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 3)
	_runner.auto_submit = false
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	var session: RivalEncounterSession = _re.call("get_active_session") as RivalEncounterSession
	_ok(session.player_characteristic_level == 3, "106 snap 3")
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 4)
	_ok(session.player_characteristic_level == 3, "106 stays 3 after mutate")
	_ok(_runner.last_request != null and _runner.last_request.player_level == 3, "106 request uses 3")
	# finish cleanly
	_runner.auto_submit = true
	var result: RivalCompetitionResult = RivalCompetitionResult.new()
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	result.victory_grade = GameTypes.VictoryGrade.CLOSE
	_re.call("submit_competition_result", result)


func _test_duplicate_result() -> void:
	_reset_run()
	_gs.call("add_authority", 2)
	_runner.auto_submit = false
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	var result: RivalCompetitionResult = RivalCompetitionResult.new()
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	result.victory_grade = GameTypes.VictoryGrade.CLOSE
	var finish_before: int = _finish_count
	var first: Dictionary = _re.call("submit_competition_result", result) as Dictionary
	_ok(bool(first.get("ok", false)), "107 first submit")
	var auth: int = int(_gs.call("get_authority"))
	var second: Dictionary = _re.call("submit_competition_result", result) as Dictionary
	_ok(not bool(second.get("ok", true)), "107 second rejected")
	_ok(second.get("reason", &"") == _re.REASON_ALREADY_FINISHED, "107 ALREADY_FINISHED")
	_ok(int(_gs.call("get_authority")) == auth, "107 no second reward")
	_ok(_finish_count == finish_before + 1, "107 one finish signal")


func _test_no_relationship_contamination() -> void:
	_reset_run()
	var gid: StringName = &"girl_contam"
	_gs.call("set_girl_relationship", gid, 2)
	_gs.call("add_experience", 3)
	var xp: int = int(_gs.call("get_experience"))
	var up: int = int(_gs.call("get_upgrade_points"))
	var rel: int = int(_gs.call("get_girl_relationship", gid))
	_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CLOSE,
	)
	_re.call("start_encounter", &"rival_test_low", GameTypes.RivalEncounterInitiator.PLAYER)
	_re.call("choose_competition", GameTypes.CompetitionType.SLAP)
	_ok(int(_gs.call("get_girl_relationship", gid)) == rel, "113 rel unchanged")
	_ok(int(_gs.call("get_experience")) == xp, "113 xp unchanged")
	_ok(int(_gs.call("get_upgrade_points")) == up, "113 up unchanged")
	var src: String = FileAccess.get_file_as_string("res://game/rivals/rival_encounters.gd")
	_ok(not src.contains("girl_relationship"), "113 no girl_relationship API")
	_ok(not src.contains("add_experience"), "113 no add_experience")


func _make_exhibition_def(rival_id: StringName, competition: GameTypes.CompetitionType) -> RivalDefinition:
	var def: RivalDefinition = RivalDefinition.new()
	def.id = rival_id
	def.display_name = "Exhibition"
	def.is_story = false
	def.required_authority = 0
	def.authority_reward = 99
	def.muscle = 3
	def.appearance = 3
	def.capital = 3
	def.aura = 3
	def.preferred_competition = competition
	def.allowed_competitions = [competition] as Array[GameTypes.CompetitionType]
	return def


func _make_exhibition_request(
	rival_id: StringName,
	competition: GameTypes.CompetitionType,
) -> RivalCompetitionRequest:
	var request: RivalCompetitionRequest = RivalCompetitionRequest.new()
	request.rival_id = rival_id
	request.competition_type = competition
	request.player_level = 3
	request.rival_level = 3
	request.initiator = GameTypes.RivalEncounterInitiator.RIVAL
	request.context = GameTypes.RivalEncounterContext.WORLD
	return request


func _run_exhibition_tests() -> void:
	# MODULE 21 §§13–16 / §111 — exhibition seam must not mutate Rival persistence.
	if _runner != null:
		_runner.restore_production_runner()
	var production: Node = get_node_or_null("/root/RivalCompetitionRunner")
	_ok(production != null, "M21 exhibition runner present")
	if production == null:
		return
	_ok(production.has_method("run_exhibition_competition"), "M21 run_exhibition_competition API")

	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	_gs.call("add_authority", 5)
	var auth_before: int = int(_gs.call("get_authority"))
	var finish_before: int = _finish_count
	var won_before: int = _won_count
	var lost_before: int = _lost_count

	var def_win: RivalDefinition = _make_exhibition_def(
		&"rival_exhibition_win",
		GameTypes.CompetitionType.SLAP,
	)
	var req_win: RivalCompetitionRequest = _make_exhibition_request(
		def_win.id,
		GameTypes.CompetitionType.SLAP,
	)
	var got_win: Array = []
	var cb_win: Callable = func(result: RivalCompetitionResult) -> void:
		got_win.append(result)
	var started_win: bool = bool(
		production.call("run_exhibition_competition", req_win, def_win, cb_win)
	)
	_ok(started_win, "M21 exhibition SLAP win started")
	_ok(bool(production.call("is_busy")), "M21 exhibition busy while active")
	var mg_win: CanvasLayer = production.call("get_active_minigame") as CanvasLayer
	_ok(mg_win is SlapMinigame, "M21 exhibition launches SlapMinigame")
	if mg_win != null:
		mg_win.set("auto_tick", false)
		mg_win.set("accept_input", false)
		var win_result: RivalCompetitionResult = RivalCompetitionResult.new()
		win_result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
		win_result.victory_grade = GameTypes.VictoryGrade.CLOSE
		win_result.debug_score_summary = "exhibition_win_test"
		mg_win.emit_signal("match_finished", win_result)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(got_win.size() == 1, "M21 exhibition win callback once")
	if got_win.size() == 1:
		var wr: RivalCompetitionResult = got_win[0] as RivalCompetitionResult
		_ok(
			wr != null and wr.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			"M21 exhibition callback PLAYER_WIN",
		)
	_ok(int(_gs.call("get_authority")) == auth_before, "M21 exhibition win auth unchanged")
	_ok(
		not bool(_gs.call("is_rival_defeated", &"rival_exhibition_win")),
		"M21 exhibition win not defeated",
	)
	_ok(_finish_count == finish_before, "M21 exhibition win no encounter_finished")
	_ok(_won_count == won_before, "M21 exhibition win no encounter_won")
	_ok(not bool(production.call("is_busy")), "M21 exhibition win runner idle")
	_ok(production.call("get_active_minigame") == null, "M21 exhibition win cleaned up")

	auth_before = int(_gs.call("get_authority"))
	finish_before = _finish_count
	lost_before = _lost_count
	var def_loss: RivalDefinition = _make_exhibition_def(
		&"rival_exhibition_loss",
		GameTypes.CompetitionType.DANCE,
	)
	var req_loss: RivalCompetitionRequest = _make_exhibition_request(
		def_loss.id,
		GameTypes.CompetitionType.DANCE,
	)
	var got_loss: Array = []
	var cb_loss: Callable = func(result: RivalCompetitionResult) -> void:
		got_loss.append(result)
	var started_loss: bool = bool(
		production.call("run_exhibition_competition", req_loss, def_loss, cb_loss)
	)
	_ok(started_loss, "M21 exhibition DANCE loss started")
	var mg_loss: CanvasLayer = production.call("get_active_minigame") as CanvasLayer
	_ok(mg_loss is DanceMinigame, "M21 exhibition launches DanceMinigame")
	if mg_loss != null:
		mg_loss.set("auto_tick", false)
		mg_loss.set("accept_input", false)
		var loss_result: RivalCompetitionResult = RivalCompetitionResult.new()
		loss_result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		loss_result.victory_grade = GameTypes.VictoryGrade.CLOSE
		loss_result.debug_score_summary = "exhibition_loss_test"
		mg_loss.emit_signal("match_finished", loss_result)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(got_loss.size() == 1, "M21 exhibition loss callback once")
	if got_loss.size() == 1:
		var lr: RivalCompetitionResult = got_loss[0] as RivalCompetitionResult
		_ok(
			lr != null and lr.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS,
			"M21 exhibition callback PLAYER_LOSS",
		)
	_ok(int(_gs.call("get_authority")) == auth_before, "M21 exhibition loss auth unchanged")
	_ok(
		not bool(_gs.call("is_rival_defeated", &"rival_exhibition_loss")),
		"M21 exhibition loss not defeated",
	)
	_ok(_finish_count == finish_before, "M21 exhibition loss no encounter_finished")
	_ok(_lost_count == lost_before, "M21 exhibition loss no encounter_lost")

	var def_money: RivalDefinition = _make_exhibition_def(
		&"rival_exhibition_money",
		GameTypes.CompetitionType.MONEY,
	)
	var req_money: RivalCompetitionRequest = _make_exhibition_request(
		def_money.id,
		GameTypes.CompetitionType.MONEY,
	)
	var rejected: bool = bool(
		production.call(
			"run_exhibition_competition",
			req_money,
			def_money,
			func(_r: RivalCompetitionResult) -> void: pass,
		)
	)
	_ok(not rejected, "M21 exhibition rejects MONEY")
	_ok(not bool(production.call("is_busy")), "M21 exhibition idle after reject")

	if _runner != null:
		_runner.attach(_re)
		_runner.reset_counts()
		_runner.auto_submit = true
		_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)
	_gs.call("reset_for_new_game")
	_re.call("force_clear_session")
	_gs.call("add_authority", 4)
	var start_normal: Dictionary = _re.call(
		"start_encounter",
		&"rival_test_high",
		GameTypes.RivalEncounterInitiator.RIVAL,
	) as Dictionary
	_ok(bool(start_normal.get("ok", false)), "M21 normal after exhibition start")
	var begin_normal: Dictionary = _re.call("begin_competition") as Dictionary
	_ok(bool(begin_normal.get("ok", false)), "M21 normal after exhibition begin")
	_ok(int(_gs.call("get_authority")) == 7, "M21 normal after exhibition authority +3")
	_ok(bool(_gs.call("is_rival_defeated", &"rival_test_high")), "M21 normal after exhibition defeated")
	if _runner != null:
		_runner.restore_production_runner()
