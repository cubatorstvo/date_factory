class_name ProgressionLabMetrics
extends RefCounted

var calendar_days: int = 0
var total_actions: int = 0
var work_actions: int = 0
var training_actions: int = 0
var dates: int = 0
var rival_attempts: int = 0
var rival_wins: int = 0
var purchases: int = 0
var apartment_preparations: int = 0
var dates_by_girl: Dictionary = {}
var dates_to_max_by_girl: Dictionary = {}
var money_earned: int = 0
var money_spent: int = 0
var money_end: int = 0
var minimum_money: int = 0
var outfits_acquired: int = 0
var apartment_objects_acquired: int = 0
var characteristic_upgrades: int = 0
var rating_start: int = 0
var rating_end: int = 0
var money_blocked_decision_points: int = 0
var daily_gate_blocked_decision_points: int = 0
var money_blocked_days: int = 0
var max_consecutive_money_blocked_days: int = 0
var progress_beats: int = 0
var dead_progress_days: int = 0
var max_consecutive_dead_progress_days: int = 0
var unique_situations_seen: int = 0
var unique_moves_used: int = 0
var unique_venues_used: int = 0
var max_consecutive_same_primary_action: int = 0
var max_consecutive_work_actions: int = 0
var max_consecutive_work_only_days: int = 0
var work_only_days: int = 0
var total_rival_cash_dependencies: int = 0
var story_rival_cash_dependencies: int = 0
var ordinary_rival_cash_dependencies: int = 0
var work_actions_supporting_rival: int = 0
var rival_action_money_failures: int = 0
var resolved_rival_money_failures: int = 0
var unresolved_rival_money_failures: int = 0
var novelty_events: int = 0
var stage_start_calendar_day: int = 0
var stage_end_calendar_day: int = 0
var last_date_day_index: int = -1
var days_after_last_date_before_stage_completion: int = 0
var actions_after_last_date_before_stage_completion: int = 0
var work_actions_after_last_date_before_stage_completion: int = 0
var purchases_after_last_date_before_stage_completion: int = 0
var stale_planned_goal_count: int = 0
var stale_planned_goal_ids: PackedStringArray = PackedStringArray()
var stale_planned_goals: Array = []
var money_forced_work_days: int = 0
var max_consecutive_money_forced_work_days: int = 0
var work_actions_for_characteristics: int = 0
var work_actions_for_outfits: int = 0
var work_actions_for_apartment: int = 0
var work_actions_for_dates: int = 0
var work_actions_for_rivals: int = 0
var work_actions_for_other: int = 0
var work_actions_for_career: int = 0
var career_rank_start: int = 0
var career_rank_end: int = 0
var career_advancement_actions: int = 0
var career_rank_1_day: int = -1
var career_rank_2_day: int = -1
var career_rank_3_day: int = -1
var work_income_start: int = 0
var work_income_end: int = 0
var money_earned_from_work: int = 0
var work_actions_at_rank_0: int = 0
var work_actions_at_rank_1: int = 0
var work_actions_at_rank_2: int = 0
var work_actions_at_rank_3: int = 0
var career_investment_capital_training_actions: int = 0
var work_actions_supporting_career: int = 0
var build_acquisitions: Array = []
var goal_friction: Dictionary = {}
var production_flags: Dictionary = {}

var _situations: Dictionary = {}
var _moves: Dictionary = {}
var _venues: Dictionary = {}
var _consecutive_dead: int = 0
var _consecutive_work_only: int = 0
var _consecutive_same: int = 0
var _consecutive_work: int = 0
var _last_primary: String = ""
var _day_categories: Dictionary = {}
var _day_beats: Dictionary = {}
var _money_blocked_days: Dictionary = {}
var _money_forced_work_days: Dictionary = {}
var _start_day_index: int = 0
var _actions_at_last_date: int = 0
var _work_at_last_date: int = 0
var _purchases_at_last_date: int = 0


func ensure_goal(goal_id: String) -> Dictionary:
	if goal_friction.has(goal_id):
		return goal_friction[goal_id]
	var entry: Dictionary = {
		"direct_actions": 0,
		"support_actions": 0,
		"blocked_by_money_count": 0,
		"blocked_by_daily_gate_count": 0,
		"first_attempt_day": -1,
		"completed_day": -1,
		"calendar_days_from_first_attempt_to_completion": 0,
	}
	goal_friction[goal_id] = entry
	return entry


func record_blocking_decision_point(money_blocked_goal_ids: Array, daily_gate_blocked_goal_ids: Array, day_index: int = -1) -> void:
	if not money_blocked_goal_ids.is_empty():
		money_blocked_decision_points += 1
		for goal_id in money_blocked_goal_ids:
			var money_entry: Dictionary = ensure_goal(str(goal_id))
			money_entry["blocked_by_money_count"] = int(money_entry["blocked_by_money_count"]) + 1
		if day_index >= 0:
			_money_blocked_days[str(day_index)] = true
	if not daily_gate_blocked_goal_ids.is_empty():
		daily_gate_blocked_decision_points += 1
		for goal_id in daily_gate_blocked_goal_ids:
			var daily_entry: Dictionary = ensure_goal(str(goal_id))
			daily_entry["blocked_by_daily_gate_count"] = int(daily_entry["blocked_by_daily_gate_count"]) + 1


func record_goal_action(goal_id: String, is_support: bool, day_index: int) -> void:
	if goal_id.is_empty():
		return
	var entry: Dictionary = ensure_goal(goal_id)
	if int(entry["first_attempt_day"]) < 0:
		entry["first_attempt_day"] = day_index
	if is_support:
		entry["support_actions"] = int(entry["support_actions"]) + 1
	else:
		entry["direct_actions"] = int(entry["direct_actions"]) + 1


func complete_goal(goal_id: String, day_index: int) -> void:
	if goal_id.is_empty():
		return
	var entry: Dictionary = ensure_goal(goal_id)
	if int(entry["completed_day"]) >= 0:
		return
	entry["completed_day"] = day_index
	var first_day: int = int(entry["first_attempt_day"])
	if first_day < 0:
		first_day = day_index
		entry["first_attempt_day"] = day_index
	entry["calendar_days_from_first_attempt_to_completion"] = maxi(0, day_index - first_day)


func note_situation(situation_id: StringName) -> void:
	var key: String = String(situation_id)
	if key.is_empty() or _situations.has(key):
		return
	_situations[key] = true
	unique_situations_seen = _situations.size()
	novelty_events += 1


func note_move(move_id: StringName) -> void:
	var key: String = String(move_id)
	if key.is_empty() or _moves.has(key):
		return
	_moves[key] = true
	unique_moves_used = _moves.size()
	novelty_events += 1


func note_venue(venue_id: StringName) -> void:
	var key: String = String(venue_id)
	if key.is_empty() or _venues.has(key):
		return
	_venues[key] = true
	unique_venues_used = _venues.size()
	novelty_events += 1


func add_date(girl_id: StringName) -> void:
	dates += 1
	var key: String = String(girl_id)
	dates_by_girl[key] = int(dates_by_girl.get(key, 0)) + 1


func mark_girl_max(girl_id: StringName) -> void:
	var key: String = String(girl_id)
	if dates_to_max_by_girl.has(key):
		return
	dates_to_max_by_girl[key] = int(dates_by_girl.get(key, 0))


func set_flag(flag_name: String, value: bool = true) -> void:
	if value:
		production_flags[flag_name] = true


func last_primary_category() -> String:
	return _last_primary


func consecutive_same_count() -> int:
	return _consecutive_same


func record_primary(category: String, day_index: int, beat_count: int) -> void:
	total_actions += 1
	if category == _last_primary:
		_consecutive_same += 1
	else:
		_consecutive_same = 1
		_last_primary = category
	max_consecutive_same_primary_action = maxi(max_consecutive_same_primary_action, _consecutive_same)
	if category == "WORK":
		_consecutive_work += 1
		max_consecutive_work_actions = maxi(max_consecutive_work_actions, _consecutive_work)
	else:
		_consecutive_work = 0
	var day_key: String = str(day_index)
	if not _day_categories.has(day_key):
		_day_categories[day_key] = PackedStringArray()
	var categories: PackedStringArray = _day_categories[day_key]
	categories.append(category)
	_day_categories[day_key] = categories
	_day_beats[day_key] = int(_day_beats.get(day_key, 0)) + beat_count
	progress_beats += beat_count
	if category == "DATE" or category == "STORY":
		note_last_date(day_index)
func finalize_days(last_day_index: int, money: int, rating: int, start_day_index: int = 0) -> void:
	_start_day_index = maxi(start_day_index, 0)
	var end_day: int = maxi(last_day_index, _start_day_index)
	stage_start_calendar_day = _start_day_index + 1
	stage_end_calendar_day = end_day + 1
	calendar_days = end_day - _start_day_index + 1
	money_end = money
	rating_end = rating
	_consecutive_dead = 0
	_consecutive_work_only = 0
	var consecutive_money_blocked: int = 0
	var consecutive_forced_work: int = 0
	money_blocked_days = 0
	max_consecutive_money_blocked_days = 0
	money_forced_work_days = 0
	max_consecutive_money_forced_work_days = 0
	dead_progress_days = 0
	max_consecutive_dead_progress_days = 0
	work_only_days = 0
	max_consecutive_work_only_days = 0
	for day_index in range(_start_day_index, end_day + 1):
		var day_key: String = str(day_index)
		var beats: int = int(_day_beats.get(day_key, 0))
		if beats <= 0:
			dead_progress_days += 1
			_consecutive_dead += 1
			max_consecutive_dead_progress_days = maxi(max_consecutive_dead_progress_days, _consecutive_dead)
		else:
			_consecutive_dead = 0
		if _money_blocked_days.has(day_key):
			money_blocked_days += 1
			consecutive_money_blocked += 1
			max_consecutive_money_blocked_days = maxi(max_consecutive_money_blocked_days, consecutive_money_blocked)
		else:
			consecutive_money_blocked = 0
		if _money_forced_work_days.has(day_key):
			money_forced_work_days += 1
			consecutive_forced_work += 1
			max_consecutive_money_forced_work_days = maxi(max_consecutive_money_forced_work_days, consecutive_forced_work)
		else:
			consecutive_forced_work = 0
		var categories: PackedStringArray = PackedStringArray()
		if _day_categories.has(day_key):
			categories = _day_categories[day_key]
		var work_count: int = 0
		var other_progress: bool = false
		for category in categories:
			if category == "WORK":
				work_count += 1
			elif category == "DATE" or category == "RIVAL" or category == "TRAINING" or category == "PURCHASE" or category == "STORY" or category == "CAREER":
				other_progress = true
		if work_count > 0 and not other_progress:
			work_only_days += 1
			_consecutive_work_only += 1
			max_consecutive_work_only_days = maxi(max_consecutive_work_only_days, _consecutive_work_only)
		else:
			_consecutive_work_only = 0
	_finalize_post_date_tail(end_day)
	_finalize_build_timing(end_day)

func note_last_date(day_index: int) -> void:
	last_date_day_index = day_index
	_actions_at_last_date = total_actions
	_work_at_last_date = work_actions
	_purchases_at_last_date = purchases

func begin_stage_window(start_day_index: int) -> void:
	_start_day_index = maxi(start_day_index, 0)
	stage_start_calendar_day = _start_day_index + 1


func record_money_forced_work(day_index: int) -> void:
	if day_index < 0:
		return
	_money_forced_work_days[str(day_index)] = true


func record_work_support(goal_id: String) -> void:
	var kind: String = work_goal_kind(goal_id)
	match kind:
		"characteristics":
			work_actions_for_characteristics += 1
		"outfits":
			work_actions_for_outfits += 1
		"apartment":
			work_actions_for_apartment += 1
		"dates":
			work_actions_for_dates += 1
		"rivals":
			work_actions_for_rivals += 1
		"career":
			work_actions_for_career += 1
			work_actions_supporting_career += 1
		_:
			work_actions_for_other += 1


func record_career_rank_reached(rank: int, calendar_day: int) -> void:
	if calendar_day < 1:
		return
	match rank:
		1:
			if career_rank_1_day < 0:
				career_rank_1_day = calendar_day
		2:
			if career_rank_2_day < 0:
				career_rank_2_day = calendar_day
		3:
			if career_rank_3_day < 0:
				career_rank_3_day = calendar_day


func record_work_at_rank(rank: int) -> void:
	match clampi(rank, 0, 3):
		0:
			work_actions_at_rank_0 += 1
		1:
			work_actions_at_rank_1 += 1
		2:
			work_actions_at_rank_2 += 1
		3:
			work_actions_at_rank_3 += 1

static func work_goal_kind(goal_id: String) -> String:
	match classify_supporting_goal(goal_id):
		"CHARACTERISTIC":
			return "characteristics"
		"OUTFIT":
			return "outfits"
		"APARTMENT":
			return "apartment"
		"DATE":
			return "dates"
		"RIVAL":
			return "rivals"
		"CAREER":
			return "career"
		_:
			return "other"

static func classify_supporting_goal(goal_id: String) -> String:
	if goal_id.begins_with("characteristic:"):
		return "CHARACTERISTIC"
	if goal_id.begins_with("outfit:"):
		return "OUTFIT"
	if goal_id.begins_with("apartment:"):
		return "APARTMENT"
	if goal_id.begins_with("filler:max:") or goal_id.begins_with("story:"):
		return "DATE"
	if goal_id.begins_with("rival:") or goal_id.begins_with("story_rival:"):
		return "RIVAL"
	if goal_id.begins_with("career:"):
		return "CAREER"
	return "OTHER"


static func classify_goal_friction_type(goal_id: String) -> String:
	if goal_id.begins_with("characteristic:"):
		return "Characteristic"
	if goal_id == "outfit:dressup" or goal_id == "outfit:count" or goal_id == "apartment:count":
		return "Mandatory acquisition"
	if goal_id.begins_with("outfit:"):
		return "Outfit"
	if goal_id.begins_with("apartment:"):
		return "Apartment Object"
	if goal_id.begins_with("filler:max:"):
		return "Filler Girl"
	if goal_id.begins_with("story:"):
		return "Story Girl"
	if goal_id.begins_with("story_rival:"):
		return "Story Rival"
	if goal_id.begins_with("rival:"):
		return "Ordinary Rival"
	if goal_id.begins_with("venue:"):
		return "Venue exploration"
	return "Other"

func record_stale_goal(goal_id: String, goal_type: String = "", campaign_day: int = 0, stage_day: int = 0, reason: String = "") -> void:
	if goal_id.is_empty() or stale_planned_goal_ids.has(goal_id):
		return
	stale_planned_goal_ids.append(goal_id)
	stale_planned_goal_count = stale_planned_goal_ids.size()
	var resolved_type: String = goal_type
	if resolved_type.is_empty():
		resolved_type = classify_goal_friction_type(goal_id)
	var resolved_reason: String = reason
	if resolved_reason.is_empty():
		resolved_reason = "future_use_opportunities == 0"
	stale_planned_goals.append({
		"goal_id": goal_id,
		"goal_type": resolved_type,
		"campaign_day": campaign_day,
		"stage_day": stage_day,
		"reason": resolved_reason,
	})

func record_build_acquisition(goal_id: String, campaign_day_index: int, remaining_dates: int, future_use: int, urgency_bonus: float) -> void:
	build_acquisitions.append({
		"goal_id": goal_id,
		"campaign_day": campaign_day_index + 1,
		"stage_day_acquired": maxi(campaign_day_index - _start_day_index + 1, 1),
		"remaining_stage_dates_at_acquisition": remaining_dates,
		"remaining_stage_days_after_acquisition": 0,
		"future_use_opportunities": future_use,
		"build_urgency_bonus": urgency_bonus,
	})


func _finalize_post_date_tail(end_day: int) -> void:
	if last_date_day_index < 0:
		days_after_last_date_before_stage_completion = 0
		actions_after_last_date_before_stage_completion = 0
		work_actions_after_last_date_before_stage_completion = 0
		purchases_after_last_date_before_stage_completion = 0
		return
	days_after_last_date_before_stage_completion = maxi(0, end_day - last_date_day_index)
	actions_after_last_date_before_stage_completion = maxi(0, total_actions - _actions_at_last_date)
	work_actions_after_last_date_before_stage_completion = maxi(0, work_actions - _work_at_last_date)
	purchases_after_last_date_before_stage_completion = maxi(0, purchases - _purchases_at_last_date)


func _finalize_build_timing(end_day: int) -> void:
	for i in range(build_acquisitions.size()):
		var row: Dictionary = build_acquisitions[i]
		var acquired_day: int = int(row.get("campaign_day", 1)) - 1
		row["remaining_stage_days_after_acquisition"] = maxi(0, end_day - acquired_day)
		build_acquisitions[i] = row


func work_share(kind: String) -> float:
	var total: int = maxi(work_actions, 1)
	match kind:
		"characteristics":
			return float(work_actions_for_characteristics) / float(total)
		"outfits":
			return float(work_actions_for_outfits) / float(total)
		"apartment":
			return float(work_actions_for_apartment) / float(total)
		"dates":
			return float(work_actions_for_dates) / float(total)
		"rivals":
			return float(work_actions_for_rivals) / float(total)
		"career":
			return float(work_actions_for_career) / float(total)
		_:
			return float(work_actions_for_other) / float(total)

func economy_support_share() -> float:
	return float(work_actions) / float(maxi(total_actions, 1))


func maintenance_share() -> float:
	return float(work_actions + apartment_preparations) / float(maxi(total_actions, 1))


func novelty_density() -> float:
	return float(novelty_events) / float(maxi(total_actions, 1))


func friction_summary() -> Dictionary:
	var ratios: PackedFloat64Array = PackedFloat64Array()
	var highest_id: String = ""
	var highest_ratio: float = 0.0
	for goal_id in goal_friction.keys():
		var entry: Dictionary = goal_friction[goal_id]
		var direct_actions: int = int(entry["direct_actions"])
		var support_actions: int = int(entry["support_actions"])
		var ratio: float = float(support_actions) / float(maxi(direct_actions, 1))
		ratios.append(ratio)
		if ratio > highest_ratio:
			highest_ratio = ratio
			highest_id = str(goal_id)
	var mean: float = 0.0
	if ratios.size() > 0:
		var total: float = 0.0
		for ratio in ratios:
			total += ratio
		mean = total / float(ratios.size())
	return {
		"max_goal_friction_ratio": highest_ratio,
		"mean_goal_friction_ratio": mean,
		"highest_friction_goal_id": highest_id,
		"goal_friction": goal_friction.duplicate(true),
	}


func to_dict() -> Dictionary:
	var friction: Dictionary = friction_summary()
	return {
		"calendar_days": calendar_days,
		"stage_start_calendar_day": stage_start_calendar_day,
		"stage_end_calendar_day": stage_end_calendar_day,
		"last_date_day": last_date_day_index + 1 if last_date_day_index >= 0 else 0,
		"days_after_last_date_before_stage_completion": days_after_last_date_before_stage_completion,
		"actions_after_last_date_before_stage_completion": actions_after_last_date_before_stage_completion,
		"work_actions_after_last_date_before_stage_completion": work_actions_after_last_date_before_stage_completion,
		"purchases_after_last_date_before_stage_completion": purchases_after_last_date_before_stage_completion,
		"stale_planned_goal_count": stale_planned_goal_count,
		"stale_planned_goal_ids": Array(stale_planned_goal_ids),
		"stale_planned_goals": stale_planned_goals.duplicate(true),
		"build_acquisitions": build_acquisitions.duplicate(true),
		"total_actions": total_actions,
		"work_actions": work_actions,
		"training_actions": training_actions,
		"dates": dates,
		"rival_attempts": rival_attempts,
		"rival_wins": rival_wins,
		"purchases": purchases,
		"apartment_preparations": apartment_preparations,
		"dates_by_girl": dates_by_girl.duplicate(true),
		"dates_to_max_by_girl": dates_to_max_by_girl.duplicate(true),
		"money_earned": money_earned,
		"money_spent": money_spent,
		"money_end": money_end,
		"minimum_money": minimum_money,
		"outfits_acquired": outfits_acquired,
		"apartment_objects_acquired": apartment_objects_acquired,
		"characteristic_upgrades": characteristic_upgrades,
		"rating_start": rating_start,
		"rating_end": rating_end,
		"money_blocked_decision_points": money_blocked_decision_points,
		"daily_gate_blocked_decision_points": daily_gate_blocked_decision_points,
		"money_blocked_days": money_blocked_days,
		"max_consecutive_money_blocked_days": max_consecutive_money_blocked_days,
		"money_forced_work_days": money_forced_work_days,
		"max_consecutive_money_forced_work_days": max_consecutive_money_forced_work_days,
		"work_actions_for_characteristics": work_actions_for_characteristics,
		"work_actions_for_outfits": work_actions_for_outfits,
		"work_actions_for_apartment": work_actions_for_apartment,
		"work_actions_for_dates": work_actions_for_dates,
		"work_actions_for_rivals": work_actions_for_rivals,
		"work_actions_for_other": work_actions_for_other,
		"work_actions_for_career": work_actions_for_career,
		"career_rank_start": career_rank_start,
		"career_rank_end": career_rank_end,
		"career_advancement_actions": career_advancement_actions,
		"career_rank_1_day": career_rank_1_day,
		"career_rank_2_day": career_rank_2_day,
		"career_rank_3_day": career_rank_3_day,
		"work_income_start": work_income_start,
		"work_income_end": work_income_end,
		"money_earned_from_work": money_earned_from_work,
		"work_actions_at_rank_0": work_actions_at_rank_0,
		"work_actions_at_rank_1": work_actions_at_rank_1,
		"work_actions_at_rank_2": work_actions_at_rank_2,
		"work_actions_at_rank_3": work_actions_at_rank_3,
		"career_investment_capital_training_actions": career_investment_capital_training_actions,
		"work_actions_supporting_career": work_actions_supporting_career,
		"work_share_characteristics": work_share("characteristics"),
		"work_share_outfits": work_share("outfits"),
		"work_share_apartment": work_share("apartment"),
		"work_share_dates": work_share("dates"),
		"work_share_rivals": work_share("rivals"),
		"work_share_career": work_share("career"),
		"progress_beats": progress_beats,
		"dead_progress_days": dead_progress_days,
		"max_consecutive_dead_progress_days": max_consecutive_dead_progress_days,
		"unique_situations_seen": unique_situations_seen,
		"unique_moves_used": unique_moves_used,
		"unique_venues_used": unique_venues_used,
		"max_consecutive_same_primary_action": max_consecutive_same_primary_action,
		"max_consecutive_work_actions": max_consecutive_work_actions,
		"max_consecutive_work_only_days": max_consecutive_work_only_days,
		"work_only_days": work_only_days,
		"total_rival_cash_dependencies": total_rival_cash_dependencies,
		"story_rival_cash_dependencies": story_rival_cash_dependencies,
		"ordinary_rival_cash_dependencies": ordinary_rival_cash_dependencies,
		"work_actions_supporting_rival": work_actions_supporting_rival,
		"rival_action_money_failures": rival_action_money_failures,
		"resolved_rival_money_failures": resolved_rival_money_failures,
		"unresolved_rival_money_failures": unresolved_rival_money_failures,
		"economy_support_share": economy_support_share(),
		"maintenance_share": maintenance_share(),
		"novelty_density": novelty_density(),
		"novelty_events": novelty_events,
		"max_goal_friction_ratio": friction["max_goal_friction_ratio"],
		"mean_goal_friction_ratio": friction["mean_goal_friction_ratio"],
		"highest_friction_goal_id": friction["highest_friction_goal_id"],
		"goal_friction": friction["goal_friction"],
		"production_flags": production_flags.duplicate(true),
	}


static func from_dict(data: Dictionary) -> ProgressionLabMetrics:
	var metrics := ProgressionLabMetrics.new()
	metrics.calendar_days = int(data.get("calendar_days", 0))
	metrics.stage_start_calendar_day = int(data.get("stage_start_calendar_day", 0))
	metrics.stage_end_calendar_day = int(data.get("stage_end_calendar_day", 0))
	metrics.days_after_last_date_before_stage_completion = int(data.get("days_after_last_date_before_stage_completion", 0))
	metrics.actions_after_last_date_before_stage_completion = int(data.get("actions_after_last_date_before_stage_completion", 0))
	metrics.work_actions_after_last_date_before_stage_completion = int(data.get("work_actions_after_last_date_before_stage_completion", 0))
	metrics.purchases_after_last_date_before_stage_completion = int(data.get("purchases_after_last_date_before_stage_completion", 0))
	metrics.stale_planned_goal_count = int(data.get("stale_planned_goal_count", 0))
	metrics.money_forced_work_days = int(data.get("money_forced_work_days", 0))
	metrics.max_consecutive_money_forced_work_days = int(data.get("max_consecutive_money_forced_work_days", 0))
	metrics.work_actions_for_characteristics = int(data.get("work_actions_for_characteristics", 0))
	metrics.work_actions_for_outfits = int(data.get("work_actions_for_outfits", 0))
	metrics.work_actions_for_apartment = int(data.get("work_actions_for_apartment", 0))
	metrics.work_actions_for_dates = int(data.get("work_actions_for_dates", 0))
	metrics.work_actions_for_rivals = int(data.get("work_actions_for_rivals", 0))
	metrics.work_actions_for_other = int(data.get("work_actions_for_other", 0))
	metrics.work_actions_for_career = int(data.get("work_actions_for_career", 0))
	metrics.career_rank_start = int(data.get("career_rank_start", 0))
	metrics.career_rank_end = int(data.get("career_rank_end", 0))
	metrics.career_advancement_actions = int(data.get("career_advancement_actions", 0))
	metrics.career_rank_1_day = int(data.get("career_rank_1_day", -1))
	metrics.career_rank_2_day = int(data.get("career_rank_2_day", -1))
	metrics.career_rank_3_day = int(data.get("career_rank_3_day", -1))
	metrics.work_income_start = int(data.get("work_income_start", 0))
	metrics.work_income_end = int(data.get("work_income_end", 0))
	metrics.money_earned_from_work = int(data.get("money_earned_from_work", 0))
	metrics.work_actions_at_rank_0 = int(data.get("work_actions_at_rank_0", 0))
	metrics.work_actions_at_rank_1 = int(data.get("work_actions_at_rank_1", 0))
	metrics.work_actions_at_rank_2 = int(data.get("work_actions_at_rank_2", 0))
	metrics.work_actions_at_rank_3 = int(data.get("work_actions_at_rank_3", 0))
	metrics.career_investment_capital_training_actions = int(data.get("career_investment_capital_training_actions", 0))
	metrics.work_actions_supporting_career = int(data.get("work_actions_supporting_career", 0))
	var stale_raw: Variant = data.get("stale_planned_goal_ids", [])
	if stale_raw is Array:
		for item in stale_raw:
			metrics.stale_planned_goal_ids.append(str(item))
	var stale_rows: Variant = data.get("stale_planned_goals", [])
	if stale_rows is Array:
		metrics.stale_planned_goals = stale_rows.duplicate(true)
	var build_raw: Variant = data.get("build_acquisitions", [])
	if build_raw is Array:
		metrics.build_acquisitions = build_raw.duplicate(true)
	metrics.total_actions = int(data.get("total_actions", 0))
	metrics.work_actions = int(data.get("work_actions", 0))
	metrics.training_actions = int(data.get("training_actions", 0))
	metrics.dates = int(data.get("dates", 0))
	metrics.rival_attempts = int(data.get("rival_attempts", 0))
	metrics.rival_wins = int(data.get("rival_wins", 0))
	metrics.purchases = int(data.get("purchases", 0))
	metrics.apartment_preparations = int(data.get("apartment_preparations", 0))
	metrics.money_earned = int(data.get("money_earned", 0))
	metrics.money_spent = int(data.get("money_spent", 0))
	metrics.money_end = int(data.get("money_end", 0))
	metrics.minimum_money = int(data.get("minimum_money", 0))
	metrics.outfits_acquired = int(data.get("outfits_acquired", 0))
	metrics.apartment_objects_acquired = int(data.get("apartment_objects_acquired", 0))
	metrics.characteristic_upgrades = int(data.get("characteristic_upgrades", 0))
	metrics.rating_start = int(data.get("rating_start", 0))
	metrics.rating_end = int(data.get("rating_end", 0))
	metrics.money_blocked_decision_points = int(data.get("money_blocked_decision_points", 0))
	metrics.daily_gate_blocked_decision_points = int(data.get("daily_gate_blocked_decision_points", 0))
	metrics.money_blocked_days = int(data.get("money_blocked_days", 0))
	metrics.max_consecutive_money_blocked_days = int(data.get("max_consecutive_money_blocked_days", 0))
	metrics.progress_beats = int(data.get("progress_beats", 0))
	metrics.dead_progress_days = int(data.get("dead_progress_days", 0))
	metrics.max_consecutive_dead_progress_days = int(data.get("max_consecutive_dead_progress_days", 0))
	metrics.unique_situations_seen = int(data.get("unique_situations_seen", 0))
	metrics.unique_moves_used = int(data.get("unique_moves_used", 0))
	metrics.unique_venues_used = int(data.get("unique_venues_used", 0))
	metrics.max_consecutive_same_primary_action = int(data.get("max_consecutive_same_primary_action", 0))
	metrics.max_consecutive_work_actions = int(data.get("max_consecutive_work_actions", 0))
	metrics.max_consecutive_work_only_days = int(data.get("max_consecutive_work_only_days", 0))
	metrics.work_only_days = int(data.get("work_only_days", 0))
	metrics.novelty_events = int(data.get("novelty_events", 0))
	var dates_raw: Variant = data.get("dates_by_girl", {})
	if dates_raw is Dictionary:
		metrics.dates_by_girl = dates_raw
	var max_raw: Variant = data.get("dates_to_max_by_girl", {})
	if max_raw is Dictionary:
		metrics.dates_to_max_by_girl = max_raw
	var friction_raw: Variant = data.get("goal_friction", {})
	if friction_raw is Dictionary:
		metrics.goal_friction = friction_raw
	var flags_raw: Variant = data.get("production_flags", {})
	if flags_raw is Dictionary:
		metrics.production_flags = flags_raw
	return metrics
