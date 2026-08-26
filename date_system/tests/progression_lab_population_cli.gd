extends SceneTree


func _init() -> void:
	call_deferred("_run_population")


func _run_population() -> void:
	print("POPULATION: start N=100 seeds 1..4")
	var runner := ProgressionLabRunner.new()
	var config := ProgressionLabConfig.new()
	runner.configure(config, 100, 1, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	var audit: Dictionary = runner.verify_all_replays()
	var result: ProgressionLabPopulationResult = runner.get_result()
	var folder: String = ""
	if int(audit.get("matched", 0)) == int(audit.get("total", -1)):
		folder = runner.export_full_statistics("")
	else:
		var exporter := ProgressionLabExporter.new()
		folder = exporter.export_full_statistics(result, "", {})
	var safety: int = 0
	var nouseful: int = 0
	var aborted: int = 0
	var invariant: int = 0
	var nouseful_by_stage: Dictionary = {}
	var stop_counts: Dictionary = {}
	var regression: Dictionary = {}
	var regression_seeds: PackedInt32Array = PackedInt32Array([7, 12, 15, 22, 23, 24, 31, 47, 80, 84, 86, 90, 94])
	for record in result.records:
		if record == null:
			continue
		var warnings: PackedStringArray = record.hard_warnings
		if warnings.find("SAFETY_CAP_DAYS") >= 0:
			safety += 1
		if str(record.stop_reason).begins_with("NO_USEFUL_ACTIONS_STAGE_"):
			nouseful += 1
			var stage_key: String = str(record.stop_reason)
			nouseful_by_stage[stage_key] = int(nouseful_by_stage.get(stage_key, 0)) + 1
		if record.aborted:
			aborted += 1
		if warnings.find("STAGE_TRANSITION_INVARIANT") >= 0:
			invariant += 1
		var stop: String = str(record.stop_reason)
		if stop.is_empty():
			stop = "completed"
		stop_counts[stop] = int(stop_counts.get(stop, 0)) + 1
		if regression_seeds.has(record.base_seed):
			print("Rival regression seed %d" % record.base_seed)
			regression[str(record.base_seed)] = {
				"aborted": record.aborted,
				"stop_reason": record.stop_reason,
				"calendar_days": int(record.campaign_metrics.get("calendar_days", 0)),
				"final_story_stage": record.final_story_stage,
				"unmet_goals": record.diagnostic_snapshot.get("unmet_goals", []),
				"last_rival_goal": record.diagnostic_snapshot.get("last_rival_goal", ""),
				"last_rival_action_failure": record.diagnostic_snapshot.get("last_rival_action_failure", ""),
			}
	var overall: Dictionary = result.statistics.get("overall", {})
	var payload: Dictionary = {
		"folder": folder,
		"n": result.n,
		"bad_seed_count": result.bad_seed_count,
		"bad_seed_percentage": result.bad_seed_percentage,
		"top_bad_seeds": result.top_bad_seeds.size(),
		"replay_matched": int(audit.get("matched", 0)),
		"replay_total": int(audit.get("total", 0)),
		"replay_mismatches": audit.get("mismatches", []),
		"safety_cap": safety,
		"no_useful": nouseful,
		"no_useful_by_stage": nouseful_by_stage,
		"aborted": aborted,
		"invariant": invariant,
		"stop_reasons": stop_counts,
		"regression_seeds": regression,
		"calendar_days": overall.get("calendar_days", {}),
		"work_actions": overall.get("work_actions", {}),
		"money_forced_work_days": overall.get("money_forced_work_days", {}),
		"dates": overall.get("dates", {}),
		"economy_support_share": overall.get("economy_support_share", {}),
		"max_consecutive_money_blocked_days": overall.get("max_consecutive_money_blocked_days", {}),
		"dead_progress_days": overall.get("dead_progress_days", {}),
		"max_consecutive_dead_progress_days": overall.get("max_consecutive_dead_progress_days", {}),
		"money_blocked_decision_points": overall.get("money_blocked_decision_points", {}),
		"money_blocked_days": overall.get("money_blocked_days", {}),
		"warning_prevalence": result.warning_prevalence,
		"performance": result.performance,
		"simulation_version": result.simulation_version,
		"git_dirty": result.git_dirty,
		"worktree_fingerprint": result.worktree_fingerprint,
		"rival_cash_dependency": result.rival_cash_dependency,
		"post_date_tail": result.post_date_tail,
		"build_timing": result.build_timing,
		"work_attribution": result.work_attribution,
		"career_progression": result.career_progression,
		"goal_friction_by_type": result.goal_friction_by_type,
		"stale_planned_goals_count": result.stale_planned_goals.get("count", {}),
		"stage_calendar_days": {
			"1": result.statistics.get("per_stage", {}).get("1", {}).get("calendar_days", {}),
			"2": result.statistics.get("per_stage", {}).get("2", {}).get("calendar_days", {}),
			"3": result.statistics.get("per_stage", {}).get("3", {}).get("calendar_days", {}),
			"4": result.statistics.get("per_stage", {}).get("4", {}).get("calendar_days", {}),
		},
		"apartment_item_telemetry": _apartment_item_telemetry(result.item_metrics),
	}
	var text: String = JSON.stringify(payload, "\t")
	print(text)
	print("Replay determinism: %d / %d matched" % [int(audit.get("matched", 0)), int(audit.get("total", 0))])
	var previous_path: String = "user://progression_lab_n100_summary.json"
	if FileAccess.file_exists(previous_path):
		var previous_file: FileAccess = FileAccess.open(previous_path, FileAccess.READ)
		var previous: Variant = JSON.parse_string(previous_file.get_as_text()) if previous_file != null else null
		if previous is Dictionary:
			print(_comparison_markdown(previous, payload))
	var report := FileAccess.open(previous_path, FileAccess.WRITE)
	if report != null:
		report.store_string(text)
		report.close()
	var mismatch_count: int = (audit.get("mismatches", []) as Array).size() if audit.get("mismatches", []) is Array else 0
	quit(1 if mismatch_count > 0 else 0)


func _apartment_item_telemetry(item_metrics: Dictionary) -> Dictionary:
	var acquired: int = 0
	var selected: int = 0
	var zero_use: int = 0
	var total_selected: int = 0
	for item_id in item_metrics.keys():
		if not str(item_id).begins_with("apartment__"):
			continue
		var entry: Dictionary = item_metrics[item_id] if item_metrics[item_id] is Dictionary else {}
		var acquired_runs: int = int(entry.get("acquired_runs", 0))
		if acquired_runs <= 0:
			continue
		acquired += 1
		var uses: int = int(entry.get("used_after_purchase", 0))
		total_selected += uses
		if uses > 0:
			selected += 1
		else:
			zero_use += 1
	return {
		"acquired_objects": acquired,
		"objects_with_selected_use": selected,
		"objects_with_zero_use": zero_use,
		"total_selected_apartment_moves": total_selected,
	}


func _comparison_markdown(previous: Dictionary, current: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Population comparison vs previous N=100")
	var prev_stops: Dictionary = previous.get("stop_reasons", {})
	var cur_stops: Dictionary = current.get("stop_reasons", {})
	lines.append("completed: %d -> %d" % [int(prev_stops.get("completed", 0)), int(cur_stops.get("completed", 0))])
	lines.append("aborted: %d -> %d" % [int(previous.get("aborted", 0)), int(current.get("aborted", 0))])
	for key in ["NO_USEFUL_ACTIONS_STAGE_1", "NO_USEFUL_ACTIONS_STAGE_2", "NO_USEFUL_ACTIONS_STAGE_3", "NO_USEFUL_ACTIONS_STAGE_4"]:
		lines.append("%s: %d -> %d" % [key, int(prev_stops.get(key, 0)), int(cur_stops.get(key, 0))])
	lines.append("SAFETY_CAP_DAYS: %d -> %d" % [int(previous.get("safety_cap", 0)), int(current.get("safety_cap", 0))])
	for metric in ["calendar_days", "work_actions", "dates", "economy_support_share", "money_blocked_days", "max_consecutive_money_blocked_days", "dead_progress_days"]:
		var prev_stats: Dictionary = previous.get(metric, {}) if previous.get(metric, {}) is Dictionary else {}
		var cur_stats: Dictionary = current.get(metric, {}) if current.get(metric, {}) is Dictionary else {}
		lines.append("%s P50/P90/P95/max: %s/%s/%s/%s -> %s/%s/%s/%s" % [
			metric,
			str(prev_stats.get("P50", "")),
			str(prev_stats.get("P90", "")),
			str(prev_stats.get("P95", "")),
			str(prev_stats.get("max", "")),
			str(cur_stats.get("P50", "")),
			str(cur_stats.get("P90", "")),
			str(cur_stats.get("P95", "")),
			str(cur_stats.get("max", "")),
		])
	var prev_friction: Dictionary = previous.get("statistics", {}).get("overall", {}).get("max_goal_friction_ratio", {}) if previous.get("statistics", {}) is Dictionary else {}
	lines.append("rival_cash_dependency: %s" % JSON.stringify(current.get("rival_cash_dependency", {})))
	return "\n".join(lines)