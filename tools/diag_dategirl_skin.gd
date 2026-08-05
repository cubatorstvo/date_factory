extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn") as PackedScene
	print("PACKED=", packed)
	var girl := packed.instantiate()
	print("ROOT=", girl, " class=", girl.get_class(), " script=", girl.get_script())
	get_root().add_child(girl)
	await process_frame
	await process_frame
	var lines = []
	var stack = [[girl,0]]
	while stack.size() < 200 and not stack.is_empty():
		var item = stack.pop_back()
		var n = item[0]
		var d = item[1]
		if d < 6:
			lines.append("%s%s (%s)" % ["  ".repeat(d), n.name, n.get_class()])
		for i in range(n.get_child_count()-1, -1, -1):
			stack.append([n.get_child(i), d+1])
	print("TREE:\n", "\n".join(lines))
	var skels = girl.find_children("*", "Skeleton3D", true, false)
	print("SKEL_COUNT=", skels.size())
	for s in skels:
		print("SKEL ", girl.get_path_to(s), " bones=", s.get_bone_count(), " kids=", s.get_child_count())
	print("HAS_play=", girl.has_method("play_alias"))
	if girl.has_method("play_alias"):
		print("PLAY_SIT=", girl.call("play_alias", "sit_idle"))
		await process_frame
		await process_frame
		var sk: Skeleton3D = skels[0] if skels.size() else null
		if sk:
			print("SIT_LUA=", sk.get_bone_pose_rotation(sk.find_bone("LeftUpperArm")))
			print("SIT_LUL=", sk.get_bone_pose_rotation(sk.find_bone("LeftUpperLeg")))
			print("SIT_HIPS=", sk.get_bone_pose_position(sk.find_bone("Hips")))
	quit(0)
