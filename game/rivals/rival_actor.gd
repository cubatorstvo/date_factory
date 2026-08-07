class_name RivalActor
extends Interactable
## Thin world adapter: rival_id + player challenge via RivalEncounters (MODULE 06).
## Not AI. Display/stats come from RivalDefinition.

@export var rival_id: StringName = &""

signal challenge_result(ok: bool, reason: StringName)


func _ready() -> void:
	prompt_action = "Вызвать"
	_refresh_interaction()


func _refresh_interaction() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_rival_defeated", rival_id)):
		interaction_enabled = false
	else:
		interaction_enabled = true


func can_interact(player: Node) -> bool:
	_refresh_interaction()
	return super.can_interact(player)


func get_interaction_prompt(player: Node) -> String:
	# Variant 1: always "Вызвать"; refusal happens after interact.
	return super.get_interaction_prompt(player)


func _on_interact(_player: Node) -> void:
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null:
		challenge_result.emit(false, &"NO_SERVICE")
		return
	var start: Dictionary = encounters.call(
		"start_encounter",
		rival_id,
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	var ok: bool = bool(start.get("ok", false))
	var reason: StringName = start.get("reason", &"") as StringName
	challenge_result.emit(ok, reason)
	_refresh_interaction()
