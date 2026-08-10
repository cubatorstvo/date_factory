extends CollisionShape3D
class_name InteractionCollision
## Fits an interaction collision to all MeshInstance3D bounds under a sibling Visual.

@export var visual_path: NodePath = NodePath("../../Visual")
@export var minimum_size: Vector3 = Vector3(0.05, 0.05, 0.05)


func _ready() -> void:
	call_deferred("_fit_to_visual")


func _fit_to_visual() -> void:
	var interaction: Node3D = get_parent() as Node3D
	var visual: Node3D = get_node_or_null(visual_path) as Node3D
	if interaction == null or visual == null:
		return

	var mesh_instances: Array[MeshInstance3D] = []
	if visual is MeshInstance3D:
		mesh_instances.append(visual as MeshInstance3D)
	for child: Node in visual.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			mesh_instances.append(child as MeshInstance3D)
	if mesh_instances.is_empty():
		return

	var interaction_inverse: Transform3D = interaction.global_transform.affine_inverse()
	var combined_bounds: AABB = AABB()
	var has_bounds: bool = false
	for mesh_instance: MeshInstance3D in mesh_instances:
		var mesh_resource: Mesh = mesh_instance.mesh
		if mesh_resource == null:
			continue
		var mesh_to_interaction: Transform3D = (
			interaction_inverse * mesh_instance.global_transform
		)
		var transformed_bounds: AABB = _transform_aabb(
			mesh_resource.get_aabb(),
			mesh_to_interaction
		)
		if has_bounds:
			combined_bounds = combined_bounds.merge(transformed_bounds)
		else:
			combined_bounds = transformed_bounds
			has_bounds = true
	if not has_bounds:
		return

	var fitted_shape := BoxShape3D.new()
	fitted_shape.size = Vector3(
		maxf(combined_bounds.size.x, minimum_size.x),
		maxf(combined_bounds.size.y, minimum_size.y),
		maxf(combined_bounds.size.z, minimum_size.z)
	)
	shape = fitted_shape
	position = combined_bounds.get_center()
	rotation = Vector3.ZERO
	scale = Vector3.ONE


func _transform_aabb(source: AABB, xform: Transform3D) -> AABB:
	var start: Vector3 = source.position
	var finish: Vector3 = source.end
	var corners: PackedVector3Array = PackedVector3Array([
		Vector3(start.x, start.y, start.z),
		Vector3(finish.x, start.y, start.z),
		Vector3(start.x, finish.y, start.z),
		Vector3(start.x, start.y, finish.z),
		Vector3(finish.x, finish.y, start.z),
		Vector3(finish.x, start.y, finish.z),
		Vector3(start.x, finish.y, finish.z),
		Vector3(finish.x, finish.y, finish.z),
	])
	var transformed: AABB = AABB(xform * corners[0], Vector3.ZERO)
	for index: int in range(1, corners.size()):
		transformed = transformed.expand(xform * corners[index])
	return transformed
