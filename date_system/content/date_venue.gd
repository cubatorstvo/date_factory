class_name DateVenue
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var uses_apartment_preparation: bool = false
@export var local_object_ids: Array[StringName] = []
@export var future_location_scene: PackedScene
