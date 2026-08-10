class_name MediaPhotoSession
extends CanvasLayer
## Bespoke 3-shot editorial photo session (MODULE 15).
## Modal UI built in code. Abort commits nothing.

const ACTION_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"

signal session_finished()
signal session_aborted()
signal phase_changed(phase: MediaTypes.SessionPhase)

var _phase: MediaTypes.SessionPhase = MediaTypes.SessionPhase.INTRO
var _player: Node = null
var _transient_poses: Dictionary = {}
var _last_feedback: String = ""
@onready var _ui_root: Control = %Root
@onready var _continue_button: Button = $Root/Panel/MarginContainer/VBox/Buttons/ContinueBtn
@onready var _abort_button: Button = $Root/Panel/MarginContainer/VBox/Buttons/AbortBtn
var _started: bool = false
var _finished: bool = false
var _committed: bool = false


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(_ui_root)
	_continue_button.pressed.connect(_on_continue_pressed)
	_abort_button.pressed.connect(_on_abort_pressed)
	visible = false


func is_finished() -> bool:
	return _finished


func get_phase() -> MediaTypes.SessionPhase:
	return _phase


func get_transient_poses() -> Dictionary:
	var out: Dictionary = {}
	for key in _transient_poses.keys():
		out[key] = _transient_poses[key]
	return out


func get_last_feedback() -> String:
	return _last_feedback


func start(player: Node = null) -> bool:
	if _started:
		return false
	var media: Node = get_node_or_null("/root/Media")
	if media == null or not bool(media.call("is_photo_session_available")):
		return false
	_started = true
	_finished = false
	_committed = false
	_player = player
	_transient_poses.clear()
	_last_feedback = ""
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	_set_phase(MediaTypes.SessionPhase.INTRO)
	_ui_root.visible = true
	visible = true
	_refresh_ui()
	return true


## Advance INTRO → SHOT_1, or RESULT → commit FINISHED.
func continue_session() -> bool:
	if _finished:
		return false
	match _phase:
		MediaTypes.SessionPhase.INTRO:
			_set_phase(MediaTypes.SessionPhase.SHOT_1)
			_refresh_ui()
			return true
		MediaTypes.SessionPhase.RESULT:
			return _commit_and_finish()
		_:
			return false


func select_pose(pose_id: StringName) -> bool:
	if _finished:
		return false
	var shot_id: StringName = _current_shot_id()
	if String(shot_id) == "":
		return false
	var poses: Array[StringName] = MediaContent.poses_for_shot(shot_id)
	if not poses.has(pose_id):
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var appearance: int = int(gs.call("get_appearance"))
	if appearance < MediaContent.pose_required_appearance(pose_id):
		return false
	_transient_poses[shot_id] = pose_id
	_audio_play_sfx(AudioIds.MEDIA_POSE_CONFIRM)
	_audio_play_sfx(AudioIds.CAMERA_SHUTTER)
	var tier: MediaTypes.PoseTier = MediaContent.pose_tier(pose_id)
	_last_feedback = str(MediaContent.EDITOR_FEEDBACK.get(tier, ""))
	_play_shutter_presentation()
	_advance_after_shot()
	_refresh_ui()
	return true


func abort_session() -> void:
	if _finished:
		return
	_finished = true
	_transient_poses.clear()
	_teardown_ui()
	_restore_player()
	session_aborted.emit()
	queue_free()


func is_pose_available(pose_id: StringName) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var appearance: int = int(gs.call("get_appearance"))
	return appearance >= MediaContent.pose_required_appearance(pose_id)


func get_current_shot_pose_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shot_id: StringName = _current_shot_id()
	if String(shot_id) == "":
		return out
	for pose_id in MediaContent.poses_for_shot(shot_id):
		var req: int = MediaContent.pose_required_appearance(pose_id)
		var entry: Dictionary = {
			"pose_id": pose_id,
			"label": MediaContent.pose_label(pose_id),
			"required_appearance": req,
			"attention": MediaContent.pose_attention(pose_id),
			"available": is_pose_available(pose_id),
			"tier": MediaContent.pose_tier(pose_id),
		}
		out.append(entry)
	return out


func _current_shot_id() -> StringName:
	match _phase:
		MediaTypes.SessionPhase.SHOT_1:
			return MediaContent.PHOTO_PROFILE
		MediaTypes.SessionPhase.SHOT_2:
			return MediaContent.PHOTO_CHAIR
		MediaTypes.SessionPhase.SHOT_3:
			return MediaContent.PHOTO_COVER
		_:
			return &""


func _advance_after_shot() -> void:
	match _phase:
		MediaTypes.SessionPhase.SHOT_1:
			_set_phase(MediaTypes.SessionPhase.SHOT_2)
		MediaTypes.SessionPhase.SHOT_2:
			_set_phase(MediaTypes.SessionPhase.SHOT_3)
		MediaTypes.SessionPhase.SHOT_3:
			_set_phase(MediaTypes.SessionPhase.RESULT)
		_:
			pass


func _commit_and_finish() -> bool:
	if _committed or _finished:
		return false
	if _transient_poses.size() != MediaContent.SHOT_IDS.size():
		return false
	var media: Node = get_node_or_null("/root/Media")
	if media == null or not media.has_method("complete_photo_session"):
		return false
	_committed = true
	var ok: bool = bool(media.call("complete_photo_session", _transient_poses))
	if ok:
		_audio_play_sfx(AudioIds.MEDIA_PUBLISH)
	if not ok:
		_committed = false
		return false
	_set_phase(MediaTypes.SessionPhase.FINISHED)
	_finished = true
	_teardown_ui()
	_restore_player()
	session_finished.emit()
	queue_free()
	return true


func _set_phase(phase: MediaTypes.SessionPhase) -> void:
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
	var body: Label = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Body") as Label
	var choices: VBoxContainer = _ui_root.get_node_or_null(
		"Panel/MarginContainer/VBox/ChoicesScroll/Choices"
	) as VBoxContainer
	var feedback: Label = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Feedback") as Label
	var cont: Button = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Buttons/ContinueBtn") as Button
	var abort_btn: Button = _ui_root.get_node_or_null("Panel/MarginContainer/VBox/Buttons/AbortBtn") as Button
	if choices != null:
		for child in choices.get_children():
			child.queue_free()
	match _phase:
		MediaTypes.SessionPhase.INTRO:
			if body != null:
				body.text = MediaContent.INTRO_TEXT
			if feedback != null:
				feedback.text = ""
			if cont != null:
				cont.visible = true
				cont.text = "Начать"
			if abort_btn != null:
				abort_btn.visible = true
		MediaTypes.SessionPhase.SHOT_1, MediaTypes.SessionPhase.SHOT_2, MediaTypes.SessionPhase.SHOT_3:
			var shot_id: StringName = _current_shot_id()
			if body != null:
				body.text = MediaContent.shot_setup(shot_id)
			if feedback != null:
				feedback.text = _last_feedback
			if cont != null:
				cont.visible = false
			if abort_btn != null:
				abort_btn.visible = true
			if choices != null:
				for entry in get_current_shot_pose_choices():
					var pose_id: StringName = entry["pose_id"] as StringName
					var available: bool = bool(entry["available"])
					var packed: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
					if packed == null:
						continue
					var btn: Button = packed.instantiate() as Button
					if btn == null:
						continue
					var label: String = str(entry["label"])
					var req_app: int = int(entry["required_appearance"])
					# Spec §86: Appearance gate visible; enable only when available.
					if available:
						btn.text = "%s [Внешность %d]" % [label, req_app]
						btn.pressed.connect(_on_pose_pressed.bind(pose_id))
					else:
						btn.text = "%s [Внешность %d]" % [label, req_app]
						btn.disabled = true
					btn.custom_minimum_size = Vector2(0, 36)
					choices.add_child(btn)
		MediaTypes.SessionPhase.RESULT:
			if body != null:
				body.text = "Три кадра готовы. Редактор уносит материал в номер."
			if feedback != null:
				feedback.text = _last_feedback
			if cont != null:
				cont.visible = true
				cont.text = "Готово"
			if abort_btn != null:
				abort_btn.visible = false
		_:
			pass


func _on_continue_pressed() -> void:
	continue_session()


func _on_abort_pressed() -> void:
	abort_session()


func _on_pose_pressed(pose_id: StringName) -> void:
	if not is_pose_available(pose_id):
		_audio_play_ui(AudioIds.UI_DENIED)
		return
	select_pose(pose_id)


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _play_shutter_presentation() -> void:
	ScreenFlash.play_media_shutter(self)
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", AudioIds.CAMERA_SHUTTER)
