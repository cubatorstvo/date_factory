extends Node

var flow: FlowState
var story: StoryState
var player: PlayerState
var progression: ProgressionState
var world: WorldState
var girls: GirlsState
var dating: DatingState
var rivals: RivalsState
var automation: AutomationState


func _ready() -> void:
	apply_new_game()


func apply_new_game() -> void:
	flow = FlowState.new()
	story = StoryState.new()
	player = PlayerState.new()
	progression = ProgressionState.new()
	world = WorldState.new()
	girls = GirlsState.new()
	dating = DatingState.new()
	rivals = RivalsState.new()
	automation = AutomationState.new()


func to_dict() -> Dictionary:
	return {
		"flow": flow.to_dict(),
		"story": story.to_dict(),
		"player": player.to_dict(),
		"progression": progression.to_dict(),
		"world": world.to_dict(),
		"girls": girls.to_dict(),
		"dating": dating.to_dict(),
		"rivals": rivals.to_dict(),
		"automation": automation.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	apply_new_game()
	flow.from_dict(_section(data, "flow"))
	story.from_dict(_section(data, "story"))
	player.from_dict(_section(data, "player"))
	progression.from_dict(_section(data, "progression"))
	world.from_dict(_section(data, "world"))
	girls.from_dict(_section(data, "girls"))
	dating.from_dict(_section(data, "dating"))
	rivals.from_dict(_section(data, "rivals"))
	automation.from_dict(_section(data, "automation"))


func _section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	return {}
