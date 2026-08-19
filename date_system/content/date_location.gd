class_name DateLocation
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var base_quality_bonus: int = 0
@export var preference_mode: DateTypes.LocationPreferenceMode = DateTypes.LocationPreferenceMode.NEUTRAL
@export var location_format_id: StringName = &""
@export var uses_apartment_quality: bool = false
@export var uses_apartment_preparation: bool = false
@export var future_location_scene: PackedScene
