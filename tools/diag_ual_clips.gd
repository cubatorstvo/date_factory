extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://assets/animation/universal_library/source/UAL1_Standard.glb") as PackedScene
	var root := packed.instantiate()
	root_add(root)
	await process_frame
	var player := _find_ap(root)
	print("AP=", player)
	if player:
		print("LIST=", player.get_animation_list())
		for name in ["Idle", "Sitting_Idle", "Walk", "Idle_Loop", "Sitting_Idle_Loop"]:
			if player.has_animation(name):
				var a: Animation = player.get_animation(name)
				print("CLIP ", name, " tracks=", a.get_track_count(), " len=", a.length)
				for ti in mini(5, a.get_track_count()):
					print("  path=", a.track_get_path(ti), " type=", a.track_get_type(ti))
			else:
				# try with library prefixes
				for lib in player.get_animation_library_list():
					var key := "%s/%s" % [lib, name]
					if player.has_animation(key):
						var a2: Animation = player.get_animation(key)
						print("CLIP ", key, " tracks=", a2.get_track_count(), " len=", a2.length)
						for ti2 in mini(5, a2.get_track_count()):
							print("  path=", a2.track_get_path(ti2), " type=", a2.track_get_type(ti2))
	quit(0)

func root_add(n: Node) -> void:
	root.add_child(n)

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var f := _find_ap(c)
		if f: return f
	return null
