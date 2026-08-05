extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn") as PackedScene
	var girl := packed.instantiate()
	root.add_child(girl)
	await process_frame
	await process_frame
	var sk: Skeleton3D = null
	for n in girl.find_children("*", "Skeleton3D", true, false):
		sk = n
		break
	var hips := sk.find_bone("Hips")
	var left_up := sk.find_bone("LeftUpperArm")
	var rest_hips := sk.get_bone_pose_rotation(hips)
	var rest_arm := sk.get_bone_pose_rotation(left_up)
	print("REST hips=", rest_hips, " arm=", rest_arm)
	print("PLAY=", girl.call("play_alias", "sit_idle"))
	for i in 10:
		await process_frame
	var after_hips := sk.get_bone_pose_rotation(hips)
	var after_arm := sk.get_bone_pose_rotation(left_up)
	print("AFTER hips=", after_hips, " arm=", after_arm)
	print("CHANGED_HIPS=", not rest_hips.is_equal_approx(after_hips))
	print("CHANGED_ARM=", not rest_arm.is_equal_approx(after_arm))
	var lib := load("res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res") as AnimationLibrary
	for a in ["idle", "walk", "sit_enter", "sit_idle", "seated_gesture"]:
		if lib.has_animation(StringName(a)):
			var anim: Animation = lib.get_animation(StringName(a))
			print("ALIAS ", a, " tracks=", anim.get_track_count(), " len=", anim.length)
	quit(0)
