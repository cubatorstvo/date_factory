extends SceneTree
func _initialize() -> void:
	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	var root: Node3D = packed.instantiate() as Node3D
	root_node.add_child(root)
	await process_frame
	await process_frame
	for path in [
		"Geometry/ApartmentArt/Furniture/Wardrobe",
		"Geometry/ApartmentArt/Objects/ExitDoor/Visual",
		"Geometry/ApartmentArt/Furniture/NeighborDoor",
		"Geometry/ApartmentArt/Furniture/NightStand",
	]:
		var n: Node3D = root.get_node_or_null(path) as Node3D
		if n == null:
			print("MISSING ", path)
			continue
		var aabb := _world_aabb(n)
		print("AABB %s center=%s size=%s min=%s max=%s" % [path, aabb.get_center(), aabb.size, aabb.position, aabb.end])
	quit(0)

func _world_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local: AABB = mi.get_aabb()
		# Transform 8 corners to world
		for i in 8:
			var c: Vector3 = local.get_endpoint(i)
			var w: Vector3 = mi.global_transform * c
			if first:
				result = AABB(w, Vector3.ZERO)
				first = false
			else:
				result = result.expand(w)
	return result
