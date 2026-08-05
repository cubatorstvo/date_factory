extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://assets/animation/universal_library/source/UAL1_Standard.glb") as PackedScene
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	var sk := _find_sk(root)
	print("BONES=", sk.get_bone_count() if sk else -1)
	if sk:
		var names := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		print("BONE_NAMES=", ",".join(names))
	var player := _find_ap(root)
	var a: Animation = player.get_animation("Sitting_Idle")
	var bones := {}
	for ti in a.get_track_count():
		var p := String(a.track_get_path(ti))
		var bn := p.get_slice(":", 1)
		bones[bn] = true
		print("TRACK ", ti, " ", p, " type=", a.track_get_type(ti))
	print("UNIQUE_BONES=", bones.keys())
	# Check import rest vs animated
	var hips := sk.find_bone("Hips")
	print("HIPS_REST=", sk.get_bone_rest(hips))
	player.play("Sitting_Idle")
	await process_frame
	await process_frame
	print("HIPS_POSE=", sk.get_bone_pose(hips))
	var lua := sk.find_bone("LeftUpperArm")
	print("LUA=", lua, " pose=", sk.get_bone_pose(lua) if lua >= 0 else "missing")
	quit(0)

func _find_sk(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var f := _find_sk(c)
		if f: return f
	return null

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var f := _find_ap(c)
		if f: return f
	return null
