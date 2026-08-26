class_name ProgressionLabPopulationResult
extends RefCounted

var schema_version: int = 2
var simulation_version: String = ""
var config: Dictionary = {}
var n: int = 0
var base_seed_start: int = 1
var end_story_stage: int = 4
var archetype_mode: StringName = &"POPULATION"
var records: Array = []
var statistics: Dictionary = {}
var all_bad_seeds: Array = []
var top_bad_seeds: Array = []
var bad_seeds: Array = []
var bad_seed_count: int = 0
var bad_seed_percentage: float = 0.0
var representative_seeds: Dictionary = {}
var analysis_warnings: PackedStringArray = PackedStringArray()
var warning_prevalence: Array = []
var item_metrics: Dictionary = {}
var performance: Dictionary = {}
var isolation: Dictionary = {}
var replay_matched: int = 0
var replay_total: int = 0
var replay_mismatches: Array = []
var git_dirty: bool = false
var worktree_fingerprint: String = ""
var rival_cash_dependency: Dictionary = {}
var post_date_tail: Dictionary = {}
var build_timing: Dictionary = {}
var work_attribution: Dictionary = {}
var goal_friction_by_type: Dictionary = {}
var stale_planned_goals: Dictionary = {}
var career_progression: Dictionary = {}


func to_dict() -> Dictionary:
	var compact_records: Array = []
	for record in records:
		if record is ProgressionLabRunRecord:
			compact_records.append(record.summary_dict())
		elif record is Dictionary:
			compact_records.append(record)
	return {
		"schema_version": schema_version,
		"simulation_version": simulation_version,
		"config": config.duplicate(true),
		"n": n,
		"base_seed_start": base_seed_start,
		"end_story_stage": end_story_stage,
		"archetype_mode": String(archetype_mode),
		"records": compact_records,
		"statistics": statistics.duplicate(true),
		"all_bad_seeds": all_bad_seeds.duplicate(true),
		"top_bad_seeds": top_bad_seeds.duplicate(true),
		"bad_seeds": all_bad_seeds.duplicate(true),
		"bad_seed_count": bad_seed_count,
		"bad_seed_percentage": bad_seed_percentage,
		"representative_seeds": representative_seeds.duplicate(true),
		"analysis_warnings": Array(analysis_warnings),
		"warning_prevalence": warning_prevalence.duplicate(true),
		"item_metrics": item_metrics.duplicate(true),
		"performance": performance.duplicate(true),
		"isolation": isolation.duplicate(true),
		"replay_matched": replay_matched,
		"replay_total": replay_total,
		"replay_mismatches": replay_mismatches.duplicate(true),
		"git_dirty": git_dirty,
		"worktree_fingerprint": worktree_fingerprint,
		"rival_cash_dependency": rival_cash_dependency.duplicate(true),
		"post_date_tail": post_date_tail.duplicate(true),
		"build_timing": build_timing.duplicate(true),
		"work_attribution": work_attribution.duplicate(true),
		"goal_friction_by_type": goal_friction_by_type.duplicate(true),
		"stale_planned_goals": stale_planned_goals.duplicate(true),
		"career_progression": career_progression.duplicate(true),
	}
