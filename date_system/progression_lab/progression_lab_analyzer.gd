class_name ProgressionLabAnalyzer
extends RefCounted

const WARNING_CLASS_RUNTIME: String = "RUNTIME_FAILURE"
const WARNING_CLASS_PACING: String = "PACING_WARNING"
const DIAGNOSTIC_METRIC_KEYS: PackedStringArray = [
	"money_blocked_decision_points",
	"money_blocked_days",
	"money_forced_work_days",
	"dead_progress_days",
	"max_consecutive_dead_progress_days",
	"max_goal_friction_ratio",
	"max_consecutive_work_only_days",
	"economy_support_share",
]

const METRIC_KEYS: PackedStringArray = [
	"calendar_days",
	"total_actions",
	"work_actions",
	"training_actions",
	"dates",
	"rival_attempts",
	"rival_wins",
	"purchases",
	"apartment_preparations",
	"money_earned",
	"money_spent",
	"money_end",
	"minimum_money",
	"outfits_acquired",
	"apartment_objects_acquired",
	"characteristic_upgrades",
	"rating_end",
	"money_blocked_decision_points",
	"daily_gate_blocked_decision_points",
	"money_blocked_days",
	"max_consecutive_money_blocked_days",
	"progress_beats",
	"dead_progress_days",
	"max_consecutive_dead_progress_days",
	"unique_situations_seen",
	"unique_moves_used",
	"unique_venues_used",
	"max_consecutive_same_primary_action",
	"max_consecutive_work_actions",
	"max_consecutive_work_only_days",
	"work_only_days",
	"economy_support_share",
	"maintenance_share",
	"novelty_density",
	"max_goal_friction_ratio",
	"mean_goal_friction_ratio",
	"days_after_last_date_before_stage_completion",
	"actions_after_last_date_before_stage_completion",
	"work_actions_after_last_date_before_stage_completion",
	"purchases_after_last_date_before_stage_completion",
	"money_forced_work_days",
	"max_consecutive_money_forced_work_days",
	"stale_planned_goal_count",
	"work_actions_for_characteristics",
	"work_actions_for_outfits",
	"work_actions_for_apartment",
	"work_actions_for_dates",
	"work_actions_for_rivals",
	"work_actions_for_other",
	"work_actions_for_career",
	"career_rank_start",
	"career_rank_end",
	"career_advancement_actions",
	"career_rank_1_day",
	"career_rank_2_day",
	"career_rank_3_day",
	"career_connections_unlock_day",
	"career_connections_unlock_stage",
	"rank_1_before_connections",
	"work_income_start",
	"work_income_end",
	"money_earned_from_work",
	"work_actions_at_rank_0",
	"work_actions_at_rank_1",
	"work_actions_at_rank_2",
	"work_actions_at_rank_3",
	"career_investment_capital_training_actions",
	"work_actions_supporting_career",
	"career_negative_or_zero_roi_investments",
	"career_positive_roi_investments",
	"career_reservation_started_count",
	"career_reservation_completed_count",
	"career_reservation_override_count",
	"career_reserved_money_peak",
	"career_support_work_before_target_rank",
	"career_support_work_wasted",
	"career_support_work_before_rank_1",
	"career_support_work_before_rank_2",
	"career_support_work_before_rank_3",
]


func analyze(result: ProgressionLabPopulationResult, config: ProgressionLabConfig) -> void:
	if result == null or config == null:
		return
	var summaries: Array = []
	for record in result.records:
		if record is ProgressionLabRunRecord:
			summaries.append(record)
	result.statistics = {
		"overall": _stats_for(summaries, ""),
		"per_archetype": {},
		"per_stage": {},
		"per_archetype_per_stage": {},
	}
	for archetype in [ProgressionLabConfig.ARCHETYPE_EFFICIENT, ProgressionLabConfig.ARCHETYPE_TYPICAL, ProgressionLabConfig.ARCHETYPE_EXPLORER, ProgressionLabConfig.ARCHETYPE_CHAOTIC]:
		var filtered: Array = []
		for record in summaries:
			if record.archetype == archetype:
				filtered.append(record)
		result.statistics["per_archetype"][String(archetype)] = _stats_for(filtered, "")
	for stage in range(1, 5):
		result.statistics["per_stage"][str(stage)] = _stats_for(summaries, str(stage))
		for archetype in [ProgressionLabConfig.ARCHETYPE_EFFICIENT, ProgressionLabConfig.ARCHETYPE_TYPICAL, ProgressionLabConfig.ARCHETYPE_EXPLORER, ProgressionLabConfig.ARCHETYPE_CHAOTIC]:
			var filtered: Array = []
			for record in summaries:
				if record.archetype == archetype:
					filtered.append(record)
			result.statistics["per_archetype_per_stage"]["%s:%d" % [String(archetype), stage]] = _stats_for(filtered, str(stage))
	_apply_badness(summaries, config)
	var display_k: int = config.bad_seed_count_display if config.bad_seed_count_display > 0 else config.default_bad_seed_count
	var hard_bad: Array = _collect_hard_bad_seeds(summaries)
	result.hard_bad_seeds = []
	for record in hard_bad:
		result.hard_bad_seeds.append(_seed_row(record))
	result.all_bad_seeds = result.hard_bad_seeds.duplicate(true)
	result.bad_seeds = result.hard_bad_seeds.duplicate(true)
	result.bad_seed_count = result.hard_bad_seeds.size()
	result.bad_seed_percentage = float(result.bad_seed_count) / float(maxi(result.n, 1))
	result.top_badness_seeds = []
	for record in _collect_top_badness_seeds(summaries, display_k):
		result.top_badness_seeds.append(_seed_row(record))
	result.top_bad_seeds = result.top_badness_seeds.duplicate(true)
	result.representative_seeds = _select_representative(summaries)
	result.analysis_warnings = _aggregate_warnings(summaries, config)
	result.warning_prevalence = _warning_prevalence(summaries, result.n)
	result.diagnostic_metrics = _diagnostic_metrics(summaries)
	result.item_metrics = _aggregate_items(summaries)
	result.rival_cash_dependency = _rival_cash_aggregate(summaries)
	result.post_date_tail = _post_date_tail_aggregate(summaries)
	result.build_timing = _build_timing_aggregate(summaries)
	result.work_attribution = _work_attribution_aggregate(summaries)
	result.career_progression = _career_progression_aggregate(summaries)
	result.goal_friction_by_type = _goal_friction_by_type(summaries)
	result.stale_planned_goals = _stale_planned_aggregate(summaries)


func _stats_for(records: Array, stage_key: String) -> Dictionary:
	var buckets: Dictionary = {}
	for key in METRIC_KEYS:
		buckets[key] = PackedFloat64Array()
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var metrics: Dictionary = record.campaign_metrics
		if not stage_key.is_empty() and record.stage_metrics.has(stage_key):
			metrics = record.stage_metrics[stage_key]
		for key in METRIC_KEYS:
			var values: PackedFloat64Array = buckets[key]
			values.append(float(metrics.get(key, 0.0)))
			buckets[key] = values
	var result: Dictionary = {}
	for key in METRIC_KEYS:
		result[key] = describe(buckets[key])
	return result


static func describe(values: PackedFloat64Array) -> Dictionary:
	var sorted_values: PackedFloat64Array = values.duplicate()
	sorted_values.sort()
	var count: int = sorted_values.size()
	if count == 0:
		return {
			"count": 0,
			"mean": 0.0,
			"standard_deviation": 0.0,
			"min": 0.0,
			"P10": 0.0,
			"P25": 0.0,
			"P50": 0.0,
			"P75": 0.0,
			"P90": 0.0,
			"P95": 0.0,
			"max": 0.0,
		}
	var total: float = 0.0
	for value in sorted_values:
		total += value
	var mean: float = total / float(count)
	var variance: float = 0.0
	for value in sorted_values:
		var delta: float = value - mean
		variance += delta * delta
	variance = variance / float(count)
	return {
		"count": count,
		"mean": mean,
		"standard_deviation": sqrt(variance),
		"min": sorted_values[0],
		"P10": percentile(sorted_values, 0.10),
		"P25": percentile(sorted_values, 0.25),
		"P50": percentile(sorted_values, 0.50),
		"P75": percentile(sorted_values, 0.75),
		"P90": percentile(sorted_values, 0.90),
		"P95": percentile(sorted_values, 0.95),
		"max": sorted_values[count - 1],
	}


static func percentile(sorted_values: PackedFloat64Array, p: float) -> float:
	var count: int = sorted_values.size()
	if count == 0:
		return 0.0
	if count == 1:
		return sorted_values[0]
	var index: float = clampf(p, 0.0, 1.0) * float(count - 1)
	var left: int = clampi(int(floor(index)), 0, count - 1)
	var right: int = clampi(left + 1, 0, count - 1)
	var mix: float = index - float(left)
	return lerpf(sorted_values[left], sorted_values[right], mix)


func _apply_badness(records: Array, config: ProgressionLabConfig) -> void:
	var series: Dictionary = {
		"max_consecutive_work_only_days": PackedFloat64Array(),
		"economy_support_share": PackedFloat64Array(),
		"money_blocked_decision_points": PackedFloat64Array(),
		"daily_gate_blocked_decision_points": PackedFloat64Array(),
		"dead_progress_days": PackedFloat64Array(),
		"calendar_days": PackedFloat64Array(),
		"max_goal_friction_ratio": PackedFloat64Array(),
		"one_minus_novelty": PackedFloat64Array(),
	}
	for record in records:
		var metrics: Dictionary = record.campaign_metrics
		_append_series(series, "max_consecutive_work_only_days", float(metrics.get("max_consecutive_work_only_days", 0)))
		_append_series(series, "economy_support_share", float(metrics.get("economy_support_share", 0.0)))
		_append_series(series, "money_blocked_decision_points", float(metrics.get("money_blocked_decision_points", 0)))
		_append_series(series, "daily_gate_blocked_decision_points", float(metrics.get("daily_gate_blocked_decision_points", 0)))
		_append_series(series, "dead_progress_days", float(metrics.get("dead_progress_days", 0)))
		_append_series(series, "calendar_days", float(metrics.get("calendar_days", 0)))
		_append_series(series, "max_goal_friction_ratio", float(metrics.get("max_goal_friction_ratio", 0.0)))
		_append_series(series, "one_minus_novelty", one_minus_novelty(float(metrics.get("novelty_density", 0.0))))
	for key in series.keys():
		var values: PackedFloat64Array = series[key]
		values.sort()
		series[key] = values
	for record in records:
		var metrics: Dictionary = record.campaign_metrics
		var warnings: PackedStringArray = _hard_warnings_for(record, config)
		record.hard_warnings = warnings
		var badness: float = (
			config.badness_work_only_weight * _rank(series["max_consecutive_work_only_days"], float(metrics.get("max_consecutive_work_only_days", 0)))
			+ config.badness_economy_weight * _rank(series["economy_support_share"], float(metrics.get("economy_support_share", 0.0)))
			+ config.badness_money_block_weight * _rank(series["money_blocked_decision_points"], float(metrics.get("money_blocked_decision_points", 0)))
			+ config.badness_daily_gate_weight * _rank(series["daily_gate_blocked_decision_points"], float(metrics.get("daily_gate_blocked_decision_points", 0)))
			+ config.badness_dead_days_weight * _rank(series["dead_progress_days"], float(metrics.get("dead_progress_days", 0)))
			+ config.badness_calendar_weight * _rank(series["calendar_days"], float(metrics.get("calendar_days", 0)))
			+ config.badness_friction_weight * _rank(series["max_goal_friction_ratio"], float(metrics.get("max_goal_friction_ratio", 0.0)))
			+ config.badness_novelty_weight * _rank(series["one_minus_novelty"], one_minus_novelty(float(metrics.get("novelty_density", 0.0))))
		)
		record.badness_score = int(round(badness * 100.0))


func _append_series(series: Dictionary, key: String, value: float) -> void:
	var values: PackedFloat64Array = series[key]
	values.append(value)
	series[key] = values


func _rank(sorted_values: PackedFloat64Array, value: float) -> float:
	var count: int = sorted_values.size()
	if count <= 1:
		return 0.5
	var less: int = 0
	var equal: int = 0
	for item in sorted_values:
		if item < value:
			less += 1
		elif is_equal_approx(item, value):
			equal += 1
	return clampf((float(less) + 0.5 * float(equal)) / float(count), 0.0, 1.0)


func hard_warnings_for(record: ProgressionLabRunRecord, config: ProgressionLabConfig) -> PackedStringArray:
	return _hard_warnings_for(record, config)


func warning_severity(warning_id: String) -> String:
	if warning_id.begins_with("NO_USEFUL_ACTIONS_STAGE_"):
		return WARNING_CLASS_RUNTIME
	if warning_id.begins_with("STAGE_PLAN_MUTATED_"):
		return WARNING_CLASS_RUNTIME
	if warning_id == "SAFETY_CAP_DAYS" or warning_id == "SAFETY_CAP_ACTIONS":
		return WARNING_CLASS_RUNTIME
	if warning_id == "REPLAY_MISMATCH" or warning_id == "REPLAY_DETERMINISM_MISMATCH":
		return WARNING_CLASS_RUNTIME
	if warning_id == "UNRESOLVED_RIVAL_MONEY_FAILURE":
		return WARNING_CLASS_RUNTIME
	if warning_id == "ISOLATION_FAILED" or warning_id == "STAGE_TRANSITION_INVARIANT" or warning_id == "ABORTED":
		return WARNING_CLASS_RUNTIME
	if warning_id == "WORK_ONLY_STREAK" or warning_id == "DEAD_PROGRESS_STREAK":
		return WARNING_CLASS_PACING
	if warning_id == "GOAL_FRICTION" or warning_id == "ECONOMY_SUPPORT_HIGH":
		return WARNING_CLASS_PACING
	return ""


func is_hard_bad_seed(record: ProgressionLabRunRecord) -> bool:
	if record == null:
		return false
	for warning in record.hard_warnings:
		var severity: String = warning_severity(str(warning))
		if severity == WARNING_CLASS_RUNTIME or severity == WARNING_CLASS_PACING:
			return true
	return false


func normalized_novelty_density(novelty_density: float) -> float:
	return clampf(novelty_density, 0.0, 1.0)


func one_minus_novelty(novelty_density: float) -> float:
	return 1.0 - normalized_novelty_density(novelty_density)


func _hard_warnings_for(record: ProgressionLabRunRecord, config: ProgressionLabConfig) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	for existing in record.hard_warnings:
		var warning_id: String = str(existing)
		if warning_id == "MONEY_BLOCKED" or warning_id == "ECONOMY_SUPPORT":
			continue
		if warning_severity(warning_id) == WARNING_CLASS_PACING:
			continue
		if warnings.find(warning_id) >= 0:
			continue
		warnings.append(warning_id)
	var metrics: Dictionary = record.campaign_metrics
	if int(metrics.get("unresolved_rival_money_failures", 0)) > 0 and warnings.find("UNRESOLVED_RIVAL_MONEY_FAILURE") < 0:
		warnings.append("UNRESOLVED_RIVAL_MONEY_FAILURE")
	if int(metrics.get("max_consecutive_work_only_days", 0)) >= config.hard_work_only_days:
		warnings.append("WORK_ONLY_STREAK")
	if int(metrics.get("max_consecutive_dead_progress_days", 0)) >= config.hard_dead_progress_days:
		warnings.append("DEAD_PROGRESS_STREAK")
	var friction: float = float(metrics.get("max_goal_friction_ratio", 0.0))
	var support_actions: int = _highest_friction_support_actions(metrics)
	if friction >= config.hard_friction_ratio and support_actions >= config.hard_friction_support_actions:
		warnings.append("GOAL_FRICTION")
	if float(metrics.get("economy_support_share", 0.0)) >= config.hard_economy_share and int(metrics.get("total_actions", 0)) >= config.hard_economy_min_actions:
		warnings.append("ECONOMY_SUPPORT_HIGH")
	if record.aborted and warnings.find("ABORTED") < 0:
		warnings.append("ABORTED")
	return warnings


func _highest_friction_support_actions(metrics: Dictionary) -> int:
	if metrics.has("highest_friction_support_actions"):
		return int(metrics.get("highest_friction_support_actions", 0))
	var highest_id: String = str(metrics.get("highest_friction_goal_id", ""))
	var friction_map: Variant = metrics.get("goal_friction", {})
	if friction_map is Dictionary and friction_map.has(highest_id):
		var entry: Variant = friction_map[highest_id]
		if entry is Dictionary:
			return int(entry.get("support_actions", 0))
	return 0


func _collect_hard_bad_seeds(records: Array) -> Array:
	var bad: Array = []
	for record in records:
		if is_hard_bad_seed(record):
			bad.append(record)
	bad.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		if a.hard_warnings.size() != b.hard_warnings.size():
			return a.hard_warnings.size() > b.hard_warnings.size()
		if a.badness_score != b.badness_score:
			return a.badness_score > b.badness_score
		return a.base_seed < b.base_seed
	)
	return bad


func _collect_top_badness_seeds(records: Array, display_k: int) -> Array:
	var ranked: Array = []
	for record in records:
		if record is ProgressionLabRunRecord:
			ranked.append(record)
	ranked.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		if a.badness_score != b.badness_score:
			return a.badness_score > b.badness_score
		return a.base_seed < b.base_seed
	)
	var limited: Array = []
	for i in range(mini(display_k, ranked.size())):
		limited.append(ranked[i])
	return limited


func _collect_all_bad_seeds(records: Array, _config: ProgressionLabConfig) -> Array:
	return _collect_hard_bad_seeds(records)


func _select_bad_seeds(records: Array, config: ProgressionLabConfig) -> Array:
	var all_bad: Array = _collect_hard_bad_seeds(records)
	var display_k: int = config.bad_seed_count_display if config.bad_seed_count_display > 0 else config.default_bad_seed_count
	var limited: Array = []
	for i in range(mini(display_k, all_bad.size())):
		limited.append(_seed_row(all_bad[i]))
	return limited


func _warning_prevalence(records: Array, n: int) -> Array:
	var counts: Dictionary = {}
	for record in records:
		var seen: Dictionary = {}
		for warning in record.hard_warnings:
			var key: String = str(warning)
			var warning_class: String = warning_severity(key)
			if warning_class.is_empty():
				continue
			if seen.has(key):
				continue
			seen[key] = true
			if not counts.has(key):
				counts[key] = {"warning_class": warning_class, "run_count": 0}
			var entry: Dictionary = counts[key]
			entry["run_count"] = int(entry.get("run_count", 0)) + 1
			counts[key] = entry
	var rows: Array = []
	var keys: Array = counts.keys()
	keys.sort()
	for key in keys:
		var entry: Dictionary = counts[key]
		var run_count: int = int(entry.get("run_count", 0))
		rows.append({
			"warning_id": str(key),
			"warning_class": str(entry.get("warning_class", "")),
			"run_count": run_count,
			"run_share": float(run_count) / float(maxi(n, 1)),
		})
	return rows


func _diagnostic_metrics(records: Array) -> Dictionary:
	var result: Dictionary = {}
	for key in DIAGNOSTIC_METRIC_KEYS:
		result[key] = _metric_describe(records, key)
	return result


func _select_representative(records: Array) -> Dictionary:
	if records.is_empty():
		return {}
	var by_days: Array = records.duplicate()
	by_days.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		return int(a.campaign_metrics.get("calendar_days", 0)) < int(b.campaign_metrics.get("calendar_days", 0))
	)
	var by_economy: Array = records.duplicate()
	by_economy.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		return float(a.campaign_metrics.get("economy_support_share", 0.0)) < float(b.campaign_metrics.get("economy_support_share", 0.0))
	)
	var by_novelty: Array = records.duplicate()
	by_novelty.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		return float(a.campaign_metrics.get("novelty_density", 0.0)) < float(b.campaign_metrics.get("novelty_density", 0.0))
	)
	return {
		"median": _seed_row(by_days[int(by_days.size() / 2)]),
		"p10_duration": _seed_row(by_days[int(float(by_days.size() - 1) * 0.10)]),
		"p90_duration": _seed_row(by_days[int(float(by_days.size() - 1) * 0.90)]),
		"median_economy_support": _seed_row(by_economy[int(by_economy.size() / 2)]),
		"highest_novelty": _seed_row(by_novelty[by_novelty.size() - 1]),
		"lowest_novelty": _seed_row(by_novelty[0]),
	}


func _seed_row(record: ProgressionLabRunRecord) -> Dictionary:
	var metrics: Dictionary = record.campaign_metrics
	var plan_line: String = ""
	if not record.stage_plans.is_empty() and record.stage_plans[0] is Dictionary:
		plan_line = str(record.stage_plans[0].get("content_hash", ""))
	return {
		"seed": record.base_seed,
		"archetype": String(record.archetype),
		"badness_score": record.badness_score,
		"hard_warnings": Array(record.hard_warnings),
		"campaign_days": int(metrics.get("calendar_days", 0)),
		"work_actions": int(metrics.get("work_actions", 0)),
		"max_work_only_streak": int(metrics.get("max_consecutive_work_only_days", 0)),
		"money_blocked": int(metrics.get("money_blocked_decision_points", 0)),
		"max_goal_friction": float(metrics.get("max_goal_friction_ratio", 0.0)),
		"novelty_density": float(metrics.get("novelty_density", 0.0)),
		"stage_plan_summary": plan_line,
		"primary_warning": String(record.hard_warnings[0]) if record.hard_warnings.size() > 0 else "",
		"stop_reason": record.stop_reason,
		"execution_signature": record.execution_signature,
		"diagnostic_snapshot": record.diagnostic_snapshot.duplicate(true),
	}


func _aggregate_warnings(records: Array, config: ProgressionLabConfig) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	var economy: PackedFloat64Array = PackedFloat64Array()
	var dead_streak: PackedFloat64Array = PackedFloat64Array()
	var friction: PackedFloat64Array = PackedFloat64Array()
	var novelty: PackedFloat64Array = PackedFloat64Array()
	var work_streak: PackedFloat64Array = PackedFloat64Array()
	for record in records:
		var metrics: Dictionary = record.campaign_metrics
		work_streak.append(float(metrics.get("max_consecutive_work_only_days", 0)))
		economy.append(float(metrics.get("economy_support_share", 0.0)))
		dead_streak.append(float(metrics.get("max_consecutive_dead_progress_days", 0)))
		friction.append(float(metrics.get("max_goal_friction_ratio", 0.0)))
		novelty.append(float(metrics.get("novelty_density", 0.0)))
	work_streak.sort()
	economy.sort()
	dead_streak.sort()
	friction.sort()
	novelty.sort()
	var work_p90: float = percentile(work_streak, 0.90)
	var economy_p50: float = percentile(economy, 0.50)
	var economy_p90: float = percentile(economy, 0.90)
	var dead_p90: float = percentile(dead_streak, 0.90)
	var friction_p90: float = percentile(friction, 0.90)
	var novelty_p10: float = percentile(novelty, 0.10)
	if work_p90 >= config.warning_work_streak_p90:
		warnings.append("WORK_STREAK_P90=%.2f" % work_p90)
	if economy_p50 >= config.warning_economy_p50:
		warnings.append("ECONOMY_SUPPORT_HIGH_MEDIAN=%.3f" % economy_p50)
	if economy_p90 >= config.warning_economy_p90:
		warnings.append("ECONOMY_SUPPORT_HIGH_TAIL=%.3f" % economy_p90)
	if dead_p90 >= config.warning_dead_streak_p90:
		warnings.append("DEAD_PROGRESS_STREAK_HIGH_TAIL=%.2f" % dead_p90)
	if friction_p90 >= config.warning_friction_p90:
		warnings.append("GOAL_FRICTION_HIGH_TAIL=%.2f" % friction_p90)
	if novelty_p10 <= config.warning_novelty_p10:
		warnings.append("NOVELTY_LOW_TAIL=%.3f" % novelty_p10)
	return warnings


func _aggregate_items(records: Array) -> Dictionary:
	var items: Dictionary = {}
	for record in records:
		for item_id in record.item_utility.keys():
			if not items.has(item_id):
				items[item_id] = {
					"eligible_runs": 0,
					"acquired_runs": 0,
					"considered_after_purchase": 0,
					"used_after_purchase": 0,
					"positive_effect_count": 0,
					"requirement_unlock_count": 0,
				}
			var entry: Dictionary = items[item_id]
			var utility: Dictionary = record.item_utility[item_id]
			entry["eligible_runs"] = int(entry["eligible_runs"]) + 1
			if bool(utility.get("acquired", false)):
				entry["acquired_runs"] = int(entry["acquired_runs"]) + 1
			entry["considered_after_purchase"] = int(entry["considered_after_purchase"]) + int(utility.get("times_considered", 0))
			entry["used_after_purchase"] = int(entry["used_after_purchase"]) + int(utility.get("times_selected", 0))
			entry["positive_effect_count"] = int(entry["positive_effect_count"]) + int(utility.get("times_produced_positive_score", 0))
			entry["requirement_unlock_count"] = int(entry["requirement_unlock_count"]) + int(utility.get("times_unlocked_requirement", 0))
	for item_id in items.keys():
		var entry: Dictionary = items[item_id]
		var acquired: int = maxi(int(entry["acquired_runs"]), 1)
		entry["acquisition_rate"] = float(entry["acquired_runs"]) / float(maxi(int(entry["eligible_runs"]), 1))
		entry["use_per_acquisition"] = float(entry["used_after_purchase"]) / float(acquired)
		entry["positive_effect_per_acquisition"] = float(entry["positive_effect_count"]) / float(acquired)
		entry["unlock_per_acquisition"] = float(entry["requirement_unlock_count"]) / float(acquired)
	return items

func _rival_cash_aggregate(records: Array) -> Dictionary:
	var runs_with: int = 0
	var total: int = 0
	var story: int = 0
	var ordinary: int = 0
	var work_support: int = 0
	var money_failures: int = 0
	var resolved: int = 0
	var unresolved: int = 0
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var metrics: Dictionary = record.campaign_metrics
		var row_total: int = int(metrics.get("total_rival_cash_dependencies", 0))
		if row_total > 0 or int(metrics.get("rival_action_money_failures", 0)) > 0:
			runs_with += 1
		total += row_total
		story += int(metrics.get("story_rival_cash_dependencies", 0))
		ordinary += int(metrics.get("ordinary_rival_cash_dependencies", 0))
		work_support += int(metrics.get("work_actions_supporting_rival", 0))
		money_failures += int(metrics.get("rival_action_money_failures", 0))
		resolved += int(metrics.get("resolved_rival_money_failures", 0))
		unresolved += int(metrics.get("unresolved_rival_money_failures", 0))
	var mean_work: float = float(work_support) / float(maxi(money_failures, 1))
	return {
		"runs_with_rival_cash_dependency": runs_with,
		"total_rival_cash_dependencies": total,
		"story_rival_cash_dependencies": story,
		"ordinary_rival_cash_dependencies": ordinary,
		"work_actions_supporting_rival": work_support,
		"mean_work_actions_per_rival_goal": mean_work,
		"rival_action_money_failures": money_failures,
		"resolved_rival_money_failures": resolved,
		"unresolved_rival_money_failures": unresolved,
	}

func _post_date_tail_aggregate(records: Array) -> Dictionary:
	return {
		"days": _metric_describe(records, "days_after_last_date_before_stage_completion"),
		"actions": _metric_describe(records, "actions_after_last_date_before_stage_completion"),
		"work": _metric_describe(records, "work_actions_after_last_date_before_stage_completion"),
		"purchases": _metric_describe(records, "purchases_after_last_date_before_stage_completion"),
	}


func _work_attribution_aggregate(records: Array) -> Dictionary:
	return {
		"characteristics": _metric_describe(records, "work_actions_for_characteristics"),
		"outfits": _metric_describe(records, "work_actions_for_outfits"),
		"apartment": _metric_describe(records, "work_actions_for_apartment"),
		"dates": _metric_describe(records, "work_actions_for_dates"),
		"rivals": _metric_describe(records, "work_actions_for_rivals"),
		"other": _metric_describe(records, "work_actions_for_other"),
		"career": _metric_describe(records, "work_actions_for_career"),
	}


func _career_progression_aggregate(records: Array) -> Dictionary:
	var rank_0_only: int = 0
	var rank_1_plus: int = 0
	var rank_2_plus: int = 0
	var rank_3: int = 0
	var rank_1_before: int = 0
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var end_rank: int = int(record.campaign_metrics.get("career_rank_end", 0))
		if end_rank <= 0:
			rank_0_only += 1
		if end_rank >= 1:
			rank_1_plus += 1
		if end_rank >= 2:
			rank_2_plus += 1
		if end_rank >= 3:
			rank_3 += 1
		if bool(record.campaign_metrics.get("rank_1_before_connections", false)):
			rank_1_before += 1
	var n: int = maxi(records.size(), 1)
	return {
		"rank_0_only": rank_0_only,
		"rank_1_plus": rank_1_plus,
		"rank_2_plus": rank_2_plus,
		"rank_3": rank_3,
		"rank_1_before_connections_count": rank_1_before,
		"rank_1_before_connections_share": float(rank_1_before) / float(n),
		"connections_unlock_day": _career_day_describe(records, "career_connections_unlock_day"),
		"rank_2_delay_after_connections": _career_rank_2_delay_describe(records),
		"rank_1_day": _career_day_describe(records, "career_rank_1_day"),
		"rank_2_day": _career_day_describe(records, "career_rank_2_day"),
		"rank_3_day": _career_day_describe(records, "career_rank_3_day"),
		"rank_1_stage_distribution": _career_stage_distribution(records, "career_rank_1_stage"),
		"rank_2_stage_distribution": _career_stage_distribution(records, "career_rank_2_stage"),
		"rank_3_stage_distribution": _career_stage_distribution(records, "career_rank_3_stage"),
		"work_at_rank_0": _metric_describe(records, "work_actions_at_rank_0"),
		"work_at_rank_1": _metric_describe(records, "work_actions_at_rank_1"),
		"work_at_rank_2": _metric_describe(records, "work_actions_at_rank_2"),
		"work_at_rank_3": _metric_describe(records, "work_actions_at_rank_3"),
		"promotion_actions": _metric_describe(records, "career_advancement_actions"),
		"capital_training_for_career": _metric_describe(records, "career_investment_capital_training_actions"),
		"work_supporting_career": _metric_describe(records, "work_actions_supporting_career"),
		"career_support_work_before_rank_1": _metric_describe(records, "career_support_work_before_rank_1"),
		"career_support_work_before_rank_2": _metric_describe(records, "career_support_work_before_rank_2"),
		"career_support_work_before_rank_3": _metric_describe(records, "career_support_work_before_rank_3"),
		"career_support_work_wasted": _metric_describe(records, "career_support_work_wasted"),
		"career_negative_or_zero_roi_investments": _metric_describe(records, "career_negative_or_zero_roi_investments"),
		"career_positive_roi_investments": _metric_describe(records, "career_positive_roi_investments"),
		"career_reservation_started": _metric_describe(records, "career_reservation_started_count"),
		"career_reservation_completed": _metric_describe(records, "career_reservation_completed_count"),
		"career_reservation_overrides": _metric_describe(records, "career_reservation_override_count"),
		"career_reserved_money_peak": _metric_describe(records, "career_reserved_money_peak"),
		"rank_1_stage_day": _career_stage_day_describe(records, 1),
	}

func _career_day_describe(records: Array, key: String) -> Dictionary:
	var values: PackedFloat64Array = PackedFloat64Array()
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var day: int = int(record.campaign_metrics.get(key, -1))
		if day >= 0:
			values.append(float(day))
	return describe(values)


func _career_stage_day_describe(records: Array, rank: int) -> Dictionary:
	var values: PackedFloat64Array = PackedFloat64Array()
	var day_key: String = "career_rank_%d_day" % rank
	var stage_key: String = "career_rank_%d_stage" % rank
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var day: int = int(record.campaign_metrics.get(day_key, -1))
		var stage: int = int(record.campaign_metrics.get(stage_key, -1))
		if day < 0 or stage < 1:
			continue
		var stage_metrics: Dictionary = record.stage_metrics.get(str(stage), {})
		var start: int = int(stage_metrics.get("stage_start_calendar_day", 0))
		values.append(float(maxi(day - start, 0)))
	return describe(values)

func _career_stage_distribution(records: Array, key: String) -> Dictionary:
	var counts: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0}
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var stage_key: String = str(int(record.campaign_metrics.get(key, -1)))
		if counts.has(stage_key):
			counts[stage_key] = int(counts[stage_key]) + 1
	return counts


func _career_rank_2_delay_describe(records: Array) -> Dictionary:
	var values: PackedFloat64Array = PackedFloat64Array()
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var rank_2_day: int = int(record.campaign_metrics.get("career_rank_2_day", -1))
		var connections_day: int = int(record.campaign_metrics.get("career_connections_unlock_day", -1))
		if rank_2_day >= 0 and connections_day >= 0:
			values.append(float(rank_2_day - connections_day))
	return describe(values)


func _stale_planned_aggregate(records: Array) -> Dictionary:
	var details: Array = []
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var rows: Variant = record.campaign_metrics.get("stale_planned_goals", [])
		if rows is Array:
			for row in rows:
				if row is Dictionary:
					var copy: Dictionary = row.duplicate(true)
					copy["seed"] = record.base_seed
					details.append(copy)
	return {
		"count": _metric_describe(records, "stale_planned_goal_count"),
		"details": details,
	}


func _build_timing_aggregate(records: Array) -> Dictionary:
	var remaining: Dictionary = {
		"outfit": PackedFloat64Array(),
		"apartment": PackedFloat64Array(),
		"characteristic": PackedFloat64Array(),
	}
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var rows: Variant = record.campaign_metrics.get("build_acquisitions", [])
		if not (rows is Array):
			continue
		for row in rows:
			if not (row is Dictionary):
				continue
			var goal_id: String = str(row.get("goal_id", ""))
			var kind: String = ""
			if goal_id.begins_with("characteristic:"):
				kind = "characteristic"
			elif goal_id.begins_with("outfit:"):
				kind = "outfit"
			elif goal_id.begins_with("apartment:"):
				kind = "apartment"
			if kind.is_empty():
				continue
			var values: PackedFloat64Array = remaining[kind]
			values.append(float(row.get("remaining_stage_dates_at_acquisition", 0)))
			remaining[kind] = values
	return {
		"outfit_remaining_dates": describe(remaining["outfit"]),
		"apartment_remaining_dates": describe(remaining["apartment"]),
		"characteristic_remaining_dates": describe(remaining["characteristic"]),
		"stale_planned_goal_count": _metric_describe(records, "stale_planned_goal_count"),
	}


func _goal_friction_by_type(records: Array) -> Dictionary:
	var buckets: Dictionary = {}
	for type_name in [
		"Characteristic",
		"Outfit",
		"Apartment Object",
		"Filler Girl",
		"Story Girl",
		"Ordinary Rival",
		"Story Rival",
		"Venue exploration",
		"Mandatory acquisition",
	]:
		buckets[type_name] = {
			"goal_count": 0,
			"direct": PackedFloat64Array(),
			"support": PackedFloat64Array(),
			"ratios": PackedFloat64Array(),
			"days": PackedFloat64Array(),
		}
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		var friction: Variant = record.campaign_metrics.get("goal_friction", {})
		if not (friction is Dictionary):
			continue
		for goal_id in friction.keys():
			var type_name: String = ProgressionLabMetrics.classify_goal_friction_type(str(goal_id))
			if not buckets.has(type_name):
				continue
			var entry: Dictionary = friction[goal_id]
			var bucket: Dictionary = buckets[type_name]
			bucket["goal_count"] = int(bucket["goal_count"]) + 1
			var direct_actions: int = int(entry.get("direct_actions", 0))
			var support_actions: int = int(entry.get("support_actions", 0))
			var ratio: float = float(support_actions) / float(maxi(direct_actions, 1))
			var direct_values: PackedFloat64Array = bucket["direct"]
			direct_values.append(float(direct_actions))
			bucket["direct"] = direct_values
			var support_values: PackedFloat64Array = bucket["support"]
			support_values.append(float(support_actions))
			bucket["support"] = support_values
			var ratio_values: PackedFloat64Array = bucket["ratios"]
			ratio_values.append(ratio)
			bucket["ratios"] = ratio_values
			var days: int = int(entry.get("calendar_days_from_first_attempt_to_completion", 0))
			var day_values: PackedFloat64Array = bucket["days"]
			day_values.append(float(days))
			bucket["days"] = day_values
	var result: Dictionary = {}
	for type_name in buckets.keys():
		var bucket: Dictionary = buckets[type_name]
		var ratio_stats: Dictionary = describe(bucket["ratios"])
		result[type_name] = {
			"goal_count": int(bucket["goal_count"]),
			"mean_direct_actions": float(describe(bucket["direct"]).get("mean", 0.0)),
			"mean_support_actions": float(describe(bucket["support"]).get("mean", 0.0)),
			"mean_friction_ratio": float(ratio_stats.get("mean", 0.0)),
			"P50_friction_ratio": float(ratio_stats.get("P50", 0.0)),
			"P90_friction_ratio": float(ratio_stats.get("P90", 0.0)),
			"mean_completion_days": float(describe(bucket["days"]).get("mean", 0.0)),
		}
	return result


func _metric_describe(records: Array, key: String) -> Dictionary:
	var values: PackedFloat64Array = PackedFloat64Array()
	for record in records:
		if not (record is ProgressionLabRunRecord):
			continue
		values.append(float(record.campaign_metrics.get(key, 0.0)))
	return describe(values)
