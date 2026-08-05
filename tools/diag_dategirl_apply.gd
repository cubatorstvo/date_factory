extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn") as PackedScene
	var girl := packed.instantiate()
	get_root().add_child(girl)
	await process_frame
	await process_frame
	await process_frame
	print("NAME=", girl.name, " SCRIPT=", girl.get_script())
	print("HAS_play=", girl.has_method("play_alias"))
	var sk := _find_sk(girl)
	print("SK=", sk, " bones=", sk.get_bone_count() if sk else -1)
	var lib = girl.get("alias_library")
	print("LIB=", lib)
	if lib:
		print("HAS_sit_idle=", lib.has_animation(&"sit_idle"))
		var anim: Animation = lib.get_animation(&"sit_idle")
		print("sit_idle tracks=", anim.get_track_count(), " len=", anim.length)
		# Sample first few rotation values
		for ti in anim.get_track_count():
			var p := String(anim.track_get_path(ti))
			var bn := p.get_slice(":", 1)
			if anim.track_get_type(ti) == Animation.TYPE_ROTATION_3D:
				var q: Quaternion = anim.rotation_track_interpolate(ti, 0.0)
				print("ROT ", bn, " = ", q)
			elif anim.track_get_type(ti) == Animation.TYPE_POSITION_3D:
				var v: Vector3 = anim.position_track_interpolate(ti, 0.0)
				print("POS ", bn, " = ", v)
	if girl.has_method("play_alias"):
		var ok = girl.call("play_alias", "sit_idle")
		print("play_alias=", ok)
		await process_frame
		await process_frame
		for bn in ["Hips", "LeftUpperArm", "LeftLowerArm", "LeftUpperLeg", "Spine", "Chest"]:
			var bi := sk.find_bone(bn)
			print("AFTER ", bn, " idx=", bi, " pose=", sk.get_bone_pose(bi) if bi >= 0 else "n/a", " rest=", sk.get_bone_rest(bi) if bi >= 0 else "n/a")
	# Check mesh skin
	var meshes := girl.find_children("*", "MeshInstance3D", true, false)
	print("MESH_COUNT=", meshes.size())
	for m in meshes:
		var mi := m as MeshInstance3D
		print("MESH ", mi.name, " skel=", mi.skeleton, " visible=", mi.visible, " mesh=", mi.mesh)
	quit(0)

func _find_sk(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var f := _find_sk(c)
		if f: return f
	return null
