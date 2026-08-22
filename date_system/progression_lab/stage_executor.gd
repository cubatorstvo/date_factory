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
	var urgent_taxi: bool = false
	var express_styling: bool = false
	var backup_outfit_id: StringName = &""
	var uses_daily_gate: bool = false
	var unblocks_higher: bool = false
	var is_novel: bool = false


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
	_date_policy.plan = plan
	_plan_hashes[stage] = plan.generation_hash
	_stage_plans.append(plan.to_dict())
	_current_stage_metrics = ProgressionLabMetrics.new()
	_stage_metrics[stage] = _current_stage_metrics
	var rating: Variant = _rating_service()
	_current_stage_metrics.rating_start = int(rating.get_rating()) if rating != null else 0
	if detailed:
		_timeline.append(_format_stage_plan(plan))
	var idle_skips: int = 0
	var stall: int = 0
	var blocked: Dictionary = {}
	while _current_story_stage() == stage and not _aborted:
		var clock: Variant = _time_service()
		var day_index: int = int(clock.get_calendar_day_index()) if clock != null else 0
		if day_index >= config.max_calendar_days:
			_hard_warnings.append("SAFETY_CAP_DAYS")
			_aborted = true
			break
		if _action_sequence.size() >= MAX_ACTIONS_PER_RUN:
			_hard_warnings.append("SAFETY_CAP_ACTIONS")
			_aborted = true
			break
		_ensure_day(day_index)
		if _barrier_complete(plan) and _story_girl_max(plan):
			var stages: Variant = _stage_service()
			if stages != null:
				stages.try_complete_current_stage()
			if _current_story_stage() != stage:
				break
		_date_policy.consume_rng = false
		var candidates: Array = []
		for raw in _collect_candidates(plan):
			if raw == null:
				continue
			var candidate: Candidate = raw
			var block_key: String = "%s:%s" % [candidate.kind, candidate.content_id]
			if blocked.has(block_key):
				continue
			candidates.append(candidate)
		_date_policy.consume_rng = true
		candidates.sort_custom(func(a: Candidate, b: Candidate) -> bool:
			return a.content_id < b.content_id
		)
		if candidates.is_empty():
			_skip_day()
			blocked.clear()
			stall = 0
			idle_skips += 1
			if idle_skips >= 8:
				_hard_warnings.append("NO_USEFUL_ACTIONS_STAGE_%d" % stage)
				_aborted = true
				break
			continue
		idle_skips = 0
		var chosen: Candidate = _pick_candidate(candidates)
		var executed: bool = _execute_candidate(chosen, plan)
		if not executed:
			if chosen != null:
				blocked["%s:%s" % [chosen.kind, chosen.content_id]] = true
			stall += 1
			if stall >= 12:
				_skip_day()
				blocked.clear()
				stall = 0
				idle_skips += 1
				if idle_skips >= 8:
					_hard_warnings.append("NO_USEFUL_ACTIONS_STAGE_%d" % stage)
					_aborted = true
					break
			continue
		stall = 0
		blocked.clear()
	if plan.content_hash() != str(_plan_hashes.get(stage, "")):
		_hard_warnings.append("STAGE_PLAN_MUTATED_%d" % stage)
	var economy: Variant = _economy_service()
	var end_clock: Variant = _time_service()
	_current_stage_metrics.finalize_days(
		int(end_clock.get_calendar_day_index()) if end_clock != null else 0,
		int(economy.get_money()) if economy != null else 0,
		int(rating.get_rating()) if rating != null else 0
	)
	if target_stage >= 0:
		pass


func _collect_candidates(plan: StagePlan) -> Array:
	var candidates: Array = []
	var barrier_done: bool = _barrier_complete(plan)
	_count_blocks(plan)
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
	return candidates


func _count_blocks(plan: StagePlan) -> void:
	var daily: Variant = _daily_activity()
	var economy: Variant = _economy_service()
	var money: int = int(economy.get_money()) if economy != null else 0
	for girl_id in plan.target_filler_girl_ids:
		if _girl_maxed(girl_id):
			continue
		if daily != null and not bool(daily.is_available(daily.date_key(girl_id), 1)):
			_campaign.daily_gate_blocked_decision_points += 1
			_current_stage_metrics.daily_gate_blocked_decision_points += 1
			var friction: Dictionary = _campaign.ensure_goal(_girl_goal(girl_id))
			friction["blocked_by_daily_gate_count"] = int(friction["blocked_by_daily_gate_count"]) + 1
		var date_cost: int = _estimated_date_cost(girl_id)
		if date_cost > money:
			_campaign.money_blocked_decision_points += 1
			_current_stage_metrics.money_blocked_decision_points += 1
			var money_friction: Dictionary = _campaign.ensure_goal(_girl_goal(girl_id))
			money_friction["blocked_by_money_count"] = int(money_friction["blocked_by_money_count"]) + 1
	for characteristic_id in plan.characteristic_targets.keys():
		var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(StringName(str(characteristic_id)))
		if upgrade == null:
			continue
		if daily != null and not bool(daily.is_available("characteristic_training", 1)):
			_campaign.daily_gate_blocked_decision_points += 1
			_current_stage_metrics.daily_gate_blocked_decision_points += 1
		if upgrade.price > money:
			_campaign.money_blocked_decision_points += 1
			_current_stage_metrics.money_blocked_decision_points += 1
			var char_friction: Dictionary = _campaign.ensure_goal(_char_goal(StringName(str(characteristic_id)), int(plan.characteristic_targets[characteristic_id])))
			char_friction["blocked_by_money_count"] = int(char_friction["blocked_by_money_count"]) + 1


func _add_girl_candidates(candidates: Array, plan: StagePlan, girl_id: StringName, priority: float, category: String) -> void:
	var girls: Variant = _girls_service()
	if girls == null or girls.get_definition(girl_id) == null:
		return
	if _girl_maxed(girl_id):
		return
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if not bool(girls.is_discovered(girl_id)):
		if bool(girls.can_meet_girl(girl_id)):
			var meet := Candidate.new()
			meet.category = category
			meet.kind = "meet"
			meet.girl_id = girl_id
			meet.location_id = definition.location_id
			meet.goal_id = _girl_goal(girl_id)
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
					travel.goal_id = _girl_goal(girl_id)
					travel.content_id = "meet:%s" % String(girl_id)
					travel.score = _score(priority, false, true, not _seen.has("girl:%s" % String(girl_id)), travel.content_id)
					candidates.append(travel)
		return
	var dating: Variant = _dating_service()
	if dating == null:
		return
	var urgent_taxi: bool = false
	if not bool(dating.can_start_date(girl_id)):
		if bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)) and str(dating.get_start_date_failure_reason(girl_id)).find("Сегодня") >= 0:
			urgent_taxi = true
		else:
			return
	if not urgent_taxi and not bool(dating.can_start_date(girl_id)):
		return
	if plan.stage >= 2 and not _owns_dressed_outfit() and _girl_requires_dressed(girl_id):
		return
	var venue_id: StringName = _date_policy.choose_venue(girl_id)
	var outfits: Dictionary = _date_policy.choose_outfits(girl_id, venue_id)
	var outfit_id: StringName = outfits["outfit_id"]
	var backup_id: StringName = outfits["backup_outfit_id"]
	var express: bool = bool(girls.has_filler_reward(FillerRewardCatalog.ID_KIRA_EXPRESS_STYLING))
	var action: GameAction = dating.create_start_date_action(girl_id, venue_id, outfit_id, {
		"backup_outfit_id": backup_id,
		"express_styling": express,
		"urgent_taxi": urgent_taxi,
	})
	var actions: Variant = _action_service()
	if actions == null or not bool(actions.can_execute(action)):
		var reason: String = str(actions.get_failure_reason(action)) if actions != null else ""
		if reason.find("денег") >= 0 or reason.find("денег") >= 0:
			return
		if not bool(actions.can_execute(action)):
			return
	if venue_id == &"apartment":
		var apartment: Variant = _apartment_service()
		if apartment != null and not bool(apartment.is_prepared()):
			var prep := Candidate.new()
			prep.category = "APARTMENT_PREPARATION"
			prep.kind = "clean"
			prep.goal_id = _girl_goal(girl_id)
			prep.is_support = true
			prep.content_id = "clean"
			prep.unblocks_higher = true
			prep.score = _score(priority, false, true, false, prep.content_id)
			candidates.append(prep)
	_consider_owned_items_for_date(outfits)
	var date := Candidate.new()
	date.category = category
	date.kind = "date"
	date.girl_id = girl_id
	date.venue_id = venue_id
	date.outfit_id = outfit_id
	date.backup_outfit_id = backup_id
	date.express_styling = express
	date.urgent_taxi = urgent_taxi
	date.goal_id = _girl_goal(girl_id)
	date.content_id = "date:%s:%s" % [String(girl_id), String(venue_id)]
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


func _add_rival_candidates(candidates: Array, _plan: StagePlan, rival_id: StringName, priority: float, is_story: bool) -> void:
	var rivals: Variant = _rivals_service()
	var competitions: Variant = _competition_service()
	if rivals == null or competitions == null:
		return
	if bool(rivals.is_defeated(rival_id)) and not bool(rivals.is_repeatable_rival(rival_id)):
		return
	var definition: RivalDefinition = rivals.get_definition(rival_id)
	if definition == null:
		return
	if not bool(rivals.is_discovered(rival_id)):
		var meet := Candidate.new()
		meet.category = "RIVAL" if not is_story else "STORY"
		meet.kind = "rival_meet"
		meet.rival_id = rival_id
		meet.location_id = definition.location_id
		meet.goal_id = _rival_goal(rival_id)
		meet.content_id = "rival_meet:%s" % String(rival_id)
		meet.is_novel = not _seen.has("rival:%s" % String(rival_id))
		meet.score = _score(priority, false, true, meet.is_novel, meet.content_id)
		candidates.append(meet)
		return
	if not bool(rivals.can_challenge_now(rival_id)):
		_campaign.daily_gate_blocked_decision_points += 1
		_current_stage_metrics.daily_gate_blocked_decision_points += 1
		return
	var list: Array = competitions.get_competitions_for_rival(rival_id)
	if list.is_empty():
		return
	var competition: CompetitionDefinition = list[0]
	var action: GameAction = competitions.create_competition_action(competition.id)
	var actions: Variant = _action_service()
	if actions == null:
		return
	if not bool(actions.can_execute(action)):
		var reason: String = str(actions.get_failure_reason(action))
		if reason.find("денег") >= 0:
			return
		if reason.find("локац") >= 0:
			pass
		else:
			return
	var fight := Candidate.new()
	fight.category = "RIVAL" if not is_story else "STORY"
	fight.kind = "rival_fight"
	fight.rival_id = rival_id
	fight.competition_id = competition.id
	fight.location_id = definition.location_id
	fight.goal_id = _rival_goal(rival_id)
	fight.content_id = "rival:%s" % String(rival_id)
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
		train.score = _score(config.priority_characteristic, true, false, false, train.content_id)
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
		buy.score = _score(config.priority_apartment, false, false, buy.is_novel, buy.content_id)
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


func _add_work_candidates(candidates: Array, plan: StagePlan, existing: Array) -> void:
	var blocked: Array = _cash_blocked_goals(plan, existing)
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
	work.goal_id = str(top["goal_id"])
	work.content_id = "work"
	work.uses_daily_gate = true
	work.score = _score(float(top["priority"]) - config.work_priority_offset, true, false, false, work.content_id)
	candidates.append(work)


func _cash_blocked_goals(plan: StagePlan, existing: Array) -> Array:
	var blocked: Array = []
	var economy: Variant = _economy_service()
	var money: int = int(economy.get_money()) if economy != null else 0
	for girl_id in plan.target_filler_girl_ids:
		if _girl_maxed(girl_id):
			continue
		var cost: int = _estimated_date_cost(girl_id)
		if cost > money:
			blocked.append({"goal_id": _girl_goal(girl_id), "priority": config.priority_filler_date, "needed": cost})
	for key in plan.characteristic_targets.keys():
		var upgrade: CharacteristicUpgradeDefinition = _upgrade_for(StringName(str(key)))
		if upgrade != null and upgrade.price > money:
			blocked.append({"goal_id": _char_goal(StringName(str(key)), int(plan.characteristic_targets[key])), "priority": config.priority_characteristic, "needed": upgrade.price})
	for outfit_id in plan.target_outfit_ids:
		var equipment: Variant = _equipment_service()
		if equipment != null and not bool(equipment.owns_outfit(outfit_id)):
			var price: int = int(equipment.get_effective_outfit_price(outfit_id))
			if price > money:
				blocked.append({"goal_id": _outfit_goal(outfit_id), "priority": config.priority_outfit, "needed": price})
	if plan.stage >= 2:
		var dress_equipment: Variant = _equipment_service()
		if dress_equipment != null and not bool(dress_equipment.owns_dressed_outfit()):
			for outfit_id in _shop_outfits_for_stage(plan.stage):
				var dress_price: int = int(dress_equipment.get_effective_outfit_price(outfit_id))
				if dress_price > money:
					blocked.append({"goal_id": "outfit:dressup", "priority": config.priority_dress_up, "needed": dress_price})
					break
	for object_id in plan.target_apartment_object_ids:
		var apartment: Variant = _apartment_service()
		if apartment != null and not bool(apartment.is_object_owned(object_id)):
			var item: ApartmentObjectDefinition = apartment.get_catalog().get_object(object_id)
			if item != null and item.price > money:
				blocked.append({"goal_id": _apartment_goal(object_id), "priority": config.priority_apartment, "needed": item.price})
	if existing.is_empty():
		pass
	return blocked


func _pick_candidate(candidates: Array) -> Candidate:
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


func _score(priority: float, daily_gate: bool, unblock: bool, novel: bool, content_id: String) -> float:
	var score: float = priority
	if daily_gate:
		score += config.daily_gate_bonus
	if unblock:
		score += config.unblock_bonus
	if novel:
		score += config.novelty_bonus
	var consecutive: int = _campaign.consecutive_same_count()
	score -= config.repetition_penalty_per_step * float(consecutive)
	if content_id.is_empty():
		pass
	return score


func _execute_candidate(candidate: Candidate, plan: StagePlan) -> bool:
	if candidate == null:
		return false
	if candidate.location_id != &"":
		var world: Variant = _world_service()
		if world != null and world.get_current_location_id() != candidate.location_id:
			world.enter_location(candidate.location_id)
	var before: Dictionary = _capture_world()
	var day_index: int = _day_index()
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
		_:
			ok = false
	if not ok:
		return false
	var beats: int = _apply_world_diff(before, candidate)
	_campaign.record_primary(candidate.category, day_index, beats)
	_current_stage_metrics.record_primary(candidate.category, day_index, beats)
	_campaign.record_goal_action(candidate.goal_id, candidate.is_support, day_index)
	_current_stage_metrics.record_goal_action(candidate.goal_id, candidate.is_support, day_index)
	_action_sequence.append("%s|%s|%s" % [candidate.category, candidate.kind, candidate.content_id])
	_update_goal_completion(plan, day_index)
	return true


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


func _exec_date(candidate: Candidate, plan: StagePlan) -> bool:
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	if dating == null or actions == null:
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
	if candidate.backup_outfit_id != &"":
		_campaign.set_flag("nika_backup")
	if candidate.venue_id == &"restaurant":
		_campaign.set_flag("restaurant_date")
		if engine != null and engine.get_session_state() != null and engine.get_session_state().venue_source_limit >= 2:
			_campaign.set_flag("sonya_venue_x2")
		if engine != null and engine.get_session_state() != null and engine.get_session_state().characteristic_source_used:
			_campaign.set_flag("restaurant_characteristic_unlock")
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
		_campaign.complete_goal(_venue_goal(candidate.venue_id), _day_index())
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
	_campaign.money_spent += action.money_cost
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
	_campaign.money_spent += action.money_cost
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
	_campaign.money_spent += action.money_cost
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
	competitions.set_forced_won(null)
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
	_campaign.set_flag("used_production_rival")
	_seen["rival:%s" % String(candidate.rival_id)] = true
	_log_line("### RIVAL %s %s" % [String(candidate.rival_id), "win" if won else "loss"])
	return true


func _exec_work(candidate: Candidate) -> bool:
	var actions: Variant = _action_service()
	if actions == null:
		return false
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
	_campaign.work_actions += 1
	_current_stage_metrics.work_actions += 1
	_campaign.money_earned += maxi(0, money_after - money_before)
	_campaign.set_flag("used_production_work")
	_log_line("### WORK")
	_log_line("Goal support: %s" % candidate.goal_id)
	_log_line("Money: $%d → $%d" % [money_before, money_after])
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


func _barrier_complete(plan: StagePlan) -> bool:
	if plan.stage >= 2 and not _owns_dressed_outfit():
		return false
	for girl_id in plan.target_filler_girl_ids:
		if not _girl_maxed(girl_id):
			return false
	for rival_id in plan.target_ordinary_rival_ids:
		if _rivals_service() != null and not bool(_rivals_service().is_defeated(rival_id)):
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
			_campaign.complete_goal(_girl_goal(girl_id), day_index)
	if plan.story_girl_id != &"" and _girl_maxed(plan.story_girl_id):
		_campaign.complete_goal(_girl_goal(plan.story_girl_id), day_index)
	for rival_id in plan.target_ordinary_rival_ids:
		if _rivals_service() != null and bool(_rivals_service().is_defeated(rival_id)):
			_campaign.complete_goal(_rival_goal(rival_id), day_index)
	if plan.story_rival_id != &"" and _rivals_service() != null and bool(_rivals_service().is_defeated(plan.story_rival_id)):
		_campaign.complete_goal(_rival_goal(plan.story_rival_id), day_index)
	var characteristics: Variant = _characteristic_service()
	for key in plan.characteristic_targets.keys():
		if characteristics != null and int(characteristics.get_value(StringName(str(key)))) >= int(plan.characteristic_targets[key]):
			_campaign.complete_goal(_char_goal(StringName(str(key)), int(plan.characteristic_targets[key])), day_index)
	var equipment: Variant = _equipment_service()
	for outfit_id in plan.target_outfit_ids:
		if equipment != null and bool(equipment.owns_outfit(outfit_id)):
			_campaign.complete_goal(_outfit_goal(outfit_id), day_index)
	if plan.stage >= 2 and _owns_dressed_outfit():
		_campaign.complete_goal("outfit:dressup", day_index)
	var apartment: Variant = _apartment_service()
	for object_id in plan.target_apartment_object_ids:
		if apartment != null and bool(apartment.is_object_owned(object_id)):
			_campaign.complete_goal(_apartment_goal(object_id), day_index)


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
	var money_after: int = int(after["money"])
	_campaign.minimum_money = mini(_campaign.minimum_money, money_after) if _campaign.total_actions > 0 else money_after
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


func _consider_owned_items_for_date(outfits: Dictionary) -> void:
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
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return
	for object_id in apartment.get_owned_object_ids():
		var entry: Dictionary = _ensure_item(String(object_id))
		entry["times_considered"] = int(entry["times_considered"]) + 1


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
	return cheapest


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


func _girl_goal(girl_id: StringName) -> String:
	return "filler:max:%s" % String(girl_id)


func _rival_goal(rival_id: StringName) -> String:
	return "rival:engage:%s" % String(rival_id)


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
