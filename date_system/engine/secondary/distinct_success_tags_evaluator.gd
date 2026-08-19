class_name DistinctSuccessTagsEvaluator
extends SecondaryEvaluator


func condition_type() -> DateTypes.SecondaryConditionType:
	return DateTypes.SecondaryConditionType.DISTINCT_SUCCESS_TAGS


func initial_state(_rule: SecondaryRule, _rules: DateRules) -> Dictionary:
	return {
		"success_tag_ids": [],
	}


func on_episode(state: Dictionary, episode: DateEpisodeResult, rule: SecondaryRule, rules: DateRules) -> void:
	if episode == null:
		return
	if not counted_phases(rule, rules).has(int(episode.phase)):
		return
	if episode.tag_preference <= 0:
		return
	var tags: Array = state.get("success_tag_ids", [])
	var tag_key: String = String(episode.tag_id)
	if not tags.has(tag_key):
		tags.append(tag_key)
	state["success_tag_ids"] = tags


func required_count(rule: SecondaryRule) -> int:
	return int(rule.condition_parameters.get("required_count", 3))


func is_success(state: Dictionary, rule: SecondaryRule, _rules: DateRules) -> bool:
	var tags: Array = state.get("success_tag_ids", [])
	return tags.size() >= required_count(rule)


func live_text(state: Dictionary, rule: SecondaryRule, _rules: DateRules) -> String:
	var tags: Array = state.get("success_tag_ids", [])
	return "Разные успешные теги: %d/%d" % [tags.size(), required_count(rule)]
