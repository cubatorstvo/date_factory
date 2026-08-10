extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	var root: Node3D = packed.instantiate() as Node3D
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame
	for path in [
		"Geometry/ApartmentArt/Furniture/Wardrobe",
		"Geometry/ApartmentArt/Objects/ExitDoor/Visual",
		"Geometry/ApartmentArt/Furniture/NeighborDoor",
		"Geometry/ApartmentArt/Furniture/NightStand",
		"Geometry/ApartmentArt/Objects/Bed/Visual",
	]:
		var n: Node3D = root.get_node_or_null(path) as Node3D
		if n == null:
			print("MISSING ", path)
			continue
		var aabb: AABB = _world_aabb(n)
		print("AABB %s center=(%.3f,%.3f,%.3f) size=(%.3f,%.3f,%.3f) min=(%.3f,%.3f,%.3f) max=(%.3f,%.3f,%.3f)" % [
			path, aabb.get_center().x, aabb.get_center().y, aabb.get_center().z,
			aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.position.x, aabb.position.y, aabb.position.z,
			aabb.end.x, aabb.end.y, aabb.end.z
		])
	get_tree().quit(0)

func _world_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	for m_any in meshes:
		var mi: MeshInstance3D = m_any as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local: AABB = mi.get_aabb()
		for i in 8:
			var c: Vector3 = local.get_endpoint(i)
			var w: Vector3 = mi.global_transform * c
			if first:
				result = AABB(w, Vector3.ZERO)
				first = false
			else:
				result = result.expand(w)
	return result
