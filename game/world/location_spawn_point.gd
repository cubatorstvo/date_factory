class_name LocationSpawnPoint
extends Marker3D

@export var spawn_id: StringName = &"default"


func _ready() -> void:
	add_to_group("location_spawn_points")
