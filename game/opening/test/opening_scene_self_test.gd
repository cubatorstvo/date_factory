extends Node
## Focused accelerated proof for the standalone pre-prologue opening.

var _failed: int = 0
var _passed: int = 0
var _completed_count: int = 0


func _ready() -> void:
	await get_tree().process_frame
	await _run_opening_contract()
	await _finish()


func _run_opening_contract() -> void:
	var packed: PackedScene = load("res://game/opening/opening_scene.tscn") as PackedScene
	_ok(packed != null, "opening scene loads")
	if packed == null:
		return
	var opening: OpeningScene = packed.instantiate() as OpeningScene
	_ok(opening != null, "opening scene has OpeningScene controller")
	if opening == null:
		return
	opening.timing_scale = 0.001
	opening.auto_start = true
	opening.completed.connect(_on_opening_completed)
	add_child(opening)
	await get_tree().process_frame

	_ok(opening.has_node("ApartmentSet"), "production apartment set reused")
	_ok(opening.has_node("OpeningPlayer"), "existing FPS Player reused")
	_ok(opening.has_node("Actors/Neighbor"), "Neighbor actor present")
	_ok(opening.has_node("OpeningBed/Collision"), "bed interaction volume present")
	_ok(not opening.is_player_control_enabled(), "movement locked during seated cinematic")
	_ok(opening.is_cinematic_look_enabled(), "free-look enabled while seated")
	var skip_hint: Label = opening.get_node("UI/Subtitles/Margin/VBox/SkipHint") as Label
	_ok(skip_hint != null and skip_hint.text == "Любая кнопка — дальше", "dialogue skip hint present")
	var card_prop: Node3D = opening.get_node("Props/HeartCard") as Node3D
	_ok(card_prop != null and card_prop.visible, "same physical card begins on table")
	var camera: Camera3D = opening.get_node("CinematicCamera") as Camera3D
	var rotation_before: Vector3 = camera.rotation
	var look_event: InputEventMouseMotion = InputEventMouseMotion.new()
	look_event.relative = Vector2(18.0, -9.0)
	opening._input(look_event)
	_ok(camera.rotation != rotation_before, "mouse motion rotates seated camera")
	var dialogue_active: bool = await _wait_for_dialogue(opening, 2000)
	_ok(dialogue_active, "dialogue becomes skippable")
	if dialogue_active:
		var skip_event: InputEventMouseButton = InputEventMouseButton.new()
		skip_event.button_index = MOUSE_BUTTON_LEFT
		skip_event.pressed = true
		opening._input(skip_event)
		_ok(bool(opening.get("_line_skip_requested")), "mouse button requests line skip")
	_ok(OpeningScene.CARD_COPY == "ПОКОРЁННЫХ СЕРДЕЦ: ____", "card copy has empty field")
	_ok(not OpeningScene.CARD_COPY.contains("0"), "card never displays numeric zero")
	_ok(OpeningScene.DIALOGUE_COPY.size() == 12, "all authored dialogue beats present")
	_ok(not _dialogue_contains_forbidden_copy(), "no internal-monologue or evening-decision copy")

	var reached_stand_prompt: bool = await _wait_for_stand_prompt(opening, 5000)
	_ok(reached_stand_prompt, "departure exposes E stand prompt")
	if not reached_stand_prompt:
		_release_runtime_resources(opening)
		opening.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		return
	_ok(not opening.is_player_control_enabled(), "movement remains locked until player stands")
	_ok(opening.is_card_in_hand(), "physical table card is held while seated")
	_ok(card_prop.get_parent() == opening.get_node("Props"), "held seated card is not camera-parented")
	var stand_prompt: Control = opening.get_node("UI/StandPrompt") as Control
	_ok(stand_prompt.visible, "E stand prompt is visible during departure")
	opening.request_stand()
	var reached_interactive: bool = await _wait_for_phase(
		opening,
		OpeningScene.Phase.INTERACTIVE,
		2000
	)
	_ok(reached_interactive, "E stand request reaches gameplay handoff")
	_ok(opening.is_player_control_enabled(), "FPS movement restored when player stands")
	_ok(opening.get_objective_text() == OpeningScene.SLEEP_OBJECTIVE, "sleep objective exact")
	_ok(card_prop.visible and card_prop.get_parent() == opening.get_node("OpeningPlayer"), "same physical card remains carried by player")
	var bed: OpeningBedInteractable = opening.get_node("OpeningBed") as OpeningBedInteractable
	_ok(bed != null and bed.interaction_enabled, "bed enabled only after handoff")

	var gs: Node = get_node_or_null("/root/GameState")
	var stage_before: int = int(gs.call("get_stage")) if gs != null else -1
	bed.interact(opening.get_node("OpeningPlayer"))
	var reached_finished: bool = await _wait_for_phase(opening, OpeningScene.Phase.FINISHED, 2000)
	_ok(reached_finished, "bed fade completes")
	_ok(_completed_count == 1, "opening completion emitted exactly once")
	bed.interact(opening.get_node("OpeningPlayer"))
	await get_tree().process_frame
	_ok(_completed_count == 1, "repeated bed interaction cannot duplicate completion")
	var stage_after: int = int(gs.call("get_stage")) if gs != null else -1
	_ok(stage_after == stage_before, "opening itself does not mutate Story/GameState")
	_release_runtime_resources(opening)
	opening.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _release_runtime_resources(opening: OpeningScene) -> void:
	for node: Node in opening.find_children("*", "AudioStreamPlayer", true, false):
		var audio: AudioStreamPlayer = node as AudioStreamPlayer
		if audio != null:
			audio.stop()
			audio.stream = null
	for node: Node in opening.find_children("*", "AudioStreamPlayer3D", true, false):
		var audio_3d: AudioStreamPlayer3D = node as AudioStreamPlayer3D
		if audio_3d != null:
			audio_3d.stop()
			audio_3d.stream = null
	for cup_path: NodePath in [NodePath("Props/HeroCup"), NodePath("Props/NeighborCup")]:
		var cup: Node = opening.get_node_or_null(cup_path)
		if is_instance_valid(cup):
			cup.free()


func _wait_for_dialogue(opening: OpeningScene, timeout_ms: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if bool(opening.get("_line_active")):
			return true
		await get_tree().process_frame
	return false


func _wait_for_stand_prompt(opening: OpeningScene, timeout_ms: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if opening.is_waiting_for_stand():
			return true
		await get_tree().process_frame
	return false


func _wait_for_phase(opening: OpeningScene, target: OpeningScene.Phase, timeout_ms: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if opening != null and is_instance_valid(opening) and opening.get_phase() == target:
			return true
		await get_tree().process_frame
	return false


func _dialogue_contains_forbidden_copy() -> bool:
	for line: String in OpeningScene.DIALOGUE_COPY:
		var lower: String = line.to_lower()
		if lower.contains("я думаю") or lower.contains("я решил") or lower.contains("сегодня я"):
			return true
	return false


func _on_opening_completed() -> void:
	_completed_count += 1


func _ok(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("OPENING_SCENE_SELF_TEST_PASSED passed=%d" % _passed)
	else:
		print("OPENING_SCENE_SELF_TEST_FAILED failed=%d passed=%d" % [_failed, _passed])
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(_failed)
