class_name GameActionCatalog
extends Resource

const ID_TEST_WAIT: StringName = &"test_wait"
const ID_TEST_EARN_MONEY: StringName = &"test_earn_money"
const ID_TEST_SPEND_MONEY: StringName = &"test_spend_money"
const ID_TEST_REQUIRE_MONEY: StringName = &"test_require_money"

@export var actions: Array[GameAction] = []


func find(id: StringName) -> GameAction:
	for action in actions:
		if action != null and action.id == id:
			return action
	return null


static func create_test_catalog() -> GameActionCatalog:
	var catalog := GameActionCatalog.new()
	catalog.actions.append(make_test_wait())
	catalog.actions.append(make_test_earn_money())
	catalog.actions.append(make_test_spend_money())
	catalog.actions.append(make_test_require_money())
	return catalog


static func make_test_wait() -> GameAction:
	var action := GameAction.new()
	action.id = ID_TEST_WAIT
	action.time_cost_minutes = 120
	return action


static func make_test_earn_money() -> GameAction:
	var action := GameAction.new()
	action.id = ID_TEST_EARN_MONEY
	action.time_cost_minutes = 60
	var effect := MoneyEffect.new()
	effect.amount = 100
	action.effects.append(effect)
	return action


static func make_test_spend_money() -> GameAction:
	var action := GameAction.new()
	action.id = ID_TEST_SPEND_MONEY
	action.time_cost_minutes = 30
	action.money_cost = 50
	return action


static func make_test_require_money() -> GameAction:
	var action := GameAction.new()
	action.id = ID_TEST_REQUIRE_MONEY
	action.time_cost_minutes = 10
	var requirement := MoneyRequirement.new()
	requirement.required_money = 100
	action.requirements.append(requirement)
	return action
