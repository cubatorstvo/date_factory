extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	var root: Node3D = packed.instantiate() as Node3D
	add_child(root)
	await get_tree().process_frame
	for path in ["Furniture/Wardrobe", "Furniture/ExitDoor"]:
		var n: Node3D = root.get_node(path) as Node3D
		print("NODE %s global=%s" % [path, n.global_transform])
		for m_any in n.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = m_any as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var local: AABB = mi.get_aabb()
			var waabb := AABB()
			var first := true
			for i in 8:
				var w: Vector3 = mi.global_transform * local.get_endpoint(i)
				if first:
					waabb = AABB(w, Vector3.ZERO)
					first = false
				else:
					waabb = waabb.expand(w)
			print("  MESH %s local_aabb=%s world_size=(%.3f,%.3f,%.3f) world_min_y=%.3f world_max_y=%.3f world_min_x=%.3f world_max_x=%.3f world_min_z=%.3f world_max_z=%.3f" % [
				mi.get_path(), local, waabb.size.x, waabb.size.y, waabb.size.z, waabb.position.y, waabb.end.y, waabb.position.x, waabb.end.x, waabb.position.z, waabb.end.z
			])
	# Also print overlay-equivalent box from collider
	for path2 in ["Colliders/WardrobeBody", "Colliders/ExitDoorBody"]:
		var body: StaticBody3D = root.get_node(path2) as StaticBody3D
		var shape: CollisionShape3D = body.get_node("Shape") as CollisionShape3D
		var box: BoxShape3D = shape.shape as BoxShape3D
		var half := box.size * 0.5
		var c := body.global_position
		print("BOX %s min=(%.3f,%.3f,%.3f) max=(%.3f,%.3f,%.3f)" % [path2, c.x-half.x, c.y-half.y, c.z-half.z, c.x+half.x, c.y+half.y, c.z+half.z])
	get_tree().quit(0)
