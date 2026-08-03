extends SceneTree
## Ensure art test scenes have a usable Camera3D + light for technical validation.


const SCENES := [
	"res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn",
	"res://scenes/art/city/City_Street_Slice.tscn",
	"res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn",
	"res://scenes/art/lab/Clone_Lab_Base.tscn",
	"res://scenes/art/factory/Date_Factory_Base.tscn",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	for path in SCENES:
		var ok := await _fix_scene(path)
		print("SCENE_CAM ", path.get_file(), " ", "OK" if ok else "FAIL")
	quit(0)


func _fix_scene(path: String) -> bool:
	var ps := load(path) as PackedScene
	if ps == null:
		return false
	var root := ps.instantiate()
	get_root().add_child(root)
	await process_frame

	var aabb := _world_aabb(root)
	var center := aabb.get_center()
	if aabb.size.length() < 0.01:
		center = Vector3.ZERO
		aabb = AABB(Vector3(-4, 0, -4), Vector3(8, 3, 8))
	var radius: float = maxf(aabb.size.length() * 0.55, 6.0)
	var eye := center + Vector3(radius * 0.75, radius * 0.45, radius * 0.85)

	var cam := root.get_node_or_null("TechCamera") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "TechCamera"
		root.add_child(cam)
		cam.owner = root
	cam.current = true
	cam.look_at_from_position(eye, center + Vector3(0, 0.5, 0), Vector3.UP)

	if root.get_node_or_null("TechSun") == null:
		var sun := DirectionalLight3D.new()
		sun.name = "TechSun"
		sun.light_energy = 1.15
		root.add_child(sun)
		sun.owner = root
		sun.look_at_from_position(Vector3(8, 12, 6), center, Vector3.UP)

	if root.get_node_or_null("TechEnv") == null and not _has_world_env(root):
		var we := WorldEnvironment.new()
		we.name = "TechEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.2, 0.22, 0.26)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.65, 0.68, 0.75)
		env.ambient_light_energy = 0.85
		we.environment = env
		root.add_child(we)
		we.owner = root

	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		root.queue_free()
		await process_frame
		return false
	var err := ResourceSaver.save(packed, path)
	root.queue_free()
	await process_frame
	return err == OK


func _has_world_env(n: Node) -> bool:
	if n is WorldEnvironment:
		return true
	for c in n.get_children():
		if _has_world_env(c):
			return true
	return false


func _set_owner_recursive(n: Node, owner: Node) -> void:
	if n != owner:
		n.owner = owner
	for c in n.get_children():
		_set_owner_recursive(c, owner)


func _world_aabb(n: Node) -> AABB:
	var has := false
	var aabb := AABB()
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi := n as MeshInstance3D
		var a := mi.global_transform * mi.get_aabb()
		if a.size.length() > 0.0001:
			aabb = a
			has = true
	for c in n.get_children():
		var ca := _world_aabb(c)
		if ca.size.length() > 0.0001:
			if not has:
				aabb = ca
				has = true
			else:
				aabb = aabb.merge(ca)
	return aabb if has else AABB()
