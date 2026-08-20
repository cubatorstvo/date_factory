class_name CityProgressionService
extends RefCounted

const MAX_CITY_STAGE: int = 3
const MINUTES_PER_DAY: int = 1440


static func get_city_stage() -> int:
	var world: Variant = _world_service()
	if world == null:
		return 1
	return clampi(int(world.get_city_stage()), 1, MAX_CITY_STAGE)


static func get_social_cooldown_days() -> int:
	var city_stage: int = get_city_stage()
	if city_stage >= 3:
		return 1
	if city_stage >= 2:
		return 2
	return 3


static func get_social_cooldown_minutes() -> int:
	return get_social_cooldown_days() * MINUTES_PER_DAY


static func city_stage_from_story_stage(story_stage: int) -> int:
	if story_stage <= 1:
		return 1
	if story_stage <= 3:
		return 2
	return 3


static func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node
