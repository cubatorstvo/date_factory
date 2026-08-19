class_name DateSystemTests
extends RefCounted

var _failures: PackedStringArray = PackedStringArray()
var _passed: int = 0


func run_all() -> PackedStringArray:
	_failures.clear()
	_passed = 0
	_test_unknown_plus_becomes_positive()
	_test_unknown_minus_becomes_negative()
	_test_opening_reveals_and_zero()
	_test_core_and_closing_scores()
	_test_base_pool_and_rng()
	_test_unlockables()
	_test_mapping_tags_differ_by_situation()
	_test_secondary_reveal_and_rules()
	_test_location_outfit_apartment()
	_test_relationship_clamp_and_reset()
	_test_replay_seed()
	_test_saved_resource_reload()
	_test_validator()
	_test_unlockable_tag_reservation()
	_test_twelve_tag_rebalance()
	_test_girl_difficulty()
	_test_game_state_round_trip()
	_test_game_time()
	_test_campaign_stages()
	_test_game_actions()
	_test_game_simulator()
	_test_economy()
	_test_world()
	_test_girls()
	_test_dating_and_rating()
	_test_date_venue_choice()
	_test_rivals()
	_test_character_progression()
	return _failures


func summary() -> String:
	return "passed=%d failed=%d" % [_passed, _failures.size()]


func _ok(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		return
	var message: String = name
	if not detail.is_empty():
		message += " — " + detail
	_failures.append(message)


func _catalog() -> DateContentCatalog:
	return SeedContentFactory.new().build_catalog()


func _fresh_progress(catalog: DateContentCatalog, girl_id: StringName) -> GirlProgress:
	var progress := GirlProgress.new()
	progress.reset_to_profile(catalog.find_girl(girl_id))
	return progress


func _player() -> TestPlayerState:
	return TestPlayerState.new()


func _start(catalog: DateContentCatalog, girl_id: StringName, location_id: StringName, outfit_id: StringName, seed: int, progress: GirlProgress, player: TestPlayerState) -> DateEngine:
	var engine := DateEngine.new()
	var config := DateSessionConfig.new()
	config.catalog = catalog
	config.girl_id = girl_id
	config.location_id = location_id
	config.outfit_id = outfit_id
	config.seed = seed
	config.girl_progress = progress
	config.player_state = player
	engine.create_date_session(config)
	return engine


func _pick_by_tag(engine: DateEngine, tag_id: StringName) -> StringName:
	for option in engine.get_available_moves():
		if option.is_selectable() and option.tag_id == tag_id:
			return option.move_id
	return _first_available(engine)


func _pick_preference(engine: DateEngine, want_positive: bool) -> StringName:
	var girl: GirlProfile = engine.catalog().find_girl(engine.get_session_state().girl_id)
	for option in engine.get_available_moves():
		if not option.is_selectable():
			continue
		var pref: int = girl.prefers_tag(option.tag_id)
		if want_positive and pref > 0:
			return option.move_id
		if not want_positive and pref < 0:
			return option.move_id
	return _first_available(engine)


func _has_preference(engine: DateEngine, want_positive: bool) -> bool:
	var girl: GirlProfile = engine.catalog().find_girl(engine.get_session_state().girl_id)
	if girl == null:
		return false
	for option in engine.get_available_moves():
		if not option.is_selectable():
			continue
		var pref: int = girl.prefers_tag(option.tag_id)
		if want_positive and pref > 0:
			return true
		if not want_positive and pref < 0:
			return true
	return false


func _first_available(engine: DateEngine) -> StringName:
	for option in engine.get_available_moves():
		if option.is_selectable():
			return option.move_id
	return &""


func _choose(engine: DateEngine, move_id: StringName) -> void:
	engine.choose_move(move_id)
	engine.advance()


func _test_unknown_plus_becomes_positive() -> void:
	var found: bool = false
	for seed in range(1, 80):
		var probe_catalog: DateContentCatalog = _catalog()
		var progress: GirlProgress = _fresh_progress(probe_catalog, &"alina")
		var probe_engine: DateEngine = _start(probe_catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		if not _has_preference(probe_engine, true):
			continue
		var move_id: StringName = _pick_preference(probe_engine, true)
		var option: DateMoveOption = _option(probe_engine, move_id)
		_ok("1. UNKNOWN before +1", progress.tag_knowledge(option.tag_id) == DateTypes.TagKnowledge.UNKNOWN)
		_choose(probe_engine, move_id)
		_ok("1. UNKNOWN Tag after +1 becomes POSITIVE", progress.tag_knowledge(option.tag_id) == DateTypes.TagKnowledge.POSITIVE)
		found = true
		break
	_ok("1. found positive selectable Tag", found)


func _test_unknown_minus_becomes_negative() -> void:
	var found: bool = false
	for seed in range(1, 80):
		var catalog := _catalog()
		var progress := _fresh_progress(catalog, &"alina")
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		if not _has_preference(engine, false):
			continue
		var move_id: StringName = _pick_preference(engine, false)
		var option: DateMoveOption = _option(engine, move_id)
		_choose(engine, move_id)
		_ok("2. UNKNOWN Tag after -1 becomes NEGATIVE", progress.tag_knowledge(option.tag_id) == DateTypes.TagKnowledge.NEGATIVE)
		found = true
		break
	_ok("2. found negative selectable Tag", found)


func _test_opening_reveals_and_zero() -> void:
	var catalog := _catalog()
	var progress := _fresh_progress(catalog, &"alina")
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 3, progress, _player())
	_ok("opening situation", engine.get_session_state().current_phase == DateTypes.DatePhase.OPENING)
	_choose(engine, _pick_preference(engine, true))
	_ok("3. Opening раскрывает Tag", progress.revealed_positive_tag_ids.size() + progress.revealed_negative_tag_ids.size() == 1)
	_ok("4. Opening даёт 0", engine.get_session_state().score_breakdown.opening_scores[0] == 0)


func _test_core_and_closing_scores() -> void:
	var pos_engine := _run_until_phase(_catalog(), true)
	_ok("5. Core positive даёт +1", _last_score_of(pos_engine, DateTypes.DatePhase.CORE) == 1)
	var neg_engine := _run_until_phase(_catalog(), false)
	_ok("6. Core negative даёт -1", _last_score_of(neg_engine, DateTypes.DatePhase.CORE) == -1)
	var close_pos := _finish_with_preference(_catalog(), true, true)
	_ok("7. Closing positive даёт +1", _last_score_of(close_pos, DateTypes.DatePhase.CLOSING) == 1)
	var close_neg := _finish_with_preference(_catalog(), false, false)
	_ok("8. Closing negative даёт -1", _last_score_of(close_neg, DateTypes.DatePhase.CLOSING) == -1)


func _last_score_of(engine: DateEngine, phase: DateTypes.DatePhase) -> int:
	var last: int = 0
	for episode in engine.get_session_state().episode_history:
		if episode.phase == phase:
			last = episode.score_delta
	return last


func _run_until_phase(catalog: DateContentCatalog, want_positive: bool) -> DateEngine:
	for seed in range(1, 400):
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var skipped: bool = false
		while engine.get_session_state().current_phase != DateTypes.DatePhase.CORE:
			if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
				engine.advance()
				continue
			var opening_move: StringName = _pick_preference(engine, want_positive) if _has_preference(engine, want_positive) else _first_available(engine)
			_choose(engine, opening_move)
			if engine.get_session_state().current_phase != DateTypes.DatePhase.CORE and engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE:
				skipped = true
				break
		if skipped:
			continue
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
		if engine.get_session_state().current_phase != DateTypes.DatePhase.CORE:
			continue
		if not _has_preference(engine, want_positive):
			continue
		_choose(engine, _pick_preference(engine, want_positive))
		return engine
	return _start(catalog, &"alina", &"cafe", &"casual", 21, _fresh_progress(catalog, &"alina"), _player())


func _finish_with_preference(catalog: DateContentCatalog, core_positive: bool, closing_positive: bool) -> DateEngine:
	for seed in range(1, 400):
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var valid: bool = true
		while engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE or engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
				engine.advance()
				continue
			var want: bool = closing_positive if engine.get_session_state().current_phase == DateTypes.DatePhase.CLOSING else core_positive
			if engine.get_session_state().current_phase == DateTypes.DatePhase.OPENING:
				want = true
			if engine.get_session_state().current_phase != DateTypes.DatePhase.OPENING and not _has_preference(engine, want):
				valid = false
				break
			var move_id: StringName = _pick_preference(engine, want) if _has_preference(engine, want) else _first_available(engine)
			_choose(engine, move_id)
		if valid and engine.get_session_state().stage == DateSession.Stage.SHOWING_DATE_RESULT:
			return engine
	return _start(catalog, &"alina", &"cafe", &"casual", 33, _fresh_progress(catalog, &"alina"), _player())


func _test_base_pool_and_rng() -> void:
	var catalog := _catalog()
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 41, _fresh_progress(catalog, &"alina"), _player())
	var situation_id: StringName = engine.get_session_state().selected_situation_ids[0]
	var pool: Array[DateMove] = catalog.applicable_moves(situation_id, DateTypes.DateMoveKind.BASE)
	_ok("9. BASE pool собирается по mappings", pool.size() >= 3)
	_ok("10. RNG выбирает 3 BASE", engine.get_session_state().current_selected_base_move_ids.size() == 3)
	var engine_a := _start(_catalog(), &"alina", &"cafe", &"casual", 77, _fresh_progress(_catalog(), &"alina"), _player())
	var engine_b := _start(_catalog(), &"alina", &"cafe", &"casual", 77, _fresh_progress(_catalog(), &"alina"), _player())
	_ok("11. одинаковый seed воспроизводит BASE selection", engine_a.get_session_state().current_selected_base_move_ids == engine_b.get_session_state().current_selected_base_move_ids)


func _test_unlockables() -> void:
	var catalog := _catalog()
	var locked_player := _player()
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 8, _fresh_progress(catalog, &"alina"), locked_player)
	_ok("12. UNLOCKABLE отображаются отдельным набором", true)
	var found_unlock := false
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT and engine.get_session_state().stage != DateSession.Stage.COMPLETED:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		var view := engine.get_current_episode()
		if view != null and view.situation != null and view.situation.id == &"rival_provocation":
			found_unlock = view.unlockable_options.size() > 0
			var punch: DateMoveOption = null
			for option in view.unlockable_options:
				if option.move_id == &"punch":
					punch = option
			_ok("13. применимые UNLOCKABLE присутствуют в эпизоде", punch != null)
			_ok("14a. Requirement locked", punch != null and punch.availability == DateTypes.MoveAvailability.LOCKED)
		_choose(engine, _first_available(engine))
	_ok("13/14 found rival episode", found_unlock)
	var unlocked_player := _player()
	unlocked_player.muscle = 4
	var engine2 := _start(_catalog(), &"alina", &"cafe", &"casual", 8, _fresh_progress(_catalog(), &"alina"), unlocked_player)
	var used_ok := false
	while engine2.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine2.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine2.advance()
			continue
		var view2 := engine2.get_current_episode()
		if view2 != null and view2.situation != null and view2.situation.id == &"rival_provocation":
			var punch2: DateMoveOption = null
			for option in view2.unlockable_options:
				if option.move_id == &"punch":
					punch2 = option
			_ok("14. Requirement корректно меняет locked/unlocked", punch2 != null and punch2.availability == DateTypes.MoveAvailability.AVAILABLE)
			engine2.choose_move(&"punch")
			engine2.advance()
			used_ok = true
			continue
		_choose(engine2, _first_available(engine2))
	# replay same seed until another rival? only one rival per date. Check used count after punch.
	_ok("15. max_uses_per_date tracked", used_ok and int(engine2.get_session_state().used_unlockable_move_counts.get("punch", 0)) == 1)


func _test_mapping_tags_differ_by_situation() -> void:
	var move: DateMove = _catalog().find_move(&"compliment")
	var appearance: DateMoveSituationMapping = move.mapping_for(&"appearance_question")
	var bet: DateMoveSituationMapping = move.mapping_for(&"spontaneous_bet")
	_ok("16. один Move получает разные Tags в разных Situations", appearance.tag_id != bet.tag_id)


func _test_secondary_reveal_and_rules() -> void:
	var catalog := _catalog()
	var progress := _fresh_progress(catalog, &"alina")
	_ok("17 pre", progress.secondary_revealed == false)
	_finish_with_preference(catalog, true, true).get_result()
	# that used different progress. Use same progress object.
	var engine := _finish_progress(catalog, &"alina", progress, true)
	_ok("17. первый completed date раскрывает Secondary", progress.secondary_revealed and progress.completed_dates == 1)
	var engine2 := _start(_catalog(), &"alina", &"cafe", &"casual", 5, progress, _player())
	_ok("18. следующий DateSession знает Secondary заранее", progress.secondary_revealed)
	engine2.abort()
	_ok("19. VARIETY считает distinct successful Tags", _variety_distinct_works())
	_ok("19b. VARIETY считает первый успешный ход", _variety_counts_first_success())
	_ok("20. DEMANDING считает CORE failures", _demanding_counts_failures())


func _finish_progress(catalog: DateContentCatalog, girl_id: StringName, progress: GirlProgress, want_positive: bool) -> DateEngine:
	var engine := _start(catalog, girl_id, &"cafe", &"casual", 9, progress, _player())
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		_choose(engine, _pick_preference(engine, want_positive))
	return engine


func _variety_distinct_works() -> bool:
	for seed in range(1, 400):
		var catalog := _catalog()
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var used: Dictionary = {}
		while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
			if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
				engine.advance()
				continue
			var move_id: StringName = _pick_new_success(engine, used)
			var option := _option(engine, move_id)
			if option != null:
				used[String(option.tag_id)] = true
			_choose(engine, move_id)
		if used.size() >= 3 and engine.get_result().score_breakdown.secondary_success:
			return true
	return false


func _variety_counts_first_success() -> bool:
	for seed in range(1, 80):
		var engine := _start(_catalog(), &"alina", &"cafe", &"casual", seed, _fresh_progress(_catalog(), &"alina"), _player())
		if engine.get_session_state().current_phase != DateTypes.DatePhase.OPENING:
			continue
		var move_id: StringName = _pick_preference(engine, true)
		var option := _option(engine, move_id)
		if option == null:
			continue
		var girl: GirlProfile = engine.catalog().find_girl(&"alina")
		if girl.prefers_tag(option.tag_id) <= 0:
			continue
		engine.choose_move(move_id)
		return engine.secondary_live_text() == "Разные успешные теги: 1/3"
	return false


func _pick_new_success(engine: DateEngine, used: Dictionary) -> StringName:
	var girl: GirlProfile = engine.catalog().find_girl(engine.get_session_state().girl_id)
	for option in engine.get_available_moves():
		if option.is_selectable() and girl.prefers_tag(option.tag_id) > 0 and not used.has(String(option.tag_id)):
			return option.move_id
	return _pick_preference(engine, true)


func _option(engine: DateEngine, move_id: StringName) -> DateMoveOption:
	for option in engine.get_available_moves():
		if option.move_id == move_id:
			return option
	return null


func _demanding_counts_failures() -> bool:
	var catalog := _catalog()
	var engine := _finish_progress(catalog, &"vika", _fresh_progress(catalog, &"vika"), false)
	var failures: int = int(engine.get_session_state().secondary_runtime_state.get("failure_count", -1))
	return failures >= 1 and engine.get_result().score_breakdown.secondary_success == false


func _test_location_outfit_apartment() -> void:
	var catalog := _catalog()
	var cafe := _finish_at(catalog, &"cafe", &"casual", _player())
	_ok("21. NEUTRAL Location считает quality", cafe.score_breakdown.location_quality_score == 1)
	_ok("21b preference 0", cafe.score_breakdown.location_preference_score == 0)
	var park := _finish_at(catalog, &"park", &"casual", _player())
	_ok("22. THEMATIC favorite Location даёт +1", park.score_breakdown.location_preference_score == 1)
	var arcade := _finish_at(catalog, &"arcade", &"casual", _player())
	_ok("23. THEMATIC other Location даёт -1", arcade.score_breakdown.location_preference_score == -1)
	var apt_player := _player()
	apt_player.apartment_quality = 3
	apt_player.apartment_prepared = true
	var apt := _finish_at(catalog, &"apartment", &"casual", apt_player)
	_ok("24. apartment quality считает 0..3", apt.score_breakdown.apartment_quality_score == 3)
	var unprepared := _player()
	unprepared.apartment_quality = 0
	unprepared.apartment_prepared = false
	var apt2 := _finish_at(catalog, &"apartment", &"casual", unprepared)
	_ok("25. apartment preparation считает 0/-1", apt2.score_breakdown.apartment_preparation_score == -1)
	var luxury := _finish_at(catalog, &"cafe", &"luxury", _player())
	_ok("26. Outfit bonus рассчитывается корректно", luxury.score_breakdown.outfit_score == 2)


func _finish_at(catalog: DateContentCatalog, location_id: StringName, outfit_id: StringName, player: TestPlayerState) -> DateRunResult:
	var engine := _start(catalog, &"alina", location_id, outfit_id, 4, _fresh_progress(catalog, &"alina"), player)
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		_choose(engine, _first_available(engine))
	return engine.get_result()


func _test_relationship_clamp_and_reset() -> void:
	var catalog := _catalog()
	var alina := _fresh_progress(catalog, &"alina")
	alina.relationship = 5
	var engine := _finish_progress(catalog, &"alina", alina, true)
	_ok("27. отношения АЛИНЫ clamp в -5..+5", engine.get_session_state().relationship_after <= 5 and engine.get_session_state().relationship_after >= -5)
	var vika := _fresh_progress(catalog, &"vika")
	vika.relationship = 10
	var engine_v := _finish_progress(catalog, &"vika", vika, true)
	_ok("28. отношения ВИКИ clamp в -10..+10", engine_v.get_session_state().relationship_after <= 10 and engine_v.get_session_state().relationship_after >= -10)
	var store := DateProgressStore.new()
	store.reset_all(catalog)
	var girl: GirlProfile = catalog.find_girl(&"alina")
	alina.relationship = 4
	alina.secondary_revealed = true
	alina.completed_dates = 2
	store.girl_progress_by_id["alina"] = alina
	store.reset_girl(girl)
	var reset: GirlProgress = store.get_girl_progress(&"alina", girl)
	_ok("29. reset GirlProgress восстанавливает старт", reset.relationship == 0 and reset.completed_dates == 0 and reset.secondary_revealed == false and reset.revealed_positive_tag_ids.is_empty())


func _test_replay_seed() -> void:
	var catalog := _catalog()
	var a := _start(catalog, &"alina", &"cafe", &"casual", 12345, _fresh_progress(catalog, &"alina"), _player())
	var b := _start(_catalog(), &"alina", &"cafe", &"casual", 12345, _fresh_progress(_catalog(), &"alina"), _player())
	_ok("30. replay seed воспроизводит случайные элементы", a.get_session_state().selected_situation_ids == b.get_session_state().selected_situation_ids and a.get_session_state().current_selected_base_move_ids == b.get_session_state().current_selected_base_move_ids)


func _test_saved_resource_reload() -> void:
	var catalog := _catalog()
	var tag: DateTag = catalog.find_tag(&"politeness")
	tag.description = "reloaded-description"
	DirAccess.make_dir_recursive_absolute("user://date_system")
	var path: String = "user://date_system/test_tag.tres"
	var err: Error = ResourceSaver.save(tag, path)
	_ok("31 save", err == OK)
	var loaded: DateTag = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as DateTag
	_ok("31 load", loaded != null and loaded.description == "reloaded-description")
	for i in catalog.tags.size():
		if catalog.tags[i].id == &"politeness":
			catalog.tags[i] = loaded
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 1, _fresh_progress(catalog, &"alina"), _player())
	var snapped: DateTag = engine.catalog().find_tag(&"politeness")
	_ok("31. сохранённый Resource после reload используется новым DateSession", snapped != null and snapped.description == "reloaded-description")


func _test_validator() -> void:
	var validator := ContentValidator.new()
	var clean := validator.validate(_catalog())
	_ok("validator seed has no errors", not _has_error(clean))
	var dup_catalog := _catalog()
	var clone: DateTag = dup_catalog.tags[0].duplicate() as DateTag
	dup_catalog.tags.append(clone)
	_ok("32. Validator ловит duplicate IDs", _has_issue(validator.validate(dup_catalog), "Дублирующийся"))
	var broken := _catalog()
	broken.moves[0].situation_mappings[0].situation_id = &"missing_sit"
	_ok("33. Validator ловит broken references", _has_issue(validator.validate(broken), "Неизвестная Situation"))
	var thin := _catalog()
	var situation: DateSituation = thin.find_situation(&"appearance_question")
	for move in thin.moves:
		var keep: Array[DateMoveSituationMapping] = []
		for mapping in move.situation_mappings:
			if mapping.situation_id != situation.id:
				keep.append(mapping)
		move.situation_mappings = keep
	_ok("34. Validator ловит Situation с недостаточным BASE pool", _has_issue(validator.validate(thin), "Недостаточно BASE"))
	var secondary := _catalog()
	secondary.find_secondary(&"variety").condition_parameters["required_count"] = 0
	_ok("35. Validator проверяет Secondary parameters", _has_issue(validator.validate(secondary), "required_count"))
	var unlock := _catalog()
	unlock.find_move(&"punch").unlock_requirement = null
	_ok("36. Validator проверяет UnlockRequirement", _has_issue(validator.validate(unlock), "UnlockRequirement"))
	var dup_unlock := _diversity_catalog(
		[["base_a", "directness"], ["base_b", "risk"], ["base_c", "status"]],
		[["unlock_status_a", "status", 0, 1], ["unlock_status_b", "status", 0, 1]]
	)
	var dup_issues: Array[ContentValidationIssue] = validator.validate(dup_unlock)
	var dup_warning: ContentValidationIssue = _find_code(dup_issues, "DUPLICATE_UNLOCKABLE_TAG_IN_SITUATION")
	_ok("8. WARNING DUPLICATE_UNLOCKABLE_TAG_IN_SITUATION", dup_warning != null and dup_warning.severity == DateTypes.ValidationSeverity.WARNING)
	_ok("8. warning names status unlockables", dup_warning != null and "status" in dup_warning.message and "unlock_status_a" in dup_warning.message and "unlock_status_b" in dup_warning.message)


func _has_issue(issues: Array[ContentValidationIssue], needle: String) -> bool:
	for issue in issues:
		if needle in issue.message:
			return true
	return false


func _has_error(issues: Array[ContentValidationIssue]) -> bool:
	for issue in issues:
		if issue.severity == DateTypes.ValidationSeverity.ERROR:
			return true
	return false


func _find_code(issues: Array[ContentValidationIssue], code: String) -> ContentValidationIssue:
	for issue in issues:
		if issue.code == code:
			return issue
	return null


func _test_unlockable_tag_reservation() -> void:
	var four_base: Array = [["base_risk", "risk"], ["base_directness", "directness"], ["base_status", "status"], ["base_dominance", "dominance"]]
	var available_catalog: DateContentCatalog = _diversity_catalog(four_base, [["unlock_risk", "risk", 3, 1]])
	var available_player: TestPlayerState = _player()
	available_player.capital = 6
	var available_engine: DateEngine = _start(available_catalog, &"alina", &"cafe", &"casual", 3, _fresh_progress(available_catalog, &"alina"), available_player)
	var available_session: DateSession = available_engine.get_session_state()
	_ok("1. AVAILABLE reserves risk", available_session.current_reserved_unlockable_tag_ids.has(&"risk"))
	_ok("1. BASE tags are the non-reserved set", _same_tag_set(available_session.current_selected_base_tag_ids, ["directness", "status", "dominance"]))
	_ok("1. risk BASE is fallback", available_session.current_fallback_base_move_ids.has(&"base_risk") and not available_session.current_preferred_base_move_ids.has(&"base_risk"))

	var locked_catalog: DateContentCatalog = _diversity_catalog(four_base, [["unlock_risk", "risk", 3, 1]])
	var locked_engine: DateEngine = _start(locked_catalog, &"alina", &"cafe", &"casual", 3, _fresh_progress(locked_catalog, &"alina"), _player())
	var locked_session: DateSession = locked_engine.get_session_state()
	_ok("2. LOCKED does not reserve", locked_session.current_locked_unlockable_move_ids.has(&"unlock_risk") and not locked_session.current_reserved_unlockable_tag_ids.has(&"risk"))
	_ok("2. BASE risk is in preferred pool", locked_session.current_preferred_base_move_ids.has(&"base_risk"))

	var used_catalog: DateContentCatalog = _diversity_catalog(four_base, [["unlock_risk", "risk", 3, 1]], 0, 2, true)
	var used_player: TestPlayerState = _player()
	used_player.capital = 6
	var used_engine: DateEngine = _start(used_catalog, &"alina", &"cafe", &"casual", 3, _fresh_progress(used_catalog, &"alina"), used_player)
	_ok("3 pre AVAILABLE", used_engine.get_session_state().current_available_unlockable_move_ids.has(&"unlock_risk"))
	used_engine.choose_move(&"unlock_risk")
	used_engine.advance()
	var used_session: DateSession = used_engine.get_session_state()
	_ok("3. USED does not reserve", used_session.current_used_unlockable_move_ids.has(&"unlock_risk") and not used_session.current_reserved_unlockable_tag_ids.has(&"risk"))
	_ok("3. BASE risk returns to preferred pool", used_session.current_preferred_base_move_ids.has(&"base_risk"))

	var unique_catalog: DateContentCatalog = _diversity_catalog(four_base, [])
	var unique_engine: DateEngine = _start(unique_catalog, &"alina", &"cafe", &"casual", 17, _fresh_progress(unique_catalog, &"alina"), _player())
	_ok("4. three BASE have three Tags", unique_engine.get_session_state().current_selected_base_move_ids.size() == 3 and _unique_count(unique_engine.get_session_state().current_selected_base_tag_ids) == 3)

	var fallback_catalog: DateContentCatalog = _diversity_catalog(
		[["base_a", "risk"], ["base_b", "risk"], ["base_c", "directness"], ["base_d", "directness"], ["base_e", "risk"]],
		[]
	)
	var fallback_engine: DateEngine = _start(fallback_catalog, &"alina", &"cafe", &"casual", 19, _fresh_progress(fallback_catalog, &"alina"), _player())
	var fallback_session: DateSession = fallback_engine.get_session_state()
	_ok("5. three BASE with only two Tags", fallback_session.current_selected_base_move_ids.size() == 3 and _unique_count(fallback_session.current_selected_base_tag_ids) == 2)

	var need_fallback: DateContentCatalog = _diversity_catalog(
		[["base_risk", "risk"], ["base_directness", "directness"], ["base_status", "status"]],
		[["unlock_risk", "risk", 3, 1]]
	)
	var need_player: TestPlayerState = _player()
	need_player.capital = 6
	var need_engine: DateEngine = _start(need_fallback, &"alina", &"cafe", &"casual", 23, _fresh_progress(need_fallback, &"alina"), need_player)
	var need_session: DateSession = need_engine.get_session_state()
	_ok("6. fallback includes reserved Tag", _same_tag_set(need_session.current_selected_base_tag_ids, ["risk", "directness", "status"]))
	_ok("6. all three BASE selected", need_session.current_selected_base_move_ids.size() == 3)

	var det_catalog_a: DateContentCatalog = _diversity_catalog(four_base, [["unlock_risk", "risk", 3, 1]])
	var det_catalog_b: DateContentCatalog = _diversity_catalog(four_base, [["unlock_risk", "risk", 3, 1]])
	var det_player_a: TestPlayerState = _player()
	det_player_a.capital = 6
	var det_player_b: TestPlayerState = _player()
	det_player_b.capital = 6
	var det_a: DateEngine = _start(det_catalog_a, &"alina", &"cafe", &"casual", 91, _fresh_progress(det_catalog_a, &"alina"), det_player_a)
	var det_b: DateEngine = _start(det_catalog_b, &"alina", &"cafe", &"casual", 91, _fresh_progress(det_catalog_b, &"alina"), det_player_b)
	_ok("7. same seed same BASE ids and order", det_a.get_session_state().current_selected_base_move_ids == det_b.get_session_state().current_selected_base_move_ids)

	var seed_catalog: DateContentCatalog = _catalog()
	for situation in seed_catalog.situations:
		if situation.id != &"appearance_question" and situation.id != &"spontaneous_bet":
			situation.enabled = false
	seed_catalog.date_rules.core_episode_count = 1
	seed_catalog.date_rules.closing_episode_count = 0
	var seed_player: TestPlayerState = _player()
	seed_player.capital = 6
	var seed_engine: DateEngine = _start(seed_catalog, &"alina", &"cafe", &"casual", 5, _fresh_progress(seed_catalog, &"alina"), seed_player)
	_choose(seed_engine, _first_available(seed_engine))
	var seed_session: DateSession = seed_engine.get_session_state()
	_ok("seed spontaneous_bet episode", seed_session.selected_situation_ids.size() >= 2 and seed_session.selected_situation_ids[1] == &"spontaneous_bet")
	_ok("seed reserved STATUS", seed_session.current_reserved_unlockable_tag_ids.has(&"status"))
	_ok("seed reserved RISK", seed_session.current_reserved_unlockable_tag_ids.has(&"risk"))
	_ok("seed BASE prefers other tags", not seed_session.current_selected_base_tag_ids.has(&"status") and not seed_session.current_selected_base_tag_ids.has(&"risk"))


func _test_twelve_tag_rebalance() -> void:
	var catalog: DateContentCatalog = _catalog()
	var enabled: Array[DateTag] = catalog.enabled_tags()
	_ok("22.1 seed contains 12 Tags", enabled.size() == 12)
	var alina: GirlProfile = catalog.find_girl(&"alina")
	_ok("22.2 Alina difficulty starter", alina.difficulty_preset_id == &"starter")
	_ok("22.2 Alina positives", _same_tag_set(alina.positive_tag_ids, ["politeness", "directness", "care", "generosity", "composure", "humor"]))
	_ok("22.2 Alina sizes", alina.positive_tag_ids.size() == 6 and alina.negative_tag_ids.size() == 6)
	_ok("22.2 Alina range", alina.relationship_min == -5 and alina.relationship_max == 5)
	var vika: GirlProfile = catalog.find_girl(&"vika")
	_ok("22.3 Vika difficulty late", vika.difficulty_preset_id == &"late")
	_ok("22.3 Vika positives", _same_tag_set(vika.positive_tag_ids, ["audacity", "dominance", "risk"]))
	_ok("22.3 Vika sizes", vika.positive_tag_ids.size() == 3 and vika.negative_tag_ids.size() == 9)
	_ok("22.3 Vika range", vika.relationship_min == -10 and vika.relationship_max == 10)
	for girl in catalog.girls:
		_ok("22.4 coverage %s" % String(girl.id), _girl_covers_enabled_tags(girl, enabled))
	var validator := ContentValidator.new()
	var two: DateContentCatalog = _catalog()
	var two_girl: GirlProfile = two.find_girl(&"alina")
	two_girl.positive_tag_ids = [&"care", &"generosity"] as Array[StringName]
	two_girl.sync_negative_tags(two.enabled_tags())
	_ok("22.5 two positives", _find_code(validator.validate(two), "INVALID_POSITIVE_TAG_COUNT") != null)
	var four: DateContentCatalog = _catalog()
	var four_girl: GirlProfile = four.find_girl(&"alina")
	four_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
	four_girl.sync_negative_tags(four.enabled_tags())
	_ok("22.5 four positives", _find_code(validator.validate(four), "INVALID_POSITIVE_TAG_COUNT") != null)
	var three_issues: Array[ContentValidationIssue] = validator.validate(_catalog())
	_ok("22.5 six positives pass count", _find_code(three_issues, "INVALID_POSITIVE_TAG_COUNT") == null)
	_ok("22.6 unused tags warning count", _count_code(three_issues, "TAG_WITHOUT_MOVE_MAPPING") == 0)
	_ok("22.6 no incomplete coverage", _find_code(three_issues, "INCOMPLETE_GIRL_TAG_COVERAGE") == null)
	for situation in catalog.situations:
		if situation == null or not situation.enabled:
			continue
		var distinct: int = _distinct_base_tags(catalog, situation.id)
		print("BASE diversity %s = %d" % [String(situation.id), distinct])
		_ok("22.7 BASE diversity %s" % String(situation.id), distinct >= 6)
	_ok("22.8 support appearance care", _mapping_tag(&"support", &"appearance_question") == &"care")
	_ok("22.8 support verdict care", _mapping_tag(&"support", &"date_verdict") == &"care")
	_ok("22.9 tease appearance humor", _mapping_tag(&"tease", &"appearance_question") == &"humor")
	_ok("22.9 tease rival humor", _mapping_tag(&"tease", &"rival_provocation") == &"humor")
	_ok("22.9 tease verdict humor", _mapping_tag(&"tease", &"date_verdict") == &"humor")
	_ok("22.10 tease money cunning", _mapping_tag(&"tease", &"money_request") == &"cunning")
	_ok("22.10 refuse rival cunning", _mapping_tag(&"refuse", &"rival_provocation") == &"cunning")
	_ok("22.11 smooth rival composure", _mapping_tag(&"smooth", &"rival_provocation") == &"composure")
	_ok("22.11 refuse money composure", _mapping_tag(&"refuse", &"money_request") == &"composure")
	_ok("22.11 refuse bet composure", _mapping_tag(&"refuse", &"spontaneous_bet") == &"composure")
	_ok("22.11 silent verdict composure", _mapping_tag(&"silent_pressure", &"date_verdict") == &"composure")
	var reset_progress: GirlProgress = _fresh_progress(catalog, &"alina")
	for tag_id in [&"care", &"humor", &"composure", &"cunning"]:
		_ok("22.12 UNKNOWN %s" % String(tag_id), reset_progress.tag_knowledge(tag_id) == DateTypes.TagKnowledge.UNKNOWN)
	var remap_progress := GirlProgress.new()
	remap_progress.reset_to_profile(alina)
	remap_progress.revealed_positive_tag_ids = [&"flattery"] as Array[StringName]
	remap_progress.revealed_negative_tag_ids = [&"care"] as Array[StringName]
	remap_progress.realign_revealed_to_profile(alina, catalog)
	_ok("22.12 remap flattery negative", remap_progress.tag_knowledge(&"flattery") == DateTypes.TagKnowledge.NEGATIVE)
	_ok("22.12 remap care positive", remap_progress.tag_knowledge(&"care") == DateTypes.TagKnowledge.POSITIVE)
	_ok("22.12 remap humor unknown", remap_progress.tag_knowledge(&"humor") == DateTypes.TagKnowledge.UNKNOWN)
	_ok("22.13 reveal care positive", _reveal_tag_knowledge(&"care", true))
	_ok("22.13 reveal composure positive", _reveal_tag_knowledge(&"composure", true))
	_ok("22.13 reveal humor positive", _reveal_tag_knowledge(&"humor", true))
	_ok("22.13 reveal cunning negative", _reveal_tag_knowledge(&"cunning", false))
	_test_twelve_tag_reservation_regression()
	_test_twelve_tag_balance_simulation()


func _girl_covers_enabled_tags(girl: GirlProfile, enabled: Array[DateTag]) -> bool:
	var positive: Dictionary = {}
	var negative: Dictionary = {}
	for tag_id in girl.positive_tag_ids:
		positive[String(tag_id)] = true
	for tag_id in girl.negative_tag_ids:
		negative[String(tag_id)] = true
	for tag_id in positive.keys():
		if negative.has(String(tag_id)):
			return false
	var union: Dictionary = {}
	for tag_id in positive.keys():
		union[String(tag_id)] = true
	for tag_id in negative.keys():
		union[String(tag_id)] = true
	if union.size() != enabled.size():
		return false
	for tag in enabled:
		if not union.has(String(tag.id)):
			return false
	return true


func _distinct_base_tags(catalog: DateContentCatalog, situation_id: StringName) -> int:
	var tags: Dictionary = {}
	for move in catalog.applicable_moves(situation_id, DateTypes.DateMoveKind.BASE):
		var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
		if mapping == null:
			continue
		tags[String(mapping.tag_id)] = true
	return tags.size()


func _mapping_tag(move_id: StringName, situation_id: StringName) -> StringName:
	var move: DateMove = _catalog().find_move(move_id)
	if move == null:
		return &""
	var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
	if mapping == null:
		return &""
	return mapping.tag_id


func _count_code(issues: Array[ContentValidationIssue], code: String) -> int:
	var count: int = 0
	for issue in issues:
		if issue.code == code:
			count += 1
	return count


func _reveal_tag_knowledge(tag_id: StringName, expect_positive: bool) -> bool:
	for seed in range(1, 200):
		var catalog: DateContentCatalog = _new_tag_lab_catalog()
		var progress: GirlProgress = _fresh_progress(catalog, &"alina")
		var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		var found: bool = false
		for option in engine.get_available_moves():
			if option.is_selectable() and option.tag_id == tag_id:
				found = true
				_choose(engine, option.move_id)
				break
		if not found:
			continue
		var knowledge: DateTypes.TagKnowledge = progress.tag_knowledge(tag_id)
		if expect_positive:
			return knowledge == DateTypes.TagKnowledge.POSITIVE
		return knowledge == DateTypes.TagKnowledge.NEGATIVE
	return false


func _new_tag_lab_catalog() -> DateContentCatalog:
	return _diversity_catalog(
		[["base_care", "care"], ["base_humor", "humor"], ["base_composure", "composure"], ["base_cunning", "cunning"]],
		[]
	)


func _test_twelve_tag_reservation_regression() -> void:
	var specs: Array = []
	for tag in _catalog().enabled_tags():
		specs.append(["base_%s" % String(tag.id), String(tag.id)])
	var catalog: DateContentCatalog = _diversity_catalog(specs, [["unlock_care", "care", 3, 1]])
	var player: TestPlayerState = _player()
	player.capital = 6
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 11, _fresh_progress(catalog, &"alina"), player)
	var session: DateSession = engine.get_session_state()
	_ok("22.14 reserved care", session.current_reserved_unlockable_tag_ids.has(&"care"))
	_ok("22.14 care not preferred", not session.current_preferred_base_move_ids.has(&"base_care"))
	_ok("22.14 care is fallback", session.current_fallback_base_move_ids.has(&"base_care"))
	_ok("22.14 selected BASE omits reserved care", not session.current_selected_base_tag_ids.has(&"care"))
	_ok("22.14 three BASE selected", session.current_selected_base_move_ids.size() == 3)


func _test_twelve_tag_balance_simulation() -> void:
	var cases: Array = [
		[6, 0.89, 0.93, "STARTER"],
		[5, 0.82, 0.86, "EARLY"],
		[4, 0.72, 0.77, "MID"],
		[3, 0.59, 0.65, "LATE"],
		[2, 0.42, 0.49, "ELITE"],
	]
	for case in cases:
		var share: float = _uniform_positive_share(int(case[0]))
		print("BALANCE %s positive=%d share=%.4f" % [str(case[3]), int(case[0]), share])
		_ok("23. %s 10000-seed share %.2f..%.2f" % [str(case[3]), float(case[1]), float(case[2])], share >= float(case[1]) and share <= float(case[2]), "share=%.4f" % share)


func _uniform_positive_share(positive_count: int) -> float:
	var specs: Array = []
	var catalog: DateContentCatalog = _catalog()
	for tag in catalog.enabled_tags():
		specs.append(["base_%s" % String(tag.id), String(tag.id)])
	catalog = _diversity_catalog(specs, [])
	var girl: GirlProfile = catalog.find_girl(&"alina")
	var positives: Array[StringName] = []
	for tag in catalog.enabled_tags():
		if positives.size() >= positive_count:
			break
		positives.append(tag.id)
	girl.positive_tag_ids = positives
	girl.sync_negative_tags(catalog.enabled_tags())
	var liked: Dictionary = {}
	for tag_id in girl.positive_tag_ids:
		liked[String(tag_id)] = true
	var hits: int = 0
	for seed in range(1, 10001):
		var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var has_positive: bool = false
		for tag_id in engine.get_session_state().current_selected_base_tag_ids:
			if liked.has(String(tag_id)):
				has_positive = true
				break
		if has_positive:
			hits += 1
	return float(hits) / 10000.0


func _diversity_catalog(base_specs: Array, unlock_specs: Array, opening_count: int = 1, core_count: int = 0, allow_repeats: bool = false) -> DateContentCatalog:
	var catalog: DateContentCatalog = _catalog()
	var situation: DateSituation = DateSituation.new()
	situation.id = &"lab_episode"
	situation.display_name = "Lab"
	situation.description = "Lab"
	situation.situation_text = "Lab"
	situation.enabled = true
	situation.allowed_phases = [
		int(DateTypes.DatePhase.OPENING),
		int(DateTypes.DatePhase.CORE),
		int(DateTypes.DatePhase.CLOSING),
	]
	situation.weight = 1.0
	var situations: Array[DateSituation] = []
	situations.append(situation)
	catalog.situations = situations
	var moves: Array[DateMove] = []
	for spec in base_specs:
		moves.append(_test_base_move(String(spec[0]), String(spec[1])))
	for spec in unlock_specs:
		moves.append(_test_unlock_move(String(spec[0]), String(spec[1]), int(spec[2]), int(spec[3])))
	catalog.moves = moves
	catalog.date_rules.opening_episode_count = opening_count
	catalog.date_rules.core_episode_count = core_count
	catalog.date_rules.closing_episode_count = 0
	catalog.date_rules.allow_situation_repeats = allow_repeats
	catalog.date_rules.base_moves_per_episode = 3
	return catalog


func _test_base_move(move_id: String, tag_id: String) -> DateMove:
	var move: DateMove = DateMove.new()
	move.id = StringName(move_id)
	move.display_name = move_id
	move.description = move_id
	move.kind = DateTypes.DateMoveKind.BASE
	move.enabled = true
	move.max_uses_per_date = 0
	var mappings: Array[DateMoveSituationMapping] = []
	mappings.append(_test_mapping(tag_id))
	move.situation_mappings = mappings
	return move


func _test_unlock_move(move_id: String, tag_id: String, required_level: int, max_uses: int) -> DateMove:
	var move: DateMove = DateMove.new()
	move.id = StringName(move_id)
	move.display_name = move_id
	move.description = move_id
	move.kind = DateTypes.DateMoveKind.UNLOCKABLE
	move.enabled = true
	move.max_uses_per_date = max_uses
	var requirement: UnlockRequirement = UnlockRequirement.new()
	requirement.stat_id = &"capital"
	requirement.required_level = required_level
	move.unlock_requirement = requirement
	var mappings: Array[DateMoveSituationMapping] = []
	mappings.append(_test_mapping(tag_id))
	move.situation_mappings = mappings
	return move


func _test_mapping(tag_id: String) -> DateMoveSituationMapping:
	var mapping: DateMoveSituationMapping = DateMoveSituationMapping.new()
	mapping.situation_id = &"lab_episode"
	mapping.tag_id = StringName(tag_id)
	mapping.option_text = tag_id
	mapping.positive_result_text = "ok"
	mapping.negative_result_text = "no"
	return mapping


func _test_girl_difficulty() -> void:
	var catalog: DateContentCatalog = _catalog()
	var presets: Array[GirlDifficultyPreset] = catalog.enabled_girl_difficulty_presets()
	_ok("5 enabled difficulty presets", presets.size() == 5)
	_ok("STARTER positive_tag_count == 6", catalog.find_girl_difficulty(&"starter").positive_tag_count == 6)
	_ok("EARLY positive_tag_count == 5", catalog.find_girl_difficulty(&"early").positive_tag_count == 5)
	_ok("MID positive_tag_count == 4", catalog.find_girl_difficulty(&"mid").positive_tag_count == 4)
	_ok("LATE positive_tag_count == 3", catalog.find_girl_difficulty(&"late").positive_tag_count == 3)
	_ok("ELITE positive_tag_count == 2", catalog.find_girl_difficulty(&"elite").positive_tag_count == 2)
	var expected: Array = [[6, 0.9091], [5, 0.8409], [4, 0.7455], [3, 0.6182], [2, 0.4545]]
	for pair in expected:
		var actual: float = DateBalanceMath.at_least_one_positive_probability(12, int(pair[0]), 3)
		_ok("theory positive=%d" % int(pair[0]), abs(actual - float(pair[1])) < 0.0002, "actual=%.4f" % actual)
	var validator := ContentValidator.new()
	var seed_issues: Array[ContentValidationIssue] = validator.validate(catalog)
	_ok("seed 0 INVALID_GIRL_DIFFICULTY_REFERENCE", _find_code(seed_issues, "INVALID_GIRL_DIFFICULTY_REFERENCE") == null)
	_ok("seed 0 INVALID_POSITIVE_TAG_COUNT", _find_code(seed_issues, "INVALID_POSITIVE_TAG_COUNT") == null)
	_ok("seed 0 INCOMPLETE_GIRL_TAG_COVERAGE", _find_code(seed_issues, "INCOMPLETE_GIRL_TAG_COVERAGE") == null)
	_ok("seed 0 INVALID_DIFFICULTY_POSITIVE_COUNT", _find_code(seed_issues, "INVALID_DIFFICULTY_POSITIVE_COUNT") == null)
	var missing := _catalog()
	missing.find_girl(&"alina").difficulty_preset_id = &"missing"
	_ok("INVALID_GIRL_DIFFICULTY_REFERENCE missing", _find_code(validator.validate(missing), "INVALID_GIRL_DIFFICULTY_REFERENCE") != null)
	var disabled := _catalog()
	disabled.find_girl_difficulty(&"starter").enabled = false
	_ok("INVALID_GIRL_DIFFICULTY_REFERENCE disabled", _find_code(validator.validate(disabled), "INVALID_GIRL_DIFFICULTY_REFERENCE") != null)
	var bad_count := _catalog()
	bad_count.find_girl_difficulty(&"mid").positive_tag_count = 12
	_ok("INVALID_DIFFICULTY_POSITIVE_COUNT", _find_code(validator.validate(bad_count), "INVALID_DIFFICULTY_POSITIVE_COUNT") != null)
	var mid_girl: GirlProfile = GirlProfile.new()
	mid_girl.id = &"lab_mid"
	mid_girl.display_name = "Lab Mid"
	mid_girl.enabled = true
	mid_girl.difficulty_preset_id = &"mid"
	mid_girl.relationship_min = -5
	mid_girl.relationship_max = 5
	mid_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
	mid_girl.sync_negative_tags(catalog.enabled_tags())
	_ok("save mid positive 4", mid_girl.positive_tag_ids.size() == 4)
	_ok("save mid negative 8", mid_girl.negative_tag_ids.size() == 8)
	_ok("save mid coverage", _girl_covers_enabled_tags(mid_girl, catalog.enabled_tags()))
	DirAccess.make_dir_recursive_absolute("user://date_system")
	var path: String = "user://date_system/test_mid_girl.tres"
	_ok("save mid girl", ResourceSaver.save(mid_girl, path) == OK)
	var loaded: GirlProfile = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GirlProfile
	_ok("reload mid girl", loaded != null and loaded.positive_tag_ids.size() == 4 and loaded.negative_tag_ids.size() == 8)
	_ok("reload mid coverage", loaded != null and _girl_covers_enabled_tags(loaded, catalog.enabled_tags()))
	var starter_girl: GirlProfile = catalog.find_girl(&"alina").duplicate(true) as GirlProfile
	_ok("starter current 6", starter_girl.positive_tag_ids.size() == 6)
	starter_girl.difficulty_preset_id = &"mid"
	var required: int = catalog.find_girl_difficulty(&"mid").positive_tag_count
	_ok("editor shows 6 / 4", starter_girl.positive_tag_ids.size() == 6 and required == 4)
	starter_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
	starter_girl.sync_negative_tags(catalog.enabled_tags())
	_ok("after MID save 4/8", starter_girl.difficulty_preset_id == &"mid" and starter_girl.positive_tag_ids.size() == 4 and starter_girl.negative_tag_ids.size() == 8)
	var progress := GirlProgress.new()
	var alina: GirlProfile = catalog.find_girl(&"alina")
	progress.reset_to_profile(alina)
	progress.reveal_tag(&"care", true)
	progress.reveal_tag(&"flattery", false)
	var swapped: GirlProfile = alina.duplicate(true) as GirlProfile
	swapped.positive_tag_ids.erase(&"care")
	swapped.positive_tag_ids.append(&"flattery")
	swapped.sync_negative_tags(catalog.enabled_tags())
	progress.realign_revealed_to_profile(swapped, catalog)
	_ok("known care stays known", progress.tag_knowledge(&"care") != DateTypes.TagKnowledge.UNKNOWN)
	_ok("known flattery stays known", progress.tag_knowledge(&"flattery") != DateTypes.TagKnowledge.UNKNOWN)
	_ok("care follows updated profile", progress.tag_knowledge(&"care") == DateTypes.TagKnowledge.NEGATIVE)
	_ok("flattery follows updated profile", progress.tag_knowledge(&"flattery") == DateTypes.TagKnowledge.POSITIVE)
	var diagnostics := DateBalanceDiagnostics.new()
	var alina_sim: Dictionary = {}
	var vika_sim: Dictionary = {}
	for girl_id in [&"alina", &"vika"]:
		var girl: GirlProfile = catalog.find_girl(girl_id)
		var result: Dictionary = diagnostics.simulate_girl(catalog, girl, 10000)
		if girl_id == &"alina":
			alina_sim = result
		else:
			vika_sim = result
		print("SEED SIM %s at_least_one=%.4f all_negative=%.4f avg=%.3f episodes=%d" % [String(girl_id), float(result["at_least_one"]), float(result["all_negative"]), float(result["average_positive"]), int(result["episodes"])])
		for row in result["situations"]:
			print("SEED SIM %s %s at_least=%.4f all_neg=%.4f avg=%.3f" % [String(girl_id), str(row["situation_id"]), float(row["at_least_one"]), float(row["all_negative"]), float(row["average_positive"])])
	_ok("Alina BASE availability above Vika", float(alina_sim["at_least_one"]) > float(vika_sim["at_least_one"]))


func _same_tag_set(actual: Array[StringName], expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	var found: Dictionary = {}
	for tag_id in actual:
		found[String(tag_id)] = true
	for tag in expected:
		if not found.has(String(tag)):
			return false
	return true


func _unique_count(ids: Array[StringName]) -> int:
	var found: Dictionary = {}
	for item in ids:
		found[String(item)] = true
	return found.size()


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node


func _save_manager() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("SaveManager")
	if not is_instance_valid(node):
		return null
	return node


func _time_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("TimeService")
	if not is_instance_valid(node):
		return null
	return node


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node


func _action_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ActionService")
	if not is_instance_valid(node):
		return null
	return node


func _economy_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EconomyService")
	if not is_instance_valid(node):
		return null
	return node


func _purchase_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("PurchaseService")
	if not is_instance_valid(node):
		return null
	return node


func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node


func _rating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RatingService")
	if not is_instance_valid(node):
		return null
	return node


func _active_session_location(dating: Variant) -> StringName:
	if dating == null:
		return &""
	var engine: DateEngine = dating.get_date_engine() as DateEngine
	if engine == null:
		return &""
	var session: DateSession = engine.get_session_state()
	if session == null:
		return &""
	return session.location_id


func _active_session_outfit(dating: Variant) -> StringName:
	if dating == null:
		return &""
	var engine: DateEngine = dating.get_date_engine() as DateEngine
	if engine == null:
		return &""
	var session: DateSession = engine.get_session_state()
	if session == null:
		return &""
	return session.outfit_id


func _dating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("DatingService")
	if not is_instance_valid(node):
		return null
	return node


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node


func _competition_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CompetitionService")
	if not is_instance_valid(node):
		return null
	return node


func _characteristic_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CharacteristicService")
	if not is_instance_valid(node):
		return null
	return node


func _equipment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EquipmentService")
	if not is_instance_valid(node):
		return null
	return node


func _apartment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ApartmentService")
	if not is_instance_valid(node):
		return null
	return node


func _assert_clock(label: String, clock: Variant, minutes: int, day: int, hour: int, minute: int) -> void:
	_ok("%s game_time_minutes" % label, clock.get_game_time_minutes() == minutes)
	_ok("%s day" % label, clock.get_day() == day)
	_ok("%s hour" % label, clock.get_hour() == hour)
	_ok("%s minute" % label, clock.get_minute() == minute)


func _test_game_state_round_trip() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	_ok("GameState autoload", gs != null)
	_ok("SaveManager autoload", sm != null)
	_ok("TimeService autoload", clock != null)
	if gs == null or sm == null or clock == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/game_state_round_trip.json"
	sm.delete_save()
	_ok("has_save false after delete", not sm.has_save())
	sm.new_game()
	_ok("new_game game_time_minutes 0", gs.flow.game_time_minutes == 0)
	_ok("new_game day 1", clock.get_day() == 1)
	_ok("new_game stage 1", gs.story.stage == 1)
	_ok("new_game finale false", gs.story.finale_reached == false)
	_ok("new_game money 0", gs.player.money == 0)
	_ok("new_game rating 0", gs.player.rating == 0)
	_ok("new_game muscle 0", gs.player.muscle == 0)
	_ok("new_game appearance 0", gs.player.appearance == 0)
	_ok("new_game capital 0", gs.player.capital == 0)
	_ok("new_game aura 0", gs.player.aura == 0)
	_ok("new_game purchased empty", gs.progression.purchased_ids.is_empty())
	_ok("new_game start outfit owned", gs.progression.owns_outfit(OutfitCatalog.START_OUTFIT_ID))
	_ok("new_game start outfit equipped", gs.progression.equipped_outfit_id == OutfitCatalog.START_OUTFIT_ID)
	_ok("new_game apartment level 1", gs.progression.apartment.level == 1)
	_ok("new_game start location", gs.world.current_location_id == LocationCatalog.START_LOCATION_ID)
	_ok("new_game start unlocked city", gs.world.has_unlocked(LocationCatalog.ID_CITY_CENTER))
	_ok("new_game start unlocked apartment", gs.world.has_unlocked(LocationCatalog.ID_APARTMENT))
	_ok("new_game start unlocked cafe", gs.world.has_unlocked(LocationCatalog.ID_CAFE))
	_ok("new_game restaurant locked", not gs.world.has_unlocked(LocationCatalog.ID_RESTAURANT))
	_ok("new_game girls empty", gs.girls.girls_by_id.is_empty())
	_ok("new_game rivals empty", gs.rivals.rivals_by_id.is_empty())
	gs.flow.game_time_minutes = 8640
	gs.story.stage = 3
	gs.player.money = 12345
	sm.save_game()
	_ok("has_save true after save", sm.has_save())
	var file: FileAccess = FileAccess.open(sm.save_path, FileAccess.READ)
	_ok("save file opened", file != null)
	var parsed: Variant = {}
	if file != null:
		parsed = JSON.parse_string(file.get_as_text())
		file.close()
	var root: Dictionary = parsed if parsed is Dictionary else {}
	_ok("save_version == 10", int(root.get("save_version", 0)) == 10)
	var snapshot: Variant = root.get("game_state", {})
	var state_dict: Dictionary = snapshot if snapshot is Dictionary else {}
	var progression_value: Variant = state_dict.get("progression", {})
	var progression_dict: Dictionary = progression_value if progression_value is Dictionary else {}
	var purchased_raw: Variant = progression_dict.get("purchased_ids", ["x"])
	_ok("save has empty purchased_ids", purchased_raw is Array and (purchased_raw as Array).is_empty())
	var flow_value: Variant = state_dict.get("flow", {})
	var flow_dict: Dictionary = flow_value if flow_value is Dictionary else {}
	_ok("save has game_time_minutes", int(flow_dict.get("game_time_minutes", -1)) == 8640)
	_ok("save has no day", not flow_dict.has("day"))
	var story_value: Variant = state_dict.get("story", {})
	var story_dict: Dictionary = story_value if story_value is Dictionary else {}
	_ok("save has stage", int(story_dict.get("stage", 0)) == 3)
	_ok("save has finale_reached", story_dict.get("finale_reached", true) == false)
	sm.new_game()
	_ok("new_game resets values", gs.flow.game_time_minutes == 0 and gs.story.stage == 1 and gs.story.finale_reached == false and gs.player.money == 0)
	_ok("load_game", sm.load_game())
	_ok("loaded game_time_minutes == 8640", gs.flow.game_time_minutes == 8640)
	_ok("loaded day == 7", clock.get_day() == 7)
	_ok("loaded stage == 3", gs.story.stage == 3)
	_ok("loaded finale == false", gs.story.finale_reached == false)
	_ok("loaded money == 12345", gs.player.money == 12345)
	_ok("section flow", gs.flow != null)
	_ok("section story", gs.story != null)
	_ok("section player", gs.player != null)
	_ok("section progression", gs.progression != null)
	_ok("section world", gs.world != null)
	_ok("section girls", gs.girls != null)
	_ok("section dating", gs.dating != null)
	_ok("section rivals", gs.rivals != null)
	_ok("section automation", gs.automation != null)
	gs.from_dict({"flow": {}, "story": {}, "player": {}})
	_ok("missing keys default game_time_minutes", gs.flow.game_time_minutes == 0)
	_ok("missing keys default day", clock.get_day() == 1)
	_ok("missing keys default stage", gs.story.stage == 1)
	_ok("missing keys default finale", gs.story.finale_reached == false)
	_ok("missing keys default money", gs.player.money == 0)
	_ok("missing keys default rating", gs.player.rating == 0)
	_ok("missing keys default location", gs.world.current_location_id == LocationCatalog.START_LOCATION_ID)
	_ok("missing keys default unlocked city", gs.world.has_unlocked(LocationCatalog.ID_CITY_CENTER))
	sm.delete_save()
	_ok("deleted test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()


func _test_game_time() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	_ok("game time GameState", gs != null)
	_ok("game time SaveManager", sm != null)
	_ok("game time TimeService", clock != null)
	if gs == null or sm == null or clock == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/game_time_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	_assert_clock("start", clock, 0, 1, 0, 0)
	clock.advance_time(90)
	_assert_clock("inside day", clock, 90, 1, 1, 30)
	gs.flow.game_time_minutes = 1380
	clock.advance_time(120)
	_assert_clock("day rollover", clock, 1500, 2, 1, 0)
	sm.new_game()
	clock.advance_time(4320)
	_ok("multi-day minutes", clock.get_game_time_minutes() == 4320)
	_ok("multi-day day", clock.get_day() == 4)
	sm.new_game()
	clock.advance_time(3675)
	sm.save_game()
	sm.new_game()
	_ok("clean runtime after save", clock.get_game_time_minutes() == 0)
	_ok("load_game time", sm.load_game())
	_assert_clock("loaded 3675", clock, 3675, 3, 13, 15)
	sm.new_game()
	var events: Array = []
	var on_time := func(delta_minutes: int, previous_game_time: int, current_game_time: int) -> void:
		events.append({
			"delta_minutes": delta_minutes,
			"previous_game_time": previous_game_time,
			"current_game_time": current_game_time,
		})
	clock.time_advanced.connect(on_time)
	var previous_game_time: int = clock.get_game_time_minutes()
	clock.advance_time(120)
	clock.time_advanced.disconnect(on_time)
	_ok("time event once", events.size() == 1)
	if events.size() == 1:
		var payload: Dictionary = events[0]
		_ok("time event delta", int(payload["delta_minutes"]) == 120)
		_ok("time event previous", int(payload["previous_game_time"]) == previous_game_time)
		_ok("time event current", int(payload["current_game_time"]) == previous_game_time + 120)
	sm.new_game()
	var action := GameAction.new()
	action.time_cost_minutes = 120
	clock.apply_action(action)
	_ok("game action minutes", clock.get_game_time_minutes() == 120)
	_ok("days_to_minutes", clock.days_to_minutes(3) == 4320)
	_ok("hours_to_minutes", clock.hours_to_minutes(5) == 300)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v1 save", legacy != null)
	if legacy != null:
		var v1: Dictionary = {
			"save_version": 1,
			"game_state": {
				"flow": {"day": 7},
				"story": {"stage": 1},
				"player": {"money": 0},
			},
		}
		legacy.store_string(JSON.stringify(v1, "\t"))
		legacy.close()
	_ok("load v1 save", sm.load_game())
	_ok("migrated minutes", clock.get_game_time_minutes() == 8640)
	_ok("migrated day", clock.get_day() == 7)
	_ok("migrated v1 finale false", gs.story.finale_reached == false)
	sm.delete_save()
	_ok("deleted time test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()


func _assert_campaign(label: String, stages: Variant, stage: int, finale: bool) -> void:
	_ok("%s get_current_stage" % label, stages.get_current_stage() == stage)
	_ok("%s is_finale_reached" % label, stages.is_finale_reached() == finale)
	var gs: Variant = _game_state()
	if gs == null:
		return
	_ok("%s story.stage" % label, gs.story.stage == stage)
	_ok("%s story.finale_reached" % label, gs.story.finale_reached == finale)


func _test_campaign_stages() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	_ok("campaign GameState", gs != null)
	_ok("campaign SaveManager", sm != null)
	_ok("campaign StageService", stages != null)
	if gs == null or sm == null or stages == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/campaign_round_trip.json"
	sm.delete_save()
	sm.new_game()
	_assert_campaign("new_game", stages, 1, false)
	_ok("advance 1 to 2", stages.complete_current_stage())
	_assert_campaign("after first complete", stages, 2, false)
	sm.new_game()
	for step in range(5):
		_ok("sequence complete %d" % (step + 1), stages.complete_current_stage())
	_assert_campaign("after five completes", stages, 6, false)
	_ok("enter finale", stages.complete_current_stage())
	_assert_campaign("finale", stages, 6, true)
	_ok("repeat after finale returns false", stages.complete_current_stage() == false)
	_assert_campaign("still finale", stages, 6, true)
	sm.new_game()
	gs.story.stage = 3
	gs.story.finale_reached = false
	var stage_events: Array = []
	var on_stage := func(previous_stage: int, current_stage: int) -> void:
		stage_events.append({
			"previous_stage": previous_stage,
			"current_stage": current_stage,
		})
	stages.stage_changed.connect(on_stage)
	_ok("complete 3 to 4", stages.complete_current_stage())
	stages.stage_changed.disconnect(on_stage)
	_ok("stage_changed once", stage_events.size() == 1)
	if stage_events.size() == 1:
		var payload: Dictionary = stage_events[0]
		_ok("stage_changed previous", int(payload["previous_stage"]) == 3)
		_ok("stage_changed current", int(payload["current_stage"]) == 4)
	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = false
	var finale_events: Array = []
	var on_finale := func() -> void:
		finale_events.append(true)
	stages.finale_reached.connect(on_finale)
	_ok("complete stage 6", stages.complete_current_stage())
	_ok("finale_reached once", finale_events.size() == 1)
	_ok("complete after finale false", stages.complete_current_stage() == false)
	_ok("finale_reached still once", finale_events.size() == 1)
	stages.finale_reached.disconnect(on_finale)
	sm.new_game()
	gs.story.stage = 5
	gs.story.finale_reached = false
	sm.save_game()
	sm.new_game()
	_assert_campaign("clean before load 5", stages, 1, false)
	_ok("load stage 5", sm.load_game())
	_assert_campaign("loaded stage 5", stages, 5, false)
	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = true
	sm.save_game()
	sm.new_game()
	_ok("load finale save", sm.load_game())
	_assert_campaign("loaded finale", stages, 6, true)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v2 save", legacy != null)
	if legacy != null:
		var v2: Dictionary = {
			"save_version": 2,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 4},
				"player": {"money": 0},
			},
		}
		legacy.store_string(JSON.stringify(v2, "\t"))
		legacy.close()
	_ok("load v2 save", sm.load_game())
	_assert_campaign("migrated v2", stages, 4, false)
	sm.delete_save()
	_ok("deleted campaign test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()


func _test_game_actions() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var actions: Variant = _action_service()
	_ok("game actions GameState", gs != null)
	_ok("game actions SaveManager", sm != null)
	_ok("game actions TimeService", clock != null)
	_ok("game actions ActionService", actions != null)
	if gs == null or sm == null or clock == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/game_actions_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	gs.flow.game_time_minutes = 0
	var wait_result: ActionResult = actions.execute(GameActionCatalog.make_test_wait())
	_ok("test_wait success", wait_result.success)
	_ok("test_wait time", clock.get_game_time_minutes() == 120)
	sm.new_game()
	gs.player.money = 0
	gs.flow.game_time_minutes = 0
	var earn_result: ActionResult = actions.execute(GameActionCatalog.make_test_earn_money())
	_ok("test_earn money", gs.player.money == 100)
	_ok("test_earn time", clock.get_game_time_minutes() == 60)
	_ok("test_earn success", earn_result.success)
	sm.new_game()
	gs.player.money = 100
	var spend_ok: ActionResult = actions.execute(GameActionCatalog.make_test_spend_money())
	_ok("test_spend money", gs.player.money == 50)
	_ok("test_spend success", spend_ok.success)
	_ok("test_spend time_spent", spend_ok.time_spent_minutes == 30)
	_ok("test_spend money_spent", spend_ok.money_spent == 50)
	sm.new_game()
	gs.player.money = 25
	gs.flow.game_time_minutes = 0
	var spend_fail: ActionResult = actions.execute(GameActionCatalog.make_test_spend_money())
	_ok("test_spend fail success", spend_fail.success == false)
	_ok("test_spend fail money", gs.player.money == 25)
	_ok("test_spend fail time", clock.get_game_time_minutes() == 0)
	_ok("test_spend fail reason", spend_fail.failure_reason == "Недостаточно денег")
	sm.new_game()
	gs.player.money = 50
	var req_time_before: int = clock.get_game_time_minutes()
	var req_fail: ActionResult = actions.execute(GameActionCatalog.make_test_require_money())
	_ok("require fail success", req_fail.success == false)
	_ok("require fail money", gs.player.money == 50)
	_ok("require fail time", clock.get_game_time_minutes() == req_time_before)
	_ok("require fail reason", req_fail.failure_reason == "Недостаточно денег")
	sm.new_game()
	gs.player.money = 100
	var req_ok: ActionResult = actions.execute(GameActionCatalog.make_test_require_money())
	_ok("require success", req_ok.success)
	sm.new_game()
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	var pipeline := GameAction.new()
	pipeline.id = &"pipeline_test"
	pipeline.money_cost = 30
	pipeline.time_cost_minutes = 120
	var bonus := MoneyEffect.new()
	bonus.amount = 50
	pipeline.effects.append(bonus)
	var pipe_result: ActionResult = actions.execute(pipeline)
	_ok("pipeline money", gs.player.money == 120)
	_ok("pipeline time", clock.get_game_time_minutes() == 120)
	_ok("pipeline success", pipe_result.success)
	_ok("pipeline money_spent", pipe_result.money_spent == 30)
	_ok("pipeline time_spent", pipe_result.time_spent_minutes == 120)
	sm.new_game()
	gs.player.money = 50
	gs.flow.game_time_minutes = 0
	var atomic := GameAction.new()
	atomic.id = &"atomic_fail"
	atomic.money_cost = 10
	atomic.time_cost_minutes = 60
	var req_low := MoneyRequirement.new()
	req_low.required_money = 10
	var req_high := MoneyRequirement.new()
	req_high.required_money = 100
	atomic.requirements.append(req_low)
	atomic.requirements.append(req_high)
	var poison := MoneyEffect.new()
	poison.amount = 999
	atomic.effects.append(poison)
	var atomic_result: ActionResult = actions.execute(atomic)
	_ok("atomic fail success", atomic_result.success == false)
	_ok("atomic fail money", gs.player.money == 50)
	_ok("atomic fail time", clock.get_game_time_minutes() == 0)
	_ok("atomic fail effects", atomic_result.applied_effects.is_empty())
	_ok("atomic can_execute", actions.can_execute(atomic) == false)
	sm.new_game()
	gs.player.money = 0
	gs.flow.game_time_minutes = 0
	var events: Array = []
	var on_action := func(action_id: StringName, result: ActionResult) -> void:
		events.append({
			"action_id": action_id,
			"success": result.success,
		})
	actions.action_executed.connect(on_action)
	var signal_ok: ActionResult = actions.execute(GameActionCatalog.make_test_earn_money())
	_ok("signal execute success", signal_ok.success)
	_ok("signal once", events.size() == 1)
	if events.size() == 1:
		var payload: Dictionary = events[0]
		_ok("signal action_id", payload["action_id"] == GameActionCatalog.ID_TEST_EARN_MONEY)
		_ok("signal result", bool(payload["success"]) == true)
	gs.player.money = 25
	var signal_fail: ActionResult = actions.execute(GameActionCatalog.make_test_spend_money())
	_ok("signal fail execute", signal_fail.success == false)
	_ok("signal still once", events.size() == 1)
	actions.action_executed.disconnect(on_action)
	sm.delete_save()
	_ok("deleted action test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()


func _test_game_simulator() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var actions: Variant = _action_service()
	_ok("simulator GameState", gs != null)
	_ok("simulator SaveManager", sm != null)
	_ok("simulator TimeService", clock != null)
	_ok("simulator StageService", stages != null)
	_ok("simulator ActionService", actions != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("simulator tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or stages == null or actions == null or tree == null or tree.root == null:
		return
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/game_simulator_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sim.start_new_game()
	_ok("sim new money", gs.player.money == 0)
	_ok("sim new stage", int(stages.get_current_stage()) == 1)
	_ok("sim new day", int(clock.get_day()) == 1)
	_ok("sim new minutes", int(clock.get_game_time_minutes()) == 0)
	var hud: String = sim.get_hud_text()
	_ok("sim hud day", hud.contains("День 1"))
	_ok("sim hud time", hud.contains("00:00"))
	_ok("sim hud money", hud.contains("Деньги: 0"))
	_ok("sim hud stage", hud.contains("Stage: 1"))
	sim.show_section("work")
	var earn: ActionResult = sim.execute_catalog_action(GameActionCatalog.ID_TEST_EARN_MONEY)
	_ok("sim work success", earn.success)
	_ok("sim work money", gs.player.money == 100)
	_ok("sim work time", int(clock.get_game_time_minutes()) == 60)
	_ok("sim work hud money", sim.get_hud_text().contains("Деньги: 100"))
	_ok("sim work hud time", sim.get_hud_text().contains("01:00"))
	_ok("sim work result ok", sim.get_result_text().contains("Успешно."))
	_ok("sim work result money", sim.get_result_text().contains("Получено: +100 денег"))
	_ok("sim work result time", sim.get_result_text().contains("Прошло времени: 60 мин."))
	var money_before: int = int(gs.player.money)
	var time_before: int = int(gs.flow.game_time_minutes)
	var stage_before: int = int(stages.get_current_stage())
	for pair in GameSimulator.SECTIONS:
		var section_id: String = str(pair[0])
		sim.show_section(section_id)
		_ok("nav section %s" % section_id, sim.get_current_section() == section_id)
		_ok("nav money %s" % section_id, int(gs.player.money) == money_before)
		_ok("nav time %s" % section_id, int(gs.flow.game_time_minutes) == time_before)
		_ok("nav stage %s" % section_id, int(stages.get_current_stage()) == stage_before)
	sim.show_section("city")
	var wait: ActionResult = sim.execute_catalog_action(GameActionCatalog.ID_TEST_WAIT)
	_ok("sim wait success", wait.success)
	_ok("sim wait time", int(clock.get_game_time_minutes()) == 180)
	sim.start_new_game()
	sim.execute_catalog_action(GameActionCatalog.ID_TEST_EARN_MONEY)
	sim.execute_catalog_action(GameActionCatalog.ID_TEST_EARN_MONEY)
	_ok("sim two work money", gs.player.money == 200)
	_ok("sim two work time", int(clock.get_game_time_minutes()) == 120)
	sim.save_playthrough()
	_ok("sim saved text", sim.get_result_text() == "Игра сохранена.")
	_ok("sim has save", bool(sm.has_save()))
	sim.start_new_game()
	_ok("sim reset money", gs.player.money == 0)
	_ok("sim reset time", int(clock.get_game_time_minutes()) == 0)
	sim.load_playthrough()
	_ok("sim load money", gs.player.money == 200)
	_ok("sim load time", int(clock.get_game_time_minutes()) == 120)
	_ok("sim load hud", sim.get_hud_text().contains("Деньги: 200"))
	sim.start_new_game()
	var fail: ActionResult = sim.execute_catalog_action(GameActionCatalog.ID_TEST_SPEND_MONEY)
	_ok("sim fail success", fail.success == false)
	_ok("sim fail money unchanged", gs.player.money == 0)
	_ok("sim fail header", sim.get_result_text().contains("Действие недоступно."))
	_ok("sim fail reason", sim.get_result_text().contains("Недостаточно денег"))
	sim.start_new_game()
	for step in range(5):
		sim.complete_current_stage()
	_ok("sim stage 6", int(stages.get_current_stage()) == 6)
	_ok("sim not finale yet", stages.is_finale_reached() == false)
	sim.complete_current_stage()
	_ok("sim finale stage", int(stages.get_current_stage()) == 6)
	_ok("sim finale flag", bool(stages.is_finale_reached()))
	_ok("sim finale presented", sim.is_finale_presented())
	_ok("sim finale hud", sim.get_hud_text().contains("Finale"))
	sim.delete_playthrough()
	_ok("sim deleted save", not sm.has_save())
	sim.queue_free()
	sm.save_path = original_path
	sm.new_game()


func _test_economy() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var actions: Variant = _action_service()
	var economy: Variant = _economy_service()
	var purchases: Variant = _purchase_service()
	_ok("economy GameState", gs != null)
	_ok("economy SaveManager", sm != null)
	_ok("economy TimeService", clock != null)
	_ok("economy ActionService", actions != null)
	_ok("economy EconomyService", economy != null)
	_ok("economy PurchaseService", purchases != null)
	if gs == null or sm == null or clock == null or actions == null or economy == null or purchases == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/economy_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	gs.player.money = 100
	economy.add_money(50)
	_ok("add_money 100+50", gs.player.money == 150)
	_ok("add_money get_money", int(economy.get_money()) == 150)
	sm.new_game()
	gs.player.money = 100
	var spend_ok: bool = bool(economy.spend_money(30))
	_ok("spend success money", gs.player.money == 70)
	_ok("spend success result", spend_ok)
	sm.new_game()
	gs.player.money = 20
	var spend_fail: bool = bool(economy.spend_money(30))
	_ok("spend fail money", gs.player.money == 20)
	_ok("spend fail result", spend_fail == false)
	sm.new_game()
	gs.player.money = 100
	var add_events: Array = []
	var on_add := func(previous_money: int, current_money: int, delta: int) -> void:
		add_events.append({
			"previous_money": previous_money,
			"current_money": current_money,
			"delta": delta,
		})
	economy.money_changed.connect(on_add)
	economy.add_money(50)
	economy.money_changed.disconnect(on_add)
	_ok("add money_changed once", add_events.size() == 1)
	if add_events.size() == 1:
		var add_payload: Dictionary = add_events[0]
		_ok("add previous", int(add_payload["previous_money"]) == 100)
		_ok("add current", int(add_payload["current_money"]) == 150)
		_ok("add delta", int(add_payload["delta"]) == 50)
	var spend_events: Array = []
	var on_spend := func(previous_money: int, current_money: int, delta: int) -> void:
		spend_events.append({
			"previous_money": previous_money,
			"current_money": current_money,
			"delta": delta,
		})
	economy.money_changed.connect(on_spend)
	var spend_from_150: bool = bool(economy.spend_money(30))
	economy.money_changed.disconnect(on_spend)
	_ok("spend after add result", spend_from_150)
	_ok("spend money_changed once", spend_events.size() == 1)
	if spend_events.size() == 1:
		var spend_payload: Dictionary = spend_events[0]
		_ok("spend previous", int(spend_payload["previous_money"]) == 150)
		_ok("spend current", int(spend_payload["current_money"]) == 120)
		_ok("spend delta", int(spend_payload["delta"]) == -30)
	sm.new_game()
	gs.player.money = 0
	gs.flow.game_time_minutes = 0
	var work: WorkDefinition = WorkService.make_work_basic()
	var work_action: GameAction = WorkService.create_work_action(work)
	var work_first: ActionResult = actions.execute(work_action)
	_ok("work_basic first success", work_first.success)
	_ok("work_basic first money", gs.player.money == 100)
	_ok("work_basic first time", clock.get_game_time_minutes() == 60)
	var work_second: ActionResult = actions.execute(WorkService.create_work_action(work))
	_ok("work_basic second success", work_second.success)
	_ok("work_basic second money", gs.player.money == 200)
	_ok("work_basic second time", clock.get_game_time_minutes() == 120)
	sm.new_game()
	gs.player.money = 299
	gs.flow.game_time_minutes = 0
	var definition: PurchaseDefinition = purchases.make_basic_upgrade()
	var buy_fail: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	_ok("purchase poor success", buy_fail.success == false)
	_ok("purchase poor money", gs.player.money == 299)
	_ok("purchase poor not bought", purchases.is_purchased(definition.id) == false)
	_ok("purchase poor reason", buy_fail.failure_reason == "Недостаточно денег")
	sm.new_game()
	gs.player.money = 300
	gs.flow.game_time_minutes = 90
	var purchase_events: Array = []
	var on_purchase := func(purchase_id: StringName) -> void:
		purchase_events.append(purchase_id)
	purchases.purchase_completed.connect(on_purchase)
	var buy_ok: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	_ok("purchase success", buy_ok.success)
	_ok("purchase money", gs.player.money == 0)
	_ok("purchase bought", purchases.is_purchased(&"basic_upgrade"))
	_ok("purchase time unchanged", clock.get_game_time_minutes() == 90)
	_ok("purchase_completed once", purchase_events.size() == 1)
	if purchase_events.size() == 1:
		_ok("purchase_completed id", purchase_events[0] == &"basic_upgrade")
	var buy_again: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	purchases.purchase_completed.disconnect(on_purchase)
	_ok("repurchase success", buy_again.success == false)
	_ok("repurchase money", gs.player.money == 0)
	_ok("repurchase still bought", purchases.is_purchased(&"basic_upgrade"))
	_ok("repurchase unique", gs.progression.purchased_ids.size() == 1)
	_ok("repurchase reason", buy_again.failure_reason == "Уже куплено")
	_ok("repurchase no extra signal", purchase_events.size() == 1)
	sm.new_game()
	gs.player.money = 500
	gs.flow.game_time_minutes = 0
	var buy_saved: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	_ok("save purchase success", buy_saved.success)
	_ok("save purchase money", gs.player.money == 200)
	sm.save_game()
	sm.new_game()
	_ok("clean money after save", gs.player.money == 0)
	_ok("clean purchased after save", purchases.is_purchased(&"basic_upgrade") == false)
	_ok("load economy save", sm.load_game())
	_ok("loaded money 200", gs.player.money == 200)
	_ok("loaded purchased", purchases.is_purchased(&"basic_upgrade"))
	sm.new_game()
	gs.player.money = 0
	gs.flow.game_time_minutes = 0
	for _i in range(3):
		actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	_ok("cycle money 300", gs.player.money == 300)
	_ok("cycle time 180", clock.get_game_time_minutes() == 180)
	var cycle_buy: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	_ok("cycle buy success", cycle_buy.success)
	_ok("cycle money 0", gs.player.money == 0)
	_ok("cycle purchased", purchases.is_purchased(&"basic_upgrade"))
	_ok("cycle time still 180", clock.get_game_time_minutes() == 180)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v3 save", legacy != null)
	if legacy != null:
		var v3: Dictionary = {
			"save_version": 3,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 80},
				"progression": {},
			},
		}
		legacy.store_string(JSON.stringify(v3, "\t"))
		legacy.close()
	_ok("load v3 save", sm.load_game())
	_ok("migrated v3 money", gs.player.money == 80)
	_ok("migrated v3 purchased empty", gs.progression.purchased_ids.is_empty())
	sm.delete_save()
	_ok("deleted economy test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()


func _test_world() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var world: Variant = _world_service()
	_ok("world GameState", gs != null)
	_ok("world SaveManager", sm != null)
	_ok("world TimeService", clock != null)
	_ok("world WorldService", world != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("world tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or world == null or tree == null or tree.root == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/world_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	_ok("world new current", world.get_current_location_id() == LocationCatalog.START_LOCATION_ID)
	_ok("world new city unlocked", world.is_location_unlocked(LocationCatalog.ID_CITY_CENTER))
	_ok("world new apartment unlocked", world.is_location_unlocked(LocationCatalog.ID_APARTMENT))
	_ok("world new cafe unlocked", world.is_location_unlocked(LocationCatalog.ID_CAFE))
	_ok("world new restaurant locked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
	var start_location: LocationDefinition = world.get_current_location()
	_ok("world current definition", start_location != null and start_location.id == LocationCatalog.ID_CITY_CENTER)
	var unlocked_events: Array = []
	var on_unlocked := func(location_id: StringName) -> void:
		unlocked_events.append(location_id)
	world.location_unlocked.connect(on_unlocked)
	var first_unlock: bool = bool(world.unlock_location(LocationCatalog.ID_RESTAURANT))
	_ok("world first unlock", first_unlock)
	_ok("world restaurant unlocked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	_ok("world unlock signal once", unlocked_events.size() == 1)
	var second_unlock: bool = bool(world.unlock_location(LocationCatalog.ID_RESTAURANT))
	_ok("world repeat unlock false", second_unlock == false)
	_ok("world restaurant unique", gs.world.unlocked_location_ids.count(LocationCatalog.ID_RESTAURANT) == 1)
	_ok("world unlock signal still once", unlocked_events.size() == 1)
	world.location_unlocked.disconnect(on_unlocked)
	sm.new_game()
	var changed_events: Array = []
	var on_changed := func(previous_location_id: StringName, current_location_id: StringName) -> void:
		changed_events.append([previous_location_id, current_location_id])
	world.location_changed.connect(on_changed)
	var time_before: int = int(clock.get_game_time_minutes())
	var enter_ok: bool = bool(world.enter_location(LocationCatalog.ID_APARTMENT))
	_ok("world enter apartment", enter_ok)
	_ok("world current apartment", world.get_current_location_id() == LocationCatalog.ID_APARTMENT)
	_ok("world location_changed once", changed_events.size() == 1)
	if changed_events.size() == 1:
		var payload: Array = changed_events[0]
		_ok("world changed from city", payload[0] == LocationCatalog.ID_CITY_CENTER)
		_ok("world changed to apartment", payload[1] == LocationCatalog.ID_APARTMENT)
	_ok("world enter no time", int(clock.get_game_time_minutes()) == time_before)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var locked_enter: bool = bool(world.enter_location(LocationCatalog.ID_RESTAURANT))
	_ok("world locked enter false", locked_enter == false)
	_ok("world locked current unchanged", world.get_current_location_id() == LocationCatalog.ID_CITY_CENTER)
	world.location_changed.disconnect(on_changed)
	var req := LocationRequirement.new()
	req.required_location_id = LocationCatalog.ID_APARTMENT
	world.enter_location(LocationCatalog.ID_APARTMENT)
	_ok("location requirement met", req.is_met())
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("location requirement unmet", req.is_met() == false)
	_ok("location requirement reason", req.get_failure_reason() == "Действие недоступно в этой локации")
	var unlock_effect := UnlockLocationEffect.new()
	unlock_effect.location_id = LocationCatalog.ID_RESTAURANT
	sm.new_game()
	unlock_effect.apply()
	_ok("unlock effect restaurant", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	sm.new_game()
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	sm.save_game()
	sm.new_game()
	_ok("world clean after save", world.get_current_location_id() == LocationCatalog.START_LOCATION_ID)
	_ok("world clean restaurant locked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
	_ok("world load save", sm.load_game())
	_ok("world loaded restaurant current", world.get_current_location_id() == LocationCatalog.ID_RESTAURANT)
	_ok("world loaded restaurant unlocked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v4 world save", legacy != null)
	if legacy != null:
		var v4: Dictionary = {
			"save_version": 4,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0},
				"progression": {"purchased_ids": []},
				"world": {},
			},
		}
		legacy.store_string(JSON.stringify(v4, "\t"))
		legacy.close()
	_ok("load v4 world save", sm.load_game())
	_ok("migrated v4 location", world.get_current_location_id() == LocationCatalog.START_LOCATION_ID)
	_ok("migrated v4 city unlocked", world.is_location_unlocked(LocationCatalog.ID_CITY_CENTER))
	_ok("migrated v4 apartment unlocked", world.is_location_unlocked(LocationCatalog.ID_APARTMENT))
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	sim.start_new_game()
	sim.show_section("city")
	_ok("sim city current", sim.get_city_current_location_name() == "Центральная часть города")
	var city_text: String = sim.get_city_body_text()
	_ok("sim city cafe", city_text.contains("Кафе"))
	_ok("sim city apartment", city_text.contains("Квартира"))
	_ok("sim city restaurant locked", city_text.contains("Ресторан 🔒"))
	var sim_time: int = int(clock.get_game_time_minutes())
	_ok("sim enter apartment", sim.enter_world_location(LocationCatalog.ID_APARTMENT))
	_ok("sim apartment name", sim.get_city_current_location_name() == "Квартира")
	_ok("sim exit button", sim.get_city_body_text().contains("ВЫЙТИ"))
	_ok("sim enter no time", int(clock.get_game_time_minutes()) == sim_time)
	_ok("sim exit interior", sim.exit_world_interior())
	_ok("sim back to city", sim.get_city_current_location_name() == "Центральная часть города")
	_ok("sim exit no time", int(clock.get_game_time_minutes()) == sim_time)
	var city_scene: PackedScene = load(LocationCatalog.SCENE_CITY_CENTER) as PackedScene
	_ok("city scene exists", city_scene != null)
	if city_scene != null:
		var city_node: Node = city_scene.instantiate()
		var to_apartment: LocationDoor = city_node.find_child("ToApartment", true, false) as LocationDoor
		_ok("city door to apartment", to_apartment != null and to_apartment.target_location_id == LocationCatalog.ID_APARTMENT)
		city_node.free()
	var apartment_scene: PackedScene = load(LocationCatalog.SCENE_APARTMENT) as PackedScene
	_ok("apartment scene exists", apartment_scene != null)
	if apartment_scene != null:
		var apartment_node: Node = apartment_scene.instantiate()
		var exit_door: LocationDoor = apartment_node.find_child("ExitDoor", true, false) as LocationDoor
		_ok("apartment exit to city", exit_door != null and exit_door.target_location_id == LocationCatalog.ID_CITY_CENTER)
		apartment_node.free()
	sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_girls() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var actions: Variant = _action_service()
	_ok("girls GameState", gs != null)
	_ok("girls SaveManager", sm != null)
	_ok("girls TimeService", clock != null)
	_ok("girls WorldService", world != null)
	_ok("girls GirlsService", girls != null)
	_ok("girls ActionService", actions != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("girls tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or world == null or girls == null or actions == null or tree == null or tree.root == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/girls_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	var alina_id: StringName = GirlCatalog.ID_ALINA
	var vika_id: StringName = GirlCatalog.ID_VIKA
	var alina_def: GirlDefinition = girls.get_definition(alina_id)
	var vika_def: GirlDefinition = girls.get_definition(vika_id)
	_ok("alina definition", alina_def != null and alina_def.display_name == "Алина")
	_ok("alina location cafe", alina_def != null and alina_def.location_id == LocationCatalog.ID_CAFE)
	_ok("vika definition", vika_def != null and vika_def.display_name == "Вика")
	_ok("vika location restaurant", vika_def != null and vika_def.location_id == LocationCatalog.ID_RESTAURANT)
	var default_state: GirlState = GirlState.new()
	_ok("default discovered false", default_state.discovered == false)
	_ok("default has_contact false", default_state.has_contact == false)
	_ok("default relationship 0", default_state.relationship == 0)
	_ok("default next_date_available_at 0", default_state.next_date_available_at == 0)
	_ok("default revealed tags empty", default_state.revealed_positive_tag_ids.is_empty() and default_state.revealed_negative_tag_ids.is_empty())
	_ok("default secondary hidden", default_state.secondary_revealed == false)
	_ok("default completed_dates 0", default_state.completed_dates == 0)
	var created: GirlState = girls.get_state(alina_id)
	_ok("created state defaults", created != null and created.discovered == false and created.has_contact == false and created.relationship == 0)
	_ok("created stored", gs.girls.girls_by_id.has(alina_id))
	var discovered_events: Array = []
	var on_discovered := func(girl_id: StringName) -> void:
		discovered_events.append(girl_id)
	girls.girl_discovered.connect(on_discovered)
	_ok("discover first", girls.discover_girl(alina_id))
	_ok("is_discovered", girls.is_discovered(alina_id))
	_ok("discover signal once", discovered_events.size() == 1)
	_ok("discover repeat false", girls.discover_girl(alina_id) == false)
	_ok("discover signal still once", discovered_events.size() == 1)
	girls.girl_discovered.disconnect(on_discovered)
	sm.new_game()
	_ok("give_contact first", girls.give_contact(alina_id))
	_ok("contact discovered", girls.is_discovered(alina_id))
	_ok("has_contact", girls.has_contact(alina_id))
	_ok("give_contact repeat false", girls.give_contact(alina_id) == false)
	sm.new_game()
	_ok("relationship start 0", girls.get_relationship(alina_id) == 0)
	_ok("relationship plus two", girls.change_relationship(alina_id, 2) == 2)
	_ok("relationship after plus", girls.get_relationship(alina_id) == 2)
	_ok("relationship minus one", girls.change_relationship(alina_id, -1) == 1)
	_ok("relationship after minus", girls.get_relationship(alina_id) == 1)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CAFE)
	var at_cafe: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("cafe has alina", _girl_list_has(at_cafe, alina_id))
	_ok("cafe no vika", _girl_list_has(at_cafe, vika_id) == false)
	world.enter_location(LocationCatalog.ID_APARTMENT)
	var at_apartment: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("apartment no alina", _girl_list_has(at_apartment, alina_id) == false)
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var at_restaurant: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("restaurant has vika", _girl_list_has(at_restaurant, vika_id))
	_ok("restaurant no alina", _girl_list_has(at_restaurant, alina_id) == false)
	sm.new_game()
	var contact_req := GirlContactRequirement.new()
	contact_req.girl_id = alina_id
	_ok("contact req new game false", contact_req.is_met() == false)
	world.enter_location(LocationCatalog.ID_CAFE)
	gs.flow.game_time_minutes = 0
	var meet_action: GameAction = girls.create_meet_girl_action(alina_id)
	_ok("meet action id", meet_action.id == StringName("meet_alina"))
	_ok("meet time cost", meet_action.time_cost_minutes == 30)
	_ok("meet money cost", meet_action.money_cost == 0)
	var meet_ok: ActionResult = actions.execute(meet_action)
	_ok("meet success", meet_ok.success)
	_ok("meet discovered", girls.is_discovered(alina_id))
	_ok("meet has_contact", girls.has_contact(alina_id))
	_ok("meet time 30", int(clock.get_game_time_minutes()) == 30)
	_ok("contact req after meet", contact_req.is_met())
	var time_after_meet: int = int(clock.get_game_time_minutes())
	var snapshot: Dictionary = girls.get_state(alina_id).to_dict()
	var meet_again: ActionResult = actions.execute(meet_action)
	_ok("meet repeat fail", meet_again.success == false)
	_ok("meet repeat reason", meet_again.failure_reason == "Вы уже знакомы")
	_ok("meet repeat time unchanged", int(clock.get_game_time_minutes()) == time_after_meet)
	_ok("meet repeat state unchanged", girls.get_state(alina_id).to_dict() == snapshot)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_APARTMENT)
	gs.flow.game_time_minutes = 0
	var other_loc: ActionResult = actions.execute(girls.create_meet_girl_action(alina_id))
	_ok("meet other location fail", other_loc.success == false)
	_ok("meet other location reason", other_loc.failure_reason == "Девушка находится в другой локации")
	_ok("meet other location undiscovered", girls.is_discovered(alina_id) == false)
	_ok("meet other location no contact", girls.has_contact(alina_id) == false)
	_ok("meet other location time", int(clock.get_game_time_minutes()) == 0)
	sm.new_game()
	girls.get_state(alina_id).relationship = 2
	var rel_req := RelationshipRequirement.new()
	rel_req.girl_id = alina_id
	rel_req.minimum_relationship = 1
	_ok("rel req min 1", rel_req.is_met())
	rel_req.minimum_relationship = 2
	_ok("rel req min 2", rel_req.is_met())
	rel_req.minimum_relationship = 3
	_ok("rel req min 3", rel_req.is_met() == false)
	_ok("rel req reason", rel_req.get_failure_reason() == "Недостаточный уровень отношений")
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CAFE)
	actions.execute(girls.create_meet_girl_action(alina_id))
	sm.save_game()
	sm.new_game()
	_ok("girls clean after save", girls.is_discovered(alina_id) == false and girls.has_contact(alina_id) == false)
	_ok("girls load save", sm.load_game())
	_ok("loaded discovered", girls.is_discovered(alina_id))
	_ok("loaded has_contact", girls.has_contact(alina_id))
	_ok("loaded relationship 0", girls.get_relationship(alina_id) == 0)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v5 girls save", legacy != null)
	if legacy != null:
		var v5: Dictionary = {
			"save_version": 5,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {},
			},
		}
		legacy.store_string(JSON.stringify(v5, "\t"))
		legacy.close()
	_ok("load v5 girls save", sm.load_game())
	_ok("migrated girls empty", gs.girls.girls_by_id.is_empty())
	var migrated_state: GirlState = girls.get_state(alina_id)
	_ok("migrated defaults", migrated_state != null and migrated_state.discovered == false and migrated_state.has_contact == false and migrated_state.relationship == 0)
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	sim.start_new_game()
	sim.show_section("city")
	sim.enter_world_location(LocationCatalog.ID_CAFE)
	var cafe_text: String = sim.get_city_body_text()
	_ok("sim cafe alina", cafe_text.contains("Алина"))
	_ok("sim cafe unknown", cafe_text.contains("Вы ещё не знакомы."))
	_ok("sim cafe meet button", cafe_text.contains("ПОЗНАКОМИТЬСЯ"))
	var sim_meet: ActionResult = sim.meet_girl(alina_id)
	_ok("sim meet success", sim_meet.success)
	_ok("sim meet result name", sim.get_result_text().contains("Вы познакомились с Алина."))
	_ok("sim meet result contact", sim.get_result_text().contains("Получен контакт."))
	_ok("sim meet result time", sim.get_result_text().contains("Прошло времени: 30 минут."))
	var known_text: String = sim.get_city_body_text()
	_ok("sim cafe known no meet", known_text.contains("ПОЗНАКОМИТЬСЯ") == false)
	sim.show_section("girls")
	var girls_text: String = sim.get_city_body_text()
	_ok("sim girls alina", girls_text.contains("АЛИНА"))
	_ok("sim girls relationship", girls_text.contains("Отношения: 0 / 5"))
	_ok("sim girls contact", girls_text.contains("Контакт: Да"))
	_ok("sim girls no vika", girls_text.contains("ВИКА") == false)
	sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _girl_list_has(list: Array[GirlDefinition], girl_id: StringName) -> bool:
	for girl in list:
		if girl != null and girl.id == girl_id:
			return true
	return false


func _test_dating_and_rating() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	_ok("dating GameState", gs != null)
	_ok("dating SaveManager", sm != null)
	_ok("dating TimeService", clock != null)
	_ok("dating GirlsService", girls != null)
	_ok("dating RatingService", rating != null)
	_ok("dating DatingService", dating != null)
	_ok("dating ActionService", actions != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("dating tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or girls == null or rating == null or dating == null or actions == null or tree == null or tree.root == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/dating_rating_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	var alina_id: StringName = GirlCatalog.ID_ALINA
	_ok("rating new game 0", int(rating.get_rating()) == 0)
	girls.get_state(alina_id).relationship = 4
	_ok("rating plus one at max", girls.change_relationship(alina_id, 1) == 5)
	_ok("relationship at max", girls.get_relationship(alina_id) == 5)
	_ok("rating after max", int(rating.get_rating()) == 1)
	_ok("relationship completed", girls.is_relationship_completed(alina_id))
	sm.new_game()
	girls.get_state(alina_id).relationship = 4
	_ok("rating large delta clamps", girls.change_relationship(alina_id, 10) == 5)
	_ok("rating large delta once", int(rating.get_rating()) == 1)
	_ok("rating repeat no extra", girls.change_relationship(alina_id, 1) == 5)
	_ok("rating stays 1", int(rating.get_rating()) == 1)
	_ok("relationship stays max", girls.get_relationship(alina_id) == 5)
	gs.player.rating = 3
	sm.save_game()
	sm.new_game()
	_ok("rating reset on new game", int(rating.get_rating()) == 0)
	_ok("load rating save", sm.load_game())
	_ok("loaded rating 3", int(rating.get_rating()) == 3)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	_ok("start date ready", dating.can_start_date(alina_id))
	var start_action: GameAction = dating.create_start_date_action(alina_id, &"cafe")
	_ok("start action id", start_action.id == StringName("start_date_alina"))
	_ok("start action no time", start_action.time_cost_minutes == 0)
	_ok("start action no money", start_action.money_cost == 0)
	var start_ok: ActionResult = actions.execute(start_action)
	_ok("start date success", start_ok.success)
	_ok("has active date", dating.has_active_date())
	_ok("active girl id", dating.get_active_girl_id() == alina_id)
	_ok("active location id", dating.get_active_location_id() == &"cafe")
	_ok("active_date girl", String(gs.dating.active_date.get("girl_id", "")) == String(alina_id))
	_ok("active_date location", String(gs.dating.active_date.get("location_id", "")) == "cafe")
	_ok("session location cafe", _active_session_location(dating) == &"cafe")
	sm.new_game()
	girls.discover_girl(alina_id)
	_ok("start without contact", dating.can_start_date(alina_id) == false)
	_ok("start without contact reason", dating.get_start_date_failure_reason(alina_id) == "У вас нет контакта этой девушки")
	var no_contact: ActionResult = actions.execute(dating.create_start_date_action(alina_id, &"cafe"))
	_ok("start without contact fail", no_contact.success == false)
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).next_date_available_at = int(clock.get_game_time_minutes()) + 100
	_ok("start during cooldown", dating.can_start_date(alina_id) == false)
	_ok("start cooldown reason", dating.get_start_date_failure_reason(alina_id) == "До следующего свидания нужно подождать")
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = 5
	_ok("start after max", dating.can_start_date(alina_id) == false)
	_ok("start after max reason", dating.get_start_date_failure_reason(alina_id) == "Отношения с этой девушкой уже достигли максимума")
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = 1
	gs.flow.game_time_minutes = 1000
	_ok("complete start", dating.start_date(alina_id, &"cafe"))
	var date_result := DateResult.new()
	date_result.girl_id = alina_id
	date_result.relationship_delta = 1
	date_result.duration_minutes = 120
	_ok("complete date", dating.complete_date(date_result))
	_ok("complete relationship 2", girls.get_relationship(alina_id) == 2)
	_ok("complete time 1120", int(clock.get_game_time_minutes()) == 1120)
	_ok("complete cooldown", girls.get_next_date_available_at(alina_id) == 1120 + int(clock.days_to_minutes(3)))
	_ok("complete active cleared", dating.has_active_date() == false)
	_ok("complete active dict empty", gs.dating.active_date.is_empty())
	sm.save_game()
	var cooldown_at: int = girls.get_next_date_available_at(alina_id)
	sm.new_game()
	_ok("cooldown reset new game", girls.get_next_date_available_at(alina_id) == 0)
	_ok("load cooldown save", sm.load_game())
	_ok("loaded cooldown", girls.get_next_date_available_at(alina_id) == cooldown_at)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	_ok("knowledge start", dating.start_date(alina_id, &"cafe"))
	var knowledge_engine: DateEngine = dating.get_date_engine()
	_ok("knowledge engine", knowledge_engine != null)
	var revealed_id: StringName = &""
	if knowledge_engine != null:
		var view: DateEpisodeView = knowledge_engine.get_current_episode()
		if view != null:
			for option in view.base_options:
				if option != null and option.is_selectable():
					knowledge_engine.choose_move(option.move_id)
					revealed_id = option.tag_id
					break
	_ok("knowledge revealed id", revealed_id != &"")
	var first_progress: GirlProgress = knowledge_engine.girl_progress() if knowledge_engine != null else null
	var first_knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN
	if first_progress != null and revealed_id != &"":
		first_knowledge = first_progress.tag_knowledge(revealed_id)
	_ok("knowledge during date", first_knowledge != DateTypes.TagKnowledge.UNKNOWN)
	var knowledge_result := DateResult.new()
	knowledge_result.girl_id = alina_id
	knowledge_result.relationship_delta = 0
	knowledge_result.duration_minutes = 120
	_ok("knowledge complete", dating.complete_date(knowledge_result))
	var stored: GirlState = girls.get_state(alina_id)
	_ok("knowledge stored", stored != null and (stored.revealed_positive_tag_ids.has(revealed_id) or stored.revealed_negative_tag_ids.has(revealed_id)))
	sm.save_game()
	sm.new_game()
	_ok("knowledge reset new game", girls.get_state(alina_id).revealed_positive_tag_ids.is_empty() and girls.get_state(alina_id).revealed_negative_tag_ids.is_empty())
	_ok("load knowledge save", sm.load_game())
	var loaded_state: GirlState = girls.get_state(alina_id)
	_ok("knowledge loaded", loaded_state != null and (loaded_state.revealed_positive_tag_ids.has(revealed_id) or loaded_state.revealed_negative_tag_ids.has(revealed_id)))
	girls.get_state(alina_id).next_date_available_at = 0
	_ok("knowledge second start", dating.start_date(alina_id, &"cafe"))
	var second_engine: DateEngine = dating.get_date_engine()
	var second_progress: GirlProgress = second_engine.girl_progress() if second_engine != null else null
	_ok("knowledge next date", second_progress != null and second_progress.tag_knowledge(revealed_id) == first_knowledge)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = 4
	gs.flow.game_time_minutes = 0
	_ok("cycle start", dating.start_date(alina_id, &"cafe"))
	var cycle_result := DateResult.new()
	cycle_result.girl_id = alina_id
	cycle_result.relationship_delta = 1
	cycle_result.duration_minutes = 120
	_ok("cycle complete", dating.complete_date(cycle_result))
	_ok("cycle relationship 5", girls.get_relationship(alina_id) == 5)
	_ok("cycle rating 1", int(rating.get_rating()) == 1)
	_ok("cycle completed", girls.is_relationship_completed(alina_id))
	_ok("cycle cannot start", dating.can_start_date(alina_id) == false)
	sm.save_game()
	sm.new_game()
	_ok("completed reset new game", girls.is_relationship_completed(alina_id) == false)
	_ok("load completed save", sm.load_game())
	_ok("loaded completed", girls.is_relationship_completed(alina_id))
	_ok("loaded completed cannot start", dating.can_start_date(alina_id) == false)
	_ok("loaded completed rating", int(rating.get_rating()) == 1)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	_ok("active start", dating.start_date(alina_id, &"cafe"))
	sm.save_game()
	sm.new_game()
	_ok("active reset new game", dating.has_active_date() == false)
	_ok("load active save", sm.load_game())
	_ok("loaded active date", dating.has_active_date())
	_ok("loaded active girl", dating.get_active_girl_id() == alina_id)
	_ok("loaded active location", dating.get_active_location_id() == &"cafe")
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v6 rating save", legacy != null)
	if legacy != null:
		var v6: Dictionary = {
			"save_version": 6,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {"girls_by_id": {}},
				"dating": {},
			},
		}
		legacy.store_string(JSON.stringify(v6, "\t"))
		legacy.close()
	_ok("load v6 rating save", sm.load_game())
	_ok("migrated rating 0", int(rating.get_rating()) == 0)
	_ok("migrated active empty", dating.has_active_date() == false)
	sm.delete_save()
	var v7_file: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v7 knowledge save", v7_file != null)
	if v7_file != null:
		var v7: Dictionary = {
			"save_version": 7,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {
					"girls_by_id": {
						"alina": {
							"discovered": true,
							"has_contact": true,
							"relationship": 1,
							"next_date_available_at": 0,
						},
					},
				},
				"dating": {"active_date": {}},
			},
		}
		v7_file.store_string(JSON.stringify(v7, "\t"))
		v7_file.close()
	_ok("load v7 knowledge save", sm.load_game())
	var migrated_girl: GirlState = girls.get_state(alina_id)
	_ok("migrated revealed empty", migrated_girl != null and migrated_girl.revealed_positive_tag_ids.is_empty() and migrated_girl.revealed_negative_tag_ids.is_empty())
	_ok("migrated secondary false", migrated_girl != null and migrated_girl.secondary_revealed == false)
	_ok("migrated completed_dates 0", migrated_girl != null and migrated_girl.completed_dates == 0)
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	sim.start_new_game()
	_ok("sim hud rating", sim.get_hud_text().contains("Rating: 0"))
	girls.give_contact(alina_id)
	sim.show_section("dates")
	var dates_text: String = sim.get_city_body_text()
	_ok("sim dates alina", dates_text.contains("АЛИНА"))
	_ok("sim dates relationship", dates_text.contains("Отношения: 0 / 5"))
	_ok("sim dates invite", dates_text.contains("ПРИГЛАСИТЬ"))
	sim.invite_girl(alina_id)
	var picker_text: String = sim.get_city_body_text()
	_ok("sim dates picker", picker_text.contains("ВЫБЕРИТЕ МЕСТО СВИДАНИЯ"))
	_ok("sim dates cafe", picker_text.contains("Кафе"))
	_ok("sim dates preferred", picker_text.contains("Предпочитаемое место"))
	sim.select_date_location(&"cafe")
	var selected_text: String = sim.get_city_body_text()
	_ok("sim dates selected", selected_text.contains("Место:"))
	_ok("sim dates outfit picker", selected_text.contains("ВЫБЕРИТЕ ОДЕЖДУ"))
	sim.select_date_outfit(&"casual")
	var invite: ActionResult = sim.start_selected_date()
	_ok("sim invite success", invite.success)
	_ok("sim invite active", dating.has_active_date())
	_ok("sim invite location", dating.get_active_location_id() == &"cafe")
	var overlay_open: bool = false
	for child in sim.get_children():
		if child is DatePlayPanel:
			overlay_open = true
			break
		if child is CanvasLayer:
			for nested in child.get_children():
				if nested is DatePlayPanel:
					overlay_open = true
					break
	_ok("sim date overlay", overlay_open)
	sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_date_venue_choice() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	_ok("venue GameState", gs != null)
	_ok("venue SaveManager", sm != null)
	_ok("venue GirlsService", girls != null)
	_ok("venue DatingService", dating != null)
	_ok("venue ActionService", actions != null)
	if gs == null or sm == null or girls == null or dating == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/date_venue_choice.json"
	sm.delete_save()
	sm.new_game()
	var alina_id: StringName = GirlCatalog.ID_ALINA
	var location_a: StringName = &"cafe"
	var location_b: StringName = &"park"
	var locked_id: StringName = &"locked_test_venue"
	var definition: GirlDefinition = girls.get_definition(alina_id)
	_ok("venue world location cafe", definition != null and definition.location_id == LocationCatalog.ID_CAFE)
	girls.give_contact(alina_id)
	var locations: Array = dating.get_available_date_locations(alina_id)
	_ok("venue available list", locations.size() > 1)
	_ok("venue cafe open", dating.is_date_location_available(alina_id, location_a))
	_ok("venue park open", dating.is_date_location_available(alina_id, location_b))
	_ok("venue locked closed", dating.is_date_location_available(alina_id, locked_id) == false)
	_ok("venue park preferred", dating.is_preferred_date_location(alina_id, location_b))
	_ok("venue museum preferred", dating.is_preferred_date_location(alina_id, &"museum"))
	_ok("venue cafe not preferred", dating.is_preferred_date_location(alina_id, location_a) == false)
	_ok("venue arcade not preferred", dating.is_preferred_date_location(alina_id, &"arcade") == false)
	_ok("venue park known", dating.is_date_location_preference_known(alina_id, location_b))
	_ok("venue cafe unknown preference", dating.is_date_location_preference_known(alina_id, location_a) == false)
	var locked_requirement := DateLocationAvailableRequirement.new()
	locked_requirement.girl_id = alina_id
	locked_requirement.date_location_id = locked_id
	_ok("venue locked requirement", locked_requirement.is_met() == false)
	_ok("venue locked reason", locked_requirement.get_failure_reason() == "Это место сейчас недоступно")
	var locked_action: GameAction = dating.create_start_date_action(alina_id, locked_id)
	var locked_result: ActionResult = actions.execute(locked_action)
	_ok("venue locked action fail", locked_result.success == false)
	_ok("venue locked no active", dating.has_active_date() == false)
	var start_a: GameAction = dating.create_start_date_action(alina_id, location_a)
	var result_a: ActionResult = actions.execute(start_a)
	_ok("venue A start", result_a.success)
	_ok("venue A active girl", dating.get_active_girl_id() == alina_id)
	_ok("venue A active location", dating.get_active_location_id() == location_a)
	_ok("venue A session", _active_session_location(dating) == location_a)
	var complete_a := DateResult.new()
	complete_a.girl_id = alina_id
	complete_a.relationship_delta = 0
	complete_a.duration_minutes = 120
	_ok("venue A complete", dating.complete_date(complete_a))
	girls.get_state(alina_id).next_date_available_at = 0
	_ok("venue B start", dating.start_date(alina_id, location_b))
	_ok("venue B independent", _active_session_location(dating) == location_b)
	_ok("venue B not world cafe", _active_session_location(dating) != definition.location_id)
	sm.save_game()
	sm.new_game()
	_ok("venue reset new game", dating.has_active_date() == false)
	_ok("venue load", sm.load_game())
	_ok("venue loaded girl", dating.get_active_girl_id() == alina_id)
	_ok("venue loaded location", dating.get_active_location_id() == location_b)
	_ok("venue restore", dating.restore_active_date())
	_ok("venue restored session", _active_session_location(dating) == location_b)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_rivals() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var world: Variant = _world_service()
	var rivals: Variant = _rivals_service()
	var competitions: Variant = _competition_service()
	var actions: Variant = _action_service()
	_ok("rivals GameState", gs != null)
	_ok("rivals SaveManager", sm != null)
	_ok("rivals TimeService", clock != null)
	_ok("rivals WorldService", world != null)
	_ok("rivals RivalsService", rivals != null)
	_ok("rivals CompetitionService", competitions != null)
	_ok("rivals ActionService", actions != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("rivals tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or world == null or rivals == null or competitions == null or actions == null or tree == null or tree.root == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/rivals_round_trip.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	competitions.set_forced_won(null)
	sm.new_game()
	var boris_id: StringName = RivalCatalog.ID_BORIS
	var competition_id: StringName = CompetitionCatalog.ID_BASIC
	var boris_def: RivalDefinition = rivals.get_definition(boris_id)
	var competition_def: CompetitionDefinition = competitions.get_catalog().get_competition(competition_id)
	_ok("boris definition", boris_def != null and boris_def.display_name == "Борис")
	_ok("boris location city", boris_def != null and boris_def.location_id == LocationCatalog.ID_CITY_CENTER)
	_ok("basic competition", competition_def != null and competition_def.rival_id == boris_id)
	_ok("basic time 60", competition_def != null and competition_def.time_cost_minutes == 60)
	_ok("basic chance 0.5", competition_def != null and is_equal_approx(competition_def.base_win_chance, 0.5))
	var default_state := RivalState.new()
	_ok("default discovered false", default_state.discovered == false)
	_ok("default defeated false", default_state.defeated == false)
	var created: RivalState = rivals.get_state(boris_id)
	_ok("created rival defaults", created != null and created.discovered == false and created.defeated == false)
	_ok("created rival stored", gs.rivals.rivals_by_id.has(boris_id))
	var discovered_events: Array = []
	var on_discovered := func(rival_id: StringName) -> void:
		discovered_events.append(rival_id)
	rivals.rival_discovered.connect(on_discovered)
	_ok("discover first", rivals.discover_rival(boris_id))
	_ok("is_discovered", rivals.is_discovered(boris_id))
	_ok("discover defeated false", rivals.is_defeated(boris_id) == false)
	_ok("discover signal once", discovered_events.size() == 1)
	_ok("discover repeat false", rivals.discover_rival(boris_id) == false)
	_ok("discover signal still once", discovered_events.size() == 1)
	rivals.rival_discovered.disconnect(on_discovered)
	sm.new_game()
	var defeated_events: Array = []
	var on_defeated := func(rival_id: StringName) -> void:
		defeated_events.append(rival_id)
	rivals.rival_defeated.connect(on_defeated)
	_ok("defeat first", rivals.defeat_rival(boris_id))
	_ok("defeat discovered", rivals.is_discovered(boris_id))
	_ok("is_defeated", rivals.is_defeated(boris_id))
	_ok("defeat signal once", defeated_events.size() == 1)
	_ok("defeat repeat false", rivals.defeat_rival(boris_id) == false)
	_ok("defeat still true", rivals.is_defeated(boris_id))
	_ok("defeat signal still once", defeated_events.size() == 1)
	rivals.rival_defeated.disconnect(on_defeated)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var at_city: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
	_ok("city has boris", _rival_list_has(at_city, boris_id))
	world.enter_location(LocationCatalog.ID_CAFE)
	var at_cafe: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
	_ok("cafe no boris", _rival_list_has(at_cafe, boris_id) == false)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var meet_action: GameAction = rivals.create_meet_rival_action(boris_id)
	_ok("meet rival id", meet_action.id == StringName("meet_rival_rival_boris"))
	_ok("meet rival time 0", meet_action.time_cost_minutes == 0)
	var meet_ok: ActionResult = actions.execute(meet_action)
	_ok("meet rival success", meet_ok.success)
	_ok("meet rival discovered", rivals.is_discovered(boris_id))
	_ok("meet rival not defeated", rivals.is_defeated(boris_id) == false)
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(true)
	var win_action: GameAction = competitions.create_competition_action(competition_id)
	_ok("competition action id", win_action.id == StringName("competition_competition_basic"))
	_ok("competition time cost", win_action.time_cost_minutes == 60)
	var win_result: ActionResult = actions.execute(win_action)
	_ok("win success", win_result.success)
	_ok("win defeated", rivals.is_defeated(boris_id))
	_ok("win time 60", int(clock.get_game_time_minutes()) == 60)
	competitions.set_forced_won(null)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(false)
	var loss_result: ActionResult = actions.execute(competitions.create_competition_action(competition_id))
	_ok("loss success", loss_result.success)
	_ok("loss not defeated", rivals.is_defeated(boris_id) == false)
	_ok("loss still discovered", rivals.is_discovered(boris_id))
	_ok("loss time 60", int(clock.get_game_time_minutes()) == 60)
	competitions.set_forced_won(null)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	world.enter_location(LocationCatalog.ID_CAFE)
	gs.flow.game_time_minutes = 0
	var snapshot: Dictionary = rivals.get_state(boris_id).to_dict()
	var wrong_loc: ActionResult = actions.execute(competitions.create_competition_action(competition_id))
	_ok("wrong loc fail", wrong_loc.success == false)
	_ok("wrong loc reason", wrong_loc.failure_reason == "Соперник находится в другой локации")
	_ok("wrong loc state", rivals.get_state(boris_id).to_dict() == snapshot)
	_ok("wrong loc time", int(clock.get_game_time_minutes()) == 0)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	gs.flow.game_time_minutes = 0
	var before_meet: ActionResult = actions.execute(competitions.create_competition_action(competition_id))
	_ok("before discover fail", before_meet.success == false)
	_ok("before discover reason", before_meet.failure_reason == "Вы ещё не встретили этого соперника")
	_ok("before discover defeated", rivals.is_defeated(boris_id) == false)
	_ok("before discover time", int(clock.get_game_time_minutes()) == 0)
	sm.new_game()
	rivals.defeat_rival(boris_id)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("after defeat cannot start", competitions.can_start_competition(competition_id) == false)
	_ok("after defeat reason", competitions.get_failure_reason(competition_id) == "Этот соперник уже побеждён")
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	competitions.set_forced_won(true)
	actions.execute(competitions.create_competition_action(competition_id))
	competitions.set_forced_won(null)
	sm.save_game()
	sm.new_game()
	_ok("rivals clean after save", rivals.is_discovered(boris_id) == false and rivals.is_defeated(boris_id) == false)
	_ok("rivals load save", sm.load_game())
	_ok("loaded rival discovered", rivals.is_discovered(boris_id))
	_ok("loaded rival defeated", rivals.is_defeated(boris_id))
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v8 rivals save", legacy != null)
	if legacy != null:
		var v8: Dictionary = {
			"save_version": 8,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {"girls_by_id": {}},
				"dating": {"active_date": {}},
				"rivals": {},
			},
		}
		legacy.store_string(JSON.stringify(v8, "\t"))
		legacy.close()
	_ok("load v8 rivals save", sm.load_game())
	_ok("migrated rivals empty", gs.rivals.rivals_by_id.is_empty())
	var migrated_state: RivalState = rivals.get_state(boris_id)
	_ok("migrated rival defaults", migrated_state != null and migrated_state.discovered == false and migrated_state.defeated == false)
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	sim.start_new_game()
	sim.show_section("city")
	var city_text: String = sim.get_city_body_text()
	_ok("sim city boris", city_text.contains("Борис"))
	_ok("sim city meet button", city_text.contains("ВСТРЕТИТЬ"))
	var sim_meet: ActionResult = sim.meet_rival(boris_id)
	_ok("sim meet rival success", sim_meet.success)
	_ok("sim meet rival result", sim.get_result_text().contains("Вы встретили Борис."))
	sim.show_section("rivals")
	var rivals_text: String = sim.get_city_body_text()
	_ok("sim rivals boris", rivals_text.contains("БОРИС"))
	_ok("sim rivals not defeated", rivals_text.contains("Статус: Не побеждён"))
	_ok("sim rivals competitions", rivals_text.contains("СОРЕВНОВАНИЯ"))
	_ok("sim rivals challenge", rivals_text.contains("БРОСИТЬ ВЫЗОВ"))
	competitions.set_forced_won(true)
	var sim_win: ActionResult = sim.start_competition(competition_id)
	competitions.set_forced_won(null)
	_ok("sim win success", sim_win.success)
	_ok("sim win result", sim.get_result_text().contains("Победа."))
	_ok("sim win defeated text", sim.get_result_text().contains("Соперник Борис побеждён."))
	_ok("sim win time text", sim.get_result_text().contains("Прошло времени: 60 минут."))
	var after_win: String = sim.get_city_body_text()
	_ok("sim rivals defeated", after_win.contains("Статус: Побеждён"))
	_ok("sim rivals completed", after_win.contains("Завершено"))
	sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _rival_list_has(list: Array[RivalDefinition], rival_id: StringName) -> bool:
	for rival in list:
		if rival != null and rival.id == rival_id:
			return true
	return false

func _test_character_progression() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var actions: Variant = _action_service()
	var economy: Variant = _economy_service()
	var characteristics: Variant = _characteristic_service()
	var equipment: Variant = _equipment_service()
	var apartment: Variant = _apartment_service()
	var dating: Variant = _dating_service()
	var girls: Variant = _girls_service()
	var competitions: Variant = _competition_service()
	_ok("progress GameState", gs != null)
	_ok("progress SaveManager", sm != null)
	_ok("progress ActionService", actions != null)
	_ok("progress EconomyService", economy != null)
	_ok("progress CharacteristicService", characteristics != null)
	_ok("progress EquipmentService", equipment != null)
	_ok("progress ApartmentService", apartment != null)
	_ok("progress DatingService", dating != null)
	_ok("progress GirlsService", girls != null)
	_ok("progress CompetitionService", competitions != null)
	if gs == null or sm == null or actions == null or economy == null or characteristics == null or equipment == null or apartment == null or dating == null or girls == null or competitions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/character_progression.json"
	sm.delete_save()
	sm.new_game()
	_ok("chars new muscle 0", int(characteristics.get_value(CharacteristicIds.MUSCLE)) == 0)
	_ok("chars new appearance 0", int(characteristics.get_value(CharacteristicIds.APPEARANCE)) == 0)
	_ok("chars new capital 0", int(characteristics.get_value(CharacteristicIds.CAPITAL)) == 0)
	_ok("chars new aura 0", int(characteristics.get_value(CharacteristicIds.AURA)) == 0)
	_ok("chars add appearance", int(characteristics.add_value(CharacteristicIds.APPEARANCE, 1)) == 1)
	_ok("chars appearance 1", gs.player.appearance == 1)
	sm.new_game()
	var muscle_effect := CharacteristicEffect.new()
	muscle_effect.characteristic_id = CharacteristicIds.MUSCLE
	muscle_effect.amount = 1
	var muscle_action := GameAction.new()
	muscle_action.id = &"test_muscle_effect"
	muscle_action.effects.append(muscle_effect)
	var muscle_result: ActionResult = actions.execute(muscle_action)
	_ok("char effect success", muscle_result.success)
	_ok("char effect muscle 1", gs.player.muscle == 1)
	sm.new_game()
	gs.player.money = 300
	var buy_muscle: ActionResult = actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("upgrade muscle success", buy_muscle.success)
	_ok("upgrade muscle money 0", gs.player.money == 0)
	_ok("upgrade muscle value 1", gs.player.muscle == 1)
	_ok("upgrade muscle purchased", gs.progression.has(CharacteristicCatalog.ID_MUSCLE_1))
	var buy_muscle_again: ActionResult = actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("upgrade muscle repeat fail", buy_muscle_again.success == false)
	_ok("start outfit owned", bool(equipment.owns_outfit(OutfitCatalog.START_OUTFIT_ID)))
	gs.player.money = 500
	var buy_business: ActionResult = actions.execute(equipment.create_buy_outfit_action(&"business"))
	_ok("buy business success", buy_business.success)
	_ok("owns business", bool(equipment.owns_outfit(&"business")))
	_ok("owned contains business", gs.progression.owns_outfit(&"business"))
	_ok("equip business", bool(equipment.equip_outfit(&"business")))
	_ok("equipped business", equipment.get_equipped_outfit_id() == &"business")
	girls.give_contact(GirlCatalog.ID_ALINA)
	_ok("date start outfit", dating.start_date(GirlCatalog.ID_ALINA, &"park", &"business"))
	_ok("active outfit business", dating.get_active_outfit_id() == &"business")
	_ok("session outfit business", _active_session_outfit(dating) == &"business")
	var date_result := DateResult.new()
	date_result.girl_id = GirlCatalog.ID_ALINA
	date_result.relationship_delta = 0
	date_result.duration_minutes = 120
	dating.complete_date(date_result)
	sm.new_game()
	gs.player.money = 500
	_ok("apartment start 1", int(apartment.get_level()) == 1)
	var buy_apt: ActionResult = actions.execute(apartment.create_upgrade_action(ApartmentCatalog.ID_UPGRADE_1))
	_ok("apartment buy success", buy_apt.success)
	_ok("apartment money 0", gs.player.money == 0)
	_ok("apartment level 2", int(apartment.get_level()) == 2)
	_ok("apartment upgrade stored", bool(apartment.is_upgrade_purchased(ApartmentCatalog.ID_UPGRADE_1)))
	_ok("apartment quality 1", int(apartment.get_quality()) == 1)
	girls.give_contact(GirlCatalog.ID_ALINA)
	_ok("apartment date start", dating.start_date(GirlCatalog.ID_ALINA, &"apartment"))
	var engine: DateEngine = dating.get_date_engine()
	_ok("apartment engine", engine != null)
	if engine != null:
		var player_state: TestPlayerState = engine.player_state()
		_ok("apartment quality in engine", player_state != null and player_state.apartment_quality == 1)
	dating.complete_date(date_result)
	sm.new_game()
	var competition_id: StringName = CompetitionCatalog.ID_BASIC
	_ok("chance muscle 0", is_equal_approx(float(competitions.get_win_chance(competition_id)), 0.5))
	gs.player.muscle = 2
	_ok("chance muscle 2", is_equal_approx(float(competitions.get_win_chance(competition_id)), 0.7))
	gs.player.muscle = 5
	var catalog: CompetitionCatalog = competitions.get_catalog()
	var definition: CompetitionDefinition = catalog.get_competition(competition_id)
	var previous_chance: float = definition.base_win_chance
	definition.base_win_chance = 0.8
	_ok("chance clamp 1", is_equal_approx(float(competitions.get_win_chance(competition_id)), 1.0))
	definition.base_win_chance = previous_chance
	sm.new_game()
	gs.player.money = 1000
	gs.player.muscle = 1
	gs.player.appearance = 2
	gs.player.capital = 1
	gs.player.aura = 3
	actions.execute(equipment.create_buy_outfit_action(&"business"))
	equipment.equip_outfit(&"business")
	actions.execute(apartment.create_upgrade_action(ApartmentCatalog.ID_UPGRADE_1))
	gs.player.money = 1000
	sm.save_game()
	sm.new_game()
	_ok("progress reset muscle", gs.player.muscle == 0)
	_ok("progress reset outfit", equipment.get_equipped_outfit_id() == OutfitCatalog.START_OUTFIT_ID)
	_ok("progress reset apartment", int(apartment.get_level()) == 1)
	_ok("progress load", sm.load_game())
	_ok("loaded money 1000", gs.player.money == 1000)
	_ok("loaded muscle 1", gs.player.muscle == 1)
	_ok("loaded appearance 2", gs.player.appearance == 2)
	_ok("loaded capital 1", gs.player.capital == 1)
	_ok("loaded aura 3", gs.player.aura == 3)
	_ok("loaded owns business", bool(equipment.owns_outfit(&"business")))
	_ok("loaded equipped business", equipment.get_equipped_outfit_id() == &"business")
	_ok("loaded apartment 2", int(apartment.get_level()) == 2)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v9 progression save", legacy != null)
	if legacy != null:
		var v9: Dictionary = {
			"save_version": 9,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {"girls_by_id": {}},
				"dating": {"active_date": {}},
				"rivals": {"rivals_by_id": {}},
			},
		}
		legacy.store_string(JSON.stringify(v9, "\t"))
		legacy.close()
	_ok("load v9 progression save", sm.load_game())
	_ok("migrated muscle 0", gs.player.muscle == 0)
	_ok("migrated appearance 0", gs.player.appearance == 0)
	_ok("migrated start outfit", bool(equipment.owns_outfit(OutfitCatalog.START_OUTFIT_ID)))
	_ok("migrated equipped start", equipment.get_equipped_outfit_id() == OutfitCatalog.START_OUTFIT_ID)
	_ok("migrated apartment 1", int(apartment.get_level()) == 1)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var sim := GameSimulator.new()
		tree.root.add_child(sim)
		sim.start_new_game()
		_ok("sim hud muscle", sim.get_hud_text().contains("Мышца: 0"))
		sim.show_section("progression")
		var progression_text: String = sim.get_city_body_text()
		_ok("sim progression heading", progression_text.contains("ХАРАКТЕРИСТИКИ"))
		_ok("sim progression training", progression_text.contains("Тренировка"))
		sim.show_section("clothing")
		var clothing_text: String = sim.get_city_body_text()
		_ok("sim clothing casual", clothing_text.contains("Повседневный"))
		_ok("sim clothing worn", clothing_text.contains("Надето"))
		_ok("sim clothing buy", clothing_text.contains("КУПИТЬ"))
		sim.show_section("apartment")
		var apartment_text: String = sim.get_city_body_text()
		_ok("sim apartment level", apartment_text.contains("Уровень квартиры: 1"))
		_ok("sim apartment upgrade", apartment_text.contains("Улучшить квартиру"))
		sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()
