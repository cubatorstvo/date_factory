class_name ArrivalPipeline
extends RefCounted
## Shared door → path → seat / leave pipeline for dates and world arrivals.
## Never spawn already-seated: callers must begin at `from` (door), not `to` (seat).

enum Phase { IDLE, INTRO, OUTRO, READY }

var phase: Phase = Phase.IDLE
var time: float = 0.0
var from: Vector3 = Vector3.ZERO
var to: Vector3 = Vector3.ZERO
var intro_duration: float = 2.0
var outro_duration: float = 1.2
var sit_settle: float = 0.3


func reset() -> void:
	phase = Phase.IDLE
	time = 0.0


func begin_intro(door_pos: Vector3, seat_pos: Vector3, duration: float = 2.0) -> void:
	from = door_pos
	to = seat_pos
	intro_duration = maxf(0.2, duration)
	phase = Phase.INTRO
	time = 0.0


func begin_outro(seat_pos: Vector3, door_pos: Vector3, duration: float = 1.2) -> void:
	from = seat_pos
	to = door_pos
	outro_duration = maxf(0.2, duration)
	phase = Phase.OUTRO
	time = 0.0


func skip_intro_to_ready() -> Dictionary:
	## Snap to seat after player skip; still counts as walked (not spawn-seated).
	phase = Phase.READY
	time = 0.0
	return {"position": to, "sitting": true, "done": true, "phase": "ready"}


func tick(delta: float) -> Dictionary:
	time += delta
	match phase:
		Phase.INTRO:
			var walk_t := clampf(time / intro_duration, 0.0, 1.0)
			var pos: Vector3 = from.lerp(to, walk_t)
			var sitting := walk_t >= 1.0
			var sit_blend := 0.0
			if sitting:
				sit_blend = clampf((time - intro_duration) / sit_settle, 0.0, 1.0)
			var done := sitting and time >= intro_duration + sit_settle
			if done:
				phase = Phase.READY
				pos = to
			return {"position": pos, "sitting": sitting, "sit_blend": sit_blend, "done": done, "phase": "intro"}
		Phase.OUTRO:
			var leave_t := clampf(time / outro_duration, 0.0, 1.0)
			var pos2: Vector3 = from.lerp(to, leave_t)
			var still_sit := leave_t < 0.2
			return {"position": pos2, "sitting": still_sit, "sit_blend": 1.0 if still_sit else 0.0, "done": leave_t >= 1.0, "phase": "outro"}
		Phase.READY:
			## Stay "done" after intro so callers can wait on sit_enter after the walk pulse.
			return {"position": to, "sitting": true, "sit_blend": 1.0, "done": true, "phase": "ready"}
		_:
			return {"position": from, "sitting": false, "sit_blend": 0.0, "done": false, "phase": "idle"}


static func assert_starts_at_door(current: Vector3, door_pos: Vector3, seat_pos: Vector3) -> bool:
	## True if spawn is nearer door than seat (anti spawn-already-sitting).
	return current.distance_to(door_pos) <= current.distance_to(seat_pos) + 0.01
