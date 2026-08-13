class_name Interactable
extends Area3D
## Minimal world interaction contract for MODULE 01.
## Feature systems later wrap this without Player knowing domain types.

@export var prompt_action: String = "Использовать"
@export var interaction_enabled: bool = true

signal interacted(by: Node)


func _enter_tree() -> void:
	call_deferred("_ensure_interact_outline")


func _ensure_interact_outline() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if Engine.is_editor_hint():
		return
	if get_node_or_null("InteractOutline") != null:
		return
	var script: GDScript = load("res://world/fx/interact_outline.gd") as GDScript
	if script == null:
		return
	var outline: Node = script.new() as Node
	outline.name = "InteractOutline"
	add_child(outline)


func can_interact(_player: Node) -> bool:
	return interaction_enabled and is_inside_tree() and not is_queued_for_deletion()


func get_interaction_prompt(_player: Node) -> String:
	return "[E] %s" % prompt_action


func interact(player: Node) -> void:
	if not can_interact(player):
		return
	interacted.emit(player)
	_on_interact(player)


func _on_interact(_player: Node) -> void:
	pass
