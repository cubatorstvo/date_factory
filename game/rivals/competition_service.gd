extends Node

signal competition_completed(competition_id: StringName, rival_id: StringName, won: bool)

const ACTION_PREFIX: String = "competition_"
const REASON_NOT_FOUND: String = "Соревнование не найдено"
const REASON_WRONG_LOCATION: String = "Соперник находится в другой локации"
const REASON_NOT_DISCOVERED: String = "Вы ещё не встретили этого соперника"
const REASON_ALREADY_DEFEATED: String = "Этот соперник уже побеждён"

var _catalog: CompetitionCatalog
var _forced_won: Variant = null
var _rng: RandomNumberGenerator


func _ready() -> void:
	_catalog = CompetitionCatalog.create_seed()


func get_catalog() -> CompetitionCatalog:
	if _catalog == null:
		_catalog = CompetitionCatalog.create_seed()
	return _catalog


func set_forced_won(won: Variant) -> void:
	_forced_won = won


func set_rng(source: RandomNumberGenerator) -> void:
	_rng = source


func can_start_competition(competition_id: StringName) -> bool:
	return get_failure_reason(competition_id).is_empty()


func get_failure_reason(competition_id: StringName) -> String:
	var definition: CompetitionDefinition = get_catalog().get_competition(competition_id)
	if definition == null:
		return REASON_NOT_FOUND
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return REASON_NOT_FOUND
	var rival: RivalDefinition = rivals.get_definition(definition.rival_id)
	if rival == null:
		return REASON_NOT_FOUND
	var world: Variant = _world_service()
	if world == null:
		return REASON_WRONG_LOCATION
	if rival.location_id != world.get_current_location_id():
		return REASON_WRONG_LOCATION
	if not bool(rivals.is_discovered(definition.rival_id)):
		return REASON_NOT_DISCOVERED
	if bool(rivals.is_defeated(definition.rival_id)):
		return REASON_ALREADY_DEFEATED
	return ""


func create_competition_action(competition_id: StringName) -> GameAction:
	var action := GameAction.new()
	action.id = StringName("%s%s" % [ACTION_PREFIX, String(competition_id)])
	action.money_cost = 0
	var definition: CompetitionDefinition = get_catalog().get_competition(competition_id)
	if definition != null:
		action.time_cost_minutes = definition.time_cost_minutes
	var requirement := CompetitionAvailableRequirement.new()
	requirement.competition_id = competition_id
	action.requirements.append(requirement)
	var effect := CompetitionEffect.new()
	effect.competition_id = competition_id
	action.effects.append(effect)
	return action


func get_competitions_for_rival(rival_id: StringName) -> Array[CompetitionDefinition]:
	var rivals: Variant = _rivals_service()
	var rival: RivalDefinition = null
	if rivals != null:
		rival = rivals.get_definition(rival_id)
	if rival == null:
		return get_catalog().get_competitions_for_rival(rival_id)
	var result: Array[CompetitionDefinition] = []
	for competition_id in rival.competition_ids:
		var competition: CompetitionDefinition = get_catalog().get_competition(competition_id)
		if competition != null and competition.rival_id == rival_id:
			result.append(competition)
	return result


func get_win_chance(competition_id: StringName) -> float:
	var definition: CompetitionDefinition = get_catalog().get_competition(competition_id)
	if definition == null:
		return 0.0
	var bonus: float = 0.0
	var characteristics: Variant = _characteristic_service()
	if characteristics != null and definition.primary_characteristic_id != &"":
		bonus = float(int(characteristics.get_value(definition.primary_characteristic_id))) * 0.1
	return clampf(definition.base_win_chance + bonus, 0.0, 1.0)


func resolve_competition(competition_id: StringName) -> CompetitionResult:
	var result := CompetitionResult.new()
	result.competition_id = competition_id
	var definition: CompetitionDefinition = get_catalog().get_competition(competition_id)
	if definition == null:
		result.result_text = "Поражение"
		return result
	result.rival_id = definition.rival_id
	result.won = _roll_win(definition)
	if result.won:
		result.result_text = "Победа"
	else:
		result.result_text = "Поражение"
	return result


func complete_competition(result: CompetitionResult) -> bool:
	if result == null:
		return false
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return false
	var rival: RivalDefinition = rivals.get_definition(result.rival_id)
	if rival == null:
		return false
	if result.won:
		rivals.defeat_rival(result.rival_id)
	competition_completed.emit(result.competition_id, result.rival_id, result.won)
	return true


func _roll_win(definition: CompetitionDefinition) -> bool:
	if _forced_won is bool:
		return bool(_forced_won)
	var chance: float = get_win_chance(definition.id)
	if _rng != null:
		return _rng.randf() < chance
	return randf() < chance


func _rivals_service() -> Variant:
	var node: Node = get_node_or_null("/root/RivalsService")
	if not is_instance_valid(node):
		push_error("RivalsService autoload missing")
		return null
	return node


func _world_service() -> Variant:
	var node: Node = get_node_or_null("/root/WorldService")
	if not is_instance_valid(node):
		push_error("WorldService autoload missing")
		return null
	return node


func _characteristic_service() -> Variant:
	var node: Node = get_node_or_null("/root/CharacteristicService")
	if not is_instance_valid(node):
		push_error("CharacteristicService autoload missing")
		return null
	return node
