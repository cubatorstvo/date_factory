extends Area3D
## Visual-bootstrap stub for donor city POI InteractionAreas.
## Keeps scene property loads working; does not participate in gameplay travel.

@export var action_id: StringName = &""
@export var display_name: String = ""
@export var action_label: String = ""
@export var payload: Dictionary = {}
@export var prompt_text: String = ""


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
