class_name WorkService
extends RefCounted

const ID_WORK_BASIC: StringName = &"work_basic"
const ID_CAREER_ADVANCEMENT: StringName = &"career_advancement"
const MAX_CAREER_RANK: int = 3
const BASE_SHIFT_INCOME: int = 100
const TIER_1_INCOME: int = BASE_SHIFT_INCOME
const TIER_2_INCOME: int = 200
const WORK_MINUTES: int = 60


static func get_tiers() -> Array[WorkTierDefinition]:
	var tiers: Array[WorkTierDefinition] = []
	for rank in range(MAX_CAREER_RANK + 1):
		tiers.append(_make_tier(1, _shift_income_for_rank(rank), WORK_MINUTES))
	return tiers


static func get_career_rank(game_state: Variant = null) -> int:
	var player: PlayerState = _player(game_state)
	if player == null:
		return 0
	return clampi(player.career_rank, 0, MAX_CAREER_RANK)


static func get_current_shift_income(game_state: Variant = null) -> int:
	return _shift_income_for_rank(get_career_rank(game_state))


static func get_current_hourly_pay(game_state: Variant = null) -> int:
	return get_current_shift_income(game_state)


static func get_current_tier(game_state: Variant = null) -> WorkTierDefinition:
	return _make_tier(1, get_current_shift_income(game_state), WORK_MINUTES)


static func has_career_connections(game_state: Variant = null) -> bool:
	var gs: Variant = _resolve_game_state(game_state)
	if gs == null:
		return false
	var player: PlayerState = gs.player as PlayerState
	if player != null and player.career_connections_unlocked:
		return true
	if gs.progression != null and gs.progression.has_method("has_filler_reward"):
		if bool(gs.progression.has_filler_reward(FillerRewardCatalog.ID_CAREER_CONNECTIONS)):
			return true
		return bool(gs.progression.has_filler_reward(FillerRewardCatalog.ID_CAREER_PROGRESSION_UNLOCK))
	return false

static func next_rank_requires_connections(game_state: Variant = null) -> bool:
	var rank: int = get_career_rank(game_state)
	return rank >= 1 and rank < MAX_CAREER_RANK

static func get_next_career_rank(game_state: Variant = null) -> int:
	var rank: int = get_career_rank(game_state)
	if rank >= MAX_CAREER_RANK:
		return -1
	return rank + 1


static func get_next_career_income(game_state: Variant = null) -> int:
	var next_rank: int = get_next_career_rank(game_state)
	if next_rank < 0:
		return 0
	return _shift_income_for_rank(next_rank)


static func get_next_career_capital_requirement(game_state: Variant = null) -> int:
	return _capital_requirement_for_next_rank(get_career_rank(game_state))


static func can_advance_career(game_state: Variant = null) -> bool:
	var rank: int = get_career_rank(game_state)
	if rank < 0 or rank >= MAX_CAREER_RANK:
		return false
	var player: PlayerState = _player(game_state)
	if player == null:
		return false
	if player.capital < get_next_career_capital_requirement(game_state):
		return false
	if next_rank_requires_connections(game_state) and not has_career_connections(game_state):
		return false
	if not is_work_available_today():
		return false
	return true

static func advance_career(game_state: Variant = null) -> bool:
	if not can_advance_career(game_state):
		return false
	return _apply_career_rank_increment(game_state)


static func _apply_career_rank_increment(game_state: Variant = null) -> bool:
	var player: PlayerState = _player(game_state)
	if player == null:
		return false
	if player.career_rank >= MAX_CAREER_RANK:
		return false
	player.career_rank = clampi(player.career_rank + 1, 0, MAX_CAREER_RANK)
	return true


static func create_career_advancement_action() -> GameAction:
	var action := GameAction.new()
	action.id = ID_CAREER_ADVANCEMENT
	action.time_cost_minutes = WORK_MINUTES
	action.money_cost = 0
	var availability := WorkAvailableTodayRequirement.new()
	action.requirements.append(availability)
	if next_rank_requires_connections():
		var unlocked_script := load("res://game/actions/career_connections_unlocked_requirement.gd") as GDScript
		var unlocked: ActionRequirement = unlocked_script.new() as ActionRequirement
		action.requirements.append(unlocked)
	var rank_script := load("res://game/actions/career_rank_below_max_requirement.gd") as GDScript
	var rank_req: ActionRequirement = rank_script.new() as ActionRequirement
	action.requirements.append(rank_req)
	var capital_script := load("res://game/actions/career_capital_requirement.gd") as GDScript
	var capital_req: ActionRequirement = capital_script.new() as ActionRequirement
	action.requirements.append(capital_req)
	var record := RecordWorkDayEffect.new()
	action.effects.append(record)
	var promote_script := load("res://game/actions/increment_career_rank_effect.gd") as GDScript
	var promote: ActionEffect = promote_script.new() as ActionEffect
	action.effects.append(promote)
	return action

static func make_work_basic() -> WorkDefinition:
	return make_current_work()


static func make_current_work(game_state: Variant = null) -> WorkDefinition:
	var work := WorkDefinition.new()
	work.id = ID_WORK_BASIC
	work.display_name = "Работать"
	work.income = get_current_shift_income(game_state)
	work.time_cost_minutes = WORK_MINUTES
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
	var clock: Variant = _time_service_node()
	if clock != null and clock.has_method("get_calendar_day_index"):
		return int(clock.get_calendar_day_index())
	var gs: Variant = _game_state()
	if gs != null and gs.flow != null:
		return int(int(gs.flow.game_time_minutes) / 1440)
	return 0


static func _time_service_node() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeService")


static func is_work_available_today() -> bool:
	var daily: Variant = _daily_activity()
	if daily == null:
		return false
	return int(daily.usage_today(daily.KEY_WORK)) == 0


static func has_olya_overtime() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return bool(girls.has_filler_reward(FillerRewardCatalog.ID_OLYA_OVERTIME))


static func get_overtime_pay(game_state: Variant = null) -> int:
	return int(get_current_shift_income(game_state) * FillerRewardCatalog.OLYA_OVERTIME_PAY_PERCENT / 100)


static func is_overtime_available_today() -> bool:
	if not has_olya_overtime():
		return false
	var daily: Variant = _daily_activity()
	if daily == null:
		return false
	return int(daily.usage_today(daily.KEY_WORK)) == 1 and int(daily.work_daily_limit()) >= 2


static func make_overtime_work(game_state: Variant = null) -> WorkDefinition:
	var work := WorkDefinition.new()
	work.id = &"work_overtime"
	work.display_name = "Выйти на подработку"
	work.income = get_overtime_pay(game_state)
	work.time_cost_minutes = WORK_MINUTES
	return work


static func create_overtime_action() -> GameAction:
	var work: WorkDefinition = make_overtime_work()
	var action := GameAction.new()
	action.id = work.id
	action.time_cost_minutes = work.time_cost_minutes
	action.money_cost = 0
	var availability := WorkOvertimeAvailableRequirement.new()
	action.requirements.append(availability)
	var effect := MoneyEffect.new()
	effect.amount = work.income
	action.effects.append(effect)
	var record := RecordOvertimeDayEffect.new()
	action.effects.append(record)
	return action


static func create_work_with_overtime_action() -> GameAction:
	var regular: WorkDefinition = make_current_work()
	var overtime_pay: int = get_overtime_pay()
	var action := GameAction.new()
	action.id = &"work_basic_with_overtime"
	action.time_cost_minutes = regular.time_cost_minutes + WORK_MINUTES
	action.money_cost = 0
	var availability := WorkAvailableTodayRequirement.new()
	action.requirements.append(availability)
	var reward_req := FillerRewardUnlockedRequirement.new()
	reward_req.reward_id = FillerRewardCatalog.ID_OLYA_OVERTIME
	action.requirements.append(reward_req)
	var effect := MoneyEffect.new()
	effect.amount = regular.income + overtime_pay
	action.effects.append(effect)
	var record := RecordWorkDayEffect.new()
	action.effects.append(record)
	var overtime_record := RecordOvertimeDayEffect.new()
	action.effects.append(overtime_record)
	return action


static func _shift_income_for_rank(rank: int) -> int:
	var clamped: int = clampi(rank, 0, MAX_CAREER_RANK)
	return BASE_SHIFT_INCOME * (1 << clamped)


static func _capital_requirement_for_next_rank(current_rank: int) -> int:
	match clampi(current_rank, 0, MAX_CAREER_RANK):
		0:
			return 1
		1:
			return 3
		2:
			return 5
		_:
			return 0


static func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node


static func _make_tier(min_story_stage: int, income: int, time_cost_minutes: int) -> WorkTierDefinition:
	var tier := WorkTierDefinition.new()
	tier.min_story_stage = min_story_stage
	tier.income = income
	tier.time_cost_minutes = time_cost_minutes
	return tier


static func _resolve_game_state(game_state: Variant = null) -> Variant:
	if game_state != null:
		return game_state
	return _game_state()


static func _player(game_state: Variant = null) -> PlayerState:
	var gs: Variant = _resolve_game_state(game_state)
	if gs == null:
		return null
	return gs.player as PlayerState


static func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node


static func _daily_activity() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DailyActivityService")
