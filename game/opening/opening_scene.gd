class_name OpeningScene
extends Node3D
## Standalone pre-prologue evening. Owns presentation only; TitleMenu commits New Game.

enum Phase {
	CINEMATIC,
	INTERACTIVE,
	FADING,
	FINISHED,
}

signal completed
signal phase_changed(phase: int)

const CARD_COPY: String = "ПОКОРЁННЫХ СЕРДЕЦ: ____"
const SLEEP_OBJECTIVE: String = "Уже поздно. Ложись спать."
const CINEMATIC_PITCH_LIMIT_DEGREES: float = 70.0
const DIALOGUE_COPY: Array[String] = [
	"Сколько стран ты посетил?",
	"Три.",
	"Скучно. Следующий.",
	"Самая бесполезная покупка?",
	"Второй тостер.",
	"Зачем тебе два?",
	"Первый был занят.",
	"Так… последний.",
	"Сколько сердец ты покорил?",
	"Ну что, уснул?",
	"Хотя уже реально поздно. Мне пора. Спокойной ночи.",
	"Спокойной.",
]

@export_range(0.001, 4.0, 0.001) var timing_scale: float = 1.0
@export var auto_start: bool = true

@onready var _apartment_set: Node3D = $ApartmentSet
@onready var _player: PlayerController = $OpeningPlayer
@onready var _cinematic_camera: Camera3D = $CinematicCamera
@onready var _neighbor: CharacterActor = $Actors/Neighbor
@onready var _neighbor_exit_a: Marker3D = $Staging/NeighborExitA
@onready var _neighbor_exit_b: Marker3D = $Staging/NeighborExitB
@onready var _card_hold_pose: Marker3D = $Staging/CardHoldPose
@onready var _card_carry_pose: Marker3D = $OpeningPlayer/CardCarryPose
@onready var _bed: OpeningBedInteractable = $OpeningBed
@onready var _card_prop: Node3D = $Props/HeartCard
@onready var _subtitle_panel: Control = $UI/Subtitles
@onready var _speaker_label: Label = $UI/Subtitles/Margin/VBox/Speaker
@onready var _dialogue_label: Label = $UI/Subtitles/Margin/VBox/Dialogue
@onready var _stand_prompt: Control = $UI/StandPrompt
@onready var _objective_panel: Control = $UI/ObjectivePanel
@onready var _objective_label: Label = $UI/ObjectivePanel/Margin/VBox/Objective
@onready var _crosshair: Control = $UI/Crosshair
@onready var _fade_rect: ColorRect = $UI/Fade

var _phase: Phase = Phase.CINEMATIC
var _completion_emitted: bool = false
var _line_active: bool = false
var _line_skip_requested: bool = false
var _cinematic_look_enabled: bool = true
var _cinematic_yaw: float = 0.0
var _cinematic_pitch: float = 0.0
var _awaiting_stand: bool = false
var _card_in_hand: bool = false


func _ready() -> void:
	add_to_group("opening_scene")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_isolate_apartment()
	_prepare_neighbor()
	_prepare_player()
	_prepare_ui()
	if not _bed.sleep_requested.is_connected(_on_sleep_requested):
		_bed.sleep_requested.connect(_on_sleep_requested)
	if auto_start:
		call_deferred("_run_sequence")


func _input(event: InputEvent) -> void:
	if _phase == Phase.FINISHED:
		return
	if _awaiting_stand and event.is_action_pressed("interact"):
		request_stand()
		get_viewport().set_input_as_handled()
		return
	if _line_active and _is_dialogue_skip_input(event):
		_line_skip_requested = true
		get_viewport().set_input_as_handled()
		return
	if (
		_phase == Phase.CINEMATIC
		and _cinematic_look_enabled
		and event is InputEventMouseMotion
	):
		_apply_cinematic_look(event as InputEventMouseMotion)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("phone"):
		get_viewport().set_input_as_handled()


func get_phase() -> Phase:
	return _phase


func get_dialogue_copy() -> Array[String]:
	return DIALOGUE_COPY.duplicate()


func get_objective_text() -> String:
	return _objective_label.text if _objective_label != null else ""


func is_player_control_enabled() -> bool:
	return _player != null and _player.get_control_mode() == PlayerController.ControlMode.GAMEPLAY


func is_waiting_for_stand() -> bool:
	return _awaiting_stand


func is_card_in_hand() -> bool:
	return _card_in_hand


func is_cinematic_look_enabled() -> bool:
	return _cinematic_look_enabled


func request_stand() -> void:
	if not _awaiting_stand or _phase != Phase.CINEMATIC:
		return
	_stand_up()


func _isolate_apartment() -> void:
	if _apartment_set == null:
		return
	_disable_apartment_areas(_apartment_set)
	for path in ["NpcSpawns", "PlayerSpawns", "StoryEventPoints"]:
		var node: Node = _apartment_set.get_node_or_null(path)
		if node != null:
			node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is Node3D:
				(node as Node3D).visible = false


func _disable_apartment_areas(node: Node) -> void:
	if node is Area3D:
		var area: Area3D = node as Area3D
		area.collision_layer = 0
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = false
		area.process_mode = Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		_disable_apartment_areas(child)


func _prepare_neighbor() -> void:
	if _neighbor == null:
		return
	_neighbor.apply_appearance(&"appearance_female_neighbor")
	_neighbor.collision_layer = 0
	_neighbor.collision_mask = 0
	var collision: CollisionShape3D = _neighbor.get_node_or_null("Collision") as CollisionShape3D
	if collision != null:
		collision.disabled = true
	var interaction: Area3D = _neighbor.get_node_or_null("InteractionTarget") as Area3D
	if interaction != null:
		interaction.collision_layer = 0
		interaction.monitorable = false
	_neighbor.face_point(_cinematic_camera.global_position)
	_neighbor.rotate_y(PI)
	var animation: CharacterAnimationController = _neighbor.get_animation_controller()
	if animation != null and not animation.play_loop(&"sit_idle"):
		animation.play_loop(&"idle")


func _prepare_player() -> void:
	if _player == null:
		return
	_player.enter_modal_ui()
	var player_camera: Camera3D = _player.get_camera()
	if player_camera != null:
		player_camera.current = false
	if _cinematic_camera != null:
		_cinematic_camera.current = true
		_cinematic_camera.look_at(_neighbor.global_position + Vector3(0.0, 1.15, 0.0), Vector3.UP)
		_cinematic_pitch = _cinematic_camera.rotation.x
		_cinematic_yaw = _cinematic_camera.rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _prepare_ui() -> void:
	_subtitle_panel.visible = false
	_stand_prompt.visible = false
	_objective_panel.visible = false
	_crosshair.visible = false
	_card_prop.visible = true
	_objective_label.text = ""
	_fade_rect.visible = true
	_fade_rect.color = Color(0.02, 0.015, 0.012, 1.0)
	_bed.interaction_enabled = false


func _run_sequence() -> void:
	_set_phase(Phase.CINEMATIC)
	await _fade_to(0.0, 1.5)
	await _wait(3.0)

	await _show_line("СОСЕДКА", DIALOGUE_COPY[0], 4.5, true)
	await _show_line("ГЕРОЙ", DIALOGUE_COPY[1], 2.8)
	await _show_line("СОСЕДКА", DIALOGUE_COPY[2], 3.2, true)
	await _wait(2.0)

	await _show_line("СОСЕДКА", DIALOGUE_COPY[3], 4.5, true)
	await _show_line("ГЕРОЙ", DIALOGUE_COPY[4], 3.2)
	await _show_line("СОСЕДКА", DIALOGUE_COPY[5], 3.6, true)
	await _show_line("ГЕРОЙ", DIALOGUE_COPY[6], 3.6)
	_hide_subtitles()
	await _wait(2.5)

	await _show_line("СОСЕДКА", DIALOGUE_COPY[7], 3.5, true)
	await _show_line("СОСЕДКА", "«%s»" % DIALOGUE_COPY[8], 4.8)
	_hide_subtitles()
	await _give_card()
	await _wait(8.0)
	await _wait(4.0)

	await _show_line("СОСЕДКА", DIALOGUE_COPY[9], 3.5, true)
	_hide_subtitles()
	await _wait(3.0)
	await _show_line("СОСЕДКА", DIALOGUE_COPY[10], 5.2)
	await _show_line("ГЕРОЙ", DIALOGUE_COPY[11], 2.8)
	_hide_subtitles()
	_awaiting_stand = true
	_stand_prompt.visible = true
	call_deferred("_animate_neighbor_departure")


func _show_line(speaker: String, copy: String, seconds: float, gesture: bool = false) -> void:
	_speaker_label.text = speaker
	_dialogue_label.text = copy
	_subtitle_panel.visible = true
	_line_active = true
	_line_skip_requested = false
	if gesture and _neighbor != null:
		var animation: CharacterAnimationController = _neighbor.get_animation_controller()
		if animation != null and not animation.play_loop(&"seated_gesture"):
			animation.play_semantic(&"gesture_short")
	await _wait_or_skip(seconds)
	_line_active = false
	_line_skip_requested = false
	if gesture and _neighbor != null:
		var animation: CharacterAnimationController = _neighbor.get_animation_controller()
		if animation != null:
			if not animation.play_loop(&"sit_idle"):
				animation.play_loop(&"idle")


func _hide_subtitles() -> void:
	_subtitle_panel.visible = false
	_speaker_label.text = ""
	_dialogue_label.text = ""


func _animate_neighbor_departure() -> void:
	if _neighbor == null:
		return
	var animation: CharacterAnimationController = _neighbor.get_animation_controller()
	if animation != null:
		animation.play_loop(&"walk")
	_neighbor.face_point(_neighbor_exit_a.global_position)
	_neighbor.rotate_y(PI)
	var first: Tween = create_tween()
	first.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	first.tween_property(
		_neighbor,
		"global_position",
		_neighbor_exit_a.global_position,
		_scaled_duration(3.0)
	)
	await first.finished
	_neighbor.face_point(_neighbor_exit_b.global_position)
	_neighbor.rotate_y(PI)
	var second: Tween = create_tween()
	second.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	second.tween_property(
		_neighbor,
		"global_position",
		_neighbor_exit_b.global_position,
		_scaled_duration(3.5)
	)
	await second.finished
	_neighbor.visible = false


func _stand_up() -> void:
	_awaiting_stand = false
	_stand_prompt.visible = false
	_cinematic_look_enabled = false
	if _cinematic_camera != null:
		_cinematic_camera.current = false
	var player_camera: Camera3D = _player.get_camera()
	if player_camera != null:
		player_camera.current = true
	if _card_in_hand and _card_carry_pose != null:
		var carry_transform: Transform3D = _card_carry_pose.transform
		_card_prop.reparent(_player, false)
		_card_prop.transform = carry_transform
	_player.enter_gameplay()
	_objective_label.text = SLEEP_OBJECTIVE
	_objective_panel.visible = true
	_crosshair.visible = true
	_bed.interaction_enabled = true
	_set_phase(Phase.INTERACTIVE)


func _give_card() -> void:
	if _card_prop == null or _card_hold_pose == null:
		return
	_cinematic_look_enabled = false
	var card_tween: Tween = create_tween()
	card_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	card_tween.tween_property(
		_card_prop,
		"global_transform",
		_card_hold_pose.global_transform,
		_scaled_duration(0.9)
	)
	await card_tween.finished
	_card_in_hand = true
	await _turn_head_to_card()
	_cinematic_look_enabled = true


func _turn_head_to_card() -> void:
	if _cinematic_camera == null or _card_prop == null:
		return
	var look_transform: Transform3D = _cinematic_camera.global_transform.looking_at(
		_card_prop.global_position,
		Vector3.UP
	)
	var target_rotation: Vector3 = look_transform.basis.get_euler()
	target_rotation.z = 0.0
	var look_tween: Tween = create_tween()
	look_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	look_tween.tween_property(
		_cinematic_camera,
		"rotation",
		target_rotation,
		_scaled_duration(0.65)
	)
	await look_tween.finished
	_cinematic_pitch = _cinematic_camera.rotation.x
	_cinematic_yaw = _cinematic_camera.rotation.y


func _apply_cinematic_look(motion: InputEventMouseMotion) -> void:
	var sensitivity: float = deg_to_rad(_player.get_mouse_sensitivity_degrees())
	var pitch_limit: float = deg_to_rad(CINEMATIC_PITCH_LIMIT_DEGREES)
	_cinematic_yaw -= motion.relative.x * sensitivity
	_cinematic_pitch = clampf(
		_cinematic_pitch - motion.relative.y * sensitivity,
		-pitch_limit,
		pitch_limit
	)
	_cinematic_camera.rotation = Vector3(_cinematic_pitch, _cinematic_yaw, 0.0)


func _is_dialogue_skip_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return key_event.pressed and not key_event.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


func _wait_or_skip(seconds: float) -> void:
	var duration_usec: int = int(_scaled_duration(seconds) * 1000000.0)
	var deadline_usec: int = Time.get_ticks_usec() + duration_usec
	while Time.get_ticks_usec() < deadline_usec and not _line_skip_requested:
		await get_tree().process_frame


func _on_sleep_requested() -> void:
	if _phase != Phase.INTERACTIVE or _completion_emitted:
		return
	_set_phase(Phase.FADING)
	_player.enter_modal_ui()
	_objective_panel.visible = false
	_crosshair.visible = false
	await _fade_to(1.0, 1.3)
	await _wait(0.5)
	_completion_emitted = true
	_set_phase(Phase.FINISHED)
	completed.emit()


func _fade_to(alpha: float, seconds: float) -> void:
	_fade_rect.visible = true
	var target: Color = _fade_rect.color
	target.a = clampf(alpha, 0.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "color", target, _scaled_duration(seconds))
	await tween.finished
	if alpha <= 0.0:
		_fade_rect.visible = false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(_scaled_duration(seconds), true, false, true).timeout


func _scaled_duration(seconds: float) -> float:
	return maxf(seconds * timing_scale, 0.001)


func _set_phase(next_phase: Phase) -> void:
	if _phase == next_phase:
		return
	_phase = next_phase
	phase_changed.emit(int(_phase))
