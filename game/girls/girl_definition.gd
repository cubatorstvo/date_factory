class_name GirlDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var location_id: StringName = &""
@export var relationship_min: int = 0
@export var relationship_max: int = 0
@export var meet_requirements: Array[GirlAccessRequirement] = []
@export var date_requirements: Array[GirlAccessRequirement] = []
