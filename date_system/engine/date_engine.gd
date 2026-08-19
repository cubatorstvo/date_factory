class_name DateEngine
extends RefCounted

signal date_started
signal episode_started
signal move_selected(move_id: StringName)
signal tag_revealed(tag_id: StringName, knowledge: DateTypes.TagKnowledge)
signal relationship_changed(girl_id: StringName, value: int)
signal secondary_revealed(girl_id: StringName)
signal date_completed
signal relationship_max_reached(girl_id: StringName)

var _catalog: DateContentCatalog
var _session: DateSession
var _girl: GirlProfile
var _location: DateLocation
var _outfit: Outfit
var _girl_progress: GirlProgress
var _player: TestPlayerState
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _evaluators: SecondaryEvaluatorRegistry = SecondaryEvaluatorRegistry.new()
var _last_result: DateRunResult
var _relationship_max_emitted: bool = false


func create_date_session(config: DateSessionConfig) -> DateSession:
	assert(config != null)
	assert(config.catalog != null)
	_catalog = config.catalog.snapshot()
	_girl = _catalog.find_girl(config.girl_id)
	_location = _catalog.find_location(config.location_id)
	_outfit = _catalog.find_outfit(config.outfit_id)
	_girl_progress = config.girl_progress
	_player = config.player_state
	_last_result = null
	_relationship_max_emitted = false
	assert(_girl != null)
	assert(_location != null)
	assert(_outfit != null)
	assert(_girl_progress != null)
	assert(_player != null)
	assert(_catalog.date_rules != null)

	_session = DateSession.new()
	_session.seed = config.seed
	_session.session_id = "%d-%d" % [config.seed, Time.get_ticks_msec()]
	_session.girl_id = config.girl_id
	_session.location_id = config.location_id
	_session.outfit_id = config.outfit_id
	_session.relationship_before = _girl_progress.relationship
	_session.relationship_after = _girl_progress.relationship
	_session.score_breakdown = DateScoreBreakdown.new()
	_session.used_unlockable_move_counts = {}
	_session.secondary_runtime_state = _initial_secondary_state()
	_rng.seed = config.seed
	_session.current_episode_index = 0
	_begin_episode()
	date_started.emit()
	return _session


func get_session_state() -> DateSession:
	return _session


func get_current_episode() -> DateEpisodeView:
	if _session == null:
		return null
	if _session.stage == DateSession.Stage.COMPLETED or _session.stage == DateSession.Stage.ABORTED:
		return null
	if _session.current_episode_index >= _catalog.date_rules.total_episode_count():
		return null
	var view := DateEpisodeView.new()
	view.phase = _session.current_phase
	view.episode_index = _session.current_episode_index
	view.index_in_phase = _catalog.date_rules.index_in_phase(_session.current_episode_index)
	if not _session.selected_situation_ids.is_empty() and _session.current_episode_index < _session.selected_situation_ids.size():
		view.situation = _catalog.find_situation(_session.selected_situation_ids[_session.current_episode_index])
	view.base_options = _build_options(_session.current_selected_base_move_ids, DateTypes.DateMoveKind.BASE)
	view.unlockable_options = _build_options(_session.current_applicable_unlockable_move_ids, DateTypes.DateMoveKind.UNLOCKABLE)
	return view


func get_available_moves() -> Array[DateMoveOption]:
	var view := get_current_episode()
	var result: Array[DateMoveOption] = []
	if view == null:
		return result
	result.append_array(view.base_options)
	result.append_array(view.unlockable_options)
	return result


func choose_move(move_id: StringName) -> void:
	if _session == null or _session.stage != DateSession.Stage.AWAITING_MOVE:
		return
	var option := _find_option(move_id)
	if option == null or not option.is_selectable():
		return
	var situation_id: StringName = _session.selected_situation_ids[_session.current_episode_index]
	var move: DateMove = _catalog.find_move(move_id)
	var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
	var tag_id: StringName = mapping.tag_id
	var preference: int = _girl.prefers_tag(tag_id)
	var score: int = _score_for_phase(_session.current_phase, preference)
	var revealed: bool = false
	if _catalog.date_rules.reveal_tag_after_use:
		revealed = _girl_progress.reveal_tag(tag_id, preference > 0)
		if revealed:
			_session.revealed_tags_during_session.append(tag_id)
			var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.POSITIVE if preference > 0 else DateTypes.TagKnowledge.NEGATIVE
			tag_revealed.emit(tag_id, knowledge)

	if move.kind == DateTypes.DateMoveKind.UNLOCKABLE:
		var used: int = int(_session.used_unlockable_move_counts.get(String(move_id), 0))
		_session.used_unlockable_move_counts[String(move_id)] = used + 1

	var episode := DateEpisodeResult.new()
	episode.phase = _session.current_phase
	episode.episode_index = _session.current_episode_index
	episode.situation_id = situation_id
	episode.move_id = move_id
	episode.tag_id = tag_id
	episode.tag_preference = preference
	episode.score_delta = score
	episode.revealed_tag = revealed
	if preference > 0:
		episode.result_text = mapping.positive_result_text
	else:
		episode.result_text = mapping.negative_result_text

	_session.episode_history.append(episode)
	_session.current_selected_move_id = move_id
	_session.current_resolved_tag_id = tag_id
	_session.current_tag_preference = preference
	_session.current_score_delta = score
	_session.current_result_text = episode.result_text
	_append_episode_score(episode)
	_update_secondary(episode)
	_session.stage = DateSession.Stage.SHOWING_EPISODE_RESULT
	move_selected.emit(move_id)


func advance() -> void:
	if _session == null:
		return
	if _session.stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		_session.current_episode_index += 1
		if _session.current_episode_index >= _catalog.date_rules.total_episode_count():
			_finish_date()
		else:
			_begin_episode()
		return
	if _session.stage == DateSession.Stage.SHOWING_DATE_RESULT:
		_session.stage = DateSession.Stage.COMPLETED
		_session.completed = true


func get_result() -> DateRunResult:
	return _last_result


func abort() -> void:
	if _session == null:
		return
	_session.stage = DateSession.Stage.ABORTED
	_session.completed = false


func secondary_live_text() -> String:
	var rule: SecondaryRule = _catalog.find_secondary(_girl.secondary_rule_id)
	var evaluator: SecondaryEvaluator = _evaluators.get_evaluator(rule.condition_type)
	if evaluator == null:
		return ""
	return evaluator.live_text(_session.secondary_runtime_state, rule, _catalog.date_rules)


func catalog() -> DateContentCatalog:
	return _catalog


func girl_progress() -> GirlProgress:
	return _girl_progress


func _begin_episode() -> void:
	var rules: DateRules = _catalog.date_rules
	_session.current_phase = rules.phase_for_episode_index(_session.current_episode_index)
	var situation: DateSituation = _pick_situation(_session.current_phase)
	_session.selected_situation_ids.append(situation.id)
	var base_pool: Array[DateMove] = _catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE)
	_session.current_candidate_base_move_ids = _ids_of(base_pool)
	var selected: Array[DateMove] = _pick_base_moves(base_pool, rules.base_moves_per_episode)
	_session.current_selected_base_move_ids = _ids_of(selected)
	var unlockables: Array[DateMove] = _catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.UNLOCKABLE)
	if not rules.show_locked_unlockable_moves:
		var visible: Array[DateMove] = []
		for move in unlockables:
			if _unlockable_availability(move) != DateTypes.MoveAvailability.LOCKED:
				visible.append(move)
		unlockables = visible
	_session.current_applicable_unlockable_move_ids = _ids_of(unlockables)
	_session.current_selected_move_id = &""
	_session.current_resolved_tag_id = &""
	_session.current_tag_preference = 0
	_session.current_score_delta = 0
	_session.current_result_text = ""
	_session.stage = DateSession.Stage.AWAITING_MOVE
	episode_started.emit()


func _pick_situation(phase: DateTypes.DatePhase) -> DateSituation:
	var pool: Array[DateSituation] = []
	var weights: Array[float] = []
	for situation in _catalog.enabled_situations():
		if not situation.allows_phase(phase):
			continue
		if not _catalog.date_rules.allow_situation_repeats and _session.selected_situation_ids.has(situation.id):
			continue
		pool.append(situation)
		weights.append(situation.weight)
	assert(not pool.is_empty())
	return pool[_weighted_index(weights)]


func _pick_base_moves(pool: Array[DateMove], count: int) -> Array[DateMove]:
	var copy: Array[DateMove] = pool.duplicate()
	_shuffle_moves(copy)
	var selected: Array[DateMove] = []
	var take: int = mini(count, copy.size())
	for i in take:
		selected.append(copy[i])
	return selected


func _shuffle_moves(items: Array[DateMove]) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: DateMove = items[i]
		items[i] = items[j]
		items[j] = tmp


func _weighted_index(weights: Array[float]) -> int:
	var total: float = 0.0
	for weight in weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return _rng.randi_range(0, weights.size() - 1)
	var roll: float = _rng.randf() * total
	var cursor: float = 0.0
	for i in weights.size():
		cursor += maxf(weights[i], 0.0)
		if roll <= cursor:
			return i
	return weights.size() - 1


func _build_options(move_ids: Array[StringName], kind: DateTypes.DateMoveKind) -> Array[DateMoveOption]:
	var options: Array[DateMoveOption] = []
	if _session.selected_situation_ids.is_empty() or _session.current_episode_index >= _session.selected_situation_ids.size():
		return options
	var situation_id: StringName = _session.selected_situation_ids[_session.current_episode_index]
	for move_id in move_ids:
		var move: DateMove = _catalog.find_move(move_id)
		if move == null:
			continue
		var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
		if mapping == null:
			continue
		var option := DateMoveOption.new()
		option.move_id = move.id
		option.display_name = move.display_name
		option.kind = kind
		option.option_text = mapping.option_text
		option.tag_id = mapping.tag_id
		var tag: DateTag = _catalog.find_tag(mapping.tag_id)
		option.tag_display_name = tag.display_name if tag != null else String(mapping.tag_id)
		option.tag_knowledge = _girl_progress.tag_knowledge(mapping.tag_id)
		if kind == DateTypes.DateMoveKind.UNLOCKABLE:
			option.availability = _unlockable_availability(move)
			if move.unlock_requirement != null:
				option.requirement_stat_id = move.unlock_requirement.stat_id
				option.requirement_level = move.unlock_requirement.required_level
				option.current_stat_level = _player.get_stat(move.unlock_requirement.stat_id)
			option.uses_max = move.max_uses_per_date
			option.uses_used = int(_session.used_unlockable_move_counts.get(String(move.id), 0))
		else:
			option.availability = DateTypes.MoveAvailability.AVAILABLE
		options.append(option)
	return options


func _unlockable_availability(move: DateMove) -> DateTypes.MoveAvailability:
	var used: int = int(_session.used_unlockable_move_counts.get(String(move.id), 0))
	if not move.is_unlimited() and used >= move.max_uses_per_date:
		return DateTypes.MoveAvailability.USED
	if move.unlock_requirement != null:
		var current: int = _player.get_stat(move.unlock_requirement.stat_id)
		if current < move.unlock_requirement.required_level:
			return DateTypes.MoveAvailability.LOCKED
	return DateTypes.MoveAvailability.AVAILABLE


func _find_option(move_id: StringName) -> DateMoveOption:
	for option in get_available_moves():
		if option.move_id == move_id:
			return option
	return null


func _score_for_phase(phase: DateTypes.DatePhase, preference: int) -> int:
	var rules: DateRules = _catalog.date_rules
	match phase:
		DateTypes.DatePhase.OPENING:
			return rules.opening_choice_score
		DateTypes.DatePhase.CORE:
			return rules.core_positive_score if preference > 0 else rules.core_negative_score
		DateTypes.DatePhase.CLOSING:
			return rules.closing_positive_score if preference > 0 else rules.closing_negative_score
		_:
			return 0


func _append_episode_score(episode: DateEpisodeResult) -> void:
	match episode.phase:
		DateTypes.DatePhase.OPENING:
			_session.score_breakdown.opening_scores.append(episode.score_delta)
		DateTypes.DatePhase.CORE:
			_session.score_breakdown.core_scores.append(episode.score_delta)
		DateTypes.DatePhase.CLOSING:
			_session.score_breakdown.closing_scores.append(episode.score_delta)
	_session.score_breakdown.recompute()


func _initial_secondary_state() -> Dictionary:
	var rule: SecondaryRule = _catalog.find_secondary(_girl.secondary_rule_id)
	var evaluator: SecondaryEvaluator = _evaluators.get_evaluator(rule.condition_type)
	if evaluator == null:
		return {}
	return evaluator.initial_state(rule, _catalog.date_rules)


func _update_secondary(episode: DateEpisodeResult) -> void:
	var rule: SecondaryRule = _catalog.find_secondary(_girl.secondary_rule_id)
	var evaluator: SecondaryEvaluator = _evaluators.get_evaluator(rule.condition_type)
	if evaluator == null:
		return
	evaluator.on_episode(_session.secondary_runtime_state, episode, rule, _catalog.date_rules)


func _finish_date() -> void:
	var rules: DateRules = _catalog.date_rules
	var rule: SecondaryRule = _catalog.find_secondary(_girl.secondary_rule_id)
	var evaluator: SecondaryEvaluator = _evaluators.get_evaluator(rule.condition_type)
	var secondary_ok: bool = evaluator != null and evaluator.is_success(_session.secondary_runtime_state, rule, rules)
	_session.score_breakdown.secondary_success = secondary_ok
	_session.score_breakdown.secondary_score = rule.success_score if secondary_ok else rule.failure_score
	_session.score_breakdown.location_quality_score = _location_quality_score()
	_session.score_breakdown.location_preference_score = _location_preference_score()
	_session.score_breakdown.outfit_score = _outfit.score_bonus
	_session.score_breakdown.apartment_quality_score = _apartment_quality_score()
	_session.score_breakdown.apartment_preparation_score = _apartment_preparation_score()
	_session.score_breakdown.recompute()

	var next_rel: int = clampi(
		_session.relationship_before + _session.score_breakdown.total,
		_girl.relationship_min,
		_girl.relationship_max
	)
	_session.relationship_after = next_rel
	_girl_progress.relationship = next_rel
	relationship_changed.emit(_girl.id, next_rel)
	_girl_progress.completed_dates += 1
	if rules.reveal_secondary_after_first_completed_date and not _girl_progress.secondary_revealed:
		_girl_progress.secondary_revealed = true
		secondary_revealed.emit(_girl.id)

	var max_reached: bool = next_rel >= _girl.relationship_max and _session.relationship_before < _girl.relationship_max
	if max_reached:
		_relationship_max_emitted = true
		relationship_max_reached.emit(_girl.id)

	_session.stage = DateSession.Stage.SHOWING_DATE_RESULT
	_session.completed = true
	_last_result = DateRunResult.new()
	_last_result.session = _session
	_last_result.girl_progress = _girl_progress
	_last_result.score_breakdown = _session.score_breakdown
	_last_result.secondary_rule = rule
	_last_result.secondary_live_text = evaluator.live_text(_session.secondary_runtime_state, rule, rules) if evaluator != null else ""
	_last_result.relationship_max_reached = max_reached
	date_completed.emit()


func _location_quality_score() -> int:
	if _location.uses_apartment_quality:
		return 0
	return _location.base_quality_bonus


func _location_preference_score() -> int:
	if _location.preference_mode != DateTypes.LocationPreferenceMode.THEMATIC:
		return 0
	if _girl.favorite_location_format_ids.has(_location.location_format_id):
		return _catalog.date_rules.location_preference_success
	return _catalog.date_rules.location_preference_failure


func _apartment_quality_score() -> int:
	if not _location.uses_apartment_quality:
		return 0
	return clampi(_player.apartment_quality, _catalog.date_rules.apartment_quality_min, _catalog.date_rules.apartment_quality_max)


func _apartment_preparation_score() -> int:
	if not _location.uses_apartment_preparation:
		return 0
	if _player.apartment_prepared:
		return 0
	return _catalog.date_rules.apartment_unprepared_penalty


func _ids_of(moves: Array[DateMove]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for move in moves:
		ids.append(move.id)
	return ids
