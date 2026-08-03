extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var paths := [
		"res://assets/characters/hero_base/prefabs/Hero.tscn",
		"res://assets/characters/hero_base/prefabs/Clone.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Casual.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Formal.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Worker.tscn",
		"res://assets/characters/women_modular/prefabs/Manager_Suit.tscn",
	]
	var root := Node3D.new()
	root.name = "ProbeRoot"
	get_root().add_child(root)
	for path in paths:
		var ps := load(path) as PackedScene
		if ps == null:
			print("FAIL load ", path)
			continue
		var n := ps.instantiate()
		root.add_child(n)
		await process_frame
		await process_frame
		var aliases_ok := 0
		for a in ["idle", "walk", "run", "sit", "stand", "gesture", "react"]:
			if n.has_method("has_alias") and bool(n.call("has_alias", a)):
				aliases_ok += 1
		var played := false
		if n.has_method("play_alias"):
			played = bool(n.call("play_alias", "walk"))
		var ap := _find_ap(n)
		var playing := ""
		if ap != null:
			playing = ap.current_animation
		var mesh_ok := _has_mesh(n)
		var sk := _find_skel(n)
		print(
			"CHAR ",
			n.name,
			" aliases=",
			aliases_ok,
			"/7 mesh=",
			mesh_ok,
			" bones=",
			sk.get_bone_count() if sk else 0,
			" play_walk=",
			played,
			" current=",
			playing
		)
		n.queue_free()
		await process_frame

	# Fix camera on testbed if needed + quick load check
	var tb := load("res://scenes/art/testbeds/Character_Testbed.tscn") as PackedScene
	print("TESTBED_LOAD ", tb != null)
	if tb != null:
		var tbn := tb.instantiate()
		root.add_child(tbn)
		await process_frame
		var cam := tbn.get_node_or_null("Camera3D") as Camera3D
		if cam != null:
			cam.look_at_from_position(Vector3(0, 1.6, 7.5), Vector3(0, 1.0, 0), Vector3.UP)
			print("CAM_FIXED pos=", cam.global_position)
		print("TB_CHARS ", tbn.get_node("Characters").get_child_count() if tbn.get_node_or_null("Characters") else 0)
		tbn.queue_free()
	quit(0)


func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null:
			return r
	return null


func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var r := _find_skel(c)
		if r != null:
			return r
	return null


func _has_mesh(n: Node) -> bool:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return true
	for c in n.get_children():
		if _has_mesh(c):
			return true
	return false
