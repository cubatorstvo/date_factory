extends SceneTree


func _init() -> void:
	call_deferred("_run_population")


func _run_population() -> void:
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
	var regression_seeds: PackedInt32Array = PackedInt32Array([7, 12, 22, 23, 24, 31, 47, 84, 90, 94])
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
			regression[str(record.base_seed)] = {
				"aborted": record.aborted,
				"stop_reason": record.stop_reason,
				"calendar_days": int(record.campaign_metrics.get("calendar_days", 0)),
				"final_story_stage": record.final_story_stage,
				"unmet_goals": record.diagnostic_snapshot.get("unmet_goals", []),
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
		"dead_progress_days": overall.get("dead_progress_days", {}),
		"max_consecutive_dead_progress_days": overall.get("max_consecutive_dead_progress_days", {}),
		"money_blocked_decision_points": overall.get("money_blocked_decision_points", {}),
		"money_blocked_days": overall.get("money_blocked_days", {}),
		"warning_prevalence": result.warning_prevalence,
		"performance": result.performance,
	}
	var text: String = JSON.stringify(payload, "\t")
	print(text)
	print("Replay determinism: %d / %d matched" % [int(audit.get("matched", 0)), int(audit.get("total", 0))])
	var report := FileAccess.open("user://progression_lab_n100_summary.json", FileAccess.WRITE)
	if report != null:
		report.store_string(text)
		report.close()
	var mismatch_count: int = (audit.get("mismatches", []) as Array).size() if audit.get("mismatches", []) is Array else 0
	quit(1 if mismatch_count > 0 else 0)