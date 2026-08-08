extends Node
## Minimal integer game-day broadcaster (MODULE 13).
## Autoload name: GameDay. Not a time-of-day / schedule system.

signal day_advanced(new_day: int)

var current_day: int = 1


func _ready() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	DfLog.info("MODULE_13", "GameDay ready")


func get_current_day() -> int:
	return current_day


func advance_day() -> int:
	current_day += 1
	day_advanced.emit(current_day)
	return current_day


## Save/Load restore — does not emit day_advanced.
func restore_day(day: int) -> bool:
	if day < 1:
		push_error("[GameDay] restore_day rejected day=%s" % day)
		return false
	current_day = day
	return true


func _on_state_reset() -> void:
	current_day = 1
