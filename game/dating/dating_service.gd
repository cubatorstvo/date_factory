extends Node

signal date_started(girl_id: StringName)
signal date_completed(girl_id: StringName, relationship_delta: int, current_relationship: int)

const START_ACTION_PREFIX: String = "start_date_"
const DATE_DURATION_MINUTES: int = 120
const DEFAULT_OUTFIT_ID: StringName = OutfitCatalog.START_OUTFIT_ID
const REASON_NOT_DISCOVERED: String = "Вы ещё не знакомы"
const REASON_NO_CONTACT: String = "У вас нет контакта этой девушки"
const REASON_COOLDOWN: String = "Сегодня уже встречались. Следующая встреча: завтра."
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


func can_start_date(girl_id: StringName, bypass_cooldown: bool = false) -> bool:
	return get_start_date_failure_reason(girl_id, bypass_cooldown).is_empty()


func get_start_date_failure_reason(girl_id: StringName, bypass_cooldown: bool = false) -> String:
	var girls: Variant = _girls_service()
	if girls == null or girls.get_definition(girl_id) == null:
		return REASON_NOT_DISCOVERED
	if not bool(girls.is_discovered(girl_id)):
		return REASON_NOT_DISCOVERED
	if not bool(girls.has_contact(girl_id)):
		return REASON_NO_CONTACT
	if not bypass_cooldown and not is_free_date_available_today(girl_id):
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


func get_available_date_venues(girl_id: StringName) -> Array:
	var result: Array[DateVenue] = []
	var catalog: DateContentCatalog = _catalog()
	if catalog == null:
		return result
	if catalog.find_girl(girl_id) == null:
		return result
	for location in catalog.date_venues:
		if location != null and location.enabled:
			result.append(location)
	return result


func is_date_venue_available(girl_id: StringName, date_venue_id: StringName) -> bool:
	if date_venue_id == &"":
		return false
	for date_venue in get_available_date_venues(girl_id):
		if date_venue != null and date_venue.id == date_venue_id:
			return true
	return false


func resolve_date_local_object_ids(date_venue_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var catalog: DateContentCatalog = _catalog()
	if catalog == null or date_venue_id == &"":
		return result
	var location: DateVenue = catalog.find_venue(date_venue_id)
	if location == null:
		return result
	for object_id in location.local_object_ids:
		if object_id != &"" and not result.has(object_id):
			result.append(object_id)
	if location.uses_apartment_preparation:
		var apartment: Variant = _apartment_service()
		if apartment != null:
			for object_id in apartment.get_granted_local_object_ids():
				if object_id != &"" and not result.has(object_id):
					result.append(object_id)
	return result


func create_start_date_action(
	girl_id: StringName,
	date_venue_id: StringName,
	outfit_id: StringName = &"",
	options: Dictionary = {}
) -> GameAction:
	var resolved_outfit_id: StringName = _resolve_outfit_id(outfit_id)
	var backup_outfit_id: StringName = StringName(str(options.get("backup_outfit_id", "")))
	var express_styling: bool = bool(options.get("express_styling", false))
	var urgent_taxi: bool = bool(options.get("urgent_taxi", false))
	var action := GameAction.new()
	action.id = StringName("%s%s" % [START_ACTION_PREFIX, String(girl_id)])
	action.time_cost_minutes = 0
	action.money_cost = 0
	if express_styling:
		action.money_cost += FillerRewardCatalog.KIRA_STYLING_COST
	if urgent_taxi:
		action.money_cost += FillerRewardCatalog.RITA_TAXI_COST
	var availability := DateAvailableRequirement.new()
	availability.girl_id = girl_id
	availability.bypass_cooldown = urgent_taxi
	action.requirements.append(availability)
	if express_styling:
		var styling_req := FillerRewardUnlockedRequirement.new()
		styling_req.reward_id = FillerRewardCatalog.ID_KIRA_EXPRESS_STYLING
		action.requirements.append(styling_req)
	if urgent_taxi:
		var taxi_req := FillerRewardUnlockedRequirement.new()
		taxi_req.reward_id = FillerRewardCatalog.ID_RITA_URGENT_TAXI
		action.requirements.append(taxi_req)
	var venue_requirement := DateVenueAvailableRequirement.new()
	venue_requirement.girl_id = girl_id
	venue_requirement.date_venue_id = date_venue_id
	action.requirements.append(venue_requirement)
	var outfit_requirement := OutfitOwnedRequirement.new()
	outfit_requirement.outfit_id = resolved_outfit_id
	action.requirements.append(outfit_requirement)
	if backup_outfit_id != &"":
		var backup_req := OutfitOwnedRequirement.new()
		backup_req.outfit_id = backup_outfit_id
		action.requirements.append(backup_req)
	var effect := StartDateEffect.new()
	effect.girl_id = girl_id
	effect.date_venue_id = date_venue_id
	effect.outfit_id = resolved_outfit_id
	effect.backup_outfit_id = backup_outfit_id
	effect.express_styling = express_styling
	effect.urgent_taxi = urgent_taxi
	action.effects.append(effect)
	return action


func start_date(
	girl_id: StringName,
	date_venue_id: StringName,
	outfit_id: StringName = &"",
	options: Dictionary = {}
) -> bool:
	var resolved_outfit_id: StringName = _resolve_outfit_id(outfit_id)
	var backup_outfit_id: StringName = StringName(str(options.get("backup_outfit_id", "")))
	var express_styling: bool = bool(options.get("express_styling", false))
	var urgent_taxi: bool = bool(options.get("urgent_taxi", false))
	if not can_start_date(girl_id, urgent_taxi):
		return false
	if not is_date_venue_available(girl_id, date_venue_id):
		return false
	var equipment: Variant = _equipment_service()
	if equipment == null or not bool(equipment.owns_outfit(resolved_outfit_id)):
		return false
	if backup_outfit_id != &"" and (backup_outfit_id == resolved_outfit_id or not bool(equipment.owns_outfit(backup_outfit_id))):
		return false
	equipment.equip_outfit(resolved_outfit_id)
	var catalog: DateContentCatalog = _catalog()
	var venue: DateVenue = catalog.find_venue(date_venue_id) if catalog != null else null
	var apartment: Variant = _apartment_service()
	var girls: Variant = _girls_service()
	if venue != null and venue.uses_apartment_preparation and apartment != null and girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_LERA_APARTMENT_CLEANING)):
		apartment.set_prepared(true)
	var dating: DatingState = _dating()
	var clock: Variant = _time_service()
	if dating == null or clock == null:
		return false
	if not _create_engine(girl_id, date_venue_id, resolved_outfit_id, backup_outfit_id, express_styling):
		return false
	if not urgent_taxi:
		_register_free_date_usage(girl_id)
	dating.active_date = {
		"girl_id": girl_id,
		"venue_id": date_venue_id,
		"outfit_id": resolved_outfit_id,
		"backup_outfit_id": backup_outfit_id,
		"express_styling": express_styling,
		"urgent_taxi": urgent_taxi,
		"outfit_swap_used": false,
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
	var venue: DateVenue = _catalog().find_venue(StringName(str(dating.active_date.get("venue_id", "")))) if _catalog() != null else null
	if venue != null and venue.uses_apartment_preparation:
		var apartment: Variant = _apartment_service()
		if apartment != null:
			apartment.set_prepared(false)
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


func get_active_venue_id() -> StringName:
	var dating: DatingState = _dating()
	if dating == null:
		return &""
	var venue_text: String = str(dating.active_date.get("venue_id", dating.active_date.get("location_id", "")))
	return StringName(venue_text)


func get_active_outfit_id() -> StringName:
	var dating: DatingState = _dating()
	if dating == null:
		return &""
	var outfit_text: String = str(dating.active_date.get("outfit_id", ""))
	if outfit_text.is_empty():
		return DEFAULT_OUTFIT_ID
	return StringName(outfit_text)


func is_free_date_available_today(girl_id: StringName) -> bool:
	var daily: Variant = _daily_activity()
	if daily == null:
		return false
	return bool(daily.is_available(daily.date_key(girl_id), 1))


func get_date_cooldown_remaining_minutes(girl_id: StringName) -> int:
	if is_free_date_available_today(girl_id):
		return 0
	var clock: Variant = _time_service()
	if clock == null:
		return 0
	var minutes: int = int(clock.get_game_time_minutes())
	var next_day_start: int = (int(minutes / 1440) + 1) * 1440
	return maxi(0, next_day_start - minutes)


func _register_free_date_usage(girl_id: StringName) -> void:
	var daily: Variant = _daily_activity()
	if daily == null:
		return
	daily.register_usage(daily.date_key(girl_id), 1)


func _daily_activity() -> Variant:
	return get_node_or_null("/root/DailyActivityService")


func restore_active_date() -> bool:
	if not has_active_date():
		_engine = null
		return false
	return _create_engine(get_active_girl_id(), get_active_venue_id(), get_active_outfit_id())


func _resolve_outfit_id(outfit_id: StringName) -> StringName:
	if outfit_id != &"":
		return outfit_id
	var equipment: Variant = _equipment_service()
	if equipment != null:
		return equipment.get_current_outfit_id()
	return DEFAULT_OUTFIT_ID


func try_vika_reroll() -> String:
	if _engine == null:
		return "Других вариантов сейчас нет."
	var economy: Variant = _economy_service()
	if economy == null or not bool(economy.can_afford(FillerRewardCatalog.VIKA_REROLL_COST)):
		return "Недостаточно денег."
	var error_text: String = _engine.reroll_base_moves()
	if not error_text.is_empty():
		return error_text
	economy.spend_money(FillerRewardCatalog.VIKA_REROLL_COST)
	return ""


func _economy_service() -> Variant:
	return get_node_or_null("/root/EconomyService")


func _create_engine(girl_id: StringName, date_venue_id: StringName, outfit_id: StringName, backup_outfit_id: StringName = &"", express_styling: bool = false) -> bool:
	var catalog_service: DateCatalogService = get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return false
	var catalog: DateContentCatalog = catalog_service.catalog
	var girl: GirlProfile = catalog.find_girl(girl_id)
	if girl == null:
		return false
	if catalog.find_venue(date_venue_id) == null:
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
	config.venue_id = date_venue_id
	config.outfit_id = outfit_id
	config.catalog = catalog
	config.girl_progress = progress
	config.local_object_ids = resolve_date_local_object_ids(date_venue_id)
	config.player_snapshot = _make_player_snapshot(catalog.find_venue(date_venue_id), express_styling)
	if girls != null:
		config.relationship_max = int(girls.get_relationship_max(girl_id))
		config.vika_reroll_available = bool(girls.has_filler_reward(FillerRewardCatalog.ID_VIKA_BASE_REROLL))
		config.dasha_soften_available = bool(girls.has_filler_reward(FillerRewardCatalog.ID_DASHA_SOFTEN_NEGATIVE))
		config.nika_swap_available = bool(girls.has_filler_reward(FillerRewardCatalog.ID_NIKA_BACKUP_OUTFIT)) and backup_outfit_id != &""
		if bool(girls.has_filler_reward(FillerRewardCatalog.ID_SONYA_RESTAURANT_SECOND_VENUE)) and date_venue_id == &"restaurant":
			config.venue_source_limit = 2
	else:
		config.relationship_max = GirlCatalog.seed_relationship_max(girl_id)
	config.backup_outfit_id = backup_outfit_id
	config.express_styling_bonus = 1 if express_styling else 0
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	return true


func _make_player_snapshot(venue: DateVenue, express_styling: bool = false) -> DatePlayerSnapshot:
	var player := DatePlayerSnapshot.new()
	var characteristics: Variant = _characteristic_service()
	if characteristics != null:
		player.muscle = int(characteristics.get_value(CharacteristicIds.MUSCLE))
		player.appearance = int(characteristics.get_value(CharacteristicIds.APPEARANCE))
		player.capital = int(characteristics.get_value(CharacteristicIds.CAPITAL))
		player.aura = int(characteristics.get_value(CharacteristicIds.AURA))
	player.express_styling_bonus = 1 if express_styling else 0
	var apartment: Variant = _apartment_service()
	player.apartment_prepared = true
	if apartment != null and venue != null and venue.uses_apartment_preparation:
		player.apartment_prepared = bool(apartment.is_prepared())
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
