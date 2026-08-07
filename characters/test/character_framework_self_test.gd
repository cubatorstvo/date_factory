extends Node
## Reproducible MODULE 04 Character Framework tests.
## Run via characters/test/character_framework_test.tscn (headless-friendly).

var _failed: int = 0
var _passed: int = 0
var _spawn_root: Node3D = null
var _gesture_finished_alias: StringName = &""


func _ready() -> void:
	await get_tree().process_frame
	_spawn_root = get_node_or_null("SpawnRoot") as Node3D
	if _spawn_root == null:
		_spawn_root = Node3D.new()
		_spawn_root.name = "SpawnRoot"
		add_child(_spawn_root)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_04_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_04_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_04_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_04_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_04_TEST] FAIL: %s" % label)
		print("MODULE_04_TEST FAIL: %s" % label)


func _run_all() -> void:
	await _test_male_female_instantiate_idle()
	await _test_mandatory_aliases()
	await _test_play_once_gesture()
	_test_missing_alias()
	await _test_apply_appearance_replace()
	_test_missing_appearance_fails_safely()
	_test_visibility_toggle()


func _test_male_female_instantiate_idle() -> void:
	var male: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"test_male", _spawn_root)
	var female: CharacterActor = CharacterFactory.create(&"appearance_female_base", &"test_female", _spawn_root)
	_ok(male != null, "male instantiate")
	_ok(female != null, "female instantiate")
	if male != null:
		male.global_position = Vector3(-1.2, 0.0, 0.0)
		_ok(male.get_appearance_profile_id() == &"appearance_male_base", "male appearance id")
		var male_anim: CharacterAnimationController = male.get_animation_controller()
		_ok(male_anim != null, "male anim controller")
		if male_anim != null:
			_ok(male_anim.play_loop(&"idle"), "male idle play")
			_ok(male_anim.get_current_animation_alias() == &"idle", "male current idle")
	if female != null:
		female.global_position = Vector3(1.2, 0.0, 0.0)
		_ok(female.get_appearance_profile_id() == &"appearance_female_base", "female appearance id")
		var female_anim: CharacterAnimationController = female.get_animation_controller()
		_ok(female_anim != null, "female anim controller")
		if female_anim != null:
			_ok(female_anim.play_loop(&"idle"), "female idle play")
			_ok(female_anim.get_current_animation_alias() == &"idle", "female current idle")
	await get_tree().process_frame
	await get_tree().process_frame


func _test_mandatory_aliases() -> void:
	var male: CharacterActor = _find_actor(&"test_male")
	var female: CharacterActor = _find_actor(&"test_female")
	_ok(male != null and female != null, "actors present for alias checks")
	if male == null or female == null:
		return
	for alias in [&"idle", &"walk", &"gesture", &"react"]:
		_ok(male.get_animation_controller().has_animation(alias), "male has %s" % String(alias))
		_ok(female.get_animation_controller().has_animation(alias), "female has %s" % String(alias))


func _test_play_once_gesture() -> void:
	var male: CharacterActor = _find_actor(&"test_male")
	_ok(male != null, "male for gesture")
	if male == null:
		return
	var anim: CharacterAnimationController = male.get_animation_controller()
	_gesture_finished_alias = &""
	var on_finished := func(alias: StringName) -> void:
		_gesture_finished_alias = alias
	anim.animation_finished.connect(on_finished)
	_ok(anim.play_once(&"gesture"), "play_once gesture")
	var frames: int = 0
	while _gesture_finished_alias == &"" and frames < 600:
		await get_tree().process_frame
		frames += 1
	_ok(_gesture_finished_alias == &"gesture", "gesture animation_finished")
	# Allow idle return
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(anim.get_current_animation_alias() == &"idle", "return to idle after gesture")
	if anim.animation_finished.is_connected(on_finished):
		anim.animation_finished.disconnect(on_finished)


func _test_missing_alias() -> void:
	var male: CharacterActor = _find_actor(&"test_male")
	_ok(male != null, "male for missing alias")
	if male == null:
		return
	var anim: CharacterAnimationController = male.get_animation_controller()
	_ok(not anim.has_animation(&"no_such_alias_xyz"), "missing alias has_animation false")
	_ok(not anim.play_loop(&"no_such_alias_xyz"), "missing alias play_loop false")
	_ok(not anim.play_once(&"no_such_alias_xyz"), "missing alias play_once false")


func _test_apply_appearance_replace() -> void:
	var male: CharacterActor = _find_actor(&"test_male")
	_ok(male != null, "male for replace")
	if male == null:
		return
	var ok_replace: bool = male.apply_appearance(&"appearance_female_base")
	_ok(ok_replace, "apply_appearance replace to female")
	_ok(male.get_appearance_profile_id() == &"appearance_female_base", "replaced appearance id")
	var ok_back: bool = male.apply_appearance(&"appearance_male_base")
	_ok(ok_back, "apply_appearance replace back to male")
	_ok(male.get_appearance_profile_id() == &"appearance_male_base", "restored appearance id")
	await get_tree().process_frame


func _test_missing_appearance_fails_safely() -> void:
	var male: CharacterActor = _find_actor(&"test_male")
	_ok(male != null, "male for missing appearance")
	if male == null:
		return
	var before: StringName = male.get_appearance_profile_id()
	var ok: bool = male.apply_appearance(&"appearance_does_not_exist")
	_ok(not ok, "missing appearance returns false")
	_ok(male.get_appearance_profile_id() == before, "appearance unchanged after missing")


func _test_visibility_toggle() -> void:
	var female: CharacterActor = _find_actor(&"test_female")
	_ok(female != null, "female for visibility")
	if female == null:
		return
	female.set_character_visible(false)
	var visual: Node3D = female.get_node("VisualRoot") as Node3D
	var collision: CollisionShape3D = female.get_node("Collision") as CollisionShape3D
	_ok(visual != null and not visual.visible, "visual hidden")
	_ok(collision != null and collision.disabled, "collision disabled when hidden")
	female.set_character_visible(true)
	_ok(visual.visible, "visual shown")
	_ok(not collision.disabled, "collision enabled when shown")


func _find_actor(content_id: StringName) -> CharacterActor:
	for child in _spawn_root.get_children():
		var actor: CharacterActor = child as CharacterActor
		if actor != null and actor.content_id == content_id:
			return actor
	return null
