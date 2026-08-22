extends Node

const _DailyActivityAvailableRequirement := preload("res://game/actions/daily_activity_available_requirement.gd")
const _RecordDailyActivityEffect := preload("res://game/actions/record_daily_activity_effect.gd")

signal characteristic_changed(
	characteristic_id: StringName,
	previous_value: int,
	current_value: int,
	delta: int
)

var _catalog: CharacteristicCatalog


func _ready() -> void:
	_catalog = CharacteristicCatalog.create_seed()


func get_catalog() -> CharacteristicCatalog:
	if _catalog == null:
		_catalog = CharacteristicCatalog.create_seed()
	return _catalog


func get_max_level(characteristic_id: StringName = &"") -> int:
	return get_catalog().get_max_level(characteristic_id)


func get_cost_per_level(characteristic_id: StringName = &"") -> int:
	return get_catalog().get_cost_per_level(characteristic_id)


func can_upgrade(characteristic_id: StringName) -> bool:
	if not CharacteristicIds.is_known(characteristic_id):
		return false
	return get_value(characteristic_id) < get_max_level(characteristic_id)


func is_upgrade_visible(upgrade: CharacteristicUpgradeDefinition) -> bool:
	if upgrade == null:
		return false
	if upgrade.required_filler_reward_id == &"":
		return true
	var girls: Variant = get_node_or_null("/root/GirlsService")
	if girls == null:
		return false
	return bool(girls.has_filler_reward(upgrade.required_filler_reward_id))


func can_buy_upgrade(upgrade_id: StringName) -> bool:
	var upgrade: CharacteristicUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if upgrade == null or not is_upgrade_visible(upgrade):
		return false
	return can_upgrade(upgrade.characteristic_id)


func get_value(characteristic_id: StringName) -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	match characteristic_id:
		CharacteristicIds.MUSCLE:
			return player.muscle
		CharacteristicIds.APPEARANCE:
			return player.appearance
		CharacteristicIds.CAPITAL:
			return player.capital
		CharacteristicIds.AURA:
			return player.aura
		_:
			return 0


func get_outfit_bonus(characteristic_id: StringName, outfit: Outfit = null) -> int:
	var resolved: Outfit = outfit
	if resolved == null:
		var equipment: Variant = get_node_or_null("/root/EquipmentService")
		if equipment != null:
			resolved = equipment.get_current_outfit()
	if resolved == null:
		return 0
	return resolved.bonus_for(characteristic_id)


func get_effective_value(characteristic_id: StringName, outfit: Outfit = null) -> int:
	return DateTypes.effective_stat(get_value(characteristic_id), outfit if outfit != null else _current_outfit(), characteristic_id)


func _current_outfit() -> Outfit:
	var equipment: Variant = get_node_or_null("/root/EquipmentService")
	if equipment == null:
		return null
	return equipment.get_current_outfit()


func add_value(characteristic_id: StringName, amount: int) -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	if not CharacteristicIds.is_known(characteristic_id):
		return 0
	var previous_value: int = get_value(characteristic_id)
	var current_value: int = clampi(previous_value + amount, 0, get_max_level(characteristic_id))
	match characteristic_id:
		CharacteristicIds.MUSCLE:
			player.muscle = current_value
		CharacteristicIds.APPEARANCE:
			player.appearance = current_value
		CharacteristicIds.CAPITAL:
			player.capital = current_value
		CharacteristicIds.AURA:
			player.aura = current_value
	var delta: int = current_value - previous_value
	characteristic_changed.emit(characteristic_id, previous_value, current_value, delta)
	return current_value


func create_upgrade_action(upgrade_id: StringName) -> GameAction:
	var action := GameAction.new()
	var upgrade: CharacteristicUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if upgrade == null:
		return action
	action.id = upgrade.id
	action.money_cost = upgrade.price
	action.time_cost_minutes = upgrade.time_cost_minutes
	var below_max := CharacteristicBelowMaxRequirement.new()
	below_max.characteristic_id = upgrade.characteristic_id
	action.requirements.append(below_max)
	var daily = _DailyActivityAvailableRequirement.new()
	daily.activity_key = "characteristic_training"
	daily.daily_limit = 1
	daily.failure_reason = "Сегодня уже тренировались. Следующая тренировка: завтра."
	action.requirements.append(daily)
	if upgrade.required_filler_reward_id != &"":
		var reward_req := FillerRewardUnlockedRequirement.new()
		reward_req.reward_id = upgrade.required_filler_reward_id
		action.requirements.append(reward_req)
	var effect := CharacteristicEffect.new()
	effect.characteristic_id = upgrade.characteristic_id
	effect.amount = upgrade.amount
	action.effects.append(effect)
	var record = _RecordDailyActivityEffect.new()
	record.activity_key = "characteristic_training"
	record.amount = 1
	action.effects.append(record)
	return action


func _player() -> PlayerState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.player as PlayerState


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node
