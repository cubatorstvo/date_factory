class_name ProgressionLabAnalyzer
extends RefCounted

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
	var all_bad: Array = _collect_all_bad_seeds(summaries, config)
	var display_k: int = config.bad_seed_count_display if config.bad_seed_count_display > 0 else config.default_bad_seed_count
	result.all_bad_seeds = []
	for record in all_bad:
		result.all_bad_seeds.append(_seed_row(record))
	result.bad_seed_count = result.all_bad_seeds.size()
	result.bad_seed_percentage = float(result.bad_seed_count) / float(maxi(result.n, 1))
	result.top_bad_seeds = []
	for i in range(mini(display_k, result.all_bad_seeds.size())):
		result.top_bad_seeds.append(result.all_bad_seeds[i])
	result.bad_seeds = result.all_bad_seeds.duplicate(true)
	result.representative_seeds = _select_representative(summaries)
	result.analysis_warnings = _aggregate_warnings(summaries, config)
	result.warning_prevalence = _warning_prevalence(summaries, result.n)
	result.item_metrics = _aggregate_items(summaries)


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
		_append_series(series, "one_minus_novelty", 1.0 - float(metrics.get("novelty_density", 0.0)))
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
			+ config.badness_novelty_weight * _rank(series["one_minus_novelty"], 1.0 - float(metrics.get("novelty_density", 0.0)))
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


func _hard_warnings_for(record: ProgressionLabRunRecord, config: ProgressionLabConfig) -> PackedStringArray:
	var warnings: PackedStringArray = record.hard_warnings.duplicate()
	var metrics: Dictionary = record.campaign_metrics
	if int(metrics.get("max_consecutive_work_only_days", 0)) >= config.hard_work_only_days:
		warnings.append("WORK_ONLY_STREAK")
	if int(metrics.get("max_consecutive_dead_progress_days", 0)) >= config.hard_dead_progress_days:
		warnings.append("DEAD_PROGRESS_STREAK")
	if int(metrics.get("money_blocked_decision_points", 0)) >= config.hard_money_blocked:
		warnings.append("MONEY_BLOCKED")
	var friction: float = float(metrics.get("max_goal_friction_ratio", 0.0))
	var highest_id: String = str(metrics.get("highest_friction_goal_id", ""))
	var support_actions: int = 0
	var friction_map: Variant = metrics.get("goal_friction", {})
	if friction_map is Dictionary and friction_map.has(highest_id):
		var entry: Variant = friction_map[highest_id]
		if entry is Dictionary:
			support_actions = int(entry.get("support_actions", 0))
	if friction >= config.hard_friction_ratio and support_actions >= config.hard_friction_support_actions:
		warnings.append("GOAL_FRICTION")
	if float(metrics.get("economy_support_share", 0.0)) >= config.hard_economy_share and int(metrics.get("total_actions", 0)) >= config.hard_economy_min_actions:
		warnings.append("ECONOMY_SUPPORT")
	if record.aborted:
		warnings.append("ABORTED")
	return warnings


func _collect_all_bad_seeds(records: Array, config: ProgressionLabConfig) -> Array:
	var bad: Array = []
	for record in records:
		if record.badness_score >= 90 or record.hard_warnings.size() > 0:
			bad.append(record)
	bad.sort_custom(func(a: ProgressionLabRunRecord, b: ProgressionLabRunRecord) -> bool:
		if a.hard_warnings.size() != b.hard_warnings.size():
			return a.hard_warnings.size() > b.hard_warnings.size()
		if a.badness_score != b.badness_score:
			return a.badness_score > b.badness_score
		return a.base_seed < b.base_seed
	)
	return bad


func _select_bad_seeds(records: Array, config: ProgressionLabConfig) -> Array:
	var all_bad: Array = _collect_all_bad_seeds(records, config)
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
			if seen.has(key):
				continue
			seen[key] = true
			counts[key] = int(counts.get(key, 0)) + 1
	var rows: Array = []
	var keys: Array = counts.keys()
	keys.sort()
	for key in keys:
		var run_count: int = int(counts[key])
		rows.append({
			"warning_id": str(key),
			"run_count": run_count,
			"run_share": float(run_count) / float(maxi(n, 1)),
		})
	return rows


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
	var days: PackedFloat64Array = PackedFloat64Array()
	var economy: PackedFloat64Array = PackedFloat64Array()
	var money_block: PackedFloat64Array = PackedFloat64Array()
	var dead: PackedFloat64Array = PackedFloat64Array()
	var friction: PackedFloat64Array = PackedFloat64Array()
	var novelty: PackedFloat64Array = PackedFloat64Array()
	var work_streak: PackedFloat64Array = PackedFloat64Array()
	for record in records:
		var metrics: Dictionary = record.campaign_metrics
		work_streak.append(float(metrics.get("max_consecutive_work_only_days", 0)))
		economy.append(float(metrics.get("economy_support_share", 0.0)))
		money_block.append(float(metrics.get("money_blocked_decision_points", 0)))
		dead.append(float(metrics.get("dead_progress_days", 0)))
		friction.append(float(metrics.get("max_goal_friction_ratio", 0.0)))
		novelty.append(float(metrics.get("novelty_density", 0.0)))
		days.append(float(metrics.get("calendar_days", 0)))
	work_streak.sort()
	economy.sort()
	money_block.sort()
	dead.sort()
	friction.sort()
	novelty.sort()
	var work_p90: float = percentile(work_streak, 0.90)
	var economy_p50: float = percentile(economy, 0.50)
	var economy_p90: float = percentile(economy, 0.90)
	var money_p90: float = percentile(money_block, 0.90)
	var dead_p90: float = percentile(dead, 0.90)
	var friction_p90: float = percentile(friction, 0.90)
	var novelty_p10: float = percentile(novelty, 0.10)
	if work_p90 >= config.warning_work_streak_p90:
		warnings.append("WORK_STREAK_P90=%.2f" % work_p90)
	if economy_p50 >= config.warning_economy_p50:
		warnings.append("ECONOMY_SUPPORT_HIGH_MEDIAN=%.3f" % economy_p50)
	if economy_p90 >= config.warning_economy_p90:
		warnings.append("ECONOMY_SUPPORT_HIGH_TAIL=%.3f" % economy_p90)
	if money_p90 >= config.warning_money_block_p90:
		warnings.append("MONEY_BLOCKING_HIGH_TAIL=%.2f" % money_p90)
	if dead_p90 >= config.warning_dead_days_p90:
		warnings.append("DEAD_PROGRESS_HIGH_TAIL=%.2f" % dead_p90)
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
