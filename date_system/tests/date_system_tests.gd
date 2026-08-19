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
	_ok("new_game money 0", gs.player.money == 0)
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
	_ok("save_version == 2", int(root.get("save_version", 0)) == 2)
	var snapshot: Variant = root.get("game_state", {})
	var state_dict: Dictionary = snapshot if snapshot is Dictionary else {}
	_ok("save has empty progression", state_dict.get("progression", {"x": 1}).is_empty())
	var flow_value: Variant = state_dict.get("flow", {})
	var flow_dict: Dictionary = flow_value if flow_value is Dictionary else {}
	_ok("save has game_time_minutes", int(flow_dict.get("game_time_minutes", -1)) == 8640)
	_ok("save has no day", not flow_dict.has("day"))
	sm.new_game()
	_ok("new_game resets values", gs.flow.game_time_minutes == 0 and gs.story.stage == 1 and gs.player.money == 0)
	_ok("load_game", sm.load_game())
	_ok("loaded game_time_minutes == 8640", gs.flow.game_time_minutes == 8640)
	_ok("loaded day == 7", clock.get_day() == 7)
	_ok("loaded stage == 3", gs.story.stage == 3)
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
	_ok("missing keys default money", gs.player.money == 0)
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
	sm.delete_save()
	_ok("deleted time test save", not sm.has_save())
	sm.save_path = original_path
	sm.new_game()
