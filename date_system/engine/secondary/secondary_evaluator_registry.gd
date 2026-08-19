class_name SecondaryEvaluatorRegistry
extends RefCounted

var _evaluators: Dictionary = {}


func _init() -> void:
	register_evaluator(DistinctSuccessTagsEvaluator.new())
	register_evaluator(NoFailuresEvaluator.new())


func register_evaluator(evaluator: SecondaryEvaluator) -> void:
	_evaluators[int(evaluator.condition_type())] = evaluator


func get_evaluator(condition_type: DateTypes.SecondaryConditionType) -> SecondaryEvaluator:
	var evaluator: Variant = _evaluators.get(int(condition_type), null)
	return evaluator as SecondaryEvaluator
