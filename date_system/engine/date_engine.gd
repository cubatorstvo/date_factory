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
	view.local_object_views = _build_local_object_views()
	return view


func get_available_moves() -> Array[DateMoveOption]:
	var view := get_current_episode()
	var result: Array[DateMoveOption] = []
	if view == null:
		return result
	result.append_array(view.base_options)
	result.append_array(view.unlockable_options)
	for local_view in view.local_object_views:
		result.append_array(local_view.options)
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

	if move.kind == DateTypes.DateMoveKind.UNLOCKABLE:
		var used: int = int(_session.used_unlockable_move_counts.get(String(move_id), 0))
		_session.used_unlockable_move_counts[String(move_id)] = used + 1
	if move.is_local():
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
	var unlockables: Array[DateMove] = _catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.UNLOCKABLE)
	if not rules.show_locked_unlockable_moves:
		var visible: Array[DateMove] = []
		for move in unlockables:
			if _move_availability(move) != DateTypes.MoveAvailability.LOCKED:
				visible.append(move)
		unlockables = visible
	_session.current_applicable_unlockable_move_ids = _ids_of(unlockables)
	var reserved: Dictionary = {}
	var available_unlockables: Array[DateMove] = []
	var locked_unlockables: Array[DateMove] = []
	var used_unlockables: Array[DateMove] = []
	for move in unlockables:
		var state: DateTypes.MoveAvailability = _move_availability(move)
		match state:
			DateTypes.MoveAvailability.AVAILABLE:
				available_unlockables.append(move)
				var mapping: DateMoveSituationMapping = move.mapping_for(situation.id)
				if mapping != null:
					reserved[mapping.tag_id] = true
			DateTypes.MoveAvailability.LOCKED:
				locked_unlockables.append(move)
			DateTypes.MoveAvailability.USED:
				used_unlockables.append(move)
	_session.current_available_unlockable_move_ids = _ids_of(available_unlockables)
	_session.current_locked_unlockable_move_ids = _ids_of(locked_unlockables)
	_session.current_used_unlockable_move_ids = _ids_of(used_unlockables)
	_session.current_reserved_unlockable_tag_ids = _tag_ids_from_reserved(reserved)
	var base_pool: Array[DateMove] = _catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE)
	_session.current_candidate_base_move_ids = _ids_of(base_pool)
	var preferred: Array[DateMove] = []
	var fallback: Array[DateMove] = []
	for move in base_pool:
		var tag_id: StringName = _move_tag(move, situation.id)
		if reserved.has(tag_id):
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
	var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
	if mapping == null:
		return &""
	return mapping.tag_id


func _tags_of(moves: Array[DateMove], situation_id: StringName) -> Array[StringName]:
	var tags: Array[StringName] = []
	for move in moves:
		tags.append(_move_tag(move, situation_id))
	return tags


func _tag_ids_from_reserved(reserved: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in reserved.keys():
		ids.append(key as StringName)
	return ids


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
		if move.is_local():
			continue
		var tag_id: StringName = move.resolved_tag_id(situation_id)
		if tag_id == &"":
			continue
		var option := DateMoveOption.new()
		option.move_id = move.id
		option.display_name = move.display_name
		option.kind = kind
		option.option_text = move.resolved_option_text(situation_id)
		option.tag_id = tag_id
		var tag: DateTag = _catalog.find_tag(tag_id)
		option.tag_display_name = tag.display_name if tag != null else String(tag_id)
		option.tag_knowledge = _girl_progress.tag_knowledge(tag_id, _girl)
		if kind == DateTypes.DateMoveKind.UNLOCKABLE:
			option.availability = _move_availability(move)
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


func _move_availability(move: DateMove) -> DateTypes.MoveAvailability:
	if move.is_local():
		var local_object: DateLocalObject = _catalog.find_local_object_for_move(move.id)
		if local_object != null and _session.used_local_object_ids.has(local_object.id):
			return DateTypes.MoveAvailability.USED
	else:
		var used: int = int(_session.used_unlockable_move_counts.get(String(move.id), 0))
		if not move.is_unlimited() and used >= move.max_uses_per_date:
			return DateTypes.MoveAvailability.USED
	if move.unlock_requirement != null:
		var current: int = _player.get_stat(move.unlock_requirement.stat_id)
		if current < move.unlock_requirement.required_level:
			return DateTypes.MoveAvailability.LOCKED
	return DateTypes.MoveAvailability.AVAILABLE


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
		view.used = _session.used_local_object_ids.has(local_object.id)
		for move_id in local_object.move_ids:
			var option: DateMoveOption = _build_local_option(move_id, local_object, view.used)
			if option != null:
				view.options.append(option)
		views.append(view)
	return views


func _build_local_option(move_id: StringName, local_object: DateLocalObject, object_used: bool) -> DateMoveOption:
	var move: DateMove = _catalog.find_move(move_id)
	if move == null or not move.is_local():
		return null
	var option := DateMoveOption.new()
	option.move_id = move.id
	option.display_name = move.display_name
	option.kind = DateTypes.DateMoveKind.LOCAL
	option.option_text = move.resolved_option_text(&"")
	option.tag_id = move.resolved_tag_id(&"")
	var tag: DateTag = _catalog.find_tag(option.tag_id)
	option.tag_display_name = tag.display_name if tag != null else String(option.tag_id)
	option.tag_knowledge = _girl_progress.tag_knowledge(option.tag_id, _girl)
	option.local_object_id = local_object.id
	option.local_object_display_name = local_object.display_name
	if move.unlock_requirement != null:
		option.requirement_stat_id = move.unlock_requirement.stat_id
		option.requirement_level = move.unlock_requirement.required_level
		option.current_stat_level = _player.get_stat(move.unlock_requirement.stat_id)
	if object_used:
		option.availability = DateTypes.MoveAvailability.USED
	else:
		option.availability = _move_availability(move)
	return option


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
