class_name DateEngine
extends RefCounted

signal date_started
signal episode_started
signal move_selected(move_id: StringName)
signal tag_revealed(tag_id: StringName, knowledge: DateTypes.TagKnowledge)
signal relationship_changed(girl_id: StringName, value: int)
signal combo_achieved
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
	_session.relationship_max = config.relationship_max
	_session.girl_trait_applied = false
	_session.score_breakdown = DateScoreBreakdown.new()
	var girl_trait: GirlTrait = _catalog.find_trait(_girl.trait_id)
	if girl_trait != null:
		_session.score_breakdown.girl_trait_display_name = girl_trait.display_name
	_session.used_unlockable_move_counts = {}
	_session.local_object_ids = config.local_object_ids.duplicate()
	_session.used_local_object_ids = []
	_session.used_base_move_ids = []
	_session.characteristic_source_used = false
	_session.outfit_source_used = false
	_session.location_source_used = false
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
	view.source_views = _build_source_views()
	for source_view in view.source_views:
		if source_view.source == DateTypes.DateMoveSource.CHARACTERISTIC:
			view.unlockable_options = source_view.options
	view.local_object_views = _build_local_object_views()
	return view


func get_available_moves() -> Array[DateMoveOption]:
	var view := get_current_episode()
	var result: Array[DateMoveOption] = []
	if view == null:
		return result
	result.append_array(view.base_options)
	for source_view in view.source_views:
		result.append_array(source_view.options)
	return result


func choose_move(move_id: StringName) -> void:
	if _session == null or _session.stage != DateSession.Stage.AWAITING_MOVE:
		return
	var option := _find_option(move_id)
	if option == null or not option.is_selectable():
		return
	var situation_id: StringName = _session.selected_situation_ids[_session.current_episode_index]
	var move: DateMove = _catalog.find_move(move_id)
	var tag_id: StringName = move.resolved_tag_id(situation_id)
	var preference: int = _girl.prefers_tag(tag_id)
	var score: int = _score_for_phase(_session.current_phase, preference)
	var revealed: bool = false
	if _catalog.date_rules.reveal_tag_after_use:
		revealed = _girl_progress.reveal_tag(tag_id, preference > 0, _girl)
		if revealed:
			_session.revealed_tags_during_session.append(tag_id)
			var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.POSITIVE if preference > 0 else DateTypes.TagKnowledge.NEGATIVE
			tag_revealed.emit(tag_id, knowledge)

	if move.kind == DateTypes.DateMoveKind.BASE:
		if not _session.used_base_move_ids.has(move_id):
			_session.used_base_move_ids.append(move_id)
	elif move.is_characteristic():
		_session.characteristic_source_used = true
		_session.used_unlockable_move_counts[String(move_id)] = 1
	elif move.is_outfit_move():
		_session.outfit_source_used = true
	elif move.is_local():
		_session.location_source_used = true
		var object_id: StringName = option.local_object_id
		if object_id == &"":
			var local_object: DateLocalObject = _catalog.find_local_object_for_move(move_id)
			if local_object != null:
				object_id = local_object.id
		if object_id != &"" and not _session.used_local_object_ids.has(object_id):
			_session.used_local_object_ids.append(object_id)

	var episode := DateEpisodeResult.new()
	episode.phase = _session.current_phase
	episode.episode_index = _session.current_episode_index
	episode.situation_id = situation_id
	episode.move_id = move_id
	episode.tag_id = tag_id
	episode.tag_preference = preference
	episode.score_delta = score
	episode.revealed_tag = revealed
	episode.result_text = move.resolved_result_text(situation_id, preference > 0)
	_apply_characteristic_trait(episode, move)

	_session.episode_history.append(episode)
	_session.current_selected_move_id = move_id
	_session.current_resolved_tag_id = tag_id
	_session.current_tag_preference = preference
	_session.current_score_delta = score
	_session.current_result_text = episode.result_text
	_append_episode_score(episode)
	_update_combo(episode)
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


func catalog() -> DateContentCatalog:
	return _catalog


func girl_progress() -> GirlProgress:
	return _girl_progress


func player_state() -> TestPlayerState:
	return _player


func _begin_episode() -> void:
	var rules: DateRules = _catalog.date_rules
	_session.current_phase = rules.phase_for_episode_index(_session.current_episode_index)
	var situation: DateSituation = _pick_situation(_session.current_phase)
	_session.selected_situation_ids.append(situation.id)
	var characteristic_moves: Array[DateMove] = _catalog.characteristic_moves()
	_session.current_applicable_unlockable_move_ids = _ids_of(characteristic_moves)
	var available_unlockables: Array[DateMove] = []
	var locked_unlockables: Array[DateMove] = []
	var used_unlockables: Array[DateMove] = []
	for move in characteristic_moves:
		var state: DateTypes.MoveAvailability = _move_availability(move)
		match state:
			DateTypes.MoveAvailability.AVAILABLE:
				available_unlockables.append(move)
			DateTypes.MoveAvailability.LOCKED:
				locked_unlockables.append(move)
			DateTypes.MoveAvailability.USED:
				used_unlockables.append(move)
	_session.current_available_unlockable_move_ids = _ids_of(available_unlockables)
	_session.current_locked_unlockable_move_ids = _ids_of(locked_unlockables)
	_session.current_used_unlockable_move_ids = _ids_of(used_unlockables)
	_session.current_reserved_unlockable_tag_ids = []
	var base_pool: Array[DateMove] = _catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE)
	_session.current_candidate_base_move_ids = _ids_of(base_pool)
	var preferred: Array[DateMove] = []
	var fallback: Array[DateMove] = []
	for move in base_pool:
		if _session.used_base_move_ids.has(move.id):
			fallback.append(move)
		else:
			preferred.append(move)
	_session.current_preferred_base_move_ids = _ids_of(preferred)
	_session.current_fallback_base_move_ids = _ids_of(fallback)
	var selected: Array[DateMove] = _pick_base_moves(preferred, fallback, rules.base_moves_per_episode, situation.id)
	_session.current_selected_base_move_ids = _ids_of(selected)
	_session.current_selected_base_tag_ids = _tags_of(selected, situation.id)
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


func _pick_base_moves(preferred: Array[DateMove], fallback: Array[DateMove], count: int, situation_id: StringName) -> Array[DateMove]:
	var selected: Array[DateMove] = []
	var preferred_copy: Array[DateMove] = preferred.duplicate()
	var fallback_copy: Array[DateMove] = fallback.duplicate()
	_take_unique_then_rest(selected, preferred_copy, count, situation_id)
	_take_unique_then_rest(selected, fallback_copy, count, situation_id)
	return selected


func _take_unique_then_rest(selected: Array[DateMove], pool: Array[DateMove], count: int, situation_id: StringName) -> void:
	_take_from_pool(selected, pool, count, situation_id, true)
	_take_from_pool(selected, pool, count, situation_id, false)


func _take_from_pool(selected: Array[DateMove], pool: Array[DateMove], count: int, situation_id: StringName, unique_only: bool) -> void:
	while selected.size() < count:
		var candidates: Array[DateMove] = []
		var selected_tags: Dictionary = _selected_tag_set(selected, situation_id)
		for move in pool:
			if unique_only and selected_tags.has(_move_tag(move, situation_id)):
				continue
			candidates.append(move)
		if candidates.is_empty():
			break
		var picked: DateMove = candidates[_rng.randi_range(0, candidates.size() - 1)]
		selected.append(picked)
		pool.erase(picked)


func _selected_tag_set(selected: Array[DateMove], situation_id: StringName) -> Dictionary:
	var tags: Dictionary = {}
	for move in selected:
		tags[_move_tag(move, situation_id)] = true
	return tags


func _move_tag(move: DateMove, situation_id: StringName) -> StringName:
	return move.resolved_tag_id(situation_id)


func _tags_of(moves: Array[DateMove], situation_id: StringName) -> Array[StringName]:
	var tags: Array[StringName] = []
	for move in moves:
		tags.append(_move_tag(move, situation_id))
	return tags


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
	var situation_id: StringName = &""
	if not _session.selected_situation_ids.is_empty() and _session.current_episode_index < _session.selected_situation_ids.size():
		situation_id = _session.selected_situation_ids[_session.current_episode_index]
	for move_id in move_ids:
		var option: DateMoveOption = _build_option(move_id, kind, situation_id, &"", "")
		if option != null:
			options.append(option)
	return options


func _build_option(
	move_id: StringName,
	kind: DateTypes.DateMoveKind,
	situation_id: StringName,
	local_object_id: StringName,
	local_object_display_name: String
) -> DateMoveOption:
	var move: DateMove = _catalog.find_move(move_id)
	if move == null:
		return null
	var tag_id: StringName = move.resolved_tag_id(situation_id)
	if tag_id == &"":
		return null
	var option := DateMoveOption.new()
	option.move_id = move.id
	option.display_name = move.display_name
	option.kind = kind
	option.option_text = move.resolved_option_text(situation_id)
	option.tag_id = tag_id
	var tag: DateTag = _catalog.find_tag(tag_id)
	option.tag_display_name = tag.display_name if tag != null else String(tag_id)
	option.tag_knowledge = _girl_progress.tag_knowledge(tag_id, _girl)
	option.local_object_id = local_object_id
	option.local_object_display_name = local_object_display_name
	option.availability = DateTypes.MoveAvailability.AVAILABLE if kind == DateTypes.DateMoveKind.BASE else _move_availability(move)
	if move.unlock_requirement != null:
		option.requirement_stat_id = move.unlock_requirement.stat_id
		option.requirement_level = move.unlock_requirement.required_level
		option.current_base_stat_level = _base_stat(move.unlock_requirement.stat_id)
		option.outfit_stat_bonus = _outfit_bonus(move.unlock_requirement.stat_id)
		option.current_stat_level = _effective_stat(move.unlock_requirement.stat_id)
	return option


func _move_availability(move: DateMove) -> DateTypes.MoveAvailability:
	if move.is_characteristic() and _session.characteristic_source_used:
		return DateTypes.MoveAvailability.USED
	if move.is_outfit_move() and _session.outfit_source_used:
		return DateTypes.MoveAvailability.USED
	if move.is_local() and _session.location_source_used:
		return DateTypes.MoveAvailability.USED
	if move.unlock_requirement != null:
		var current: int = _effective_stat(move.unlock_requirement.stat_id)
		if current < move.unlock_requirement.required_level:
			return DateTypes.MoveAvailability.LOCKED
	return DateTypes.MoveAvailability.AVAILABLE


func _build_source_views() -> Array[DateMoveSourceView]:
	var views: Array[DateMoveSourceView] = []
	var characteristic_view: DateMoveSourceView = _build_characteristic_source()
	if characteristic_view != null:
		views.append(characteristic_view)
	var outfit_view: DateMoveSourceView = _build_outfit_source()
	if outfit_view != null:
		views.append(outfit_view)
	var location_view: DateMoveSourceView = _build_location_source()
	if location_view != null:
		views.append(location_view)
	return views


func _build_characteristic_source() -> DateMoveSourceView:
	var moves: Array[DateMove] = _catalog.characteristic_moves()
	if moves.is_empty():
		return null
	var view := DateMoveSourceView.new()
	view.source = DateTypes.DateMoveSource.CHARACTERISTIC
	view.display_name = DateTypes.source_name(view.source)
	view.visible = true
	view.used = _session.characteristic_source_used
	var situation_id: StringName = _current_situation_id()
	var options: Array[DateMoveOption] = []
	for move in moves:
		var option: DateMoveOption = _build_option(move.id, DateTypes.DateMoveKind.UNLOCKABLE, situation_id, &"", "")
		if option != null:
			options.append(option)
	options.sort_custom(_sort_characteristic_options)
	view.options = options
	view.state = _source_state(options, view.used)
	return view


func _build_outfit_source() -> DateMoveSourceView:
	if _outfit == null or not _outfit.has_outfit_move():
		return null
	var move: DateMove = _catalog.find_move(_outfit.outfit_move_id)
	if move == null:
		return null
	var view := DateMoveSourceView.new()
	view.source = DateTypes.DateMoveSource.OUTFIT
	view.display_name = DateTypes.source_name(view.source)
	view.visible = true
	view.used = _session.outfit_source_used
	var option: DateMoveOption = _build_option(move.id, DateTypes.DateMoveKind.OUTFIT, _current_situation_id(), &"", "")
	if option != null:
		view.options.append(option)
	view.state = _source_state(view.options, view.used)
	return view


func _build_location_source() -> DateMoveSourceView:
	var options: Array[DateMoveOption] = []
	for object_id in _session.local_object_ids:
		var local_object: DateLocalObject = _catalog.find_local_object(object_id)
		if local_object == null or not local_object.enabled:
			continue
		for move_id in local_object.move_ids:
			var option: DateMoveOption = _build_option(
				move_id,
				DateTypes.DateMoveKind.LOCAL,
				_current_situation_id(),
				local_object.id,
				local_object.display_name
			)
			if option != null:
				options.append(option)
	if options.is_empty():
		return null
	var view := DateMoveSourceView.new()
	view.source = DateTypes.DateMoveSource.LOCATION
	view.display_name = DateTypes.source_name(view.source)
	view.visible = true
	view.used = _session.location_source_used
	view.options = options
	view.state = _source_state(options, view.used)
	return view


func _source_state(options: Array[DateMoveOption], used: bool) -> DateTypes.DateMoveSourceState:
	if used:
		return DateTypes.DateMoveSourceState.USED
	var has_positive: bool = false
	var has_unknown: bool = false
	var has_available: bool = false
	for option in options:
		if option.availability != DateTypes.MoveAvailability.AVAILABLE:
			continue
		has_available = true
		match option.tag_knowledge:
			DateTypes.TagKnowledge.POSITIVE:
				has_positive = true
			DateTypes.TagKnowledge.UNKNOWN:
				has_unknown = true
	if not has_available:
		return DateTypes.DateMoveSourceState.BLOCKED
	if has_positive:
		return DateTypes.DateMoveSourceState.POSITIVE
	if has_unknown:
		return DateTypes.DateMoveSourceState.UNKNOWN
	return DateTypes.DateMoveSourceState.NEGATIVE


func _sort_characteristic_options(a: DateMoveOption, b: DateMoveOption) -> bool:
	var a_group: int = _characteristic_option_group(a)
	var b_group: int = _characteristic_option_group(b)
	if a_group != b_group:
		return a_group < b_group
	var a_move: DateMove = _catalog.find_move(a.move_id)
	var b_move: DateMove = _catalog.find_move(b.move_id)
	return DateTypes.characteristic_sort_key(a_move) < DateTypes.characteristic_sort_key(b_move)


func _characteristic_option_group(option: DateMoveOption) -> int:
	if option.availability != DateTypes.MoveAvailability.AVAILABLE:
		return 3
	match option.tag_knowledge:
		DateTypes.TagKnowledge.POSITIVE:
			return 0
		DateTypes.TagKnowledge.UNKNOWN:
			return 1
		_:
			return 2


func _build_local_object_views() -> Array[DateLocalObjectView]:
	var views: Array[DateLocalObjectView] = []
	if _session == null:
		return views
	for object_id in _session.local_object_ids:
		var local_object: DateLocalObject = _catalog.find_local_object(object_id)
		if local_object == null or not local_object.enabled:
			continue
		var view := DateLocalObjectView.new()
		view.object_id = local_object.id
		view.display_name = local_object.display_name
		view.used = _session.location_source_used
		for move_id in local_object.move_ids:
			var option: DateMoveOption = _build_option(
				move_id,
				DateTypes.DateMoveKind.LOCAL,
				_current_situation_id(),
				local_object.id,
				local_object.display_name
			)
			if option != null:
				view.options.append(option)
		views.append(view)
	return views


func _current_situation_id() -> StringName:
	if _session == null or _session.selected_situation_ids.is_empty():
		return &""
	if _session.current_episode_index >= _session.selected_situation_ids.size():
		return &""
	return _session.selected_situation_ids[_session.current_episode_index]


func _base_stat(stat_id: StringName) -> int:
	return _player.get_stat(stat_id)


func _outfit_bonus(stat_id: StringName) -> int:
	if _outfit == null:
		return 0
	return _outfit.bonus_for(stat_id)


func _effective_stat(stat_id: StringName) -> int:
	return DateTypes.effective_stat(_base_stat(stat_id), _outfit, stat_id)


func _find_option(move_id: StringName) -> DateMoveOption:
	for option in get_available_moves():
		if option.move_id == move_id:
			return option
	return null


func _score_for_phase(phase: DateTypes.DatePhase, preference: int) -> int:
	var rules: DateRules = _catalog.date_rules
	match phase:
		DateTypes.DatePhase.OPENING:
			return rules.opening_positive_score if preference > 0 else rules.opening_negative_score
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


func _update_combo(episode: DateEpisodeResult) -> void:
	var rules: DateRules = _catalog.date_rules
	if episode.score_delta <= 0:
		_session.combo_distinct_success_tag_ids.clear()
		return
	var tag_id: StringName = episode.tag_id
	if tag_id == &"":
		return
	var chain: Array[StringName] = _session.combo_distinct_success_tag_ids
	var previous_index: int = chain.rfind(tag_id)
	if previous_index >= 0:
		var tail: Array[StringName] = []
		var seen: Dictionary = {}
		for i in range(previous_index + 1, chain.size()):
			var existing: StringName = chain[i]
			var key: String = String(existing)
			if seen.has(key):
				continue
			seen[key] = true
			tail.append(existing)
		_session.combo_distinct_success_tag_ids = tail
		chain = _session.combo_distinct_success_tag_ids
	chain.append(tag_id)
	if chain.size() < rules.combo_required_distinct_success_tags:
		return
	if _session.combo_rewards_earned >= rules.combo_max_rewards_per_date:
		return
	_session.score_breakdown.combo_score += rules.combo_bonus_score
	_session.combo_achieved = true
	_session.combo_rewards_earned += 1
	episode.combo_granted = true
	_session.score_breakdown.recompute()
	combo_achieved.emit()


func _finish_date() -> void:
	_apply_venue_trait()
	_session.score_breakdown.apartment_preparation_score = _apartment_preparation_score()
	_session.score_breakdown.recompute()

	var rel_max: int = maxi(0, _session.relationship_max)
	var next_rel: int = mini(_session.relationship_before + _session.score_breakdown.relationship_gain, rel_max)
	next_rel = maxi(next_rel, 0)
	_session.relationship_after = next_rel
	_girl_progress.relationship = next_rel
	relationship_changed.emit(_girl.id, next_rel)
	_girl_progress.completed_dates += 1

	var max_reached: bool = rel_max > 0 and next_rel >= rel_max and _session.relationship_before < rel_max
	if max_reached:
		_relationship_max_emitted = true
		relationship_max_reached.emit(_girl.id)

	_session.stage = DateSession.Stage.SHOWING_DATE_RESULT
	_session.completed = true
	_last_result = DateRunResult.new()
	_last_result.session = _session
	_last_result.girl_progress = _girl_progress
	_last_result.score_breakdown = _session.score_breakdown
	_last_result.relationship_max_reached = max_reached
	date_completed.emit()


func _apply_characteristic_trait(episode: DateEpisodeResult, move: DateMove) -> void:
	if episode.score_delta <= 0:
		return
	if _session.girl_trait_applied:
		return
	var girl_trait: GirlTrait = _catalog.find_trait(_girl.trait_id)
	if girl_trait == null or girl_trait.kind != GirlTrait.Kind.CHARACTERISTIC:
		return
	if move == null or move.unlock_requirement == null:
		return
	if move.unlock_requirement.stat_id != girl_trait.characteristic_id:
		return
	_session.girl_trait_applied = true
	_session.score_breakdown.girl_trait_score = 1
	_session.score_breakdown.girl_trait_display_name = girl_trait.display_name
	episode.trait_bonus_text = girl_trait.result_line(1)
	_session.score_breakdown.recompute()


func _apply_venue_trait() -> void:
	var girl_trait: GirlTrait = _catalog.find_trait(_girl.trait_id)
	if girl_trait == null:
		return
	_session.score_breakdown.girl_trait_display_name = girl_trait.display_name
	if girl_trait.kind != GirlTrait.Kind.VENUE:
		return
	var score: int = 1 if _location != null and _location.id == girl_trait.date_location_id else 0
	_session.score_breakdown.girl_trait_score = score


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
