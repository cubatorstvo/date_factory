class_name SecondaryEvaluator
extends RefCounted

func condition_type() -> DateTypes.SecondaryConditionType:
	return DateTypes.SecondaryConditionType.DISTINCT_SUCCESS_TAGS


func initial_state(_rule: SecondaryRule, _rules: DateRules) -> Dictionary:
	return {}


func on_episode(_state: Dictionary, _episode: DateEpisodeResult, _rule: SecondaryRule, _rules: DateRules) -> void:
	pass


func is_success(_state: Dictionary, _rule: SecondaryRule, _rules: DateRules) -> bool:
	return false


func live_text(_state: Dictionary, _rule: SecondaryRule, _rules: DateRules) -> String:
	return ""


func counted_phases(rule: SecondaryRule, rules: DateRules) -> Array[int]:
	var raw: Variant = rule.condition_parameters.get("counted_phases", rules.secondary_counted_phases)
	var phases: Array[int] = []
	if raw is Array:
		for item in raw:
			phases.append(int(item))
	return phases
