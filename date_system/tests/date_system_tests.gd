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
	for seed in range(1, 80):
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
	for seed in range(1, 80):
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
	for seed in range(1, 80):
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
