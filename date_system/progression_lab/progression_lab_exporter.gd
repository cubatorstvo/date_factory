class_name ProgressionLabExporter
extends RefCounted

const DEFAULT_ROOT: String = "user://progression_lab_exports/"


func default_export_root() -> String:
	return DEFAULT_ROOT


func export_full_statistics(result: ProgressionLabPopulationResult, directory: String = "", detailed_records: Dictionary = {}) -> String:
	var folder: String = _prepare_folder(result, directory)
	_write_text("%s/config.json" % folder, JSON.stringify(_config_payload(result), "\t"))
	_write_text("%s/aggregate_summary.md" % folder, _aggregate_markdown(result))
	_write_text("%s/aggregate_metrics.csv" % folder, _metrics_csv(result.statistics.get("overall", {})))
	_write_text("%s/stage_metrics.csv" % folder, _group_csv(result.statistics.get("per_stage", {})))
	_write_text("%s/archetype_metrics.csv" % folder, _group_csv(result.statistics.get("per_archetype", {})))
	_write_text("%s/seed_summaries.csv" % folder, _seed_csv(result))
	_write_text("%s/bad_seeds.csv" % folder, _bad_csv(result.bad_seeds))
	_write_text("%s/item_metrics.csv" % folder, _item_csv(result.item_metrics))
	_write_text("%s/representative_seeds.csv" % folder, _representative_csv(result.representative_seeds))
	_write_text("%s/share_bundle.md" % folder, share_bundle_markdown(result))
	_write_text("%s/share_bundle.json" % folder, JSON.stringify(share_bundle_json(result), "\t"))
	_write_text("%s/warning_prevalence.csv" % folder, _warning_prevalence_csv(result))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/bad_seed_logs" % folder))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/representative_seed_logs" % folder))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/replay_mismatches" % folder))
	for row in result.top_bad_seeds:
		var seed: int = int(row.get("seed", 0))
		var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
		if record != null:
			_write_verified_seed_pair("%s/bad_seed_logs" % folder, record, result, detailed_records.get("expected_%d" % seed, null))
	for key in result.representative_seeds.keys():
		var row: Variant = result.representative_seeds[key]
		if row is Dictionary:
			var seed: int = int(row.get("seed", 0))
			var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
			if record != null:
				_write_verified_seed_pair("%s/representative_seed_logs" % folder, record, result, detailed_records.get("expected_%d" % seed, null))
	for mismatch in result.replay_mismatches:
		if mismatch is Dictionary:
			var seed: int = int(mismatch.get("seed", 0))
			_write_text("%s/replay_mismatches/seed_%d_replay_mismatch.json" % [folder, seed], JSON.stringify(mismatch, "\t"))
			_write_text("%s/replay_mismatches/seed_%d_replay_mismatch.md" % [folder, seed], _mismatch_markdown(mismatch))
	return ProjectSettings.globalize_path(folder)


func export_bad_seeds_only(result: ProgressionLabPopulationResult, directory: String = "", detailed_records: Dictionary = {}) -> String:
	var folder: String = _prepare_folder(result, directory, "bad")
	_write_text("%s/config.json" % folder, JSON.stringify(_config_payload(result), "\t"))
	_write_text("%s/bad_seeds.csv" % folder, _bad_csv(result.all_bad_seeds))
	_write_text("%s/bad_seeds_summary.md" % folder, _bad_summary_md(result))
	var jsonl: PackedStringArray = PackedStringArray()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/logs" % folder))
	for row in result.all_bad_seeds:
		jsonl.append(JSON.stringify(row))
	_write_text("%s/bad_seeds.jsonl" % folder, "\n".join(jsonl))
	for row in result.top_bad_seeds:
		var seed: int = int(row.get("seed", 0))
		var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
		if record != null:
			_write_verified_seed_pair("%s/logs" % folder, record, result, detailed_records.get("expected_%d" % seed, null))
	return ProjectSettings.globalize_path(folder)

func export_specific_seed(record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult, directory: String = "") -> String:
	var folder: String = directory
	if folder.is_empty():
		folder = DEFAULT_ROOT
	if not folder.ends_with("/"):
		folder += "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var md_path: String = "%sseed_%d.md" % [folder, record.base_seed]
	var json_path: String = "%sseed_%d.json" % [folder, record.base_seed]
	_write_text(md_path, specific_seed_markdown(record, result))
	_write_text(json_path, JSON.stringify(specific_seed_json(record, result), "\t"))
	return ProjectSettings.globalize_path(folder)


func share_bundle_markdown(result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Monte Carlo Progression Lab")
	lines.append("")
	lines.append("schema_version: %d" % result.schema_version)
	lines.append("simulation_version: %s" % result.simulation_version)
	lines.append("git_dirty: %s" % str(result.git_dirty).to_lower())
	lines.append("worktree_fingerprint: %s" % result.worktree_fingerprint)
	lines.append("Simulation version: %s" % result.simulation_version)
	lines.append("Git dirty: %s" % str(result.git_dirty))
	lines.append("Worktree fingerprint: %s" % result.worktree_fingerprint)
	lines.append("N: %d" % result.n)
	lines.append("end_story_stage: %d" % result.end_story_stage)
	lines.append("archetype_mode: %s" % String(result.archetype_mode))
	lines.append("")
	lines.append("## Config")
	lines.append("")
	lines.append("```json")
	lines.append(JSON.stringify(result.config, "\t"))
	lines.append("```")
	lines.append("")
	lines.append("## Aggregate P10 / P50 / P90 / P95")
	lines.append("")
	var overall: Dictionary = result.statistics.get("overall", {})
	for key in ["calendar_days", "work_actions", "dates", "economy_support_share", "dead_progress_days", "money_blocked_decision_points", "money_blocked_days", "max_goal_friction_ratio", "novelty_density"]:
		if overall.has(key):
			var stats: Dictionary = overall[key]
			lines.append("- %s: P10=%.3f P50=%.3f P90=%.3f P95=%.3f" % [
				key,
				float(stats.get("P10", 0.0)),
				float(stats.get("P50", 0.0)),
				float(stats.get("P90", 0.0)),
				float(stats.get("P95", 0.0)),
			])
	lines.append("")
	lines.append("## Stages")
	var stages: Dictionary = result.statistics.get("per_stage", {})
	for stage_key in stages.keys():
		lines.append("### Stage %s" % str(stage_key))
		var stage_stats: Dictionary = stages[stage_key]
		if stage_stats.has("calendar_days"):
			var days: Dictionary = stage_stats["calendar_days"]
			lines.append("calendar_days P50=%.2f" % float(days.get("P50", 0.0)))
	lines.append("")
	lines.append("## Bad seeds: %d / %d (%.1f%%)" % [result.bad_seed_count, maxi(result.n, 1), 100.0 * result.bad_seed_percentage])
	lines.append("Top %d of %d bad seeds" % [result.top_bad_seeds.size(), result.bad_seed_count])
	lines.append("")
	lines.append("## Warnings")
	for warning in result.analysis_warnings:
		lines.append("- %s" % warning)
	lines.append("")
	lines.append("## Warning prevalence")
	for row in result.warning_prevalence:
		lines.append("- %s: %d (%.1f%%)" % [str(row.get("warning_id", "")), int(row.get("run_count", 0)), 100.0 * float(row.get("run_share", 0.0))])
	lines.append("")
	lines.append("## Rival Cash Dependency")
	var rival_cash: Dictionary = result.rival_cash_dependency
	for key in ["runs_with_rival_cash_dependency", "total_rival_cash_dependencies", "story_rival_cash_dependencies", "ordinary_rival_cash_dependencies", "work_actions_supporting_rival", "mean_work_actions_per_rival_goal", "rival_action_money_failures", "resolved_rival_money_failures", "unresolved_rival_money_failures"]:
		lines.append("- %s: %s" % [key, str(rival_cash.get(key, 0))])
	lines.append("")
	lines.append("## Top bad seeds")
	for row in result.top_bad_seeds:
		lines.append("- seed %s [%s] badness=%s warning=%s days=%s stop=%s" % [
			str(row.get("seed", 0)),
			str(row.get("archetype", "")),
			str(row.get("badness_score", 0)),
			str(row.get("primary_warning", "")),
			str(row.get("campaign_days", 0)),
			str(row.get("stop_reason", "")),
		])
		var snapshot: Variant = row.get("diagnostic_snapshot", {})
		if snapshot is Dictionary and not (snapshot as Dictionary).is_empty():
			lines.append("  unmet=%s money=$%s equipped=%s" % [
				str(snapshot.get("unmet_goals", [])),
				str(snapshot.get("money", 0)),
				str(snapshot.get("equipped_outfit", "")),
			])
	lines.append("")
	lines.append("## Representative seeds")
	lines.append(JSON.stringify(result.representative_seeds, "\t"))
	lines.append("")
	lines.append("## Post-Date Tail")
	var tail: Dictionary = result.post_date_tail
	for key in ["days", "work", "purchases"]:
		var stats: Dictionary = tail.get(key, {})
		if stats is Dictionary:
			lines.append("- %s after last Date: P50=%.3f P90=%.3f P95=%.3f max=%.3f" % [
				key,
				float(stats.get("P50", 0.0)),
				float(stats.get("P90", 0.0)),
				float(stats.get("P95", 0.0)),
				float(stats.get("max", 0.0)),
			])
	lines.append("")
	lines.append("## Build Timing")
	var timing: Dictionary = result.build_timing
	for key in ["outfit_remaining_dates", "apartment_remaining_dates", "characteristic_remaining_dates"]:
		var stats: Dictionary = timing.get(key, {})
		if stats is Dictionary:
			lines.append("- %s: P10=%.3f P50=%.3f P90=%.3f" % [
				key,
				float(stats.get("P10", 0.0)),
				float(stats.get("P50", 0.0)),
				float(stats.get("P90", 0.0)),
			])
	var stale_stats: Dictionary = timing.get("stale_planned_goal_count", {})
	if stale_stats is Dictionary:
		lines.append("- stale planned goals: P50=%.3f P90=%.3f P95=%.3f max=%.3f" % [
			float(stale_stats.get("P50", 0.0)),
			float(stale_stats.get("P90", 0.0)),
			float(stale_stats.get("P95", 0.0)),
			float(stale_stats.get("max", 0.0)),
		])
	lines.append("")
	lines.append("## Work Attribution")
	var work_attr: Dictionary = result.work_attribution
	for key in ["characteristics", "outfits", "apartment", "dates", "rivals", "career", "other"]:
		var stats: Dictionary = work_attr.get(key, {})
		if stats is Dictionary:
			lines.append("- %s: mean=%.3f P50=%.3f P90=%.3f" % [
				key,
				float(stats.get("mean", 0.0)),
				float(stats.get("P50", 0.0)),
				float(stats.get("P90", 0.0)),
			])
	lines.append("")
	lines.append("## Career Progression")
	var career: Dictionary = result.career_progression
	lines.append("Rank reached:")
	lines.append("- Rank 0 only: %s" % str(career.get("rank_0_only", 0)))
	lines.append("- Rank 1+: %s" % str(career.get("rank_1_plus", 0)))
	lines.append("- Rank 2+: %s" % str(career.get("rank_2_plus", 0)))
	lines.append("- Rank 3: %s" % str(career.get("rank_3", 0)))
	for rank_key in ["rank_1_day", "rank_2_day", "rank_3_day"]:
		var day_stats: Dictionary = career.get(rank_key, {})
		if day_stats is Dictionary:
			lines.append("- %s: P10=%.3f P50=%.3f P90=%.3f" % [
				rank_key,
				float(day_stats.get("P10", 0.0)),
				float(day_stats.get("P50", 0.0)),
				float(day_stats.get("P90", 0.0)),
			])
	lines.append("Work by rank:")
	for rank_key in ["work_at_rank_0", "work_at_rank_1", "work_at_rank_2", "work_at_rank_3"]:
		var work_stats: Dictionary = career.get(rank_key, {})
		if work_stats is Dictionary:
			lines.append("- %s: mean=%.3f P50=%.3f P90=%.3f" % [
				rank_key,
				float(work_stats.get("mean", 0.0)),
				float(work_stats.get("P50", 0.0)),
				float(work_stats.get("P90", 0.0)),
			])
	lines.append("Career support:")
	for support_key in ["promotion_actions", "capital_training_for_career", "work_supporting_career"]:
		var support_stats: Dictionary = career.get(support_key, {})
		if support_stats is Dictionary:
			lines.append("- %s: mean=%.3f P50=%.3f P90=%.3f" % [
				support_key,
				float(support_stats.get("mean", 0.0)),
				float(support_stats.get("P50", 0.0)),
				float(support_stats.get("P90", 0.0)),
			])
	lines.append("")
	lines.append("## Goal Friction by Type")
	for type_name in result.goal_friction_by_type.keys():
		var row: Dictionary = result.goal_friction_by_type[type_name]
		lines.append("- %s: goals=%d mean_direct=%.2f mean_support=%.2f mean_ratio=%.3f P50=%.3f P90=%.3f mean_days=%.2f" % [
			str(type_name),
			int(row.get("goal_count", 0)),
			float(row.get("mean_direct_actions", 0.0)),
			float(row.get("mean_support_actions", 0.0)),
			float(row.get("mean_friction_ratio", 0.0)),
			float(row.get("P50_friction_ratio", 0.0)),
			float(row.get("P90_friction_ratio", 0.0)),
			float(row.get("mean_completion_days", 0.0)),
		])
	lines.append("")
	lines.append("## Apartment Item Utility")
	for item_id in result.item_metrics.keys():
		if not str(item_id).begins_with("apartment"):
			continue
		var entry: Dictionary = result.item_metrics[item_id]
		lines.append("- %s considered=%s selected=%s positive=%s unlock=%s use/acq=%.3f" % [
			str(item_id),
			str(entry.get("considered_after_purchase", 0)),
			str(entry.get("used_after_purchase", 0)),
			str(entry.get("positive_effect_count", 0)),
			str(entry.get("requirement_unlock_count", 0)),
			float(entry.get("use_per_acquisition", 0.0)),
		])
	lines.append("")
	lines.append("## Item utility (lowest use_per_acquisition first)")
	var item_rows: Array = []
	for item_id in result.item_metrics.keys():
		var entry: Dictionary = result.item_metrics[item_id]
		item_rows.append({"id": str(item_id), "use": float(entry.get("use_per_acquisition", 0.0)), "entry": entry})
	item_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["use"]) < float(b["use"])
	)
	for row in item_rows:
		lines.append("- %s use/acq=%.3f acq_rate=%.3f" % [str(row["id"]), float(row["use"]), float(row["entry"].get("acquisition_rate", 0.0))])
	return "\n".join(lines)


func share_bundle_json(result: ProgressionLabPopulationResult) -> Dictionary:
	return {
		"schema_version": result.schema_version,
		"simulation_version": result.simulation_version,
		"git_dirty": result.git_dirty,
		"worktree_fingerprint": result.worktree_fingerprint,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"project_version": _project_version(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"n": result.n,
		"config": result.config,
		"statistics": result.statistics,
		"bad_seed_count": result.bad_seed_count,
		"bad_seed_percentage": result.bad_seed_percentage,
		"top_bad_seeds": result.top_bad_seeds,
		"all_bad_seeds": result.all_bad_seeds,
		"warning_prevalence": result.warning_prevalence,
		"replay_matched": result.replay_matched,
		"replay_total": result.replay_total,
		"rival_cash_dependency": result.rival_cash_dependency,
		"analysis_warnings": Array(result.analysis_warnings),
		"representative_seeds": result.representative_seeds,
		"item_metrics": result.item_metrics,
		"performance": result.performance,
		"post_date_tail": result.post_date_tail,
		"build_timing": result.build_timing,
		"work_attribution": result.work_attribution,
		"goal_friction_by_type": result.goal_friction_by_type,
		"stale_planned_goals": result.stale_planned_goals,
		"career_progression": result.career_progression,
	}


func specific_seed_markdown(record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Specific Seed %d" % record.base_seed)
	lines.append("")
	lines.append("## Summary")
	lines.append("Archetype: %s" % String(record.archetype))
	lines.append("Badness: %d" % record.badness_score)
	lines.append("execution_signature: %s" % record.execution_signature)
	lines.append("Warnings: %s" % ", ".join(record.hard_warnings))
	if not record.stop_reason.is_empty():
		lines.append("Stop reason: %s" % record.stop_reason)
	if not record.diagnostic_snapshot.is_empty():
		lines.append("")
		lines.append("## Diagnostic snapshot")
		lines.append(JSON.stringify(record.diagnostic_snapshot, "\t"))
	lines.append("")
	lines.append("## Profile")
	lines.append(JSON.stringify(record.profile, "\t"))
	lines.append("")
	lines.append("## Stage Plan")
	for plan in record.stage_plans:
		lines.append(JSON.stringify(plan, "\t"))
	lines.append("")
	lines.append("## Daily timeline")
	if record.timeline_markdown.is_empty():
		lines.append("(compact summary run; replay with detailed=true for full timeline)")
	else:
		lines.append(record.timeline_markdown)
	lines.append("")
	lines.append("## Date summaries")
	lines.append(JSON.stringify(record.date_summaries, "\t"))
	lines.append("")
	lines.append("## Goal friction")
	lines.append(JSON.stringify(record.campaign_metrics.get("goal_friction", {}), "\t"))
	lines.append("")
	lines.append("## Metrics")
	lines.append(JSON.stringify(record.campaign_metrics, "\t"))
	if result != null:
		lines.append("")
		lines.append("schema_version: %d" % result.schema_version)
	return "\n".join(lines)


func specific_seed_json(record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult) -> Dictionary:
	return {
		"schema_version": result.schema_version if result != null else 1,
		"simulation_version": result.simulation_version if result != null else "",
		"git_dirty": result.git_dirty if result != null else false,
		"worktree_fingerprint": result.worktree_fingerprint if result != null else "",
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"project_version": _project_version(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"seed": record.base_seed,
		"execution_signature": record.execution_signature,
		"rng_draw_counts": record.rng_draw_counts,
		"config": result.config if result != null else {},
		"profile": record.profile,
		"stage_plans": record.stage_plans,
		"metrics": record.campaign_metrics,
		"stage_metrics": record.stage_metrics,
		"warnings": Array(record.hard_warnings),
		"stop_reason": record.stop_reason,
		"diagnostic_snapshot": record.diagnostic_snapshot.duplicate(true),
		"timeline_markdown": record.timeline_markdown,
		"daily_log": record.daily_log,
		"date_summaries": record.date_summaries,
		"item_utility": record.item_utility,
	}


func _write_seed_pair(folder: String, record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult) -> void:
	_write_text("%s/%d.md" % [folder, record.base_seed], specific_seed_markdown(record, result))
	_write_text("%s/%d.json" % [folder, record.base_seed], JSON.stringify(specific_seed_json(record, result), "\t"))


func _write_verified_seed_pair(folder: String, record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult, expected: Variant) -> void:
	if expected is ProgressionLabRunRecord:
		var pass1: ProgressionLabRunRecord = expected
		if pass1.execution_signature != record.execution_signature:
			var mismatch: Dictionary = ProgressionLabRunRecord.first_difference(pass1, record)
			_write_text("%s/seed_%d_replay_mismatch.json" % [folder, record.base_seed], JSON.stringify(mismatch, "\t"))
			_write_text("%s/seed_%d_replay_mismatch.md" % [folder, record.base_seed], _mismatch_markdown(mismatch))
			return
	_write_seed_pair(folder, record, result)


func _warning_prevalence_csv(result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("warning_id,run_count,run_share")
	for row in result.warning_prevalence:
		lines.append("%s,%s,%s" % [str(row.get("warning_id", "")), str(row.get("run_count", 0)), str(row.get("run_share", 0.0))])
	return "\n".join(lines)


func _mismatch_markdown(mismatch: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Replay mismatch seed %s" % str(mismatch.get("seed", 0)))
	lines.append("")
	lines.append("expected: %s" % str(mismatch.get("expected_signature", "")))
	lines.append("actual: %s" % str(mismatch.get("actual_signature", "")))
	lines.append("first differing action index: %s" % str(mismatch.get("first_differing_action_index", -1)))
	lines.append("summary action: %s" % str(mismatch.get("summary_action", "")))
	lines.append("replay action: %s" % str(mismatch.get("replay_action", "")))
	lines.append("summary stop: %s" % str(mismatch.get("summary_stop_reason", "")))
	lines.append("replay stop: %s" % str(mismatch.get("replay_stop_reason", "")))
	lines.append("summary days: %s replay days: %s" % [str(mismatch.get("summary_campaign_days", 0)), str(mismatch.get("replay_campaign_days", 0))])
	return "\n".join(lines)


func _prepare_folder(result: ProgressionLabPopulationResult, directory: String, suffix: String = "") -> String:
	var root: String = directory
	if root.is_empty():
		root = DEFAULT_ROOT
	if not root.ends_with("/"):
		root += "/"
	var stamp: String = Time.get_datetime_string_from_system(true, true).replace(":", "-").replace("T", "_")
	var name: String = "%s__N_%d__seed_%d" % [stamp, result.n, result.base_seed_start]
	if not suffix.is_empty():
		name += "__%s" % suffix
	var folder: String = root + name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	return folder


func _config_payload(result: ProgressionLabPopulationResult) -> Dictionary:
	return {
		"schema_version": result.schema_version,
		"simulation_version": result.simulation_version,
		"git_dirty": result.git_dirty,
		"worktree_fingerprint": result.worktree_fingerprint,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"project_version": _project_version(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"n": result.n,
		"seed_start": result.base_seed_start,
		"end_story_stage": result.end_story_stage,
		"archetype_mode": String(result.archetype_mode),
		"config": result.config,
	}


func _aggregate_markdown(result: ProgressionLabPopulationResult) -> String:
	return share_bundle_markdown(result)


func _metrics_csv(stats: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("metric,count,mean,sd,min,P10,P25,P50,P75,P90,P95,max")
	for key in stats.keys():
		var row: Dictionary = stats[key]
		lines.append("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
			str(key),
			str(row.get("count", 0)),
			str(row.get("mean", 0)),
			str(row.get("standard_deviation", 0)),
			str(row.get("min", 0)),
			str(row.get("P10", 0)),
			str(row.get("P25", 0)),
			str(row.get("P50", 0)),
			str(row.get("P75", 0)),
			str(row.get("P90", 0)),
			str(row.get("P95", 0)),
			str(row.get("max", 0)),
		])
	return "\n".join(lines)


func _group_csv(groups: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("group,metric,P50,P90")
	for group_key in groups.keys():
		var stats: Dictionary = groups[group_key]
		for metric_key in stats.keys():
			var row: Dictionary = stats[metric_key]
			lines.append("%s,%s,%s,%s" % [str(group_key), str(metric_key), str(row.get("P50", 0)), str(row.get("P90", 0))])
	return "\n".join(lines)


func _seed_csv(result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("seed,archetype,days,work,dates,economy,dead,friction,novelty,badness,warnings,signature,stop,days_after_last_date_before_stage_completion,actions_after_last_date_before_stage_completion,work_actions_after_last_date_before_stage_completion,purchases_after_last_date_before_stage_completion,money_forced_work_days,max_consecutive_money_forced_work_days,stale_planned_goal_count,work_actions_for_characteristics,work_actions_for_outfits,work_actions_for_apartment,work_actions_for_dates,work_actions_for_rivals,work_actions_for_other,work_actions_for_career,career_rank_start,career_rank_end,career_advancement_actions,career_rank_1_day,career_rank_2_day,career_rank_3_day,work_income_start,work_income_end,money_earned_from_work,work_actions_at_rank_0,work_actions_at_rank_1,work_actions_at_rank_2,work_actions_at_rank_3,career_investment_capital_training_actions,work_actions_supporting_career")
	for record in result.records:
		if not (record is ProgressionLabRunRecord):
			continue
		var metrics: Dictionary = record.campaign_metrics
		lines.append("%d,%s,%s,%s,%s,%s,%s,%s,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
			record.base_seed,
			String(record.archetype),
			str(metrics.get("calendar_days", 0)),
			str(metrics.get("work_actions", 0)),
			str(metrics.get("dates", 0)),
			str(metrics.get("economy_support_share", 0)),
			str(metrics.get("dead_progress_days", 0)),
			str(metrics.get("max_goal_friction_ratio", 0)),
			str(metrics.get("novelty_density", 0)),
			record.badness_score,
			"|".join(record.hard_warnings),
			record.execution_signature,
			record.stop_reason,
			str(metrics.get("days_after_last_date_before_stage_completion", 0)),
			str(metrics.get("actions_after_last_date_before_stage_completion", 0)),
			str(metrics.get("work_actions_after_last_date_before_stage_completion", 0)),
			str(metrics.get("purchases_after_last_date_before_stage_completion", 0)),
			str(metrics.get("money_forced_work_days", 0)),
			str(metrics.get("max_consecutive_money_forced_work_days", 0)),
			str(metrics.get("stale_planned_goal_count", 0)),
			str(metrics.get("work_actions_for_characteristics", 0)),
			str(metrics.get("work_actions_for_outfits", 0)),
			str(metrics.get("work_actions_for_apartment", 0)),
			str(metrics.get("work_actions_for_dates", 0)),
			str(metrics.get("work_actions_for_rivals", 0)),
			str(metrics.get("work_actions_for_other", 0)),
			str(metrics.get("work_actions_for_career", 0)),
			str(metrics.get("career_rank_start", 0)),
			str(metrics.get("career_rank_end", 0)),
			str(metrics.get("career_advancement_actions", 0)),
			str(metrics.get("career_rank_1_day", -1)),
			str(metrics.get("career_rank_2_day", -1)),
			str(metrics.get("career_rank_3_day", -1)),
			str(metrics.get("work_income_start", 0)),
			str(metrics.get("work_income_end", 0)),
			str(metrics.get("money_earned_from_work", 0)),
			str(metrics.get("work_actions_at_rank_0", 0)),
			str(metrics.get("work_actions_at_rank_1", 0)),
			str(metrics.get("work_actions_at_rank_2", 0)),
			str(metrics.get("work_actions_at_rank_3", 0)),
			str(metrics.get("career_investment_capital_training_actions", 0)),
			str(metrics.get("work_actions_supporting_career", 0)),
		])
	return "\n".join(lines)

func _bad_csv(rows: Array) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("seed,archetype,badness,warnings,days,work,work_only,money_blocked,friction,novelty")
	for row in rows:
		if not (row is Dictionary):
			continue
		lines.append("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
			str(row.get("seed", 0)),
			str(row.get("archetype", "")),
			str(row.get("badness_score", 0)),
			"|".join(row.get("hard_warnings", [])),
			str(row.get("campaign_days", 0)),
			str(row.get("work_actions", 0)),
			str(row.get("max_work_only_streak", 0)),
			str(row.get("money_blocked", 0)),
			str(row.get("max_goal_friction", 0)),
			str(row.get("novelty_density", 0)),
		])
	return "\n".join(lines)


func _item_csv(items: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("item_id,eligible,acquired,acquisition_rate,times_considered,times_selected,times_produced_positive_score,times_unlocked_requirement,use_per_acquisition,positive_effect_per_acquisition,unlock_per_acquisition")
	for item_id in items.keys():
		var entry: Dictionary = items[item_id]
		lines.append("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
			str(item_id),
			str(entry.get("eligible_runs", 0)),
			str(entry.get("acquired_runs", 0)),
			str(entry.get("acquisition_rate", 0)),
			str(entry.get("considered_after_purchase", 0)),
			str(entry.get("used_after_purchase", 0)),
			str(entry.get("positive_effect_count", 0)),
			str(entry.get("requirement_unlock_count", 0)),
			str(entry.get("use_per_acquisition", 0)),
			str(entry.get("positive_effect_per_acquisition", 0)),
			str(entry.get("unlock_per_acquisition", 0)),
		])
	return "\n".join(lines)

func _representative_csv(rows: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("kind,seed,archetype,days,novelty")
	for key in rows.keys():
		var row: Variant = rows[key]
		if row is Dictionary:
			lines.append("%s,%s,%s,%s,%s" % [
				str(key),
				str(row.get("seed", 0)),
				str(row.get("archetype", "")),
				str(row.get("campaign_days", 0)),
				str(row.get("novelty_density", 0)),
			])
	return "\n".join(lines)


func _bad_summary_md(result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Bad Seeds")
	for row in result.bad_seeds:
		lines.append("- seed %s warning=%s badness=%s" % [str(row.get("seed", 0)), str(row.get("primary_warning", "")), str(row.get("badness_score", 0))])
	return "\n".join(lines)


func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)


func _project_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))
