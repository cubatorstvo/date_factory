extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn") as PackedScene
	var girl := packed.instantiate()
	root.add_child(girl)
	await process_frame
	var sk: Skeleton3D = null
	for n in girl.find_children("*", "Skeleton3D", true, false):
		sk = n as Skeleton3D
		break
	print("SKELETON=", sk)
	if sk:
		print("BONE_COUNT=", sk.get_bone_count())
		print("HAS_Hips=", sk.find_bone("Hips") >= 0)
		print("HAS_pelvis=", sk.find_bone("pelvis") >= 0)
		print("HAS_upperarm_l=", sk.find_bone("upperarm_l") >= 0)
		print("HAS_LeftUpperArm=", sk.find_bone("LeftUpperArm") >= 0)
		var sample: PackedStringArray = []
		for i in mini(12, sk.get_bone_count()):
			sample.append(sk.get_bone_name(i))
		print("BONES0=", ", ".join(sample))
	var lib := load("res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res") as AnimationLibrary
	print("LIB=", lib)
	if lib != null and lib.has_animation(&"idle"):
		var anim := lib.get_animation(&"idle")
		print("IDLE_TRACKS=", anim.get_track_count())
		var hit := 0
		var miss := 0
		var sample_bones: PackedStringArray = []
		for ti in anim.get_track_count():
			var p := String(anim.track_get_path(ti))
			if not p.contains(":"):
				continue
			var b := p.get_slice(":", 1)
			if sample_bones.size() < 10:
				sample_bones.append(b)
			if sk != null and sk.find_bone(b) >= 0:
				hit += 1
			else:
				miss += 1
		print("TRACK_BONES_SAMPLE=", ", ".join(sample_bones))
		print("HIT=", hit, " MISS=", miss)
		if girl.has_method("play_alias"):
			print("PLAY_IDLE=", girl.call("play_alias", "idle"))
			print("PLAY_SIT=", girl.call("play_alias", "sit_idle"))
	quit(0)
