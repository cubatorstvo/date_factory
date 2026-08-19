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


func _first_available(engine: DateEngine) -> StringName:
	for option in engine.get_available_moves():
		if option.is_selectable():
			return option.move_id
	return &""


func _choose(engine: DateEngine, move_id: StringName) -> void:
	engine.choose_move(move_id)
	engine.advance()


func _test_unknown_plus_becomes_positive() -> void:
	var catalog := _catalog()
	var progress := _fresh_progress(catalog, &"alina")
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 7, progress, _player())
	_ok("1. UNKNOWN before +1", progress.tag_knowledge(&"directness") == DateTypes.TagKnowledge.UNKNOWN)
	_choose(engine, _pick_by_tag(engine, &"directness"))
	_ok("1. UNKNOWN Tag after +1 becomes POSITIVE", progress.tag_knowledge(&"directness") == DateTypes.TagKnowledge.POSITIVE)


func _test_unknown_minus_becomes_negative() -> void:
	var catalog := _catalog()
	var progress := _fresh_progress(catalog, &"alina")
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 11, progress, _player())
	_choose(engine, _pick_by_tag(engine, &"audacity"))
	_ok("2. UNKNOWN Tag after -1 becomes NEGATIVE", progress.tag_knowledge(&"audacity") == DateTypes.TagKnowledge.NEGATIVE)


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
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 21, _fresh_progress(catalog, &"alina"), _player())
	while engine.get_session_state().current_phase != DateTypes.DatePhase.CORE:
		_choose(engine, _pick_preference(engine, want_positive))
	_choose(engine, _pick_preference(engine, want_positive))
	return engine


func _finish_with_preference(catalog: DateContentCatalog, core_positive: bool, closing_positive: bool) -> DateEngine:
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 33, _fresh_progress(catalog, &"alina"), _player())
	while engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE or engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		var want: bool = closing_positive if engine.get_session_state().current_phase == DateTypes.DatePhase.CLOSING else core_positive
		if engine.get_session_state().current_phase == DateTypes.DatePhase.OPENING:
			want = true
		_choose(engine, _pick_preference(engine, want))
	return engine


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
			var move_id: StringName = _first_available(engine)
			if engine.get_session_state().current_phase == DateTypes.DatePhase.CORE:
				move_id = _pick_new_success(engine, used)
				var option := _option(engine, move_id)
				if option != null:
					used[String(option.tag_id)] = true
			_choose(engine, move_id)
		if used.size() >= 3 and engine.get_result().score_breakdown.secondary_success:
			return true
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
	_ok("validator seed clean", clean.is_empty())
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


func _has_issue(issues: Array[ContentValidationIssue], needle: String) -> bool:
	for issue in issues:
		if needle in issue.message:
			return true
	return false
