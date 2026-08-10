extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	var root: Node3D = packed.instantiate() as Node3D
	add_child(root)
	await get_tree().process_frame
	for pair in [
		["Furniture/Wardrobe", "Colliders/WardrobeBody"],
		["Furniture/ExitDoor", "Colliders/ExitDoorBody"],
	]:
		var mesh_n: Node3D = root.get_node(pair[0]) as Node3D
		var body: StaticBody3D = root.get_node(pair[1]) as StaticBody3D
		var shape: CollisionShape3D = body.get_node("Shape") as CollisionShape3D
		var box: BoxShape3D = shape.shape as BoxShape3D
		var maabb: AABB = _world_aabb(mesh_n)
		var half: Vector3 = box.size * 0.5
		var c: Vector3 = body.global_position
		var overhang_pos: Vector3 = Vector3(
			maxf(0.0, (c.x + half.x) - maabb.end.x),
			maxf(0.0, (c.y + half.y) - maabb.end.y),
			maxf(0.0, (c.z + half.z) - maabb.end.z)
		)
		var overhang_neg: Vector3 = Vector3(
			maxf(0.0, maabb.position.x - (c.x - half.x)),
			maxf(0.0, maabb.position.y - (c.y - half.y)),
			maxf(0.0, maabb.position.z - (c.z - half.z))
		)
		# Room-facing X overhang for exit (positive X into room)
		var room_face_overhang_x: float = maxf(0.0, (c.x + half.x) - maabb.end.x) if pair[1].contains("Exit") else maxf(0.0, maabb.position.x - (c.x - half.x))
		print("FIT %s box_size=%s box_pos=%s mesh_size=%s mesh_center=%s room_overhang=%.3f max_axis_overhang_pos=%s neg=%s" % [
			pair[1], box.size, c, maabb.size, maabb.get_center(), room_face_overhang_x, overhang_pos, overhang_neg
		])
	get_tree().quit(0)

func _world_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for m_any in node.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = m_any as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local: AABB = mi.get_aabb()
		for i in 8:
			var w: Vector3 = mi.global_transform * local.get_endpoint(i)
			if first:
				result = AABB(w, Vector3.ZERO)
				first = false
			else:
				result = result.expand(w)
	return result
