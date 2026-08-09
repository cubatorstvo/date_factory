extends Node3D
## AP1 character review fixture (does not quit).
## Modes: male_base_clean, female_base_clean, male_5_variants, female_5_variants,
## mixed_10, side_views, walk_pose.

@export var review_mode: String = "mixed_10"

var _spawn: Node3D = null
var _actors: Array[CharacterActor] = []


func _ready() -> void:
	_spawn = get_node_or_null("SpawnRoot") as Node3D
	if _spawn == null:
		_spawn = Node3D.new()
		_spawn.name = "SpawnRoot"
		add_child(_spawn)
	var mode: String = review_mode.strip_edges().to_lower()
	if OS.get_environment("DF_CHARS_REVIEW_MODE") != "":
		mode = OS.get_environment("DF_CHARS_REVIEW_MODE").strip_edges().to_lower()
	match mode:
		"male_base_clean":
			_spawn_clean(&"appearance_male_base", Vector3.ZERO, false)
		"female_base_clean":
			_spawn_clean(&"appearance_female_base", Vector3.ZERO, false)
		"male_5_variants":
			_spawn_hair_line(true)
		"female_5_variants":
			_spawn_hair_line(false)
		"side_views":
			_spawn_side_views()
		"walk_pose":
			_spawn_walk_checkpoints()
		_:
			_spawn_mixed_10()
	_setup_camera_for_mode(mode)
	DfLog.info("MODULE_04_VISUAL", "mode=%s actors=%s" % [mode, _actors.size()])


func _spawn_clean(appearance_id: StringName, pos: Vector3, walk: bool) -> void:
	var actor: CharacterActor = CharacterFactory.create(appearance_id, appearance_id, _spawn)
	if actor == null:
		return
	actor.global_position = pos
	var ctrl: CharacterVariantController = _find_controller(actor)
	if ctrl != null:
		# Clean base: no modular clothing/accessories; keep body + optional bald/default hair off parts.
		ctrl.apply_variants(&"0" if String(appearance_id).contains("male") else &"4", &"brown", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
		_hide_modular_except_body(ctrl)
	var anim: CharacterAnimationController = actor.get_animation_controller()
	if anim != null:
		anim.play_loop(&"walk" if walk else &"idle")
	_actors.append(actor)


func _hide_modular_except_body(ctrl: CharacterVariantController) -> void:
	for slot_name in ["HairRoot", "TopRoot", "BottomRoot", "ShoesRoot", "HeadAccessoryRoot", "NeckAccessoryRoot", "HandAccessoryRoot"]:
		var slot: Node = ctrl.get_node_or_null(slot_name)
		if slot == null:
			continue
		for child in slot.get_children():
			var n3: Node3D = child as Node3D
			if n3 != null:
				n3.visible = false


func _spawn_hair_line(is_male: bool) -> void:
	var base_id: StringName = &"appearance_male_base" if is_male else &"appearance_female_base"
	for i in 5:
		var actor: CharacterActor = CharacterFactory.create(base_id, StringName("%s_h%s" % [base_id, i]), _spawn)
		if actor == null:
			continue
		actor.global_position = Vector3(float(i) * 1.1 - 2.2, 0.0, 0.0)
		var ctrl: CharacterVariantController = _find_controller(actor)
		if ctrl != null:
			ctrl.apply_variants(
				StringName(str(i)),
				[&"black", &"brown", &"blond", &"red", &"unusual"][i],
				StringName(str(i % 4)),
				&"teal",
				StringName(str(i % 3)),
				&"navy",
				StringName(str(i % 2)),
				&"none",
				&"none",
				&"none"
			)
		var anim: CharacterAnimationController = actor.get_animation_controller()
		if anim != null:
			anim.play_loop(&"idle")
		_actors.append(actor)


func _spawn_mixed_10() -> void:
	var ids: PackedStringArray = PackedStringArray([
		"appearance_male_base",
		"appearance_female_base",
		"appearance_male_city_thermos",
		"appearance_female_neighbor",
		"appearance_male_gym_mirror",
		"appearance_female_cafe_laptop",
		"appearance_male_first_clone",
		"appearance_female_city_umbrella",
		"appearance_male_public_watch",
		"appearance_female_actress",
	])
	for i in ids.size():
		var appearance_id: String = ids[i]
		var actor: CharacterActor = CharacterFactory.create(
			StringName(appearance_id), StringName(appearance_id), _spawn
		)
		if actor == null:
			continue
		actor.global_position = Vector3(float(i) * 1.05 - 4.7, 0.0, 0.0)
		var anim: CharacterAnimationController = actor.get_animation_controller()
		if anim != null:
			anim.play_loop(&"idle")
		_actors.append(actor)


func _spawn_side_views() -> void:
	var male: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"side_male", _spawn)
	var female: CharacterActor = CharacterFactory.create(&"appearance_female_base", &"side_female", _spawn)
	if male != null:
		male.global_position = Vector3(-1.2, 0.0, 0.0)
		male.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		male.get_animation_controller().play_loop(&"idle")
		_actors.append(male)
	if female != null:
		female.global_position = Vector3(1.2, 0.0, 0.0)
		female.rotation_degrees = Vector3(0.0, -90.0, 0.0)
		female.get_animation_controller().play_loop(&"idle")
		_actors.append(female)


func _spawn_walk_checkpoints() -> void:
	var male: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"walk_male", _spawn)
	var female: CharacterActor = CharacterFactory.create(&"appearance_female_base", &"walk_female", _spawn)
	if male != null:
		male.global_position = Vector3(-1.2, 0.0, 0.0)
		male.get_animation_controller().play_loop(&"walk")
		_actors.append(male)
	if female != null:
		female.global_position = Vector3(1.2, 0.0, 0.0)
		female.get_animation_controller().play_loop(&"walk")
		_actors.append(female)


func _setup_camera_for_mode(mode: String) -> void:
	var cam: Camera3D = get_node_or_null("Camera") as Camera3D
	if cam == null:
		return
	match mode:
		"male_5_variants", "female_5_variants":
			cam.global_position = Vector3(0.0, 1.55, 5.8)
			cam.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)
		"mixed_10":
			cam.global_position = Vector3(0.0, 1.6, 8.5)
			cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		"side_views":
			cam.global_position = Vector3(0.0, 1.5, 4.0)
			cam.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)
		_:
			cam.global_position = Vector3(0.0, 1.6, 4.2)
			cam.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)
	cam.current = true


func _find_controller(actor: CharacterActor) -> CharacterVariantController:
	if actor == null:
		return null
	var visual_root: Node = actor.get_node_or_null("VisualRoot")
	if visual_root == null:
		return null
	var queue: Array[Node] = [visual_root]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		var typed: CharacterVariantController = node as CharacterVariantController
		if typed != null:
			return typed
		for child in node.get_children():
			queue.append(child)
	return null
