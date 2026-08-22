class_name RatingGirlRequirement
extends GirlAccessRequirement

@export var required_rating: int = 0


func is_met(girl_id: StringName) -> bool:
	var rating: Variant = _rating_service()
	if rating == null:
		return false
	return int(rating.get_rating()) >= _required_rating(girl_id)


func get_description(_girl_id: StringName) -> String:
	return "Рейтинг"


func get_progress_text(girl_id: StringName) -> String:
	var current_rating: int = 0
	var rating: Variant = _rating_service()
	if rating != null:
		current_rating = int(rating.get_rating())
	return "%d / %d" % [current_rating, _required_rating(girl_id)]


func _required_rating(girl_id: StringName) -> int:
	var catalog: StageCatalog = _stage_catalog()
	if catalog != null:
		var definition: StageDefinition = catalog.find_stage_for_girl(girl_id)
		if definition != null and definition.story_girl_id == girl_id:
			return definition.story_girl_required_rating
	return required_rating


func _stage_catalog() -> StageCatalog:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	var stages: Variant = node
	return stages.get_catalog() as StageCatalog


func _rating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RatingService")
	if not is_instance_valid(node):
		return null
	return node
