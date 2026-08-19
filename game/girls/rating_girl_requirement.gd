class_name RatingGirlRequirement
extends GirlAccessRequirement

@export var required_rating: int = 0


func is_met(_girl_id: StringName) -> bool:
	var rating: Variant = _rating_service()
	if rating == null:
		return false
	return int(rating.get_rating()) >= required_rating


func get_description(_girl_id: StringName) -> String:
	return "Рейтинг"


func get_progress_text(_girl_id: StringName) -> String:
	var current_rating: int = 0
	var rating: Variant = _rating_service()
	if rating != null:
		current_rating = int(rating.get_rating())
	return "%d / %d" % [current_rating, required_rating]


func _rating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RatingService")
	if not is_instance_valid(node):
		return null
	return node
