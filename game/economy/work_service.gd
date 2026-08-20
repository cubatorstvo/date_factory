class_name WorkService
extends RefCounted

const ID_WORK_BASIC: StringName = &"work_basic"
const TIER_1_INCOME: int = 100
const TIER_2_INCOME: int = 200
const TIER_2_MIN_STORY_STAGE: int = 3
const WORK_MINUTES: int = 60


static func get_tiers() -> Array[WorkTierDefinition]:
	var tiers: Array[WorkTierDefinition] = []
	tiers.append(_make_tier(1, TIER_1_INCOME, WORK_MINUTES))
	tiers.append(_make_tier(TIER_2_MIN_STORY_STAGE, TIER_2_INCOME, WORK_MINUTES))
	return tiers


static func get_current_hourly_pay() -> int:
	return get_current_tier().income


static func get_current_tier() -> WorkTierDefinition:
	var current_stage: int = _current_story_stage()
	var selected: WorkTierDefinition = _make_tier(1, TIER_1_INCOME, WORK_MINUTES)
	for tier in get_tiers():
		if tier != null and current_stage >= tier.min_story_stage:
			selected = tier
	return selected


static func make_work_basic() -> WorkDefinition:
	return make_current_work()


static func make_current_work() -> WorkDefinition:
	var tier: WorkTierDefinition = get_current_tier()
	var work := WorkDefinition.new()
	work.id = ID_WORK_BASIC
	work.display_name = "Работать"
	work.income = tier.income
	work.time_cost_minutes = tier.time_cost_minutes
	return work


static func create_work_action(work: WorkDefinition) -> GameAction:
	var action := GameAction.new()
	if work == null:
		return action
	action.id = work.id
	action.time_cost_minutes = work.time_cost_minutes
	action.money_cost = 0
	var availability := WorkAvailableTodayRequirement.new()
	action.requirements.append(availability)
	var effect := MoneyEffect.new()
	effect.amount = work.income
	action.effects.append(effect)
	var record := RecordWorkDayEffect.new()
	action.effects.append(record)
	return action


static func get_calendar_day_index() -> int:
	var minutes: int = 0
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var clock: Node = tree.root.get_node_or_null("TimeService")
		if is_instance_valid(clock):
			minutes = int(clock.get_game_time_minutes())
		else:
			var gs: Variant = _game_state()
			if gs != null and gs.flow != null:
				minutes = int(gs.flow.game_time_minutes)
	return int(minutes / 1440)


static func is_work_available_today() -> bool:
	var gs: Variant = _game_state()
	if gs == null or gs.player == null:
		return false
	return int(gs.player.last_work_day_index) != get_calendar_day_index()


static func _make_tier(min_story_stage: int, income: int, time_cost_minutes: int) -> WorkTierDefinition:
	var tier := WorkTierDefinition.new()
	tier.min_story_stage = min_story_stage
	tier.income = income
	tier.time_cost_minutes = time_cost_minutes
	return tier


static func _current_story_stage() -> int:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 1
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return 1
	return int(node.get_current_stage())


static func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
