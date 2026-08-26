class_name StageExecutor
extends RefCounted

const MAX_ACTIONS_PER_RUN: int = 8000

class Candidate:
	var category: String = "OTHER"
	var content_id: String = ""
	var goal_id: String = ""
	var is_support: bool = false
	var score: float = 0.0
	var kind: String = ""
	var girl_id: StringName = &""
	var rival_id: StringName = &""
	var outfit_id: StringName = &""
	var object_id: StringName = &""
	var venue_id: StringName = &""
	var location_id: StringName = &""
	var upgrade_id: StringName = &""
	var competition_id: StringName = &""
	var cash_needed: int = 0
	var action_id: String = ""
	var required_money: int = 0
	var cash_before: int = 0
	var cash_gap: int = 0
	var supporting_action_id: String = ""
	var urgent_taxi: bool = false
	var express_styling: bool = false
	var backup_outfit_id: StringName = &""
	var uses_daily_gate: bool = false
	var unblocks_higher: bool = false
	var is_novel: bool = false


class ExecutionResult:
	var success: bool = false
	var failure_code: String = ""
	var failure_reason: String = ""


var config: ProgressionLabConfig
var profile: PlayerProfile
var interests: CampaignInterests
var isolation_mode: StringName = &""
var isolation_characteristic_id: StringName = &""
var isolation_milestone: int = 0
var detailed: bool = false

var _campaign: ProgressionLabMetrics
var _stage_metrics: Dictionary = {}
var _current_stage_metrics: ProgressionLabMetrics
var _action_sequence: PackedStringArray = PackedStringArray()
var _daily_log: Array = []
var _date_summaries: Array = []
var _timeline: PackedStringArray = PackedStringArray()
var _item_utility: Dictionary = {}
var _seen: Dictionary = {}
var _visited_venues: Dictionary = {}
var _day_lines: PackedStringArray = PackedStringArray()
var _current_day: int = -1
var _plan_hashes: Dictionary = {}
var _hard_warnings: PackedStringArray = PackedStringArray()
var _aborted: bool = false
var _execution_rng: RandomNumberGenerator
var _date_rng: RandomNumberGenerator
var _date_policy: DateDecisionPolicy
var _stage_plans: Array = []
var _run_base_seed: int = 0
var _run_stage: int = 1
var _consecutive_stalled_decisions: int = 0
var _consecutive_stalled_days: int = 0
var _day_had_successful_action: bool = false
var _stall_day_index: int = -1
var _last_failed_candidates: Array = []
var _last_candidate_count: int = 0
var _stop_reason: String = ""
var _diagnostic_snapshot: Dictionary = {}
var _active_plan: StagePlan
var _last_action_failure: String = ""
var _failed_candidate_sequence: PackedStringArray = PackedStringArray()
var _stage_transitions: PackedStringArray = PackedStringArray()
var _rng_draw_counts: Dictionary = {}
var _cash_dependencies: Array = []
var _rival_money_failed_goals: Dictionary = {}
var _resolved_rival_money_goals: Dictionary = {}
var _recorded_build_goals: Dictionary = {}
var test_max_possible_relationship_gain: int = -1
var _target_career_rank: int = -1
var _career_roi_day: int = -1
var _last_career_roi: Dictionary = {}
var _last_career_lock_diagnostics: Dictionary = {}


func execute_run(base_seed: int, end_story_stage: int) -> ProgressionLabRunRecord:
	var record := ProgressionLabRunRecord.new()
	record.base_seed = base_seed
	record.archetype = profile.archetype
	record.profile = profile.to_dict()
	record.interests = interests.to_dict()
	record.end_story_stage = end_story_stage
	_campaign = ProgressionLabMetrics.new()
	_stage_metrics.clear()
	_action_sequence.clear()
	_daily_log.clear()
	_date_summaries.clear()
	_timeline.clear()
	_item_utility.clear()
	_seen.clear()
	_visited_venues.clear()
	_hard_warnings.clear()
	_aborted = false
	_run_base_seed = base_seed
	_consecutive_stalled_decisions = 0
	_consecutive_stalled_days = 0
	_day_had_successful_action = false
	_stall_day_index = -1
	_last_failed_candidates.clear()
	_last_candidate_count = 0
	_stop_reason = ""
	_diagnostic_snapshot.clear()
	_active_plan = null
	_last_action_failure = ""
	_failed_candidate_sequence.clear()
	_stage_transitions.clear()
	_rng_draw_counts.clear()
	_cash_dependencies.clear()
	_rival_money_failed_goals.clear()
	_resolved_rival_money_goals.clear()
	_recorded_build_goals.clear()
	_target_career_rank = -1
	_career_roi_day = -1
	_last_career_roi = {}
	seed(ProgressionRng.derive_seed(base_seed, "GLOBAL"))
	var competitions_reset: Variant = _competition_service()
	if competitions_reset != null:
		competitions_reset.set_forced_won(null)
		competitions_reset.set_rng(ProgressionRng.make(base_seed, "COMPETITION"))
	_stage_plans.clear()
	_plan_hashes.clear()
	_date_rng = ProgressionRng.make(base_seed, ProgressionRng.STREAM_DATE)
	_date_policy = DateDecisionPolicy.new()
	_date_policy.config = config
	_date_policy.profile = profile
	_date_policy.interests = interests
	_date_policy.rng = _date_rng
	var rating: Variant = _rating_service()
	var economy: Variant = _economy_service()
	_campaign.rating_start = int(rating.get_rating()) if rating != null else 0
	_campaign.minimum_money = int(economy.get_money()) if economy != null else 0
	_snapshot_career_start(_campaign)
	if detailed:
		_timeline.append(_format_career_state("## Starting Career State"))
	var target_stage: int = clampi(end_story_stage, 1, 4)
	while _current_story_stage() <= target_stage and not _aborted:
		var stage: int = _current_story_stage()
		if stage < 1 or stage > 4:
			break
		_execute_stage(stage, base_seed, target_stage)
		if _current_story_stage() == stage:
			break
	_flush_day()
	var clock: Variant = _time_service()
	var last_day: int = int(clock.get_calendar_day_index()) if clock != null else 0
	_campaign.finalize_days(last_day, int(economy.get_money()) if economy != null else 0, int(rating.get_rating()) if rating != null else 0)
	_snapshot_career_end(_campaign)
	if detailed:
		_timeline.append(_format_career_state("## Ending Career State"))
	_finalize_rival_money_metrics(_active_plan)
	record.stage_plans = _stage_plans.duplicate(true)
	record.campaign_metrics = _campaign.to_dict()
	record.stage_metrics = {}
	for key in _stage_metrics.keys():
		var metrics: ProgressionLabMetrics = _stage_metrics[key]
		record.stage_metrics[str(key)] = metrics.to_dict()
	record.hard_warnings = _hard_warnings.duplicate()
	record.timeline_markdown = "\n".join(_timeline)
	record.action_sequence = _action_sequence.duplicate()
	record.daily_log = _daily_log.duplicate(true)
	record.date_summaries = _date_summaries.duplicate(true)
	record.item_utility = _item_utility.duplicate(true)
	record.aborted = _aborted
	record.stop_reason = _stop_reason
	record.diagnostic_snapshot = _diagnostic_snapshot.duplicate(true)
	record.failed_candidate_sequence = _failed_candidate_sequence.duplicate()
	record.stage_transitions = _stage_transitions.duplicate()
	record.final_story_stage = _current_story_stage()
	record.final_money = int(economy.get_money()) if economy != null else 0
	record.rng_draw_counts = _rng_draw_counts.duplicate(true)
	record.rng_draw_counts[ProgressionRng.STREAM_DATE] = ProgressionRng.draw_count_of(_date_rng)
	var girls_rng: Variant = _girls_service()
	if girls_rng != null:
		record.rng_draw_counts[ProgressionRng.STREAM_GIRL_KNOWLEDGE] = ProgressionRng.draw_count_of(girls_rng.knowledge_rng)
	return record


func _execute_stage(stage: int, base_seed: int, target_stage: int) -> void:
	_execution_rng = ProgressionRng.make(base_seed, ProgressionRng.execution_stream(stage))
	_run_stage = stage
	var generator := StagePlanGenerator.new()
	generator.config = config
	generator.profile = profile
	generator.interests = interests
	generator.isolation_mode = isolation_mode
	generator.isolation_characteristic_id = isolation_characteristic_id
	generator.isolation_milestone = isolation_milestone
	var plan_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.stage_plan_stream(stage))
	var plan: StagePlan = generator.generate(stage, plan_rng)
	_rng_draw_counts[ProgressionRng.stage_plan_stream(stage)] = ProgressionRng.draw_count_of(plan_rng)
	_date_policy.plan = plan
	_active_plan = plan
	_plan_hashes[stage] = plan.generation_hash
	_stage_plans.append(plan.to_dict())
	_current_stage_metrics = ProgressionLabMetrics.new()
	_stage_metrics[stage] = _current_stage_metrics
	var start_clock: Variant = _time_service()
	var stage_start_day: int = int(start_clock.get_calendar_day_index()) if start_clock != null else 0
	_current_stage_metrics.begin_stage_window(stage_start_day)
	_clear_career_commitment()
	_snapshot_career_start(_current_stage_metrics)
	var rating: Variant = _rating_service()
	var economy_start: Variant = _economy_service()
	_current_stage_metrics.rating_start = int(rating.get_rating()) if rating != null else 0
	_current_stage_metrics.minimum_money = int(economy_start.get_money()) if economy_start != null else 0
	if detailed:
		_timeline.append(_format_stage_plan(plan))
		_timeline.append(_format_career_state("## Stage %d Career State" % stage))
	while _current_story_stage() == stage and not _aborted:
		var clock: Variant = _time_service()
		var day_index: int = int(clock.get_calendar_day_index()) if clock != null else 0
		if day_index >= config.max_calendar_days:
			_abort_run(plan, "SAFETY_CAP_DAYS")
			break
		if _action_sequence.size() >= MAX_ACTIONS_PER_RUN:
			_abort_run(plan, "SAFETY_CAP_ACTIONS")
			break
		_ensure_day(day_index)
		if _try_complete_stage(plan, stage):
			break
		var excluded: Dictionary = {}
		var attempts: int = 0
		var initial_count: int = -1
		var progressed: bool = false
		while not _aborted and _current_story_stage() == stage:
			var candidates: Array = _collect_scored_candidates(plan, excluded)
			if initial_count < 0:
				initial_count = candidates.size()
				_last_candidate_count = initial_count
			if candidates.is_empty():
				_finish_stalled_decision_cycle(plan, stage, initial_count)
				break
			var chosen: Candidate = pick_scored_candidate(candidates)
			_log_selected_candidate(chosen, plan)
			var executed: ExecutionResult = _execute_candidate(chosen, plan)
			attempts += 1
			if executed.success:
				_consecutive_stalled_decisions = 0
				_consecutive_stalled_days = 0
				_day_had_successful_action = true
				_last_failed_candidates.clear()
				progressed = true
				break
			_record_failed_candidate(chosen, executed, plan)
			excluded[_candidate_identity(chosen)] = true
			_consecutive_stalled_decisions += 1
			if attempts >= maxi(initial_count, 1):
				_finish_stalled_decision_cycle(plan, stage, initial_count)
				break
		if progressed:
			continue
	if plan.content_hash() != str(_plan_hashes.get(stage, "")):
		_hard_warnings.append("STAGE_PLAN_MUTATED_%d" % stage)
	_rng_draw_counts[ProgressionRng.execution_stream(stage)] = ProgressionRng.draw_count_of(_execution_rng)
	var economy: Variant = _economy_service()
	var end_clock: Variant = _time_service()
	_record_stale_planned_goals(plan)
	_current_stage_metrics.finalize_days(
		int(end_clock.get_calendar_day_index()) if end_clock != null else 0,
		int(economy.get_money()) if economy != null else 0,
		int(rating.get_rating()) if rating != null else 0,
		stage_start_day
	)
	_snapshot_career_end(_current_stage_metrics)
	_clear_career_commitment()
	if target_stage >= 0:
		pass


func _collect_candidates(plan: StagePlan) -> Array:
	var previous_consume: bool = true
	if _date_policy != null:
		previous_consume = _date_policy.consume_rng
		_date_policy.consume_rng = false
	var candidates: Array = []
	var barrier_done: bool = _barrier_complete(plan)
	var snapshot: Dictionary = collect_blocking_snapshot(plan)
	apply_blocking_snapshot(snapshot)
	if plan.stage >= 2 and not _owns_dressed_outfit():
		_add_outfit_candidates(candidates, plan, true)
	for girl_id in plan.target_filler_girl_ids:
		_add_girl_candidates(candidates, plan, girl_id, config.priority_filler_date, "DATE")
	if plan.story_rival_id != &"":
		_add_rival_candidates(candidates, plan, plan.story_rival_id, config.priority_story_rival, true)
	for rival_id in plan.target_ordinary_rival_ids:
		_add_rival_candidates(candidates, plan, rival_id, config.priority_ordinary_rival, false)
	_add_characteristic_candidates(candidates, plan)
	_add_outfit_candidates(candidates, plan, false)
	_add_apartment_candidates(candidates, plan)
	_add_venue_prep_candidates(candidates, plan)
	if plan.story_girl_id != &"":
		var story_priority: float = config.priority_story_girl_after_barrier if barrier_done else config.priority_story_girl_before_barrier
		_add_girl_candidates(candidates, plan, plan.story_girl_id, story_priority, "STORY")
	_add_work_candidates(candidates, plan, candidates)
	_add_career_candidates(candidates, plan)
	if _date_policy != null:
		_date_policy.consume_rng = previous_consume
	return candidates

func collect_blocking_snapshot(plan: StagePlan) -> Dictionary:
	_cash_dependencies = _build_cash_dependencies(plan)
	var money_ids: PackedStringArray = PackedStringArray()
	var daily_ids: PackedStringArray = PackedStringArray()
	for blocked in _cash_dependencies:
		var cash_goal: String = str(blocked.get("goal_id", ""))
		if cash_goal.is_empty() or money_ids.has(cash_goal):
			continue
		money_ids.append(cash_goal)
	var daily: Variant = _daily_activity()
	var girl_ids: Array[StringName] = plan.target_filler_girl_ids.duplicate()
	if plan.story_girl_id != &"" and not girl_ids.has(plan.story_girl_id):
		girl_ids.append(plan.story_girl_id)
	for girl_id in girl_ids:
		if _girl_maxed(girl_id):
			continue
		var girl_goal: String = _girl_goal(girl_id, plan.story_girl_id == girl_id)
		if daily != null and not bool(daily.is_available(daily.date_key(girl_id), 1)):
			daily_ids.append(girl_goal)
	var rival_ids: Array[StringName] = plan.target_ordinary_rival_ids.duplicate()
	if plan.story_rival_id != &"" and not rival_ids.has(plan.story_rival_id):
		rival_ids.append(plan.story_rival_id)
	var rivals: Variant = _rivals_service()
	for rival_id in rival_ids:
		if rivals == null:
			continue
		var is_story_rival: bool = rival_id == plan.story_rival_id
		if is_rival_goal_complete(_rival_goal_id(rival_id, is_story_rival), rival_id):
			continue
		var intent: Dictionary = evaluate_rival_intent(rival_id, is_story_rival)
		if str(intent.get("failure_code", "")) == "DAILY_GATE":
			daily_ids.append(_rival_goal_id(rival_id, is_story_rival))
	for characteristic_id in plan.characteristic_targets.keys():
		var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(StringName(str(characteristic_id)))
		if upgrade == null:
			continue
		var characteristics: Variant = _characteristic_service()
		if characteristics != null and int(characteristics.get_value(StringName(str(characteristic_id)))) >= int(plan.characteristic_targets[characteristic_id]):
			continue
		var char_goal: String = _char_goal(StringName(str(characteristic_id)), int(plan.characteristic_targets[characteristic_id]))
		if daily != null and not bool(daily.is_available("characteristic_training", 1)):
			daily_ids.append(char_goal)
	return {
		"money": money_ids,
		"daily_gate": daily_ids,
		"cash_dependencies": _cash_dependencies.duplicate(true),
	}

func apply_blocking_snapshot(snapshot: Dictionary) -> void:
	var money_ids: Array = snapshot.get("money", PackedStringArray())
	var daily_ids: Array = snapshot.get("daily_gate", PackedStringArray())
	var day_index: int = _day_index()
	if _campaign != null:
		_campaign.record_blocking_decision_point(money_ids, daily_ids, day_index)
	if _current_stage_metrics != null:
		_current_stage_metrics.record_blocking_decision_point(money_ids, daily_ids, day_index)
	if detailed and (not money_ids.is_empty() or not daily_ids.is_empty()):
		_log_line("Money-blocked goals:")
		for goal_id in money_ids:
			_log_line("- %s" % str(goal_id))
		_log_line("Daily-gate-blocked goals:")
		for goal_id in daily_ids:
			_log_line("- %s" % str(goal_id))


func _add_girl_candidates(candidates: Array, plan: StagePlan, girl_id: StringName, priority: float, category: String) -> void:
	var girls: Variant = _girls_service()
	if girls == null or girls.get_definition(girl_id) == null:
		return
	if _girl_maxed(girl_id):
		return
	var definition: GirlDefinition = girls.get_definition(girl_id)
	var is_story: bool = category == "STORY"
	if not bool(girls.is_discovered(girl_id)):
		if bool(girls.can_meet_girl(girl_id)):
			var meet := Candidate.new()
			meet.category = category
			meet.kind = "meet"
			meet.girl_id = girl_id
			meet.location_id = definition.location_id
			meet.goal_id = _girl_goal(girl_id, is_story)
			meet.content_id = "meet:%s" % String(girl_id)
			meet.score = _score(priority, false, true, not _seen.has("girl:%s" % String(girl_id)), meet.content_id)
			candidates.append(meet)
		elif _world_service() != null and definition.location_id != _world_service().get_current_location_id():
			if _world_service().can_enter_location(definition.location_id):
				if _meet_only_blocked_by_location(girl_id, definition):
					var travel := Candidate.new()
					travel.category = category
					travel.kind = "meet"
					travel.girl_id = girl_id
					travel.location_id = definition.location_id
					travel.goal_id = _girl_goal(girl_id, is_story)
					travel.content_id = "meet:%s" % String(girl_id)
					travel.score = _score(priority, false, true, not _seen.has("girl:%s" % String(girl_id)), travel.content_id)
					candidates.append(travel)
		return
	var dating: Variant = _dating_service()
	if dating == null:
		return
	var urgent_taxi: bool = false
	var cooldown_reason: String = str(dating.get_start_date_failure_reason(girl_id))
	if not cooldown_reason.is_empty() and str(cooldown_reason).find("Сегодня") >= 0 and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)):
		urgent_taxi = true
	if plan.stage >= 2 and not _owns_dressed_outfit() and _girl_requires_dressed(girl_id):
		return
	var outfits: Dictionary = _date_policy.choose_outfits(girl_id, &"", _girl_requires_dressed(girl_id))
	var outfit_id: StringName = outfits["outfit_id"]
	var backup_id: StringName = outfits["backup_outfit_id"]
	var venue_id: StringName = _date_policy.choose_venue(girl_id)
	if _story_date_blocked_by_barrier(plan, girl_id, category, outfit_id, venue_id):
		_log_story_barrier_hold(plan, girl_id, outfit_id, venue_id)
		return
	var express: bool = bool(girls.has_filler_reward(FillerRewardCatalog.ID_KIRA_EXPRESS_STYLING))
	var eligibility: Dictionary = evaluate_date_candidate(girl_id, outfit_id, venue_id, urgent_taxi, express, backup_id)
	if not bool(eligibility.get("eligible", false)):
		return
	if venue_id == &"apartment":
		var apartment: Variant = _apartment_service()
		if apartment != null and not bool(apartment.is_prepared()):
			var prep := Candidate.new()
			prep.category = "APARTMENT_PREPARATION"
			prep.kind = "clean"
			prep.goal_id = _girl_goal(girl_id, is_story)
			prep.is_support = true
			prep.content_id = "clean"
			prep.unblocks_higher = true
			prep.score = _score(priority, false, true, false, prep.content_id)
			candidates.append(prep)
	_consider_owned_items_for_date(outfits, venue_id)
	var date := Candidate.new()
	date.category = category
	date.kind = "date"
	date.girl_id = girl_id
	date.venue_id = venue_id
	date.outfit_id = outfit_id
	date.backup_outfit_id = backup_id
	date.express_styling = express
	date.urgent_taxi = urgent_taxi
	date.goal_id = _girl_goal(girl_id, is_story)
	date.action_id = str(eligibility.get("action_id", ""))
	date.required_money = int(eligibility.get("required_money", 0))
	date.content_id = "date:%s:%s:%s:%s:%s" % [String(girl_id), String(venue_id), String(outfit_id), "x" if express else "n", "t" if urgent_taxi else "n"]
	date.uses_daily_gate = not urgent_taxi
	date.is_novel = not _seen.has("girl:%s" % String(girl_id)) or not _visited_venues.has(String(venue_id))
	date.score = _score(priority, date.uses_daily_gate, false, date.is_novel, date.content_id)
	candidates.append(date)

func _meet_only_blocked_by_location(girl_id: StringName, definition: GirlDefinition) -> bool:
	var world: Variant = _world_service()
	if world == null or not bool(world.can_enter_location(definition.location_id)):
		return false
	var previous: StringName = world.get_current_location_id()
	world.enter_location(definition.location_id)
	var can_meet: bool = bool(_girls_service().can_meet_girl(girl_id))
	world.enter_location(previous)
	return can_meet


func _add_rival_candidates(candidates: Array, plan: StagePlan, rival_id: StringName, priority: float, is_story: bool) -> void:
	var intent: Dictionary = evaluate_rival_intent(rival_id, is_story)
	if str(intent.get("failure_code", "")) == "RIVAL_ALREADY_COMPLETE":
		return
	if not bool(intent.get("production_available", false)):
		return
	if int(intent.get("cash_gap", 0)) > 0:
		return
	var definition: RivalDefinition = null
	var rivals: Variant = _rivals_service()
	if rivals != null:
		definition = rivals.get_definition(rival_id)
	var action_type: String = str(intent.get("action_type", ""))
	if action_type == "RIVAL_MEET":
		var meet := Candidate.new()
		meet.category = "RIVAL" if not is_story else "STORY"
		meet.kind = "rival_meet"
		meet.rival_id = rival_id
		meet.location_id = definition.location_id if definition != null else &""
		meet.goal_id = str(intent.get("goal_id", ""))
		meet.action_id = str(intent.get("production_action_id", ""))
		meet.required_money = int(intent.get("required_money", 0))
		meet.cash_before = int(intent.get("current_money", 0))
		meet.cash_gap = 0
		meet.content_id = meet.action_id
		meet.is_novel = not _seen.has("rival:%s" % String(rival_id))
		meet.score = _score(priority, false, true, meet.is_novel, meet.content_id)
		candidates.append(meet)
		return
	if action_type != "RIVAL_CHALLENGE":
		return
	var fight := Candidate.new()
	fight.category = "RIVAL" if not is_story else "STORY"
	fight.kind = "rival_fight"
	fight.rival_id = rival_id
	fight.competition_id = StringName(str(intent.get("competition_id", "")))
	fight.location_id = definition.location_id if definition != null else &""
	fight.goal_id = str(intent.get("goal_id", ""))
	fight.action_id = str(intent.get("production_action_id", ""))
	fight.required_money = int(intent.get("required_money", 0))
	fight.cash_before = int(intent.get("current_money", 0))
	fight.cash_gap = 0
	fight.content_id = fight.action_id
	fight.uses_daily_gate = true
	fight.is_novel = not _seen.has("rival:%s" % String(rival_id))
	fight.score = _score(priority, true, false, fight.is_novel, fight.content_id)
	candidates.append(fight)
func _add_characteristic_candidates(candidates: Array, plan: StagePlan) -> void:
	var characteristics: Variant = _characteristic_service()
	if characteristics == null:
		return
	for key in plan.characteristic_targets.keys():
		var characteristic_id: StringName = StringName(str(key))
		var target: int = int(plan.characteristic_targets[key])
		var current_value: int = int(characteristics.get_value(characteristic_id))
		if current_value >= target:
			continue
		var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(characteristic_id)
		if upgrade == null:
			continue
		var action: GameAction = characteristics.create_upgrade_action(upgrade.id)
		var actions: Variant = _action_service()
		if actions == null or not bool(actions.can_execute(action)):
			continue
		var train := Candidate.new()
		train.category = "TRAINING"
		train.kind = "train"
		train.upgrade_id = upgrade.id
		train.goal_id = _char_goal(characteristic_id, target)
		train.content_id = "train:%s" % String(characteristic_id)
		train.uses_daily_gate = true
		var priority: float = _apply_build_priority(config.priority_characteristic, plan, train.goal_id, 95.0)
		train.score = _score(priority, true, false, false, train.content_id)
		candidates.append(train)

func _add_outfit_candidates(candidates: Array, plan: StagePlan, dress_up: bool) -> void:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return
	var wanted: Array[StringName] = plan.target_outfit_ids.duplicate()
	if dress_up:
		wanted = _shop_outfits_for_stage(plan.stage)
	var owned_count: int = 0
	for outfit_id in plan.target_outfit_ids:
		if bool(equipment.owns_outfit(outfit_id)):
			owned_count += 1
	if not dress_up and owned_count >= plan.target_outfit_count:
		return
	if dress_up and _owns_dressed_outfit():
		return
	for outfit_id in wanted:
		if bool(equipment.owns_outfit(outfit_id)):
			continue
		var action: GameAction = equipment.create_buy_outfit_action(outfit_id)
		var actions: Variant = _action_service()
		if actions == null or not bool(actions.can_execute(action)):
			continue
		var buy := Candidate.new()
		buy.category = "PURCHASE"
		buy.kind = "buy_outfit"
		buy.outfit_id = outfit_id
		buy.location_id = LocationCatalog.ID_CLOTHING_STORE
		buy.goal_id = "outfit:dressup" if dress_up else _outfit_goal(outfit_id)
		buy.content_id = "outfit:%s" % String(outfit_id)
		buy.unblocks_higher = dress_up
		buy.is_novel = not _seen.has("outfit:%s" % String(outfit_id))
		var priority: float = config.priority_dress_up if dress_up else config.priority_outfit
		if not dress_up:
			priority = _apply_build_priority(priority, plan, buy.goal_id, 95.0)
		buy.score = _score(priority, false, dress_up, buy.is_novel, buy.content_id)
		candidates.append(buy)

func _add_apartment_candidates(candidates: Array, plan: StagePlan) -> void:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return
	var owned: int = 0
	for object_id in plan.target_apartment_object_ids:
		if bool(apartment.is_object_owned(object_id)):
			owned += 1
	if owned >= plan.target_apartment_object_count:
		return
	for object_id in plan.target_apartment_object_ids:
		if bool(apartment.is_object_owned(object_id)):
			continue
		var action: GameAction = apartment.create_buy_apartment_object_action(object_id)
		var actions: Variant = _action_service()
		if actions == null or not bool(actions.can_execute(action)):
			continue
		var buy := Candidate.new()
		buy.category = "PURCHASE"
		buy.kind = "buy_apartment"
		buy.object_id = object_id
		buy.location_id = LocationCatalog.ID_FURNITURE_STORE
		buy.goal_id = _apartment_goal(object_id)
		buy.content_id = "apt:%s" % String(object_id)
		buy.is_novel = not _seen.has("apt:%s" % String(object_id))
		var priority: float = _apply_build_priority(config.priority_apartment, plan, buy.goal_id, 90.0)
		buy.score = _score(priority, false, false, buy.is_novel, buy.content_id)
		candidates.append(buy)
	if bool(apartment.has_interior_accent_reward()) and apartment.get_accent_object_id() == &"":
		var owned_ids: Array[StringName] = apartment.get_owned_object_ids()
		if not owned_ids.is_empty():
			var accent := Candidate.new()
			accent.category = "APARTMENT_PREPARATION"
			accent.kind = "accent"
			accent.object_id = owned_ids[0]
			accent.goal_id = _apartment_goal(owned_ids[0])
			accent.content_id = "accent:%s" % String(owned_ids[0])
			accent.score = _score(config.priority_apartment, false, false, true, accent.content_id)
			candidates.append(accent)

func _add_venue_prep_candidates(candidates: Array, plan: StagePlan) -> void:
	for venue_id in plan.venue_visit_goals:
		if _visited_venues.has(String(venue_id)):
			continue
		if plan.target_filler_girl_ids.is_empty() and plan.story_girl_id == &"":
			continue
		var girl_id: StringName = plan.story_girl_id if plan.story_girl_id != &"" else plan.target_filler_girl_ids[0]
		for candidate_girl in plan.target_filler_girl_ids:
			if _girls_service() != null and bool(_girls_service().is_discovered(candidate_girl)) and not _girl_maxed(candidate_girl):
				girl_id = candidate_girl
				break
		if _girls_service() == null or not bool(_girls_service().is_discovered(girl_id)):
			continue
		var dating: Variant = _dating_service()
		if dating == null or not bool(dating.is_date_venue_available(girl_id, venue_id)):
			continue
		if not bool(dating.can_start_date(girl_id)):
			continue
		var date := Candidate.new()
		date.category = "DATE"
		date.kind = "date"
		date.girl_id = girl_id
		date.venue_id = venue_id
		var outfits: Dictionary = _date_policy.choose_outfits(girl_id, venue_id)
		date.outfit_id = outfits["outfit_id"]
		date.backup_outfit_id = outfits["backup_outfit_id"]
		date.goal_id = _venue_goal(venue_id)
		date.content_id = "venue:%s" % String(venue_id)
		date.uses_daily_gate = true
		date.is_novel = true
		date.score = _score(config.priority_venue, true, false, true, date.content_id)
		candidates.append(date)


func _add_work_candidates(candidates: Array, plan: StagePlan, _existing: Array) -> void:
	var blocked: Array = _cash_blocked_goals(plan, [])
	if blocked.is_empty():
		return
	if not WorkService.is_work_available_today() and not WorkService.is_overtime_available_today():
		return
	blocked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["priority"]) > float(b["priority"])
	)
	var top: Dictionary = blocked[0]
	var work := Candidate.new()
	work.category = "WORK"
	work.kind = "work"
	work.is_support = true
	work.goal_id = str(top.get("goal_id", ""))
	work.action_id = "work"
	work.supporting_action_id = str(top.get("action_id", ""))
	work.required_money = int(top.get("required_money", 0))
	work.cash_before = int(top.get("current_money", 0))
	work.cash_gap = int(top.get("cash_gap", 0))
	work.cash_needed = work.cash_gap
	work.content_id = "work"
	work.uses_daily_gate = true
	work.score = _score(float(top.get("priority", 0.0)) - config.work_priority_offset, true, false, false, work.content_id)
	candidates.append(work)

func _cash_blocked_goals(plan: StagePlan, _existing: Array) -> Array:
	if _cash_dependencies.is_empty():
		_cash_dependencies = _build_cash_dependencies(plan)
	return _cash_dependencies

func _build_cash_dependencies(plan: StagePlan) -> Array:
	var blocked: Array = []
	if plan == null:
		return blocked
	var economy: Variant = _economy_service()
	var money: int = int(economy.get_money()) if economy != null else 0
	for girl_id in plan.target_filler_girl_ids:
		_append_date_cash_dependency(blocked, plan, girl_id, config.priority_filler_date, money)
	if plan.story_girl_id != &"" and _barrier_complete(plan):
		_append_date_cash_dependency(blocked, plan, plan.story_girl_id, config.priority_story_girl_after_barrier, money)
	for key in plan.characteristic_targets.keys():
		var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(StringName(str(key)))
		if upgrade == null or upgrade.price <= money:
			continue
		var characteristics: Variant = _characteristic_service()
		if characteristics != null and int(characteristics.get_value(StringName(str(key)))) >= int(plan.characteristic_targets[key]):
			continue
		blocked.append(_cash_row(_char_goal(StringName(str(key)), int(plan.characteristic_targets[key])), "train:%s" % String(key), "train", upgrade.price, money, config.priority_characteristic))
	for outfit_id in plan.target_outfit_ids:
		var equipment: Variant = _equipment_service()
		if equipment == null or bool(equipment.owns_outfit(outfit_id)):
			continue
		var price: int = int(equipment.get_effective_outfit_price(outfit_id))
		if price > money:
			blocked.append(_cash_row(_outfit_goal(outfit_id), "buy_outfit:%s" % String(outfit_id), "buy_outfit", price, money, config.priority_outfit))
	if plan.stage >= 2:
		var dress_equipment: Variant = _equipment_service()
		if dress_equipment != null and not bool(dress_equipment.owns_dressed_outfit()):
			for outfit_id in _shop_outfits_for_stage(plan.stage):
				var dress_price: int = int(dress_equipment.get_effective_outfit_price(outfit_id))
				if dress_price > money:
					blocked.append(_cash_row("outfit:dressup", "buy_outfit:%s" % String(outfit_id), "buy_outfit", dress_price, money, config.priority_dress_up))
					break
	for object_id in plan.target_apartment_object_ids:
		var apartment: Variant = _apartment_service()
		if apartment == null or bool(apartment.is_object_owned(object_id)):
			continue
		var item: ApartmentObjectDefinition = apartment.get_catalog().get_object(object_id)
		if item != null and item.price > money:
			blocked.append(_cash_row(_apartment_goal(object_id), "buy_apartment:%s" % String(object_id), "buy_apartment", item.price, money, config.priority_apartment))
	for rival_id in plan.target_ordinary_rival_ids:
		_append_rival_cash_dependency(blocked, rival_id, false, money)
	if plan.story_rival_id != &"":
		_append_rival_cash_dependency(blocked, plan.story_rival_id, true, money)
	return blocked

func _append_date_cash_dependency(blocked: Array, plan: StagePlan, girl_id: StringName, priority: float, money: int) -> void:
	if _girl_maxed(girl_id):
		return
	var girls: Variant = _girls_service()
	if girls == null or not bool(girls.is_discovered(girl_id)):
		return
	var dating: Variant = _dating_service()
	if dating == null:
		return
	var urgent_taxi: bool = false
	var cooldown_reason: String = str(dating.get_start_date_failure_reason(girl_id))
	if not cooldown_reason.is_empty() and str(cooldown_reason).find("Сегодня") >= 0 and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)):
		urgent_taxi = true
	if plan != null and plan.stage >= 2 and not _owns_dressed_outfit() and _girl_requires_dressed(girl_id):
		return
	var outfits: Dictionary = _date_policy.choose_outfits(girl_id, &"", _girl_requires_dressed(girl_id))
	var outfit_id: StringName = outfits["outfit_id"]
	var backup_id: StringName = outfits["backup_outfit_id"]
	var venue_id: StringName = _date_policy.choose_venue(girl_id)
	var category: String = "STORY" if plan != null and girl_id == plan.story_girl_id else "DATE"
	if _story_date_blocked_by_barrier(plan, girl_id, category, outfit_id, venue_id):
		return
	var express: bool = bool(girls.has_filler_reward(FillerRewardCatalog.ID_KIRA_EXPRESS_STYLING))
	var eligibility: Dictionary = evaluate_date_candidate(girl_id, outfit_id, venue_id, urgent_taxi, express, backup_id)
	var required_money: int = int(eligibility.get("required_money", 0))
	if required_money <= money:
		return
	var failure_code: String = str(eligibility.get("failure_code", ""))
	if not bool(eligibility.get("eligible", false)) and failure_code != "INSUFFICIENT_MONEY":
		return
	blocked.append(_cash_row(_girl_goal(girl_id, plan != null and plan.story_girl_id == girl_id), str(eligibility.get("action_id", "")), "date", required_money, money, priority))
func _append_rival_cash_dependency(blocked: Array, rival_id: StringName, is_story: bool, money: int) -> void:
	var intent: Dictionary = evaluate_rival_intent(rival_id, is_story)
	if not bool(intent.get("production_available", false)):
		return
	var cash_gap: int = int(intent.get("cash_gap", 0))
	if cash_gap <= 0:
		return
	var goal_id: String = str(intent.get("goal_id", ""))
	var action_id: String = str(intent.get("production_action_id", ""))
	var action_type: String = str(intent.get("action_type", "RIVAL_CHALLENGE"))
	var required_money: int = int(intent.get("required_money", 0))
	var priority: float = config.priority_story_rival if is_story else config.priority_ordinary_rival
	blocked.append(_cash_row(goal_id, action_id, action_type, required_money, money, priority))
	_note_rival_money_failure(goal_id, is_story)


func _cash_row(goal_id: String, action_id: String, action_type: String, required_money: int, current_money: int, priority: float) -> Dictionary:
	return {
		"goal_id": goal_id,
		"action_id": action_id,
		"action_type": action_type,
		"required_money": required_money,
		"current_money": current_money,
		"cash_gap": maxi(required_money - current_money, 0),
		"priority": priority,
	}

func pick_scored_candidate(candidates: Array) -> Candidate:
	var best: Candidate = null
	for candidate in candidates:
		if candidate == null:
			continue
		if best == null:
			best = candidate
			continue
		if candidate.score > best.score or (candidate.score == best.score and candidate.content_id < best.content_id):
			best = candidate
	return best


func decision_noise_amplitude(planning_skill: float) -> float:
	var noise_max: float = config.decision_noise_max if config != null else 15.0
	return noise_max * (1.0 - planning_skill)


func repetition_penalty_for(candidate_primary_activity: String, previous_primary_activity: String, consecutive_count: int) -> float:
	if candidate_primary_activity.is_empty() or candidate_primary_activity != previous_primary_activity:
		return 0.0
	var step: float = config.repetition_penalty_per_step if config != null else 8.0
	return step * float(consecutive_count)


func base_candidate_score(priority: float, daily_gate: bool, unblock: bool, novel: bool) -> float:
	var score: float = priority
	if daily_gate and config != null:
		score += config.daily_gate_bonus
	elif daily_gate:
		score += 20.0
	if unblock and config != null:
		score += config.unblock_bonus
	elif unblock:
		score += 25.0
	if novel and config != null:
		score += config.novelty_bonus
	elif novel:
		score += 10.0
	return score


func apply_execution_scores(
	candidates: Array,
	previous_primary: String,
	consecutive_count: int,
	rng: RandomNumberGenerator,
	planning_skill: float
) -> void:
	var amplitude: float = decision_noise_amplitude(planning_skill)
	for candidate in candidates:
		if candidate == null:
			continue
		var decision_noise: float = 0.0
		if rng != null:
			decision_noise = rng.randf_range(-amplitude, amplitude)
		var penalty: float = repetition_penalty_for(candidate.category, previous_primary, consecutive_count)
		candidate.score = candidate.score + decision_noise - penalty


func _pick_candidate(candidates: Array) -> Candidate:
	return pick_scored_candidate(candidates)


func _score(priority: float, daily_gate: bool, unblock: bool, novel: bool, content_id: String) -> float:
	var score: float = base_candidate_score(priority, daily_gate, unblock, novel)
	if content_id.is_empty():
		pass
	return score


func _execute_candidate(candidate: Candidate, plan: StagePlan) -> ExecutionResult:
	var result := ExecutionResult.new()
	if candidate == null:
		result.failure_code = "UNKNOWN"
		result.failure_reason = "missing candidate"
		return result
	var stage_before: int = _current_story_stage()
	if candidate.location_id != &"":
		var world: Variant = _world_service()
		if world != null and world.get_current_location_id() != candidate.location_id:
			world.enter_location(candidate.location_id)
	var before: Dictionary = _capture_world()
	var day_index: int = _day_index()
	_last_action_failure = ""
	var ok: bool = false
	match candidate.kind:
		"meet":
			ok = _exec_meet(candidate)
		"date":
			ok = _exec_date(candidate, plan)
		"train":
			ok = _exec_train(candidate)
		"buy_outfit":
			ok = _exec_buy_outfit(candidate)
		"buy_apartment":
			ok = _exec_buy_apartment(candidate)
		"clean":
			ok = _exec_clean(candidate)
		"accent":
			ok = _exec_accent(candidate)
		"rival_meet":
			ok = _exec_rival_meet(candidate)
		"rival_fight":
			ok = _exec_rival_fight(candidate)
		"work":
			ok = _exec_work(candidate)
		"career_advancement":
			ok = _exec_career_advancement(candidate)
		_:
			ok = false
	if not ok:
		return _classify_execution_failure(candidate, plan)
	_record_money_delta(int(before.get("money", 0)))
	var beats: int = _apply_world_diff(before, candidate)
	_campaign.record_primary(candidate.category, day_index, beats)
	_current_stage_metrics.record_primary(candidate.category, day_index, beats)
	_campaign.record_goal_action(candidate.goal_id, candidate.is_support, day_index)
	_current_stage_metrics.record_goal_action(candidate.goal_id, candidate.is_support, day_index)
	_action_sequence.append("%s|%s|%s" % [candidate.category, candidate.kind, candidate.content_id])
	_update_goal_completion(plan, day_index)
	var barrier_at_transition: bool = plan != null and _barrier_complete(plan)
	var story_max_at_transition: bool = plan != null and _story_girl_max(plan)
	_try_complete_stage(plan, stage_before)
	_assert_stage_transition(stage_before, barrier_at_transition, story_max_at_transition)
	result.success = true
	return result


func _exec_meet(candidate: Candidate) -> bool:
	var girls: Variant = _girls_service()
	var actions: Variant = _action_service()
	if girls == null or actions == null:
		return false
	var action: GameAction = girls.create_meet_girl_action(candidate.girl_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_reseed_girl_tags(candidate.girl_id)
	_seen["girl:%s" % String(candidate.girl_id)] = true
	_campaign.set_flag("used_production_meet")
	if candidate.girl_id == GirlCatalog.ID_EVA:
		_campaign.set_flag("eva_knowledge")
	_log_line("### MEET — %s" % _girl_name(candidate.girl_id))
	return true


func _reseed_girl_tags(girl_id: StringName) -> void:
	var girls: Variant = _girls_service()
	if girls == null or not girls.has_method("get_state"):
		return
	var state: Variant = girls.get_state(girl_id)
	if state == null:
		return
	if state.revealed_positive_tag_ids is PackedStringArray:
		state.revealed_positive_tag_ids = PackedStringArray()
	else:
		state.revealed_positive_tag_ids.clear()
	if state.revealed_negative_tag_ids is PackedStringArray:
		state.revealed_negative_tag_ids = PackedStringArray()
	else:
		state.revealed_negative_tag_ids.clear()
	var tag_rng: RandomNumberGenerator = ProgressionRng.make(_run_base_seed, "TAGS:%s" % String(girl_id))
	girls.apply_initial_known_tags(girl_id, tag_rng)
	if girl_id == GirlCatalog.ID_EVA or bool(girls.has_filler_reward(FillerRewardCatalog.ID_EVA_READ_PEOPLE)):
		_campaign.set_flag("eva_knowledge")


func _exec_date(candidate: Candidate, plan: StagePlan) -> bool:
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	if dating == null or actions == null:
		return false
	if _story_date_blocked_by_barrier(plan, candidate.girl_id, candidate.category, candidate.outfit_id, candidate.venue_id):
		_last_action_failure = "Story Girl held below MAX until StagePlan barrier complete"
		return false
	var equipment: Variant = _equipment_service()
	if candidate.outfit_id != &"" and equipment != null:
		if not bool(equipment.owns_outfit(candidate.outfit_id)):
			_last_action_failure = "Outfit unavailable"
			return false
		equipment.equip_outfit(candidate.outfit_id)
	var eligibility: Dictionary = evaluate_date_candidate(candidate.girl_id, candidate.outfit_id, candidate.venue_id, candidate.urgent_taxi, candidate.express_styling, candidate.backup_outfit_id)
	if not bool(eligibility.get("eligible", false)):
		_last_action_failure = str(eligibility.get("reason", "Date eligibility changed"))
		return false
	var options: Dictionary = {
		"backup_outfit_id": candidate.backup_outfit_id,
		"express_styling": candidate.express_styling,
		"urgent_taxi": candidate.urgent_taxi,
		"date_seed": ProgressionRng.derive_seed(_run_base_seed, "DATE:%s:%d" % [String(candidate.girl_id), _campaign.dates]),
	}
	dating.pending_date_seed = int(options["date_seed"])
	var action: GameAction = dating.create_start_date_action(candidate.girl_id, candidate.venue_id, candidate.outfit_id, options)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		dating.pending_date_seed = -1
		_last_action_failure = str(result.failure_reason) if result != null else "start date rejected"
		return false
	if not bool(dating.has_active_date()):
		dating.start_date(candidate.girl_id, candidate.venue_id, candidate.outfit_id, options)
	if not bool(dating.has_active_date()):
		return false
	var engine: DateEngine = dating.get_date_engine()
	var play: Dictionary = _date_policy.play_date(engine)
	var run_result: DateRunResult = engine.get_result() if engine != null else null
	var date_result: DateResult = DateResult.from_run_result(run_result)
	date_result.girl_id = candidate.girl_id
	if date_result.duration_minutes <= 0:
		date_result.duration_minutes = 120
	var rel_before: int = int(_girls_service().get_relationship(candidate.girl_id))
	dating.complete_date(date_result)
	var rel_after: int = int(_girls_service().get_relationship(candidate.girl_id))
	_campaign.add_date(candidate.girl_id)
	_current_stage_metrics.add_date(candidate.girl_id)
	if _girl_maxed(candidate.girl_id):
		_campaign.mark_girl_max(candidate.girl_id)
		_current_stage_metrics.mark_girl_max(candidate.girl_id)
	_campaign.set_flag("used_production_date")
	_visited_venues[String(candidate.venue_id)] = true
	_seen["girl:%s" % String(candidate.girl_id)] = true
	_campaign.note_venue(candidate.venue_id)
	if candidate.urgent_taxi:
		_campaign.set_flag("rita_taxi")
	if candidate.backup_outfit_id != &"" and candidate.backup_outfit_id != candidate.outfit_id:
		_campaign.set_flag("nika_backup")
	if candidate.venue_id == &"restaurant":
		_campaign.set_flag("restaurant_date")
		if engine != null and engine.get_session_state() != null and engine.get_session_state().venue_source_limit >= 2:
			_campaign.set_flag("sonya_venue_x2")
		if engine != null and engine.get_session_state() != null and engine.get_session_state().characteristic_source_used:
			_campaign.set_flag("restaurant_characteristic_unlock")
	if engine != null and engine.get_session_state() != null and engine.get_session_state().accent_object_id != &"":
		_campaign.set_flag("katya_accent")
	var moves: PackedStringArray = PackedStringArray()
	var situations: PackedStringArray = PackedStringArray()
	if play.has("moves"):
		moves = play["moves"]
	if play.has("situations"):
		situations = play["situations"]
	for move_id in moves:
		_campaign.note_move(StringName(move_id))
	for situation_id in situations:
		_campaign.note_situation(StringName(situation_id))
	_note_item_use(candidate.outfit_id, run_result)
	_note_selected_source_moves(moves, run_result)
	_date_summaries.append({
		"girl_id": String(candidate.girl_id),
		"venue_id": String(candidate.venue_id),
		"outfit_id": String(candidate.outfit_id),
		"relationship_before": rel_before,
		"relationship_after": rel_after,
		"moves": Array(moves),
		"score": date_result.relationship_delta,
	})
	if detailed:
		_log_line("### DATE — %s" % _girl_name(candidate.girl_id))
		_log_line("Venue: %s" % String(candidate.venue_id))
		_log_line("Outfit: %s" % String(candidate.outfit_id))
		_log_line("Relationship: %d → %d" % [rel_before, rel_after])
		_log_line("Date score: %+d" % date_result.relationship_delta)
	if plan != null and plan.venue_visit_goals.has(candidate.venue_id):
		_complete_goal_both(_venue_goal(candidate.venue_id), _day_index())
	return true


func _exec_train(candidate: Candidate) -> bool:
	var characteristics: Variant = _characteristic_service()
	var actions: Variant = _action_service()
	if characteristics == null or actions == null:
		return false
	var action: GameAction = characteristics.create_upgrade_action(candidate.upgrade_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.training_actions += 1
	_current_stage_metrics.training_actions += 1
	_campaign.characteristic_upgrades += 1
	_current_stage_metrics.characteristic_upgrades += 1
	if candidate.goal_id.begins_with("career:"):
		_campaign.career_investment_capital_training_actions += 1
		_current_stage_metrics.career_investment_capital_training_actions += 1
	_log_line("### TRAINING %s" % String(candidate.upgrade_id))
	return true


func _exec_buy_outfit(candidate: Candidate) -> bool:
	var equipment: Variant = _equipment_service()
	var actions: Variant = _action_service()
	if equipment == null or actions == null:
		return false
	var marina: bool = bool(equipment.is_marina_gift_price(candidate.outfit_id))
	var action: GameAction = equipment.create_buy_outfit_action(candidate.outfit_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.purchases += 1
	_current_stage_metrics.purchases += 1
	_campaign.outfits_acquired += 1
	_current_stage_metrics.outfits_acquired += 1
	_seen["outfit:%s" % String(candidate.outfit_id)] = true
	_ensure_item(String(candidate.outfit_id))["acquired"] = true
	_campaign.set_flag("used_production_purchase")
	if marina:
		_campaign.set_flag("marina_free_outfit")
	if _owns_dressed_outfit():
		_campaign.set_flag("stage2_dress_up")
	_log_line("### PURCHASE outfit %s" % String(candidate.outfit_id))
	return true


func _exec_buy_apartment(candidate: Candidate) -> bool:
	var apartment: Variant = _apartment_service()
	var actions: Variant = _action_service()
	if apartment == null or actions == null:
		return false
	var action: GameAction = apartment.create_buy_apartment_object_action(candidate.object_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.purchases += 1
	_current_stage_metrics.purchases += 1
	_campaign.apartment_objects_acquired += 1
	_current_stage_metrics.apartment_objects_acquired += 1
	_seen["apt:%s" % String(candidate.object_id)] = true
	_ensure_item(String(candidate.object_id))["acquired"] = true
	_campaign.set_flag("apartment_purchase")
	_log_line("### PURCHASE apartment %s" % String(candidate.object_id))
	return true


func _exec_clean(candidate: Candidate) -> bool:
	var apartment: Variant = _apartment_service()
	var actions: Variant = _action_service()
	if apartment == null or actions == null:
		return false
	var action: GameAction = apartment.create_clean_action()
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.apartment_preparations += 1
	_current_stage_metrics.apartment_preparations += 1
	_log_line("### APARTMENT_PREPARATION clean for %s" % candidate.goal_id)
	return true


func _exec_accent(candidate: Candidate) -> bool:
	var apartment: Variant = _apartment_service()
	var actions: Variant = _action_service()
	if apartment == null or actions == null:
		return false
	var action: GameAction = apartment.create_assign_accent_action(candidate.object_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.set_flag("katya_accent")
	_campaign.apartment_preparations += 1
	_log_line("### APARTMENT_PREPARATION accent %s" % String(candidate.object_id))
	return true


func _exec_rival_meet(candidate: Candidate) -> bool:
	var rivals: Variant = _rivals_service()
	var actions: Variant = _action_service()
	if rivals == null or actions == null:
		return false
	var action: GameAction = rivals.create_meet_rival_action(candidate.rival_id)
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_seen["rival:%s" % String(candidate.rival_id)] = true
	_log_line("### RIVAL meet %s" % String(candidate.rival_id))
	return true


func _exec_rival_fight(candidate: Candidate) -> bool:
	var competitions: Variant = _competition_service()
	var actions: Variant = _action_service()
	if competitions == null or actions == null:
		return false
	var fight_rng: RandomNumberGenerator = ProgressionRng.make(_run_base_seed, "%s:fight:%s:%d" % [ProgressionRng.execution_stream(_run_stage), String(candidate.competition_id), _campaign.rival_attempts])
	competitions.set_rng(fight_rng)
	var action: GameAction = competitions.create_competition_action(candidate.competition_id)
	var result: ActionResult = actions.execute(action)
	var won: bool = false
	if result != null:
		for line in result.applied_effects:
			if str(line).find("Победа") >= 0:
				won = true
				break
	if result == null or not result.success:
		return false
	_campaign.rival_attempts += 1
	_current_stage_metrics.rival_attempts += 1
	if won:
		_campaign.rival_wins += 1
		_current_stage_metrics.rival_wins += 1
		if _rival_money_failed_goals.has(candidate.goal_id):
			_resolved_rival_money_goals[candidate.goal_id] = true
	_campaign.set_flag("used_production_rival")
	_seen["rival:%s" % String(candidate.rival_id)] = true
	_log_line("### RIVAL %s %s" % [String(candidate.rival_id), "win" if won else "loss"])
	return true


func _exec_work(candidate: Candidate) -> bool:
	var actions: Variant = _action_service()
	if actions == null:
		return false
	var rank_before: int = WorkService.get_career_rank()
	var action: GameAction
	if WorkService.is_work_available_today() and WorkService.has_olya_overtime():
		action = WorkService.create_work_with_overtime_action()
	elif WorkService.is_overtime_available_today():
		action = WorkService.create_overtime_action()
	else:
		action = WorkService.create_work_action(WorkService.make_current_work())
	var money_before: int = int(_economy_service().get_money())
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	var money_after: int = int(_economy_service().get_money())
	var earned: int = maxi(0, money_after - money_before)
	_campaign.work_actions += 1
	_current_stage_metrics.work_actions += 1
	_campaign.money_earned_from_work += earned
	_current_stage_metrics.money_earned_from_work += earned
	_campaign.record_work_at_rank(rank_before)
	_current_stage_metrics.record_work_at_rank(rank_before)
	if str(candidate.supporting_action_id).begins_with("rival_"):
		_campaign.work_actions_supporting_rival += 1
		_current_stage_metrics.work_actions_supporting_rival += 1
	_campaign.record_work_support(candidate.goal_id)
	_current_stage_metrics.record_work_support(candidate.goal_id)
	if candidate.goal_id != "" and candidate.cash_gap > 0:
		var day_index: int = _day_index()
		_campaign.record_money_forced_work(day_index)
		_current_stage_metrics.record_money_forced_work(day_index)
	_campaign.set_flag("used_production_work")
	_log_line("### WORK")
	_log_line("Goal support: %s" % candidate.goal_id)
	_log_line("Action support: %s" % candidate.supporting_action_id)
	_log_line("Work attribution: %s" % ProgressionLabMetrics.classify_supporting_goal(candidate.goal_id))
	_log_line("Money: $%d → $%d" % [money_before, money_after])
	_log_line("Required for action: $%d" % candidate.required_money)
	return true
func _skip_day() -> void:
	var actions: Variant = _action_service()
	if actions == null:
		return
	var action: GameAction = GameActionCatalog.make_skip_to_08_00()
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		var clock: Variant = _time_service()
		if clock != null:
			clock.advance_time(int(clock.minutes_until_next_morning(clock.get_game_time_minutes())))
	_action_sequence.append("OTHER|skip|skip_to_08_00")
	_log_line("### SKIP to 08:00")


func evaluate_date_candidate(girl_id: StringName, selected_outfit_id: StringName, selected_venue_id: StringName, urgent_taxi: bool = false, express_styling: bool = false, backup_outfit_id: StringName = &"") -> Dictionary:
	var result: Dictionary = {
		"eligible": false,
		"reason": "",
		"failure_code": "UNKNOWN",
		"required_money": 0,
		"action_id": "",
	}
	var dating: Variant = _dating_service()
	var equipment: Variant = _equipment_service()
	if dating == null:
		result["reason"] = "DatingService missing"
		return result
	if selected_outfit_id == &"" or equipment == null or not bool(equipment.owns_outfit(selected_outfit_id)):
		result["failure_code"] = "OUTFIT_UNAVAILABLE"
		result["reason"] = "Selected outfit is not owned"
		return result
	if selected_venue_id == &"" or not bool(dating.is_date_venue_available(girl_id, selected_venue_id)):
		result["failure_code"] = "VENUE_UNAVAILABLE"
		result["reason"] = "Selected venue is not available"
		return result
	var previous_outfit: StringName = equipment.get_current_outfit_id()
	equipment.equip_outfit(selected_outfit_id)
	var options: Dictionary = {
		"urgent_taxi": urgent_taxi,
		"express_styling": express_styling,
		"backup_outfit_id": backup_outfit_id,
	}
	var action: GameAction = dating.create_start_date_action(girl_id, selected_venue_id, selected_outfit_id, options)
	result["required_money"] = int(action.money_cost)
	result["action_id"] = "date:%s:%s:%s:%s:%s" % [String(girl_id), String(selected_venue_id), String(selected_outfit_id), "x" if express_styling else "n", "t" if urgent_taxi else "n"]
	var reason: String = str(dating.get_start_date_failure_reason(girl_id, urgent_taxi))
	if reason.is_empty():
		var actions: Variant = _action_service()
		if actions != null and not bool(actions.can_execute(action)):
			reason = str(actions.get_failure_reason(action))
	if previous_outfit != &"" and bool(equipment.owns_outfit(previous_outfit)):
		equipment.equip_outfit(previous_outfit)
	if reason.is_empty():
		result["eligible"] = true
		result["failure_code"] = ""
		return result
	result["reason"] = reason
	result["failure_code"] = _failure_code_from_reason(reason)
	return result

func evaluate_rival_intent(rival_id: StringName, is_story: bool) -> Dictionary:
	var economy: Variant = _economy_service()
	var current_money: int = int(economy.get_money()) if economy != null else 0
	var goal_id: String = _rival_goal_id(rival_id, is_story)
	var intent: Dictionary = {
		"goal_id": goal_id,
		"rival_id": String(rival_id),
		"rival_goal_type": "story" if is_story else "ordinary",
		"action_type": "",
		"production_action_id": "",
		"production_available": false,
		"production_failure_reason": "",
		"failure_code": "",
		"required_money": 0,
		"current_money": current_money,
		"cash_gap": 0,
		"primary_activity": "RIVAL",
		"competition_id": "",
		"location_id": "",
		"production_state": _rival_simulation_state(rival_id),
	}
	if is_rival_goal_complete(goal_id, rival_id):
		intent["failure_code"] = "RIVAL_ALREADY_COMPLETE"
		intent["production_state"] = "DEFEATED"
		return intent
	var state: String = str(intent.get("production_state", ""))
	if state == "LOCKED":
		intent["failure_code"] = "RIVAL_LOCKED"
		return intent
	if state == "DAILY_GATED":
		intent["failure_code"] = "DAILY_GATE"
		return intent
	if state == "DEFEATED":
		intent["failure_code"] = "RIVAL_ALREADY_COMPLETE"
		return intent
	var rivals: Variant = _rivals_service()
	var definition: RivalDefinition = rivals.get_definition(rival_id) if rivals != null else null
	if definition != null:
		intent["location_id"] = String(definition.location_id)
	var actions: Variant = _action_service()
	if state == "AVAILABLE_TO_MEET":
		intent["action_type"] = "RIVAL_MEET"
		intent["production_action_id"] = "rival_meet:%s" % String(rival_id)
		intent["production_available"] = true
		if rivals == null:
			intent["production_available"] = false
			intent["failure_code"] = "PRODUCTION_ACTION_REJECTED"
			return intent
		var meet_action: GameAction = rivals.create_meet_rival_action(rival_id)
		intent["required_money"] = int(meet_action.money_cost)
		intent["cash_gap"] = maxi(int(intent["required_money"]) - current_money, 0)
		if actions != null and not bool(actions.can_execute(meet_action)):
			intent["production_failure_reason"] = str(actions.get_failure_reason(meet_action))
			intent["failure_code"] = _failure_code_from_reason(str(intent["production_failure_reason"]))
		if int(intent["cash_gap"]) > 0:
			intent["failure_code"] = "INSUFFICIENT_MONEY"
			if str(intent["production_failure_reason"]).is_empty():
				intent["production_failure_reason"] = "INSUFFICIENT_MONEY"
		return intent
	if state != "AVAILABLE_TO_CHALLENGE":
		intent["failure_code"] = "PRODUCTION_ACTION_REJECTED"
		return intent
	intent["action_type"] = "RIVAL_CHALLENGE"
	intent["production_action_id"] = "rival_challenge:%s" % String(rival_id)
	intent["production_available"] = true
	var competitions: Variant = _competition_service()
	if competitions == null:
		intent["production_available"] = false
		intent["failure_code"] = "PRODUCTION_ACTION_REJECTED"
		return intent
	var list: Array = competitions.get_competitions_for_rival(rival_id)
	if list.is_empty():
		intent["production_available"] = false
		intent["failure_code"] = "PRODUCTION_ACTION_REJECTED"
		return intent
	var competition: CompetitionDefinition = list[0]
	intent["competition_id"] = String(competition.id)
	var action: GameAction = competitions.create_competition_action(competition.id)
	intent["required_money"] = int(action.money_cost)
	intent["cash_gap"] = maxi(int(intent["required_money"]) - current_money, 0)
	if actions != null and not bool(actions.can_execute(action)):
		intent["production_failure_reason"] = str(actions.get_failure_reason(action))
		intent["failure_code"] = _failure_code_from_reason(str(intent["production_failure_reason"]))
	if int(intent["cash_gap"]) > 0:
		intent["failure_code"] = "INSUFFICIENT_MONEY"
		if str(intent["production_failure_reason"]).is_empty():
			intent["production_failure_reason"] = "INSUFFICIENT_MONEY"
	return intent

func _note_rival_money_failure(goal_id: String, is_story: bool) -> void:
	if goal_id.is_empty() or _campaign == null:
		return
	_campaign.total_rival_cash_dependencies += 1
	if is_story:
		_campaign.story_rival_cash_dependencies += 1
	else:
		_campaign.ordinary_rival_cash_dependencies += 1
	if _current_stage_metrics != null:
		_current_stage_metrics.total_rival_cash_dependencies += 1
		if is_story:
			_current_stage_metrics.story_rival_cash_dependencies += 1
		else:
			_current_stage_metrics.ordinary_rival_cash_dependencies += 1
	if _rival_money_failed_goals.has(goal_id):
		return
	_rival_money_failed_goals[goal_id] = true
	_campaign.rival_action_money_failures += 1
	if _current_stage_metrics != null:
		_current_stage_metrics.rival_action_money_failures += 1

func _finalize_rival_money_metrics(plan: StagePlan) -> void:
	if _campaign == null:
		return
	for goal_id in _resolved_rival_money_goals.keys():
		_campaign.resolved_rival_money_failures += 1
	for goal_id in _rival_money_failed_goals.keys():
		if _resolved_rival_money_goals.has(goal_id):
			continue
		var still_unmet: bool = plan != null and Array(_unmet_goals(plan)).has(str(goal_id))
		if still_unmet:
			_campaign.unresolved_rival_money_failures += 1

func _collect_scored_candidates(plan: StagePlan, excluded: Dictionary) -> Array:
	_date_policy.consume_rng = false
	var candidates: Array = []
	for raw in _collect_candidates(plan):
		if raw == null:
			continue
		var candidate: Candidate = raw
		if excluded.has(_candidate_identity(candidate)):
			continue
		candidates.append(candidate)
	_date_policy.consume_rng = true
	candidates.sort_custom(func(a: Candidate, b: Candidate) -> bool:
		return a.content_id < b.content_id
	)
	apply_execution_scores(
		candidates,
		_campaign.last_primary_category() if _campaign != null else "",
		_campaign.consecutive_same_count() if _campaign != null else 0,
		_execution_rng,
		profile.planning_skill if profile != null else 1.0
	)
	return candidates


func _candidate_identity(candidate: Candidate) -> String:
	if candidate == null:
		return ""
	return "%s|%s|%s|%s|%s" % [candidate.kind, candidate.content_id, String(candidate.girl_id), String(candidate.outfit_id), String(candidate.venue_id)]


func _try_complete_stage(plan: StagePlan, stage: int) -> bool:
	if plan == null or not _barrier_complete(plan) or not _story_girl_max(plan):
		return false
	var stages: Variant = _stage_service()
	if stages != null:
		stages.try_complete_current_stage()
	var stage_after: int = _current_story_stage()
	if stage_after != stage:
		_stage_transitions.append("%d->%d" % [stage, stage_after])
	return stage_after != stage


func _assert_stage_transition(stage_before: int, barrier_before: bool, story_girl_max_before: bool) -> void:
	var stage_after: int = _current_story_stage()
	if stage_after <= stage_before:
		return
	if barrier_before and story_girl_max_before:
		return
	_hard_warnings.append("STAGE_TRANSITION_INVARIANT")


func _story_date_blocked_by_barrier(plan: StagePlan, girl_id: StringName, category: String, outfit_id: StringName = &"", venue_id: StringName = &"") -> bool:
	if plan == null or girl_id == &"" or plan.story_girl_id != girl_id:
		return false
	if category != "STORY" and category != "DATE":
		return false
	var barrier_done: bool = _barrier_complete(plan)
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	var rel_max: int = int(girls.get_relationship_max(girl_id))
	var rel: int = int(girls.get_relationship(girl_id))
	var planned: Dictionary = {
		"girl_id": girl_id,
		"outfit_id": outfit_id,
		"venue_id": venue_id,
	}
	var gain: int = get_max_possible_relationship_gain(planned)
	return is_predictive_story_barrier_blocked(rel, rel_max, gain, barrier_done)
func get_max_possible_relationship_gain(planned_date_context: Dictionary) -> int:
	if test_max_possible_relationship_gain >= 0:
		return test_max_possible_relationship_gain
	var dating: Variant = _dating_service()
	if dating == null:
		return 0
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return 0
	var catalog: DateContentCatalog = catalog_service.catalog
	var rules: DateRules = catalog.date_rules
	if rules == null:
		return 0
	var gain: int = rules.total_episode_count() * rules.positive_move_score
	gain += rules.combo_bonus_score * rules.combo_max_rewards_per_date
	var girl_id: StringName = StringName(str(planned_date_context.get("girl_id", "")))
	var venue_id: StringName = StringName(str(planned_date_context.get("venue_id", "")))
	var outfit_id: StringName = StringName(str(planned_date_context.get("outfit_id", "")))
	var girl: GirlProfile = catalog.find_girl(girl_id)
	if girl != null:
		var girl_trait: GirlTrait = catalog.find_trait(girl.trait_id)
		if girl_trait != null:
			if girl_trait.kind == GirlTrait.Kind.CHARACTERISTIC:
				gain += 1
			elif girl_trait.kind == GirlTrait.Kind.VENUE and girl_trait.date_venue_id == venue_id:
				gain += 1
	var venue: DateVenue = catalog.find_venue(venue_id)
	if venue != null and venue.uses_apartment_preparation:
		var apartment: Variant = _apartment_service()
		if apartment != null and not bool(apartment.is_prepared()):
			gain += rules.apartment_unprepared_penalty
	if outfit_id != &"" and catalog.find_outfit(outfit_id) != null:
		pass
	return maxi(gain, 0)

func is_predictive_story_barrier_blocked(current_relationship: int, relationship_max: int, max_possible_gain: int, barrier_complete: bool) -> bool:
	if barrier_complete:
		return false
	return relationship_max > 0 and current_relationship + max_possible_gain >= relationship_max
func _finish_stalled_decision_cycle(plan: StagePlan, stage: int, initial_count: int) -> void:
	if initial_count <= 0:
		_consecutive_stalled_decisions += 1
	_log_stall_day(plan, initial_count)
	if not _day_had_successful_action:
		_consecutive_stalled_days += 1
	_skip_day()
	_day_had_successful_action = false
	var max_stalled: int = 8
	if config != null:
		max_stalled = config.max_consecutive_stalled_days
	if _consecutive_stalled_days >= max_stalled:
		_abort_run(plan, "NO_USEFUL_ACTIONS_STAGE_%d" % stage)


func _abort_run(plan: StagePlan, reason: String) -> void:
	_stop_reason = reason
	_hard_warnings.append(reason)
	_diagnostic_snapshot = _build_diagnostic_snapshot(plan)
	_aborted = true


func _record_failed_candidate(candidate: Candidate, executed: ExecutionResult, plan: StagePlan) -> void:
	var entry: Dictionary = {
		"kind": candidate.kind if candidate != null else "",
		"category": candidate.category if candidate != null else "",
		"goal_id": candidate.goal_id if candidate != null else "",
		"girl_id": String(candidate.girl_id) if candidate != null else "",
		"outfit_id": String(candidate.outfit_id) if candidate != null else "",
		"venue_id": String(candidate.venue_id) if candidate != null else "",
		"failure_code": executed.failure_code,
		"failure_reason": executed.failure_reason,
	}
	_last_failed_candidates.append(entry)
	if candidate != null:
		_failed_candidate_sequence.append("%s|%s|%s" % [candidate.kind, candidate.content_id, executed.failure_code])
	if not detailed or candidate == null:
		return
	var economy: Variant = _economy_service()
	_log_line("### FAILED CANDIDATE")
	_log_line("Primary activity: %s" % candidate.category)
	_log_line("Goal: %s" % candidate.goal_id)
	if candidate.girl_id != &"":
		_log_line("Girl: %s" % _girl_name(candidate.girl_id))
	if candidate.outfit_id != &"":
		_log_line("Planned Outfit: %s" % String(candidate.outfit_id))
	if candidate.venue_id != &"":
		_log_line("Planned Venue: %s" % String(candidate.venue_id))
	_log_line("Failure code: %s" % executed.failure_code)
	_log_line("Failure reason: %s" % executed.failure_reason)
	_log_line("Money: $%d" % (int(economy.get_money()) if economy != null else 0))
	_log_line("Story Stage: %d" % _current_story_stage())
	_log_line("Barrier complete: %s" % str(_barrier_complete(plan) if plan != null else false))

func _log_selected_candidate(candidate: Candidate, plan: StagePlan) -> void:
	if not detailed or candidate == null:
		return
	_log_line("### SELECTED CANDIDATE")
	_log_line("Primary activity: %s" % candidate.category)
	_log_line("Goal: %s" % candidate.goal_id)
	if candidate.kind == "date":
		_log_line("Girl: %s" % _girl_name(candidate.girl_id))
		_log_line("Planned Outfit: %s" % String(candidate.outfit_id))
		_log_line("Planned Venue: %s" % String(candidate.venue_id))
		_log_line("Barrier complete: %s" % str(_barrier_complete(plan) if plan != null else false))
	if candidate.kind == "work":
		_log_line("Goal support: %s" % candidate.goal_id)
		_log_line("Action support: %s" % candidate.supporting_action_id)
		_log_line("Required for action: $%d" % candidate.required_money)
	if candidate.kind == "career_advancement" or candidate.goal_id.begins_with("career:"):
		_log_career_roi(_last_career_roi)

func _log_stall_day(plan: StagePlan, initial_count: int) -> void:
	if not detailed:
		return
	_log_line("Available candidates before execution: %d" % initial_count)
	_log_line("Failed candidates: %d" % _last_failed_candidates.size())
	_log_line("Remaining unmet goals:")
	for goal_id in _unmet_goals(plan):
		_log_line("- %s" % goal_id)


func _classify_execution_failure(candidate: Candidate, plan: StagePlan) -> ExecutionResult:
	var result := ExecutionResult.new()
	var reason: String = _last_action_failure
	if candidate != null and candidate.kind == "date":
		var eligibility: Dictionary = evaluate_date_candidate(candidate.girl_id, candidate.outfit_id, candidate.venue_id, candidate.urgent_taxi, candidate.express_styling, candidate.backup_outfit_id)
		if not bool(eligibility.get("eligible", false)):
			reason = str(eligibility.get("reason", reason))
			result.failure_code = str(eligibility.get("failure_code", "DATE_ELIGIBILITY_CHANGED"))
			result.failure_reason = reason
			return result
	if reason.is_empty():
		reason = "production action rejected"
	result.failure_reason = reason
	result.failure_code = _failure_code_from_reason(reason)
	if candidate != null and _goal_already_complete(candidate, plan):
		result.failure_code = "GOAL_ALREADY_COMPLETE"
	return result


func _failure_code_from_reason(reason: String) -> String:
	var text: String = reason.to_lower()
	if text.find("outfit") >= 0 or text.find("образ") >= 0 or text.find("casual") >= 0 or text.find("повседнев") >= 0:
		return "OUTFIT_UNAVAILABLE" if text.find("owned") >= 0 or text.find("не влад") >= 0 else "DATE_ELIGIBILITY_CHANGED"
	if text.find("venue") >= 0 or text.find("локац") >= 0:
		return "VENUE_UNAVAILABLE"
	if text.find("денег") >= 0 or text.find("money") >= 0:
		return "INSUFFICIENT_MONEY"
	if text.find("побежд") >= 0 or text.find("defeated") >= 0 or text.find("already") >= 0:
		return "RIVAL_ALREADY_COMPLETE"
	if text.find("заблок") >= 0 or text.find("locked") >= 0:
		return "RIVAL_LOCKED"
	if text.find("сегодня") >= 0 or text.find("daily") >= 0:
		return "DAILY_GATE"
	if text.find("apart") >= 0 or text.find("квартир") >= 0 or text.find("clean") >= 0:
		return "APARTMENT_PREPARATION_FAILED"
	if text.find("changed") >= 0 or text.find("state") >= 0:
		return "STATE_CHANGED"
	if text.find("barrier") >= 0 or text.find("complete") >= 0:
		return "GOAL_ALREADY_COMPLETE"
	if reason.is_empty():
		return "UNKNOWN"
	return "PRODUCTION_ACTION_REJECTED"


func _goal_already_complete(candidate: Candidate, plan: StagePlan) -> bool:
	if candidate == null:
		return false
	if candidate.girl_id != &"" and _girl_maxed(candidate.girl_id):
		return true
	if candidate.kind == "buy_outfit":
		var equipment: Variant = _equipment_service()
		return equipment != null and bool(equipment.owns_outfit(candidate.outfit_id))
	if candidate.kind == "buy_apartment":
		var apartment: Variant = _apartment_service()
		return apartment != null and bool(apartment.is_object_owned(candidate.object_id))
	if candidate.kind == "rival_meet" or candidate.kind == "rival_fight":
		return is_rival_goal_complete(candidate.goal_id, candidate.rival_id)
	if plan != null and candidate.kind == "date" and candidate.girl_id == plan.story_girl_id and _story_date_blocked_by_barrier(plan, candidate.girl_id, candidate.category):
		return true
	return false

func _record_money_delta(money_before: int) -> void:
	var economy: Variant = _economy_service()
	var money_after: int = int(economy.get_money()) if economy != null else money_before
	var earned: int = maxi(0, money_after - money_before)
	var spent: int = maxi(0, money_before - money_after)
	if _campaign != null:
		_campaign.money_earned += earned
		_campaign.money_spent += spent
		_campaign.minimum_money = mini(_campaign.minimum_money, money_after) if _campaign.total_actions > 0 else money_after
	if _current_stage_metrics != null:
		_current_stage_metrics.money_earned += earned
		_current_stage_metrics.money_spent += spent
		_current_stage_metrics.minimum_money = mini(_current_stage_metrics.minimum_money, money_after) if _current_stage_metrics.total_actions > 0 else money_after


func _complete_goal_both(goal_id: String, day_index: int) -> void:
	if _campaign != null:
		_campaign.complete_goal(goal_id, day_index)
	if _current_stage_metrics != null:
		_current_stage_metrics.complete_goal(goal_id, day_index)


func _unmet_goals(plan: StagePlan) -> PackedStringArray:
	var unmet: PackedStringArray = PackedStringArray()
	if plan == null:
		return unmet
	if plan.stage >= 2 and not _owns_dressed_outfit():
		unmet.append("outfit:dressup")
	for girl_id in plan.target_filler_girl_ids:
		if not _girl_maxed(girl_id):
			unmet.append(_girl_goal(girl_id))
	for rival_id in plan.target_ordinary_rival_ids:
		if not is_rival_goal_complete(_rival_goal(rival_id), rival_id):
			unmet.append(_rival_goal(rival_id))
	if plan.story_rival_id != &"" and not is_rival_goal_complete(_story_rival_goal(plan.story_rival_id), plan.story_rival_id):
		unmet.append(_story_rival_goal(plan.story_rival_id))
	var characteristics: Variant = _characteristic_service()
	for key in plan.characteristic_targets.keys():
		if characteristics == null or int(characteristics.get_value(StringName(str(key)))) < int(plan.characteristic_targets[key]):
			unmet.append(_char_goal(StringName(str(key)), int(plan.characteristic_targets[key])))
	var equipment: Variant = _equipment_service()
	var owned_outfits: int = 0
	for outfit_id in plan.target_outfit_ids:
		if equipment != null and bool(equipment.owns_outfit(outfit_id)):
			owned_outfits += 1
		elif equipment != null:
			unmet.append(_outfit_goal(outfit_id))
	if owned_outfits < plan.target_outfit_count:
		unmet.append("outfit:count")
	var apartment: Variant = _apartment_service()
	var owned_objects: int = 0
	for object_id in plan.target_apartment_object_ids:
		if apartment != null and bool(apartment.is_object_owned(object_id)):
			owned_objects += 1
		elif apartment != null:
			unmet.append(_apartment_goal(object_id))
	if owned_objects < plan.target_apartment_object_count:
		unmet.append("apartment:count")
	for venue_id in plan.venue_visit_goals:
		if not _visited_venues.has(String(venue_id)):
			unmet.append(_venue_goal(venue_id))
	if plan.story_girl_id != &"" and not _girl_maxed(plan.story_girl_id):
		unmet.append(_girl_goal(plan.story_girl_id, true))
	return unmet

func _build_diagnostic_snapshot(plan: StagePlan) -> Dictionary:
	var girls: Variant = _girls_service()
	var equipment: Variant = _equipment_service()
	var apartment: Variant = _apartment_service()
	var economy: Variant = _economy_service()
	var characteristics: Variant = _characteristic_service()
	var blocking: Dictionary = collect_blocking_snapshot(plan) if plan != null else {"money": PackedStringArray(), "daily_gate": PackedStringArray(), "cash_dependencies": []}
	var owned_outfits: PackedStringArray = PackedStringArray()
	if equipment != null:
		for outfit in equipment.get_owned_outfits():
			if outfit != null:
				owned_outfits.append(String(outfit.id))
	var owned_objects: PackedStringArray = PackedStringArray()
	if apartment != null:
		for object_id in apartment.get_owned_object_ids():
			owned_objects.append(String(object_id))
	var rels: Dictionary = {}
	var availability: Dictionary = {}
	if girls != null:
		for definition in girls.get_catalog().get_all_girls():
			if definition == null:
				continue
			rels[String(definition.id)] = int(girls.get_relationship(definition.id))
			availability[String(definition.id)] = {
				"discovered": bool(girls.is_discovered(definition.id)),
				"can_meet": bool(girls.can_meet_girl(definition.id)),
				"completed": bool(girls.is_relationship_completed(definition.id)),
			}
	var chars: Dictionary = {}
	if characteristics != null:
		for characteristic_id in CharacteristicIds.all_ids():
			chars[String(characteristic_id)] = int(characteristics.get_value(characteristic_id))
	var dating: Variant = _dating_service()
	var rival_availability: Dictionary = {}
	if plan != null:
		for rival_id in plan.target_ordinary_rival_ids:
			rival_availability[String(rival_id)] = _rival_diagnostic_row(rival_id, false)
		if plan.story_rival_id != &"":
			rival_availability[String(plan.story_rival_id)] = _rival_diagnostic_row(plan.story_rival_id, true)
	return {
		"unmet_goals": Array(_unmet_goals(plan)),
		"money": int(economy.get_money()) if economy != null else 0,
		"owned_outfits": Array(owned_outfits),
		"equipped_outfit": String(equipment.get_current_outfit_id()) if equipment != null else "",
		"owned_apartment_objects": Array(owned_objects),
		"characteristics": chars,
		"girl_relationships": rels,
		"girl_availability": availability,
		"rival_availability": rival_availability,
		"story_stage": _current_story_stage(),
		"city_stage": int(_world_service().get_city_stage()) if _world_service() != null else 0,
		"cash_blocked_goals": Array(blocking.get("money", PackedStringArray())),
		"cash_dependencies": Array(blocking.get("cash_dependencies", [])),
		"daily_gate_blocked_goals": Array(blocking.get("daily_gate", PackedStringArray())),
		"candidate_count": _last_candidate_count,
		"last_failed_candidates": _last_failed_candidates.duplicate(true),
		"consecutive_stalled_decisions": _consecutive_stalled_decisions,
		"consecutive_stalled_days": _consecutive_stalled_days,
		"barrier_complete": _barrier_complete(plan) if plan != null else false,
		"has_dating_service": dating != null,
		"last_rival_goal": _last_rival_goal_from_diagnostics(rival_availability),
		"last_rival_action_failure": _last_rival_failure_from_diagnostics(rival_availability),
		"career_connections": WorkService.has_career_connections(_game_state()),
		"career_rank": WorkService.get_career_rank(_game_state()),
		"career_lock": _last_career_lock_diagnostics.duplicate(true),
	}

func _barrier_complete(plan: StagePlan) -> bool:
	if plan.stage >= 2 and not _owns_dressed_outfit():
		return false
	for girl_id in plan.target_filler_girl_ids:
		if not _girl_maxed(girl_id):
			return false
	for rival_id in plan.target_ordinary_rival_ids:
		if not is_rival_goal_complete(_rival_goal(rival_id), rival_id):
			return false
	if plan.story_rival_id != &"" and not is_rival_goal_complete(_story_rival_goal(plan.story_rival_id), plan.story_rival_id):
		return false
	var characteristics: Variant = _characteristic_service()
	for key in plan.characteristic_targets.keys():
		if characteristics == null:
			return false
		if int(characteristics.get_value(StringName(str(key)))) < int(plan.characteristic_targets[key]):
			return false
	var equipment: Variant = _equipment_service()
	var owned_outfits: int = 0
	if equipment != null:
		for outfit_id in plan.target_outfit_ids:
			if bool(equipment.owns_outfit(outfit_id)):
				owned_outfits += 1
	if owned_outfits < plan.target_outfit_count:
		return false
	var apartment: Variant = _apartment_service()
	var owned_objects: int = 0
	if apartment != null:
		for object_id in plan.target_apartment_object_ids:
			if bool(apartment.is_object_owned(object_id)):
				owned_objects += 1
	if owned_objects < plan.target_apartment_object_count:
		return false
	for venue_id in plan.venue_visit_goals:
		if not _visited_venues.has(String(venue_id)):
			return false
	return true

func _story_girl_max(plan: StagePlan) -> bool:
	if plan.story_girl_id == &"":
		return true
	return _girl_maxed(plan.story_girl_id)


func _update_goal_completion(plan: StagePlan, day_index: int) -> void:
	for girl_id in plan.target_filler_girl_ids:
		if _girl_maxed(girl_id):
			_complete_goal_both(_girl_goal(girl_id), day_index)
	if plan.story_girl_id != &"" and _girl_maxed(plan.story_girl_id):
		_complete_goal_both(_girl_goal(plan.story_girl_id, true), day_index)
	for rival_id in plan.target_ordinary_rival_ids:
		if is_rival_goal_complete(_rival_goal(rival_id), rival_id):
			_complete_goal_both(_rival_goal(rival_id), day_index)
	if plan.story_rival_id != &"" and is_rival_goal_complete(_story_rival_goal(plan.story_rival_id), plan.story_rival_id):
		_complete_goal_both(_story_rival_goal(plan.story_rival_id), day_index)
	var characteristics: Variant = _characteristic_service()
	for key in plan.characteristic_targets.keys():
		if characteristics != null and int(characteristics.get_value(StringName(str(key)))) >= int(plan.characteristic_targets[key]):
			var goal_id: String = _char_goal(StringName(str(key)), int(plan.characteristic_targets[key]))
			_complete_goal_both(goal_id, day_index)
			_record_build_acquisition_if_needed(plan, goal_id)
	var equipment: Variant = _equipment_service()
	for outfit_id in plan.target_outfit_ids:
		if equipment != null and bool(equipment.owns_outfit(outfit_id)):
			var goal_id: String = _outfit_goal(outfit_id)
			_complete_goal_both(goal_id, day_index)
			_record_build_acquisition_if_needed(plan, goal_id)
	if plan.stage >= 2 and _owns_dressed_outfit():
		_complete_goal_both("outfit:dressup", day_index)
	var apartment: Variant = _apartment_service()
	for object_id in plan.target_apartment_object_ids:
		if apartment != null and bool(apartment.is_object_owned(object_id)):
			var goal_id: String = _apartment_goal(object_id)
			_complete_goal_both(goal_id, day_index)
			_record_build_acquisition_if_needed(plan, goal_id)
func _capture_world() -> Dictionary:
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var economy: Variant = _economy_service()
	var equipment: Variant = _equipment_service()
	var apartment: Variant = _apartment_service()
	var rivals: Variant = _rivals_service()
	var world: Variant = _world_service()
	var stages: Variant = _stage_service()
	var characteristics: Variant = _characteristic_service()
	var girl_rel: Dictionary = {}
	var girl_tags: Dictionary = {}
	var girl_discovered: Dictionary = {}
	if girls != null:
		for definition in girls.get_catalog().get_all_girls():
			if definition == null:
				continue
			girl_rel[String(definition.id)] = int(girls.get_relationship(definition.id))
			var state: GirlState = girls.peek_state(definition.id)
			girl_discovered[String(definition.id)] = bool(girls.is_discovered(definition.id))
			var tags: PackedStringArray = PackedStringArray()
			if state != null:
				for tag_id in state.revealed_positive_tag_ids:
					tags.append(String(tag_id))
				for tag_id in state.revealed_negative_tag_ids:
					tags.append("-%s" % String(tag_id))
			girl_tags[String(definition.id)] = tags
	var rival_defeated: Dictionary = {}
	if rivals != null:
		for rival in rivals.get_catalog().get_all_rivals():
			if rival != null:
				rival_defeated[String(rival.id)] = bool(rivals.is_defeated(rival.id))
	var char_values: Dictionary = {}
	if characteristics != null:
		for characteristic_id in CharacteristicIds.all_ids():
			char_values[String(characteristic_id)] = int(characteristics.get_value(characteristic_id))
	var outfits: PackedStringArray = PackedStringArray()
	if equipment != null:
		for outfit in equipment.get_owned_outfits():
			if outfit != null:
				outfits.append(String(outfit.id))
	var objects: PackedStringArray = PackedStringArray()
	if apartment != null:
		for object_id in apartment.get_owned_object_ids():
			objects.append(String(object_id))
	var venues: PackedStringArray = PackedStringArray()
	if world != null:
		var world_state: WorldState = _game_state().world
		if world_state != null:
			for venue_id in world_state.unlocked_date_venue_ids:
				venues.append(String(venue_id))
	return {
		"rel": girl_rel,
		"tags": girl_tags,
		"discovered": girl_discovered,
		"rivals": rival_defeated,
		"chars": char_values,
		"outfits": outfits,
		"objects": objects,
		"venues": venues,
		"rating": int(rating.get_rating()) if rating != null else 0,
		"money": int(economy.get_money()) if economy != null else 0,
		"stage": int(stages.get_current_stage()) if stages != null else 1,
		"rewards": _reward_ids(),
		"career_rank": WorkService.get_career_rank(),
		"career_connections": WorkService.has_career_connections(),
	}


func _apply_world_diff(before: Dictionary, candidate: Candidate) -> int:
	var after: Dictionary = _capture_world()
	var beats: int = 0
	var rel_before: Dictionary = before["rel"]
	var rel_after: Dictionary = after["rel"]
	for key in rel_after.keys():
		if int(rel_after[key]) > int(rel_before.get(key, 0)):
			beats += 1
	var tags_before: Dictionary = before["tags"]
	var tags_after: Dictionary = after["tags"]
	for key in tags_after.keys():
		if tags_after[key] != tags_before.get(key, PackedStringArray()):
			beats += 1
	var chars_before: Dictionary = before["chars"]
	var chars_after: Dictionary = after["chars"]
	for key in chars_after.keys():
		if int(chars_after[key]) > int(chars_before.get(key, 0)):
			beats += 1
	if (after["outfits"] as PackedStringArray).size() > (before["outfits"] as PackedStringArray).size():
		beats += 1
	if (after["objects"] as PackedStringArray).size() > (before["objects"] as PackedStringArray).size():
		beats += 1
	var rivals_before: Dictionary = before["rivals"]
	var rivals_after: Dictionary = after["rivals"]
	for key in rivals_after.keys():
		if bool(rivals_after[key]) and not bool(rivals_before.get(key, false)):
			beats += 1
	if int(after["rating"]) > int(before["rating"]):
		beats += 1
	if int(after["stage"]) > int(before["stage"]):
		beats += 1
	if (after["venues"] as PackedStringArray).size() > (before["venues"] as PackedStringArray).size():
		beats += 1
	var discovered_before: Dictionary = before["discovered"]
	var discovered_after: Dictionary = after["discovered"]
	for key in discovered_after.keys():
		if bool(discovered_after[key]) and not bool(discovered_before.get(key, false)):
			beats += 1
	if (after["rewards"] as PackedStringArray).size() > (before["rewards"] as PackedStringArray).size():
		beats += 1
	if bool(after.get("career_connections", false)) and not bool(before.get("career_connections", false)):
		_mark_career_novelty("career:connections")
		var connections_day: int = _day_index() + 1
		var connections_stage: int = _current_story_stage()
		if _campaign != null:
			_campaign.record_career_connections_unlocked(connections_day, connections_stage)
		if _current_stage_metrics != null:
			_current_stage_metrics.record_career_connections_unlocked(connections_day, connections_stage)
	var rank_before: int = int(before.get("career_rank", 0))
	var rank_after: int = int(after.get("career_rank", 0))
	if rank_after > rank_before:
		beats += 1
		var calendar_day: int = _day_index() + 1
		var rank_stage: int = _current_story_stage()
		if _campaign != null:
			_campaign.record_career_rank_reached(rank_after, calendar_day, rank_stage)
		if _current_stage_metrics != null:
			_current_stage_metrics.record_career_rank_reached(rank_after, calendar_day, rank_stage)
		_mark_career_novelty("career:rank_%d" % rank_after)
		if rank_after >= _target_career_rank and _target_career_rank > 0:
			_target_career_rank = -1
	if candidate != null:
		pass
	return beats


func _reward_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	var girls: Variant = _girls_service()
	if girls == null:
		return ids
	var catalog: FillerRewardCatalog = girls.get_filler_reward_catalog()
	if catalog == null:
		return ids
	for reward in catalog.rewards:
		if reward != null and bool(girls.has_filler_reward(reward.id)):
			ids.append(String(reward.id))
	return ids


func _consider_owned_items_for_date(outfits: Dictionary, venue_id: StringName = &"") -> void:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return
	for outfit in equipment.get_owned_outfits():
		if outfit == null or outfit.id == OutfitCatalog.START_OUTFIT_ID:
			continue
		var entry: Dictionary = _ensure_item(String(outfit.id))
		entry["times_considered"] = int(entry["times_considered"]) + 1
		if String(outfits.get("outfit_id", "")) == String(outfit.id) or String(outfits.get("backup_outfit_id", "")) == String(outfit.id):
			entry["times_selected"] = int(entry["times_selected"]) + 1
	if venue_id != &"apartment":
		return
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return
	var dating: Variant = _dating_service()
	var catalog: DateContentCatalog = null
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null:
			catalog = catalog_service.catalog
	for object_id in apartment.get_owned_object_ids():
		if not _apartment_object_selectable(catalog, object_id):
			continue
		var entry: Dictionary = _ensure_item(String(object_id))
		entry["times_considered"] = int(entry["times_considered"]) + 1
func _apartment_object_selectable(catalog: DateContentCatalog, object_id: StringName) -> bool:
	if catalog == null or object_id == &"":
		return false
	if not _is_apartment_local_object(object_id):
		return false
	var local_object: DateLocalObject = catalog.find_local_object(object_id)
	if local_object == null or not local_object.enabled:
		return false
	var apartment: Variant = _apartment_service()
	var active_moves: Array[StringName] = []
	if apartment != null and apartment.has_method("get_active_local_move_ids"):
		active_moves = apartment.get_active_local_move_ids()
	for move_id in local_object.move_ids:
		var move: DateMove = catalog.find_move(move_id)
		if move == null or not move.enabled:
			continue
		if not active_moves.is_empty() and not active_moves.has(move_id):
			continue
		return true
	return false
func _log_story_barrier_hold(plan: StagePlan, girl_id: StringName, outfit_id: StringName, venue_id: StringName) -> void:
	if not detailed:
		return
	var girls: Variant = _girls_service()
	var rel: int = int(girls.get_relationship(girl_id)) if girls != null else 0
	var rel_max: int = int(girls.get_relationship_max(girl_id)) if girls != null else 0
	var gain: int = get_max_possible_relationship_gain({
		"girl_id": girl_id,
		"outfit_id": outfit_id,
		"venue_id": venue_id,
	})
	_log_line("Story Girl barrier hold")
	_log_line("Current Relationship: %d" % rel)
	_log_line("MAX: %d" % rel_max)
	_log_line("Max possible next-Date gain: %d" % gain)
	_log_line("Barrier complete: %s" % str(_barrier_complete(plan)))


func _remaining_date_goals(plan: StagePlan) -> int:
	if plan == null:
		return 0
	var count: int = 0
	for girl_id in plan.target_filler_girl_ids:
		if not _girl_maxed(girl_id):
			count += 1
	if plan.story_girl_id != &"" and not _girl_maxed(plan.story_girl_id):
		count += 1
	return count


func _future_use_opportunities(plan: StagePlan, goal_id: String) -> int:
	if plan == null or goal_id.is_empty():
		return 0
	var remaining_dates: int = _remaining_date_goals(plan)
	if goal_id.begins_with("characteristic:"):
		return remaining_dates + _remaining_rival_actions(plan)
	if goal_id.begins_with("outfit:"):
		return remaining_dates
	if goal_id.begins_with("apartment:"):
		var apartment_dates: int = 0
		if plan.story_girl_id != &"" and not _girl_maxed(plan.story_girl_id):
			apartment_dates += 1
		for girl_id in plan.target_filler_girl_ids:
			if not _girl_maxed(girl_id):
				apartment_dates += 1
		for venue_id in plan.venue_visit_goals:
			if String(venue_id) == "apartment" and not _visited_venues.has("apartment"):
				apartment_dates += 1
		return apartment_dates
	return 0


func _remaining_rival_actions(plan: StagePlan) -> int:
	if plan == null:
		return 0
	var count: int = 0
	for rival_id in plan.target_ordinary_rival_ids:
		if not is_rival_goal_complete(_rival_goal(rival_id), rival_id):
			count += 1
	if plan.story_rival_id != &"" and not is_rival_goal_complete(_story_rival_goal(plan.story_rival_id), plan.story_rival_id):
		count += 1
	return count


func _build_use_urgency_bonus(plan: StagePlan, goal_id: String) -> float:
	if _future_use_opportunities(plan, goal_id) <= 0:
		return 0.0
	var remaining: int = _remaining_date_goals(plan)
	return clampf(30.0 - 5.0 * float(maxi(remaining - 1, 0)), 0.0, 30.0)


func _apply_build_priority(base_priority: float, plan: StagePlan, goal_id: String, floor_when_urgent: float) -> float:
	var urgency: float = _build_use_urgency_bonus(plan, goal_id)
	var score: float = base_priority + urgency
	if _remaining_date_goals(plan) <= 2 and urgency > 0.0:
		score = maxf(score, floor_when_urgent)
	return score


func _record_stale_planned_goals(plan: StagePlan) -> void:
	if plan == null or _current_stage_metrics == null:
		return
	var campaign_day: int = _day_index() + 1
	var stage_day: int = maxi(campaign_day - _current_stage_metrics.stage_start_calendar_day + 1, 1)
	var characteristics: Variant = _characteristic_service()
	for key in plan.characteristic_targets.keys():
		var goal_id: String = _char_goal(StringName(str(key)), int(plan.characteristic_targets[key]))
		if characteristics != null and int(characteristics.get_value(StringName(str(key)))) >= int(plan.characteristic_targets[key]):
			continue
		if _future_use_opportunities(plan, goal_id) <= 0:
			_note_stale_planned_goal(goal_id, campaign_day, stage_day)
	var equipment: Variant = _equipment_service()
	for outfit_id in plan.target_outfit_ids:
		if equipment != null and bool(equipment.owns_outfit(outfit_id)):
			continue
		var outfit_goal: String = _outfit_goal(outfit_id)
		if _future_use_opportunities(plan, outfit_goal) <= 0:
			_note_stale_planned_goal(outfit_goal, campaign_day, stage_day)
	var apartment: Variant = _apartment_service()
	for object_id in plan.target_apartment_object_ids:
		if apartment != null and bool(apartment.is_object_owned(object_id)):
			continue
		var apt_goal: String = _apartment_goal(object_id)
		if _future_use_opportunities(plan, apt_goal) <= 0:
			_note_stale_planned_goal(apt_goal, campaign_day, stage_day)

func _note_stale_planned_goal(goal_id: String, campaign_day: int, stage_day: int) -> void:
	var before: int = _current_stage_metrics.stale_planned_goal_count if _current_stage_metrics != null else 0
	if _current_stage_metrics != null:
		_current_stage_metrics.record_stale_goal(goal_id, ProgressionLabMetrics.classify_goal_friction_type(goal_id), campaign_day, stage_day, "future_use_opportunities == 0")
	if _campaign != null:
		_campaign.record_stale_goal(goal_id, ProgressionLabMetrics.classify_goal_friction_type(goal_id), campaign_day, stage_day, "future_use_opportunities == 0")
	if _current_stage_metrics != null and _current_stage_metrics.stale_planned_goal_count > before:
		if not _hard_warnings.has("STALE_PLANNED_GOAL"):
			_hard_warnings.append("STALE_PLANNED_GOAL")


func _record_build_acquisition_if_needed(plan: StagePlan, goal_id: String) -> void:
	if plan == null or goal_id.is_empty() or _recorded_build_goals.has(goal_id):
		return
	if not (
		goal_id.begins_with("characteristic:")
		or goal_id.begins_with("outfit:acquire:")
		or goal_id.begins_with("apartment:acquire:")
	):
		return
	_recorded_build_goals[goal_id] = true
	var remaining_dates: int = _remaining_date_goals(plan)
	var future_use: int = _future_use_opportunities(plan, goal_id)
	var urgency: float = _build_use_urgency_bonus(plan, goal_id)
	var day_index: int = _day_index()
	if _current_stage_metrics != null:
		_current_stage_metrics.record_build_acquisition(goal_id, day_index, remaining_dates, future_use, urgency)
	if _campaign != null:
		_campaign.record_build_acquisition(goal_id, day_index, remaining_dates, future_use, urgency)


func resolve_item_source_from_move(move_id: StringName) -> Dictionary:
	var result: Dictionary = {
		"source_type": "",
		"source_id": "",
		"error": "",
	}
	if move_id == &"":
		result["error"] = "unknown"
		return result
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		result["error"] = "unknown"
		return result
	var outfit_matches: PackedStringArray = PackedStringArray()
	for outfit in catalog.outfits:
		if outfit != null and outfit.outfit_move_id == move_id:
			outfit_matches.append(String(outfit.id))
	if outfit_matches.size() > 1:
		result["error"] = "ambiguous"
		return result
	if outfit_matches.size() == 1:
		result["source_type"] = "OUTFIT"
		result["source_id"] = outfit_matches[0]
		return result
	var apartment_matches: PackedStringArray = PackedStringArray()
	for item in catalog.local_objects:
		if item == null or not item.move_ids.has(move_id):
			continue
		if not _is_apartment_local_object(item.id):
			continue
		apartment_matches.append(String(item.id))
	if apartment_matches.size() > 1:
		result["error"] = "ambiguous"
		return result
	if apartment_matches.size() == 1:
		result["source_type"] = "APARTMENT_OBJECT"
		result["source_id"] = apartment_matches[0]
		return result
	result["error"] = "unknown"
	return result

func _note_selected_source_moves(moves: PackedStringArray, run_result: DateRunResult) -> void:
	var episode_scores: Dictionary = {}
	if run_result != null and run_result.session != null:
		for episode in run_result.session.episode_history:
			if episode == null:
				continue
			episode_scores[String(episode.move_id)] = int(episode.score_delta)
	for move_id in moves:
		var source: Dictionary = resolve_item_source_from_move(StringName(move_id))
		var source_type: String = str(source.get("source_type", ""))
		var source_id: String = str(source.get("source_id", ""))
		if source_id.is_empty() or (source_type != "APARTMENT_OBJECT" and source_type != "OUTFIT"):
			continue
		if source_type == "OUTFIT" and source_id == String(OutfitCatalog.START_OUTFIT_ID):
			continue
		var entry: Dictionary = _ensure_item(source_id)
		if source_type == "APARTMENT_OBJECT":
			entry["times_selected"] = int(entry["times_selected"]) + 1
		var score_delta: int = int(episode_scores.get(str(move_id), 0))
		if source_type == "APARTMENT_OBJECT" and score_delta > 0:
			entry["times_produced_positive_score"] = int(entry["times_produced_positive_score"]) + 1
		if source_type == "APARTMENT_OBJECT":
			var catalog: DateContentCatalog = _date_catalog()
			var move: DateMove = catalog.find_move(StringName(move_id)) if catalog != null else null
			var unlocked: bool = move != null and move.unlock_requirement != null
			if not unlocked and run_result != null and run_result.session != null:
				for episode in run_result.session.episode_history:
					if episode != null and String(episode.move_id) == str(move_id) and bool(episode.revealed_tag):
						unlocked = true
						break
			if unlocked:
				entry["times_unlocked_requirement"] = int(entry["times_unlocked_requirement"]) + 1


func _date_catalog() -> DateContentCatalog:
	var dating: Variant = _dating_service()
	if dating == null:
		return null
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog

func _is_apartment_local_object(object_id: StringName) -> bool:
	if object_id == &"":
		return false
	if String(object_id).begins_with("apartment__"):
		return true
	var apartment: Variant = _apartment_service()
	if apartment != null and apartment.has_method("get_definition"):
		return apartment.get_definition(object_id) != null
	return false


func _note_item_use(outfit_id: StringName, run_result: DateRunResult) -> void:
	if outfit_id != &"" and outfit_id != OutfitCatalog.START_OUTFIT_ID:
		var entry: Dictionary = _ensure_item(String(outfit_id))
		if run_result != null and run_result.score_breakdown != null and run_result.score_breakdown.relationship_gain > 0:
			entry["times_produced_positive_score"] = int(entry["times_produced_positive_score"]) + 1
		if run_result != null and run_result.session != null and run_result.session.outfit_source_used:
			entry["times_unlocked_requirement"] = int(entry["times_unlocked_requirement"]) + 1


func _ensure_item(item_id: String) -> Dictionary:
	if _item_utility.has(item_id):
		return _item_utility[item_id]
	var entry: Dictionary = {
		"times_considered": 0,
		"times_selected": 0,
		"times_produced_positive_score": 0,
		"times_unlocked_requirement": 0,
		"acquired": false,
	}
	_item_utility[item_id] = entry
	return entry


func _owns_dressed_outfit() -> bool:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return false
	return bool(equipment.owns_dressed_outfit())


func _girl_maxed(girl_id: StringName) -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return bool(girls.is_relationship_completed(girl_id))


func _girl_requires_dressed(girl_id: StringName) -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if definition == null:
		return false
	for requirement in definition.date_requirements:
		if requirement is OutfitAboveCasualGirlRequirement:
			return true
	return false


func _estimated_date_cost(girl_id: StringName) -> int:
	var dating: Variant = _dating_service()
	if dating == null:
		return 0
	var cheapest: int = 0
	var found: bool = false
	for venue in dating.get_available_date_venues(girl_id):
		if venue == null:
			continue
		if not bool(dating.is_date_venue_available(girl_id, venue.id)):
			continue
		var price: int = int(venue.price)
		if not found or price < cheapest:
			cheapest = price
			found = true
	var taxi_cost: int = 0
	var girls: Variant = _girls_service()
	var daily: Variant = _daily_activity()
	if girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)):
		if daily != null and not bool(daily.is_available(daily.date_key(girl_id), 1)):
			taxi_cost = FillerRewardCatalog.RITA_TAXI_COST
	return cheapest + taxi_cost


func _upgrade_for(characteristic_id: StringName) -> CharacteristicUpgradeDefinition:
	var characteristics: Variant = _characteristic_service()
	if characteristics == null:
		return null
	var catalog: CharacteristicCatalog = characteristics.get_catalog()
	if catalog == null:
		return null
	var upgrades: Array[CharacteristicUpgradeDefinition] = catalog.get_upgrades_for_characteristic(characteristic_id)
	for upgrade in upgrades:
		if upgrade != null and bool(characteristics.can_buy_upgrade(upgrade.id)):
			return upgrade
	if not upgrades.is_empty():
		return upgrades[0]
	return null


func _shop_outfits_for_stage(stage: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return ids
	for outfit in equipment.get_shop_outfits():
		if outfit != null and outfit.min_story_stage == stage:
			ids.append(outfit.id)
	return ids


func _girl_goal(girl_id: StringName, is_story: bool = false) -> String:
	if is_story:
		return "story:max:%s" % String(girl_id)
	return "filler:max:%s" % String(girl_id)

func _rival_goal(rival_id: StringName) -> String:
	return "rival:engage:%s" % String(rival_id)

func _story_rival_goal(rival_id: StringName) -> String:
	return "story_rival:%s:defeat" % String(rival_id)


func _rival_goal_id(rival_id: StringName, is_story: bool) -> String:
	return _story_rival_goal(rival_id) if is_story else _rival_goal(rival_id)


func is_rival_goal_complete(_goal_id: String, rival_id: StringName) -> bool:
	var rivals: Variant = _rivals_service()
	return rivals != null and bool(rivals.is_defeated(rival_id))


func _rival_simulation_state(rival_id: StringName) -> String:
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return "LOCKED"
	var definition: RivalDefinition = rivals.get_definition(rival_id)
	if definition == null:
		return "LOCKED"
	if bool(rivals.is_defeated(rival_id)):
		return "DEFEATED"
	if not _rival_story_stage_available(definition):
		return "LOCKED"
	if definition.linked_girl_id != &"":
		var girls: Variant = _girls_service()
		if girls == null or not bool(girls.is_discovered(definition.linked_girl_id)):
			return "LOCKED"
	if not bool(rivals.is_discovered(rival_id)):
		if _production_available_to_meet(rival_id):
			return "AVAILABLE_TO_MEET"
		return "LOCKED"
	if bool(rivals.can_challenge_now(rival_id)):
		return "AVAILABLE_TO_CHALLENGE"
	return "DAILY_GATED"


func _production_available_to_meet(rival_id: StringName) -> bool:
	var rivals: Variant = _rivals_service()
	if rivals == null or bool(rivals.is_discovered(rival_id)):
		return false
	var definition: RivalDefinition = rivals.get_definition(rival_id)
	if definition == null or not _rival_story_stage_available(definition):
		return false
	if definition.linked_girl_id != &"":
		var girls: Variant = _girls_service()
		if girls == null or not bool(girls.is_discovered(definition.linked_girl_id)):
			return false
	var world: Variant = _world_service()
	if world == null:
		return false
	if world.get_current_location_id() == definition.location_id:
		return true
	return bool(world.can_enter_location(definition.location_id))


func _rival_story_stage_available(definition: RivalDefinition) -> bool:
	if definition == null:
		return false
	var stages: Variant = _stage_service()
	var story_stage: int = int(stages.get_current_stage()) if stages != null else 1
	return definition.minimum_story_stage <= story_stage

func _rival_diagnostic_row(rival_id: StringName, is_story: bool) -> Dictionary:
	var rivals: Variant = _rivals_service()
	var definition: RivalDefinition = rivals.get_definition(rival_id) if rivals != null else null
	var intent: Dictionary = evaluate_rival_intent(rival_id, is_story)
	var state: String = str(intent.get("production_state", _rival_simulation_state(rival_id)))
	var blocking_reason: String = str(intent.get("failure_code", ""))
	return {
		"rival_id": String(rival_id),
		"goal_id": str(intent.get("goal_id", _rival_goal_id(rival_id, is_story))),
		"goal_type": "story" if is_story else "ordinary",
		"discovered": rivals != null and bool(rivals.is_discovered(rival_id)),
		"defeated": rivals != null and bool(rivals.is_defeated(rival_id)),
		"production_state": state,
		"state": state,
		"production_available_to_meet": _production_available_to_meet(rival_id),
		"production_available_to_challenge": rivals != null and bool(rivals.can_challenge_now(rival_id)),
		"planned_action_type": str(intent.get("action_type", "")),
		"planned_action_id": str(intent.get("production_action_id", "")),
		"action_can_execute": bool(intent.get("production_available", false)) and int(intent.get("cash_gap", 0)) <= 0 and str(intent.get("failure_code", "")) == "",
		"action_failure_code": str(intent.get("failure_code", "")),
		"action_failure_reason": str(intent.get("production_failure_reason", "")),
		"required_money": int(intent.get("required_money", 0)),
		"current_money": int(intent.get("current_money", 0)),
		"cash_gap": int(intent.get("cash_gap", 0)),
		"daily_gate_used": state == "DAILY_GATED",
		"linked_girl_id": String(definition.linked_girl_id) if definition != null else "",
		"blocking_reason": blocking_reason,
	}

func _last_rival_goal_from_diagnostics(rival_availability: Dictionary) -> String:
	var last_goal: String = ""
	for rival_id in rival_availability.keys():
		var row: Variant = rival_availability[rival_id]
		if not (row is Dictionary):
			continue
		var data: Dictionary = row
		if bool(data.get("defeated", false)):
			continue
		last_goal = str(data.get("goal_id", ""))
		if str(data.get("action_failure_code", "")) == "INSUFFICIENT_MONEY":
			return last_goal
	return last_goal


func _last_rival_failure_from_diagnostics(rival_availability: Dictionary) -> String:
	var last_failure: String = ""
	for rival_id in rival_availability.keys():
		var row: Variant = rival_availability[rival_id]
		if not (row is Dictionary):
			continue
		var data: Dictionary = row
		var code: String = str(data.get("action_failure_code", ""))
		if code.is_empty():
			continue
		last_failure = code
		if code == "INSUFFICIENT_MONEY":
			return last_failure
	return last_failure

func _char_goal(characteristic_id: StringName, target: int) -> String:
	return "characteristic:%s:%d" % [String(characteristic_id), target]


func _outfit_goal(outfit_id: StringName) -> String:
	return "outfit:acquire:%s" % String(outfit_id)


func _apartment_goal(object_id: StringName) -> String:
	return "apartment:acquire:%s" % String(object_id)


func _venue_goal(venue_id: StringName) -> String:
	return "venue:visit:%s" % String(venue_id)


func _current_story_stage() -> int:
	var stages: Variant = _stage_service()
	if stages == null:
		return 1
	return int(stages.get_current_stage())


func _day_index() -> int:
	var clock: Variant = _time_service()
	if clock == null:
		return 0
	return int(clock.get_calendar_day_index())


func _ensure_day(day_index: int) -> void:
	if _current_day == day_index:
		return
	_flush_day()
	_current_day = day_index
	_day_had_successful_action = false
	_day_lines = PackedStringArray()
	if detailed:
		_day_lines.append("## Day %d" % (day_index + 1))


func _flush_day() -> void:
	if _current_day < 0:
		return
	if detailed and not _day_lines.is_empty():
		var economy: Variant = _economy_service()
		_day_lines.append("### End of day")
		_day_lines.append("Money: $%d" % (int(economy.get_money()) if economy != null else 0))
		_timeline.append_array(_day_lines)
		_daily_log.append({"day": _current_day + 1, "lines": Array(_day_lines)})
	_day_lines = PackedStringArray()


func _log_line(text: String) -> void:
	if detailed:
		_day_lines.append(text)


func _format_stage_plan(plan: StagePlan) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("## Stage %d Plan" % plan.stage)
	lines.append("Archetype: %s" % String(profile.archetype))
	lines.append("")
	lines.append("Filler:")
	for girl_id in plan.target_filler_girl_ids:
		lines.append("- %s: MAX" % _girl_name(girl_id))
	for girl_id in plan.skipped_filler_girl_ids:
		lines.append("- %s: skip" % _girl_name(girl_id))
	lines.append("")
	lines.append("Ordinary Rivals:")
	for rival_id in plan.target_ordinary_rival_ids:
		lines.append("- %s: engage" % String(rival_id))
	for rival_id in plan.skipped_ordinary_rival_ids:
		lines.append("- %s: skip" % String(rival_id))
	lines.append("")
	lines.append("Characteristics:")
	for key in plan.characteristic_targets.keys():
		lines.append("- %s → %s" % [str(key), str(plan.characteristic_targets[key])])
	lines.append("")
	lines.append("Outfits:")
	lines.append("- target count: %d" % plan.target_outfit_count)
	for outfit_id in plan.target_outfit_ids:
		lines.append("- %s" % String(outfit_id))
	lines.append("")
	lines.append("Apartment:")
	lines.append("- target count: %d" % plan.target_apartment_object_count)
	for object_id in plan.target_apartment_object_ids:
		lines.append("- %s" % String(object_id))
	lines.append("")
	lines.append("Venue exploration:")
	for venue_id in plan.venue_visit_goals:
		lines.append("- %s: visit" % String(venue_id))
	return "\n".join(lines)


func _girl_name(girl_id: StringName) -> String:
	var girls: Variant = _girls_service()
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return String(girl_id)


func _game_state() -> Variant:
	return _root_node("GameState")


func _action_service() -> Variant:
	return _root_node("ActionService")


func _girls_service() -> Variant:
	return _root_node("GirlsService")


func _dating_service() -> Variant:
	return _root_node("DatingService")


func _rivals_service() -> Variant:
	return _root_node("RivalsService")


func _competition_service() -> Variant:
	return _root_node("CompetitionService")


func _characteristic_service() -> Variant:
	return _root_node("CharacteristicService")


func _equipment_service() -> Variant:
	return _root_node("EquipmentService")


func _apartment_service() -> Variant:
	return _root_node("ApartmentService")


func _economy_service() -> Variant:
	return _root_node("EconomyService")


func _rating_service() -> Variant:
	return _root_node("RatingService")


func _world_service() -> Variant:
	return _root_node("WorldService")


func _stage_service() -> Variant:
	return _root_node("StageService")


func _time_service() -> Variant:
	return _root_node("TimeService")


func _daily_activity() -> Variant:
	return _root_node("DailyActivityService")


func _root_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func remaining_cash_need(plan: StagePlan) -> int:
	var rows: Array = _build_cash_dependencies(plan) if plan != null else []
	var seen: Dictionary = {}
	var total: int = 0
	for row in rows:
		if not (row is Dictionary):
			continue
		var goal_id: String = str(row.get("goal_id", ""))
		if goal_id.is_empty() or seen.has(goal_id):
			continue
		seen[goal_id] = true
		total += int(row.get("required_money", 0))
	return total


func evaluate_career_roi(plan: StagePlan) -> Dictionary:
	return _evaluate_career_roi(plan)


func _clear_career_commitment() -> void:
	_target_career_rank = -1
	_career_roi_day = -1
	_last_career_roi = {}


func _snapshot_career_start(metrics: ProgressionLabMetrics) -> void:
	if metrics == null:
		return
	metrics.career_rank_start = WorkService.get_career_rank()
	metrics.work_income_start = WorkService.get_current_shift_income()


func _snapshot_career_end(metrics: ProgressionLabMetrics) -> void:
	if metrics == null:
		return
	metrics.career_rank_end = WorkService.get_career_rank()
	metrics.work_income_end = WorkService.get_current_shift_income()


func _format_career_state(heading: String) -> String:
	var gs: Variant = _game_state()
	var connections: bool = WorkService.has_career_connections(gs)
	var rank: int = WorkService.get_career_rank(gs)
	var income: int = WorkService.get_current_shift_income(gs)
	var next_rank: int = WorkService.get_next_career_rank(gs)
	var next_requirement: String = str(WorkService.get_next_career_capital_requirement(gs)) if next_rank >= 0 else "-"
	var next_income: String = ("$%d" % WorkService.get_next_career_income(gs)) if next_rank >= 0 else "-"
	return "%s\nCareer Connections: %s\nCareer Rank: %d\nCurrent Work income: $%d\nNext Career requirement: %s\nNext Career income: %s" % [
		heading,
		str(connections),
		rank,
		income,
		next_requirement,
		next_income,
	]


func _career_goal_id(rank: int) -> String:
	return "career:rank_%d" % rank


func _plan_capital_target(plan: StagePlan) -> int:
	if plan == null:
		return 0
	var best: int = 0
	for key in plan.characteristic_targets.keys():
		if String(key) == String(CharacteristicIds.CAPITAL):
			best = maxi(best, int(plan.characteristic_targets[key]))
	return best


func _capital_training_price() -> int:
	var characteristics: Variant = _characteristic_service()
	if characteristics != null:
		return int(characteristics.get_cost_per_level(CharacteristicIds.CAPITAL))
	return CharacteristicCatalog.SEED_PRICE


func _ceil_div(numerator: int, denominator: int) -> int:
	if numerator <= 0:
		return 0
	if denominator <= 0:
		return 0
	return int(ceili(float(numerator) / float(denominator)))


func _highest_cash_blocked_priority() -> float:
	var highest: float = 0.0
	for row in _cash_dependencies:
		if row is Dictionary:
			highest = maxf(highest, float(row.get("priority", 0.0)))
	return highest


func _career_score_base(saved_support_actions: int) -> float:
	return _highest_cash_blocked_priority() + 10.0 + 5.0 * float(mini(maxi(saved_support_actions, 0), 4))


func _evaluate_career_roi(plan: StagePlan, apply_noise: bool = true) -> Dictionary:
	var gs: Variant = _game_state()
	var rank_before: int = WorkService.get_career_rank(gs)
	var rank_after: int = WorkService.get_next_career_rank(gs)
	var current_income: int = WorkService.get_current_shift_income(gs)
	var new_income: int = WorkService.get_next_career_income(gs)
	var remaining: int = remaining_cash_need(plan)
	var economy: Variant = _economy_service()
	var current_money: int = int(economy.get_money()) if economy != null else 0
	var required_capital: int = WorkService.get_next_career_capital_requirement(gs)
	var characteristics: Variant = _characteristic_service()
	var current_capital: int = int(characteristics.get_value(CharacteristicIds.CAPITAL)) if characteristics != null else 0
	var capital_actions: int = maxi(0, required_capital - current_capital)
	var capital_cost: int = capital_actions * _capital_training_price()
	var work_without: int = _ceil_div(maxi(remaining - current_money, 0), current_income)
	var work_with: int = _ceil_div(maxi(remaining + capital_cost - current_money, 0), new_income)
	var economic_with: int = capital_actions + 1 + work_with
	var saved: int = work_without - economic_with
	var planning_skill: float = profile.planning_skill if profile != null else 1.0
	var amplitude: float = 2.0 * (1.0 - planning_skill)
	var perceived: float = float(saved)
	if apply_noise and _execution_rng != null:
		perceived += _execution_rng.randf_range(-amplitude, amplitude)
	var decision: String = "INVEST" if perceived > 0.0 else "SKIP_FOR_NOW"
	return {
		"career_rank_before": rank_before,
		"career_rank_after": rank_after,
		"current_income": current_income,
		"new_income": new_income,
		"remaining_cash_need": remaining,
		"work_actions_without_upgrade": work_without,
		"economic_support_actions_with_upgrade": economic_with,
		"saved_support_actions": saved,
		"perceived_saved_support_actions": perceived,
		"decision": decision,
	}


func _log_career_roi(roi: Dictionary) -> void:
	if not detailed or roi.is_empty():
		return
	_log_line("### CAREER ROI")
	_log_line("career_rank_before: %s" % str(roi.get("career_rank_before", 0)))
	_log_line("career_rank_after: %s" % str(roi.get("career_rank_after", 0)))
	_log_line("current_income: %s" % str(roi.get("current_income", 0)))
	_log_line("new_income: %s" % str(roi.get("new_income", 0)))
	_log_line("remaining_cash_need: %s" % str(roi.get("remaining_cash_need", 0)))
	_log_line("work_actions_without_upgrade: %s" % str(roi.get("work_actions_without_upgrade", 0)))
	_log_line("economic_support_actions_with_upgrade: %s" % str(roi.get("economic_support_actions_with_upgrade", 0)))
	_log_line("saved_support_actions: %s" % str(roi.get("saved_support_actions", 0)))
	_log_line("perceived_saved_support_actions: %s" % str(roi.get("perceived_saved_support_actions", 0.0)))
	_log_line("decision: %s" % str(roi.get("decision", "")))


func _sync_career_commitment() -> void:
	if _target_career_rank < 0:
		return
	var gs: Variant = _game_state()
	if WorkService.get_career_rank(gs) >= _target_career_rank:
		_target_career_rank = -1
		return
	var next_rank: int = WorkService.get_next_career_rank(gs)
	if next_rank < 0:
		_target_career_rank = -1
		return
	if WorkService.next_rank_requires_connections(gs) and not WorkService.has_career_connections(gs):
		_target_career_rank = -1


func _refresh_career_decision(plan: StagePlan) -> void:
	_sync_career_commitment()
	if _target_career_rank > 0:
		return
	var day_index: int = _day_index()
	if day_index == _career_roi_day:
		return
	_career_roi_day = day_index
	_last_career_lock_diagnostics = {}
	var gs: Variant = _game_state()
	var next_rank: int = WorkService.get_next_career_rank(gs)
	if next_rank < 0:
		_last_career_roi = {}
		return
	if WorkService.next_rank_requires_connections(gs) and not WorkService.has_career_connections(gs):
		_last_career_roi = {}
		_note_career_connections_lock(plan, gs, next_rank)
		return
	_last_career_roi = _evaluate_career_roi(plan)
	_log_career_roi(_last_career_roi)
	if str(_last_career_roi.get("decision", "")) == "INVEST":
		_target_career_rank = int(_last_career_roi.get("career_rank_after", 0))

func _note_career_connections_lock(plan: StagePlan, gs: Variant, next_rank: int) -> void:
	var required_capital: int = WorkService.get_next_career_capital_requirement(gs)
	var mine_boss_id: StringName = &"girl_mine_boss"
	var mine_boss_name: String = _girl_name(mine_boss_id)
	var reward_id: String = String(FillerRewardCatalog.ID_CAREER_CONNECTIONS)
	var source: String = "%s / %s / %s" % [String(mine_boss_id), mine_boss_name, reward_id]
	var diagnostics: Dictionary = {
		"target_rank": next_rank,
		"capital_requirement": required_capital,
		"connections_requirement": true,
		"mine_boss_reward_source": source,
		"decision": "LOCKED_CONNECTIONS",
	}
	var dependency: String = ""
	if next_rank == 2 and _plan_has_mine_boss(plan) and _career_upgrade_saved_actions(plan) > 0:
		dependency = "Career dependency:\nRank 2\n→ Career Connections\n→ Mine Boss relationship reward"
		diagnostics["career_dependency"] = dependency
	_last_career_lock_diagnostics = diagnostics
	if not detailed:
		return
	_log_line("### CAREER CONNECTIONS LOCK")
	_log_line("target rank: %d" % next_rank)
	_log_line("Capital requirement: %s" % str(required_capital))
	_log_line("Connections requirement: true")
	_log_line("Mine Boss reward source: %s" % source)
	if not dependency.is_empty():
		_log_line(dependency)


func _plan_has_mine_boss(plan: StagePlan) -> bool:
	if plan == null:
		return false
	return plan.target_filler_girl_ids.has(&"girl_mine_boss")


func _career_upgrade_saved_actions(plan: StagePlan) -> int:
	return int(_evaluate_career_roi(plan, false).get("saved_support_actions", 0))


func _add_career_candidates(candidates: Array, plan: StagePlan) -> void:
	_refresh_career_decision(plan)
	if _target_career_rank <= 0:
		return
	var gs: Variant = _game_state()
	if WorkService.next_rank_requires_connections(gs) and not WorkService.has_career_connections(gs):
		return
	var rank: int = WorkService.get_career_rank(gs)
	if rank >= _target_career_rank:
		_target_career_rank = -1
		return
	var required_capital: int = WorkService.get_next_career_capital_requirement(gs)
	var characteristics: Variant = _characteristic_service()
	var current_capital: int = int(characteristics.get_value(CharacteristicIds.CAPITAL)) if characteristics != null else 0
	var saved: int = int(_last_career_roi.get("saved_support_actions", 0))
	var base: float = _career_score_base(saved)
	var goal_id: String = _career_goal_id(_target_career_rank)
	var novel: bool = not _seen.has("career:rank_%d" % _target_career_rank)
	var plan_covers_capital: bool = _plan_capital_target(plan) >= required_capital
	if WorkService.can_advance_career(gs):
		var advance := Candidate.new()
		advance.category = "CAREER"
		advance.kind = "career_advancement"
		advance.goal_id = goal_id
		advance.content_id = "career_advancement:%d" % _target_career_rank
		advance.uses_daily_gate = true
		advance.unblocks_higher = true
		advance.is_novel = novel
		advance.score = _score(base, true, true, novel, advance.content_id)
		candidates.append(advance)
		return
	if current_capital >= required_capital:
		return
	if plan_covers_capital:
		return
	var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(CharacteristicIds.CAPITAL)
	if upgrade == null or characteristics == null:
		return
	var train_action: GameAction = characteristics.create_upgrade_action(upgrade.id)
	var actions: Variant = _action_service()
	if actions != null and bool(actions.can_execute(train_action)):
		var train := Candidate.new()
		train.category = "TRAINING"
		train.kind = "train"
		train.is_support = true
		train.upgrade_id = upgrade.id
		train.goal_id = goal_id
		train.content_id = "career_train:capital"
		train.uses_daily_gate = true
		train.unblocks_higher = true
		train.is_novel = novel
		train.score = _score(base, true, true, novel, train.content_id)
		candidates.append(train)
		return
	var economy: Variant = _economy_service()
	var money: int = int(economy.get_money()) if economy != null else 0
	if money >= upgrade.price:
		return
	if not WorkService.is_work_available_today() and not WorkService.is_overtime_available_today():
		return
	var work := Candidate.new()
	work.category = "WORK"
	work.kind = "work"
	work.is_support = true
	work.goal_id = goal_id
	work.action_id = "work"
	work.supporting_action_id = "characteristic:capital:%d" % required_capital
	work.required_money = upgrade.price
	work.cash_before = money
	work.cash_gap = maxi(upgrade.price - money, 0)
	work.cash_needed = work.cash_gap
	work.content_id = "work:career:%d" % _target_career_rank
	work.uses_daily_gate = true
	work.unblocks_higher = true
	var work_offset: float = config.work_priority_offset if config != null else 5.0
	work.score = _score(base - work_offset, true, true, false, work.content_id)
	candidates.append(work)


func _exec_career_advancement(candidate: Candidate) -> bool:
	var actions: Variant = _action_service()
	if actions == null:
		return false
	var action: GameAction = WorkService.create_career_advancement_action()
	var result: ActionResult = actions.execute(action)
	if result == null or not result.success:
		return false
	_campaign.career_advancement_actions += 1
	_current_stage_metrics.career_advancement_actions += 1
	_log_line("### CAREER ADVANCEMENT")
	_log_line("Goal: %s" % candidate.goal_id)
	_log_line("Career Rank: %d" % WorkService.get_career_rank())
	_log_line("Current Work income: $%d" % WorkService.get_current_shift_income())
	return true


func _mark_career_novelty(key: String) -> void:
	if key.is_empty() or _seen.has(key):
		return
	_seen[key] = true
	if _campaign != null:
		_campaign.novelty_events += 1
	if _current_stage_metrics != null:
		_current_stage_metrics.novelty_events += 1
