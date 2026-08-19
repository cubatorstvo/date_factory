class_name LocationDefinition
extends Resource

enum LocationType {
	CITY_ZONE,
	INTERIOR,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var location_type: LocationType = LocationType.CITY_ZONE
@export_file("*.tscn") var scene_path: String = ""
@export var default_spawn_id: StringName = &"default"
@export var parent_location_id: StringName = &""
