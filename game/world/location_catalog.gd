class_name LocationCatalog
extends Resource

const ID_CITY_CENTER: StringName = &"city_center"
const ID_APARTMENT: StringName = &"apartment"
const ID_CAFE: StringName = &"cafe"
const ID_LEISURE_CENTER: StringName = &"leisure_center"
const ID_RESTAURANT: StringName = &"restaurant"
const ID_FURNITURE_STORE: StringName = &"furniture_store"
const START_LOCATION_ID: StringName = ID_CITY_CENTER
const SPAWN_DEFAULT: StringName = &"default"
const SPAWN_ENTRANCE: StringName = &"entrance"
const SPAWN_APARTMENT_DOOR: StringName = &"apartment_door"
const SPAWN_CAFE_DOOR: StringName = &"cafe_door"
const SPAWN_LEISURE_CENTER_DOOR: StringName = &"leisure_center_door"
const SPAWN_RESTAURANT_DOOR: StringName = &"restaurant_door"
const SPAWN_FURNITURE_STORE_DOOR: StringName = &"furniture_store_door"
const SCENE_CITY_CENTER: String = "res://game/world/locations/city_center.tscn"
const SCENE_APARTMENT: String = "res://game/world/locations/apartment.tscn"
const SCENE_CAFE: String = "res://game/world/locations/cafe.tscn"
const SCENE_LEISURE_CENTER: String = "res://game/world/locations/leisure_center.tscn"
const SCENE_RESTAURANT: String = "res://game/world/locations/restaurant.tscn"
const SCENE_FURNITURE_STORE: String = "res://game/world/locations/furniture_store.tscn"

const START_UNLOCKED_LOCATION_IDS: Array[StringName] = [
	ID_CITY_CENTER,
	ID_APARTMENT,
	ID_CAFE,
]

@export var locations: Array[LocationDefinition] = []


func get_location(location_id: StringName) -> LocationDefinition:
	if location_id == &"":
		return null
	for location in locations:
		if location != null and location.id == location_id:
			return location
	return null


func get_all_locations() -> Array[LocationDefinition]:
	var result: Array[LocationDefinition] = []
	for location in locations:
		if location != null:
			result.append(location)
	return result


func get_locations_by_type(location_type: LocationDefinition.LocationType) -> Array[LocationDefinition]:
	var result: Array[LocationDefinition] = []
	for location in locations:
		if location != null and location.location_type == location_type:
			result.append(location)
	return result


func get_interiors_for_zone(zone_id: StringName) -> Array[LocationDefinition]:
	var result: Array[LocationDefinition] = []
	if zone_id == &"":
		return result
	for location in locations:
		if location == null:
			continue
		if location.location_type != LocationDefinition.LocationType.INTERIOR:
			continue
		if location.parent_location_id == zone_id:
			result.append(location)
	return result


static func create_seed() -> LocationCatalog:
	var catalog := LocationCatalog.new()
	catalog.locations.append(_make_zone(ID_CITY_CENTER, "Центральная часть города", SCENE_CITY_CENTER, SPAWN_DEFAULT))
	catalog.locations.append(_make_interior(ID_APARTMENT, "Квартира", SCENE_APARTMENT, ID_CITY_CENTER))
	catalog.locations.append(_make_interior(ID_CAFE, "Кафе", SCENE_CAFE, ID_CITY_CENTER))
	catalog.locations.append(_make_interior(ID_LEISURE_CENTER, "Центр досуга", SCENE_LEISURE_CENTER, ID_CITY_CENTER))
	catalog.locations.append(_make_interior(ID_RESTAURANT, "Ресторан", SCENE_RESTAURANT, ID_CITY_CENTER))
	catalog.locations.append(_make_interior(ID_FURNITURE_STORE, "Мебельный магазин", SCENE_FURNITURE_STORE, ID_CITY_CENTER))
	return catalog


static func _make_zone(id: StringName, display_name: String, scene_path: String, spawn_id: StringName) -> LocationDefinition:
	var location := LocationDefinition.new()
	location.id = id
	location.display_name = display_name
	location.location_type = LocationDefinition.LocationType.CITY_ZONE
	location.scene_path = scene_path
	location.default_spawn_id = spawn_id
	location.parent_location_id = &""
	return location


static func _make_interior(id: StringName, display_name: String, scene_path: String, parent_id: StringName) -> LocationDefinition:
	var location := LocationDefinition.new()
	location.id = id
	location.display_name = display_name
	location.location_type = LocationDefinition.LocationType.INTERIOR
	location.scene_path = scene_path
	location.default_spawn_id = SPAWN_ENTRANCE
	location.parent_location_id = parent_id
	return location
