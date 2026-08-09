extends Node
## Camera-at-spawn visual capture + movement collision probe for PE01 apartment.
## Run: res://world/test/apartment_spawn_visual_capture.tscn

const ABS_EVIDENCE: String = "C:/Users/User/Documents/GodotProjects/date_factory/tmp/pe01_apt_phys/evidence"

var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ABS_EVIDENCE)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("reset_for_new_game"):
		gs.call("reset_for_new_game")
	await get_tree().process_frame
	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	_ok(packed != null, "load apartment.tscn")
	if packed == null:
		_finish()
		return
	var loc: Node3D = packed.instantiate() as Node3D
	_ok(loc != null, "instantiate apartment")
	add_child(loc)
	await get_tree().process_frame
	await get_tree().process_frame
	var spawn: Node3D = loc.get_node_or_null("PlayerSpawns/spawn_default") as Node3D
	var neighbor: Node3D = loc.get_node_or_null("NpcSpawns/npc_girl_neighbor") as Node3D
	_ok(spawn != null, "spawn_default")
	_ok(neighbor != null, "npc_girl_neighbor")
	if spawn == null:
		_finish()
		return
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	add_child(cam)
	cam.current = true
	cam.global_transform = Transform3D(
		spawn.global_transform.basis,
		spawn.global_position + Vector3(0.0, 1.65, 0.0)
	)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_ok(_save_shot("01_new_game_first_frame.png"), "shot first frame")
	# Exit approach from readable distance (still looking at city door).
	cam.global_position = Vector3(-1.15, 1.65, 0.25)
	cam.look_at(Vector3(-2.35, 1.35, 0.25), Vector3.UP)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_ok(_save_shot("06_exit_approach.png"), "shot exit approach")
	# Neighbor: look from room center toward south door spawn.
	if neighbor != null:
		if neighbor.has_method("_refresh_spawn"):
			neighbor.call("_refresh_spawn")
		await get_tree().process_frame
		await get_tree().process_frame
		var spawned: Node3D = neighbor.get_node_or_null("Spawned_girl_neighbor") as Node3D
		_ok(String(neighbor.get("content_id")) == "girl_neighbor", "content_id girl_neighbor")
		_ok(spawned != null, "Spawned_girl_neighbor present")
		cam.global_position = Vector3(-0.4, 1.65, 0.35)
		var look_target: Vector3 = neighbor.global_position + Vector3(0.0, 1.45, 0.0)
		cam.look_at(look_target, Vector3.UP)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_ok(_save_shot("08_neighbor_view.png"), "shot neighbor view")
	await _probe_furniture_blocking(loc, spawn)
	# Kitchen sweep for furniture readability.
	cam.global_position = Vector3(-0.2, 1.65, -0.3)
	cam.look_at(Vector3(-1.5, 1.2, -2.1), Vector3.UP)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_ok(_save_shot("05_apartment_navigation.png"), "shot kitchen/nav")
	_finish()


func _probe_furniture_blocking(loc: Node3D, spawn: Node3D) -> void:
	var space: PhysicsDirectSpaceState3D = loc.get_world_3d().direct_space_state
	_ok(space != null, "physics space for probes")
	if space == null:
		return
	# Capsule overlap at bed / table / wardrobe / fridge centers must hit furniture colliders.
	for point_name in [
		["bed", Vector3(1.55, 0.9, -1.55)],
		["table", Vector3(0.4, 0.9, 0.61)],
		["wardrobe", Vector3(2.15, 0.55, 0.95)],
		["fridge", Vector3(-2.05, 0.9, -2.15)],
		["exit_door", Vector3(-2.43, 1.0, 0.684)],
	]:
		var label: String = str(point_name[0])
		var at: Vector3 = point_name[1] as Vector3
		var q := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 1.8
		q.shape = capsule
		q.transform = Transform3D(Basis.IDENTITY, at)
		q.collision_mask = 1
		q.collide_with_areas = false
		q.collide_with_bodies = true
		var hits: Array = space.intersect_shape(q, 8)
		_ok(not hits.is_empty(), "capsule blocked inside %s volume" % label)
	# Open floor near spawn must remain free.
	var open_q := PhysicsShapeQueryParameters3D.new()
	var open_cap := CapsuleShape3D.new()
	open_cap.radius = 0.32
	open_cap.height = 1.8
	open_q.shape = open_cap
	open_q.transform = Transform3D(Basis.IDENTITY, spawn.global_position + Vector3(0.0, 0.9, 0.0))
	open_q.collision_mask = 1
	open_q.collide_with_areas = false
	open_q.collide_with_bodies = true
	var open_hits: Array = space.intersect_shape(open_q, 8)
	_ok(open_hits.is_empty(), "spawn floor capsule free")
	# Ray into exit door from approach stand.
	var ray := PhysicsRayQueryParameters3D.create(
		Vector3(-1.5, 1.0, 0.684),
		Vector3(-2.55, 1.0, 0.684)
	)
	ray.collision_mask = 1
	ray.collide_with_areas = false
	var door_hit: Dictionary = space.intersect_ray(ray)
	_ok(not door_hit.is_empty(), "ray hits exit door/wall collider")
	await get_tree().process_frame


func _save_shot(filename: String) -> bool:
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		return false
	var abs_path: String = ABS_EVIDENCE.path_join(filename)
	var err: Error = img.save_png(abs_path)
	print("CAPTURE %s err=%s path=%s" % [filename, err, abs_path])
	return err == OK


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("PE01_APT_VIS PASS: %s" % label)
	else:
		_failed += 1
		push_error("PE01_APT_VIS FAIL: %s" % label)
		print("PE01_APT_VIS FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("PE01_APT_VIS: ALL PASS (%s)" % _passed)
	else:
		print("PE01_APT_VIS: FAIL passed=%s failed=%s" % [_passed, _failed])
	get_tree().create_timer(0.2).timeout.connect(func() -> void: get_tree().quit(0 if _failed == 0 else 1))
