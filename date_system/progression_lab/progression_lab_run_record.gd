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
var stop_reason: String = ""
var diagnostic_snapshot: Dictionary = {}
var execution_signature: String = ""
var rng_draw_counts: Dictionary = {}
var failed_candidate_sequence: PackedStringArray = PackedStringArray()
var stage_transitions: PackedStringArray = PackedStringArray()
var final_story_stage: int = 1
var final_money: int = 0


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
		"stop_reason": stop_reason,
		"diagnostic_snapshot": diagnostic_snapshot.duplicate(true),
		"execution_signature": execution_signature,
		"rng_draw_counts": rng_draw_counts.duplicate(true),
		"failed_candidate_sequence": Array(failed_candidate_sequence),
		"stage_transitions": Array(stage_transitions),
		"final_story_stage": final_story_stage,
		"final_money": final_money,
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
		"stop_reason": stop_reason,
		"diagnostic_snapshot": diagnostic_snapshot.duplicate(true),
		"execution_signature": execution_signature,
		"rng_draw_counts": rng_draw_counts.duplicate(true),
		"final_story_stage": final_story_stage,
		"final_money": final_money,
	}


func canonical_execution_payload() -> Dictionary:
	return {
		"base_seed": base_seed,
		"archetype": String(archetype),
		"profile": profile.duplicate(true),
		"interests": interests.duplicate(true),
		"stage_plans": stage_plans.duplicate(true),
		"action_sequence": Array(action_sequence),
		"failed_candidate_sequence": Array(failed_candidate_sequence),
		"date_summaries": date_summaries.duplicate(true),
		"stage_transitions": Array(stage_transitions),
		"final_story_stage": final_story_stage,
		"final_money": final_money,
		"campaign_metrics": campaign_metrics.duplicate(true),
		"stage_metrics": stage_metrics.duplicate(true),
		"stop_reason": stop_reason,
		"hard_warnings": Array(hard_warnings),
		"rng_draw_counts": rng_draw_counts.duplicate(true),
	}


func compute_execution_signature() -> String:
	execution_signature = ProgressionRng.sha256_hex(JSON.stringify(_canonicalize(canonical_execution_payload())))
	return execution_signature


func _canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var source: Dictionary = value
		var keys: Array = source.keys()
		keys.sort()
		var ordered: Dictionary = {}
		for key in keys:
			ordered[str(key)] = _canonicalize(source[key])
		return ordered
	if value is Array:
		var items: Array = []
		for item in value:
			items.append(_canonicalize(item))
		return items
	return value

static func first_difference(expected: ProgressionLabRunRecord, actual: ProgressionLabRunRecord) -> Dictionary:
	var diff: Dictionary = {
		"seed": actual.base_seed if actual != null else (expected.base_seed if expected != null else 0),
		"expected_signature": expected.execution_signature if expected != null else "",
		"actual_signature": actual.execution_signature if actual != null else "",
		"first_differing_action_index": -1,
		"summary_action": "",
		"replay_action": "",
		"summary_stop_reason": expected.stop_reason if expected != null else "",
		"replay_stop_reason": actual.stop_reason if actual != null else "",
		"summary_campaign_days": int(expected.campaign_metrics.get("calendar_days", 0)) if expected != null else 0,
		"replay_campaign_days": int(actual.campaign_metrics.get("calendar_days", 0)) if actual != null else 0,
		"summary_total_actions": int(expected.campaign_metrics.get("total_actions", 0)) if expected != null else 0,
		"replay_total_actions": int(actual.campaign_metrics.get("total_actions", 0)) if actual != null else 0,
		"summary_dates": int(expected.campaign_metrics.get("dates", 0)) if expected != null else 0,
		"replay_dates": int(actual.campaign_metrics.get("dates", 0)) if actual != null else 0,
		"summary_work_actions": int(expected.campaign_metrics.get("work_actions", 0)) if expected != null else 0,
		"replay_work_actions": int(actual.campaign_metrics.get("work_actions", 0)) if actual != null else 0,
		"field": "",
	}
	if expected == null or actual == null:
		diff["field"] = "null_record"
		return diff
	var expected_actions: PackedStringArray = expected.action_sequence
	var actual_actions: PackedStringArray = actual.action_sequence
	var limit: int = maxi(expected_actions.size(), actual_actions.size())
	for i in range(limit):
		var left: String = expected_actions[i] if i < expected_actions.size() else ""
		var right: String = actual_actions[i] if i < actual_actions.size() else ""
		if left != right:
			diff["first_differing_action_index"] = i
			diff["summary_action"] = left
			diff["replay_action"] = right
			diff["field"] = "action_sequence"
			return diff
	if "|".join(expected.failed_candidate_sequence) != "|".join(actual.failed_candidate_sequence):
		diff["field"] = "failed_candidate_sequence"
		return diff
	if JSON.stringify(expected.date_summaries) != JSON.stringify(actual.date_summaries):
		diff["field"] = "date_summaries"
		return diff
	if JSON.stringify(expected.campaign_metrics) != JSON.stringify(actual.campaign_metrics):
		diff["field"] = "campaign_metrics"
		return diff
	if JSON.stringify(expected.stage_metrics) != JSON.stringify(actual.stage_metrics):
		diff["field"] = "stage_metrics"
		return diff
	if ",".join(expected.hard_warnings) != ",".join(actual.hard_warnings):
		diff["field"] = "hard_warnings"
		return diff
	if JSON.stringify(expected.rng_draw_counts) != JSON.stringify(actual.rng_draw_counts):
		diff["field"] = "rng_draw_counts"
		return diff
	diff["field"] = "other"
	return diff