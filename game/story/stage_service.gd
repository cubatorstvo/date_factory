extends Node

signal stage_changed(previous_stage: int, current_stage: int)
signal finale_reached()

const FIRST_STAGE: int = 1
const LAST_STAGE: int = 6


func get_current_stage() -> int:
	var story: StoryState = _story()
	if story == null:
		return FIRST_STAGE
	return story.stage


func is_finale_reached() -> bool:
	var story: StoryState = _story()
	if story == null:
		return false
	return story.finale_reached


func complete_current_stage() -> bool:
	var story: StoryState = _story()
	if story == null:
		return false
	if story.finale_reached:
		return false
	if story.stage >= FIRST_STAGE and story.stage < LAST_STAGE:
		var previous_stage: int = story.stage
		story.stage = previous_stage + 1
		stage_changed.emit(previous_stage, story.stage)
		return true
	if story.stage == LAST_STAGE:
		story.finale_reached = true
		finale_reached.emit()
		return true
	return false


func _story() -> StoryState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.story as StoryState
