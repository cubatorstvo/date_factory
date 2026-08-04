extends SceneTree
## Verify humanoid-normalized UAL and women imports before library extraction.


const UAL_PATH := "res://assets/animation/universal_library/source/UAL1_Standard.glb"
const CASUAL_PATH := "res://assets/characters/women_modular/meshes/individuals/Casual.gltf"
const FORMAL_PATH := "res://assets/characters/women_modular/meshes/individuals/Formal.gltf"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var ok := true
	for path in [UAL_PATH, CASUAL_PATH, FORMAL_PATH]:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Load failed: " + path)
			ok = false
			continue
		var root := packed.instantiate()
		var skeleton := _find_skeleton(root)
		var player := _find_animation_player(root)
		if skeleton == null or player == null:
			push_error("Skeleton/AnimationPlayer missing: " + path)
			ok = false
			root.free()
			continue
		var bones: PackedStringArray = []
		for i in skeleton.get_bone_count():
			bones.append(String(skeleton.get_bone_name(i)))
		print("RETARGET_SCENE path=", path, " bones=", skeleton.get_bone_count(), " profile_hips=", bones.has("Hips"), " profile_spine=", bones.has("Spine"))
		var clip_name := "Sitting_Enter" if path == UAL_PATH else "Walk"
		if not player.has_animation(clip_name):
			push_error("Missing clip %s in %s" % [clip_name, path])
			ok = false
		else:
			var animation := player.get_animation(clip_name)
			var paths: PackedStringArray = []
			for track_index in mini(animation.get_track_count(), 8):
				paths.append(String(animation.track_get_path(track_index)))
			print("RETARGET_TRACKS path=", path, " clip=", clip_name, " tracks=", animation.get_track_count(), " sample=", paths)
		root.free()
	var women_library := load("res://assets/animation/universal_library/libraries/DF_Women_Aliases.res") as AnimationLibrary
	print("WOMEN_LIBRARY_ALIASES=", women_library.get_animation_list() if women_library != null else [])
	if women_library != null:
		_report_seated_track_motion(women_library.get_animation(&"sit_enter"))
	for prefab_path in [
		"res://assets/characters/women_modular/prefabs/Girl_Casual.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Formal.tscn",
	]:
		ok = await _verify_seated_prefab(prefab_path) and ok
	print("RETARGET_IMPORT_VERIFY=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _report_seated_track_motion(animation: Animation) -> void:
	for track_index in animation.get_track_count():
		var path := String(animation.track_get_path(track_index))
		if not path.ends_with(":LeftUpperLeg") or animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var first := animation.rotation_track_interpolate(track_index, 0.0)
		var last := animation.rotation_track_interpolate(track_index, animation.length)
		print("SEATED_TRACK path=", path, " length=", animation.length, " rotation_delta=", first.angle_to(last))


func _verify_seated_prefab(prefab_path: String) -> bool:
	var packed := load(prefab_path) as PackedScene
	if packed == null:
		push_error("Prefab load failed: " + prefab_path)
		return false
	var character := packed.instantiate()
	get_root().add_child(character)
	await process_frame
	await process_frame
	var controller_aliases: PackedStringArray = character.call("list_aliases") if character.has_method("list_aliases") else PackedStringArray()
	print("PREFAB_CONTROLLER_ALIASES path=", prefab_path, " aliases=", controller_aliases)
	var skeleton := _find_skeleton(character)
	var player := _find_alias_player(character, &"df_aliases/sit_enter")
	if skeleton == null or player == null:
		push_error("Prefab skeleton/player missing: " + prefab_path)
		character.queue_free()
		return false
	var animation_root := player.get_node_or_null(player.root_node)
	var expected_target := animation_root.get_node_or_null("CharacterArmature/Skeleton3D") if animation_root != null else null
	print("SEATED_PLAYER path=", character.get_path_to(player), " root_node=", player.root_node, " root=", character.get_path_to(animation_root) if animation_root != null else "missing", " expected_target=", expected_target != null)
	var required := [&"sit_enter", &"sit_idle", &"seated_gesture", &"sit_exit"]
	for alias: StringName in required:
		if not character.has_method("has_alias") or not bool(character.call("has_alias", String(alias))):
			push_error("Missing seated alias %s: %s" % [alias, prefab_path])
			character.queue_free()
			return false
	var hips_index := skeleton.find_bone("Hips")
	var left_leg_index := skeleton.find_bone("LeftUpperLeg")
	var standing_hips := skeleton.get_bone_pose_position(hips_index)
	var standing_leg := skeleton.get_bone_pose_rotation(left_leg_index)
	var sit_length := float(character.call("get_alias_length", "sit_enter"))
	character.call("play_alias", "sit_enter")
	await create_timer(maxf(sit_length + 0.05, 0.1)).timeout
	var seated_hips := skeleton.get_bone_pose_position(hips_index)
	var seated_leg := skeleton.get_bone_pose_rotation(left_leg_index)
	var hips_delta := standing_hips.distance_to(seated_hips)
	var leg_delta := standing_leg.angle_to(seated_leg)
	var pose_changed := hips_delta > 0.05 or leg_delta > 0.35
	print("SEATED_PREFAB path=", prefab_path, " skeleton_path=", character.get_path_to(skeleton), " current=", character.call("get_current_alias"), " hips_delta=", hips_delta, " leg_delta=", leg_delta, " changed=", pose_changed)
	character.queue_free()
	await process_frame
	return pose_changed


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_alias_player(node: Node, animation_name: StringName) -> AnimationPlayer:
	if node is AnimationPlayer and (node as AnimationPlayer).has_animation(animation_name):
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_alias_player(child, animation_name)
		if found != null:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
