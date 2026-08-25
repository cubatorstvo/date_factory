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


func finalize_days(last_day_index: int, money: int, rating: int) -> void:
	calendar_days = last_day_index + 1
	money_end = money
	rating_end = rating
	_consecutive_dead = 0
	_consecutive_work_only = 0
	var consecutive_money_blocked: int = 0
	money_blocked_days = 0
	max_consecutive_money_blocked_days = 0
	for day_index in range(calendar_days):
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
		var categories: PackedStringArray = PackedStringArray()
		if _day_categories.has(day_key):
			categories = _day_categories[day_key]
		var work_count: int = 0
		var other_progress: bool = false
		for category in categories:
			if category == "WORK":
				work_count += 1
			elif category == "DATE" or category == "RIVAL" or category == "TRAINING" or category == "PURCHASE" or category == "STORY":
				other_progress = true
		if work_count > 0 and not other_progress:
			work_only_days += 1
			_consecutive_work_only += 1
			max_consecutive_work_only_days = maxi(max_consecutive_work_only_days, _consecutive_work_only)
		else:
			_consecutive_work_only = 0


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
