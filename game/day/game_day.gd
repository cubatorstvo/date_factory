extends Node
## Integer game-day and ticking clock 0–23:59 (MODULE 13).
## Autoload name: GameDay. Minutes tick in GAMEPLAY; sleep jumps to 08:00.

signal day_advanced(new_day: int)
signal hour_changed(new_hour: int)
signal minute_changed(new_minute: int)

const SECONDS_PER_GAME_MINUTE: float = 1.0

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var _minute_accum: float = 0.0


func _ready() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	DfLog.info("MODULE_13", "GameDay ready")


func get_current_day() -> int:
	return current_day


func get_current_hour() -> int:
	return current_hour


func get_current_minute() -> int:
	return current_minute


func advance_day() -> int:
	current_day += 1
	current_hour = 8
	current_minute = 0
	_minute_accum = 0.0
	day_advanced.emit(current_day)
	hour_changed.emit(current_hour)
	minute_changed.emit(current_minute)
	return current_day


func wait_until_hour(hour: int) -> void:
	var target: int = clampi(hour, 0, 23)
	## Next day only when that hour is already finished. 21:10 waiting until 21 stays today.
	if target < current_hour:
		advance_day()
	current_hour = target
	current_minute = 0
	_minute_accum = 0.0
	hour_changed.emit(current_hour)
	minute_changed.emit(current_minute)


func restore_day(day: int) -> bool:
	if day < 1:
		push_error("[GameDay] restore_day rejected day=%s" % day)
		return false
	current_day = day
	return true


func restore_hour(hour: int) -> bool:
	if hour < 0 or hour > 23:
		push_error("[GameDay] restore_hour rejected hour=%s" % hour)
		return false
	current_hour = hour
	return true


func restore_minute(minute: int) -> bool:
	if minute < 0 or minute > 59:
		push_error("[GameDay] restore_minute rejected minute=%s" % minute)
		return false
	current_minute = minute
	_minute_accum = 0.0
	return true


func tick_one_minute() -> void:
	_advance_one_minute()


func _process(delta: float) -> void:
	if not _should_tick():
		return
	_minute_accum += delta
	while _minute_accum >= SECONDS_PER_GAME_MINUTE:
		_minute_accum -= SECONDS_PER_GAME_MINUTE
		_advance_one_minute()


func _should_tick() -> bool:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_player"):
		return false
	var player: Node = world.call("get_player") as Node
	if player == null or not is_instance_valid(player):
		return false
	if player.has_method("get_control_mode"):
		if int(player.call("get_control_mode")) != int(PlayerController.ControlMode.GAMEPLAY):
			return false
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_method("is_date_active") and bool(dc.call("is_date_active")):
		return false
	return true


func _advance_one_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			day_advanced.emit(current_day)
		hour_changed.emit(current_hour)
	minute_changed.emit(current_minute)


func _on_state_reset() -> void:
	current_day = 1
	current_hour = 8
	current_minute = 0
	_minute_accum = 0.0
