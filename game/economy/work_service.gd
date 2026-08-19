class_name WorkService
extends RefCounted

const ID_WORK_BASIC: StringName = &"work_basic"


static func make_work_basic() -> WorkDefinition:
	var work := WorkDefinition.new()
	work.id = ID_WORK_BASIC
	work.display_name = "Работать"
	work.income = 100
	work.time_cost_minutes = 60
	return work


static func create_work_action(work: WorkDefinition) -> GameAction:
	var action := GameAction.new()
	if work == null:
		return action
	action.id = work.id
	action.time_cost_minutes = work.time_cost_minutes
	action.money_cost = 0
	var effect := MoneyEffect.new()
	effect.amount = work.income
	action.effects.append(effect)
	return action
