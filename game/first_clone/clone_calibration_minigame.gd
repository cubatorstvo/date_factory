class_name CloneCalibrationMinigame
extends CanvasLayer
## One-time 3-pass clone calibration (MODULE 17).
## Deterministic track; miss retries same pass; abort creates no clone.

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const BODY_FONT_SIZE: int = 16

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
var _ui_root: Control = null
var _last_feedback: String = ""
var _feedback_timer: float = 0.0
var _awaiting_feedback_advance: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_build_ui()
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
		_ui_root.queue_free()
	_ui_root = null


func _build_ui() -> void:
	_teardown_ui()
	visible = true
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_theme(root)
	add_child(root)
	_ui_root = root
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.06, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-340, -230)
	panel.size = Vector2(680, 460)
	root.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var title: Label = Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	var body: Label = Label.new()
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(640, 90)
	body.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(body)
	var track: Control = Control.new()
	track.name = "Track"
	track.custom_minimum_size = Vector2(640, 48)
	vbox.add_child(track)
	var track_bg: ColorRect = ColorRect.new()
	track_bg.name = "TrackBg"
	track_bg.color = Color(0.15, 0.17, 0.2, 1.0)
	track_bg.position = Vector2(20, 16)
	track_bg.size = Vector2(600, 16)
	track.add_child(track_bg)
	var zone: ColorRect = ColorRect.new()
	zone.name = "Zone"
	zone.color = Color(0.25, 0.7, 0.4, 0.75)
	zone.size = Vector2(40, 16)
	zone.position = Vector2(20, 16)
	track.add_child(zone)
	var pointer: ColorRect = ColorRect.new()
	pointer.name = "Pointer"
	pointer.color = Color(0.95, 0.9, 0.35, 1.0)
	pointer.size = Vector2(6, 28)
	pointer.position = Vector2(20, 10)
	track.add_child(pointer)
	var feedback: Label = Label.new()
	feedback.name = "Feedback"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(feedback)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons)
	var cont: Button = Button.new()
	cont.name = "ContinueBtn"
	cont.text = "Начать"
	cont.custom_minimum_size = Vector2(0, 34)
	cont.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	cont.pressed.connect(_on_continue_pressed)
	buttons.add_child(cont)
	var abort_btn: Button = Button.new()
	abort_btn.name = "AbortBtn"
	abort_btn.text = "Отмена"
	abort_btn.custom_minimum_size = Vector2(0, 34)
	abort_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	abort_btn.pressed.connect(_on_abort_pressed)
	buttons.add_child(abort_btn)


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


func _apply_theme(root: Control) -> void:
	if root == null:
		return
	if ResourceLoader.exists(THEME_PATH):
		var theme_res: Resource = load(THEME_PATH)
		if theme_res is Theme:
			root.theme = theme_res as Theme
