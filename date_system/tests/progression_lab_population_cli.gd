extends SceneTree


func _init() -> void:
	call_deferred("_run_population")


func _run_population() -> void:
	var runner := ProgressionLabRunner.new()
	var config := ProgressionLabConfig.new()
	runner.configure(config, 100, 1, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	var result: ProgressionLabPopulationResult = runner.get_result()
	var exporter := ProgressionLabExporter.new()
	var folder: String = exporter.export_full_statistics(result, "", {})
	var safety: int = 0
	var nouseful: int = 0
	var aborted: int = 0
	var invariant: int = 0
	var nouseful_by_stage: Dictionary = {}
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
	var overall: Dictionary = result.statistics.get("overall", {})
	var payload: Dictionary = {
		"folder": folder,
		"n": result.n,
		"bad_seeds": result.bad_seeds.size(),
		"safety_cap": safety,
		"no_useful": nouseful,
		"no_useful_by_stage": nouseful_by_stage,
		"aborted": aborted,
		"invariant": invariant,
		"calendar_days": overall.get("calendar_days", {}),
		"dead_progress_days": overall.get("dead_progress_days", {}),
		"max_consecutive_dead_progress_days": overall.get("max_consecutive_dead_progress_days", {}),
		"money_blocked_decision_points": overall.get("money_blocked_decision_points", {}),
		"money_blocked_days": overall.get("money_blocked_days", {}),
		"performance": result.performance,
	}
	var text: String = JSON.stringify(payload, "\t")
	print(text)
	var report := FileAccess.open("user://progression_lab_n100_summary.json", FileAccess.WRITE)
	if report != null:
		report.store_string(text)
		report.close()
	quit(0)
