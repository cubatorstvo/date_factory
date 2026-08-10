class_name OpeningBedInteractable
extends Interactable
## One-shot bed handoff for the standalone opening evening scene.

signal sleep_requested

var _used: bool = false


func can_interact(player: Node) -> bool:
	return not _used and super.can_interact(player)


func _on_interact(_player: Node) -> void:
	if _used:
		return
	_used = true
	interaction_enabled = false
	sleep_requested.emit()


func reset_for_test() -> void:
	_used = false
	interaction_enabled = true
