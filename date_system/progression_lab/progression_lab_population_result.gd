class_name ProgressionLabPopulationResult
extends RefCounted

var schema_version: int = 1
var simulation_version: String = ""
var config: Dictionary = {}
var n: int = 0
var base_seed_start: int = 1
var end_story_stage: int = 4
var archetype_mode: StringName = &"POPULATION"
var records: Array = []
var statistics: Dictionary = {}
var bad_seeds: Array = []
var representative_seeds: Dictionary = {}
var analysis_warnings: PackedStringArray = PackedStringArray()
var item_metrics: Dictionary = {}
var performance: Dictionary = {}
var isolation: Dictionary = {}


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
		"bad_seeds": bad_seeds.duplicate(true),
		"representative_seeds": representative_seeds.duplicate(true),
		"analysis_warnings": Array(analysis_warnings),
		"item_metrics": item_metrics.duplicate(true),
		"performance": performance.duplicate(true),
		"isolation": isolation.duplicate(true),
	}
