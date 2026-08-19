extends Node

var _pending_spawn_id: StringName = &""


func transition_to_location(location_id: StringName, spawn_id: StringName = &"") -> bool:
	var world: Variant = _world_service()
	if world == null:
		return false
	var catalog: LocationCatalog = world.get_catalog()
	if catalog == null:
		return false
	var definition: LocationDefinition = catalog.get_location(location_id)
	if definition == null:
		return false
	if not bool(world.can_enter_location(location_id)):
		return false
	if not bool(world.enter_location(location_id)):
		return false
	var resolved_spawn: StringName = spawn_id
	if resolved_spawn == &"":
		resolved_spawn = definition.default_spawn_id
	return _load_location_scene(definition, resolved_spawn)


func restore_current_location(spawn_id: StringName = &"") -> bool:
	var world: Variant = _world_service()
	if world == null:
		return false
	var definition: LocationDefinition = world.get_current_location()
	if definition == null:
		return false
	var resolved_spawn: StringName = spawn_id
	if resolved_spawn == &"":
		resolved_spawn = definition.default_spawn_id
	return _load_location_scene(definition, resolved_spawn)


func _load_location_scene(definition: LocationDefinition, spawn_id: StringName) -> bool:
	if definition.scene_path.is_empty():
		return false
	var packed: PackedScene = load(definition.scene_path) as PackedScene
	if packed == null:
		return false
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	_pending_spawn_id = spawn_id
	var err: Error = tree.change_scene_to_packed(packed)
	if err != OK:
		return false
	call_deferred("_apply_pending_spawn")
	return true


func _apply_pending_spawn() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var spawn: LocationSpawnPoint = _find_spawn(tree.current_scene, _pending_spawn_id)
	var player: Node3D = tree.get_first_node_in_group("world_player") as Node3D
	if spawn == null or player == null:
		return
	player.global_transform = spawn.global_transform


func _find_spawn(root: Node, spawn_id: StringName) -> LocationSpawnPoint:
	var fallback: LocationSpawnPoint = null
	for node in root.get_tree().get_nodes_in_group("location_spawn_points"):
		var spawn: LocationSpawnPoint = node as LocationSpawnPoint
		if spawn == null:
			continue
		if spawn.spawn_id == spawn_id:
			return spawn
		if fallback == null:
			fallback = spawn
	return fallback


func _world_service() -> Variant:
	var node: Node = get_node_or_null("/root/WorldService")
	if not is_instance_valid(node):
		push_error("WorldService autoload missing")
		return null
	return node
