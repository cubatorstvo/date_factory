extends Node

signal date_started(girl_id: StringName)
signal date_completed(girl_id: StringName, relationship_delta: int, current_relationship: int)

const START_ACTION_PREFIX: String = "start_date_"
const DATE_COOLDOWN_DAYS: int = 3
const DATE_DURATION_MINUTES: int = 120
const DEFAULT_OUTFIT_ID: StringName = &"casual"
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
	return ""


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


func create_start_date_action(girl_id: StringName, date_location_id: StringName) -> GameAction:
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
	var effect := StartDateEffect.new()
	effect.girl_id = girl_id
	effect.date_location_id = date_location_id
	action.effects.append(effect)
	return action


func start_date(girl_id: StringName, date_location_id: StringName) -> bool:
	if not can_start_date(girl_id):
		return false
	if not is_date_location_available(girl_id, date_location_id):
		return false
	var dating: DatingState = _dating()
	var clock: Variant = _time_service()
	if dating == null or clock == null:
		return false
	if not _create_engine(girl_id, date_location_id):
		return false
	dating.active_date = {
		"girl_id": girl_id,
		"location_id": date_location_id,
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
	return _create_engine(get_active_girl_id(), get_active_location_id())


func _create_engine(girl_id: StringName, date_location_id: StringName) -> bool:
	var catalog_service: DateCatalogService = get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return false
	var catalog: DateContentCatalog = catalog_service.catalog
	var girl: GirlProfile = catalog.find_girl(girl_id)
	if girl == null:
		return false
	if catalog.find_location(date_location_id) == null:
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
	config.outfit_id = DEFAULT_OUTFIT_ID
	config.catalog = catalog
	config.girl_progress = progress
	config.player_state = TestPlayerState.new()
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	return true


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
