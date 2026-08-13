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
	call_deferred("_ensure_interact_outline")


func _ensure_interact_outline() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if get_node_or_null("InteractOutline") != null:
		return
	var script: GDScript = load("res://world/fx/interact_outline.gd") as GDScript
	if script == null:
		return
	var outline: Node = script.new() as Node
	outline.name = "InteractOutline"
	add_child(outline)
