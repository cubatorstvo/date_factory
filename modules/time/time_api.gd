class_name TimeAPI
extends Node
## Lightweight in-game clock. Not a hard schedule sim — just planning tension.

signal time_changed(day: int, minutes: int)
signal day_changed(day: int)

const MINUTES_PER_DAY := 24 * 60
## Real seconds → game minutes. ~1 real minute ≈ 30 game minutes.
const DEFAULT_SCALE := 0.5

var day: int = 1
var minutes: float = 18.0 * 60.0 ## start early evening
var time_scale: float = DEFAULT_SCALE
var paused: bool = false
var _emit_bucket: int = -1


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	day = 1
	minutes = 18.0 * 60.0
	time_scale = DEFAULT_SCALE
	paused = false
	_emit_bucket = -1
	_emit()


func _process(delta: float) -> void:
	if not Game.run_started or paused:
		return
	if not Game.dating.active_manual.is_empty():
		return
	advance_minutes(delta * time_scale)


func advance_minutes(amount: float) -> void:
	if amount <= 0.0:
		return
	minutes += amount
	while minutes >= float(MINUTES_PER_DAY):
		minutes -= float(MINUTES_PER_DAY)
		day += 1
		day_changed.emit(day)
	_emit()


func skip_to_minutes(target_day: int, target_minutes: int) -> void:
	## Fast-forward to an absolute day/minute (for sitting and waiting).
	var now := absolute_minutes()
	var goal := (target_day - 1) * MINUTES_PER_DAY + clampi(target_minutes, 0, MINUTES_PER_DAY - 1)
	if goal <= now:
		return
	var delta := goal - now
	day = target_day
	minutes = float(target_minutes)
	_emit()
	if delta > 0:
		EventBus.toast("Время промотано: +%d мин." % delta, &"info")


func absolute_minutes() -> int:
	return (day - 1) * MINUTES_PER_DAY + int(minutes)


func clock_minutes() -> int:
	return int(minutes) % MINUTES_PER_DAY


func format_clock(mins: int = -1) -> String:
	var m := clock_minutes() if mins < 0 else (mins % MINUTES_PER_DAY)
	return "%02d:%02d" % [int(m / 60.0), m % 60]


func format_day_clock() -> String:
	return "День %d — %s" % [day, format_clock()]


func minutes_until(target_day: int, target_minutes: int) -> int:
	var goal := (target_day - 1) * MINUTES_PER_DAY + clampi(target_minutes, 0, MINUTES_PER_DAY - 1)
	return goal - absolute_minutes()


func slot_label(target_day: int, target_minutes: int) -> String:
	var diff_day := target_day - day
	var when := "Сегодня"
	if diff_day == 1:
		when = "Завтра"
	elif diff_day > 1:
		when = "День %d" % target_day
	elif diff_day < 0:
		when = "Прошло"
	return "%s, %s" % [when, format_clock(target_minutes)]


func next_slots(count: int = 8, step: int = 30, min_lead: int = 45) -> Array:
	## Returns [{day, minutes, label}, ...] starting at least min_lead minutes ahead.
	var out: Array = []
	var start := clock_minutes() + min_lead
	var slot_day := day
	if start >= MINUTES_PER_DAY:
		start -= MINUTES_PER_DAY
		slot_day += 1
	start = int(ceili(float(start) / float(step)) * step)
	if start >= MINUTES_PER_DAY:
		start = 0
		slot_day += 1
	for _i in range(count):
		out.append({
			"day": slot_day,
			"minutes": start,
			"label": slot_label(slot_day, start),
		})
		start += step
		if start >= MINUTES_PER_DAY:
			start -= MINUTES_PER_DAY
			slot_day += 1
	return out


func _emit() -> void:
	var bucket := clock_minutes()
	if bucket == _emit_bucket:
		return
	_emit_bucket = bucket
	time_changed.emit(day, bucket)
	EventBus.time_changed.emit(day, bucket)


func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes, "time_scale": time_scale}


func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	minutes = float(data.get("minutes", 18.0 * 60.0))
	time_scale = float(data.get("time_scale", DEFAULT_SCALE))
	_emit_bucket = -1
	_emit()
