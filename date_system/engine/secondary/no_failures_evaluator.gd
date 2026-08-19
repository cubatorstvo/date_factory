class_name NoFailuresEvaluator
extends SecondaryEvaluator


func condition_type() -> DateTypes.SecondaryConditionType:
	return DateTypes.SecondaryConditionType.NO_FAILURES


func initial_state(_rule: SecondaryRule, _rules: DateRules) -> Dictionary:
	return {
		"failure_count": 0,
	}


func on_episode(state: Dictionary, episode: DateEpisodeResult, rule: SecondaryRule, rules: DateRules) -> void:
	if episode == null:
		return
	if not counted_phases(rule, rules).has(int(episode.phase)):
		return
	if episode.tag_preference < 0:
		state["failure_count"] = int(state.get("failure_count", 0)) + 1


func is_success(state: Dictionary, _rule: SecondaryRule, _rules: DateRules) -> bool:
	return int(state.get("failure_count", 0)) == 0


func live_text(state: Dictionary, _rule: SecondaryRule, _rules: DateRules) -> String:
	return "Ошибки CORE: %d" % int(state.get("failure_count", 0))
