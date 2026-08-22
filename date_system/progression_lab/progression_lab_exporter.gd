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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/bad_seed_logs" % folder))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/representative_seed_logs" % folder))
	for row in result.bad_seeds:
		var seed: int = int(row.get("seed", 0))
		var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
		if record != null:
			_write_seed_pair("%s/bad_seed_logs" % folder, record, result)
	for key in result.representative_seeds.keys():
		var row: Variant = result.representative_seeds[key]
		if row is Dictionary:
			var seed: int = int(row.get("seed", 0))
			var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
			if record != null:
				_write_seed_pair("%s/representative_seed_logs" % folder, record, result)
	return ProjectSettings.globalize_path(folder)


func export_bad_seeds_only(result: ProgressionLabPopulationResult, directory: String = "", detailed_records: Dictionary = {}) -> String:
	var folder: String = _prepare_folder(result, directory, "bad")
	_write_text("%s/config.json" % folder, JSON.stringify(_config_payload(result), "\t"))
	_write_text("%s/bad_seeds.csv" % folder, _bad_csv(result.bad_seeds))
	_write_text("%s/bad_seeds_summary.md" % folder, _bad_summary_md(result))
	var jsonl: PackedStringArray = PackedStringArray()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/logs" % folder))
	for row in result.bad_seeds:
		jsonl.append(JSON.stringify(row))
		var seed: int = int(row.get("seed", 0))
		var record: ProgressionLabRunRecord = detailed_records.get(seed, null)
		if record != null:
			_write_seed_pair("%s/logs" % folder, record, result)
	_write_text("%s/bad_seeds.jsonl" % folder, "\n".join(jsonl))
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
	for key in ["calendar_days", "work_actions", "dates", "economy_support_share", "dead_progress_days", "max_goal_friction_ratio", "novelty_density"]:
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
	lines.append("## Bad seeds: %d / %d (%.1f%%)" % [result.bad_seeds.size(), maxi(result.n, 1), 100.0 * float(result.bad_seeds.size()) / float(maxi(result.n, 1))])
	lines.append("")
	lines.append("## Warnings")
	for warning in result.analysis_warnings:
		lines.append("- %s" % warning)
	lines.append("")
	lines.append("## Top bad seeds")
	for row in result.bad_seeds:
		lines.append("- seed %s [%s] badness=%s warning=%s days=%s" % [
			str(row.get("seed", 0)),
			str(row.get("archetype", "")),
			str(row.get("badness_score", 0)),
			str(row.get("primary_warning", "")),
			str(row.get("campaign_days", 0)),
		])
	lines.append("")
	lines.append("## Representative seeds")
	lines.append(JSON.stringify(result.representative_seeds, "\t"))
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
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"project_version": _project_version(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"n": result.n,
		"config": result.config,
		"statistics": result.statistics,
		"bad_seeds": result.bad_seeds,
		"analysis_warnings": Array(result.analysis_warnings),
		"representative_seeds": result.representative_seeds,
		"item_metrics": result.item_metrics,
		"performance": result.performance,
	}


func specific_seed_markdown(record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Specific Seed %d" % record.base_seed)
	lines.append("")
	lines.append("## Summary")
	lines.append("Archetype: %s" % String(record.archetype))
	lines.append("Badness: %d" % record.badness_score)
	lines.append("Warnings: %s" % ", ".join(record.hard_warnings))
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
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"project_version": _project_version(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"seed": record.base_seed,
		"config": result.config if result != null else {},
		"profile": record.profile,
		"stage_plans": record.stage_plans,
		"metrics": record.campaign_metrics,
		"stage_metrics": record.stage_metrics,
		"warnings": Array(record.hard_warnings),
		"timeline_markdown": record.timeline_markdown,
		"daily_log": record.daily_log,
		"date_summaries": record.date_summaries,
		"item_utility": record.item_utility,
	}


func _write_seed_pair(folder: String, record: ProgressionLabRunRecord, result: ProgressionLabPopulationResult) -> void:
	_write_text("%s/%d.md" % [folder, record.base_seed], specific_seed_markdown(record, result))
	_write_text("%s/%d.json" % [folder, record.base_seed], JSON.stringify(specific_seed_json(record, result), "\t"))


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
	lines.append("seed,archetype,days,work,dates,economy,dead,friction,novelty,badness,warnings")
	for record in result.records:
		if not (record is ProgressionLabRunRecord):
			continue
		var metrics: Dictionary = record.campaign_metrics
		lines.append("%d,%s,%s,%s,%s,%s,%s,%s,%s,%d,%s" % [
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
	lines.append("item_id,eligible,acquired,acquisition_rate,use_per_acquisition,positive_per_acquisition,unlock_per_acquisition")
	for item_id in items.keys():
		var entry: Dictionary = items[item_id]
		lines.append("%s,%s,%s,%s,%s,%s,%s" % [
			str(item_id),
			str(entry.get("eligible_runs", 0)),
			str(entry.get("acquired_runs", 0)),
			str(entry.get("acquisition_rate", 0)),
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
