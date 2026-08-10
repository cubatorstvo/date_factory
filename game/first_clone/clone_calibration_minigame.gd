class_name CloneCalibrationMinigame
extends CanvasLayer
## One-time 3-pass clone calibration (MODULE 17).
## Deterministic track; miss retries same pass; abort creates no clone.

signal calibration_finished()
signal calibration_aborted()
signal phase_changed(phase: FirstCloneTypes.CalibrationPhase)

var _phase: FirstCloneTypes.CalibrationPhase = FirstCloneTypes.CalibrationPhase.INTRO
var _pass_index: int = 0
var _pointer: float = 0.0
var _pointer_dir: float = 1.0
var _miss_timer: float = 0.0
var _in_miss_feedback: bool = false
var _player: Node = null
var _started: bool = false
var _finished: bool = false
@onready var _ui_root: Control = %Root
@onready var _continue_button: Button = $Root/Panel/MarginContainer/VBox/Buttons/ContinueBtn
@onready var _abort_button: Button = $Root/Panel/MarginContainer/VBox/Buttons/AbortBtn
var _last_feedback: String = ""
var _feedback_timer: float = 0.0
var _awaiting_feedback_advance: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(_ui_root)
	_continue_button.pressed.connect(_on_continue_pressed)
	_abort_button.pressed.connect(_on_abort_pressed)
	visible = false
	set_process(false)


func is_finished() -> bool:
	return _finished


func get_phase() -> FirstCloneTypes.CalibrationPhase:
	return _phase


func get_pass_index() -> int:
	return _pass_index


func get_pointer() -> float:
	return _pointer


func get_last_feedback() -> String:
	return _last_feedback


func is_in_miss_feedback() -> bool:
	return _in_miss_feedback


func get_pass_constants(pass_index: int = -1) -> Dictionary:
	var idx: int = _pass_index if pass_index < 0 else pass_index
	return {
		"label": FirstCloneTypes.pass_label(idx),
		"target_center": FirstCloneTypes.pass_center(idx),
		"target_width": FirstCloneTypes.pass_width(idx),
		"pointer_speed": FirstCloneTypes.pass_speed(idx),
	}


func start(player: Node = null) -> bool:
	if _started:
		return false
	_started = true
	_finished = false
	_player = player
	_pass_index = 0
	_pointer = 0.0
	_pointer_dir = 1.0
	_miss_timer = 0.0
	_in_miss_feedback = false
	_last_feedback = ""
	_feedback_timer = 0.0
	_awaiting_feedback_advance = false
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_minigame"):
		_player.call("enter_minigame", Input.MOUSE_MODE_VISIBLE)
	elif _player != null and is_instance_valid(_player) and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	_set_phase(FirstCloneTypes.CalibrationPhase.INTRO)
	_ui_root.visible = true
	visible = true
	set_process(true)
	_refresh_ui()
	return true


func abort_calibration() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	_teardown_ui()
	_restore_player()
	calibration_aborted.emit()
	queue_free()


func continue_intro() -> bool:
	if _finished:
		return false
	if _phase != FirstCloneTypes.CalibrationPhase.INTRO:
		return false
	_begin_pass(0)
	return true


## Deterministic pointer step. Reflects at 0..1.
func tick_pointer(delta: float) -> void:
	if _finished:
		return
	if _phase != FirstCloneTypes.CalibrationPhase.CALIBRATION:
		return
	if _in_miss_feedback:
		_miss_timer -= delta
		if _miss_timer <= 0.0:
			_in_miss_feedback = false
			_miss_timer = 0.0
			_last_feedback = ""
			_refresh_ui()
		return
	var speed: float = FirstCloneTypes.pass_speed(_pass_index)
	_pointer += _pointer_dir * speed * delta
	if _pointer >= 1.0:
		_pointer = 1.0
		_pointer_dir = -1.0
	elif _pointer <= 0.0:
		_pointer = 0.0
		_pointer_dir = 1.0
	_refresh_track_ui()


func try_space() -> bool:
	if _finished:
		return false
	match _phase:
		FirstCloneTypes.CalibrationPhase.INTRO:
			return continue_intro()
		FirstCloneTypes.CalibrationPhase.CALIBRATION:
			return try_press_at(_pointer)
		FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK:
			return _advance_after_pass_feedback()
		FirstCloneTypes.CalibrationPhase.COMPLETE:
			return _finish_success()
		_:
			return false


func try_press_at(normalized_pos: float) -> bool:
	if _finished:
		return false
	if _phase != FirstCloneTypes.CalibrationPhase.CALIBRATION:
		return false
	if _in_miss_feedback:
		return false
	var center: float = FirstCloneTypes.pass_center(_pass_index)
	var half: float = FirstCloneTypes.pass_width(_pass_index) * 0.5
	var lo: float = center - half
	var hi: float = center + half
	if normalized_pos >= lo and normalized_pos <= hi:
		_on_pass_success()
		return true
	_on_pass_miss()
	return false


## Test helper: force a hit on the current pass without aiming.
func force_hit_current_pass() -> bool:
	var center: float = FirstCloneTypes.pass_center(_pass_index)
	return try_press_at(center)


func _process(delta: float) -> void:
	if _finished:
		return
	if _phase == FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK and _awaiting_feedback_advance:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			_awaiting_feedback_advance = false
			_advance_after_pass_feedback()
		return
	if _phase == FirstCloneTypes.CalibrationPhase.CALIBRATION:
		tick_pointer(delta)
		if Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE):
			# Debounce via just_pressed for ui_accept; physical SPACE once per frame via edge.
			if Input.is_action_just_pressed("ui_accept") or _space_just_pressed():
				try_space()
	elif _phase == FirstCloneTypes.CalibrationPhase.INTRO:
		if Input.is_action_just_pressed("ui_accept") or _space_just_pressed():
			try_space()
	elif _phase == FirstCloneTypes.CalibrationPhase.COMPLETE:
		if Input.is_action_just_pressed("ui_accept") or _space_just_pressed():
			try_space()


var _space_was_down: bool = false


func _space_just_pressed() -> bool:
	var down: bool = Input.is_physical_key_pressed(KEY_SPACE)
	var just: bool = down and not _space_was_down
	_space_was_down = down
	return just


func _begin_pass(pass_index: int) -> void:
	_pass_index = pass_index
	_pointer = 0.0
	_pointer_dir = 1.0
	_in_miss_feedback = false
	_miss_timer = 0.0
	_last_feedback = ""
	_awaiting_feedback_advance = false
	_set_phase(FirstCloneTypes.CalibrationPhase.CALIBRATION)
	_refresh_ui()


func _on_pass_success() -> void:
	_audio_play_sfx(AudioIds.CLONE_CALIBRATE_ACCEPT)
	_last_feedback = FirstCloneTypes.pass_success_feedback(_pass_index)
	_set_phase(FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK)
	_feedback_timer = 0.7
	_awaiting_feedback_advance = true
	_refresh_ui()


func _on_pass_miss() -> void:
	_audio_play_sfx(AudioIds.CLONE_CALIBRATE_REJECT)
	_in_miss_feedback = true
	_miss_timer = FirstCloneTypes.MISS_FEEDBACK_SEC
	_last_feedback = FirstCloneTypes.FEEDBACK_MISS
	_refresh_ui()


func _advance_after_pass_feedback() -> bool:
	if _phase != FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK:
		return false
	_awaiting_feedback_advance = false
	if _pass_index >= 2:
		_last_feedback = FirstCloneTypes.FEEDBACK_COMPLETE
		_audio_play_sfx(AudioIds.CLONE_MACHINE_CHARGE)
		_set_phase(FirstCloneTypes.CalibrationPhase.COMPLETE)
		_refresh_ui()
		return true
	_begin_pass(_pass_index + 1)
	return true


func _finish_success() -> bool:
	if _finished:
		return false
	if _phase != FirstCloneTypes.CalibrationPhase.COMPLETE:
		return false
	_finished = true
	_set_phase(FirstCloneTypes.CalibrationPhase.FINISHED)
	set_process(false)
	_teardown_ui()
	_restore_player()
	calibration_finished.emit()
	queue_free()
	return true


## Test helper: complete remaining passes and finish without UI waits.
func force_complete_all_for_test() -> void:
	if _finished:
		return
	if _phase == FirstCloneTypes.CalibrationPhase.INTRO:
		continue_intro()
	while not _finished and _phase != FirstCloneTypes.CalibrationPhase.COMPLETE:
		if _phase == FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK:
			_advance_after_pass_feedback()
			continue
		if _phase == FirstCloneTypes.CalibrationPhase.CALIBRATION:
			force_hit_current_pass()
			if _phase == FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK:
				_advance_after_pass_feedback()
			continue
		break
	if _phase == FirstCloneTypes.CalibrationPhase.COMPLETE:
		_finish_success()


func _set_phase(phase: FirstCloneTypes.CalibrationPhase) -> void:
	_phase = phase
	phase_changed.emit(_phase)


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	_player = null


func _teardown_ui() -> void:
	visible = false
	if _ui_root != null and is_instance_valid(_ui_root):
		_ui_root.visible = false


func _refresh_ui() -> void:
	if _ui_root == null or not is_instance_valid(_ui_root):
		return
	var title: Label = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Title") as Label
	var body: Label = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Body") as Label
	var feedback: Label = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Feedback") as Label
	var track: Control = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Track") as Control
	var cont: Button = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Buttons/ContinueBtn") as Button
	var abort_btn: Button = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Buttons/AbortBtn") as Button
	if feedback != null:
		feedback.text = _last_feedback
	match _phase:
		FirstCloneTypes.CalibrationPhase.INTRO:
			if title != null:
				title.text = FirstCloneTypes.INTRO_TITLE
			if body != null:
				body.text = FirstCloneTypes.INTRO_BODY
			if track != null:
				track.visible = false
			if cont != null:
				cont.visible = true
				cont.text = "Начать"
			if abort_btn != null:
				abort_btn.visible = true
		FirstCloneTypes.CalibrationPhase.CALIBRATION:
			if title != null:
				title.text = FirstCloneTypes.pass_label(_pass_index)
			if body != null:
				body.text = "SPACE — подтвердить совпадение"
			if track != null:
				track.visible = true
			if cont != null:
				cont.visible = false
			if abort_btn != null:
				abort_btn.visible = true
			_refresh_track_ui()
		FirstCloneTypes.CalibrationPhase.PASS_FEEDBACK:
			if title != null:
				title.text = FirstCloneTypes.pass_label(_pass_index)
			if body != null:
				body.text = _last_feedback
			if track != null:
				track.visible = false
			if cont != null:
				cont.visible = false
			if abort_btn != null:
				abort_btn.visible = true
		FirstCloneTypes.CalibrationPhase.COMPLETE:
			if title != null:
				title.text = "КАЛИБРОВКА ЗАВЕРШЕНА"
			if body != null:
				body.text = FirstCloneTypes.FEEDBACK_COMPLETE
			if track != null:
				track.visible = false
			if cont != null:
				cont.visible = true
				cont.text = "Печать"
			if abort_btn != null:
				abort_btn.visible = false
		_:
			pass


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _refresh_track_ui() -> void:
	if _ui_root == null or not is_instance_valid(_ui_root):
		return
	var zone: ColorRect = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Track/Zone") as ColorRect
	var pointer: ColorRect = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Track/Pointer") as ColorRect
	var track_w: float = 600.0
	var origin_x: float = 20.0
	var center: float = FirstCloneTypes.pass_center(_pass_index)
	var width: float = FirstCloneTypes.pass_width(_pass_index)
	if zone != null:
		var zw: float = track_w * width
		zone.size = Vector2(zw, 16.0)
		zone.position = Vector2(origin_x + track_w * (center - width * 0.5), 16.0)
	if pointer != null:
		pointer.position = Vector2(origin_x + track_w * clampf(_pointer, 0.0, 1.0) - 3.0, 10.0)


func _on_continue_pressed() -> void:
	try_space()


func _on_abort_pressed() -> void:
	abort_calibration()
