extends Node

signal date_started(girl_id: StringName)
signal date_completed(girl_id: StringName, relationship_delta: int, current_relationship: int)

const START_ACTION_PREFIX: String = "start_date_"
const DATE_COOLDOWN_DAYS: int = 3
const DATE_DURATION_MINUTES: int = 120
const DEFAULT_OUTFIT_ID: StringName = OutfitCatalog.START_OUTFIT_ID
const REASON_NOT_DISCOVERED: String = "Вы ещё не знакомы"
const REASON_NO_CONTACT: String = "У вас нет контакта этой девушки"
const REASON_COOLDOWN: String = "До следующего свидания нужно подождать"
const REASON_COMPLETED: String = "Отношения с этой девушкой уже достигли максимума"
const REASON_ACTIVE: String = "Свидание уже идёт"

var _catalog_service: DateCatalogService
var _engine: DateEngine


func _ready() -> void:
	get_catalog_service()


func get_catalog_service() -> DateCatalogService:
	if _catalog_service == null:
		_catalog_service = DateCatalogService.new()
		_catalog_service.load_catalog()
		if _catalog_service.catalog == null:
			_catalog_service.catalog = SeedContentFactory.new().build_catalog()
	return _catalog_service


func get_date_engine() -> DateEngine:
	return _engine


func can_start_date(girl_id: StringName) -> bool:
	return get_start_date_failure_reason(girl_id).is_empty()


func get_start_date_failure_reason(girl_id: StringName) -> String:
	var girls: Variant = _girls_service()
	if girls == null or girls.get_definition(girl_id) == null:
		return REASON_NOT_DISCOVERED
	if not bool(girls.is_discovered(girl_id)):
		return REASON_NOT_DISCOVERED
	if not bool(girls.has_contact(girl_id)):
		return REASON_NO_CONTACT
	if not bool(girls.is_date_cooldown_finished(girl_id)):
		return REASON_COOLDOWN
	if bool(girls.is_relationship_completed(girl_id)):
		return REASON_COMPLETED
	if has_active_date():
		return REASON_ACTIVE
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if definition != null:
		for requirement in definition.date_requirements:
			if requirement == null:
				continue
			if not requirement.is_met(girl_id):
				return "%s: %s" % [requirement.get_description(girl_id), requirement.get_progress_text(girl_id)]
	return ""


func get_date_requirements_status(girl_id: StringName) -> Array[RequirementStatus]:
	var girls: Variant = _girls_service()
	if girls == null:
		var empty: Array[RequirementStatus] = []
		return empty
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if definition == null:
		var empty_status: Array[RequirementStatus] = []
		return empty_status
	return girls.build_requirement_status_list(girl_id, definition.date_requirements)


func get_available_date_locations(girl_id: StringName) -> Array:
	var result: Array[DateLocation] = []
	var catalog: DateContentCatalog = _catalog()
	if catalog == null:
		return result
	if catalog.find_girl(girl_id) == null:
		return result
	for location in catalog.locations:
		if location != null and location.enabled:
			result.append(location)
	return result


func is_date_location_available(girl_id: StringName, date_location_id: StringName) -> bool:
	if date_location_id == &"":
		return false
	for location in get_available_date_locations(girl_id):
		var date_location: DateLocation = location as DateLocation
		if date_location != null and date_location.id == date_location_id:
			return true
	return false


func is_preferred_date_location(girl_id: StringName, date_location_id: StringName) -> bool:
	var catalog: DateContentCatalog = _catalog()
	if catalog == null:
		return false
	var girl: GirlProfile = catalog.find_girl(girl_id)
	var location: DateLocation = catalog.find_location(date_location_id)
	if girl == null or location == null:
		return false
	if location.preference_mode != DateTypes.LocationPreferenceMode.THEMATIC:
		return false
	return girl.favorite_location_format_ids.has(location.location_format_id)


func is_date_location_preference_known(girl_id: StringName, date_location_id: StringName) -> bool:
	return is_preferred_date_location(girl_id, date_location_id)


func is_preferred_outfit(girl_id: StringName, outfit_id: StringName) -> bool:
	var catalog: DateContentCatalog = _catalog()
	if catalog == null:
		return false
	var girl: GirlProfile = catalog.find_girl(girl_id)
	var outfit: Outfit = catalog.find_outfit(outfit_id)
	if girl == null or outfit == null:
		return false
	return girl.favorite_outfit_ids.has(outfit_id)


func is_outfit_preference_known(girl_id: StringName, outfit_id: StringName) -> bool:
	return is_preferred_outfit(girl_id, outfit_id)


func create_start_date_action(
	girl_id: StringName,
	date_location_id: StringName,
	outfit_id: StringName = &""
) -> GameAction:
	var resolved_outfit_id: StringName = _resolve_outfit_id(outfit_id)
	var action := GameAction.new()
	action.id = StringName("%s%s" % [START_ACTION_PREFIX, String(girl_id)])
	action.time_cost_minutes = 0
	action.money_cost = 0
	var availability := DateAvailableRequirement.new()
	availability.girl_id = girl_id
	action.requirements.append(availability)
	var location_requirement := DateLocationAvailableRequirement.new()
	location_requirement.girl_id = girl_id
	location_requirement.date_location_id = date_location_id
	action.requirements.append(location_requirement)
	var outfit_requirement := OutfitOwnedRequirement.new()
	outfit_requirement.outfit_id = resolved_outfit_id
	action.requirements.append(outfit_requirement)
	var effect := StartDateEffect.new()
	effect.girl_id = girl_id
	effect.date_location_id = date_location_id
	effect.outfit_id = resolved_outfit_id
	action.effects.append(effect)
	return action


func start_date(
	girl_id: StringName,
	date_location_id: StringName,
	outfit_id: StringName = &""
) -> bool:
	var resolved_outfit_id: StringName = _resolve_outfit_id(outfit_id)
	if not can_start_date(girl_id):
		return false
	if not is_date_location_available(girl_id, date_location_id):
		return false
	var equipment: Variant = _equipment_service()
	if equipment == null or not bool(equipment.owns_outfit(resolved_outfit_id)):
		return false
	var dating: DatingState = _dating()
	var clock: Variant = _time_service()
	if dating == null or clock == null:
		return false
	if not _create_engine(girl_id, date_location_id, resolved_outfit_id):
		return false
	dating.active_date = {
		"girl_id": girl_id,
		"location_id": date_location_id,
		"outfit_id": resolved_outfit_id,
		"started_at_game_time": int(clock.get_game_time_minutes()),
	}
	date_started.emit(girl_id)
	return true


func complete_date(result: DateResult) -> bool:
	if result == null:
		return false
	if not has_active_date():
		return false
	if result.girl_id != get_active_girl_id():
		return false
	var girls: Variant = _girls_service()
	var clock: Variant = _time_service()
	var dating: DatingState = _dating()
	if girls == null or clock == null or dating == null:
		return false
	var girl_id: StringName = result.girl_id
	var session_progress: GirlProgress = null
	if _engine != null:
		session_progress = _engine.girl_progress()
	var current_relationship: int = int(girls.change_relationship(girl_id, result.relationship_delta))
	if session_progress != null:
		girls.apply_date_knowledge(girl_id, session_progress)
	clock.advance_time(result.duration_minutes)
	girls.set_date_cooldown(girl_id, int(clock.days_to_minutes(DATE_COOLDOWN_DAYS)))
	dating.active_date = {}
	_engine = null
	date_completed.emit(girl_id, result.relationship_delta, current_relationship)
	return true


func has_active_date() -> bool:
	var dating: DatingState = _dating()
	if dating == null:
		return false
	return not String(dating.active_date.get("girl_id", "")).is_empty()


func get_active_girl_id() -> StringName:
	var dating: DatingState = _dating()
	if dating == null:
		return &""
	return StringName(str(dating.active_date.get("girl_id", "")))


func get_active_location_id() -> StringName:
	var dating: DatingState = _dating()
	if dating == null:
		return &""
	return StringName(str(dating.active_date.get("location_id", "")))


func get_active_outfit_id() -> StringName:
	var dating: DatingState = _dating()
	if dating == null:
		return &""
	var outfit_text: String = str(dating.active_date.get("outfit_id", ""))
	if outfit_text.is_empty():
		return DEFAULT_OUTFIT_ID
	return StringName(outfit_text)


func get_date_cooldown_remaining_minutes(girl_id: StringName) -> int:
	var girls: Variant = _girls_service()
	var clock: Variant = _time_service()
	if girls == null or clock == null:
		return 0
	var remaining: int = int(girls.get_next_date_available_at(girl_id)) - int(clock.get_game_time_minutes())
	return maxi(0, remaining)


func restore_active_date() -> bool:
	if not has_active_date():
		_engine = null
		return false
	return _create_engine(get_active_girl_id(), get_active_location_id(), get_active_outfit_id())


func _resolve_outfit_id(outfit_id: StringName) -> StringName:
	if outfit_id != &"":
		return outfit_id
	var equipment: Variant = _equipment_service()
	if equipment != null:
		return equipment.get_equipped_outfit_id()
	return DEFAULT_OUTFIT_ID


func _create_engine(girl_id: StringName, date_location_id: StringName, outfit_id: StringName) -> bool:
	var catalog_service: DateCatalogService = get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return false
	var catalog: DateContentCatalog = catalog_service.catalog
	var girl: GirlProfile = catalog.find_girl(girl_id)
	if girl == null:
		return false
	if catalog.find_location(date_location_id) == null:
		return false
	if catalog.find_outfit(outfit_id) == null:
		return false
	var girls: Variant = _girls_service()
	var progress := GirlProgress.new()
	progress.reset_to_profile(girl)
	if girls != null:
		girls.fill_date_progress(girl_id, progress)
	progress.realign_revealed_to_profile(girl, catalog)
	var config := DateSessionConfig.new()
	config.seed = randi()
	config.girl_id = girl_id
	config.location_id = date_location_id
	config.outfit_id = outfit_id
	config.catalog = catalog
	config.girl_progress = progress
	config.player_state = _make_player_state(catalog.find_location(date_location_id))
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	return true


func _make_player_state(location: DateLocation) -> TestPlayerState:
	var player := TestPlayerState.new()
	var characteristics: Variant = _characteristic_service()
	if characteristics != null:
		player.muscle = int(characteristics.get_value(CharacteristicIds.MUSCLE))
		player.appearance = int(characteristics.get_value(CharacteristicIds.APPEARANCE))
		player.capital = int(characteristics.get_value(CharacteristicIds.CAPITAL))
		player.aura = int(characteristics.get_value(CharacteristicIds.AURA))
	var apartment: Variant = _apartment_service()
	if apartment != null and location != null and location.uses_apartment_quality:
		player.apartment_quality = int(apartment.get_quality())
	player.apartment_prepared = true
	return player


func _catalog() -> DateContentCatalog:
	var catalog_service: DateCatalogService = get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog


func _dating() -> DatingState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.dating as DatingState


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node


func _girls_service() -> Variant:
	var node: Node = get_node_or_null("/root/GirlsService")
	if not is_instance_valid(node):
		push_error("GirlsService autoload missing")
		return null
	return node


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
		return null
	return node


func _equipment_service() -> Variant:
	var node: Node = get_node_or_null("/root/EquipmentService")
	if not is_instance_valid(node):
		push_error("EquipmentService autoload missing")
		return null
	return node


func _characteristic_service() -> Variant:
	var node: Node = get_node_or_null("/root/CharacteristicService")
	if not is_instance_valid(node):
		push_error("CharacteristicService autoload missing")
		return null
	return node


func _apartment_service() -> Variant:
	var node: Node = get_node_or_null("/root/ApartmentService")
	if not is_instance_valid(node):
		push_error("ApartmentService autoload missing")
		return null
	return node
