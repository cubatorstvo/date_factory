class_name ProgressionLabRunRecord
extends RefCounted

var base_seed: int = 0
var archetype: StringName = &""
var profile: Dictionary = {}
var interests: Dictionary = {}
var stage_plans: Array = []
var campaign_metrics: Dictionary = {}
var stage_metrics: Dictionary = {}
var hard_warnings: PackedStringArray = PackedStringArray()
var badness_score: int = 0
var timeline_markdown: String = ""
var action_sequence: PackedStringArray = PackedStringArray()
var daily_log: Array = []
var date_summaries: Array = []
var item_utility: Dictionary = {}
var aborted: bool = false
var end_story_stage: int = 4


func to_dict() -> Dictionary:
	return {
		"base_seed": base_seed,
		"archetype": String(archetype),
		"profile": profile.duplicate(true),
		"interests": interests.duplicate(true),
		"stage_plans": stage_plans.duplicate(true),
		"campaign_metrics": campaign_metrics.duplicate(true),
		"stage_metrics": stage_metrics.duplicate(true),
		"hard_warnings": Array(hard_warnings),
		"badness_score": badness_score,
		"timeline_markdown": timeline_markdown,
		"action_sequence": Array(action_sequence),
		"daily_log": daily_log.duplicate(true),
		"date_summaries": date_summaries.duplicate(true),
		"item_utility": item_utility.duplicate(true),
		"aborted": aborted,
		"end_story_stage": end_story_stage,
	}


func summary_dict() -> Dictionary:
	return {
		"base_seed": base_seed,
		"archetype": String(archetype),
		"profile": profile.duplicate(true),
		"stage_plans": stage_plans.duplicate(true),
		"campaign_metrics": campaign_metrics.duplicate(true),
		"stage_metrics": stage_metrics.duplicate(true),
		"hard_warnings": Array(hard_warnings),
		"badness_score": badness_score,
		"aborted": aborted,
		"end_story_stage": end_story_stage,
	}
