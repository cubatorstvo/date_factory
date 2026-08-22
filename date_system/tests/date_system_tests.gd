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
	_test_situation_owned_architecture()
	_test_cleanup_contracts()
	_test_characteristic_moves()
	_test_character_build_sources()
	_test_mapping_tags_differ_by_situation()
	_test_combo_rules()
	_test_venue_outfit_apartment()
	_test_local_moves()
	_test_relationship_clamp_and_reset()
	_test_replay_seed()
	_test_saved_resource_reload()
	_test_validator()
	_test_characteristic_tag_reservation()
	_test_twelve_tag_rebalance()
	_test_girl_difficulty()
	_test_dating_core_model()
	_test_catalog_snapshot()
	_test_game_state_round_trip()
	_test_game_time()
	_test_campaign_stages()
	_test_stage_story_rules()
	_test_game_actions()
	_test_game_simulator()
	_test_economy()
	_test_world()
	_test_girls()
	_test_dating_and_rating()
	_test_girl_access_requirements()
	_test_date_venue_choice()
	_test_venues_and_local_objects()
	_test_progression_integration()
	_test_rivals()
	_test_home_city_catalog_consistency()
	_test_rating_meet_gates()
	_test_story_rival_visibility()
	_test_restaurant_stage_unlock()
	_test_dates_for_home_city_girls()
	_test_manual_progression_sonya_path()
	_test_manual_progression_factory_rating_path()
	_test_skip_to_08_00()
	_test_character_progression()
	_test_filler_girl_rewards()
	_test_city_density_progression()
	_test_automation()
	_test_availability_ui()
	_test_game_terms()
	_test_objectives()
	_test_guidance()
	_test_objective_markers()
	_test_semantic_cleanup()
	_test_playtest_daily_activity()
	return _failures


func _test_cleanup_contracts() -> void:
	var catalog: DateContentCatalog = _catalog()
	var situation: DateSituation = catalog.find_situation(&"appearance_question")
	_ok("cleanup situation owns six BASE", situation != null and situation.base_move_ids.size() == 6)
	var move: DateMove = catalog.find_move(situation.base_move_ids[0]) if situation != null else null
	_ok(
		"cleanup resolved fixed api",
		move != null
		and move.has_fixed_presentation()
		and move.resolved_tag_id() != &""
		and not move.resolved_option_text().strip_edges().is_empty()
		and not move.resolved_positive_result_text().strip_edges().is_empty()
		and not move.resolved_negative_result_text().strip_edges().is_empty()
	)
	_ok("cleanup situation-owned lookup", catalog.base_moves_for_situation(&"appearance_question").size() == 6)
	var base_count: int = 0
	for item in catalog.moves:
		if item != null and item.enabled and item.is_base():
			base_count += 1
	_ok("cleanup 180 baseline BASE", base_count == 180)
	var validator := ContentValidator.new()
	_ok("cleanup catalog validates without mapping layer", not _has_error(validator.validate(catalog)))
	var alina: GirlProfile = catalog.find_girl(GirlCatalog.ID_ALINA)
	var actress: GirlProfile = catalog.find_girl(GirlCatalog.ID_ACTRESS)
	_ok("cleanup alina known from profile", alina != null and alina.initial_known_tag_count == 2)
	_ok("cleanup actress known from profile", actress != null and actress.initial_known_tag_count == 0)
	var girls: Variant = _girls_service()
	if girls != null:
		_ok("cleanup effective alina", int(girls.get_effective_initial_known_tag_count(GirlCatalog.ID_ALINA)) == 2)
		_ok("cleanup effective actress", int(girls.get_effective_initial_known_tag_count(GirlCatalog.ID_ACTRESS)) == 0)


func _test_semantic_cleanup() -> void:
	var catalog := _catalog()
	var move: DateMove = catalog.find_move(&"char_hold_pause")
	_ok("semantic characteristic kind", move != null and move.is_characteristic() and move.kind == DateTypes.DateMoveKind.CHARACTERISTIC)
	_ok("semantic fixed presentation", move != null and move.has_fixed_presentation() and move.fixed_tag_id == &"composure" and not move.fixed_option_text.strip_edges().is_empty())
	var cafe: DateVenue = catalog.find_venue(&"cafe")
	_ok("semantic date venue", cafe != null and cafe.id == &"cafe")
	var player := _player()
	player.muscle = 5
	player.appearance = 5
	player.capital = 5
	player.aura = 5
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 11, _fresh_progress(catalog, &"alina"), player)
	var view := engine.get_current_episode()
	var has_characteristic := false
	var has_venue := false
	if view != null:
		for source_view in view.source_views:
			if source_view.source == DateTypes.DateMoveSource.CHARACTERISTIC:
				has_characteristic = true
			elif source_view.source == DateTypes.DateMoveSource.VENUE:
				has_venue = true
	_ok("semantic source characteristic", has_characteristic)
	_ok("semantic source venue", has_venue)
	var rules: DateRules = catalog.date_rules
	_ok("semantic shared scores", rules != null and rules.positive_move_score == 1 and rules.negative_move_score == -1)
	var char_option: DateMoveOption = null
	if view != null:
		for option in _source_options(view, DateTypes.DateMoveSource.CHARACTERISTIC):
			if option.is_selectable():
				char_option = option
				break
	if char_option != null:
		engine.choose_move(char_option.move_id)
		engine.advance()
		_ok("semantic characteristic source spent", engine.get_session_state().characteristic_source_used)
	else:
		_ok("semantic characteristic source spent", false)
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT and engine.get_session_state().stage != DateSession.Stage.COMPLETED and engine.get_session_state().stage != DateSession.Stage.ABORTED:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		var move_id: StringName = _first_available(engine)
		if move_id == &"":
			break
		engine.choose_move(move_id)
	if engine.get_session_state().stage == DateSession.Stage.SHOWING_DATE_RESULT:
		engine.advance()
	_ok("semantic date completes", engine.get_result() != null)


func _test_game_terms() -> void:
	var catalog := _catalog()
	var registry := GameTermRegistry.from_catalog(catalog)
	var humor: GameTerm = registry.find_by_alias("ЮМОР")
	_ok("ЮМОР is DateTag Game Term", humor != null and humor.category == GameTerm.Category.TAG and humor.id == &"humor")
	var muscle: GameTerm = registry.find_by_alias("Мышца")
	_ok("Мышца is CharacteristicDefinition Game Term", muscle != null and muscle.category == GameTerm.Category.STAT and muscle.id == &"muscle")
	var rating: GameTerm = registry.find_by_alias("Рейтинг")
	_ok("Рейтинг is system Game Term", rating != null and rating.category == GameTerm.Category.SYSTEM and rating.id == &"rating")
	var factory_term: GameTerm = registry.find_by_alias("Date Factory")
	_ok("Date Factory is system Game Term", factory_term != null and factory_term.category == GameTerm.Category.SYSTEM and factory_term.id == &"date_factory")
	var tag_term: GameTerm = registry.find_by_alias("тег")
	_ok("тег is system Game Term", tag_term != null and tag_term.category == GameTerm.Category.SYSTEM and tag_term.id == &"tag")
	var outfit_term: GameTerm = registry.find_by_alias("Одежда")
	_ok("Одежда is system Game Term", outfit_term != null and outfit_term.category == GameTerm.Category.SYSTEM and outfit_term.id == &"outfit")
	_ok("tooltip description", rating != null and not rating.description.strip_edges().is_empty())
	var longest: GameTerm = GameTermFormatter.longest_alias_term("Этап города", registry)
	_ok("longest alias wins", longest != null and longest.id == &"city_stage")
	var positive: String = GameTermFormatter.format_bbcode("ЮМОР", {&"humor": DateTypes.TagKnowledge.POSITIVE}, registry)
	var negative: String = GameTermFormatter.format_bbcode("ЮМОР", {&"humor": DateTypes.TagKnowledge.NEGATIVE}, registry)
	var unknown: String = GameTermFormatter.format_bbcode("ЮМОР", {}, registry)
	_ok("positive tag color", positive.contains(LabUi.POSITIVE.to_html(false)))
	_ok("negative tag color", negative.contains(LabUi.NEGATIVE.to_html(false)))
	_ok("unknown tag stays bold", unknown.contains("[b]") and not unknown.contains(LabUi.POSITIVE.to_html(false)))
	var formatted: String = GameTermFormatter.format_bbcode("ЮМОР Мышца Рейтинг КОМБО Одежда", {}, registry)
	_ok("bold Game Term spans", formatted.contains("[b]") and formatted.contains("game_term:humor") and formatted.contains("game_term:muscle") and formatted.contains("game_term:rating") and formatted.contains("game_term:combo") and formatted.contains("game_term:outfit"))
	var tag_aliases: PackedStringArray = PackedStringArray()
	if tag_term != null:
		tag_aliases = registry.aliases_of(tag_term)
	_ok("term id is not a text alias", not tag_aliases.has("tag"))
	_ok("Stage: 1 has no GameTerm", GameTermFormatter.longest_alias_term("Stage: 1", registry) == null)
	_ok("Stage: 1 stays plain", not GameTermFormatter.format_bbcode("Stage: 1", {}, registry).contains("game_term:"))
	var stage_hit: GameTerm = GameTermFormatter.longest_alias_term("Stage", registry)
	_ok("tag is not detected inside Stage", stage_hit == null or stage_hit.id != &"tag")
	var standalone_tag: GameTerm = GameTermFormatter.longest_alias_term("тег", registry)
	_ok("standalone тег is GameTerm tag", standalone_tag != null and standalone_tag.id == &"tag")
	var humor_bracket: GameTerm = GameTermFormatter.longest_alias_term("[ЮМОР]", registry)
	_ok("[ЮМОР] is GameTerm humor", humor_bracket != null and humor_bracket.id == &"humor")
	var humor_bb: String = GameTermFormatter.format_bbcode("[ЮМОР]", {}, registry)
	_ok("[ЮМОР] keeps brackets", humor_bb.contains("game_term:humor") and humor_bb.contains("[lb]") and humor_bb.contains("[rb]"))
	var rating_hit: GameTerm = GameTermFormatter.longest_alias_term("Рейтинг", registry)
	_ok("Рейтинг stays a GameTerm", rating_hit != null and rating_hit.id == &"rating")


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


func _player() -> DatePlayerSnapshot:
	return DatePlayerSnapshot.new()


func _start(catalog: DateContentCatalog, girl_id: StringName, venue_id: StringName, outfit_id: StringName, seed: int, progress: GirlProgress, player: DatePlayerSnapshot, forced_situation_id: StringName = &"") -> DateEngine:
	var engine := DateEngine.new()
	var config := DateSessionConfig.new()
	config.catalog = catalog
	config.girl_id = girl_id
	config.venue_id = venue_id
	config.outfit_id = outfit_id
	config.seed = seed
	config.girl_progress = progress
	config.player_snapshot = player
	config.relationship_max = GirlCatalog.seed_relationship_max(girl_id)
	config.forced_situation_id = forced_situation_id
	var venue: DateVenue = catalog.find_venue(venue_id)
	if venue != null:
		config.local_object_ids = venue.local_object_ids.duplicate()
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


func _pick_unknown_preference(engine: DateEngine, want_positive: bool) -> StringName:
	var girl: GirlProfile = engine.catalog().find_girl(engine.get_session_state().girl_id)
	var progress: GirlProgress = engine.girl_progress()
	for option in engine.get_available_moves():
		if not option.is_selectable():
			continue
		if progress.tag_knowledge(option.tag_id, girl) != DateTypes.TagKnowledge.UNKNOWN:
			continue
		var pref: int = girl.prefers_tag(option.tag_id)
		if want_positive and pref > 0:
			return option.move_id
		if not want_positive and pref < 0:
			return option.move_id
	return &""


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

func _episode_option(view: DateEpisodeView, move_id: StringName) -> DateMoveOption:
	if view == null:
		return null
	for option in view.base_options:
		if option.move_id == move_id:
			return option
	for source_view in view.source_views:
		for option in source_view.options:
			if option.move_id == move_id:
				return option
	return null


func _choose(engine: DateEngine, move_id: StringName) -> void:
	engine.choose_move(move_id)
	engine.advance()


func _test_unknown_plus_becomes_positive() -> void:
	var found: bool = false
	for seed in range(1, 80):
		var probe_catalog: DateContentCatalog = _catalog()
		var girl: GirlProfile = probe_catalog.find_girl(&"alina")
		var progress: GirlProgress = _fresh_progress(probe_catalog, &"alina")
		var probe_engine: DateEngine = _start(probe_catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		var move_id: StringName = _pick_unknown_preference(probe_engine, true)
		if move_id == &"":
			continue
		var option: DateMoveOption = _option(probe_engine, move_id)
		_ok("1. UNKNOWN before +1", progress.tag_knowledge(option.tag_id, girl) == DateTypes.TagKnowledge.UNKNOWN)
		_choose(probe_engine, move_id)
		_ok("1. UNKNOWN Tag after +1 becomes POSITIVE", progress.tag_knowledge(option.tag_id, girl) == DateTypes.TagKnowledge.POSITIVE)
		found = true
		break
	_ok("1. found positive selectable Tag", found)


func _test_unknown_minus_becomes_negative() -> void:
	var found: bool = false
	for seed in range(1, 80):
		var catalog := _catalog()
		var girl: GirlProfile = catalog.find_girl(&"alina")
		var progress := _fresh_progress(catalog, &"alina")
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		var move_id: StringName = _pick_unknown_preference(engine, false)
		if move_id == &"":
			continue
		var option: DateMoveOption = _option(engine, move_id)
		_choose(engine, move_id)
		_ok("2. UNKNOWN Tag after -1 becomes NEGATIVE", progress.tag_knowledge(option.tag_id, girl) == DateTypes.TagKnowledge.NEGATIVE)
		found = true
		break
	_ok("2. found negative selectable Tag", found)


func _test_opening_reveals_and_zero() -> void:
	var found: bool = false
	for seed in range(1, 80):
		var catalog := _catalog()
		var progress := _fresh_progress(catalog, &"alina")
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		if engine.get_session_state().current_phase != DateTypes.DatePhase.OPENING:
			continue
		var move_id: StringName = _pick_unknown_preference(engine, true)
		if move_id == &"":
			continue
		_choose(engine, move_id)
		_ok("3. Opening раскрывает Tag", progress.revealed_positive_tag_ids.size() + progress.revealed_negative_tag_ids.size() == 1)
		_ok("4. Opening даёт +1", engine.get_session_state().score_breakdown.opening_scores[0] == 1)
		found = true
		break
	_ok("3/4 found opening reveal", found)


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
	_ok("9. BASE pool equals situation six-move set", pool.size() == 6)
	_ok("10. RNG выбирает 3 BASE", engine.get_session_state().current_selected_base_move_ids.size() == 3)
	_ok("10b. reroll хранит оставшиеся 3", engine.get_session_state().current_reroll_base_move_ids.size() == 3)
	var engine_a := _start(_catalog(), &"alina", &"cafe", &"casual", 77, _fresh_progress(_catalog(), &"alina"), _player())
	var engine_b := _start(_catalog(), &"alina", &"cafe", &"casual", 77, _fresh_progress(_catalog(), &"alina"), _player())
	_ok("11. одинаковый seed воспроизводит BASE selection", engine_a.get_session_state().current_selected_base_move_ids == engine_b.get_session_state().current_selected_base_move_ids)


func _test_situation_owned_architecture() -> void:
	var catalog: DateContentCatalog = _catalog()
	var validator := ContentValidator.new()
	_ok("owned seed has no errors", not _has_error(validator.validate(catalog)))
	var disk: DateContentCatalog = load("res://date_system/content/catalog/date_content_catalog.tres") as DateContentCatalog
	_ok("disk catalog thirty situations", disk != null and disk.enabled_situations().size() == 30)
	_ok("disk catalog no errors", disk != null and not _has_error(validator.validate(disk)))
	var expected_ids: Array[StringName] = [
		&"appearance_question",
		&"awkward_silence",
		&"why_me",
		&"first_compliment",
		&"phone_reminder",
		&"takes_control",
		&"money_request",
		&"spontaneous_bet",
		&"rival_provocation",
		&"terrible_joke",
		&"embarrassing_hobby",
		&"stranger_flirts",
		&"small_rule",
		&"small_lie",
		&"friends_dilemma",
		&"staff_conflict",
		&"compatibility_test",
		&"lost_in_hand",
		&"mistaken_married",
		&"take_photo",
		&"big_money",
		&"choose_for_me",
		&"friend_call",
		&"lights_out",
		&"date_verdict",
		&"see_again",
		&"honest_question",
		&"lost_wallet",
		&"simple_goodbye",
		&"sudden_rain",
	]
	var public_only: Array[StringName] = [
		&"stranger_flirts",
		&"small_rule",
		&"staff_conflict",
		&"mistaken_married",
		&"lost_wallet",
	]
	_ok("owned thirty baseline situations", catalog.enabled_situations().size() == 30)
	var opening: int = 0
	var core: int = 0
	var closing: int = 0
	var tag_counts: Dictionary = {}
	for situation in catalog.enabled_situations():
		if situation.allows_phase(DateTypes.DatePhase.OPENING):
			opening += 1
		if situation.allows_phase(DateTypes.DatePhase.CORE):
			core += 1
		if situation.allows_phase(DateTypes.DatePhase.CLOSING):
			closing += 1
		_ok("owned six moves %s" % String(situation.id), situation.base_move_ids.size() == 6)
		_ok("owned six tags %s" % String(situation.id), _distinct_base_tags(catalog, situation.id) == 6)
		_ok("owned api %s" % String(situation.id), catalog.base_moves_for_situation(situation.id).size() == 6)
		_ok("owned girl filter empty %s" % String(situation.id), situation.allowed_girl_ids.is_empty())
		for move in catalog.base_moves_for_situation(situation.id):
			_ok("owned texts %s" % String(move.id), not move.fixed_option_text.strip_edges().is_empty() and not move.fixed_positive_result_text.strip_edges().is_empty() and not move.fixed_negative_result_text.strip_edges().is_empty())
			var tag_key: String = String(move.fixed_tag_id)
			tag_counts[tag_key] = int(tag_counts.get(tag_key, 0)) + 1
		if public_only.has(situation.id):
			_ok("owned public venues %s" % String(situation.id), situation.allowed_venue_ids.has(&"cafe") and situation.allowed_venue_ids.has(&"leisure_center") and situation.allowed_venue_ids.has(&"restaurant") and not situation.allowed_venue_ids.has(&"apartment"))
		else:
			_ok("owned general venue %s" % String(situation.id), situation.allowed_venue_ids.is_empty())
	_ok("owned phase counts 6/18/6", opening == 6 and core == 18 and closing == 6)
	for tag in catalog.enabled_tags():
		_ok("owned tag count 15 %s" % String(tag.id), int(tag_counts.get(String(tag.id), 0)) == 15)
	_ok("owned opening id", catalog.find_situation(&"appearance_question") != null and catalog.find_situation(&"appearance_question").allows_phase(DateTypes.DatePhase.OPENING))
	_ok("owned closing id", catalog.find_situation(&"date_verdict") != null and catalog.find_situation(&"date_verdict").allows_phase(DateTypes.DatePhase.CLOSING))
	for expected_id in expected_ids:
		_ok("owned situation present %s" % String(expected_id), catalog.find_situation(expected_id) != null)

	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 21, _fresh_progress(catalog, &"alina"), _player())
	engine.get_session_state().vika_reroll_available = true
	var shown: Array[StringName] = engine.get_session_state().current_selected_base_move_ids.duplicate()
	var hidden: Array[StringName] = engine.get_session_state().current_reroll_base_move_ids.duplicate()
	var situation_id: StringName = engine.get_session_state().selected_situation_ids[0]
	var sources_before: Array = [
		engine.get_session_state().characteristic_source_used,
		engine.get_session_state().outfit_source_used,
		engine.get_session_state().venue_source_used,
	]
	_ok("vika swap exact remaining", engine.reroll_base_moves().is_empty() and engine.get_session_state().current_selected_base_move_ids == hidden)
	_ok("vika keeps situation", engine.get_session_state().selected_situation_ids[0] == situation_id)
	_ok("vika keeps sources", engine.get_session_state().characteristic_source_used == sources_before[0] and engine.get_session_state().outfit_source_used == sources_before[1] and engine.get_session_state().venue_source_used == sources_before[2])
	_ok("vika used state", engine.reroll_base_moves() == "Пересборка уже использована на этом свидании.")
	_ok("vika shown changed", engine.get_session_state().current_selected_base_move_ids != shown)
	_ok("owned politeness result", catalog.find_move(&"awkward_silence__how_arrived") != null and catalog.find_move(&"awkward_silence__how_arrived").fixed_positive_result_text == "Ей нравится твоя корректность.")
	for row in [
		[&"appearance_question", DateTypes.DatePhase.OPENING],
		[&"stranger_flirts", DateTypes.DatePhase.CORE],
		[&"date_verdict", DateTypes.DatePhase.CLOSING],
	]:
		var sit_id: StringName = row[0]
		var phase: DateTypes.DatePhase = row[1]
		var any_catalog: DateContentCatalog = _catalog()
		any_catalog.date_rules.opening_episode_count = 1 if phase == DateTypes.DatePhase.OPENING else 0
		any_catalog.date_rules.core_episode_count = 1 if phase == DateTypes.DatePhase.CORE else 0
		any_catalog.date_rules.closing_episode_count = 1 if phase == DateTypes.DatePhase.CLOSING else 0
		var any_engine: DateEngine = _start(any_catalog, &"alina", &"cafe", &"casual", 21, _fresh_progress(any_catalog, &"alina"), _player(), sit_id)
		any_engine.get_session_state().vika_reroll_available = true
		var any_hidden: Array[StringName] = any_engine.get_session_state().current_reroll_base_move_ids.duplicate()
		_ok("vika any %s" % String(sit_id), any_engine.get_session_state().selected_situation_ids[0] == sit_id and any_engine.reroll_base_moves().is_empty() and any_engine.get_session_state().current_selected_base_move_ids == any_hidden)

	var filter_catalog: DateContentCatalog = _catalog()
	_ok("filter general cafe", _eligible_has(filter_catalog, DateTypes.DatePhase.OPENING, &"cafe", &"alina", &"appearance_question"))
	_ok("filter general restaurant", _eligible_has(filter_catalog, DateTypes.DatePhase.OPENING, &"restaurant", &"vika", &"appearance_question"))
	_ok("filter general apartment", _eligible_has(filter_catalog, DateTypes.DatePhase.OPENING, &"apartment", &"alina", &"appearance_question"))
	_ok("public-only cafe", _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"cafe", &"alina", &"stranger_flirts"))
	_ok("public-only leisure_center", _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"leisure_center", &"alina", &"stranger_flirts"))
	_ok("public-only restaurant", _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"restaurant", &"alina", &"stranger_flirts"))
	_ok("public-only apartment out", not _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"apartment", &"alina", &"stranger_flirts"))
	_ok("public-only closing apartment out", not _eligible_has(filter_catalog, DateTypes.DatePhase.CLOSING, &"apartment", &"alina", &"lost_wallet"))
	_ok("public-only closing cafe", _eligible_has(filter_catalog, DateTypes.DatePhase.CLOSING, &"cafe", &"alina", &"lost_wallet"))
	filter_catalog.find_situation(&"money_request").allowed_venue_ids = [&"restaurant"] as Array[StringName]
	_ok("filter venue in", _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"restaurant", &"alina", &"money_request"))
	_ok("filter venue out", not _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"cafe", &"alina", &"money_request"))
	filter_catalog.find_situation(&"money_request").allowed_girl_ids = [&"alina"] as Array[StringName]
	_ok("filter girl+venue match", _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"restaurant", &"alina", &"money_request"))
	_ok("filter girl+venue miss", not _eligible_has(filter_catalog, DateTypes.DatePhase.CORE, &"restaurant", &"vika", &"money_request"))
	var girl_only: DateContentCatalog = _catalog()
	girl_only.find_situation(&"date_verdict").allowed_girl_ids = [&"vika"] as Array[StringName]
	_ok("filter girl-specific in", _eligible_has(girl_only, DateTypes.DatePhase.CLOSING, &"cafe", &"vika", &"date_verdict"))
	_ok("filter girl-specific out", not _eligible_has(girl_only, DateTypes.DatePhase.CLOSING, &"cafe", &"alina", &"date_verdict"))

	var progress: GirlProgress = _fresh_progress(catalog, &"alina")
	var first: DateEngine = _play_full_date(catalog, progress, 44)
	_ok("anti-repeat stores five", first.girl_progress().last_date_situation_ids.size() == 5)
	var first_ids: Array[StringName] = first.girl_progress().last_date_situation_ids.duplicate()
	_ok("five-episode opening", catalog.find_situation(first_ids[0]) != null and catalog.find_situation(first_ids[0]).allows_phase(DateTypes.DatePhase.OPENING))
	_ok("five-episode core 1", catalog.find_situation(first_ids[1]) != null and catalog.find_situation(first_ids[1]).allows_phase(DateTypes.DatePhase.CORE))
	_ok("five-episode core 2", catalog.find_situation(first_ids[2]) != null and catalog.find_situation(first_ids[2]).allows_phase(DateTypes.DatePhase.CORE))
	_ok("five-episode core 3", catalog.find_situation(first_ids[3]) != null and catalog.find_situation(first_ids[3]).allows_phase(DateTypes.DatePhase.CORE))
	_ok("five-episode closing", catalog.find_situation(first_ids[4]) != null and catalog.find_situation(first_ids[4]).allows_phase(DateTypes.DatePhase.CLOSING))
	var second: DateEngine = _play_full_date(catalog, first.girl_progress(), 45)
	_ok("anti-repeat prefers unused opening", second.get_session_state().selected_situation_ids[0] != first_ids[0])
	var opening_ids: Array[StringName] = []
	for situation in catalog.enabled_situations():
		if situation.allows_phase(DateTypes.DatePhase.OPENING):
			opening_ids.append(situation.id)
	var reuse_progress: GirlProgress = GirlProgress.new()
	reuse_progress.reset_to_profile(catalog.find_girl(&"alina"))
	reuse_progress.last_date_situation_ids = opening_ids.duplicate()
	var reuse: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 9, reuse_progress, _player())
	_ok("anti-repeat reuses when preferred empty", opening_ids.has(reuse.get_session_state().selected_situation_ids[0]))


func _eligible_has(catalog: DateContentCatalog, phase: DateTypes.DatePhase, venue_id: StringName, girl_id: StringName, situation_id: StringName) -> bool:
	for situation in catalog.eligible_situations(phase, venue_id, girl_id):
		if situation != null and situation.id == situation_id:
			return true
	return false


func _play_full_date(catalog: DateContentCatalog, progress: GirlProgress, seed: int) -> DateEngine:
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
	var guard: int = 0
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT and engine.get_session_state().stage != DateSession.Stage.COMPLETED and guard < 20:
		guard += 1
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		if engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE:
			_choose(engine, _first_available(engine))
	return engine


func _test_characteristic_moves() -> void:
	var catalog := _catalog()
	var locked_player := _player()
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 8, _fresh_progress(catalog, &"alina"), locked_player)
	var view := engine.get_current_episode()
	_ok("12. Characteristic Moves видны в каждом эпизоде", view != null and _source_options(view, DateTypes.DateMoveSource.CHARACTERISTIC).size() == 12)
	var say_plain: DateMoveOption = _episode_option(view, &"char_say_plain")
	_ok("13. muscle 1 ход присутствует", say_plain != null)
	_ok("14a. Requirement locked", say_plain != null and say_plain.availability == DateTypes.MoveAvailability.LOCKED)
	engine.choose_move(&"char_say_plain")
	_ok("14b. locked ход нельзя выбрать", engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE)
	var unlocked_player := _player()
	unlocked_player.muscle = 1
	var engine2 := _start(_catalog(), &"alina", &"cafe", &"casual", 8, _fresh_progress(_catalog(), &"alina"), unlocked_player)
	var say2: DateMoveOption = _episode_option(engine2.get_current_episode(), &"char_say_plain")
	_ok("14. Requirement корректно меняет locked/unlocked", say2 != null and say2.availability == DateTypes.MoveAvailability.AVAILABLE)
	engine2.choose_move(&"char_say_plain")
	_ok("15. источник характеристики израсходован", engine2.get_session_state().characteristic_source_used)
	engine2.advance()
	var say3: DateMoveOption = _episode_option(engine2.get_current_episode(), &"char_say_plain")
	_ok("15b. Used сохраняется в следующем эпизоде", say3 != null and say3.availability == DateTypes.MoveAvailability.USED)

func _test_character_build_sources() -> void:
	var catalog: DateContentCatalog = _catalog()
	var char_moves: Array[DateMove] = catalog.characteristic_moves()
	_ok("build 12 Characteristic Moves", char_moves.size() == 12)
	var tags: Dictionary = {}
	var slots: Dictionary = {}
	for move in char_moves:
		tags[String(move.fixed_tag_id)] = true
		_ok("build %s at 1/3/5" % String(move.id), move.unlock_requirement != null and DateTypes.CHARACTERISTIC_LEVELS.has(move.unlock_requirement.required_level))
		if move.unlock_requirement != null:
			slots["%s:%d" % [String(move.unlock_requirement.stat_id), move.unlock_requirement.required_level]] = true
	_ok("build 12 Tags", tags.size() == 12)
	_ok("build 12 slots", slots.size() == 12)
	var locked_player: DatePlayerSnapshot = _player()
	locked_player.muscle = 0
	var casual_engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 4, _fresh_progress(catalog, &"alina"), locked_player)
	var locked_option: DateMoveOption = _episode_option(casual_engine.get_current_episode(), &"char_say_plain")
	_ok("build casual muscle 1 locked", locked_option != null and locked_option.availability == DateTypes.MoveAvailability.LOCKED)
	var sport_engine: DateEngine = _start(_catalog(), &"alina", &"cafe", &"sport", 4, _fresh_progress(_catalog(), &"alina"), _player())
	var opened_by_outfit: DateMoveOption = _episode_option(sport_engine.get_current_episode(), &"char_say_plain")
	_ok("build EffectiveStat opens muscle 1", opened_by_outfit != null and opened_by_outfit.availability == DateTypes.MoveAvailability.AVAILABLE)
	_ok("build EffectiveStat cap 5", DateTypes.effective_stat(5, _catalog().find_outfit(&"sport"), &"muscle") == 5)
	var source_player: DatePlayerSnapshot = _player()
	source_player.muscle = 5
	var source_engine: DateEngine = _start(_catalog(), &"alina", &"cafe", &"wrestling", 6, _fresh_progress(_catalog(), &"alina"), source_player)
	var session: DateSession = source_engine.get_session_state()
	_ok("build sources start unused", not session.characteristic_source_used and not session.outfit_source_used and not session.venue_source_used)
	source_engine.get_available_moves()
	_ok("build peek does not spend", not source_engine.get_session_state().characteristic_source_used)
	source_engine.choose_move(&"char_say_plain")
	_ok("build characteristic spent independently", source_engine.get_session_state().characteristic_source_used and not source_engine.get_session_state().outfit_source_used and not source_engine.get_session_state().venue_source_used)
	source_engine.advance()
	source_engine.choose_move(&"outfit_flex_bicep")
	_ok("build outfit spent independently", source_engine.get_session_state().outfit_source_used and source_engine.get_session_state().characteristic_source_used and not source_engine.get_session_state().venue_source_used)
	source_engine.advance()
	var local_id: StringName = _first_selectable_local_move_id(source_engine)
	_ok("build local move exists", local_id != &"")
	if local_id != &"":
		source_engine.choose_move(local_id)
	_ok("build location spent independently", source_engine.get_session_state().venue_source_used)
	var used_char: DateMoveOption = _episode_option(source_engine.get_current_episode(), &"char_force_argument")
	_ok("build used persists in episode", used_char != null and used_char.availability == DateTypes.MoveAvailability.USED)
	source_engine.advance()
	var next_char: DateMoveOption = _episode_option(source_engine.get_current_episode(), &"char_force_argument")
	_ok("build used persists next episode", next_char != null and next_char.availability == DateTypes.MoveAvailability.USED)
	var fresh: DateEngine = _start(_catalog(), &"alina", &"cafe", &"wrestling", 7, _fresh_progress(_catalog(), &"alina"), source_player)
	_ok("build sources reset next date", not fresh.get_session_state().characteristic_source_used and not fresh.get_session_state().outfit_source_used and not fresh.get_session_state().venue_source_used)
	var locked_local_player: DatePlayerSnapshot = _player()
	locked_local_player.aura = 0
	locked_local_player.muscle = 0
	locked_local_player.appearance = 0
	locked_local_player.capital = 0
	var locked_local: DateEngine = _start(_catalog(), &"alina", &"restaurant", &"casual", 12, _fresh_progress(_catalog(), &"alina"), locked_local_player)
	var locked_local_option: DateMoveOption = _first_locked_local_option(locked_local)
	_ok("build locked local listed", locked_local_option == null or locked_local_option.availability == DateTypes.MoveAvailability.LOCKED)
	if locked_local_option != null:
		locked_local.choose_move(locked_local_option.move_id)
	_ok("build locked local not selectable", locked_local.get_session_state().stage == DateSession.Stage.AWAITING_MOVE)
	var phase_player: DatePlayerSnapshot = _player()
	phase_player.muscle = 5
	var phase_engine: DateEngine = _start(_catalog(), &"alina", &"cafe", &"casual", 9, _fresh_progress(_catalog(), &"alina"), phase_player)
	var seen_phases: Dictionary = {}
	while phase_engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT and phase_engine.get_session_state().stage != DateSession.Stage.COMPLETED:
		if phase_engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			phase_engine.advance()
			continue
		var episode: DateEpisodeView = phase_engine.get_current_episode()
		var source: DateMoveSourceView = null
		for source_view in episode.source_views:
			if source_view.source == DateTypes.DateMoveSource.CHARACTERISTIC:
				source = source_view
				break
		var phase_name: String = DateTypes.phase_name(episode.phase)
		seen_phases[phase_name] = true
		_ok("build %s has characteristic source" % phase_name, source != null and source.visible)
		_ok("build %s source unused until spend" % phase_name, source != null and not source.used)
		_choose(phase_engine, _first_available(phase_engine))
	_ok("build opening present", seen_phases.has("OPENING"))
	_ok("build core present", seen_phases.has("CORE"))
	_ok("build closing present", seen_phases.has("CLOSING"))

func _test_mapping_tags_differ_by_situation() -> void:
	var catalog: DateContentCatalog = _catalog()
	var appearance: DateMove = catalog.find_move(&"appearance_question__better_live")
	var verdict: DateMove = catalog.find_move(&"date_verdict__best_part_you")
	_ok("16. situation-owned flattery IDs exist", appearance != null and verdict != null)
	_ok("16. same Tag keeps situation-local option text", appearance != null and verdict != null and appearance.fixed_tag_id == &"flattery" and verdict.fixed_tag_id == &"flattery" and appearance.fixed_option_text != verdict.fixed_option_text)


func _test_combo_rules() -> void:
	var catalog := _catalog()
	var rules: DateRules = catalog.date_rules
	_ok("combo required_distinct >= 2", rules != null and rules.combo_required_distinct_success_tags >= 2)
	_ok("combo bonus > 0", rules != null and rules.combo_bonus_score > 0)
	_ok("combo max rewards >= 1", rules != null and rules.combo_max_rewards_per_date >= 1)
	# BASE+CHARACTERISTIC+LOCAL all count: DateEngine._update_combo uses episode.score_delta > 0 and tag_id, not move kind.
	var three: DateEngine = _find_combo_three_engine()
	_ok("combo three distinct score 1", three != null and three.get_result().score_breakdown.combo_score == 1)
	_ok("combo_achieved", three != null and three.get_session_state().combo_achieved)
	if three != null:
		var bd: DateScoreBreakdown = three.get_result().score_breakdown
		var expected_total: int = 0
		for value in bd.opening_scores:
			expected_total += value
		for value in bd.core_scores:
			expected_total += value
		for value in bd.closing_scores:
			expected_total += value
		expected_total += bd.combo_score
		expected_total += bd.girl_trait_score
		expected_total += bd.apartment_preparation_score
		_ok("combo included in total", bd.total == expected_total)
		var replay: DateEngine = _replay_combo_engine(three)
		_ok("combo replay same seed", replay != null and replay.get_result().score_breakdown.combo_score == bd.combo_score)
		_ok("combo max one reward", three.get_session_state().combo_rewards_earned == 1 and bd.combo_score == rules.combo_bonus_score)
	_ok("combo opening participates", _combo_opening_participates())
	_ok("combo closing participates", _combo_closing_participates())
	_ok("combo failure clears chain", _combo_failure_clears_chain())
	_ok("combo repeat keeps unique tail", _combo_repeat_keeps_unique_tail())
	_ok("combo outfit apartment not in chain", _combo_outfit_apartment_not_in_chain())
	_ok("combo local counts as source", _combo_local_counts())


func _finish_progress(catalog: DateContentCatalog, girl_id: StringName, progress: GirlProgress, want_positive: bool) -> DateEngine:
	var engine := _start(catalog, girl_id, &"cafe", &"casual", 9, progress, _player())
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		_choose(engine, _pick_preference(engine, want_positive))
	return engine


func _find_combo_three_engine() -> DateEngine:
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
		if engine.get_result().score_breakdown.combo_score == 1 and engine.get_session_state().combo_achieved:
			return engine
	return null


func _combo_opening_participates() -> bool:
	var catalog := _catalog()
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 3, _fresh_progress(catalog, &"alina"), _player())
	if engine.get_session_state().current_phase != DateTypes.DatePhase.OPENING:
		return false
	var move_id: StringName = _pick_preference(engine, true)
	var option := _option(engine, move_id)
	var girl: GirlProfile = engine.catalog().find_girl(&"alina")
	if option == null or girl == null or girl.prefers_tag(option.tag_id) <= 0:
		return false
	engine.choose_move(move_id)
	return engine.get_session_state().combo_distinct_success_tag_ids.size() == 1


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


func _replay_combo_engine(source: DateEngine) -> DateEngine:
	var session: DateSession = source.get_session_state()
	var catalog := _catalog()
	var engine := _start(catalog, session.girl_id, session.venue_id, session.outfit_id, session.seed, _fresh_progress(catalog, session.girl_id), _player())
	for episode in session.episode_history:
		while engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
		_choose(engine, episode.move_id)
	while engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		engine.advance()
	return engine


func _combo_closing_participates() -> bool:
	var catalog := _catalog()
	var engine := _finish_progress(catalog, &"alina", _fresh_progress(catalog, &"alina"), true)
	var history: Array[DateEpisodeResult] = engine.get_session_state().episode_history
	if history.is_empty():
		return false
	var last: DateEpisodeResult = history[history.size() - 1]
	return last.phase == DateTypes.DatePhase.CLOSING and last.score_delta > 0


func _combo_failure_clears_chain() -> bool:
	for seed in range(1, 80):
		var catalog := _catalog()
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var girl: GirlProfile = engine.catalog().find_girl(&"alina")
		var move_id: StringName = _pick_preference(engine, true)
		var option := _option(engine, move_id)
		if option == null or girl == null or girl.prefers_tag(option.tag_id) <= 0:
			continue
		_choose(engine, move_id)
		if engine.get_session_state().combo_distinct_success_tag_ids.is_empty():
			continue
		while engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
		var fail_id: StringName = _pick_preference(engine, false)
		var fail_option := _option(engine, fail_id)
		if fail_option == null or girl.prefers_tag(fail_option.tag_id) >= 0:
			continue
		_choose(engine, fail_id)
		return engine.get_session_state().combo_distinct_success_tag_ids.is_empty()
	return false


func _combo_repeat_keeps_unique_tail() -> bool:
	for seed in range(1, 600):
		var catalog := _catalog()
		var engine := _start(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player())
		var girl: GirlProfile = engine.catalog().find_girl(&"alina")
		if girl == null:
			continue
		var step: int = 0
		var ok_seq: bool = true
		while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
			if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
				engine.advance()
				continue
			var wanted: StringName = &"humor"
			if step == 1:
				wanted = &"care"
			elif step == 2:
				wanted = &"humor"
			if step <= 2:
				var move_id: StringName = _pick_by_tag(engine, wanted)
				var option := _option(engine, move_id)
				if option == null or option.tag_id != wanted or girl.prefers_tag(wanted) <= 0:
					ok_seq = false
					break
				_choose(engine, move_id)
				if step == 2:
					var chain: Array[StringName] = engine.get_session_state().combo_distinct_success_tag_ids
					if chain.size() != 2 or chain[0] != &"care" or chain[1] != &"humor":
						ok_seq = false
						break
			else:
				var used: Dictionary = {"care": true, "humor": true}
				var third_id: StringName = _pick_new_success(engine, used)
				var third := _option(engine, third_id)
				if third == null or used.has(String(third.tag_id)) or girl.prefers_tag(third.tag_id) <= 0:
					ok_seq = false
					break
				_choose(engine, third_id)
				return engine.get_session_state().combo_achieved and engine.get_session_state().score_breakdown.combo_score == 1
			step += 1
		if not ok_seq:
			continue
	return false


func _combo_outfit_apartment_not_in_chain() -> bool:
	var catalog := _catalog()
	var casual := _finish_at(catalog, &"cafe", &"casual", _player())
	var luxury := _finish_at(catalog, &"cafe", &"luxury", _player())
	var unprepared := _player()
	unprepared.apartment_prepared = false
	var apt := _finish_at(catalog, &"apartment", &"casual", unprepared)
	return casual.score_breakdown.combo_score == luxury.score_breakdown.combo_score and not luxury.score_breakdown.to_dictionary().has("outfit_score") and apt.score_breakdown.apartment_preparation_score == -1


func _combo_local_counts() -> bool:
	var catalog := _catalog()
	var engine := _start(catalog, &"alina", &"cafe", &"casual", 13, _fresh_progress(catalog, &"alina"), _player())
	var local_id: StringName = _first_selectable_local_move_id(engine)
	if local_id == &"":
		return false
	engine.choose_move(local_id)
	var chain: Array[StringName] = engine.get_session_state().combo_distinct_success_tag_ids
	return not chain.is_empty()


func _test_venue_outfit_apartment() -> void:
	var catalog := _catalog()
	var cafe := _finish_at(catalog, &"cafe", &"casual", _player())
	_ok("21. cafe не даёт location_quality_score", not ("location_quality_score" in cafe.score_breakdown.to_dictionary()))
	_ok("21b cafe без venue score", cafe.score_breakdown.apartment_preparation_score == 0)
	var restaurant := _finish_at(catalog, &"restaurant", &"casual", _player())
	_ok("22. restaurant без location preference", not ("location_preference_score" in restaurant.score_breakdown.to_dictionary()))
	var apt_player := _player()
	apt_player.apartment_prepared = true
	var apt := _finish_at(catalog, &"apartment", &"casual", apt_player)
	_ok("23. apartment quality scoring отсутствует", not ("apartment_quality_score" in apt.score_breakdown.to_dictionary()))
	_ok("24. подготовленная квартира даёт 0", apt.score_breakdown.apartment_preparation_score == 0)
	var unprepared := _player()
	unprepared.apartment_prepared = false
	var apt2 := _finish_at(catalog, &"apartment", &"casual", unprepared)
	_ok("25. неподготовленная квартира даёт -1", apt2.score_breakdown.apartment_preparation_score == -1)
	var luxury := _finish_at(catalog, &"cafe", &"luxury", _player())
	_ok("26. Outfit bonus не входит в Dating Core", not luxury.score_breakdown.to_dictionary().has("outfit_score"))


func _test_local_moves() -> void:
	var catalog := _catalog()
	var cafe := _finish_at(catalog, &"cafe", &"casual", _player())
	var restaurant := _finish_at(catalog, &"restaurant", &"casual", _player())
	var apartment := _finish_at(catalog, &"apartment", &"casual", _player())
	_ok("1. cafe без location_quality_score", not ("location_quality_score" in cafe.score_breakdown.to_dictionary()))
	_ok("1b restaurant без location_quality_score", not ("location_quality_score" in restaurant.score_breakdown.to_dictionary()))
	_ok("1c apartment без location_quality_score", not ("location_quality_score" in apartment.score_breakdown.to_dictionary()))
	_ok("2. favorite location scoring отсутствует", not ("location_preference_score" in cafe.score_breakdown.to_dictionary()))
	_ok("3. apartment quality scoring отсутствует", not ("apartment_quality_score" in apartment.score_breakdown.to_dictionary()))
	var unprepared := _player()
	unprepared.apartment_prepared = false
	var unprepared_result := _finish_at(catalog, &"apartment", &"casual", unprepared)
	_ok("4. неподготовленная квартира даёт -1", unprepared_result.score_breakdown.apartment_preparation_score == -1)
	var prepared := _player()
	prepared.apartment_prepared = true
	var prepared_result := _finish_at(catalog, &"apartment", &"casual", prepared)
	_ok("5. подготовленная квартира даёт 0", prepared_result.score_breakdown.apartment_preparation_score == 0)
	var luxury := _finish_at(catalog, &"cafe", &"luxury", _player())
	_ok("6. outfit bonus отсутствует", not luxury.score_breakdown.to_dictionary().has("outfit_score"))
	var cafe_engine := _start(catalog, &"alina", &"cafe", &"casual", 9, _fresh_progress(catalog, &"alina"), _player())
	var cafe_view: DateEpisodeView = cafe_engine.get_current_episode()
	var cafe_local_id: StringName = _first_selectable_local_move_id(cafe_engine)
	_ok("9. Local Move появляется независимо от Situation", cafe_local_id != &"" or _source_options(cafe_view, DateTypes.DateMoveSource.VENUE).is_empty())
	if cafe_local_id != &"":
		var opening_engine := _start(catalog, &"alina", &"cafe", &"casual", 3, _fresh_progress(catalog, &"alina"), _player())
		var opening_id: StringName = _first_selectable_local_move_id(opening_engine)
		opening_engine.choose_move(opening_id)
		var opening_delta: int = int(opening_engine.get_session_state().current_score_delta)
		_ok("7. OPENING local score ±1", opening_delta == 1 or opening_delta == -1)
		cafe_engine.choose_move(cafe_local_id)
		_ok("11b. location source used after one local", cafe_engine.get_session_state().venue_source_used)
		_ok("11. used local move consumed", _local_option_used(cafe_engine.get_current_episode(), cafe_local_id))
	var new_session := _start(catalog, &"alina", &"cafe", &"casual", 11, _fresh_progress(catalog, &"alina"), _player())
	var new_local_id: StringName = _first_selectable_local_move_id(new_session)
	_ok("13. в новой сессии local снова доступно", new_local_id != &"" or _source_options(new_session.get_current_episode(), DateTypes.DateMoveSource.VENUE).is_empty())
	var without_local := DateEngine.new()
	var without_config := DateSessionConfig.new()
	without_config.catalog = catalog
	without_config.girl_id = &"alina"
	without_config.venue_id = &"cafe"
	without_config.outfit_id = &"casual"
	without_config.seed = 21
	without_config.girl_progress = _fresh_progress(catalog, &"alina")
	without_config.player_snapshot = _player()
	without_config.relationship_max = GirlCatalog.seed_relationship_max(&"alina")
	without_local.create_date_session(without_config)
	var with_local := _start(catalog, &"alina", &"cafe", &"casual", 21, _fresh_progress(catalog, &"alina"), _player())
	_ok("18. LOCAL не влияет на random BASE", without_local.get_session_state().current_selected_base_move_ids == with_local.get_session_state().current_selected_base_move_ids)
	_test_local_moves_progression_and_validator(catalog)


func _test_local_moves_progression_and_validator(catalog: DateContentCatalog) -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var apartment: Variant = _apartment_service()
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	var girls: Variant = _girls_service()
	_ok("19. services", gs != null and sm != null and apartment != null and dating != null and actions != null and girls != null)
	if gs == null or sm == null or apartment == null or dating == null or actions == null or girls == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/local_moves_stage17.json"
	sm.delete_save()
	sm.new_game()
	gs.story.stage = 2
	gs.player.money = 150
	var buy: ActionResult = actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	_ok("19. apartment__plaid открывает local object", buy.success and apartment.get_owned_local_object_ids().has(&"apartment__plaid") and gs.progression.apartment.owned_local_object_ids.has(&"apartment__plaid"))
	sm.save_game()
	sm.new_game()
	_ok("20. reset без plaid", not apartment.get_owned_local_object_ids().has(&"apartment__plaid"))
	_ok("20. load", sm.load_game())
	_ok("20. после load plaid доступен", apartment.get_owned_local_object_ids().has(&"apartment__plaid"))
	_write_v12_apartment_save(sm, false, [])
	_ok("21. load v12", sm.load_game())
	_ok("21. prepared=true", bool(gs.progression.apartment.prepared))
	_write_v12_apartment_save(sm, false, ["apartment__plaid"])
	_ok("22. load owned objects", sm.load_game())
	_ok("22. owned_local_object_ids has plaid", gs.progression.apartment.owned_local_object_ids.has(&"apartment__plaid"))
	var replay_progress := _fresh_progress(catalog, &"alina")
	var store := DateProgressStore.new()
	store.player_snapshot = _player()
	var replay_ids: Array[StringName] = [&"apartment__plaid", &"apartment__tv"]
	store.capture_replay(33, &"alina", &"apartment", &"casual", replay_progress, replay_ids)
	var replay_engine := DateEngine.new()
	var replay_config := DateSessionConfig.new()
	replay_config.catalog = catalog
	replay_config.girl_id = &"alina"
	replay_config.venue_id = &"apartment"
	replay_config.outfit_id = &"casual"
	replay_config.seed = 33
	replay_config.girl_progress = _fresh_progress(catalog, &"alina")
	replay_config.player_snapshot = _player()
	replay_config.relationship_max = GirlCatalog.seed_relationship_max(&"alina")
	replay_config.local_object_ids = store.last_replay.local_object_ids.duplicate()
	replay_engine.create_date_session(replay_config)
	_ok("23. replay сохраняет toolkit", replay_engine.get_session_state().local_object_ids == replay_ids)
	var validator := ContentValidator.new()
	var clean: Array[ContentValidationIssue] = validator.validate(catalog)
	_ok("24. validator seed без errors", not _has_error(clean))
	var broken := _catalog()
	var broken_object: DateLocalObject = broken.find_local_object(&"cafe__window")
	if broken_object == null:
		broken_object = broken.find_local_object(&"window")
	if broken_object != null:
		broken_object.move_ids.append(&"missing_local_move")
	_ok("24. validator ловит broken Local Object", _has_issue(validator.validate(broken), "Неизвестный DateMove"))
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _local_move_present(view: DateEpisodeView, move_id: StringName) -> bool:
	return _find_local_option(view, move_id) != null


func _source_options(view: DateEpisodeView, source: DateTypes.DateMoveSource) -> Array[DateMoveOption]:
	var options: Array[DateMoveOption] = []
	if view == null:
		return options
	for source_view in view.source_views:
		if source_view.source == source:
			return source_view.options
	return options


func _local_object_used(view: DateEpisodeView, object_id: StringName) -> bool:
	if view == null:
		return false
	for source_view in view.source_views:
		if source_view.source != DateTypes.DateMoveSource.VENUE:
			continue
		for option in source_view.options:
			if option.local_object_id == object_id:
				return source_view.used
	return false


func _local_option_used(view: DateEpisodeView, move_id: StringName) -> bool:
	var option: DateMoveOption = _find_local_option(view, move_id)
	return option != null and option.availability == DateTypes.MoveAvailability.USED


func _local_option_selectable(view: DateEpisodeView, move_id: StringName) -> bool:
	var option: DateMoveOption = _find_local_option(view, move_id)
	return option != null and option.is_selectable()


func _local_option_visible(view: DateEpisodeView, move_id: StringName) -> bool:
	return _find_local_option(view, move_id) != null


func _find_local_option(view: DateEpisodeView, move_id: StringName) -> DateMoveOption:
	if view == null:
		return null
	for option in _source_options(view, DateTypes.DateMoveSource.VENUE):
		if option.move_id == move_id:
			return option
	return null


func _local_object_move_ids(engine: DateEngine, object_id: StringName) -> PackedStringArray:
	var ids := PackedStringArray()
	var view: DateEpisodeView = engine.get_current_episode()
	if view == null:
		return ids
	for option in _source_options(view, DateTypes.DateMoveSource.VENUE):
		if option.local_object_id == object_id:
			ids.append(String(option.move_id))
	return ids


func _finish_at(catalog: DateContentCatalog, location_id: StringName, outfit_id: StringName, player: DatePlayerSnapshot) -> DateRunResult:
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
	_ok("27. отношения АЛИНЫ clamp в 0..+10", engine.get_session_state().relationship_after <= 10 and engine.get_session_state().relationship_after >= 0)
	var vika := _fresh_progress(catalog, &"vika")
	vika.relationship = 5
	var engine_v := _finish_progress(catalog, &"vika", vika, true)
	_ok("28. отношения ВИКИ clamp в 0..+10", engine_v.get_session_state().relationship_after <= 10 and engine_v.get_session_state().relationship_after >= 0)
	var store := DateProgressStore.new()
	store.reset_all(catalog)
	var girl: GirlProfile = catalog.find_girl(&"alina")
	alina.relationship = 4
	alina.completed_dates = 2
	store.girl_progress_by_id["alina"] = alina
	store.reset_girl(girl)
	var reset: GirlProgress = store.get_girl_progress(&"alina", girl)
	_ok("29. reset GirlProgress восстанавливает старт", reset.relationship == 0 and reset.completed_dates == 0 and reset.revealed_positive_tag_ids.is_empty())


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
	broken.find_situation(&"appearance_question").base_move_ids[0] = &"missing_sit_move"
	_ok("33. Validator ловит broken references", _has_issue(validator.validate(broken), "отсутствующий Move"))
	var thin := _catalog()
	var situation: DateSituation = thin.find_situation(&"appearance_question")
	situation.base_move_ids = [situation.base_move_ids[0], situation.base_move_ids[1]] as Array[StringName]
	_ok("34. Validator ловит Situation с недостаточным BASE pool", _has_issue(validator.validate(thin), "ровно 6 BASE"))
	var combo_low := _catalog()
	combo_low.date_rules.combo_required_distinct_success_tags = 1
	_ok("35. Validator проверяет combo required_distinct", _has_issue(validator.validate(combo_low), "combo_required_distinct_success_tags"))
	var combo_bonus := _catalog()
	combo_bonus.date_rules.combo_bonus_score = 0
	_ok("35b. Validator проверяет combo bonus", _has_issue(validator.validate(combo_bonus), "combo_bonus_score"))
	var combo_max := _catalog()
	combo_max.date_rules.combo_max_rewards_per_date = 0
	_ok("35c. Validator проверяет combo max rewards", _has_issue(validator.validate(combo_max), "combo_max_rewards_per_date"))
	_ok("35d. Validator catalog has kira", _catalog().find_girl(&"kira") != null)
	_ok("35e. Validator catalog has eva", _catalog().find_girl(&"eva") != null)
	var unlock := _catalog()
	unlock.find_move(&"char_say_plain").unlock_requirement = null
	_ok("36. Validator проверяет UnlockRequirement", _has_issue(validator.validate(unlock), "UnlockRequirement"))
	var dup_unlock := _diversity_catalog(
		[["base_a", "directness"], ["base_b", "risk"], ["base_c", "status"]],
		[["unlock_status_a", "status", 1, 1], ["unlock_status_b", "status", 1, 1]]
	)
	var dup_issues: Array[ContentValidationIssue] = validator.validate(dup_unlock)
	var dup_error: ContentValidationIssue = _find_code(dup_issues, "CHARACTERISTIC_TAG_DUPLICATE")
	_ok("8. ERROR CHARACTERISTIC_TAG_DUPLICATE", dup_error != null and dup_error.severity == DateTypes.ValidationSeverity.ERROR)
	_ok("8. error names status characteristic moves", dup_error != null and "status" in dup_error.message and "unlock_status_a" in dup_error.message and "unlock_status_b" in dup_error.message)


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


func _test_characteristic_tag_reservation() -> void:
	var catalog: DateContentCatalog = _catalog()
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 17, _fresh_progress(catalog, &"alina"), _player())
	var session: DateSession = engine.get_session_state()
	var selected: Array[StringName] = session.current_selected_base_move_ids
	var reroll: Array[StringName] = session.current_reroll_base_move_ids
	var situation: DateSituation = catalog.find_situation(session.selected_situation_ids[0])
	_ok("1. shown triple size", selected.size() == 3)
	_ok("1. reroll triple size", reroll.size() == 3)
	var overlap: bool = false
	for move_id in selected:
		if reroll.has(move_id):
			overlap = true
	_ok("1. selected and reroll disjoint", not overlap)
	var union_ok: bool = selected.size() + reroll.size() == 6
	for move_id in situation.base_move_ids:
		if not selected.has(move_id) and not reroll.has(move_id):
			union_ok = false
	_ok("1. selected union reroll is six-move set", union_ok)
	_ok("4. three BASE have three Tags", _unique_count(session.current_selected_base_tag_ids) == 3)
	var det_a: DateEngine = _start(_catalog(), &"alina", &"cafe", &"casual", 91, _fresh_progress(_catalog(), &"alina"), _player())
	var det_b: DateEngine = _start(_catalog(), &"alina", &"cafe", &"casual", 91, _fresh_progress(_catalog(), &"alina"), _player())
	_ok("7. same seed same BASE ids and order", det_a.get_session_state().current_selected_base_move_ids == det_b.get_session_state().current_selected_base_move_ids)

func _test_twelve_tag_rebalance() -> void:
	var catalog: DateContentCatalog = _catalog()
	var enabled: Array[DateTag] = catalog.enabled_tags()
	_ok("22.1 seed contains 12 Tags", enabled.size() == 12)
	var alina: GirlProfile = catalog.find_girl(&"alina")
	_ok("22.2 Alina difficulty wide", alina.difficulty_preset_id == &"wide")
	_ok("22.2 Alina positives", _same_tag_set(alina.positive_tag_ids, ["politeness", "directness", "care", "generosity", "composure", "humor", "risk", "dominance"]))
	_ok("22.2 Alina sizes", alina.positive_tag_ids.size() == 8 and _computed_negative_count(alina, catalog) == 4)
	_ok("22.2 Alina range", GirlCatalog.seed_relationship_max(&"alina") == 10)
	var vika: GirlProfile = catalog.find_girl(&"vika")
	_ok("22.3 Vika difficulty preset", catalog.find_girl_difficulty(vika.difficulty_preset_id) != null)
	_ok("22.3 Vika positives exist", vika.positive_tag_ids.size() > 0)
	_ok("22.3 Vika sizes", vika.positive_tag_ids.size() + _computed_negative_count(vika, catalog) == catalog.enabled_tags().size())
	_ok("22.3 Vika range", GirlCatalog.seed_relationship_max(&"vika") == 10)
	for girl in catalog.girls:
		_ok("22.4 coverage %s" % String(girl.id), _girl_covers_enabled_tags(girl, enabled))
	var validator := ContentValidator.new()
	var two: DateContentCatalog = _catalog()
	var two_girl: GirlProfile = two.find_girl(&"alina")
	two_girl.positive_tag_ids = [&"care", &"generosity"] as Array[StringName]
	_ok("22.5 two positives", _find_code(validator.validate(two), "INVALID_POSITIVE_TAG_COUNT") != null)
	var four: DateContentCatalog = _catalog()
	var four_girl: GirlProfile = four.find_girl(&"alina")
	four_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
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
		_ok("22.7 BASE diversity %s" % String(situation.id), distinct == 6)
	_ok("22.8 hobby care", _mapping_tag(&"embarrassing_hobby__ask_without_mockery", &"embarrassing_hobby") == &"care")
	_ok("22.8 verdict care", _mapping_tag(&"date_verdict__were_you_comfortable", &"date_verdict") == &"care")
	_ok("22.9 silence humor", _mapping_tag(&"awkward_silence__minute_of_silence", &"awkward_silence") == &"humor")
	_ok("22.9 rival humor", _mapping_tag(&"rival_provocation__brave_attempt", &"rival_provocation") == &"humor")
	_ok("22.9 joke humor", _mapping_tag(&"terrible_joke__worse_punchline", &"terrible_joke") == &"humor")
	_ok("22.10 money cunning", _mapping_tag(&"money_request__next_expense_yours", &"money_request") == &"cunning")
	_ok("22.10 rule cunning", _mapping_tag(&"small_rule__legal_loophole", &"small_rule") == &"cunning")
	_ok("22.11 appearance composure", _mapping_tag(&"appearance_question__get_used_to_it", &"appearance_question") == &"composure")
	_ok("22.11 rival composure", _mapping_tag(&"rival_provocation__no_reaction", &"rival_provocation") == &"composure")
	_ok("22.11 verdict composure", _mapping_tag(&"date_verdict__good_no_analysis", &"date_verdict") == &"composure")
	_ok("22.11 hold pause composure", _catalog().find_move(&"char_hold_pause").fixed_tag_id == &"composure")
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
	for tag_id in girl.positive_tag_ids:
		var key: String = String(tag_id)
		if positive.has(key):
			return false
		positive[key] = true
	for tag in enabled:
		if tag == null:
			continue
		var pref: int = girl.prefers_tag(tag.id)
		if positive.has(String(tag.id)):
			if pref <= 0:
				return false
		elif pref >= 0:
			return false
	for key in positive.keys():
		var found: bool = false
		for tag in enabled:
			if tag != null and String(tag.id) == String(key):
				found = true
				break
		if not found:
			return false
	return true


func _computed_negative_count(girl: GirlProfile, catalog: DateContentCatalog) -> int:
	var count: int = 0
	for tag in catalog.enabled_tags():
		if girl.prefers_tag(tag.id) < 0:
			count += 1
	return count


func _distinct_base_tags(catalog: DateContentCatalog, situation_id: StringName) -> int:
	var tags: Dictionary = {}
	for move in catalog.base_moves_for_situation(situation_id):
		if move == null or move.fixed_tag_id == &"":
			continue
		tags[String(move.fixed_tag_id)] = true
	return tags.size()


func _mapping_tag(move_id: StringName, situation_id: StringName) -> StringName:
	var move: DateMove = _catalog().find_move(move_id)
	if move == null:
		return &""
	return move.fixed_tag_id


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
	var player: DatePlayerSnapshot = _player()
	player.capital = 6
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 11, _fresh_progress(catalog, &"alina"), player)
	var session: DateSession = engine.get_session_state()
	_ok("22.14 six-move candidate pool", session.current_candidate_base_move_ids.size() == specs.size())
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
	var base_ids: Array[StringName] = []
	for spec in base_specs:
		base_ids.append(StringName(String(spec[0])))
	situation.base_move_ids = base_ids
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
	move.fixed_tag_id = StringName(tag_id)
	move.fixed_option_text = "option"
	move.fixed_positive_result_text = "positive"
	move.fixed_negative_result_text = "negative"
	return move


func _test_unlock_move(move_id: String, tag_id: String, required_level: int, max_uses: int) -> DateMove:
	var move: DateMove = DateMove.new()
	move.id = StringName(move_id)
	move.display_name = move_id
	move.description = move_id
	move.kind = DateTypes.DateMoveKind.CHARACTERISTIC
	move.enabled = true
	move.max_uses_per_date = max_uses
	move.fixed_tag_id = StringName(tag_id)
	move.fixed_option_text = move_id
	move.fixed_positive_result_text = "ok"
	move.fixed_negative_result_text = "bad"
	var requirement: UnlockRequirement = UnlockRequirement.new()
	requirement.stat_id = &"capital"
	requirement.required_level = required_level
	move.unlock_requirement = requirement
	return move

func _test_girl_difficulty() -> void:
	var catalog: DateContentCatalog = _catalog()
	var presets: Array[GirlDifficultyPreset] = catalog.enabled_girl_difficulty_presets()
	_ok("7 enabled difficulty presets", presets.size() == 7)
	_ok("WIDE positive_tag_count == 8", catalog.find_girl_difficulty(&"wide").positive_tag_count == 8)
	_ok("EASY positive_tag_count == 7", catalog.find_girl_difficulty(&"easy").positive_tag_count == 7)
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
	mid_girl.trait_id = &"loves_cafe"
	mid_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
	_ok("save mid positive 4", mid_girl.positive_tag_ids.size() == 4)
	_ok("save mid negative 8", _computed_negative_count(mid_girl, catalog) == 8)
	_ok("save mid coverage", _girl_covers_enabled_tags(mid_girl, catalog.enabled_tags()))
	DirAccess.make_dir_recursive_absolute("user://date_system")
	var path: String = "user://date_system/test_mid_girl.tres"
	_ok("save mid girl", ResourceSaver.save(mid_girl, path) == OK)
	var loaded: GirlProfile = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GirlProfile
	_ok("reload mid girl", loaded != null and loaded.positive_tag_ids.size() == 4 and _computed_negative_count(loaded, catalog) == 8)
	_ok("reload mid coverage", loaded != null and _girl_covers_enabled_tags(loaded, catalog.enabled_tags()))
	var starter_girl: GirlProfile = catalog.find_girl(&"alina").duplicate(true) as GirlProfile
	_ok("alina current 8", starter_girl.positive_tag_ids.size() == 8)
	starter_girl.difficulty_preset_id = &"mid"
	var required: int = catalog.find_girl_difficulty(&"mid").positive_tag_count
	_ok("editor shows 8 / 4", starter_girl.positive_tag_ids.size() == 8 and required == 4)
	starter_girl.positive_tag_ids = [&"care", &"generosity", &"composure", &"humor"] as Array[StringName]
	_ok("after MID save 4/8", starter_girl.difficulty_preset_id == &"mid" and starter_girl.positive_tag_ids.size() == 4 and _computed_negative_count(starter_girl, catalog) == 8)
	var progress := GirlProgress.new()
	var alina: GirlProfile = catalog.find_girl(&"alina")
	progress.reset_to_profile(alina)
	progress.reveal_tag(&"care", true)
	progress.reveal_tag(&"flattery", false)
	var swapped: GirlProfile = alina.duplicate(true) as GirlProfile
	swapped.positive_tag_ids.erase(&"care")
	swapped.positive_tag_ids.append(&"flattery")
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
	_ok("Alina sim ran", not alina_sim.is_empty())
	_ok("Vika sim ran", not vika_sim.is_empty())
	var alina_pos: int = int(catalog.find_girl(&"alina").positive_tag_ids.size())
	var vika_pos: int = int(catalog.find_girl(&"vika").positive_tag_ids.size())
	if alina_pos > vika_pos:
		_ok("Alina BASE availability above Vika", float(alina_sim["at_least_one"]) > float(vika_sim["at_least_one"]))

func _test_dating_core_model() -> void:
	var catalog: DateContentCatalog = _catalog()
	var world_ids: Array[StringName] = [
		GirlCatalog.ID_ALINA, GirlCatalog.ID_MARINA, GirlCatalog.ID_VIKA, GirlCatalog.ID_DASHA,
		GirlCatalog.ID_KATYA, GirlCatalog.ID_LERA, GirlCatalog.ID_KIRA, GirlCatalog.ID_OLYA,
		GirlCatalog.ID_SONYA, GirlCatalog.ID_NIKA, GirlCatalog.ID_RITA, GirlCatalog.ID_EVA,
		GirlCatalog.ID_ACTRESS, GirlCatalog.ID_MINE_BOSS, GirlCatalog.ID_MAGAZINE_EDITOR,
		GirlCatalog.ID_SCIENTIST, GirlCatalog.ID_PRESIDENT,
	]
	_ok("1. 17 girls in Date Content", catalog.girls.size() == 17)
	for girl_id in world_ids:
		_ok("1. date profile %s" % String(girl_id), catalog.find_girl(girl_id) != null)
	_ok("2. ordinary MAX 10", GirlCatalog.seed_relationship_max(&"alina") == 10)
	_ok("2. actress MAX 10", GirlCatalog.seed_relationship_max(GirlCatalog.ID_ACTRESS) == 10)
	_ok("2. scientist MAX 15", GirlCatalog.seed_relationship_max(GirlCatalog.ID_SCIENTIST) == 15)
	var actress_req: GirlRelationshipRequirement = StageCatalog.make_girl_relationship_requirement(GirlCatalog.create_seed().get_girl(GirlCatalog.ID_ACTRESS))
	_ok("3. story requirement reads MAX 10", actress_req != null and actress_req.target_relationship == 10)
	var alina: GirlProfile = catalog.find_girl(&"alina")
	var actress: GirlProfile = catalog.find_girl(GirlCatalog.ID_ACTRESS)
	var fresh: GirlProgress = _fresh_progress(catalog, &"alina")
	_ok("4. relationships start at 0", fresh.relationship == 0)
	_ok("13. filler initial known count 2", alina.initial_known_tag_count == 2)
	_ok("13. engine progress starts UNKNOWN until first meet", fresh.tag_knowledge(&"politeness", alina) == DateTypes.TagKnowledge.UNKNOWN)
	_ok("13. revealed tags empty before first meet", fresh.revealed_positive_tag_ids.is_empty() and fresh.revealed_negative_tag_ids.is_empty())
	var actress_progress: GirlProgress = _fresh_progress(catalog, GirlCatalog.ID_ACTRESS)
	var actress_unknown: bool = true
	for tag in catalog.enabled_tags():
		if actress_progress.tag_knowledge(tag.id, actress) != DateTypes.TagKnowledge.UNKNOWN:
			actress_unknown = false
			break
	_ok("14. story girl starts UNKNOWN", actress_unknown and actress.initial_known_tag_count == 0)
	var good: DateEngine = _finish_with_preference(catalog, true, true)
	var good_bd: DateScoreBreakdown = good.get_result().score_breakdown
	_ok("5. five positive episodes give positive raw", good_bd.total > 0)
	_ok("29. raw separate from gain", good_bd.relationship_gain == maxi(good_bd.total, 0))
	var bad_found: bool = false
	for seed in range(1, 200):
		var progress: GirlProgress = _fresh_progress(catalog, &"alina")
		progress.relationship = 4
		var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", seed, progress, _player())
		var valid: bool = true
		while engine.get_session_state().stage == DateSession.Stage.AWAITING_MOVE or engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
				engine.advance()
				continue
			if not _has_preference(engine, false):
				valid = false
				break
			_choose(engine, _pick_preference(engine, false))
		if not valid or engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
			continue
		var bd: DateScoreBreakdown = engine.get_result().score_breakdown
		_ok("6. negative raw gives gain 0", bd.total < 0 and bd.relationship_gain == 0)
		_ok("7. bad date keeps relationship", engine.get_session_state().relationship_after == 4)
		bad_found = true
		break
	_ok("6/7 found negative date", bad_found)
	var clamp_progress: GirlProgress = _fresh_progress(catalog, &"alina")
	clamp_progress.relationship = 9
	var clamp_engine: DateEngine = _finish_progress(catalog, &"alina", clamp_progress, true)
	_ok("8. positive gain clamps to MAX", clamp_engine.get_session_state().relationship_after == 10)
	var persist_progress: GirlProgress = _fresh_progress(catalog, &"alina")
	var persist_engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 11, persist_progress, _player())
	var persist_move: StringName = _pick_unknown_preference(persist_engine, true)
	if persist_move != &"":
		var persist_option: DateMoveOption = _option(persist_engine, persist_move)
		_choose(persist_engine, persist_move)
		var second: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 12, persist_progress, _player())
		_ok("12. knowledge persists between dates", persist_option != null and persist_progress.tag_knowledge(persist_option.tag_id, alina) == DateTypes.TagKnowledge.POSITIVE and second.girl_progress().tag_knowledge(persist_option.tag_id, alina) == DateTypes.TagKnowledge.POSITIVE)
	_test_characteristic_trait_rules()
	_test_venue_trait_and_apartment()
	_test_raise_stakes_capital_gate()
	_test_full_date_cycle_result()


func _test_catalog_snapshot() -> void:
	var catalog: DateContentCatalog = _catalog()
	var snap: DateContentCatalog = catalog.snapshot()
	_ok("snapshot is separate catalog", snap != null and snap != catalog)
	_ok("snapshot find_girl", snap.find_girl(&"alina") != null)
	_ok("snapshot find_situation", snap.find_situation(&"appearance_question") != null)
	_ok("snapshot find_outfit", snap.find_outfit(&"casual") != null)
	_ok("snapshot find_venue", snap.find_venue(&"cafe") != null)
	_ok("snapshot find_trait", snap.find_trait(&"homebody") != null)
	var opening: DateSituation = snap.find_situation(&"appearance_question")
	_ok("snapshot allows_phase", opening != null and opening.allows_phase(DateTypes.DatePhase.OPENING))
	var original_girl_count: int = catalog.girls.size()
	catalog.girls = []
	_ok("snapshot arrays independent", snap.girls.size() == original_girl_count and catalog.girls.is_empty())
	catalog.girls = snap.girls.duplicate()
	_ok("snapshot shares girl resource", snap.find_girl(&"alina") == catalog.find_girl(&"alina"))
	_ok("snapshot shares date_rules", snap.date_rules == catalog.date_rules)
	var girl: GirlProfile = catalog.find_girl(&"alina")
	var location: DateVenue = catalog.find_venue(&"cafe")
	var progress: GirlProgress = _fresh_progress(catalog, &"alina")
	var engine: DateEngine = DateEngine.new()
	var config: DateSessionConfig = DateSessionConfig.new()
	config.catalog = snap
	config.girl_id = &"alina"
	config.venue_id = &"cafe"
	config.outfit_id = &"casual"
	config.seed = 1
	config.girl_progress = progress
	config.player_snapshot = _player()
	config.relationship_max = 10
	if location != null:
		config.local_object_ids = location.local_object_ids.duplicate()
	var session: DateSession = engine.create_date_session(config)
	_ok("engine session on snapshot catalog", session != null and engine.get_available_moves().size() > 0)
	_ok("prefers positive tag +1", girl.prefers_tag(&"politeness") == 1)
	_ok("prefers other tag -1", girl.prefers_tag(&"audacity") == -1)
	_ok("seed has no authored negatives", not ("negative_tag_ids" in girl))
	for item in catalog.girls:
		_ok("coverage %s" % String(item.id), _girl_covers_enabled_tags(item, catalog.enabled_tags()))
	var issues: Array[ContentValidationIssue] = ContentValidator.new().validate(catalog)
	var blocking: bool = false
	for issue in issues:
		if issue.severity == DateTypes.ValidationSeverity.ERROR:
			blocking = true
			break
	_ok("seed validator has no errors", not blocking)
	var roundtrip: GirlProgress = GirlProgress.from_dictionary(progress.to_dictionary())
	progress.reveal_tag(&"flattery", false, girl)
	roundtrip = GirlProgress.from_dictionary(progress.to_dictionary())
	_ok("revealed negatives persist", roundtrip.revealed_negative_tag_ids.has(&"flattery"))


func _test_characteristic_trait_rules() -> void:
	var hit: DateContentCatalog = _diversity_catalog(
		[["base_a", "directness"], ["base_b", "care"], ["base_c", "humor"]],
		[["unlock_muscle", "care", 1, 1]],
		1, 0, true
	)
	hit.find_move(&"unlock_muscle").unlock_requirement.stat_id = &"muscle"
	hit.find_girl(&"alina").trait_id = &"loves_strong"
	var hit_player: DatePlayerSnapshot = _player()
	hit_player.muscle = 5
	var hit_engine: DateEngine = _start(hit, &"alina", &"cafe", &"casual", 3, _fresh_progress(hit, &"alina"), hit_player)
	_choose(hit_engine, &"unlock_muscle")
	while hit_engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		hit_engine.advance()
	var hit_bd: DateScoreBreakdown = hit_engine.get_result().score_breakdown
	_ok("18. characteristic Trait +1", hit_bd.girl_trait_score == 1)
	var other: DateContentCatalog = _diversity_catalog(
		[["base_a", "directness"], ["base_b", "care"], ["base_c", "humor"]],
		[["unlock_looks", "care", 1, 1]],
		1, 0, true
	)
	other.find_move(&"unlock_looks").unlock_requirement.stat_id = &"appearance"
	other.find_girl(&"alina").trait_id = &"loves_strong"
	var other_player: DatePlayerSnapshot = _player()
	other_player.appearance = 5
	var other_engine: DateEngine = _start(other, &"alina", &"cafe", &"casual", 3, _fresh_progress(other, &"alina"), other_player)
	_choose(other_engine, &"unlock_looks")
	while other_engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		other_engine.advance()
	_ok("19. Trait ignores other characteristic", other_engine.get_result().score_breakdown.girl_trait_score == 0)
	var miss: DateContentCatalog = _diversity_catalog(
		[["base_a", "directness"], ["base_b", "care"], ["base_c", "humor"]],
		[["unlock_muscle_bad", "audacity", 1, 1]],
		1, 0, true
	)
	miss.find_move(&"unlock_muscle_bad").unlock_requirement.stat_id = &"muscle"
	miss.find_girl(&"alina").trait_id = &"loves_strong"
	var miss_player: DatePlayerSnapshot = _player()
	miss_player.muscle = 5
	var miss_engine: DateEngine = _start(miss, &"alina", &"cafe", &"casual", 3, _fresh_progress(miss, &"alina"), miss_player)
	_choose(miss_engine, &"unlock_muscle_bad")
	while miss_engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		miss_engine.advance()
	_ok("20. Trait ignores negative reaction", miss_engine.get_result().score_breakdown.girl_trait_score == 0)
	var twice: DateContentCatalog = _diversity_catalog(
		[["base_a", "directness"], ["base_b", "care"], ["base_c", "humor"]],
		[["unlock_muscle_a", "care", 1, 1], ["unlock_muscle_b", "humor", 1, 1]],
		1, 1, true
	)
	twice.find_move(&"unlock_muscle_a").unlock_requirement.stat_id = &"muscle"
	twice.find_move(&"unlock_muscle_b").unlock_requirement.stat_id = &"muscle"
	twice.find_girl(&"alina").trait_id = &"loves_strong"
	var twice_player: DatePlayerSnapshot = _player()
	twice_player.muscle = 5
	var twice_engine: DateEngine = _start(twice, &"alina", &"cafe", &"casual", 3, _fresh_progress(twice, &"alina"), twice_player)
	while twice_engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if twice_engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			twice_engine.advance()
			continue
		var chosen: StringName = &""
		for option in twice_engine.get_available_moves():
			if option.move_id == &"unlock_muscle_a" or option.move_id == &"unlock_muscle_b":
				if option.is_selectable():
					chosen = option.move_id
					break
		if chosen == &"":
			chosen = _first_available(twice_engine)
		_choose(twice_engine, chosen)
	_ok("21. characteristic Trait once per date", twice_engine.get_result().score_breakdown.girl_trait_score == 1)


func _test_venue_trait_and_apartment() -> void:
	var catalog: DateContentCatalog = _catalog()
	var prepared: DatePlayerSnapshot = _player()
	prepared.apartment_prepared = true
	var apt: DateRunResult = _finish_at(catalog, &"apartment", &"casual", prepared)
	_ok("22. venue Trait +1 at matching place", apt.score_breakdown.girl_trait_score == 1)
	_ok("24. prepared apartment 0", apt.score_breakdown.apartment_preparation_score == 0)
	var cafe: DateRunResult = _finish_at(catalog, &"cafe", &"casual", _player())
	_ok("23. venue Trait +0 at other place", cafe.score_breakdown.girl_trait_score == 0)
	var unprepared: DatePlayerSnapshot = _player()
	unprepared.apartment_prepared = false
	var apt2: DateRunResult = _finish_at(catalog, &"apartment", &"casual", unprepared)
	_ok("25. unprepared apartment -1", apt2.score_breakdown.apartment_preparation_score == -1)


func _test_raise_stakes_capital_gate() -> void:
	var locked: DateMoveOption = _find_characteristic_option(4, &"char_status_solve")
	var open: DateMoveOption = _find_characteristic_option(5, &"char_status_solve")
	_ok("28. status solve locked at capital 4", locked != null and locked.availability == DateTypes.MoveAvailability.LOCKED)
	_ok("28. status solve available at capital 5", open != null and open.availability == DateTypes.MoveAvailability.AVAILABLE)

func _find_raise_stakes_option(capital: int) -> DateMoveOption:
	return _find_characteristic_option(capital, &"char_status_solve")


func _find_characteristic_option(capital: int, move_id: StringName) -> DateMoveOption:
	var catalog: DateContentCatalog = _catalog()
	var player: DatePlayerSnapshot = _player()
	player.capital = capital
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 1, _fresh_progress(catalog, &"alina"), player)
	return _episode_option(engine.get_current_episode(), move_id)

func _test_full_date_cycle_result() -> void:
	var catalog: DateContentCatalog = _catalog()
	var progress: GirlProgress = _fresh_progress(catalog, &"alina")
	var engine: DateEngine = _start(catalog, &"alina", &"cafe", &"casual", 21, progress, _player())
	var episodes: int = 0
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		_choose(engine, _first_available(engine))
		episodes += 1
	var result: DateRunResult = engine.get_result()
	_ok("30. five episodes then result", episodes == 5 and result != null and result.score_breakdown != null)
	_ok("30. gain is non-negative", result.score_breakdown.relationship_gain >= 0)
	_ok("30. no outfit_score", not result.score_breakdown.to_dictionary().has("outfit_score"))


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


func _active_session_venue(dating: Variant) -> StringName:
	if dating == null:
		return &""
	var engine: DateEngine = dating.get_date_engine() as DateEngine
	if engine == null:
		return &""
	var session: DateSession = engine.get_session_state()
	if session == null:
		return &""
	return session.venue_id


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


func _daily_activity() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DailyActivityService")


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


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node

func _objective_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ObjectiveService")
	if not is_instance_valid(node):
		return null
	return node


func _guidance_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GuidanceService")
	if not is_instance_valid(node):
		return null
	return node


func _rebuild_objective() -> ObjectiveView:
	var objectives: Variant = _objective_service()
	if objectives == null:
		return null
	objectives.rebuild()
	return objectives.get_current() as ObjectiveView


func _subgoal_by_id(view: ObjectiveView, id: StringName) -> ObjectiveSubgoalView:
	if view == null:
		return null
	for subgoal in view.subgoals:
		if subgoal.id == id:
			return subgoal
	return null


func _current_subgoal(view: ObjectiveView) -> ObjectiveSubgoalView:
	if view == null:
		return null
	return view.current_subgoal()


func _test_objectives() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var objectives: Variant = _objective_service()
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var rivals: Variant = _rivals_service()
	var dating: Variant = _dating_service()
	var clock: Variant = _time_service()
	_ok("ObjectiveService autoload", objectives != null)
	if gs == null or sm == null or objectives == null or girls == null or rating == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/objectives_stage20.json"
	sm.delete_save()
	sm.new_game()
	var view: ObjectiveView = _rebuild_objective()
	_ok("stage 1 actress title", view != null and view.title == "Актриса")
	_ok("stage 1 description", view != null and view.description.contains("Актрисы"))
	var rating_goal: ObjectiveSubgoalView = _subgoal_by_id(view, &"meet_rating")
	_ok("stage 1 rating current", rating_goal != null and rating_goal.is_current and rating_goal.progress_text == "0 / 2")
	_ok("stage 1 next rating", view.next_step_text.contains("Рейтинг для знакомства") and view.next_step_text.contains("0 / 2"))
	_ok("rating target empty", view.target_type == &"" and view.target_location_id == &"")
	rating.add_rating(1)
	view = _rebuild_objective()
	rating_goal = _subgoal_by_id(view, &"meet_rating")
	_ok("rating progress 1/2", rating_goal != null and rating_goal.progress_text == "1 / 2" and not rating_goal.completed)
	rating.add_rating(1)
	view = _rebuild_objective()
	rating_goal = _subgoal_by_id(view, &"meet_rating")
	var meet_goal: ObjectiveSubgoalView = _subgoal_by_id(view, &"meet_girl")
	_ok("rating complete", rating_goal != null and rating_goal.completed and rating_goal.progress_text == "2 / 2")
	_ok("next is meet", meet_goal != null and meet_goal.is_current and view.next_step_text.contains("Познакомиться с Актрисой"))
	_ok("meet target girl", view.target_type == ObjectiveView.TARGET_GIRL and view.target_id == GirlCatalog.ID_ACTRESS)
	_ok("meet target location", view.target_location_id == LocationCatalog.ID_CITY_CENTER)
	girls.discover_girl(GirlCatalog.ID_ACTRESS)
	view = _rebuild_objective()
	var rival_goal: ObjectiveSubgoalView = _subgoal_by_id(view, StringName("date_rival_%s" % String(RivalCatalog.ID_BORIS)))
	_ok("next is rival", rival_goal != null and rival_goal.is_current and view.next_step_text.contains("Борис"))
	_ok("rival target", view.target_type == ObjectiveView.TARGET_RIVAL and view.target_id == RivalCatalog.ID_BORIS)
	_ok("rival location", view.target_location_id == LocationCatalog.ID_CITY_CENTER)
	if rivals != null:
		rivals.defeat_rival(RivalCatalog.ID_BORIS)
	view = _rebuild_objective()
	var rel_goal: ObjectiveSubgoalView = _subgoal_by_id(view, &"relationship")
	_ok("relationship uses max", rel_goal != null and rel_goal.progress_text == "0 / %d" % int(girls.get_relationship_max(GirlCatalog.ID_ACTRESS)))
	_ok("next is invite", rel_goal != null and rel_goal.is_current and view.next_step_text.contains("Пригласить Актрису на свидание"))
	_ok("dating target", view.target_type == ObjectiveView.TARGET_DATING and view.target_id == GirlCatalog.ID_ACTRESS)
	var daily_obj: Variant = _daily_activity()
	if daily_obj != null:
		daily_obj.register_usage(daily_obj.date_key(GirlCatalog.ID_ACTRESS), 1)
	view = _rebuild_objective()
	_ok("cooldown next step", view.next_step_text.contains("Сегодня уже встречались"))
	if clock != null:
		clock.advance_time(1440)
	view = _rebuild_objective()
	_ok("after cooldown invite again", view.next_step_text.contains("Пригласить Актрису на свидание"))
	girls.change_relationship(GirlCatalog.ID_ACTRESS, int(girls.get_relationship_max(GirlCatalog.ID_ACTRESS)))
	view = _rebuild_objective()
	_ok("max advances to dress up", view != null and view.stage == 2 and view.title == "Приоденься")
	gs.story.stage = 3
	view = _rebuild_objective()
	_ok("stage 3 editor", view != null and view.title == "Редактор журнала")
	gs.story.stage = 4
	view = _rebuild_objective()
	_ok("stage 4 scientist", view != null and view.title == "Учёная")
	gs.story.stage = 5
	view = _rebuild_objective()
	_ok("stage 5 president", view != null and view.title == "Президент")
	gs.story.stage = 6
	gs.automation.unlocked = true
	gs.automation.current_expansion_scope = &"city"
	gs.automation.expansion_progress = 40.0
	view = _rebuild_objective()
	_ok("stage 6 factory title", view != null and view.title == "Date Factory")
	var city_reach: ObjectiveSubgoalView = _subgoal_by_id(view, &"factory_reach")
	_ok("stage 6 city progress", city_reach != null and city_reach.progress_text == "40 / 100" and city_reach.is_current)
	gs.automation.expansion_progress = 100.0
	view = _rebuild_objective()
	var expand: ObjectiveSubgoalView = _subgoal_by_id(view, &"factory_expand")
	_ok("city expand cost", expand != null and expand.is_current and expand.progress_text == "10 000")
	gs.automation.current_expansion_scope = &"country"
	gs.automation.expansion_progress = 250.0
	view = _rebuild_objective()
	var country_reach: ObjectiveSubgoalView = _subgoal_by_id(view, &"factory_reach")
	_ok("country progress", country_reach != null and country_reach.progress_text == "250 / 1000")
	_ok("country has city done", _subgoal_by_id(view, &"factory_scope_city") != null and _subgoal_by_id(view, &"factory_scope_city").completed)
	gs.automation.expansion_progress = 1000.0
	view = _rebuild_objective()
	expand = _subgoal_by_id(view, &"factory_expand")
	_ok("country expand cost", expand != null and expand.progress_text == "1 000 000")
	gs.automation.current_expansion_scope = &"world"
	gs.automation.expansion_progress = 5000.0
	view = _rebuild_objective()
	var world_reach: ObjectiveSubgoalView = _subgoal_by_id(view, &"factory_reach")
	_ok("world progress", world_reach != null and world_reach.progress_text == "5000 / 10000")
	gs.automation.expansion_progress = 10000.0
	view = _rebuild_objective()
	world_reach = _subgoal_by_id(view, &"factory_reach")
	_ok("world 100 percent completed", view.completed and world_reach != null and world_reach.progress_text == "100%" and world_reach.completed)
	_ok("world completed before finale", gs.story.finale_reached == false)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_guidance() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var guidance: Variant = _guidance_service()
	_ok("GuidanceService autoload", guidance != null)
	if gs == null or sm == null or guidance == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/guidance_stage20.json"
	sm.delete_save()
	sm.new_game()
	_ok("new save empty guidance", gs.guidance.shown_tutorial_ids.is_empty() and gs.guidance.shown_milestone_ids.is_empty())
	guidance.on_playthrough_reset()
	_ok("objectives intro queued", guidance.request_tutorial(GuidanceCatalog.ID_OBJECTIVES_INTRO))
	_ok("objectives intro active", guidance.get_active_id() == GuidanceCatalog.ID_OBJECTIVES_INTRO)
	guidance.dismiss_current()
	_ok("objectives intro saved", gs.guidance.has_seen_tutorial(GuidanceCatalog.ID_OBJECTIVES_INTRO))
	_ok("repeat objectives intro skipped", guidance.request_tutorial(GuidanceCatalog.ID_OBJECTIVES_INTRO) == false and not guidance.has_active_message())
	_ok("dating intro once", guidance.request_tutorial(GuidanceCatalog.ID_DATING_INTRO))
	guidance.dismiss_current()
	_ok("local objects intro once", guidance.request_tutorial(GuidanceCatalog.ID_LOCAL_OBJECTS_INTRO))
	guidance.dismiss_current()
	_ok("locked moves intro once", guidance.request_tutorial(GuidanceCatalog.ID_LOCKED_MOVES_INTRO))
	guidance.dismiss_current()
	_ok("rival intro once", guidance.request_tutorial(GuidanceCatalog.ID_RIVAL_INTRO))
	guidance.dismiss_current()
	_ok("factory intro once", guidance.request_tutorial(GuidanceCatalog.ID_FACTORY_INTRO))
	guidance.dismiss_current()
	_ok("repeat dating skipped", guidance.request_tutorial(GuidanceCatalog.ID_DATING_INTRO) == false)
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_2)
	guidance.dismiss_current()
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_3)
	guidance.dismiss_current()
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_4)
	guidance.dismiss_current()
	_ok("stage 2-4 milestones once", gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_2) and gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_3) and gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_4))
	_ok("repeat stage 2 skipped", guidance.request_milestone(GuidanceCatalog.ID_STAGE_2) == false)
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_5)
	guidance.request_tutorial(GuidanceCatalog.ID_FACTORY_INTRO)
	_ok("stage 5 milestone first", guidance.get_active_id() == GuidanceCatalog.ID_STAGE_5)
	guidance.dismiss_current()
	_ok("factory already seen after stage 5", not guidance.has_active_message() and gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_5))
	guidance.on_playthrough_reset()
	gs.guidance.shown_tutorial_ids.clear()
	gs.guidance.shown_milestone_ids.clear()
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_5)
	guidance.request_tutorial(GuidanceCatalog.ID_FACTORY_INTRO)
	_ok("queue milestone then factory", guidance.get_active_id() == GuidanceCatalog.ID_STAGE_5)
	guidance.dismiss_current()
	_ok("queue factory after milestone", guidance.get_active_id() == GuidanceCatalog.ID_FACTORY_INTRO)
	guidance.dismiss_current()
	guidance.request_milestone(GuidanceCatalog.ID_STAGE_6)
	guidance.dismiss_current()
	_ok("stage 6 milestone once", gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_6))
	_ok("repeat stage 6 skipped", guidance.request_milestone(GuidanceCatalog.ID_STAGE_6) == false)
	sm.save_game()
	sm.new_game()
	_ok("new game clears guidance history", gs.guidance.shown_tutorial_ids.is_empty())
	sm.load_game()
	_ok("load keeps factory tutorial", gs.guidance.has_seen_tutorial(GuidanceCatalog.ID_FACTORY_INTRO))
	_ok("load keeps stage 5 milestone", gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_5))
	_ok("load keeps stage 6 milestone", gs.guidance.has_seen_milestone(GuidanceCatalog.ID_STAGE_6))
	var guidance_catalog: GuidanceCatalog = guidance.get_catalog() as GuidanceCatalog
	var dating_intro: TutorialDefinition = guidance_catalog.get_tutorial(GuidanceCatalog.ID_DATING_INTRO) if guidance_catalog != null else null
	_ok("21. daily date rule", dating_intro != null and dating_intro.body.contains("одна обычная встреча в календарный день") and dating_intro.body.contains("Сегодня уже встречались. Следующая встреча: завтра."))
	_ok("21. rita same-day", dating_intro != null and dating_intro.body.contains("такси $75"))
	var stage2_milestone: MilestoneDefinition = guidance_catalog.get_milestone(GuidanceCatalog.ID_STAGE_2) if guidance_catalog != null else null
	var stage2_body: String = "\n".join(stage2_milestone.body_lines) if stage2_milestone != null else ""
	_ok("21. stage 2 dress-up onboarding", stage2_body.contains("Приоденься") and not stage2_body.contains("Перерыв между свиданиями"))
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_objective_markers() -> void:
	var sm: Variant = _save_manager()
	var objectives: Variant = _objective_service()
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var rivals: Variant = _rivals_service()
	var gs: Variant = _game_state()
	if sm == null or objectives == null or girls == null or rating == null or gs == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/objective_markers_stage20.json"
	sm.delete_save()
	sm.new_game()
	rating.add_rating(2)
	var view: ObjectiveView = _rebuild_objective()
	_ok("meet marks location", objectives.marker_suffix(&"", &"", LocationCatalog.ID_CITY_CENTER) == ObjectiveView.MARKER_SUFFIX)
	_ok("meet marks girl", objectives.marker_suffix(ObjectiveView.TARGET_GIRL, GirlCatalog.ID_ACTRESS) == ObjectiveView.MARKER_SUFFIX)
	_ok("meet does not mark factory", objectives.marker_suffix(ObjectiveView.TARGET_FACTORY) == "")
	girls.discover_girl(GirlCatalog.ID_ACTRESS)
	view = _rebuild_objective()
	_ok("rival marks location", objectives.marker_suffix(&"", &"", LocationCatalog.ID_CITY_CENTER) == ObjectiveView.MARKER_SUFFIX)
	_ok("rival marks rival", objectives.marker_suffix(ObjectiveView.TARGET_RIVAL, RivalCatalog.ID_BORIS) == ObjectiveView.MARKER_SUFFIX)
	if rivals != null:
		rivals.defeat_rival(RivalCatalog.ID_BORIS)
	view = _rebuild_objective()
	_ok("dating marks girl", objectives.marker_suffix(ObjectiveView.TARGET_DATING, GirlCatalog.ID_ACTRESS) == ObjectiveView.MARKER_SUFFIX)
	_ok("dating does not mark city location", objectives.marker_suffix(&"", &"", LocationCatalog.ID_CITY_CENTER) == "")
	gs.story.stage = 6
	gs.automation.unlocked = true
	gs.automation.current_expansion_scope = &"city"
	gs.automation.expansion_progress = 10.0
	view = _rebuild_objective()
	_ok("stage 6 marks factory", objectives.marker_suffix(ObjectiveView.TARGET_FACTORY) == ObjectiveView.MARKER_SUFFIX)
	_ok("factory does not mark actress", objectives.marker_suffix(ObjectiveView.TARGET_GIRL, GirlCatalog.ID_ACTRESS) == "")
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


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
	_ok("new_game start outfit current", gs.progression.current_outfit_id == OutfitCatalog.START_OUTFIT_ID)
	_ok("new_game last_work_day_index -1", int(gs.player.last_work_day_index) == -1)
	_ok("new_game apartment owned empty", gs.progression.apartment.owned_local_object_ids.is_empty())
	_ok("new_game start location", gs.world.current_location_id == LocationCatalog.START_LOCATION_ID)
	_ok("new_game start unlocked city", gs.world.has_unlocked(LocationCatalog.ID_CITY_CENTER))
	_ok("new_game start unlocked apartment", gs.world.has_unlocked(LocationCatalog.ID_APARTMENT))
	_ok("new_game start unlocked cafe", gs.world.has_unlocked(LocationCatalog.ID_CAFE))
	_ok("new_game restaurant locked", not gs.world.has_unlocked(LocationCatalog.ID_RESTAURANT))
	_ok("new_game apartment date venue", gs.world.has_unlocked_date_venue(&"apartment"))
	_ok("new_game cafe date venue locked", not gs.world.has_unlocked_date_venue(&"cafe"))
	_ok("new_game city stage 1", int(gs.world.city_stage) == 1)
	_ok("new_game girls empty", gs.girls.girls_by_id.is_empty())
	_ok("new_game rivals empty", gs.rivals.rivals_by_id.is_empty())
	_ok("new_game automation locked", gs.automation.unlocked == false)
	_ok("new_game clones 0", gs.automation.total_clones == 0)
	_ok("new_game work percent 50", gs.automation.work_allocation_percent == 50)
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
	_ok("save_version == 18", int(root.get("save_version", 0)) == 18)
	_ok("SAVE_VERSION constant 17", int(sm.SAVE_VERSION) == 17)
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
	_ok("section guidance", gs.guidance != null)
	_ok("new_game guidance empty", gs.guidance.shown_tutorial_ids.is_empty() and gs.guidance.shown_milestone_ids.is_empty())
	gs.from_dict({"flow": {}, "story": {}, "player": {}})
	_ok("missing keys default game_time_minutes", gs.flow.game_time_minutes == 0)
	_ok("missing keys default day", clock.get_day() == 1)
	_ok("missing keys default stage", gs.story.stage == 1)
	_ok("missing keys default finale", gs.story.finale_reached == false)
	_ok("missing keys default money", gs.player.money == 0)
	_ok("missing keys default rating", gs.player.rating == 0)
	_ok("missing keys default location", gs.world.current_location_id == LocationCatalog.START_LOCATION_ID)
	_ok("missing keys default unlocked city", gs.world.has_unlocked(LocationCatalog.ID_CITY_CENTER))
	sm.new_game()
	gs.world.city_stage = 2
	var girls_svc: Variant = _girls_service()
	var rivals_svc: Variant = _rivals_service()
	if girls_svc != null:
		girls_svc.give_contact(GirlCatalog.ID_ALINA)
		girls_svc.get_state(GirlCatalog.ID_ALINA).revealed_positive_tag_ids.append(&"care")
	if rivals_svc != null:
		rivals_svc.discover_rival(RivalCatalog.ID_BORIS)
	gs.player.last_work_day_index = 0
	sm.save_game()
	sm.new_game()
	_ok("round-trip load", sm.load_game())
	_ok("round-trip city_stage", int(gs.world.city_stage) == 2)
	_ok("round-trip last_work_day_index", int(gs.player.last_work_day_index) == 0)
	if girls_svc != null:
		var loaded_girl: GirlState = girls_svc.get_state(GirlCatalog.ID_ALINA)
		_ok("round-trip tag knowledge", loaded_girl != null and loaded_girl.revealed_positive_tag_ids.has(&"care"))
		_ok("round-trip no secondary_revealed", loaded_girl != null and not loaded_girl.to_dict().has("secondary_revealed"))
	if rivals_svc != null:
		_ok("round-trip rival discovered", rivals_svc.is_discovered(RivalCatalog.ID_BORIS))
	sm.delete_save()
	var folder_v14: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder_v14))
	var v14_file: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v14 core save", v14_file != null)
	if v14_file != null:
		var v14: Dictionary = {
			"save_version": 14,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {
					"purchased_ids": [],
					"owned_outfit_ids": ["casual", "business", "luxury"],
					"equipped_outfit_id": "business",
				},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
					"city_stage": 2,
				},
				"girls": {
					"girls_by_id": {
						"alina": {
							"discovered": true,
							"has_contact": true,
							"relationship": -3,
							"secondary_revealed": true,
							"revealed_positive_tag_ids": ["care"],
						},
					},
				},
				"dating": {"active_date": {}},
				"rivals": {"rivals_by_id": {}},
			},
		}
		v14_file.store_string(JSON.stringify(v14, "\t"))
		v14_file.close()
	_ok("load v14 core save", sm.load_game())
	_ok("v14 migrated last_work_day_index", int(gs.player.last_work_day_index) == -1)
	_ok("v14 migrated relationship floor", girls_svc != null and int(girls_svc.get_relationship(GirlCatalog.ID_ALINA)) == 0)
	_ok("v14 migrated current outfit business", gs.progression.current_outfit_id == OutfitCatalog.ID_BUSINESS)
	if girls_svc != null:
		var migrated_v14: GirlState = girls_svc.get_state(GirlCatalog.ID_ALINA)
		_ok("v14 stripped secondary_revealed", migrated_v14 != null and not migrated_v14.to_dict().has("secondary_revealed"))
		_ok("v14 kept tag knowledge", migrated_v14 != null and migrated_v14.revealed_positive_tag_ids.has(&"care"))
	_ok("v14 kept city_stage", int(gs.world.city_stage) == 2)
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
	_ok("advance 1 to 2", stages.force_complete_current_stage_for_dev())
	_assert_campaign("after first complete", stages, 2, false)
	sm.new_game()
	for step in range(5):
		_ok("sequence complete %d" % (step + 1), stages.force_complete_current_stage_for_dev())
	_assert_campaign("after five completes", stages, 6, false)
	_ok("enter finale", stages.force_complete_current_stage_for_dev())
	_assert_campaign("finale", stages, 6, true)
	_ok("repeat after finale returns false", stages.force_complete_current_stage_for_dev() == false)
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
	_ok("complete 3 to 4", stages.force_complete_current_stage_for_dev())
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
	_ok("complete stage 6", stages.force_complete_current_stage_for_dev())
	_ok("finale_reached once", finale_events.size() == 1)
	_ok("complete after finale false", stages.force_complete_current_stage_for_dev() == false)
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


func _test_stage_story_rules() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	var girls: Variant = _girls_service()
	var world: Variant = _world_service()
	_ok("story GameState", gs != null)
	_ok("story SaveManager", sm != null)
	_ok("story StageService", stages != null)
	_ok("story GirlsService", girls != null)
	_ok("story WorldService", world != null)
	if gs == null or sm == null or stages == null or girls == null or world == null:
		return
	var catalog: StageCatalog = stages.get_catalog() as StageCatalog
	_ok("story catalog", catalog != null)
	if catalog == null:
		return
	_clear_stage_enter_effects(catalog)

	sm.new_game()
	var rel_req: GirlRelationshipRequirement = GirlRelationshipRequirement.new()
	rel_req.girl_id = GirlCatalog.ID_ACTRESS
	rel_req.target_relationship = 5
	girls.change_relationship(GirlCatalog.ID_ACTRESS, 3)
	_ok("req unmet at 3", rel_req.is_met() == false)
	_ok("req current 3", rel_req.get_current_value() == 3)
	_ok("req target 5", rel_req.get_target_value() == 5)
	girls.change_relationship(GirlCatalog.ID_ACTRESS, 2)
	_ok("req met at 5", rel_req.is_met())

	sm.new_game()
	var actress_max: int = int(girls.get_relationship_max(GirlCatalog.ID_ACTRESS))
	girls.change_relationship(GirlCatalog.ID_ACTRESS, actress_max - 1)
	_ok("auto can_complete false", stages.can_complete_current_stage() == false)
	girls.change_relationship(GirlCatalog.ID_ACTRESS, 1)
	_ok("auto stage 2", stages.get_current_stage() == 2)

	sm.new_game()
	var alina_max: int = int(girls.get_relationship_max(GirlCatalog.ID_ALINA))
	girls.change_relationship(GirlCatalog.ID_ALINA, alina_max)
	_ok("wrong girl stage 1", stages.get_current_stage() == 1)
	var vika_max: int = int(girls.get_relationship_max(GirlCatalog.ID_VIKA))
	girls.change_relationship(GirlCatalog.ID_VIKA, vika_max)
	_ok("wrong vika stage 1", stages.get_current_stage() == 1)
	girls.change_relationship(GirlCatalog.ID_ACTRESS, actress_max)
	_ok("actress max stage 2", stages.get_current_stage() == 2)

	var stage2: StageDefinition = catalog.get_stage(2)
	_ok("stage 2 definition", stage2 != null)
	if stage2 != null:
		var unlock_effect: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
		unlock_effect.location_id = LocationCatalog.ID_RESTAURANT
		stage2.on_enter_effects.append(unlock_effect)
		sm.new_game()
		_ok("enter restaurant locked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
		var signal_order: Array = []
		var on_completed := func(completed_stage: int) -> void:
			signal_order.append({"name": "completed", "stage": completed_stage})
		var on_changed := func(previous_stage: int, current_stage: int) -> void:
			signal_order.append({
				"name": "changed",
				"previous_stage": previous_stage,
				"current_stage": current_stage,
				"restaurant_unlocked": bool(world.is_location_unlocked(LocationCatalog.ID_RESTAURANT)),
			})
		stages.stage_completed.connect(on_completed)
		stages.stage_changed.connect(on_changed)
		girls.change_relationship(GirlCatalog.ID_ACTRESS, actress_max)
		stages.stage_completed.disconnect(on_completed)
		stages.stage_changed.disconnect(on_changed)
		_ok("enter stage 2", stages.get_current_stage() == 2)
		_ok("enter restaurant unlocked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
		var unlocked_during_changed: bool = false
		if signal_order.size() >= 2:
			var changed_payload: Dictionary = signal_order[1]
			unlocked_during_changed = bool(changed_payload.get("restaurant_unlocked", false))
		_ok("enter unlocked during changed", unlocked_during_changed)
		_ok("enter signal count", signal_order.size() == 2)
		if signal_order.size() >= 1:
			var completed_payload: Dictionary = signal_order[0]
			_ok("enter completed first", str(completed_payload.get("name", "")) == "completed")
			_ok("enter completed stage", int(completed_payload.get("stage", 0)) == 1)
		if signal_order.size() >= 2:
			var changed_payload: Dictionary = signal_order[1]
			_ok("enter changed second", str(changed_payload.get("name", "")) == "changed")
			_ok("enter changed previous", int(changed_payload.get("previous_stage", 0)) == 1)
			_ok("enter changed current", int(changed_payload.get("current_stage", 0)) == 2)
		stage2.on_enter_effects.clear()

	var stage1: StageDefinition = catalog.get_stage(1)
	var stage3: StageDefinition = catalog.get_stage(3)
	_ok("reconcile stage 1", stage1 != null)
	_ok("reconcile stage 2", stage2 != null)
	if stage1 != null and stage2 != null:
		var effect1: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
		effect1.location_id = LocationCatalog.ID_RESTAURANT
		var effect2: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
		effect2.location_id = LocationCatalog.ID_RESTAURANT
		stage1.on_enter_effects.append(effect1)
		stage2.on_enter_effects.append(effect2)
		sm.new_game()
		gs.story.stage = 3
		gs.world.unlocked_location_ids.erase(LocationCatalog.ID_RESTAURANT)
		_ok("reconcile restaurant removed", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
		stages.reconcile_stage_entry_state()
		_ok("reconcile restaurant unlocked", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
		var unlocked_after: Array = gs.world.unlocked_location_ids.duplicate()
		stages.reconcile_stage_entry_state()
		_ok("reconcile restaurant still", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
		_ok("reconcile unlock set same", gs.world.unlocked_location_ids.size() == unlocked_after.size())
		_ok("reconcile restaurant unique", gs.world.unlocked_location_ids.count(LocationCatalog.ID_RESTAURANT) == 1)
		stage1.on_enter_effects.clear()
		stage2.on_enter_effects.clear()
		if stage3 != null:
			stage3.on_enter_effects.clear()

	var original_path: String = sm.save_path
	sm.save_path = "user://saves/stage_story_progress.json"
	sm.delete_save()
	sm.new_game()
	girls.change_relationship(GirlCatalog.ID_ACTRESS, 3)
	sm.save_game()
	sm.new_game()
	_ok("progress clean load path", sm.load_game())
	var loaded_req: StageRequirement = stages.get_current_requirement() as StageRequirement
	_ok("progress requirement", loaded_req != null)
	if loaded_req != null:
		_ok("progress current 3", loaded_req.get_current_value() == 3)
		_ok("progress target actress max", loaded_req.get_target_value() == actress_max)
		_ok("progress unmet", loaded_req.is_met() == false)
	sm.delete_save()
	sm.save_path = original_path

	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = false
	var stage6: StageDefinition = stages.get_current_definition() as StageDefinition
	_ok("stage 6 definition", stage6 != null)
	if stage6 != null:
		_ok("stage 6 world reach req", stage6.completion_requirement is WorldReachRequirement)
		_ok("stage 6 world unmet", stage6.completion_requirement != null and stage6.completion_requirement.is_met() == false)
	_ok("stage 6 can_complete false", stages.can_complete_current_stage() == false)
	_ok("stage 6 try_complete false", stages.try_complete_current_stage() == false)
	_ok("stage 6 stays", stages.get_current_stage() == 6)
	_ok("stage 6 finale false", stages.is_finale_reached() == false)

	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = false
	var finale_events: Array = []
	var on_finale := func() -> void:
		finale_events.append(true)
	stages.finale_reached.connect(on_finale)
	_ok("dev finale force", stages.force_complete_current_stage_for_dev())
	_ok("dev finale stage 6", stages.get_current_stage() == 6)
	_ok("dev finale true", stages.is_finale_reached())
	_ok("dev finale signal once", finale_events.size() == 1)
	_ok("dev finale repeat false", stages.force_complete_current_stage_for_dev() == false)
	_ok("dev finale still once", finale_events.size() == 1)
	stages.finale_reached.disconnect(on_finale)

	sm.new_game()
	var story_ids: Array[StringName] = [
		GirlCatalog.ID_ACTRESS,
		GirlCatalog.ID_MINE_BOSS,
		GirlCatalog.ID_MAGAZINE_EDITOR,
		GirlCatalog.ID_SCIENTIST,
		GirlCatalog.ID_PRESIDENT,
	]
	for index in range(story_ids.size()):
		var girl_id: StringName = story_ids[index]
		var max_value: int = int(girls.get_relationship_max(girl_id))
		girls.change_relationship(girl_id, max_value)
		var expected_stage: int = index + 2
		_ok("skeleton stage after %d" % (index + 1), stages.get_current_stage() == expected_stage)
		var definition: StageDefinition = stages.get_current_definition() as StageDefinition
		_ok("skeleton definition %d" % expected_stage, definition != null and definition.stage == expected_stage)
		var requirement: StageRequirement = stages.get_current_requirement() as StageRequirement
		if expected_stage == 6:
			_ok("skeleton stage 6 world reach", requirement is WorldReachRequirement)
			_ok("skeleton stage 6 unmet", requirement != null and requirement.is_met() == false)
		else:
			_ok("skeleton req typed %d" % expected_stage, requirement is GirlRelationshipRequirement)
			var girl_req: GirlRelationshipRequirement = requirement as GirlRelationshipRequirement
			_ok("skeleton req girl %d" % expected_stage, girl_req != null and girl_req.girl_id == story_ids[index + 1])

	_clear_stage_enter_effects(catalog)
	catalog.apply_canonical_enter_effects()
	sm.new_game()


func _clear_stage_enter_effects(catalog: StageCatalog) -> void:
	if catalog == null:
		return
	for stage_number in range(1, 7):
		var definition: StageDefinition = catalog.get_stage(stage_number)
		if definition != null:
			definition.on_enter_effects.clear()


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
	sm.new_game()
	gs.player.money = 0
	gs.flow.game_time_minutes = 0
	_ok("work available new day", WorkService.is_work_available_today())
	var day_work: ActionResult = actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	_ok("work first success", day_work.success)
	_ok("work time_cost 60", day_work.time_spent_minutes == 60)
	_ok("work unavailable same day", WorkService.is_work_available_today() == false)
	var same_day: ActionResult = actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	_ok("work same day fail", same_day.success == false)
	_ok("work same day reason", same_day.failure_reason == "Сегодня уже работали.")
	clock.advance_time(1440)
	_ok("work available after midnight", WorkService.is_work_available_today())
	var next_day: ActionResult = actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	_ok("work next day success", next_day.success)
	var daily: Variant = _daily_activity()
	_ok("work usage 1 after shift", daily != null and int(daily.usage_today("work")) == 1)
	sm.save_game()
	sm.new_game()
	_ok("work usage reset new game", daily != null and int(daily.usage_today("work")) == 0)
	_ok("load work day save", sm.load_game())
	_ok("loaded work usage", daily != null and int(daily.usage_today("work")) == 1)
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
	_ok("work_basic time_cost 60", work.time_cost_minutes == 60)
	_ok("work_basic tier 100", WorkService.TIER_1_INCOME == 100)
	_ok("work_basic tier 200", WorkService.TIER_2_INCOME == 200)
	_ok("work available new day", WorkService.is_work_available_today())
	var work_first: ActionResult = actions.execute(work_action)
	_ok("work_basic first success", work_first.success)
	_ok("work_basic first money", gs.player.money == 100)
	_ok("work_basic first time", clock.get_game_time_minutes() == 60)
	_ok("work unavailable same day", WorkService.is_work_available_today() == false)
	var work_second: ActionResult = actions.execute(WorkService.create_work_action(work))
	_ok("work_basic second fail", work_second.success == false)
	_ok("work_basic second money unchanged", gs.player.money == 100)
	_ok("work_basic second time unchanged", clock.get_game_time_minutes() == 60)
	clock.advance_time(1440)
	_ok("work available next day", WorkService.is_work_available_today())
	var work_next: ActionResult = actions.execute(WorkService.create_work_action(work))
	_ok("work_basic next day success", work_next.success)
	_ok("work_basic next day money", gs.player.money == 200)
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
	for i in range(3):
		if i > 0:
			clock.advance_time(1440)
		actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	_ok("cycle money 300", gs.player.money == 300)
	var cycle_time: int = int(clock.get_game_time_minutes())
	var cycle_buy: ActionResult = actions.execute(purchases.create_purchase_action(definition))
	_ok("cycle buy success", cycle_buy.success)
	_ok("cycle money 0", gs.player.money == 0)
	_ok("cycle purchased", purchases.is_purchased(&"basic_upgrade"))
	_ok("cycle time unchanged after buy", int(clock.get_game_time_minutes()) == cycle_time)
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
	_ok("world new leisure locked", world.is_location_unlocked(LocationCatalog.ID_LEISURE_CENTER) == false)
	_ok("world new furniture locked", world.is_location_unlocked(LocationCatalog.ID_FURNITURE_STORE) == false)
	_ok("world catalog leisure", world.get_catalog().get_location(LocationCatalog.ID_LEISURE_CENTER) != null)
	_ok("world catalog furniture", world.get_catalog().get_location(LocationCatalog.ID_FURNITURE_STORE) != null)
	_ok("world new apartment date venue", world.has_unlocked_date_venue(&"apartment"))
	_ok("world new cafe date venue locked", world.has_unlocked_date_venue(&"cafe") == false)
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
	_ok("alina location city_center", alina_def != null and alina_def.location_id == LocationCatalog.ID_CITY_CENTER)
	_ok("vika definition", vika_def != null and vika_def.display_name == "Вика")
	_ok("vika location cafe", vika_def != null and vika_def.location_id == LocationCatalog.ID_CAFE)
	var default_state: GirlState = GirlState.new()
	_ok("default discovered false", default_state.discovered == false)
	_ok("default has_contact false", default_state.has_contact == false)
	_ok("default relationship 0", default_state.relationship == 0)
	_ok("default last_date_situation_ids empty", default_state.last_date_situation_ids.is_empty())
	_ok("default revealed tags empty", default_state.revealed_positive_tag_ids.is_empty() and default_state.revealed_negative_tag_ids.is_empty())
	_ok("default serialize no secondary_revealed", not default_state.to_dict().has("secondary_revealed"))
	_ok("default completed_dates 0", default_state.completed_dates == 0)
	var created: GirlState = girls.get_state(alina_id)
	_ok("created state defaults", created != null and created.discovered == false and created.has_contact == false and created.relationship == 0)
	_ok("created stored", gs.girls.girls_by_id.has(alina_id))
	var gs_dump: Dictionary = gs.to_dict()
	var girls_dump: Variant = gs_dump.get("girls", {})
	var by_id: Variant = girls_dump.get("girls_by_id", {}) if girls_dump is Dictionary else {}
	var alina_dump: Variant = by_id.get(String(alina_id), {}) if by_id is Dictionary else {}
	_ok("game state serialize no secondary_revealed", alina_dump is Dictionary and not (alina_dump as Dictionary).has("secondary_revealed"))
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
	_ok("relationship floor at 0", girls.change_relationship(alina_id, -1) == 0)
	_ok("relationship stays 0", girls.get_relationship(alina_id) == 0)
	_ok("relationship plus two", girls.change_relationship(alina_id, 2) == 2)
	_ok("relationship after plus", girls.get_relationship(alina_id) == 2)
	_ok("relationship minus one", girls.change_relationship(alina_id, -1) == 1)
	_ok("relationship after minus", girls.get_relationship(alina_id) == 1)
	_ok("relationship plus to 3", girls.change_relationship(alina_id, 2) == 3)
	_ok("relationship drop from 3", girls.change_relationship(alina_id, -1) == 2)
	_ok("relationship ordinary max 10", int(girls.get_relationship_max(alina_id)) == 10)
	_ok("kira max 10", int(girls.get_relationship_max(GirlCatalog.ID_KIRA)) == 10)
	_ok("eva max 10", int(girls.get_relationship_max(GirlCatalog.ID_EVA)) == 10)
	_ok("actress max 10", int(girls.get_relationship_max(GirlCatalog.ID_ACTRESS)) == 10)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var at_city: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("city has alina", _girl_list_has(at_city, alina_id))
	_ok("city no vika", _girl_list_has(at_city, vika_id) == false)
	world.enter_location(LocationCatalog.ID_APARTMENT)
	var at_apartment: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("apartment no alina", _girl_list_has(at_apartment, alina_id) == false)
	world.enter_location(LocationCatalog.ID_CAFE)
	var at_cafe: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("cafe has vika", _girl_list_has(at_cafe, vika_id))
	_ok("cafe no alina", _girl_list_has(at_cafe, alina_id) == false)
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var at_restaurant: Array[GirlDefinition] = girls.get_girls_at_current_location()
	_ok("restaurant no vika", _girl_list_has(at_restaurant, vika_id) == false)
	_ok("restaurant no alina", _girl_list_has(at_restaurant, alina_id) == false)
	sm.new_game()
	var contact_req := GirlContactRequirement.new()
	contact_req.girl_id = alina_id
	_ok("contact req new game false", contact_req.is_met() == false)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
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
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
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
	sim.enter_world_location(LocationCatalog.ID_CITY_CENTER)
	var city_people: String = sim.get_city_body_text()
	_ok("sim city alina", city_people.contains("Алина"))
	_ok("sim city later girls", city_people.contains("Катя") and city_people.contains("Лера"))
	_ok("sim city rating gates", city_people.contains("Требования для знакомства:"))
	_ok("sim city meet button", city_people.contains("ПОЗНАКОМИТЬСЯ"))
	var sim_meet: ActionResult = sim.meet_girl(alina_id)
	_ok("sim meet success", sim_meet.success)
	_ok("sim meet result name", sim.get_result_text().contains("Вы познакомились с Алина."))
	_ok("sim meet result contact", sim.get_result_text().contains("Получен контакт."))
	_ok("sim meet result time", sim.get_result_text().contains("Прошло времени: 30 минут."))
	var known_text: String = sim.get_city_body_text()
	_ok("sim city alina contact", known_text.contains("Контакт: Да"))
	_ok("sim city other meet remains", known_text.contains("ПОЗНАКОМИТЬСЯ"))
	sim.show_section("girls")
	var girls_text: String = sim.get_city_body_text()
	_ok("sim girls alina", girls_text.contains("АЛИНА"))
	_ok("sim girls relationship", girls_text.contains("Отношения: 0 / %d" % int(girls.get_relationship_max(GirlCatalog.ID_ALINA))))
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
	var alina_max: int = int(girls.get_relationship_max(alina_id))
	_ok("rating new game 0", int(rating.get_rating()) == 0)
	girls.get_state(alina_id).relationship = alina_max - 1
	_ok("rating plus one at max", girls.change_relationship(alina_id, 1) == alina_max)
	_ok("relationship at max", girls.get_relationship(alina_id) == alina_max)
	_ok("rating after max", int(rating.get_rating()) == 1)
	_ok("relationship completed", girls.is_relationship_completed(alina_id))
	sm.new_game()
	girls.get_state(alina_id).relationship = alina_max - 1
	_ok("rating large delta clamps", girls.change_relationship(alina_id, 10) == alina_max)
	_ok("rating large delta once", int(rating.get_rating()) == 1)
	_ok("rating repeat no extra", girls.change_relationship(alina_id, 1) == alina_max)
	_ok("rating stays 1", int(rating.get_rating()) == 1)
	_ok("relationship stays max", girls.get_relationship(alina_id) == alina_max)
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
	var start_action: GameAction = dating.create_start_date_action(alina_id, &"apartment")
	_ok("start action id", start_action.id == StringName("start_date_alina"))
	_ok("start action no time", start_action.time_cost_minutes == 0)
	_ok("start action no money", start_action.money_cost == 0)
	var start_ok: ActionResult = actions.execute(start_action)
	_ok("start date success", start_ok.success)
	_ok("has active date", dating.has_active_date())
	_ok("active girl id", dating.get_active_girl_id() == alina_id)
	_ok("active location id", dating.get_active_venue_id() == &"apartment")
	_ok("active_date girl", String(gs.dating.active_date.get("girl_id", "")) == String(alina_id))
	_ok("active_date location", String(gs.dating.active_date.get("venue_id", "")) == "apartment")
	_ok("session location apartment", _active_session_venue(dating) == &"apartment")
	sm.new_game()
	girls.discover_girl(alina_id)
	_ok("start without contact", dating.can_start_date(alina_id) == false)
	_ok("start without contact reason", dating.get_start_date_failure_reason(alina_id) == "У вас нет контакта этой девушки")
	var no_contact: ActionResult = actions.execute(dating.create_start_date_action(alina_id, &"apartment"))
	_ok("start without contact fail", no_contact.success == false)
	sm.new_game()
	girls.give_contact(alina_id)
	clock.advance_time(60)
	var daily_alina: Variant = _daily_activity()
	if daily_alina != null:
		daily_alina.register_usage(daily_alina.date_key(alina_id), 1)
	_ok("start during cooldown", dating.can_start_date(alina_id) == false)
	_ok("start cooldown reason", dating.get_start_date_failure_reason(alina_id) == "Сегодня уже встречались. Следующая встреча: завтра.")
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = int(girls.get_relationship_max(alina_id))
	_ok("start after max", dating.can_start_date(alina_id) == false)
	_ok("start after max reason", dating.get_start_date_failure_reason(alina_id) == "Отношения с этой девушкой уже достигли максимума")
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = 1
	gs.flow.game_time_minutes = 1000
	_ok("complete start", dating.start_date(alina_id, &"apartment"))
	var date_result := DateResult.new()
	date_result.girl_id = alina_id
	date_result.relationship_delta = 1
	date_result.duration_minutes = 120
	_ok("complete date", dating.complete_date(date_result))
	_ok("complete relationship 2", girls.get_relationship(alina_id) == 2)
	_ok("complete time 1120", int(clock.get_game_time_minutes()) == 1120)
	_ok("complete daily used", dating.is_free_date_available_today(alina_id) == false)
	_ok("complete active cleared", dating.has_active_date() == false)
	_ok("complete active dict empty", gs.dating.active_date.is_empty())
	sm.save_game()
	sm.new_game()
	_ok("daily reset new game", dating.is_free_date_available_today(alina_id))
	_ok("load cooldown save", sm.load_game())
	_ok("loaded daily used", dating.is_free_date_available_today(alina_id) == false)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	_ok("knowledge start", dating.start_date(alina_id, &"apartment"))
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
	var daily_knowledge: Variant = _daily_activity()
	if daily_knowledge != null:
		daily_knowledge.set_usage_today(daily_knowledge.date_key(alina_id), 0)
	_ok("knowledge second start", dating.start_date(alina_id, &"apartment"))
	var second_engine: DateEngine = dating.get_date_engine()
	var second_progress: GirlProgress = second_engine.girl_progress() if second_engine != null else null
	_ok("knowledge next date", second_progress != null and second_progress.tag_knowledge(revealed_id) == first_knowledge)
	sm.delete_save()
	sm.new_game()
	girls.give_contact(alina_id)
	girls.get_state(alina_id).relationship = alina_max - 1
	gs.flow.game_time_minutes = 0
	_ok("cycle start", dating.start_date(alina_id, &"apartment"))
	var cycle_result := DateResult.new()
	cycle_result.girl_id = alina_id
	cycle_result.relationship_delta = 1
	cycle_result.duration_minutes = 120
	_ok("cycle complete", dating.complete_date(cycle_result))
	_ok("cycle relationship max", girls.get_relationship(alina_id) == alina_max)
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
	_ok("active start", dating.start_date(alina_id, &"apartment"))
	sm.save_game()
	sm.new_game()
	_ok("active reset new game", dating.has_active_date() == false)
	_ok("load active save", sm.load_game())
	_ok("loaded active date", dating.has_active_date())
	_ok("loaded active girl", dating.get_active_girl_id() == alina_id)
	_ok("loaded active location", dating.get_active_venue_id() == &"apartment")
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
	_ok("migrated no secondary_revealed", migrated_girl != null and not migrated_girl.to_dict().has("secondary_revealed"))
	_ok("migrated completed_dates 0", migrated_girl != null and migrated_girl.completed_dates == 0)
	var sim := GameSimulator.new()
	tree.root.add_child(sim)
	sim.start_new_game()
	_ok("sim hud rating", sim.get_hud_text().contains("Rating: 0"))
	girls.give_contact(alina_id)
	sim.show_section("dates")
	var dates_text: String = sim.get_city_body_text()
	_ok("sim dates alina", dates_text.contains("АЛИНА"))
	_ok("sim dates relationship", dates_text.contains("Отношения: 0 / %d" % int(girls.get_relationship_max(alina_id))))
	_ok("sim dates invite", dates_text.contains("ПРИГЛАСИТЬ"))
	sim.invite_girl(alina_id)
	var picker_text: String = sim.get_city_body_text()
	_ok("sim dates picker", picker_text.contains("ВЫБЕРИТЕ МЕСТО СВИДАНИЯ"))
	_ok("sim dates cafe", picker_text.contains("Кафе") or picker_text.contains("Квартира"))
	_ok("sim dates toolkit window", picker_text.contains("Квартира") or picker_text.contains("Кафе") or picker_text.contains("Окно"))
	_ok("sim dates no preferred", not picker_text.contains("Предпочитаемое место"))
	sim.select_date_venue(&"apartment")
	var selected_text: String = sim.get_city_body_text()
	_ok("sim dates selected", selected_text.contains("Место:"))
	_ok("sim dates outfit picker", selected_text.contains("ВЫБЕРИТЕ ОДЕЖДУ"))
	sim.select_date_outfit(&"casual")
	var invite: ActionResult = sim.start_selected_date()
	_ok("sim invite success", invite.success)
	_ok("sim invite active", dating.has_active_date())
	_ok("sim invite location", dating.get_active_venue_id() == &"apartment")
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


func _test_girl_access_requirements() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var dating: Variant = _dating_service()
	var rivals: Variant = _rivals_service()
	var actions: Variant = _action_service()
	_ok("access GameState", gs != null)
	_ok("access SaveManager", sm != null)
	_ok("access TimeService", clock != null)
	_ok("access StageService", stages != null)
	_ok("access WorldService", world != null)
	_ok("access GirlsService", girls != null)
	_ok("access RatingService", rating != null)
	_ok("access DatingService", dating != null)
	_ok("access RivalsService", rivals != null)
	_ok("access ActionService", actions != null)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	_ok("access tree", tree != null and tree.root != null)
	if gs == null or sm == null or clock == null or stages == null or world == null or girls == null or rating == null or dating == null or rivals == null or actions == null or tree == null or tree.root == null:
		return
	var alina_id: StringName = GirlCatalog.ID_ALINA
	var alina_def: GirlDefinition = girls.get_definition(alina_id)
	_ok("access alina definition", alina_def != null)
	if alina_def == null:
		return
	var actress_def: GirlDefinition = girls.get_definition(GirlCatalog.ID_ACTRESS)
	_ok("access actress definition", actress_def != null)
	var catalog: StageCatalog = stages.get_catalog() as StageCatalog
	_ok("access stage catalog", catalog != null)
	if catalog == null:
		return
	var stage6: StageDefinition = catalog.get_stage(6)
	var original_meet: Array[GirlAccessRequirement] = []
	original_meet.assign(alina_def.meet_requirements)
	var original_date: Array[GirlAccessRequirement] = []
	original_date.assign(alina_def.date_requirements)
	var original_actress_max: int = 0
	if actress_def != null:
		original_actress_max = actress_def.relationship_max
	var original_stage6_req: StageRequirement = stage6.completion_requirement if stage6 != null else null
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/girl_access_requirements.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	var rating_req: RatingGirlRequirement = RatingGirlRequirement.new()
	rating_req.required_rating = 5
	gs.player.rating = 3
	_ok("30 rating unmet", rating_req.is_met(alina_id) == false)
	_ok("30 rating description", rating_req.get_description(alina_id) == "Рейтинг")
	_ok("30 rating progress 3", rating_req.get_progress_text(alina_id) == "3 / 5")
	gs.player.rating = 5
	_ok("30 rating met", rating_req.is_met(alina_id))
	_ok("30 rating progress 5", rating_req.get_progress_text(alina_id) == "5 / 5")
	sm.new_game()
	var rival_req: RivalDefeatedGirlRequirement = RivalDefeatedGirlRequirement.new()
	rival_req.rival_id = RivalCatalog.ID_BORIS
	_ok("31 rival unmet", rival_req.is_met(alina_id) == false)
	_ok("31 defeat", rivals.defeat_rival(RivalCatalog.ID_BORIS))
	_ok("31 rival met", rival_req.is_met(alina_id))
	_ok("31 rival description", rival_req.get_description(alina_id).contains("Борис"))
	_ok("31 rival stuntman", rival_req.get_description(alina_id).contains("каскадёр"))
	sm.new_game()
	var min_req: MinStageGirlRequirement = MinStageGirlRequirement.new()
	min_req.minimum_stage = 3
	gs.story.stage = 2
	_ok("32 stage 2 unmet", min_req.is_met(alina_id) == false)
	gs.story.stage = 3
	_ok("32 stage 3 met", min_req.is_met(alina_id))
	gs.story.stage = 4
	_ok("32 stage 4 met", min_req.is_met(alina_id))
	sm.new_game()
	var meet_min: MinStageGirlRequirement = MinStageGirlRequirement.new()
	meet_min.minimum_stage = 2
	var meet_rating: RatingGirlRequirement = RatingGirlRequirement.new()
	meet_rating.required_rating = 5
	var several_meet: Array[GirlAccessRequirement] = []
	several_meet.append(meet_min)
	several_meet.append(meet_rating)
	alina_def.meet_requirements = several_meet
	gs.story.stage = 2
	gs.player.rating = 3
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var several_status: Array[RequirementStatus] = girls.get_meet_requirements_status(alina_id)
	var stage_met: bool = false
	var rating_met: bool = true
	for status in several_status:
		if status == null:
			continue
		if status.description == "Этап игры":
			stage_met = status.is_met
		elif status.description == "Рейтинг":
			rating_met = status.is_met
	_ok("33 stage met", stage_met)
	_ok("33 rating unmet", rating_met == false)
	_ok("33 cannot meet", girls.can_meet_girl(alina_id) == false)
	gs.player.rating = 5
	_ok("33 can meet", girls.can_meet_girl(alina_id))
	alina_def.meet_requirements = original_meet
	sm.new_game()
	var atomic_rating: RatingGirlRequirement = RatingGirlRequirement.new()
	atomic_rating.required_rating = 5
	var atomic_meet: Array[GirlAccessRequirement] = []
	atomic_meet.append(atomic_rating)
	alina_def.meet_requirements = atomic_meet
	gs.player.rating = 3
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	gs.flow.game_time_minutes = 0
	var meet_action: GameAction = girls.create_meet_girl_action(alina_id)
	var blocked_meet: ActionResult = actions.execute(meet_action)
	_ok("34 meet blocked", blocked_meet.success == false)
	_ok("34 undiscovered", girls.is_discovered(alina_id) == false)
	_ok("34 no contact", girls.has_contact(alina_id) == false)
	_ok("34 time unchanged", int(clock.get_game_time_minutes()) == 0)
	gs.player.rating = 5
	var allowed_meet: ActionResult = actions.execute(meet_action)
	_ok("34 meet success", allowed_meet.success)
	_ok("34 discovered", girls.is_discovered(alina_id))
	_ok("34 contact", girls.has_contact(alina_id))
	_ok("34 time 30", int(clock.get_game_time_minutes()) == 30)
	alina_def.meet_requirements = original_meet
	sm.new_game()
	girls.give_contact(alina_id)
	var date_rival: RivalDefeatedGirlRequirement = RivalDefeatedGirlRequirement.new()
	date_rival.rival_id = RivalCatalog.ID_BORIS
	var date_list: Array[GirlAccessRequirement] = []
	date_list.append(date_rival)
	alina_def.date_requirements = date_list
	_ok("35 cannot start", dating.can_start_date(alina_id) == false)
	_ok("35 defeat", rivals.defeat_rival(RivalCatalog.ID_BORIS))
	_ok("35 can start", dating.can_start_date(alina_id))
	alina_def.date_requirements = original_date
	sm.new_game()
	gs.player.rating = 99
	var actress_rel: int = int(girls.get_relationship(GirlCatalog.ID_ACTRESS))
	var actress_max: int = int(girls.get_relationship_max(GirlCatalog.ID_ACTRESS))
	_ok("36 actress below max", actress_rel < actress_max)
	_ok("36 rating not stage", stages.get_current_stage() == 1)
	girls.change_relationship(GirlCatalog.ID_ACTRESS, actress_max)
	_ok("36 actress max stage 2", stages.get_current_stage() == 2)
	sm.new_game()
	if actress_def != null:
		actress_def.relationship_max = 7
		var made_req: GirlRelationshipRequirement = StageCatalog.make_girl_relationship_requirement(actress_def)
		_ok("37 factory uses live max", made_req != null and made_req.target_relationship == 7)
		var stage1: StageDefinition = catalog.get_stage(1) if catalog != null else null
		var live_stage1_req: GirlRelationshipRequirement = stage1.completion_requirement as GirlRelationshipRequirement if stage1 != null else null
		_ok("37 stage 1 original max", live_stage1_req != null and live_stage1_req.target_relationship == original_actress_max)
		actress_def.relationship_max = original_actress_max
	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = false
	if stage6 != null:
		var finale_req: GirlRelationshipRequirement = GirlRelationshipRequirement.new()
		finale_req.girl_id = alina_id
		finale_req.target_relationship = 0
		stage6.completion_requirement = finale_req
		var completed_events: Array = []
		var finale_events: Array = []
		var on_completed := func(completed_stage: int) -> void:
			completed_events.append(completed_stage)
		var on_finale := func() -> void:
			finale_events.append(true)
		stages.stage_completed.connect(on_completed)
		stages.finale_reached.connect(on_finale)
		_ok("38 try_complete", stages.try_complete_current_stage())
		_ok("38 stage stays 6", stages.get_current_stage() == 6)
		_ok("38 finale reached", stages.is_finale_reached())
		_ok("38 stage_completed 6", completed_events.size() == 1 and int(completed_events[0]) == 6)
		_ok("38 finale signal", finale_events.size() == 1)
		_ok("38 no stage 7", catalog.get_stage(7) == null)
		stages.stage_completed.disconnect(on_completed)
		stages.finale_reached.disconnect(on_finale)
		stage6.completion_requirement = original_stage6_req
	sm.new_game()
	var sim_rating: RatingGirlRequirement = RatingGirlRequirement.new()
	sim_rating.required_rating = 4
	var sim_meet: Array[GirlAccessRequirement] = []
	sim_meet.append(sim_rating)
	alina_def.meet_requirements = sim_meet
	var sim_city := GameSimulator.new()
	tree.root.add_child(sim_city)
	sim_city.start_new_game()
	gs.player.rating = 2
	sim_city.show_section("city")
	sim_city.enter_world_location(LocationCatalog.ID_CITY_CENTER)
	var city_text: String = sim_city.get_city_body_text()
	_ok("39 city alina", city_text.contains("Алина"))
	_ok("39 city rating", city_text.contains("Рейтинг"))
	_ok("39 city progress", city_text.contains("2 / 4"))
	_ok("39 city meet button", city_text.contains("ПОЗНАКОМИТЬСЯ"))
	_ok("39 cannot meet", girls.can_meet_girl(alina_id) == false)
	var blocked_sim_meet: ActionResult = sim_city.meet_girl(alina_id)
	_ok("39 meet blocked", blocked_sim_meet.success == false)
	gs.player.rating = 4
	sim_city.refresh()
	_ok("39 can meet", girls.can_meet_girl(alina_id))
	var allowed_sim_meet: ActionResult = sim_city.meet_girl(alina_id)
	_ok("39 meet success", allowed_sim_meet.success)
	sim_city.queue_free()
	alina_def.meet_requirements = original_meet
	sm.new_game()
	var sim_date_req: RivalDefeatedGirlRequirement = RivalDefeatedGirlRequirement.new()
	sim_date_req.rival_id = RivalCatalog.ID_BORIS
	var sim_dates: Array[GirlAccessRequirement] = []
	sim_dates.append(sim_date_req)
	alina_def.date_requirements = sim_dates
	var sim_date := GameSimulator.new()
	tree.root.add_child(sim_date)
	sim_date.start_new_game()
	sim_date.show_section("city")
	sim_date.enter_world_location(LocationCatalog.ID_CITY_CENTER)
	var cafe_meet: ActionResult = sim_date.meet_girl(alina_id)
	_ok("40 meet alina", cafe_meet.success)
	sim_date.show_section("dates")
	var dates_text: String = sim_date.get_city_body_text()
	_ok("40 has defeat", dates_text.contains("Победить"))
	_ok("40 has boris", dates_text.contains("Борис"))
	_ok("40 invite", dates_text.contains("ПРИГЛАСИТЬ"))
	_ok("40 cannot start", dating.can_start_date(alina_id) == false)
	_ok("40 defeat", rivals.defeat_rival(RivalCatalog.ID_BORIS))
	sim_date.refresh()
	var dates_after: String = sim_date.get_city_body_text()
	_ok("40 met copy", dates_after.contains("Выполнено") or dates_after.contains("✓"))
	_ok("40 can start", dating.can_start_date(alina_id))
	sim_date.queue_free()
	alina_def.meet_requirements = original_meet
	alina_def.date_requirements = original_date
	if actress_def != null:
		actress_def.relationship_max = original_actress_max
	if stage6 != null:
		stage6.completion_requirement = original_stage6_req
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
	var location_a: StringName = &"apartment"
	var location_b: StringName = &"cafe"
	var locked_id: StringName = &"locked_test_venue"
	var definition: GirlDefinition = girls.get_definition(alina_id)
	_ok("venue world location city_center", definition != null and definition.location_id == LocationCatalog.ID_CITY_CENTER)
	girls.give_contact(alina_id)
	var locations: Array = dating.get_available_date_venues(alina_id)
	_ok("venue available list", locations.size() >= 1)
	_ok("venue apartment open stage 1", dating.is_date_venue_available(alina_id, location_a))
	_ok("venue cafe locked stage 1", dating.is_date_venue_available(alina_id, location_b) == false)
	_ok("venue restaurant locked stage 1", dating.is_date_venue_available(alina_id, &"restaurant") == false)
	_ok("venue leisure locked stage 1", dating.is_date_venue_available(alina_id, &"leisure_center") == false)
	_ok("venue locked closed", dating.is_date_venue_available(alina_id, locked_id) == false)
	_ok("venue park closed", dating.is_date_venue_available(alina_id, &"park") == false)
	var apartment_objects: Array[StringName] = dating.resolve_date_local_object_ids(location_a)
	_ok("venue apartment empty before purchases", apartment_objects.is_empty())
	var locked_requirement := DateVenueAvailableRequirement.new()
	locked_requirement.girl_id = alina_id
	locked_requirement.date_venue_id = locked_id
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
	_ok("venue A active location", dating.get_active_venue_id() == location_a)
	_ok("venue A session", _active_session_venue(dating) == location_a)
	var complete_a := DateResult.new()
	complete_a.girl_id = alina_id
	complete_a.relationship_delta = 0
	complete_a.duration_minutes = 120
	_ok("venue A complete", dating.complete_date(complete_a))
	var daily_venue: Variant = _daily_activity()
	if daily_venue != null:
		daily_venue.set_usage_today(daily_venue.date_key(alina_id), 0)
	gs.world.unlock_date_venue(&"cafe")
	_ok("venue B start", dating.start_date(alina_id, location_b))
	_ok("venue B independent", _active_session_venue(dating) == location_b)
	_ok("venue B not world cafe", _active_session_venue(dating) != definition.location_id)
	sm.save_game()
	sm.new_game()
	_ok("venue reset new game", dating.has_active_date() == false)
	_ok("venue load", sm.load_game())
	_ok("venue loaded girl", dating.get_active_girl_id() == alina_id)
	_ok("venue loaded location", dating.get_active_venue_id() == location_b)
	_ok("venue restore", dating.restore_active_date())
	_ok("venue restored session", _active_session_venue(dating) == location_b)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()

func _test_venues_and_local_objects() -> void:
	var catalog: DateContentCatalog = _catalog()
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var apartment: Variant = _apartment_service()
	var actions: Variant = _action_service()
	_ok("venues services", gs != null and sm != null and stages != null and world != null and girls != null and dating != null and apartment != null and actions != null)
	if gs == null or sm == null or stages == null or world == null or girls == null or dating == null or apartment == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/venues_local_objects.json"
	sm.delete_save()
	sm.new_game()
	var alina_id: StringName = GirlCatalog.ID_ALINA
	girls.give_contact(alina_id)
	_ok("1. Stage 1 only apartment", dating.is_date_venue_available(alina_id, &"apartment") and not dating.is_date_venue_available(alina_id, &"cafe") and not dating.is_date_venue_available(alina_id, &"leisure_center") and not dating.is_date_venue_available(alina_id, &"restaurant"))
	var production_ids: Array[StringName] = []
	for venue in dating.get_available_date_venues(alina_id):
		if venue != null:
			production_ids.append(venue.id)
	_ok("1b. canonical 4 venues", production_ids.size() == 4 and production_ids.has(&"apartment") and production_ids.has(&"cafe") and production_ids.has(&"leisure_center") and production_ids.has(&"restaurant"))
	_ok("2. Stage 1 apartment 0 local objects", dating.resolve_date_local_object_ids(&"apartment").is_empty())
	_ok("2b. Stage 1 furniture hidden", _visible_object_ids(apartment).is_empty())
	gs.story.stage = 2
	stages.reconcile_stage_entry_state()
	_ok("3. Stage 2 apartment cafe leisure", dating.is_date_venue_available(alina_id, &"apartment") and dating.is_date_venue_available(alina_id, &"cafe") and dating.is_date_venue_available(alina_id, &"leisure_center") and not dating.is_date_venue_available(alina_id, &"restaurant"))
	gs.story.stage = 3
	stages.reconcile_stage_entry_state()
	_ok("4. Stage 3 all four venues", dating.is_date_venue_available(alina_id, &"apartment") and dating.is_date_venue_available(alina_id, &"cafe") and dating.is_date_venue_available(alina_id, &"leisure_center") and dating.is_date_venue_available(alina_id, &"restaurant"))
	var cafe_objects: Array[DateLocalObject] = _local_objects_with_prefix(catalog, "cafe__")
	var cafe_moves: Array[DateMove] = _local_moves_of_objects(catalog, cafe_objects)
	var cafe_tags: Dictionary = {}
	for move in cafe_moves:
		cafe_tags[String(move.resolved_tag_id())] = true
	_ok("5. cafe 3/6/6", cafe_objects.size() == 3 and cafe_moves.size() == 6 and cafe_tags.size() == 6)
	var leisure_objects: Array[DateLocalObject] = _local_objects_with_prefix(catalog, "leisure_center__")
	var leisure_moves: Array[DateMove] = _local_moves_of_objects(catalog, leisure_objects)
	var leisure_tags: Dictionary = {}
	for move in leisure_moves:
		leisure_tags[String(move.resolved_tag_id())] = true
	_ok("6. leisure 4/8/8", leisure_objects.size() == 4 and leisure_moves.size() == 8 and leisure_tags.size() == 8)
	var restaurant_objects: Array[DateLocalObject] = _local_objects_with_prefix(catalog, "restaurant__")
	var restaurant_moves: Array[DateMove] = _local_moves_of_objects(catalog, restaurant_objects)
	var restaurant_tags: Dictionary = {}
	var restaurant_gated: int = 0
	var restaurant_slots: Dictionary = {}
	for move in restaurant_moves:
		restaurant_tags[String(move.resolved_tag_id())] = true
		if move.unlock_requirement != null:
			restaurant_gated += 1
			restaurant_slots["%s:%d" % [String(move.unlock_requirement.stat_id), move.unlock_requirement.required_level]] = true
	_ok("7. restaurant 4/8/8", restaurant_objects.size() == 4 and restaurant_moves.size() == 8 and restaurant_tags.size() == 8)
	_ok("8. restaurant all gated", restaurant_moves.size() == 8 and restaurant_gated == 8)
	_ok("9. restaurant 1 and 3 per characteristic", restaurant_slots.size() == 8)
	var rest_ids: Array = []
	for local_object in restaurant_objects:
		rest_ids.append(local_object.id)
	var rest_flags: Dictionary = {}
	if not rest_ids.is_empty():
		rest_flags["local_object_ids"] = rest_ids
	var locked_player: DatePlayerSnapshot = _player()
	var sport_player: DatePlayerSnapshot = _player()
	sport_player.muscle = 0
	var locked_engine: DateEngine = _engine_with_flags(catalog, &"alina", &"restaurant", &"casual", 4, _fresh_progress(catalog, &"alina"), locked_player, rest_flags)
	var sport_engine: DateEngine = _engine_with_flags(catalog, &"alina", &"restaurant", &"sport", 4, _fresh_progress(catalog, &"alina"), sport_player, rest_flags)
	var locked_option: DateMoveOption = null
	var view_locked: DateEpisodeView = locked_engine.get_current_episode()
	for option in _source_options(view_locked, DateTypes.DateMoveSource.VENUE):
		if option != null and option.availability == DateTypes.MoveAvailability.LOCKED and option.requirement_stat_id == &"muscle" and option.requirement_level == 1:
			locked_option = option
			break
	if locked_option == null:
		locked_option = _first_locked_local_option(locked_engine)
	var opened_option: DateMoveOption = null
	if locked_option != null:
		opened_option = _episode_option(sport_engine.get_current_episode(), locked_option.move_id)
	_ok("10. outfit effective stat opens restaurant lock", locked_option != null and opened_option != null and opened_option.availability == DateTypes.MoveAvailability.AVAILABLE)
	var apartment_objects: Array[DateLocalObject] = _local_objects_with_prefix(catalog, "apartment__")
	var apartment_moves: Array[DateMove] = _local_moves_of_objects(catalog, apartment_objects)
	var apartment_tags: Dictionary = {}
	for move in apartment_moves:
		apartment_tags[String(move.resolved_tag_id())] = true
	_ok("11. apartment 12 objects 12 tags", apartment_objects.size() == 12 and apartment_moves.size() == 12 and apartment_tags.size() == 12)
	sm.new_game()
	_ok("12a. stage 1 furniture 0", _visible_object_ids(apartment).is_empty())
	gs.story.stage = 2
	_ok("12. stage 2 furniture 4", _visible_object_ids(apartment).size() == 4)
	gs.story.stage = 3
	_ok("13. stage 3 furniture 8", _visible_object_ids(apartment).size() == 8)
	gs.story.stage = 4
	_ok("14. stage 4 furniture 12", _visible_object_ids(apartment).size() == 12)
	sm.new_game()
	gs.story.stage = 2
	gs.player.money = 150
	var buy_plaid: ActionResult = actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	_ok("15. buy plaid", buy_plaid.success and gs.progression.apartment.owned_local_object_ids.has(&"apartment__plaid"))
	_ok("15. apartment source has plaid", dating.resolve_date_local_object_ids(&"apartment").has(&"apartment__plaid"))
	sm.new_game()
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_KATYA)
	_ok("16. pending accent before furniture", bool(apartment.is_first_accent_assignment()) and apartment.get_accent_object_id() == &"")
	_ok("16. first accent price 0", int(apartment.get_accent_reassignment_price()) == 0)
	gs.player.money = 150
	actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	var first_accent: GameAction = apartment.create_assign_accent_action(&"apartment__plaid")
	_ok("16. first assign costs 0", first_accent.money_cost == 0)
	var assign_ok: ActionResult = actions.execute(first_accent)
	_ok("16. first assign", assign_ok.success and apartment.get_accent_object_id() == &"apartment__plaid")
	gs.story.stage = 2
	_ok("19. reassignment stage 2 $300", int(apartment.get_accent_reassignment_price()) == 300)
	gs.story.stage = 3
	_ok("19. reassignment stage 3 $600", int(apartment.get_accent_reassignment_price()) == 600)
	gs.story.stage = 4
	_ok("19. reassignment stage 4 $1000", int(apartment.get_accent_reassignment_price()) == 1000)
	var girl: GirlProfile = catalog.find_girl(&"alina")
	var accent_positive_ok: bool = false
	var accent_negative_ok: bool = false
	var venue_limit_ok: bool = false
	for local_object in cafe_objects:
		for move_id in local_object.move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move == null or girl == null:
				continue
			var preference: int = girl.prefers_tag(move.resolved_tag_id())
			var flags: Dictionary = {"accent_object_id": local_object.id, "local_object_ids": [local_object.id]}
			var accent_engine: DateEngine = _engine_with_flags(catalog, &"alina", &"cafe", &"casual", 17, _fresh_progress(catalog, &"alina"), _player(), flags)
			accent_engine.choose_move(move_id)
			var delta: int = int(accent_engine.get_session_state().current_score_delta)
			if preference > 0:
				accent_positive_ok = delta == 2
			else:
				accent_negative_ok = delta == -1
			if not venue_limit_ok:
				venue_limit_ok = accent_engine.get_session_state().venue_source_used and accent_engine.get_session_state().venue_source_limit == 1
	_ok("17. accent positive +2", accent_positive_ok)
	_ok("18. accent negative -1", accent_negative_ok)
	_ok("20. default venue source 1", venue_limit_ok)
	var public_ok: bool = true
	for situation_id in [&"stranger_flirts", &"small_rule", &"staff_conflict", &"mistaken_married", &"lost_wallet"]:
		var situation: DateSituation = catalog.find_situation(situation_id)
		if situation == null or not situation.allowed_venue_ids.has(&"leisure_center"):
			public_ok = false
			break
	_ok("22. public situations include leisure_center", public_ok)
	var start_apartment: GameAction = dating.create_start_date_action(alina_id, &"apartment")
	_ok("venue apartment price 0", start_apartment.money_cost == 0)
	var cafe_venue: DateVenue = catalog.find_venue(&"cafe")
	if cafe_venue != null:
		var start_cafe: GameAction = dating.create_start_date_action(alina_id, &"cafe")
		_ok("venue cafe price included", start_cafe.money_cost == cafe_venue.price)
	var katya_reward: FillerRewardDefinition = FillerRewardCatalog.create_seed().get_reward_for_girl(GirlCatalog.ID_KATYA)
	_ok("katya reward is interior accent", katya_reward != null and katya_reward.id == FillerRewardCatalog.ID_KATYA_INTERIOR_ACCENT)
	_ok("no emperor chair reward", FillerRewardCatalog.create_seed().get_reward(&"katya_emperor_chair") == null)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_progression_integration() -> void:
	var catalog: DateContentCatalog = _catalog()
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var equipment: Variant = _equipment_service()
	var apartment: Variant = _apartment_service()
	var actions: Variant = _action_service()
	var objectives: Variant = _objective_service()
	_ok("progression integration services", gs != null and sm != null and world != null and girls != null and dating != null and equipment != null and apartment != null and actions != null)
	if gs == null or sm == null or world == null or girls == null or dating == null or equipment == null or apartment == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/progression_integration.json"
	sm.delete_save()
	sm.new_game()
	_ok("marina closed stage 1", girls.can_meet_girl(GirlCatalog.ID_MARINA) == false)
	world.set_city_stage(2)
	gs.story.stage = 2
	world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	world.enter_location(LocationCatalog.ID_CLOTHING_STORE)
	_ok("marina open stage 2", girls.can_meet_girl(GirlCatalog.ID_MARINA))
	girls.give_contact(GirlCatalog.ID_MARINA)
	_ok("marina casual date ok", dating.can_start_date(GirlCatalog.ID_MARINA))
	girls.give_contact(GirlCatalog.ID_LERA)
	_ok("stage 2 filler casual blocked", dating.can_start_date(GirlCatalog.ID_LERA) == false)
	_ok("stage 2 filler fail reason", dating.get_start_date_failure_reason(GirlCatalog.ID_LERA) == "Для этого свидания нужен образ интереснее повседневного.")
	girls.give_contact(GirlCatalog.ID_MINE_BOSS)
	_ok("stage 2 story casual blocked", dating.can_start_date(GirlCatalog.ID_MINE_BOSS) == false)
	gs.player.money = 250
	_ok("buy dressed", actions.execute(equipment.create_buy_outfit_action(&"sport")).success)
	_ok("owns dressed", bool(equipment.owns_dressed_outfit()) and int(equipment.get_current_outfit_tier()) >= 1)
	_ok("stage 2 filler dressed ok", dating.can_start_date(GirlCatalog.ID_LERA))
	_ok("stage 2 story dressed ok", dating.can_start_date(GirlCatalog.ID_MINE_BOSS) or dating.get_start_date_failure_reason(GirlCatalog.ID_MINE_BOSS) != "Для этого свидания нужен образ интереснее повседневного.")
	sm.new_game()
	girls.give_contact(GirlCatalog.ID_ALINA)
	girls.give_contact(GirlCatalog.ID_VIKA)
	girls.give_contact(GirlCatalog.ID_DASHA)
	_ok("stage 1 alina casual ok", dating.can_start_date(GirlCatalog.ID_ALINA))
	_ok("stage 1 vika casual ok", dating.can_start_date(GirlCatalog.ID_VIKA))
	_ok("stage 1 dasha casual ok", dating.can_start_date(GirlCatalog.ID_DASHA))
	var casual: Outfit = catalog.find_outfit(&"casual")
	_ok("casual stage 1 tier 0", casual != null and casual.min_story_stage == 1 and casual.tier == 0 and not casual.has_outfit_move())
	for outfit_id in [&"sport", &"stylish", &"business", &"minimal_black"]:
		var outfit: Outfit = catalog.find_outfit(outfit_id)
		_ok("%s stage 2 tier 1 no move" % String(outfit_id), outfit != null and outfit.min_story_stage == 2 and outfit.tier == 1 and not outfit.has_outfit_move())
	for outfit_id in [&"wrestling", &"magician", &"luxury", &"leather_jacket"]:
		var thematic: Outfit = catalog.find_outfit(outfit_id)
		_ok("%s stage 3 tier 1 move" % String(outfit_id), thematic != null and thematic.min_story_stage == 3 and thematic.tier == 1 and thematic.has_outfit_move())
	for outfit_id in [&"stunt", &"model", &"philanthropist", &"black_turtleneck"]:
		var late: Outfit = catalog.find_outfit(outfit_id)
		_ok("%s stage 4 tier 1 move" % String(outfit_id), late != null and late.min_story_stage == 4 and late.tier == 1 and late.has_outfit_move())
	var restaurant_objects: Array[DateLocalObject] = _local_objects_with_prefix(catalog, "restaurant__")
	var rest_ids: Array = []
	for local_object in restaurant_objects:
		rest_ids.append(local_object.id)
	var rest_flags: Dictionary = {}
	if not rest_ids.is_empty():
		rest_flags["local_object_ids"] = rest_ids
	var locked_player: DatePlayerSnapshot = _player()
	var wrestling_player: DatePlayerSnapshot = _player()
	wrestling_player.muscle = 0
	var locked_engine: DateEngine = _engine_with_flags(catalog, &"alina", &"restaurant", &"casual", 4, _fresh_progress(catalog, &"alina"), locked_player, rest_flags)
	var wrestling_engine: DateEngine = _engine_with_flags(catalog, &"alina", &"restaurant", &"wrestling", 4, _fresh_progress(catalog, &"alina"), wrestling_player, rest_flags)
	var locked_option: DateMoveOption = null
	for option in _source_options(locked_engine.get_current_episode(), DateTypes.DateMoveSource.VENUE):
		if option != null and option.availability == DateTypes.MoveAvailability.LOCKED and option.requirement_stat_id == &"muscle" and option.requirement_level == 1:
			locked_option = option
			break
	var opened_option: DateMoveOption = _episode_option(wrestling_engine.get_current_episode(), locked_option.move_id) if locked_option != null else null
	_ok("stage 3 outfit unlocks restaurant move", locked_option != null and opened_option != null and opened_option.availability == DateTypes.MoveAvailability.AVAILABLE)
	var apartment_catalog: ApartmentCatalog = apartment.get_catalog()
	var items: Array[ApartmentObjectDefinition] = apartment_catalog.all_objects()
	var object_ids: Dictionary = {}
	var move_ids: Dictionary = {}
	var tags: Dictionary = {}
	for item in items:
		if item == null:
			continue
		object_ids[String(item.id)] = true
		var local_object: DateLocalObject = catalog.find_local_object(item.local_object_id())
		if local_object == null:
			continue
		for move_id in local_object.move_ids:
			move_ids[String(move_id)] = true
			var move: DateMove = catalog.find_move(move_id)
			if move != null:
				tags[String(move.fixed_tag_id)] = true
	_ok("19.1 no apartment level", not apartment.has_method("get_level") and not gs.progression.apartment.to_dict().has("level"))
	_ok("19.2 apartment 12 objects", items.size() == 12 and object_ids.size() == 12)
	_ok("19.3 apartment 12 unique moves", move_ids.size() == 12)
	_ok("19.4 apartment 12 unique tags", tags.size() == 12)
	sm.new_game()
	_ok("19.2 new owned empty", gs.progression.apartment.owned_local_object_ids.is_empty())
	var stage2_items: Array[ApartmentObjectDefinition] = apartment_catalog.available_objects(2)
	_ok("19.5 stage 1 furniture 0", apartment_catalog.available_objects(1).is_empty() and _visible_object_ids(apartment).is_empty())
	_ok("19.5 stage 2 furniture 4", stage2_items.size() == 4)
	_ok("19.5 sort stage then authored", stage2_items.size() == 4 and stage2_items[0].id == &"apartment__plaid" and stage2_items[1].id == &"apartment__tv" and stage2_items[2].id == &"apartment__record_player" and stage2_items[3].id == &"apartment__no_filter_cards")
	_ok("19.5 stage 3 furniture 8", apartment_catalog.available_objects(3).size() == 8)
	_ok("19.5 stage 4 furniture 12", apartment_catalog.available_objects(4).size() == 12)
	_ok("19.5 service available_objects", apartment.get_available_objects().is_empty())
	gs.story.stage = 2
	gs.player.money = 150
	var buy_plaid: ActionResult = actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	_ok("19.6 buy owned id", buy_plaid.success and gs.progression.apartment.owned_local_object_ids.has(&"apartment__plaid"))
	_ok("19.6 buy local source", dating.resolve_date_local_object_ids(&"apartment").has(&"apartment__plaid"))
	_ok("19.7 is_object_owned", bool(apartment.is_object_owned(&"apartment__plaid")))
	_ok("19.8 owned alias", apartment.get_owned_object_ids().has(&"apartment__plaid") and apartment.get_owned_local_object_ids().has(&"apartment__plaid"))
	_ok("19.9 active local moves", apartment.get_active_local_move_ids().has(&"apartment__plaid__get_comfortable"))
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_KATYA)
	_ok("19.10 accent rejects unowned tv", apartment.assign_accent(&"apartment__tv") == false)
	_ok("19.10 accent accepts owned plaid", bool(apartment.assign_accent(&"apartment__plaid")))
	sm.new_game()
	gs.story.stage = 2
	if objectives != null:
		var view: ObjectiveView = _rebuild_objective()
		_ok("20. current dress up title", view != null and view.title == "Приоденься")
		_ok("20. current dress up description", view != null and view.description.contains("Купи любой образ выше «Повседневного» в магазине одежды."))
		_ok("20. current dress up hint", view != null and (view.description.contains("Марина работает в магазине одежды") or view.next_step_text.contains("Марина работает в магазине одежды")))
		_ok("20. current dress up location", view != null and view.target_location_id == LocationCatalog.ID_CLOTHING_STORE)
		_ok("20. no mine boss subgoals yet", _subgoal_by_id(view, &"meet_girl") == null)
		gs.player.money = 250
		actions.execute(equipment.create_buy_outfit_action(&"sport"))
		view = _rebuild_objective()
		_ok("20. buy advances current objective", view != null and view.title == "Начальница шахты")
		world.set_city_stage(2)
		equipment.equip_outfit(OutfitCatalog.START_OUTFIT_ID)
		girls.give_contact(GirlCatalog.ID_LERA)
		_ok("20. owned dressed casual still gated", dating.can_start_date(GirlCatalog.ID_LERA) == false)
		equipment.equip_outfit(&"sport")
		_ok("20. equipped dressed opens gate", dating.can_start_date(GirlCatalog.ID_LERA))
	sm.new_game()
	gs.story.stage = 2
	world.set_city_stage(2)
	world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	if objectives != null:
		var gift_view: ObjectiveView = _rebuild_objective()
		_ok("20. gift path starts dress up", gift_view != null and gift_view.title == "Приоденься")
		girls.grant_filler_reward_for_girl(GirlCatalog.ID_MARINA)
		var gift: GameAction = equipment.create_buy_outfit_action(OutfitCatalog.ID_BUSINESS)
		_ok("20. marina gift price 0", gift.money_cost == 0)
		gs.player.money = 0
		_ok("20. marina gift buy", actions.execute(gift).success and bool(equipment.owns_dressed_outfit()))
		gift_view = _rebuild_objective()
		_ok("20. gift advances current objective", gift_view != null and gift_view.title == "Начальница шахты")
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
	var competition_id: StringName = CompetitionCatalog.ID_CASTING
	var boris_def: RivalDefinition = rivals.get_definition(boris_id)
	var competition_def: CompetitionDefinition = competitions.get_catalog().get_competition(competition_id)
	_ok("boris definition", boris_def != null and String(boris_def.display_name).contains("Борис"))
	_ok("boris stuntman name", boris_def != null and boris_def.display_name == "Борис — каскадёр")
	_ok("boris location city", boris_def != null and boris_def.location_id == LocationCatalog.ID_CITY_CENTER)
	_ok("casting competition", competition_def != null and competition_def.rival_id == boris_id)
	_ok("casting appearance", competition_def != null and competition_def.primary_characteristic_id == CharacteristicIds.APPEARANCE)
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
	var girls: Variant = _girls_service()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var at_city: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
	_ok("city no boris before actress", _rival_list_has(at_city, boris_id) == false)
	if girls != null:
		girls.discover_girl(GirlCatalog.ID_ACTRESS)
	var at_city_after: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
	_ok("city has boris after actress", _rival_list_has(at_city_after, boris_id))
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
	gs.player.money = 100
	competitions.set_forced_won(true)
	var win_action: GameAction = competitions.create_competition_action(competition_id)
	_ok("competition action id", win_action.id == StringName("competition_competition_casting"))
	_ok("competition time cost", win_action.time_cost_minutes == 60)
	_ok("competition entry fee", win_action.money_cost == 100)
	var win_result: ActionResult = actions.execute(win_action)
	_ok("win success", win_result.success)
	_ok("win defeated", rivals.is_defeated(boris_id))
	_ok("win payout money 200", gs.player.money == 200)
	_ok("win time 60", int(clock.get_game_time_minutes()) == 60)
	competitions.set_forced_won(null)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	gs.flow.game_time_minutes = 0
	gs.player.money = 100
	competitions.set_forced_won(false)
	var loss_result: ActionResult = actions.execute(competitions.create_competition_action(competition_id))
	_ok("loss success", loss_result.success)
	_ok("loss not defeated", rivals.is_defeated(boris_id) == false)
	_ok("loss still discovered", rivals.is_discovered(boris_id))
	_ok("loss money 0", gs.player.money == 0)
	_ok("loss time 60", int(clock.get_game_time_minutes()) == 60)
	_ok("story after loss blocked same day", rivals.can_challenge_now(boris_id) == false)
	clock.advance_time(1440)
	_ok("story after loss next day", rivals.can_challenge_now(boris_id))
	_ok("story rival after loss", rivals.is_story_rival(boris_id))
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
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(true)
	actions.execute(competitions.create_competition_action(competition_id))
	competitions.set_forced_won(null)
	_ok("story after win defeated", rivals.is_defeated(boris_id))
	_ok("story after win cannot challenge", rivals.can_challenge_now(boris_id) == false)
	_ok("after win competition blocked", competitions.can_start_competition(competition_id) == false)
	_ok("after win reason defeated", String(competitions.get_failure_reason(competition_id)) == "Соперник уже побеждён")
	var defeated_req := RivalDefeatedGirlRequirement.new()
	defeated_req.rival_id = boris_id
	_ok("defeated satisfies girl requirement", defeated_req.is_met(GirlCatalog.ID_ACTRESS))
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(RivalCatalog.ID_GLEB))
	_ok("gleb is filler", rivals.is_repeatable_rival(RivalCatalog.ID_GLEB))
	_ok("gleb not story", rivals.is_story_rival(RivalCatalog.ID_GLEB) == false)
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(true)
	var filler_win: ActionResult = actions.execute(competitions.create_competition_action(CompetitionCatalog.ID_HORIZONTAL_BAR))
	_ok("filler win success", filler_win.success)
	_ok("filler win cooldown", rivals.can_challenge_now(RivalCatalog.ID_GLEB) == false)
	clock.advance_time(1440)
	gs.player.money = 100
	_ok("filler after cooldown", rivals.can_challenge_now(RivalCatalog.ID_GLEB))
	competitions.set_forced_won(null)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(RivalCatalog.ID_GLEB))
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(false)
	var filler_loss: ActionResult = actions.execute(competitions.create_competition_action(CompetitionCatalog.ID_HORIZONTAL_BAR))
	_ok("filler loss success", filler_loss.success)
	_ok("filler loss cooldown", rivals.can_challenge_now(RivalCatalog.ID_GLEB) == false)
	clock.advance_time(1440)
	_ok("filler loss after cooldown", rivals.can_challenge_now(RivalCatalog.ID_GLEB))
	competitions.set_forced_won(null)
	world.set_city_stage(2)
	_ok("city 2 stage", CityProgressionService.get_city_stage() == 2)
	world.set_city_stage(3)
	_ok("city 3 stage", CityProgressionService.get_city_stage() == 3)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(boris_id))
	gs.player.money = 100
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
	var city_before: String = sim.get_city_body_text()
	_ok("sim city no boris before actress", city_before.contains("Борис") == false)
	var girls_for_sim: Variant = _girls_service()
	if girls_for_sim != null:
		girls_for_sim.discover_girl(GirlCatalog.ID_ACTRESS)
	sim.refresh()
	var city_text: String = sim.get_city_body_text()
	_ok("sim city boris", city_text.contains("Борис"))
	_ok("sim city meet button", city_text.contains("ВСТРЕТИТЬ"))
	var sim_meet: ActionResult = sim.meet_rival(boris_id)
	_ok("sim meet rival success", sim_meet.success)
	_ok("sim meet rival result", sim.get_result_text().contains("Борис"))
	sim.show_section("rivals")
	var rivals_text: String = sim.get_city_body_text()
	_ok("sim rivals boris", rivals_text.contains("БОРИС"))
	_ok("sim rivals not defeated", rivals_text.contains("Статус: Не побеждён"))
	_ok("sim rivals competitions", rivals_text.contains("СОРЕВНОВАНИЯ"))
	_ok("sim rivals challenge", rivals_text.contains("Вызвать — взнос 100"))
	gs.player.money = 100
	competitions.set_forced_won(true)
	var sim_win: ActionResult = sim.start_competition(competition_id)
	competitions.set_forced_won(null)
	_ok("sim win success", sim_win.success)
	_ok("sim win result", sim.get_result_text().contains("Победа."))
	_ok("sim win defeated text", sim.get_result_text().contains("Борис") and sim.get_result_text().contains("побеждён"))
	_ok("sim win time text", sim.get_result_text().contains("Прошло времени: 60 минут."))
	var after_win: String = sim.get_city_body_text()
	_ok("sim rivals defeated", after_win.contains("Статус: Побеждён"))
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
	var clock: Variant = _time_service()
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
	if gs == null or sm == null or actions == null or economy == null or characteristics == null or equipment == null or apartment == null or dating == null or girls == null or competitions == null or clock == null:
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
	gs.player.money = FillerRewardCatalog.ALINA_GYM_BASE_PRICE
	var muscle_time_before: int = int(gs.flow.game_time_minutes)
	var buy_muscle: ActionResult = actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("upgrade muscle success", buy_muscle.success)
	_ok("upgrade muscle money 0", gs.player.money == 0)
	_ok("upgrade muscle value 1", gs.player.muscle == 1)
	_ok("upgrade muscle 60 min", int(gs.flow.game_time_minutes) == muscle_time_before + FillerRewardCatalog.ALINA_GYM_MINUTES)
	_ok("upgrade muscle max 5", int(characteristics.get_max_level(CharacteristicIds.MUSCLE)) == 5)
	gs.player.money = FillerRewardCatalog.ALINA_GYM_BASE_PRICE * 4
	for _level in range(4):
		clock.advance_time(1440)
		actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("upgrade muscle sequential 5", gs.player.muscle == 5)
	_ok("upgrade muscle spent to 5", gs.player.money == 0)
	var buy_muscle_again: ActionResult = actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("upgrade muscle at max fail", buy_muscle_again.success == false)
	_ok("start outfit owned", bool(equipment.owns_outfit(OutfitCatalog.START_OUTFIT_ID)))
	_ok("new player casual", equipment.get_current_outfit_id() == OutfitCatalog.START_OUTFIT_ID)
	gs.story.stage = 2
	gs.player.money = 250
	var buy_business: ActionResult = actions.execute(equipment.create_buy_outfit_action(OutfitCatalog.ID_BUSINESS))
	_ok("buy 250 business", buy_business.success)
	_ok("current business", equipment.get_current_outfit_id() == OutfitCatalog.ID_BUSINESS)
	_ok("owns business", bool(equipment.owns_outfit(&"business")))
	_ok("money 0 after business", gs.player.money == 0)
	gs.player.money = 700
	var luxury_too_early: ActionResult = actions.execute(equipment.create_buy_outfit_action(OutfitCatalog.ID_LUXURY))
	_ok("luxury gated by stage", luxury_too_early.success == false)
	girls.give_contact(GirlCatalog.ID_ALINA)
	_ok("date start uses current outfit", dating.start_date(GirlCatalog.ID_ALINA, &"apartment"))
	_ok("dating current business", dating.get_active_outfit_id() == OutfitCatalog.ID_BUSINESS)
	_ok("session outfit business", _active_session_outfit(dating) == OutfitCatalog.ID_BUSINESS)
	var date_result := DateResult.new()
	date_result.girl_id = GirlCatalog.ID_ALINA
	date_result.relationship_delta = 0
	date_result.duration_minutes = 120
	dating.complete_date(date_result)
	sm.new_game()
	gs.story.stage = 2
	gs.player.money = 150
	_ok("apartment start empty", apartment.get_owned_object_ids().is_empty())
	var buy_apt: ActionResult = actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	_ok("apartment buy success", buy_apt.success)
	_ok("apartment money 0", gs.player.money == 0)
	_ok("apartment object stored", bool(apartment.is_object_owned(&"apartment__plaid")))
	_ok("apartment grants plaid", apartment.get_owned_local_object_ids().has(&"apartment__plaid"))
	girls.give_contact(GirlCatalog.ID_ALINA)
	_ok("apartment date start", dating.start_date(GirlCatalog.ID_ALINA, &"apartment"))
	var engine: DateEngine = dating.get_date_engine()
	_ok("apartment engine", engine != null)
	if engine != null:
		var player_snapshot: DatePlayerSnapshot = engine.player_snapshot()
		_ok("apartment prepared in engine", player_snapshot != null and player_snapshot.apartment_prepared)
		_ok("apartment session has plaid", engine.get_session_state().local_object_ids.has(&"apartment__plaid"))
	dating.complete_date(date_result)
	sm.new_game()
	var competition_id: StringName = CompetitionCatalog.ID_CASTING
	_ok("chance appearance 0", is_equal_approx(float(competitions.get_win_chance(competition_id)), 0.5))
	gs.player.appearance = 2
	_ok("chance appearance 2", is_equal_approx(float(competitions.get_win_chance(competition_id)), 0.7))
	gs.player.appearance = 5
	var catalog: CompetitionCatalog = competitions.get_catalog()
	var definition: CompetitionDefinition = catalog.get_competition(competition_id)
	var previous_chance: float = definition.base_win_chance
	definition.base_win_chance = 0.8
	_ok("chance clamp 1", is_equal_approx(float(competitions.get_win_chance(competition_id)), 1.0))
	definition.base_win_chance = previous_chance
	sm.new_game()
	gs.story.stage = 2
	gs.player.money = 1000
	gs.player.muscle = 1
	gs.player.appearance = 2
	gs.player.capital = 1
	gs.player.aura = 3
	actions.execute(equipment.create_buy_outfit_action(OutfitCatalog.ID_BUSINESS))
	actions.execute(apartment.create_buy_apartment_object_action(&"apartment__plaid"))
	gs.player.money = 1000
	sm.save_game()
	sm.new_game()
	_ok("progress reset muscle", gs.player.muscle == 0)
	_ok("progress reset outfit", equipment.get_current_outfit_id() == OutfitCatalog.START_OUTFIT_ID)
	_ok("progress reset apartment", apartment.get_owned_object_ids().is_empty())
	_ok("progress load", sm.load_game())
	_ok("loaded money 1000", gs.player.money == 1000)
	_ok("loaded muscle 1", gs.player.muscle == 1)
	_ok("loaded appearance 2", gs.player.appearance == 2)
	_ok("loaded capital 1", gs.player.capital == 1)
	_ok("loaded aura 3", gs.player.aura == 3)
	_ok("loaded owns business", bool(equipment.owns_outfit(&"business")))
	_ok("loaded current business", equipment.get_current_outfit_id() == &"business")
	_ok("loaded apartment plaid", bool(apartment.is_object_owned(&"apartment__plaid")))
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
	_ok("migrated current start", equipment.get_current_outfit_id() == OutfitCatalog.START_OUTFIT_ID)
	_ok("migrated apartment empty", apartment.get_owned_object_ids().is_empty())
	sm.delete_save()
	var v14_prog: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("wrote v14 outfit save", v14_prog != null)
	if v14_prog != null:
		var v14_outfit: Dictionary = {
			"save_version": 14,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 1, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {
					"purchased_ids": [],
					"owned_outfit_ids": ["casual", "business", "luxury"],
					"equipped_outfit_id": "business",
				},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {"girls_by_id": {}},
				"dating": {"active_date": {}},
				"rivals": {"rivals_by_id": {}},
			},
		}
		v14_prog.store_string(JSON.stringify(v14_outfit, "\t"))
		v14_prog.close()
	_ok("load v14 outfit save", sm.load_game())
	_ok("v14 outfit keeps equipped business", equipment.get_current_outfit_id() == OutfitCatalog.ID_BUSINESS)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var sim := GameSimulator.new()
		tree.root.add_child(sim)
		sim.start_new_game()
		_ok("sim hud muscle", sim.get_hud_text().contains("Мышца: 0/5"))
		sim.show_section("progression")
		var progression_text: String = sim.get_city_body_text()
		_ok("sim progression heading", progression_text.contains("ХАРАКТЕРИСТИКИ"))
		_ok("sim progression upgrade", progression_text.contains("Тренажёр 1"))
		sim.show_section("clothing")
		var clothing_text: String = sim.get_city_body_text()
		_ok("sim clothing casual", clothing_text.contains("Повседневная"))
		_ok("sim clothing worn", clothing_text.contains("Сейчас:"))
		_ok("sim clothing buy", clothing_text.contains("Купить"))
		sim.show_section("apartment")
		var apartment_text: String = sim.get_city_body_text()
		_ok("sim apartment objects", apartment_text.contains("Предметы") or apartment_text.contains("Нет купленных объектов") or apartment_text.contains("0 / 12") or apartment_text.contains("0/12"))
		_ok("sim apartment store link", apartment_text.contains("МАГАЗИН МЕБЕЛИ") or apartment_text.contains("Нет купленных объектов"))
		sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _revealed_tag_count(girls: Variant, girl_id: StringName) -> int:
	var state: GirlState = girls.get_state(girl_id)
	if state == null:
		return 0
	return state.revealed_positive_tag_ids.size() + state.revealed_negative_tag_ids.size()


func _engine_with_flags(catalog: DateContentCatalog, girl_id: StringName, venue_id: StringName, outfit_id: StringName, seed: int, progress: GirlProgress, player: DatePlayerSnapshot, flags: Dictionary = {}) -> DateEngine:
	var engine := DateEngine.new()
	var config := DateSessionConfig.new()
	config.catalog = catalog
	config.girl_id = girl_id
	config.venue_id = venue_id
	config.outfit_id = outfit_id
	config.seed = seed
	config.girl_progress = progress
	config.player_snapshot = player
	config.relationship_max = GirlCatalog.seed_relationship_max(girl_id)
	config.venue_source_limit = int(flags.get("venue_source_limit", 1))
	config.vika_reroll_available = bool(flags.get("vika_reroll_available", false))
	config.dasha_soften_available = bool(flags.get("dasha_soften_available", false))
	config.nika_swap_available = bool(flags.get("nika_swap_available", false))
	config.backup_outfit_id = StringName(str(flags.get("backup_outfit_id", "")))
	config.express_styling_bonus = int(flags.get("express_styling_bonus", 0))
	config.accent_object_id = StringName(str(flags.get("accent_object_id", "")))
	var venue: DateVenue = catalog.find_venue(venue_id)
	if venue != null:
		config.local_object_ids = venue.local_object_ids.duplicate()
	if flags.has("local_object_ids"):
		var override_ids: Array[StringName] = []
		for item in flags["local_object_ids"]:
			var object_id: StringName = StringName(str(item))
			if object_id != &"" and not override_ids.has(object_id):
				override_ids.append(object_id)
		config.local_object_ids = override_ids
	engine.create_date_session(config)
	return engine


func _test_filler_girl_rewards() -> void:
	var catalog: DateContentCatalog = _catalog()
	var rewards: FillerRewardCatalog = FillerRewardCatalog.create_seed()
	_ok("filler catalog 12 rewards", rewards.get_all_rewards().size() == 12)
	var dasha_found: bool = false
	for seed in range(1, 400):
		var engine: DateEngine = _engine_with_flags(catalog, &"alina", &"cafe", &"casual", seed, _fresh_progress(catalog, &"alina"), _player(), {"dasha_soften_available": true})
		if not _has_preference(engine, false):
			continue
		_choose(engine, _pick_preference(engine, false))
		var first: DateEpisodeResult = engine.get_session_state().episode_history[0]
		if first.score_delta != 0 or not first.soften_applied:
			continue
		engine.advance()
		if not _has_preference(engine, false):
			continue
		_choose(engine, _pick_preference(engine, false))
		var second: DateEpisodeResult = engine.get_session_state().episode_history[1]
		if second.score_delta != -1:
			continue
		dasha_found = true
		break
	_ok("dasha first negative 0 then -1", dasha_found)
	var sonya_player: DatePlayerSnapshot = _player()
	sonya_player.muscle = 3
	sonya_player.appearance = 3
	sonya_player.capital = 3
	sonya_player.aura = 3
	var sonya_rest: DateEngine = _engine_with_flags(catalog, &"alina", &"restaurant", &"casual", 8, _fresh_progress(catalog, &"alina"), sonya_player, {"venue_source_limit": 2})
	var sonya_ids: Array[StringName] = _selectable_local_move_ids(sonya_rest)
	_ok("sonya restaurant has two local moves", sonya_ids.size() >= 2)
	if sonya_ids.size() >= 2:
		sonya_rest.choose_move(sonya_ids[0])
		var rest_session: DateSession = sonya_rest.get_session_state()
		_ok("sonya restaurant first venue still available", rest_session.venue_source_uses == 1 and not rest_session.venue_source_used)
		sonya_rest.advance()
		var second_ids: Array[StringName] = _selectable_local_move_ids(sonya_rest)
		var second_id: StringName = &""
		if second_ids.has(sonya_ids[1]):
			second_id = sonya_ids[1]
		elif not second_ids.is_empty():
			second_id = second_ids[0]
		if second_id != &"":
			sonya_rest.choose_move(second_id)
		rest_session = sonya_rest.get_session_state()
		_ok("sonya restaurant second venue spent", rest_session.venue_source_uses == 2 and rest_session.venue_source_used)
	var cafe_limit: DateEngine = _engine_with_flags(catalog, &"alina", &"cafe", &"casual", 8, _fresh_progress(catalog, &"alina"), _player(), {})
	var cafe_local_id: StringName = _first_selectable_local_move_id(cafe_limit)
	if cafe_local_id != &"":
		cafe_limit.choose_move(cafe_local_id)
	_ok("sonya cafe still one venue use", cafe_limit.get_session_state().venue_source_used)
	var nika_player: DatePlayerSnapshot = _player()
	nika_player.muscle = 5
	nika_player.appearance = 2
	var nika: DateEngine = _engine_with_flags(catalog, &"alina", &"cafe", &"wrestling", 6, _fresh_progress(catalog, &"alina"), nika_player, {"nika_swap_available": true, "backup_outfit_id": &"stylish"})
	nika.choose_move(&"outfit_flex_bicep")
	_ok("nika outfit source used before swap", nika.get_session_state().outfit_source_used)
	nika.set_pending_outfit_swap(true)
	nika.advance()
	var nika_session: DateSession = nika.get_session_state()
	_ok("nika swapped outfit", nika_session.outfit_id == &"stylish")
	_ok("nika outfit source kept", nika_session.outfit_source_used)
	_ok("nika appearance after swap", DateTypes.effective_stat(nika_player.appearance, catalog.find_outfit(nika_session.outfit_id), &"appearance") == 3)
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	var rating: Variant = _rating_service()
	_ok("filler services", gs != null and sm != null and clock != null and girls != null and dating != null and actions != null and rating != null)
	if gs == null or sm == null or clock == null or girls == null or dating == null or actions == null or rating == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/filler_girl_rewards.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	girls.give_contact(GirlCatalog.ID_ALINA)
	girls.give_contact(GirlCatalog.ID_ACTRESS)
	_ok("first meet filler 2 tags", _revealed_tag_count(girls, GirlCatalog.ID_ALINA) == 2)
	_ok("first meet story 0 tags", _revealed_tag_count(girls, GirlCatalog.ID_ACTRESS) == 0)
	var alina_before_eva: int = _revealed_tag_count(girls, GirlCatalog.ID_ALINA)
	girls.give_contact(GirlCatalog.ID_EVA)
	girls.change_relationship(GirlCatalog.ID_EVA, girls.get_relationship_max(GirlCatalog.ID_EVA))
	_ok("eva retro +1 unfinished girl", _revealed_tag_count(girls, GirlCatalog.ID_ALINA) == alina_before_eva + 1)
	_ok("eva retro +1 unfinished story", _revealed_tag_count(girls, GirlCatalog.ID_ACTRESS) == 1)
	girls.give_contact(GirlCatalog.ID_MARINA)
	girls.give_contact(GirlCatalog.ID_MINE_BOSS)
	_ok("after eva filler first meet 3", _revealed_tag_count(girls, GirlCatalog.ID_MARINA) == 3)
	_ok("after eva story first meet 1", _revealed_tag_count(girls, GirlCatalog.ID_MINE_BOSS) == 1)
	sm.new_game()
	girls.give_contact(GirlCatalog.ID_ALINA)
	var alina_max: int = int(girls.get_relationship_max(GirlCatalog.ID_ALINA))
	girls.change_relationship(GirlCatalog.ID_ALINA, alina_max)
	_ok("max grants rating once", int(rating.get_rating()) == 1)
	_ok("max grants alina reward", bool(girls.has_filler_reward(FillerRewardCatalog.ID_ALINA_IMPROVED_GYM)))
	girls.change_relationship(GirlCatalog.ID_ALINA, alina_max)
	_ok("repeat max no extra rating", int(rating.get_rating()) == 1)
	girls.give_contact(GirlCatalog.ID_MARINA)
	girls.change_relationship(GirlCatalog.ID_MARINA, int(girls.get_relationship_max(GirlCatalog.ID_MARINA)))
	_ok("second filler max rating 2", int(rating.get_rating()) == 2)
	_ok("marina reward once", bool(girls.has_filler_reward(FillerRewardCatalog.ID_MARINA_FREE_OUTFIT)))
	sm.new_game()
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_VIKA)
	girls.give_contact(GirlCatalog.ID_VIKA)
	gs.player.money = FillerRewardCatalog.VIKA_REROLL_COST
	var vika_ok: bool = false
	if dating.start_date(GirlCatalog.ID_VIKA, &"apartment"):
		var vika_engine: DateEngine = dating.get_date_engine()
		if vika_engine != null:
			var situation_id: StringName = vika_engine.get_session_state().selected_situation_ids[0]
			var bases: Array[StringName] = vika_engine.get_session_state().current_selected_base_move_ids.duplicate()
			var reroll_error: String = dating.try_vika_reroll()
			var after_bases: Array[StringName] = vika_engine.get_session_state().current_selected_base_move_ids.duplicate()
			vika_ok = reroll_error.is_empty() and gs.player.money == 0 and vika_engine.get_session_state().selected_situation_ids[0] == situation_id and after_bases != bases and not dating.try_vika_reroll().is_empty()
	_ok("vika reroll 25 once keeps situation", vika_ok)
	sm.new_game()
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_OLYA)
	var overtime_time: int = int(gs.flow.game_time_minutes)
	var combined: ActionResult = actions.execute(WorkService.create_work_with_overtime_action())
	_ok("olya checkbox 150/120", combined.success and gs.player.money == 150 and int(gs.flow.game_time_minutes) == overtime_time + 120)
	sm.new_game()
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_OLYA)
	var split_time: int = int(gs.flow.game_time_minutes)
	var first_shift: ActionResult = actions.execute(WorkService.create_work_action(WorkService.make_work_basic()))
	var second_shift: ActionResult = actions.execute(WorkService.create_overtime_action())
	_ok("olya two shifts 150/120", first_shift.success and second_shift.success and gs.player.money == 150 and int(gs.flow.game_time_minutes) == split_time + 120)
	sm.new_game()
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_RITA)
	girls.give_contact(GirlCatalog.ID_RITA)
	clock.advance_time(60)
	var daily_rita: Variant = _daily_activity()
	if daily_rita != null:
		daily_rita.register_usage(daily_rita.date_key(GirlCatalog.ID_RITA), 1)
	_ok("rita cooldown blocks", dating.can_start_date(GirlCatalog.ID_RITA) == false)
	gs.player.money = FillerRewardCatalog.RITA_TAXI_COST
	var taxi: ActionResult = actions.execute(dating.create_start_date_action(GirlCatalog.ID_RITA, &"apartment", OutfitCatalog.START_OUTFIT_ID, {"urgent_taxi": true}))
	_ok("rita taxi starts for 75", taxi.success and gs.player.money == 0 and dating.has_active_date())
	var taxi_result := DateResult.new()
	taxi_result.girl_id = GirlCatalog.ID_RITA
	taxi_result.relationship_delta = 0
	taxi_result.duration_minutes = 120
	dating.complete_date(taxi_result)
	_ok("rita cooldown returns", dating.can_start_date(GirlCatalog.ID_RITA) == false)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_city_density_progression() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var rivals: Variant = _rivals_service()
	var competitions: Variant = _competition_service()
	var actions: Variant = _action_service()
	var characteristics: Variant = _characteristic_service()
	_ok("density services", gs != null and sm != null and clock != null and stages != null and world != null and girls != null and dating != null and rivals != null and competitions != null and actions != null and characteristics != null)
	if gs == null or sm == null or clock == null or stages == null or world == null or girls == null or dating == null or rivals == null or competitions == null or actions == null or characteristics == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/city_density_progression.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	gs.player.money = 300
	_ok("1. buy muscle 1", actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1)).success and gs.player.muscle == 1 and gs.player.money == 0)
	gs.player.money = 1200
	var daily_train_density: Variant = _daily_activity()
	while gs.player.muscle < 5:
		if daily_train_density != null:
			daily_train_density.set_usage_today(daily_train_density.KEY_CHARACTERISTIC_TRAINING, 0)
		actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1))
	_ok("2. sequential to 5", gs.player.muscle == 5)
	_ok("3. max level 5", int(characteristics.get_max_level(CharacteristicIds.MUSCLE)) == 5)
	_ok("4. spent 1500", gs.player.money == 0)
	sm.save_game()
	sm.new_game()
	_ok("5. reset then load", sm.load_game() and gs.player.muscle == 5)
	sm.new_game()
	_ok("6. new game city 1", int(world.get_city_stage()) == 1)
	_ok("10. date free city 1", dating.is_free_date_available_today(GirlCatalog.ID_ALINA))
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("14. alina open", girls.can_meet_girl(GirlCatalog.ID_ALINA))
	_ok("14. marina closed city 1", girls.can_meet_girl(GirlCatalog.ID_MARINA) == false)
	_ok("16. katya closed city 1", girls.can_meet_girl(GirlCatalog.ID_KATYA) == false)
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("14. vika open", girls.can_meet_girl(GirlCatalog.ID_VIKA))
	_ok("14. dasha open", girls.can_meet_girl(GirlCatalog.ID_DASHA))
	gs.player.rating = 1
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("15. actress blocked rating 1", girls.can_meet_girl(GirlCatalog.ID_ACTRESS) == false)
	gs.player.rating = 2
	_ok("15. actress open rating 2", girls.can_meet_girl(GirlCatalog.ID_ACTRESS))
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("39. gleb at start", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_GLEB))
	_ok("40. lev hidden city 1", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_LEV) == false)
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("39. max at start", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_MAX))
	_ok("40. denis hidden city 1", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_DENIS) == false)
	_ok("42. gleb no linked girl", rivals.get_definition(RivalCatalog.ID_GLEB).linked_girl_id == &"")
	_ok("23. work 100", WorkService.get_current_hourly_pay() == 100)
	_ok("25. work minutes 60", WorkService.make_current_work().time_cost_minutes == 60)
	girls.give_contact(GirlCatalog.ID_ALINA)
	gs.flow.game_time_minutes = 0
	_ok("complete start density", dating.start_date(GirlCatalog.ID_ALINA, &"apartment"))
	var date_result := DateResult.new()
	date_result.girl_id = GirlCatalog.ID_ALINA
	date_result.relationship_delta = 0
	date_result.duration_minutes = 120
	_ok("complete date density", dating.complete_date(date_result))
	var girl_remaining: int = int(dating.get_date_cooldown_remaining_minutes(GirlCatalog.ID_ALINA))
	_ok("10. girl daily remaining", girl_remaining > 0)
	world.set_city_stage(2)
	_ok("7. city 2 from service", int(world.get_city_stage()) == 2)
	_ok("13. girl remaining stays until next day", int(dating.get_date_cooldown_remaining_minutes(GirlCatalog.ID_ALINA)) > 0)
	world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	world.enter_location(LocationCatalog.ID_CLOTHING_STORE)
	_ok("14. marina open city 2", girls.can_meet_girl(GirlCatalog.ID_MARINA))
	world.unlock_location(LocationCatalog.ID_FURNITURE_STORE)
	world.enter_location(LocationCatalog.ID_FURNITURE_STORE)
	_ok("16. katya open city 2", girls.can_meet_girl(GirlCatalog.ID_KATYA))
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("16. lera open city 2", girls.can_meet_girl(GirlCatalog.ID_LERA))
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	_ok("16. olya open city 2", girls.can_meet_girl(GirlCatalog.ID_OLYA))
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("40. denis city 2", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_DENIS))
	sm.new_game()
	_ok("advance actress city 2", stages.force_complete_current_stage_for_dev())
	_ok("7. after actress city 2", int(world.get_city_stage()) == 2)
	_ok("advance mine work", stages.force_complete_current_stage_for_dev())
	_ok("24. work 200 after mine", WorkService.get_current_hourly_pay() == 200)
	_ok("25. work minutes still 60", WorkService.make_current_work().time_cost_minutes == 60)
	_ok("advance editor city 3", stages.force_complete_current_stage_for_dev())
	_ok("8. after editor city 3", int(world.get_city_stage()) == 3)
	_ok("12. date free city 3", dating.is_free_date_available_today(GirlCatalog.ID_ALINA))
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("19. sonya open city 3", girls.can_meet_girl(GirlCatalog.ID_SONYA))
	world.enter_location(LocationCatalog.ID_CAFE)
	_ok("19. nika open city 3", girls.can_meet_girl(GirlCatalog.ID_NIKA))
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	_ok("19. rita open city 3", girls.can_meet_girl(GirlCatalog.ID_RITA))
	gs.player.rating = 9
	gs.story.stage = 4
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("20. scientist blocked 9", girls.can_meet_girl(GirlCatalog.ID_SCIENTIST) == false)
	gs.player.rating = 10
	_ok("20. scientist open 10", girls.can_meet_girl(GirlCatalog.ID_SCIENTIST))
	gs.player.rating = 11
	gs.story.stage = 5
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	_ok("21. president blocked 11", girls.can_meet_girl(GirlCatalog.ID_PRESIDENT) == false)
	gs.player.rating = 12
	_ok("21. president open 12", girls.can_meet_girl(GirlCatalog.ID_PRESIDENT))
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	_ok("41. lev city 3", _rival_list_has(rivals.get_rivals_at_current_location(), RivalCatalog.ID_LEV))
	sm.new_game()
	gs.story.stage = 4
	stages.reconcile_stage_entry_state()
	_ok("9. reconcile city 3", int(world.get_city_stage()) == 3)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(RivalCatalog.ID_GLEB))
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(true)
	var win: ActionResult = actions.execute(competitions.create_competition_action(CompetitionCatalog.ID_HORIZONTAL_BAR))
	_ok("26. spend 100", win.success)
	_ok("27. payout 200", gs.player.money == 200)
	_ok("28. net +100", gs.player.money == 200)
	_ok("31. defeated", rivals.is_defeated(RivalCatalog.ID_GLEB))
	_ok("33. last challenge after win", int(rivals.get_last_challenge_completed_at(RivalCatalog.ID_GLEB)) == 60)
	_ok("35. rival daily remaining", rivals.get_challenge_cooldown_remaining_minutes(RivalCatalog.ID_GLEB) > 0)
	_ok("32. rematch blocked", competitions.can_start_competition(CompetitionCatalog.ID_HORIZONTAL_BAR) == false)
	world.set_city_stage(2)
	_ok("36. remaining independent of city", rivals.get_challenge_cooldown_remaining_minutes(RivalCatalog.ID_GLEB) > 0)
	clock.advance_time(1440)
	gs.player.money = 100
	_ok("32. rematch after next day", competitions.can_start_competition(CompetitionCatalog.ID_HORIZONTAL_BAR))
	sm.new_game()
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	actions.execute(rivals.create_meet_rival_action(RivalCatalog.ID_GLEB))
	gs.player.money = 100
	gs.flow.game_time_minutes = 0
	competitions.set_forced_won(false)
	var loss: ActionResult = actions.execute(competitions.create_competition_action(CompetitionCatalog.ID_HORIZONTAL_BAR))
	competitions.set_forced_won(null)
	_ok("29. loss payout 0", loss.success and gs.player.money == 0)
	_ok("30. net -100", gs.player.money == 0)
	_ok("34. last challenge after loss", int(rivals.get_last_challenge_completed_at(RivalCatalog.ID_GLEB)) == 60)
	sm.save_game()
	var saved_challenge_at: int = int(rivals.get_last_challenge_completed_at(RivalCatalog.ID_GLEB))
	sm.new_game()
	_ok("45. load challenge time", sm.load_game() and int(rivals.get_last_challenge_completed_at(RivalCatalog.ID_GLEB)) == saved_challenge_at)
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	_ok("43. wrote v13", legacy != null)
	if legacy != null:
		var v13: Dictionary = {
			"save_version": 13,
			"game_state": {
				"flow": {"game_time_minutes": 0},
				"story": {"stage": 4, "finale_reached": false},
				"player": {"money": 0, "rating": 0},
				"progression": {"purchased_ids": []},
				"world": {
					"current_location_id": String(LocationCatalog.START_LOCATION_ID),
					"unlocked_location_ids": ["city_center", "apartment", "cafe"],
				},
				"girls": {"girls_by_id": {}},
				"dating": {"active_date": {}},
				"rivals": {
					"rivals_by_id": {
						"rival_gleb": {"discovered": true, "defeated": true},
					},
				},
			},
		}
		legacy.store_string(JSON.stringify(v13, "\t"))
		legacy.close()
	_ok("43. load v13", sm.load_game())
	_ok("43. migrated city 3", int(world.get_city_stage()) == 3)
	_ok("44. defeated preserved", rivals.is_defeated(RivalCatalog.ID_GLEB))
	_ok("44. last challenge default 0", int(rivals.get_last_challenge_completed_at(RivalCatalog.ID_GLEB)) == 0)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var sim := GameSimulator.new()
		tree.root.add_child(sim)
		sim.start_new_game()
		_ok("hud city stage", sim.get_hud_text().contains("Этап города: 1/3"))
		_ok("hud has no global cooldown", not sim.get_hud_text().contains("Cooldown:"))
		sim.show_section("work")
		_ok("work button 100", sim.get_city_body_text().contains("Работать — 1 ч — +100"))
		sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_automation() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var girls: Variant = _girls_service()
	var actions: Variant = _action_service()
	var automation: Variant = _automation_service()
	_ok("auto GameState", gs != null)
	_ok("auto SaveManager", sm != null)
	_ok("auto TimeService", clock != null)
	_ok("auto StageService", stages != null)
	_ok("auto GirlsService", girls != null)
	_ok("auto ActionService", actions != null)
	_ok("auto AutomationService", automation != null)
	if gs == null or sm == null or clock == null or stages == null or girls == null or actions == null or automation == null:
		return
	var catalog: StageCatalog = stages.get_catalog() as StageCatalog
	if catalog != null:
		catalog.apply_canonical_enter_effects()
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/automation_core.json"
	sm.delete_save()
	sm.new_game()
	_ok("auto new locked", bool(automation.is_unlocked()) == false)
	_ok("auto new clones 0", int(automation.get_total_clones()) == 0)
	_ok("auto new percent 50", int(automation.get_work_allocation_percent()) == 50)
	_ok("auto new dating percent 50", int(automation.get_dating_allocation_percent()) == 50)
	for _step in range(3):
		_ok("auto reach stage 4 step", bool(stages.force_complete_current_stage_for_dev()))
	_ok("auto stage 4", int(stages.get_current_stage()) == 4)
	var scientist_max: int = int(girls.get_relationship_max(GirlCatalog.ID_SCIENTIST))
	girls.change_relationship(GirlCatalog.ID_SCIENTIST, scientist_max)
	_ok("auto stage 5", int(stages.get_current_stage()) == 5)
	_ok("auto unlocked", bool(automation.is_unlocked()))
	_ok("auto granted", gs.automation.initial_clones_granted == true)
	_ok("auto clones 10", int(automation.get_total_clones()) == 10)
	stages.reconcile_stage_entry_state()
	stages.reconcile_stage_entry_state()
	_ok("auto reconcile clones 10", int(automation.get_total_clones()) == 10)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(40)
	gs.player.money = 0
	clock.advance_time(60)
	_ok("auto work 40 percent money", gs.player.money == 400)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(0)
	gs.player.money = 0
	clock.advance_time(60)
	_ok("auto 100 dating money 0", gs.player.money == 0)
	_ok("auto 100 dating rating 1", int(gs.player.rating) == 1)
	_ok("auto 100 dating expansion 1", is_equal_approx(float(automation.get_expansion_progress()), 1.0))
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	gs.automation.total_clones = 1
	automation.set_work_allocation_percent(0)
	clock.advance_time(60)
	_ok("auto fraction hour rating 0", int(gs.player.rating) == 0)
	_ok("auto fraction hour progress", is_equal_approx(float(automation.get_dating_progress_fraction()), 0.1))
	_ok("auto fraction hour expansion 0.1", is_equal_approx(float(automation.get_expansion_progress()), 0.1))
	clock.advance_time(540)
	_ok("auto fraction 10h rating 1", int(gs.player.rating) == 1)
	_ok("auto fraction 10h leftover", is_equal_approx(float(automation.get_dating_progress_fraction()), 0.0))
	_ok("auto fraction 10h expansion 1", is_equal_approx(float(automation.get_expansion_progress()), 1.0))
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	_ok("auto work mult 1", is_equal_approx(float(automation.get_work_multiplier()), 1.0))
	_ok("auto dating mult 1", is_equal_approx(float(automation.get_dating_multiplier()), 1.0))
	gs.player.money = 1000
	var buy_clones: ActionResult = actions.execute(automation.create_upgrade_action(AutomationCatalog.ID_EXTRA_CLONES))
	_ok("auto extra clones success", buy_clones.success)
	_ok("auto extra clones 20", int(automation.get_total_clones()) == 20)
	_ok("auto extra clones stored", bool(automation.is_upgrade_purchased(AutomationCatalog.ID_EXTRA_CLONES)))
	var buy_clones_again: ActionResult = actions.execute(automation.create_upgrade_action(AutomationCatalog.ID_EXTRA_CLONES))
	_ok("auto extra clones repeat fail", buy_clones_again.success == false)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(40)
	gs.player.money = 1500
	var buy_work: ActionResult = actions.execute(automation.create_upgrade_action(AutomationCatalog.ID_WORK_OPTIMIZATION))
	_ok("auto work upgrade success", buy_work.success)
	_ok("auto work mult 1.5", is_equal_approx(float(automation.get_work_multiplier()), 1.5))
	gs.player.money = 0
	clock.advance_time(60)
	_ok("auto work upgrade money 600", gs.player.money == 600)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(0)
	gs.player.money = 1500
	var buy_dating: ActionResult = actions.execute(automation.create_upgrade_action(AutomationCatalog.ID_DATING_OPTIMIZATION))
	_ok("auto dating upgrade success", buy_dating.success)
	_ok("auto dating mult 1.5", is_equal_approx(float(automation.get_dating_multiplier()), 1.5))
	clock.advance_time(60)
	_ok("auto dating upgrade 1.5 rating", int(gs.player.rating) == 1)
	_ok("auto dating upgrade leftover", is_equal_approx(float(automation.get_dating_progress_fraction()), 0.5))
	_ok("auto dating upgrade expansion 1.5", is_equal_approx(float(automation.get_expansion_progress()), 1.5))
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(50)
	gs.player.money = 0
	clock.advance_time(60)
	var jump_money: int = int(gs.player.money)
	var jump_rating: int = int(gs.player.rating)
	var jump_expansion: float = float(automation.get_expansion_progress())
	var jump_work_frac: float = float(automation.get_work_income_fraction())
	var jump_date_frac: float = float(automation.get_dating_progress_fraction())
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(50)
	gs.player.money = 0
	for _minute in range(60):
		clock.advance_time(1)
	_ok("auto timestep money", int(gs.player.money) == jump_money)
	_ok("auto timestep rating", int(gs.player.rating) == jump_rating)
	_ok("auto timestep expansion", is_equal_approx(float(automation.get_expansion_progress()), jump_expansion))
	_ok("auto timestep work frac", is_equal_approx(float(automation.get_work_income_fraction()), jump_work_frac))
	_ok("auto timestep date frac", is_equal_approx(float(automation.get_dating_progress_fraction()), jump_date_frac))
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	automation.set_work_allocation_percent(50)
	gs.player.money = 0
	var work_action: GameAction = WorkService.create_work_action(WorkService.make_work_basic())
	var work_result: ActionResult = actions.execute(work_action)
	_ok("auto parallel work success", work_result.success)
	_ok("auto parallel money 600", gs.player.money == 600)
	_write_v10_automation_save(sm, 5)
	_ok("auto load v10 stage 5", sm.load_game())
	_ok("auto v10 stage 5 unlocked", bool(automation.is_unlocked()))
	_ok("auto v10 stage 5 granted", gs.automation.initial_clones_granted == true)
	_ok("auto v10 stage 5 clones", int(automation.get_total_clones()) == 10)
	_write_v10_automation_save(sm, 6)
	_ok("auto load v10 stage 6", sm.load_game())
	_ok("auto v10 stage 6 unlocked", bool(automation.is_unlocked()))
	_ok("auto v10 stage 6 granted", gs.automation.initial_clones_granted == true)
	_ok("auto v10 stage 6 clones", int(automation.get_total_clones()) == 10)
	_ok("auto v10 scope city", StringName(automation.get_current_expansion_scope()) == &"city")
	_write_v11_factory_rating_save(sm, 10, 5, 0.3)
	_ok("auto load v11", sm.load_game())
	_ok("auto v11 rating 15", int(gs.player.rating) == 15)
	_ok("auto v11 fraction 0.3", is_equal_approx(float(automation.get_dating_progress_fraction()), 0.3))
	_ok("auto v11 scope city", StringName(automation.get_current_expansion_scope()) == &"city")
	_ok("auto v11 expansion 5.3", is_equal_approx(float(automation.get_expansion_progress()), 5.3))
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	gs.player.rating = 10
	gs.automation.total_clones = 34
	automation.set_work_allocation_percent(0)
	clock.advance_time(60)
	_ok("auto rating 3.4 whole", int(gs.player.rating) == 13)
	_ok("auto rating 3.4 fraction", is_equal_approx(float(automation.get_dating_progress_fraction()), 0.4))
	_ok("auto rating 3.4 expansion", is_equal_approx(float(automation.get_expansion_progress()), 3.4))
	var home_total: int = int(girls.get_home_city_girl_count())
	_ok("auto home total authored", home_total >= 7)
	var home_before: int = int(girls.get_home_city_completed_count())
	gs.player.rating = 1000
	var alina_max: int = int(girls.get_relationship_max(GirlCatalog.ID_ALINA))
	girls.change_relationship(GirlCatalog.ID_ALINA, alina_max)
	_ok("auto manual rating 1001", int(gs.player.rating) == 1001)
	_ok("auto home completed +1", int(girls.get_home_city_completed_count()) == home_before + 1)
	var coverage_before: int = int(girls.get_home_city_completed_count())
	gs.automation.total_clones = 1000
	automation.set_work_allocation_percent(0)
	clock.advance_time(60)
	_ok("auto factory rating grew", int(gs.player.rating) > 1001)
	_ok("auto home coverage independent", int(girls.get_home_city_completed_count()) == coverage_before)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	gs.automation.total_clones = 20
	gs.automation.expansion_progress = 100.0
	gs.player.money = 10000
	var expand_country: ActionResult = actions.execute(automation.create_expansion_action(&"country"))
	_ok("auto city to country", expand_country.success)
	_ok("auto country scope", StringName(automation.get_current_expansion_scope()) == &"country")
	_ok("auto country progress 0", is_equal_approx(float(automation.get_expansion_progress()), 0.0))
	_ok("auto country required 1000", is_equal_approx(float(automation.get_required_expansion_progress()), 1000.0))
	_ok("auto country clones 200", int(automation.get_total_clones()) == 200)
	_ok("auto country money 0", int(gs.player.money) == 0)
	gs.automation.expansion_progress = 1000.0
	gs.player.money = 1000000
	var expand_world: ActionResult = actions.execute(automation.create_expansion_action(&"world"))
	_ok("auto country to world", expand_world.success)
	_ok("auto world scope", StringName(automation.get_current_expansion_scope()) == &"world")
	_ok("auto world progress 0", is_equal_approx(float(automation.get_expansion_progress()), 0.0))
	_ok("auto world clones 2000", int(automation.get_total_clones()) == 2000)
	sm.new_game()
	automation.unlock()
	automation.grant_initial_clones()
	gs.automation.expansion_progress = 100.0
	automation.set_work_allocation_percent(0)
	var capped_rating: int = int(gs.player.rating)
	clock.advance_time(180)
	_ok("auto capped city 100", is_equal_approx(float(automation.get_expansion_progress()), 100.0))
	_ok("auto capped rating grows", int(gs.player.rating) > capped_rating)
	sm.new_game()
	gs.story.stage = 6
	gs.story.finale_reached = false
	automation.unlock()
	gs.automation.current_expansion_scope = &"world"
	gs.automation.expansion_progress = 9999.0
	_ok("auto stage 6 world unmet", stages.try_complete_current_stage() == false)
	_ok("auto stage 6 not finale", stages.is_finale_reached() == false)
	gs.automation.expansion_progress = 10000.0
	_ok("auto stage 6 world complete", stages.try_complete_current_stage())
	_ok("auto stage 6 stays", int(stages.get_current_stage()) == 6)
	_ok("auto stage 6 finale", stages.is_finale_reached())
	sm.new_game()
	for _pre_stage in range(4):
		_ok("auto pre world stage step", bool(stages.force_complete_current_stage_for_dev()))
	var scientist_max_pre: int = int(girls.get_relationship_max(GirlCatalog.ID_SCIENTIST))
	girls.change_relationship(GirlCatalog.ID_SCIENTIST, scientist_max_pre)
	_ok("auto pre world stage 5", int(stages.get_current_stage()) == 5)
	automation.unlock()
	gs.automation.current_expansion_scope = &"world"
	gs.automation.expansion_progress = 10000.0
	_ok("auto pre world stays 5", int(stages.get_current_stage()) == 5)
	_ok("auto pre world not finale", stages.is_finale_reached() == false)
	var president_max: int = int(girls.get_relationship_max(GirlCatalog.ID_PRESIDENT))
	girls.change_relationship(GirlCatalog.ID_PRESIDENT, president_max)
	_ok("auto pre world finale after 5", stages.is_finale_reached())
	_ok("auto pre world stage stays 6", int(stages.get_current_stage()) == 6)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var sim := GameSimulator.new()
		tree.root.add_child(sim)
		sim.start_new_game()
		sim.show_section("factory")
		_ok("auto sim factory hidden", sim.get_current_section() != "factory")
		for _stage_step in range(4):
			sim.complete_current_stage()
		_ok("auto sim stage 5", int(stages.get_current_stage()) == 5)
		sim.show_section("factory")
		_ok("auto sim factory shown", sim.get_current_section() == "factory")
		var factory_text: String = sim.get_city_body_text()
		_ok("auto sim clones", factory_text.contains("Клоны: 10"))
		_ok("auto sim work 50", factory_text.contains("Работа: 50%"))
		_ok("auto sim dating 50", factory_text.contains("Свидания: 50%"))
		_ok("auto sim income 500", factory_text.contains("500 / игровой час"))
		_ok("auto sim rating 0.5", factory_text.contains("+0.5 / игровой час"))
		_ok("auto sim factory city", factory_text.contains("другой город"))
		_ok("auto sim expansion", factory_text.contains("ЭКСПАНСИЯ"))
		automation.set_work_allocation_percent(80)
		sim.refresh()
		factory_text = sim.get_city_body_text()
		_ok("auto sim work 80", factory_text.contains("Работа: 80%"))
		_ok("auto sim dating 20", factory_text.contains("Свидания: 20%"))
		_ok("auto sim income 800", factory_text.contains("800 / игровой час"))
		_ok("auto sim rating 0.2", factory_text.contains("+0.2 / игровой час"))
		sim.show_section("home")
		var home_text: String = sim.get_city_body_text()
		_ok("auto sim home city", home_text.contains("Родной город:"))
		_ok("auto sim home factory", home_text.contains("Фабрика:"))
		sim.queue_free()
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()

func _home_city_girl_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append(GirlCatalog.ID_ALINA)
	ids.append(GirlCatalog.ID_MARINA)
	ids.append(GirlCatalog.ID_VIKA)
	ids.append(GirlCatalog.ID_DASHA)
	ids.append(GirlCatalog.ID_ACTRESS)
	ids.append(GirlCatalog.ID_KATYA)
	ids.append(GirlCatalog.ID_LERA)
	ids.append(GirlCatalog.ID_OLYA)
	ids.append(GirlCatalog.ID_MINE_BOSS)
	ids.append(GirlCatalog.ID_MAGAZINE_EDITOR)
	ids.append(GirlCatalog.ID_SONYA)
	ids.append(GirlCatalog.ID_NIKA)
	ids.append(GirlCatalog.ID_RITA)
	ids.append(GirlCatalog.ID_SCIENTIST)
	ids.append(GirlCatalog.ID_PRESIDENT)
	ids.append(GirlCatalog.ID_KIRA)
	ids.append(GirlCatalog.ID_EVA)
	return ids


func _meet_rating_table() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append({"girl_id": GirlCatalog.ID_ALINA, "rating": 0, "stage": 1, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_MARINA, "rating": 0, "stage": 1, "city_stage": 2})
	rows.append({"girl_id": GirlCatalog.ID_VIKA, "rating": 0, "stage": 1, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_DASHA, "rating": 0, "stage": 1, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_ACTRESS, "rating": 2, "stage": 1, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_KATYA, "rating": 0, "stage": 1, "city_stage": 2})
	rows.append({"girl_id": GirlCatalog.ID_LERA, "rating": 0, "stage": 1, "city_stage": 2})
	rows.append({"girl_id": GirlCatalog.ID_OLYA, "rating": 0, "stage": 1, "city_stage": 2})
	rows.append({"girl_id": GirlCatalog.ID_MINE_BOSS, "rating": 5, "stage": 2, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_MAGAZINE_EDITOR, "rating": 7, "stage": 3, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_SONYA, "rating": 0, "stage": 1, "city_stage": 3})
	rows.append({"girl_id": GirlCatalog.ID_NIKA, "rating": 0, "stage": 1, "city_stage": 3})
	rows.append({"girl_id": GirlCatalog.ID_RITA, "rating": 0, "stage": 1, "city_stage": 3})
	rows.append({"girl_id": GirlCatalog.ID_SCIENTIST, "rating": 10, "stage": 4, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_PRESIDENT, "rating": 12, "stage": 5, "city_stage": 1})
	rows.append({"girl_id": GirlCatalog.ID_KIRA, "rating": 0, "stage": 1, "city_stage": 2})
	rows.append({"girl_id": GirlCatalog.ID_EVA, "rating": 0, "stage": 1, "city_stage": 3})
	return rows


func _story_girl_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	specs.append({
		"girl_id": GirlCatalog.ID_ACTRESS,
		"rival_id": RivalCatalog.ID_BORIS,
		"location_id": LocationCatalog.ID_CITY_CENTER,
		"competition_id": CompetitionCatalog.ID_CASTING,
		"city_stage": 1,
	})
	specs.append({
		"girl_id": GirlCatalog.ID_MINE_BOSS,
		"rival_id": RivalCatalog.ID_FOREMAN,
		"location_id": LocationCatalog.ID_RESTAURANT,
		"competition_id": CompetitionCatalog.ID_ARMWRESTLING,
		"city_stage": 2,
	})
	specs.append({
		"girl_id": GirlCatalog.ID_MAGAZINE_EDITOR,
		"rival_id": RivalCatalog.ID_COLUMNIST,
		"location_id": LocationCatalog.ID_CAFE,
		"competition_id": CompetitionCatalog.ID_TASTE_DEBATE,
		"city_stage": 2,
	})
	specs.append({
		"girl_id": GirlCatalog.ID_SCIENTIST,
		"rival_id": RivalCatalog.ID_ACADEMIC,
		"location_id": LocationCatalog.ID_CITY_CENTER,
		"competition_id": CompetitionCatalog.ID_GRANT,
		"city_stage": 3,
	})
	specs.append({
		"girl_id": GirlCatalog.ID_PRESIDENT,
		"rival_id": RivalCatalog.ID_MINISTER,
		"location_id": LocationCatalog.ID_RESTAURANT,
		"competition_id": CompetitionCatalog.ID_PROTOCOL_DUEL,
		"city_stage": 3,
	})
	return specs


func _filler_girl_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append(GirlCatalog.ID_ALINA)
	ids.append(GirlCatalog.ID_MARINA)
	ids.append(GirlCatalog.ID_VIKA)
	ids.append(GirlCatalog.ID_DASHA)
	ids.append(GirlCatalog.ID_KATYA)
	ids.append(GirlCatalog.ID_LERA)
	ids.append(GirlCatalog.ID_OLYA)
	ids.append(GirlCatalog.ID_SONYA)
	ids.append(GirlCatalog.ID_NIKA)
	ids.append(GirlCatalog.ID_RITA)
	ids.append(GirlCatalog.ID_KIRA)
	ids.append(GirlCatalog.ID_EVA)
	return ids


func _assert_coverage(girls: Variant, label: String, completed: int, total: int) -> void:
	_ok("%s girl count" % label, int(girls.get_home_city_girl_count()) == total)
	_ok("%s completed" % label, int(girls.get_home_city_completed_count()) == completed)
	var expected_percent: float = 0.0
	if total > 0:
		expected_percent = 100.0 * float(completed) / float(total)
	_ok("%s percent" % label, is_equal_approx(float(girls.get_home_city_coverage_percent()), expected_percent))


func _enter_girl_world(world: Variant, girls: Variant, girl_id: StringName) -> void:
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if definition == null:
		return
	if definition.location_id == LocationCatalog.ID_RESTAURANT:
		world.unlock_location(LocationCatalog.ID_RESTAURANT)
	elif definition.location_id == LocationCatalog.ID_FURNITURE_STORE:
		world.unlock_location(LocationCatalog.ID_FURNITURE_STORE)
	elif definition.location_id == LocationCatalog.ID_LEISURE_CENTER:
		world.unlock_location(LocationCatalog.ID_LEISURE_CENTER)
	elif definition.location_id == LocationCatalog.ID_CLOTHING_STORE:
		world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	world.enter_location(definition.location_id)


func _max_girl(girls: Variant, girl_id: StringName) -> void:
	var max_value: int = int(girls.get_relationship_max(girl_id))
	var current: int = int(girls.get_relationship(girl_id))
	if current < max_value:
		girls.change_relationship(girl_id, max_value - current)


func _first_date_venue_id(dating: Variant, girl_id: StringName) -> StringName:
	var locations: Array = dating.get_available_date_venues(girl_id)
	for item in locations:
		if not (item is DateVenue):
			continue
		var venue: DateVenue = item as DateVenue
		if bool(dating.is_date_venue_available(girl_id, venue.id)):
			return venue.id
	return &"apartment"

func _first_selectable_local_move_id(engine: DateEngine) -> StringName:
	for option in engine.get_available_moves():
		if option != null and option.kind == DateTypes.DateMoveKind.LOCAL and option.is_selectable():
			return option.move_id
	return &""


func _selectable_local_move_ids(engine: DateEngine) -> Array[StringName]:
	var ids: Array[StringName] = []
	var view: DateEpisodeView = engine.get_current_episode()
	for option in _source_options(view, DateTypes.DateMoveSource.VENUE):
		if option != null and option.is_selectable():
			ids.append(option.move_id)
	return ids


func _first_locked_local_option(engine: DateEngine) -> DateMoveOption:
	var view: DateEpisodeView = engine.get_current_episode()
	for option in _source_options(view, DateTypes.DateMoveSource.VENUE):
		if option != null and option.availability == DateTypes.MoveAvailability.LOCKED:
			return option
	return null


func _visible_object_ids(apartment: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if apartment == null:
		return ids
	for upgrade in apartment.get_catalog().all_objects():
		if upgrade != null and bool(apartment.is_object_visible(upgrade)):
			ids.append(upgrade.id)
	return ids


func _local_objects_with_prefix(catalog: DateContentCatalog, prefix: String) -> Array[DateLocalObject]:
	var result: Array[DateLocalObject] = []
	for local_object in catalog.local_objects:
		if local_object == null or not local_object.enabled:
			continue
		if String(local_object.id).begins_with(prefix):
			result.append(local_object)
	return result


func _local_moves_of_objects(catalog: DateContentCatalog, objects: Array[DateLocalObject]) -> Array[DateMove]:
	var moves: Array[DateMove] = []
	for local_object in objects:
		for move_id in local_object.move_ids:
			var move: DateMove = catalog.find_move(move_id)
			if move != null:
				moves.append(move)
	return moves


func _skip_to_08_00_action() -> GameAction:
	return GameActionCatalog.make_skip_to_08_00()


func _assert_skip_to_08_00(gs: Variant, clock: Variant, actions: Variant, label: String, start_minutes: int, expected_delta: int, expected_day: int) -> void:
	gs.flow.game_time_minutes = start_minutes
	var events: Array = []
	var on_time := func(delta_minutes: int, _previous_game_time: int, _current_game_time: int) -> void:
		events.append(delta_minutes)
	clock.time_advanced.connect(on_time)
	var action: GameAction = _skip_to_08_00_action()
	_ok("%s factory id" % label, action != null and action.id == GameActionCatalog.ID_SKIP_TO_08_00)
	_ok("%s cost" % label, action != null and action.time_cost_minutes == expected_delta)
	_ok("%s money 0" % label, action != null and action.money_cost == 0)
	var result: ActionResult = actions.execute(action)
	clock.time_advanced.disconnect(on_time)
	_ok("%s success" % label, result.success)
	_ok("%s time spent" % label, int(result.time_spent_minutes) == expected_delta)
	_assert_clock(label, clock, start_minutes + expected_delta, expected_day, 8, 0)
	_ok("%s time_advanced" % label, events.size() == 1 and int(events[0]) == expected_delta)

func _play_real_date_session(dating: Variant, girl_id: StringName, date_venue_id: StringName, outfit_id: StringName) -> bool:
	if not dating.start_date(girl_id, date_venue_id, outfit_id):
		return false
	var engine: DateEngine = dating.get_date_engine()
	if engine == null:
		return false
	var guard: int = 0
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT and guard < 64:
		guard += 1
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		_choose(engine, _pick_preference(engine, true))
	var session: DateSession = engine.get_session_state()
	var date_result := DateResult.new()
	date_result.girl_id = girl_id
	date_result.relationship_delta = session.relationship_after - session.relationship_before
	date_result.duration_minutes = 120
	return bool(dating.complete_date(date_result))


func _complete_simple_date(dating: Variant, girl_id: StringName, date_venue_id: StringName, outfit_id: StringName, delta: int) -> bool:
	if not dating.start_date(girl_id, date_venue_id, outfit_id):
		return false
	var date_result := DateResult.new()
	date_result.girl_id = girl_id
	date_result.relationship_delta = delta
	date_result.duration_minutes = 120
	return bool(dating.complete_date(date_result))


func _test_home_city_catalog_consistency() -> void:
	var girls: Variant = _girls_service()
	var sm: Variant = _save_manager()
	_ok("catalog GirlsService", girls != null)
	_ok("catalog SaveManager", sm != null)
	if girls == null or sm == null:
		return
	var seed_catalog: DateContentCatalog = SeedContentFactory.new().build_catalog()
	var runtime_catalog: DateContentCatalog = load("res://date_system/content/catalog/date_content_catalog.tres") as DateContentCatalog
	_ok("seed date catalog", seed_catalog != null)
	_ok("runtime date catalog", runtime_catalog != null)
	var girl_catalog: GirlCatalog = girls.get_catalog() as GirlCatalog
	_ok("girl catalog", girl_catalog != null)
	if girl_catalog == null or seed_catalog == null:
		return
	var validator := ContentValidator.new()
	_ok("seed leftover tags", _find_code(validator.validate(seed_catalog), "INCOMPLETE_GIRL_TAG_COVERAGE") == null)
	if runtime_catalog != null:
		_ok("runtime leftover tags", _find_code(validator.validate(runtime_catalog), "INCOMPLETE_GIRL_TAG_COVERAGE") == null)
	var coverage_ids: Array[StringName] = []
	for definition in girl_catalog.get_all_girls():
		if definition == null or not definition.counts_toward_home_city_coverage:
			continue
		coverage_ids.append(definition.id)
		var seed_profile: GirlProfile = seed_catalog.find_girl(definition.id)
		_ok("seed profile %s" % String(definition.id), seed_profile != null)
		if runtime_catalog != null:
			_ok("runtime profile %s" % String(definition.id), runtime_catalog.find_girl(definition.id) != null)
		if seed_profile != null:
			_ok("id match %s" % String(definition.id), seed_profile.id == definition.id)
			_ok("trait %s" % String(definition.id), seed_catalog.find_trait(seed_profile.trait_id) != null)
			var expected_max: int = GirlCatalog.seed_relationship_max(definition.id)
			_ok("range floor %s" % String(definition.id), definition.relationship_min == 0 and definition.relationship_max == expected_max)
			_ok("difficulty %s" % String(definition.id), seed_catalog.find_girl_difficulty(seed_profile.difficulty_preset_id) != null)
			_ok("positives %s" % String(definition.id), seed_profile.positive_tag_ids.size() > 0)
			_ok("no secondary_rule_id %s" % String(definition.id), seed_profile.get("secondary_rule_id") == null)
	_ok("catalog has no secondary_rules", seed_catalog.get("secondary_rules") == null)
	_ok("breakdown has combo_score", DateScoreBreakdown.new().to_dictionary().has("combo_score"))
	_ok("breakdown has no secondary_score", not DateScoreBreakdown.new().to_dictionary().has("secondary_score"))
	_ok("home city count 17", coverage_ids.size() == 17)
	for girl_id in _home_city_girl_ids():
		_ok("authored id %s" % String(girl_id), coverage_ids.has(girl_id))
		_ok("seed has %s" % String(girl_id), seed_catalog.find_girl(girl_id) != null)
		if runtime_catalog != null:
			_ok("runtime has %s" % String(girl_id), runtime_catalog.find_girl(girl_id) != null)
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/home_city_catalog.json"
	sm.delete_save()
	sm.new_game()
	_assert_coverage(girls, "new game", 0, 17)
	_max_girl(girls, GirlCatalog.ID_ALINA)
	_assert_coverage(girls, "alina only", 1, 17)
	sm.new_game()
	for girl_id in _home_city_girl_ids():
		if girl_id == GirlCatalog.ID_SONYA:
			continue
		_max_girl(girls, girl_id)
	_assert_coverage(girls, "sixteen without sonya", 16, 17)
	_max_girl(girls, GirlCatalog.ID_SONYA)
	_assert_coverage(girls, "all seventeen", 17, 17)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_rating_meet_gates() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	_ok("gates GameState", gs != null)
	_ok("gates SaveManager", sm != null)
	_ok("gates WorldService", world != null)
	_ok("gates GirlsService", girls != null)
	if gs == null or sm == null or world == null or girls == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/rating_meet_gates.json"
	sm.delete_save()
	for row in _meet_rating_table():
		var girl_id: StringName = row["girl_id"]
		var required: int = int(row["rating"])
		var min_stage: int = int(row["stage"])
		var min_city: int = int(row.get("city_stage", 1))
		sm.new_game()
		gs.story.stage = min_stage
		_enter_girl_world(world, girls, girl_id)
		if min_city > 1:
			_ok("%s blocked at city 1" % String(girl_id), girls.can_meet_girl(girl_id) == false)
			world.set_city_stage(min_city)
		if required > 0:
			gs.player.rating = required - 1
			_ok("%s blocked at %d" % [String(girl_id), required - 1], girls.can_meet_girl(girl_id) == false)
		gs.player.rating = required
		_ok("%s open at %d" % [String(girl_id), required], girls.can_meet_girl(girl_id))
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_story_rival_visibility() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var rivals: Variant = _rivals_service()
	_ok("visibility GameState", gs != null)
	_ok("visibility SaveManager", sm != null)
	_ok("visibility WorldService", world != null)
	_ok("visibility GirlsService", girls != null)
	_ok("visibility RivalsService", rivals != null)
	if gs == null or sm == null or world == null or girls == null or rivals == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/story_rival_visibility.json"
	sm.delete_save()
	for spec in _story_girl_specs():
		var girl_id: StringName = spec["girl_id"]
		var rival_id: StringName = spec["rival_id"]
		var location_id: StringName = spec["location_id"]
		sm.new_game()
		if location_id == LocationCatalog.ID_RESTAURANT:
			world.unlock_location(LocationCatalog.ID_RESTAURANT)
		world.set_city_stage(int(spec.get("city_stage", 1)))
		world.enter_location(location_id)
		var before: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
		_ok("%s hidden before discover" % String(rival_id), _rival_list_has(before, rival_id) == false)
		_ok("discover %s" % String(girl_id), girls.discover_girl(girl_id))
		var after_discover: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
		_ok("%s visible after discover" % String(rival_id), _rival_list_has(after_discover, rival_id))
		var rival_def: RivalDefinition = rivals.get_definition(rival_id)
		if rival_def != null:
			var linked: Variant = rival_def.get("linked_girl_id")
			_ok("%s linked girl" % String(rival_id), String(linked) == String(girl_id))
		_ok("give contact %s" % String(girl_id), girls.give_contact(girl_id))
		var after_contact: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
		_ok("%s visible after contact" % String(rival_id), _rival_list_has(after_contact, rival_id))
		_ok("defeat %s" % String(rival_id), rivals.defeat_rival(rival_id))
		_ok("%s defeated state" % String(rival_id), rivals.is_defeated(rival_id))
		var defeated_req := RivalDefeatedGirlRequirement.new()
		defeated_req.rival_id = rival_id
		_ok("%s date req met" % String(rival_id), defeated_req.is_met(girl_id))
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_restaurant_stage_unlock() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	var girls: Variant = _girls_service()
	var world: Variant = _world_service()
	_ok("restaurant GameState", gs != null)
	_ok("restaurant SaveManager", sm != null)
	_ok("restaurant StageService", stages != null)
	_ok("restaurant GirlsService", girls != null)
	_ok("restaurant WorldService", world != null)
	if gs == null or sm == null or stages == null or girls == null or world == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/restaurant_stage_unlock.json"
	sm.delete_save()
	sm.new_game()
	_ok("restaurant locked new game", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
	_ok("restaurant stage 1", int(stages.get_current_stage()) == 1)
	_ok("date venue apartment only stage 1", world.has_unlocked_date_venue(&"apartment") and not world.has_unlocked_date_venue(&"cafe") and not world.has_unlocked_date_venue(&"restaurant"))
	_max_girl(girls, GirlCatalog.ID_ACTRESS)
	_ok("restaurant stage 2", int(stages.get_current_stage()) == 2)
	_ok("restaurant unlocked stage 2", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	_ok("leisure unlocked stage 2", world.is_location_unlocked(LocationCatalog.ID_LEISURE_CENTER))
	_ok("furniture unlocked stage 2", world.is_location_unlocked(LocationCatalog.ID_FURNITURE_STORE))
	_ok("date venues stage 2", world.has_unlocked_date_venue(&"cafe") and world.has_unlocked_date_venue(&"leisure_center") and not world.has_unlocked_date_venue(&"restaurant"))
	sm.save_game()
	sm.new_game()
	_ok("restaurant locked after reset", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT) == false)
	_ok("restaurant load", sm.load_game())
	_ok("restaurant stage 2 loaded", int(stages.get_current_stage()) == 2)
	_ok("restaurant unlocked loaded", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_dates_for_home_city_girls() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var rivals: Variant = _rivals_service()
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	_ok("dates10 GameState", gs != null)
	_ok("dates10 SaveManager", sm != null)
	_ok("dates10 WorldService", world != null)
	_ok("dates10 GirlsService", girls != null)
	_ok("dates10 RivalsService", rivals != null)
	_ok("dates10 DatingService", dating != null)
	_ok("dates10 ActionService", actions != null)
	if gs == null or sm == null or world == null or girls == null or rivals == null or dating == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/dates_home_city.json"
	sm.delete_save()
	sm.new_game()
	gs.player.rating = 12
	gs.story.stage = 5
	world.set_city_stage(3)
	world.unlock_location(LocationCatalog.ID_RESTAURANT)
	world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	var equipment: Variant = _equipment_service()
	if equipment != null:
		gs.player.money = 250
		actions.execute(equipment.create_buy_outfit_action(OutfitCatalog.ID_BUSINESS))
	var alina_played: bool = false
	for girl_id in _home_city_girl_ids():
		_enter_girl_world(world, girls, girl_id)
		var meet_result: ActionResult = actions.execute(girls.create_meet_girl_action(girl_id))
		_ok("meet %s" % String(girl_id), meet_result.success)
		for spec in _story_girl_specs():
			if spec["girl_id"] != girl_id:
				continue
			var rival_id: StringName = spec["rival_id"]
			_ok("defeat before date %s" % String(girl_id), rivals.defeat_rival(rival_id))
		var locations: Array = dating.get_available_date_venues(girl_id)
		_ok("venues %s" % String(girl_id), locations.size() > 0)
		var date_venue_id: StringName = _first_date_venue_id(dating, girl_id)
		var before_rel: int = int(girls.get_relationship(girl_id))
		var completed: bool = false
		if girl_id == GirlCatalog.ID_ALINA:
			completed = _play_real_date_session(dating, girl_id, date_venue_id, OutfitCatalog.ID_BUSINESS)
			alina_played = completed
		else:
			completed = _complete_simple_date(dating, girl_id, date_venue_id, OutfitCatalog.ID_BUSINESS, 1)
		_ok("date %s" % String(girl_id), completed)
		_ok("date applied %s" % String(girl_id), int(girls.get_relationship(girl_id)) != before_rel or before_rel == int(girls.get_relationship_max(girl_id)))
	_ok("alina real session", alina_played)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _advance_manual_path_to_scientist(
	_gs: Variant,
	sm: Variant,
	stages: Variant,
	world: Variant,
	girls: Variant,
	rivals: Variant,
	rating: Variant,
	dating: Variant,
	automation: Variant,
	actions: Variant
) -> void:
	sm.new_game()
	_ok("manual new rating 0", int(rating.get_rating()) == 0)
	_ok("manual new stage 1", int(stages.get_current_stage()) == 1)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var meet_alina: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_ALINA))
	_ok("manual meet alina", meet_alina.success)
	var alina_date_ok: bool = _play_real_date_session(dating, GirlCatalog.ID_ALINA, _first_date_venue_id(dating, GirlCatalog.ID_ALINA), &"casual")
	_ok("manual alina real date", alina_date_ok)
	_max_girl(girls, GirlCatalog.ID_ALINA)
	_ok("manual alina rating 1", int(rating.get_rating()) == 1)
	_ok("manual alina keeps stage 1", int(stages.get_current_stage()) == 1)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_vika: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_VIKA))
	_ok("manual meet vika", meet_vika.success)
	_max_girl(girls, GirlCatalog.ID_VIKA)
	_ok("manual vika rating 2", int(rating.get_rating()) == 2)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var meet_actress: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_ACTRESS))
	_ok("manual meet actress", meet_actress.success)
	var after_actress_meet: Array[RivalDefinition] = rivals.get_rivals_at_current_location()
	_ok("manual boris visible", _rival_list_has(after_actress_meet, RivalCatalog.ID_BORIS))
	_ok("manual defeat boris", rivals.defeat_rival(RivalCatalog.ID_BORIS))
	_max_girl(girls, GirlCatalog.ID_ACTRESS)
	_ok("manual rating 3", int(rating.get_rating()) == 3)
	_ok("manual stage 2", int(stages.get_current_stage()) == 2)
	_ok("manual city 2", int(world.get_city_stage()) == 2)
	_ok("manual restaurant", world.is_location_unlocked(LocationCatalog.ID_RESTAURANT))
	world.unlock_location(LocationCatalog.ID_CLOTHING_STORE)
	world.enter_location(LocationCatalog.ID_CLOTHING_STORE)
	_ok("manual marina open stage 2", girls.can_meet_girl(GirlCatalog.ID_MARINA))
	var meet_marina: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_MARINA))
	_ok("manual meet marina", meet_marina.success)
	world.unlock_location(LocationCatalog.ID_FURNITURE_STORE)
	world.enter_location(LocationCatalog.ID_FURNITURE_STORE)
	var meet_katya: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_KATYA))
	_ok("manual meet katya", meet_katya.success)
	_max_girl(girls, GirlCatalog.ID_KATYA)
	_ok("manual katya keeps stage 2", int(stages.get_current_stage()) == 2)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_lera: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_LERA))
	_ok("manual meet lera", meet_lera.success)
	_max_girl(girls, GirlCatalog.ID_LERA)
	_ok("manual rating 5", int(rating.get_rating()) == 5)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var meet_mine: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_MINE_BOSS))
	_ok("manual meet mine boss", meet_mine.success)
	_ok("manual defeat foreman", rivals.defeat_rival(RivalCatalog.ID_FOREMAN))
	_max_girl(girls, GirlCatalog.ID_MINE_BOSS)
	_ok("manual stage 3", int(stages.get_current_stage()) == 3)
	_ok("manual work 200", WorkService.get_current_hourly_pay() == 200)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var meet_olya: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_OLYA))
	_ok("manual meet olya", meet_olya.success)
	_max_girl(girls, GirlCatalog.ID_OLYA)
	_ok("manual rating 7", int(rating.get_rating()) == 7)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_editor: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_MAGAZINE_EDITOR))
	_ok("manual meet editor", meet_editor.success)
	_ok("manual defeat columnist", rivals.defeat_rival(RivalCatalog.ID_COLUMNIST))
	_max_girl(girls, GirlCatalog.ID_MAGAZINE_EDITOR)
	_ok("manual stage 4", int(stages.get_current_stage()) == 4)
	_ok("manual city 3", int(world.get_city_stage()) == 3)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var meet_sonya: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_SONYA))
	_ok("manual meet sonya early", meet_sonya.success)
	_max_girl(girls, GirlCatalog.ID_SONYA)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_nika: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_NIKA))
	_ok("manual meet nika", meet_nika.success)
	_max_girl(girls, GirlCatalog.ID_NIKA)
	_ok("manual rating 10", int(rating.get_rating()) == 10)
	world.enter_location(LocationCatalog.ID_CITY_CENTER)
	var meet_scientist: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_SCIENTIST))
	_ok("manual meet scientist", meet_scientist.success)
	_ok("manual defeat academic", rivals.defeat_rival(RivalCatalog.ID_ACADEMIC))
	_max_girl(girls, GirlCatalog.ID_SCIENTIST)
	_ok("manual stage 5", int(stages.get_current_stage()) == 5)
	_ok("manual factory", bool(automation.is_unlocked()))
	_ok("manual rating 11", int(rating.get_rating()) == 11)


func _test_manual_progression_sonya_path() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var rivals: Variant = _rivals_service()
	var rating: Variant = _rating_service()
	var dating: Variant = _dating_service()
	var automation: Variant = _automation_service()
	var actions: Variant = _action_service()
	_ok("sonya path services", gs != null and sm != null and stages != null and world != null and girls != null and rivals != null and rating != null and dating != null and automation != null and actions != null)
	if gs == null or sm == null or stages == null or world == null or girls == null or rivals == null or rating == null or dating == null or automation == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/manual_sonya_path.json"
	sm.delete_save()
	_advance_manual_path_to_scientist(gs, sm, stages, world, girls, rivals, rating, dating, automation, actions)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_vika: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_VIKA))
	_ok("sonya path meet vika", meet_vika.success)
	_max_girl(girls, GirlCatalog.ID_VIKA)
	world.enter_location(LocationCatalog.ID_CAFE)
	var meet_dasha: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_DASHA))
	_ok("sonya path meet dasha", meet_dasha.success)
	_max_girl(girls, GirlCatalog.ID_DASHA)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var meet_rita: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_RITA))
	_ok("sonya path meet rita", meet_rita.success)
	_max_girl(girls, GirlCatalog.ID_RITA)
	_ok("sonya path rating 14", int(rating.get_rating()) == 14)
	_ok("sonya path keeps stage 5", int(stages.get_current_stage()) == 5)
	_assert_coverage(girls, "sonya path before president", 14, 17)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	var meet_president: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_PRESIDENT))
	_ok("sonya path meet president", meet_president.success)
	_ok("sonya path defeat minister", rivals.defeat_rival(RivalCatalog.ID_MINISTER))
	_max_girl(girls, GirlCatalog.ID_PRESIDENT)
	_ok("sonya path stage 6", int(stages.get_current_stage()) == 6)
	_assert_coverage(girls, "sonya path fifteen of seventeen", 15, 17)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_manual_progression_factory_rating_path() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var stages: Variant = _stage_service()
	var world: Variant = _world_service()
	var girls: Variant = _girls_service()
	var rivals: Variant = _rivals_service()
	var rating: Variant = _rating_service()
	var dating: Variant = _dating_service()
	var automation: Variant = _automation_service()
	var actions: Variant = _action_service()
	_ok("factory path services", gs != null and sm != null and stages != null and world != null and girls != null and rivals != null and rating != null and dating != null and automation != null and actions != null)
	if gs == null or sm == null or stages == null or world == null or girls == null or rivals == null or rating == null or dating == null or automation == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/manual_factory_rating_path.json"
	sm.delete_save()
	_advance_manual_path_to_scientist(gs, sm, stages, world, girls, rivals, rating, dating, automation, actions)
	_assert_coverage(girls, "factory path skip remaining fillers", 11, 17)
	world.enter_location(LocationCatalog.ID_RESTAURANT)
	_ok("factory path president blocked", girls.can_meet_girl(GirlCatalog.ID_PRESIDENT) == false)
	rating.add_rating(1)
	_ok("factory path rating 12", int(rating.get_rating()) == 12)
	_assert_coverage(girls, "factory path still 11 of 17", 11, 17)
	var meet_president: ActionResult = actions.execute(girls.create_meet_girl_action(GirlCatalog.ID_PRESIDENT))
	_ok("factory path meet president", meet_president.success)
	_ok("factory path defeat minister", rivals.defeat_rival(RivalCatalog.ID_MINISTER))
	_max_girl(girls, GirlCatalog.ID_PRESIDENT)
	_ok("factory path stage 6", int(stages.get_current_stage()) == 6)
	_assert_coverage(girls, "factory path twelve of seventeen", 12, 17)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()


func _test_skip_to_08_00() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var world: Variant = _world_service()
	var actions: Variant = _action_service()
	_ok("skip GameState", gs != null)
	_ok("skip SaveManager", sm != null)
	_ok("skip TimeService", clock != null)
	_ok("skip WorldService", world != null)
	_ok("skip ActionService", actions != null)
	if gs == null or sm == null or clock == null or world == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/skip_to_08_00.json"
	sm.delete_save()
	sm.new_game()
	gs.flow.game_time_minutes = 0
	var test_wait: ActionResult = actions.execute(GameActionCatalog.make_test_wait())
	_ok("test_wait success", test_wait.success)
	_ok("test_wait +120", int(clock.get_game_time_minutes()) == 120)
	_ok("03:20 calc", int(clock.minutes_until_next_morning(3 * 60 + 20)) == 280)
	_ok("07:59 calc", int(clock.minutes_until_next_morning(7 * 60 + 59)) == 1)
	_ok("08:00 calc", int(clock.minutes_until_next_morning(8 * 60)) == 1440)
	_ok("23:30 calc", int(clock.minutes_until_next_morning(23 * 60 + 30)) == 510)
	sm.new_game()
	world.enter_location(LocationCatalog.ID_APARTMENT)
	gs.player.money = 40
	_assert_skip_to_08_00(gs, clock, actions, "03:20", 3 * 60 + 20, 280, 1)
	_assert_skip_to_08_00(gs, clock, actions, "07:59", 7 * 60 + 59, 1, 1)
	_assert_skip_to_08_00(gs, clock, actions, "08:00", 8 * 60, 1440, 2)
	_assert_skip_to_08_00(gs, clock, actions, "23:30", 23 * 60 + 30, 510, 2)
	_ok("skip money unchanged", int(gs.player.money) == 40)
	_ok("skip label", GameActionLabels.for_id(GameActionCatalog.ID_SKIP_TO_08_00) == GameActionLabels.LABEL_SKIP_TO_08_00)
	_ok("skip not test label", GameActionLabels.for_id(GameActionCatalog.ID_SKIP_TO_08_00) != GameActionLabels.for_id(GameActionCatalog.ID_TEST_WAIT))
	_ok("skip not TEST_WAIT", GameActionLabels.for_id(GameActionCatalog.ID_SKIP_TO_08_00).contains("TEST_WAIT") == false)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()

func _write_v10_automation_save(sm: Variant, stage: int) -> void:
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	if file == null:
		return
	var payload: Dictionary = {
		"save_version": 10,
		"game_state": {
			"flow": {"game_time_minutes": 0},
			"story": {"stage": stage, "finale_reached": false},
			"player": {"money": 0, "rating": 0},
			"progression": {"purchased_ids": []},
			"world": {
				"current_location_id": String(LocationCatalog.START_LOCATION_ID),
				"unlocked_location_ids": ["city_center", "apartment", "cafe"],
			},
			"girls": {"girls_by_id": {}},
			"dating": {"active_date": {}},
			"rivals": {"rivals_by_id": {}},
			"automation": {},
		},
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func _write_v12_apartment_save(sm: Variant, include_prepared: bool, owned_local_object_ids: Array) -> void:
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	if file == null:
		return
	var apartment: Dictionary = {
		"owned_local_object_ids": owned_local_object_ids.duplicate(),
	}
	if include_prepared:
		apartment["prepared"] = true
	var payload: Dictionary = {
		"save_version": 12,
		"game_state": {
			"flow": {"game_time_minutes": 0},
			"story": {"stage": 1, "finale_reached": false},
			"player": {"money": 0, "rating": 0},
			"progression": {
				"purchased_ids": [],
				"apartment": apartment,
			},
			"world": {
				"current_location_id": String(LocationCatalog.START_LOCATION_ID),
				"unlocked_location_ids": ["city_center", "apartment", "cafe"],
			},
			"girls": {"girls_by_id": {}},
			"dating": {"active_date": {}},
			"rivals": {"rivals_by_id": {}},
			"automation": {
				"unlocked": false,
				"initial_clones_granted": false,
				"total_clones": 0,
				"work_allocation_percent": 50,
				"work_income_fraction": 0,
				"dating_progress_fraction": 0,
				"completed_auto_dates": 0,
				"purchased_upgrade_ids": [],
			},
		},
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _write_v11_factory_rating_save(sm: Variant, rating: int, completed_auto_dates: int, dating_fraction: float) -> void:
	sm.delete_save()
	var folder: String = sm.save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file: FileAccess = FileAccess.open(sm.save_path, FileAccess.WRITE)
	if file == null:
		return
	var payload: Dictionary = {
		"save_version": 11,
		"game_state": {
			"flow": {"game_time_minutes": 0},
			"story": {"stage": 5, "finale_reached": false},
			"player": {"money": 0, "rating": rating},
			"progression": {"purchased_ids": []},
			"world": {
				"current_location_id": String(LocationCatalog.START_LOCATION_ID),
				"unlocked_location_ids": ["city_center", "apartment", "cafe"],
			},
			"girls": {"girls_by_id": {}},
			"dating": {"active_date": {}},
			"rivals": {"rivals_by_id": {}},
			"automation": {
				"unlocked": true,
				"initial_clones_granted": true,
				"total_clones": 10,
				"work_allocation_percent": 50,
				"work_income_fraction": 0,
				"dating_progress_fraction": dating_fraction,
				"completed_auto_dates": completed_auto_dates,
				"purchased_upgrade_ids": [],
			},
		},
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _test_availability_ui() -> void:
	var unknown: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN
	var bbcode: String = LabUi.tag_bbcode("Юмор", unknown, true)
	_ok("tag_bbcode has no lock", not bbcode.contains("🔒"))
	var label: Control = LabUi.tag_label("Юмор", unknown, true)
	_ok("tag_label has no lock", label != null and not str(label.get("text")).contains("🔒"))
	var panel := DatePlayPanel.new()
	var service := DateCatalogService.new()
	service.catalog = _catalog()
	panel.catalog_service = service
	var option := DateMoveOption.new()
	option.requirement_stat_id = &"muscle"
	option.requirement_level = 2
	option.current_stat_level = 0
	option.availability = DateTypes.MoveAvailability.LOCKED
	var required_text: String = panel._requirement_reason(option)
	_ok("requirement text Требуется", required_text.contains("Требуется:"))
	option.availability = DateTypes.MoveAvailability.USED
	var used_btn: Button = panel._move_button(option)
	var used_ok: bool = false
	if used_btn != null:
		for child in used_btn.get_children():
			if child is RichTextLabel and String(child.text).contains("Использовано"):
				used_ok = true
				break
	_ok("used text Использовано", used_ok)
	panel.free()


func _test_playtest_daily_activity() -> void:
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	var clock: Variant = _time_service()
	var daily: Variant = _daily_activity()
	var dating: Variant = _dating_service()
	var girls: Variant = _girls_service()
	var characteristics: Variant = _characteristic_service()
	var equipment: Variant = _equipment_service()
	var actions: Variant = _action_service()
	var catalog: DateContentCatalog = _catalog()
	_ok("daily autoload", daily != null and gs != null and sm != null and clock != null)
	if daily == null or gs == null or sm == null or clock == null or dating == null or girls == null or characteristics == null or equipment == null or actions == null:
		return
	var original_path: String = sm.save_path
	sm.save_path = "user://saves/playtest_daily_activity.json"
	sm.delete_save()
	clock.real_time_progression_enabled = false
	sm.new_game()
	_ok("alina wide 8", catalog.find_girl(&"alina").positive_tag_ids.size() == 8)
	_ok("marina easy 7", catalog.find_girl(&"marina").positive_tag_ids.size() == 7)
	_ok("vika easy 7", catalog.find_girl(&"vika").positive_tag_ids.size() == 7)
	_ok("dasha starter 6", catalog.find_girl(&"dasha").positive_tag_ids.size() == 6)
	_ok("actress max 10", GirlCatalog.seed_relationship_max(GirlCatalog.ID_ACTRESS) == 10)
	_ok("mine boss max 10", GirlCatalog.seed_relationship_max(GirlCatalog.ID_MINE_BOSS) == 10)
	_ok("editor max 10", GirlCatalog.seed_relationship_max(GirlCatalog.ID_MAGAZINE_EDITOR) == 10)
	_ok("scientist max 15", GirlCatalog.seed_relationship_max(GirlCatalog.ID_SCIENTIST) == 15)
	_ok("president max 15", GirlCatalog.seed_relationship_max(GirlCatalog.ID_PRESIDENT) == 15)
	girls.give_contact(GirlCatalog.ID_ALINA)
	girls.give_contact(GirlCatalog.ID_MARINA)
	_ok("date available first", dating.can_start_date(GirlCatalog.ID_ALINA))
	_ok("start date registers", dating.start_date(GirlCatalog.ID_ALINA, &"apartment"))
	_ok("same girl blocked", dating.can_start_date(GirlCatalog.ID_ALINA) == false)
	_ok("other girl daily free", dating.is_free_date_available_today(GirlCatalog.ID_MARINA))
	var date_result := DateResult.new()
	date_result.girl_id = GirlCatalog.ID_ALINA
	date_result.relationship_delta = 0
	date_result.duration_minutes = 120
	dating.complete_date(date_result)
	clock.advance_time(1440)
	_ok("next day date free", dating.can_start_date(GirlCatalog.ID_ALINA))
	sm.new_game()
	gs.player.money = 300
	_ok("train 1 ok", actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1)).success)
	_ok("train 2 blocked", actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1)).success == false)
	clock.advance_time(1440)
	gs.player.money = 300
	_ok("train next day", actions.execute(characteristics.create_upgrade_action(CharacteristicCatalog.ID_MUSCLE_1)).success)
	sm.new_game()
	gs.story.stage = 2
	girls.grant_filler_reward_for_girl(GirlCatalog.ID_MARINA)
	_ok("marina pending", girls.is_marina_free_outfit_pending())
	var gift: GameAction = equipment.create_buy_outfit_action(OutfitCatalog.ID_BUSINESS)
	_ok("marina shop price 0", gift.money_cost == 0)
	gs.player.money = 0
	_ok("marina buy 0", actions.execute(gift).success)
	_ok("marina pending cleared", girls.is_marina_free_outfit_pending() == false)
	var progress := GirlProgress.new()
	var alina: GirlProfile = catalog.find_girl(&"alina")
	progress.reset_to_profile(alina)
	for tag_id in alina.positive_tag_ids:
		progress.reveal_tag(tag_id, true, alina, catalog)
	_ok("deduce negatives", progress.unknown_tag_count(alina, catalog) == 0)
	_ok("all remaining negative", progress.unknown_negative_tag_count(alina, catalog) == 0)
	sm.delete_save()
	sm.save_path = original_path
	sm.new_game()
